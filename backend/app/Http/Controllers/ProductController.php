<?php

namespace App\Http\Controllers;

use App\Models\Product;
use App\Models\InventoryMovement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\DB;

class ProductController extends Controller
{
    public function index(Request $request)
    {
        $query = Product::query()
            ->select(['id', 'name', 'name_ar', 'barcode', 'sku', 'category_id', 'brand_id', 
                      'selling_price', 'stock_quantity', 'min_stock_level', 'size', 'image', 'is_active'])
            ->with(['category:id,name,name_ar', 'brand:id,name,name_ar']);

        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('name_ar', 'like', "%{$search}%")
                  ->orWhere('barcode', 'like', "%{$search}%")
                  ->orWhere('sku', 'like', "%{$search}%");
            });
        }

        if ($request->has('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        if ($request->has('brand_id')) {
            $query->where('brand_id', $request->brand_id);
        }

        if ($request->has('low_stock') && $request->low_stock) {
            $query->whereColumn('stock_quantity', '<=', 'min_stock_level');
        }

        // Add pagination for better performance
        $perPage = $request->get('per_page', 50);
        $products = $query->paginate($perPage);
        
        return response()->json($products);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'name_ar' => 'required|string|max:255',
            'barcode' => 'required|string|unique:products',
            'sku' => 'required|string|unique:products',
            'category_id' => 'required|exists:categories,id',
            'brand_id' => 'required|exists:brands,id',
            'cost_price' => 'required|numeric|min:0',
            'selling_price' => 'required|numeric|min:0',
            'stock_quantity' => 'required|integer|min:0',
            'min_stock_level' => 'required|integer|min:0',
            'size' => 'nullable|string',
            'image' => 'nullable|string',
            'is_active' => 'boolean'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        DB::beginTransaction();
        try {
            $product = Product::create($request->all());

            // Create initial inventory movement
            if ($product->stock_quantity > 0) {
                InventoryMovement::create([
                    'product_id' => $product->id,
                    'type' => 'in',
                    'quantity' => $product->stock_quantity,
                    'previous_stock' => 0,
                    'new_stock' => $product->stock_quantity,
                    'reference' => 'Initial Stock',
                    'notes' => 'Initial product creation'
                ]);
            }

            DB::commit();
            return response()->json($product->load(['category', 'brand']), 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['error' => 'Failed to create product'], 500);
        }
    }

    public function show($id)
    {
        $product = Product::with(['category', 'brand', 'inventoryMovements'])->findOrFail($id);
        return response()->json($product);
    }

    public function update(Request $request, $id)
    {
        $product = Product::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'name' => 'string|max:255',
            'name_ar' => 'string|max:255',
            'barcode' => 'string|unique:products,barcode,' . $id,
            'sku' => 'string|unique:products,sku,' . $id,
            'category_id' => 'exists:categories,id',
            'brand_id' => 'exists:brands,id',
            'cost_price' => 'numeric|min:0',
            'selling_price' => 'numeric|min:0',
            'stock_quantity' => 'integer|min:0',
            'min_stock_level' => 'integer|min:0',
            'size' => 'nullable|string',
            'image' => 'nullable|string',
            'is_active' => 'boolean'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $product->update($request->all());
        return response()->json($product->load(['category', 'brand']));
    }

    public function destroy($id)
    {
        $product = Product::findOrFail($id);
        $product->delete();
        return response()->json(['message' => 'Product deleted successfully']);
    }

    public function searchByBarcode($barcode)
    {
        $product = Product::with(['category', 'brand'])
            ->where('barcode', $barcode)
            ->first();

        if (!$product) {
            return response()->json(['message' => 'Product not found'], 404);
        }

        return response()->json($product);
    }

    public function lowStock()
    {
        $products = Product::with(['category', 'brand'])
            ->whereRaw('stock_quantity <= min_stock_level')
            ->get();

        return response()->json($products);
    }

    public function adjustStock(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'quantity' => 'required|integer',
            'type' => 'required|in:in,out,adjustment',
            'notes' => 'nullable|string'
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $product = Product::findOrFail($id);
        $previousStock = $product->stock_quantity;

        DB::beginTransaction();
        try {
            if ($request->type === 'in') {
                $product->stock_quantity += $request->quantity;
            } elseif ($request->type === 'out') {
                if ($product->stock_quantity < $request->quantity) {
                    return response()->json(['error' => 'Insufficient stock'], 400);
                }
                $product->stock_quantity -= $request->quantity;
            } else {
                $product->stock_quantity = $request->quantity;
            }

            $product->save();

            InventoryMovement::create([
                'product_id' => $product->id,
                'type' => $request->type,
                'quantity' => $request->quantity,
                'previous_stock' => $previousStock,
                'new_stock' => $product->stock_quantity,
                'reference' => $request->reference ?? 'Manual Adjustment',
                'notes' => $request->notes
            ]);

            DB::commit();
            return response()->json($product->load(['category', 'brand']));
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['error' => 'Failed to adjust stock'], 500);
        }
    }
}
