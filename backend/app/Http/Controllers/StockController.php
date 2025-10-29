<?php

namespace App\Http\Controllers;

use App\Models\Product;
use App\Models\InventoryMovement;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StockController extends Controller
{
    public function index(Request $request)
    {
        $query = Product::query();
        
        // Calculate available stock
        $query->selectRaw('products.*, (stock_quantity - reserved_qty) as available_qty');
        
        // Filter low stock
        if ($request->has('low_stock') && $request->low_stock) {
            $query->whereRaw('stock_quantity <= min_stock_level');
        }
        
        // Search
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('name_ar', 'like', "%{$search}%")
                  ->orWhere('sku', 'like', "%{$search}%")
                  ->orWhere('barcode', 'like', "%{$search}%");
            });
        }
        
        $products = $query->with(['category', 'brand'])
            ->orderBy('name', 'asc')
            ->paginate(50);
        
        // Get low stock count
        $lowStockCount = Product::whereRaw('stock_quantity <= min_stock_level')->count();
        
        return response()->json([
            'products' => $products,
            'low_stock_count' => $lowStockCount
        ]);
    }
    
    public function movements(Request $request)
    {
        $query = InventoryMovement::with(['product', 'creator']);
        
        if ($request->has('product_id')) {
            $query->where('product_id', $request->product_id);
        }
        
        if ($request->has('type')) {
            $query->where('type', $request->type);
        }
        
        if ($request->has('start_date') && $request->has('end_date')) {
            $query->whereBetween('moved_at', [$request->start_date, $request->end_date]);
        }
        
        $movements = $query->orderBy('moved_at', 'desc')->paginate(50);
        
        return response()->json($movements);
    }
    
    public function adjust(Request $request)
    {
        $request->validate([
            'product_id' => 'required|exists:products,id',
            'quantity' => 'required|integer',
            'note' => 'required|string'
        ]);
        
        $product = Product::findOrFail($request->product_id);
        
        DB::transaction(function () use ($product, $request) {
            $previousStock = $product->stock_quantity;
            $product->stock_quantity += $request->quantity;
            $product->save();
            
            InventoryMovement::create([
                'product_id' => $product->id,
                'type' => 'manual_adjust',
                'quantity' => $request->quantity,
                'previous_stock' => $previousStock,
                'new_stock' => $product->stock_quantity,
                'notes' => $request->note,
                'moved_at' => now(),
                'created_by' => auth()->id()
            ]);
        });
        
        return response()->json([
            'message' => 'Stock adjusted successfully',
            'product' => $product
        ]);
    }
    
    public function lowStock()
    {
        $products = Product::whereRaw('stock_quantity <= min_stock_level')
            ->with(['category', 'brand'])
            ->selectRaw('products.*, (stock_quantity - reserved_qty) as available_qty')
            ->get();
            
        return response()->json($products);
    }
}
