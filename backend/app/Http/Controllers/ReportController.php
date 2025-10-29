<?php

namespace App\Http\Controllers;

use App\Models\Sale;
use App\Models\Product;
use App\Models\Customer;
use App\Models\SaleItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    public function dashboard()
    {
        $today = today();
        $thisMonth = now()->startOfMonth();

        // Today's statistics
        $todaySales = Sale::whereDate('created_at', $today)
            ->where('status', 'completed')
            ->sum('total');

        $todayOrders = Sale::whereDate('created_at', $today)
            ->where('status', 'completed')
            ->count();

        // This month's statistics
        $monthSales = Sale::where('created_at', '>=', $thisMonth)
            ->where('status', 'completed')
            ->sum('total');

        $monthOrders = Sale::where('created_at', '>=', $thisMonth)
            ->where('status', 'completed')
            ->count();

        // Inventory statistics
        $totalProducts = Product::count();
        $lowStockProducts = Product::whereRaw('stock_quantity <= min_stock_level')->count();
        $outOfStockProducts = Product::where('stock_quantity', 0)->count();

        // Total inventory value
        $inventoryValue = Product::selectRaw('SUM(stock_quantity * cost_price) as total')
            ->first()
            ->total ?? 0;

        // Top selling products this month
        $topProducts = SaleItem::select('product_id', DB::raw('SUM(quantity) as total_sold'))
            ->whereHas('sale', function($q) use ($thisMonth) {
                $q->where('created_at', '>=', $thisMonth)
                  ->where('status', 'completed');
            })
            ->groupBy('product_id')
            ->orderBy('total_sold', 'desc')
            ->limit(5)
            ->with('product')
            ->get();

        // Top customers
        $topCustomers = Customer::orderBy('total_purchases', 'desc')
            ->limit(5)
            ->get();

        return response()->json([
            'today' => [
                'sales' => $todaySales,
                'orders' => $todayOrders
            ],
            'month' => [
                'sales' => $monthSales,
                'orders' => $monthOrders
            ],
            'inventory' => [
                'total_products' => $totalProducts,
                'low_stock' => $lowStockProducts,
                'out_of_stock' => $outOfStockProducts,
                'total_value' => $inventoryValue
            ],
            'top_products' => $topProducts,
            'top_customers' => $topCustomers
        ]);
    }

    public function salesReport(Request $request)
    {
        $startDate = $request->start_date ?? now()->startOfMonth();
        $endDate = $request->end_date ?? now();

        $sales = Sale::whereBetween('created_at', [$startDate, $endDate])
            ->where('status', 'completed')
            ->with(['customer', 'items.product'])
            ->get();

        $totalSales = $sales->sum('total');
        $totalOrders = $sales->count();
        $averageOrderValue = $totalOrders > 0 ? $totalSales / $totalOrders : 0;

        // Calculate profit
        $totalProfit = 0;
        foreach ($sales as $sale) {
            foreach ($sale->items as $item) {
                $profit = ($item->unit_price - $item->product->cost_price) * $item->quantity;
                $totalProfit += $profit;
            }
        }

        // Sales by payment method
        $salesByPayment = Sale::whereBetween('created_at', [$startDate, $endDate])
            ->where('status', 'completed')
            ->select('payment_method', DB::raw('SUM(total) as total'))
            ->groupBy('payment_method')
            ->get();

        // Daily sales
        $dailySales = Sale::whereBetween('created_at', [$startDate, $endDate])
            ->where('status', 'completed')
            ->select(DB::raw('DATE(created_at) as date'), DB::raw('SUM(total) as total'), DB::raw('COUNT(*) as count'))
            ->groupBy('date')
            ->orderBy('date')
            ->get();

        return response()->json([
            'summary' => [
                'total_sales' => $totalSales,
                'total_orders' => $totalOrders,
                'average_order_value' => $averageOrderValue,
                'total_profit' => $totalProfit,
                'profit_margin' => $totalSales > 0 ? ($totalProfit / $totalSales) * 100 : 0
            ],
            'sales_by_payment' => $salesByPayment,
            'daily_sales' => $dailySales,
            'sales' => $sales
        ]);
    }

    public function productReport(Request $request)
    {
        $startDate = $request->start_date ?? now()->startOfMonth();
        $endDate = $request->end_date ?? now();

        // Best selling products
        $bestSelling = SaleItem::select('product_id', 
            DB::raw('SUM(quantity) as total_sold'),
            DB::raw('SUM(total_price) as total_revenue'))
            ->whereHas('sale', function($q) use ($startDate, $endDate) {
                $q->whereBetween('created_at', [$startDate, $endDate])
                  ->where('status', 'completed');
            })
            ->groupBy('product_id')
            ->orderBy('total_sold', 'desc')
            ->with('product.category', 'product.brand')
            ->get();

        // Sales by category
        $salesByCategory = SaleItem::select('products.category_id',
            DB::raw('SUM(sale_items.quantity) as total_sold'),
            DB::raw('SUM(sale_items.total_price) as total_revenue'))
            ->join('products', 'sale_items.product_id', '=', 'products.id')
            ->whereHas('sale', function($q) use ($startDate, $endDate) {
                $q->whereBetween('created_at', [$startDate, $endDate])
                  ->where('status', 'completed');
            })
            ->groupBy('products.category_id')
            ->with('product.category')
            ->get();

        // Sales by brand
        $salesByBrand = SaleItem::select('products.brand_id',
            DB::raw('SUM(sale_items.quantity) as total_sold'),
            DB::raw('SUM(sale_items.total_price) as total_revenue'))
            ->join('products', 'sale_items.product_id', '=', 'products.id')
            ->whereHas('sale', function($q) use ($startDate, $endDate) {
                $q->whereBetween('created_at', [$startDate, $endDate])
                  ->where('status', 'completed');
            })
            ->groupBy('products.brand_id')
            ->with('product.brand')
            ->get();

        return response()->json([
            'best_selling' => $bestSelling,
            'sales_by_category' => $salesByCategory,
            'sales_by_brand' => $salesByBrand
        ]);
    }

    public function inventoryReport()
    {
        $products = Product::with(['category', 'brand'])
            ->select('*', DB::raw('stock_quantity * cost_price as stock_value'))
            ->get();

        $totalValue = $products->sum('stock_value');
        $totalProducts = $products->count();
        $lowStock = $products->filter(function($p) {
            return $p->stock_quantity <= $p->min_stock_level;
        })->count();

        return response()->json([
            'summary' => [
                'total_products' => $totalProducts,
                'total_value' => $totalValue,
                'low_stock_count' => $lowStock
            ],
            'products' => $products
        ]);
    }

    public function profitReport(Request $request)
    {
        $startDate = $request->start_date ?? now()->startOfMonth();
        $endDate = $request->end_date ?? now();

        $sales = Sale::whereBetween('created_at', [$startDate, $endDate])
            ->where('status', 'completed')
            ->with('items.product')
            ->get();

        $totalRevenue = 0;
        $totalCost = 0;
        $totalProfit = 0;

        foreach ($sales as $sale) {
            foreach ($sale->items as $item) {
                $revenue = $item->total_price;
                $cost = $item->product->cost_price * $item->quantity;
                $profit = $revenue - $cost;

                $totalRevenue += $revenue;
                $totalCost += $cost;
                $totalProfit += $profit;
            }
        }

        $profitMargin = $totalRevenue > 0 ? ($totalProfit / $totalRevenue) * 100 : 0;

        return response()->json([
            'total_revenue' => $totalRevenue,
            'total_cost' => $totalCost,
            'total_profit' => $totalProfit,
            'profit_margin' => $profitMargin
        ]);
    }
}
