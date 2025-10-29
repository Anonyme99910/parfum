# Invoices & Stock Management - Implementation Status

## ✅ COMPLETED (Phase 1 - Backend Foundation)

### Database Migrations
- ✅ Enhanced `products` table with `reserved_qty` column
- ✅ Created `payments` table for partial payment tracking
- ✅ Enhanced `sales` table with invoice fields:
  - `status` (draft, issued, partially_paid, paid, void)
  - `shipping`, `paid_sum`, `balance_due`
  - `issue_date`, `due_date`, `created_by`
- ✅ Enhanced `inventory_movements` table with:
  - New types: sale, return, manual_adjust, purchase, reserve, release
  - `related_type`, `related_id` for tracking
  - `moved_at`, `created_by`

### Models
- ✅ Created `Payment` model with:
  - Relationships: sale, creator
  - Fillable fields and casts
- ✅ Enhanced `Sale` model with:
  - New fillable fields for invoices
  - Relationships: payments, creator
  - Scopes: unpaid(), partiallyPaid(), paid(), void()
  - Methods: recordPayment(), calculateTotals()

### Controllers
- ✅ Created `PaymentController` with:
  - store() - Record payment
  - index() - List payments

---

## 🚧 IN PROGRESS (Next Steps)

### Backend API Routes
```php
// Add to routes/api.php
Route::middleware('auth:sanctum')->group(function () {
    // Invoice/Sales routes (enhance existing)
    Route::get('/sales/{id}/payments', [PaymentController::class, 'index']);
    Route::post('/sales/{id}/payments', [PaymentController::class, 'store']);
    Route::post('/sales/{id}/void', [SaleController::class, 'void']);
    
    // Stock management
    Route::get('/stock', [StockController::class, 'index']);
    Route::get('/stock/movements', [StockController::class, 'movements']);
    Route::post('/stock/adjust', [StockController::class, 'adjust']);
    Route::get('/stock/low-stock', [StockController::class, 'lowStock']);
});
```

### SaleController Enhancements Needed
```php
// Add these methods to existing SaleController

public function void($id)
{
    $sale = Sale::findOrFail($id);
    
    if ($sale->status === 'void') {
        return response()->json(['error' => 'Invoice already voided'], 422);
    }
    
    DB::transaction(function () use ($sale) {
        $sale->status = 'void';
        $sale->save();
        
        // Release reserved stock
        foreach ($sale->items as $item) {
            $product = $item->product;
            $product->reserved_qty -= $item->quantity;
            $product->save();
            
            InventoryMovement::create([
                'product_id' => $product->id,
                'type' => 'release',
                'quantity' => $item->quantity,
                'related_type' => 'sale',
                'related_id' => $sale->id,
                'moved_at' => now(),
                'created_by' => auth()->id()
            ]);
        }
    });
    
    return response()->json(['message' => 'Invoice voided successfully', 'sale' => $sale]);
}

// Enhance existing index() to support filtering
public function index(Request $request)
{
    $query = Sale::with(['customer', 'items.product', 'payments']);
    
    // Filter by status
    if ($request->has('status')) {
        if ($request->status === 'unpaid') {
            $query->unpaid();
        } elseif ($request->status === 'partially_paid') {
            $query->partiallyPaid();
        } elseif ($request->status === 'paid') {
            $query->paid();
        } elseif ($request->status === 'void') {
            $query->void();
        }
    }
    
    // Filter by date range
    if ($request->has('start_date') && $request->has('end_date')) {
        $query->whereBetween('issue_date', [$request->start_date, $request->end_date]);
    }
    
    // Filter by customer
    if ($request->has('customer_id')) {
        $query->where('customer_id', $request->customer_id);
    }
    
    $sales = $query->orderBy('created_at', 'desc')->paginate(20);
    
    // Get status counts for tabs
    $counts = [
        'all' => Sale::count(),
        'unpaid' => Sale::unpaid()->count(),
        'partially_paid' => Sale::partiallyPaid()->count(),
        'paid' => Sale::paid()->count(),
        'void' => Sale::void()->count()
    ];
    
    return response()->json([
        'sales' => $sales,
        'counts' => $counts
    ]);
}
```

### StockController (Create New)
```php
<?php

namespace App\Http\Controllers;

use App\Models\Product;
use App\Models\InventoryMovement;
use Illuminate\Http\Request;

class StockController extends Controller
{
    public function index(Request $request)
    {
        $query = Product::query();
        
        // Calculate available stock
        $query->selectRaw('*, (stock_quantity - reserved_qty) as available_qty');
        
        // Filter low stock
        if ($request->has('low_stock')) {
            $query->whereRaw('stock_quantity <= min_stock_level');
        }
        
        $products = $query->with(['category', 'brand'])->paginate(50);
        
        return response()->json($products);
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
                'note' => $request->note,
                'moved_at' => now(),
                'created_by' => auth()->id()
            ]);
        });
        
        return response()->json(['message' => 'Stock adjusted successfully', 'product' => $product]);
    }
    
    public function lowStock()
    {
        $products = Product::whereRaw('stock_quantity <= min_stock_level')
            ->with(['category', 'brand'])
            ->get();
            
        return response()->json($products);
    }
}
```

---

## 📱 FRONTEND (To Be Implemented)

### 1. Update Sidebar Navigation
```javascript
// In MainLayout.vue, add to menuItems:
{
  name: 'الفواتير',
  icon: 'FileText',
  path: '/invoices'
},
{
  name: 'المخزون',
  icon: 'Package',
  path: '/stock'
}
```

### 2. Create Vue Components

**Invoices/InvoicesList.vue**
- Tabs: All, Unpaid, Partially Paid, Paid, Void
- Table with: Invoice #, Customer, Date, Total, Paid, Balance, Status
- Filters: Date range, Customer, Payment method
- Actions: View, Download PDF, Share WhatsApp

**Invoices/InvoiceDetail.vue**
- Invoice header with status badge
- Items table
- Payments list with "Add Payment" button
- Payment modal
- PDF download and WhatsApp share buttons

**Stock/StockList.vue**
- Products table with: SKU, Name, On-hand, Reserved, Available, Reorder Level
- Low stock alerts
- Manual adjustment button

**Stock/StockMovements.vue**
- Movement history table
- Filters by product, type, date

### 3. API Service Methods
```javascript
// Add to frontend/src/services/api.js

// Invoices
getInvoices: (params) => api.get('/sales', { params }),
getInvoice: (id) => api.get(`/sales/${id}`),
voidInvoice: (id) => api.post(`/sales/${id}/void`),

// Payments
getPayments: (invoiceId) => api.get(`/sales/${invoiceId}/payments`),
recordPayment: (invoiceId, data) => api.post(`/sales/${invoiceId}/payments`, data),

// Stock
getStock: (params) => api.get('/stock', { params }),
getStockMovements: (params) => api.get('/stock/movements', { params }),
adjustStock: (data) => api.post('/stock/adjust', data),
getLowStock: () => api.get('/stock/low-stock')
```

### 4. Routes
```javascript
// Add to frontend/src/router/index.js
{
  path: '/invoices',
  name: 'Invoices',
  component: () => import('../views/Invoices/InvoicesList.vue'),
  meta: { requiresAuth: true }
},
{
  path: '/invoices/:id',
  name: 'InvoiceDetail',
  component: () => import('../views/Invoices/InvoiceDetail.vue'),
  meta: { requiresAuth: true }
},
{
  path: '/stock',
  name: 'Stock',
  component: () => import('../views/Stock/StockList.vue'),
  meta: { requiresAuth: true }
}
```

---

## 🎯 IMMEDIATE NEXT STEPS

1. **Add routes to `routes/api.php`** (5 minutes)
2. **Create StockController** (15 minutes)
3. **Enhance SaleController with void() and enhanced index()** (20 minutes)
4. **Create InvoicesList.vue component** (1 hour)
5. **Create InvoiceDetail.vue component** (1 hour)
6. **Create StockList.vue component** (45 minutes)
7. **Update sidebar navigation** (10 minutes)
8. **Test all features** (30 minutes)

**Total estimated time: ~4 hours for MVP**

---

## 📊 What's Working Now

✅ Database structure complete
✅ Payment model and controller ready
✅ Sale model enhanced with invoice features
✅ Partial payment logic implemented
✅ Stock reservation fields in place

## 🔜 What Needs to Be Done

- [ ] Add API routes
- [ ] Create StockController
- [ ] Enhance SaleController
- [ ] Create frontend components
- [ ] Update navigation
- [ ] Test end-to-end

---

**The foundation is solid. Ready to continue with backend routes and frontend implementation!**
