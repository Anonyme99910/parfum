<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\BrandController;
use App\Http\Controllers\ProductController;
use App\Http\Controllers\CustomerController;
use App\Http\Controllers\SaleController;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\StockController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\RoleController;
use App\Http\Controllers\EmployeeController;

// Test route
Route::get('/', function () {
    return response()->json([
        'message' => 'Perfume Store API',
        'version' => '1.0',
        'status' => 'running'
    ]);
});

// Public routes
Route::post('/login', [AuthController::class, 'login'])->name('login');
Route::post('/register', [AuthController::class, 'register']);

// Public PDF download (no auth required for customer access)
Route::get('/invoice/{invoice_number}', [SaleController::class, 'publicPdfDownload']);

// Public API endpoints (for testing)
Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/brands', [BrandController::class, 'index']);
Route::get('/products', [ProductController::class, 'index']);
Route::get('/customers', [CustomerController::class, 'index']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);

    // Categories (full CRUD)
    Route::apiResource('categories', CategoryController::class)->except(['index']);

    // Brands
    Route::apiResource('brands', BrandController::class);

    // Products
    Route::apiResource('products', ProductController::class);
    Route::get('products/barcode/{barcode}', [ProductController::class, 'searchByBarcode']);
    Route::get('products/low-stock/list', [ProductController::class, 'lowStock']);
    Route::post('products/{id}/adjust-stock', [ProductController::class, 'adjustStock']);

    // Customers
    Route::apiResource('customers', CustomerController::class);
    Route::get('customers/{id}/history', [CustomerController::class, 'history']);

    // Sales / Invoices
    Route::apiResource('sales', SaleController::class)->only(['index', 'store', 'show']);
    Route::post('sales/{id}/cancel', [SaleController::class, 'cancel']);
    Route::post('sales/{id}/void', [SaleController::class, 'void']);
    Route::get('sales/today/summary', [SaleController::class, 'todaySales']);
    Route::get('sales/{id}/pdf', [SaleController::class, 'downloadPdf']);
    Route::get('sales/{id}/whatsapp', [SaleController::class, 'getWhatsAppMessage']);
    
    // Payments
    Route::get('sales/{id}/payments', [PaymentController::class, 'index']);
    Route::post('sales/{id}/payments', [PaymentController::class, 'store']);
    
    // Stock Management
    Route::get('stock', [StockController::class, 'index']);
    Route::get('stock/movements', [StockController::class, 'movements']);
    Route::post('stock/adjust', [StockController::class, 'adjust']);
    Route::get('stock/low-stock', [StockController::class, 'lowStock']);

    // Reports
    Route::get('reports/dashboard', [ReportController::class, 'dashboard']);
    Route::get('reports/sales', [ReportController::class, 'salesReport']);
    Route::get('reports/products', [ReportController::class, 'productReport']);
    Route::get('reports/inventory', [ReportController::class, 'inventoryReport']);
    Route::get('reports/profit', [ReportController::class, 'profitReport']);
    
    // Employees
    Route::apiResource('employees', EmployeeController::class);
    
    // Roles
    Route::get('roles', [RoleController::class, 'index']);
});
