# Invoices & Stock Management System - Implementation Plan

## 🎯 Overview

Complete invoices and stock management system with partial payments, stock reservations, and comprehensive reporting.

---

## 📊 Database Schema

### New Tables

#### 1. invoices
```sql
CREATE TABLE invoices (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    number VARCHAR(50) UNIQUE NOT NULL,
    customer_id BIGINT UNSIGNED,
    status ENUM('draft', 'issued', 'partially_paid', 'paid', 'void') DEFAULT 'draft',
    subtotal DECIMAL(10,2) NOT NULL,
    discount DECIMAL(10,2) DEFAULT 0,
    tax DECIMAL(10,2) DEFAULT 0,
    shipping DECIMAL(10,2) DEFAULT 0,
    total_due DECIMAL(10,2) NOT NULL,
    paid_sum DECIMAL(10,2) DEFAULT 0,
    balance_due DECIMAL(10,2) NOT NULL,
    issue_date DATE,
    due_date DATE,
    notes TEXT,
    pdf_url VARCHAR(255),
    created_by BIGINT UNSIGNED,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    INDEX idx_status (status),
    INDEX idx_issue_date (issue_date),
    INDEX idx_customer (customer_id)
);
```

#### 2. invoice_items
```sql
CREATE TABLE invoice_items (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    invoice_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED,
    name_snapshot VARCHAR(255) NOT NULL,
    sku_snapshot VARCHAR(100),
    qty INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    INDEX idx_invoice (invoice_id)
);
```

#### 3. payments
```sql
CREATE TABLE payments (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    invoice_id BIGINT UNSIGNED NOT NULL,
    method ENUM('cash', 'card', 'bank', 'wallet', 'cod') NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    reference VARCHAR(100),
    paid_at DATETIME NOT NULL,
    notes TEXT,
    created_by BIGINT UNSIGNED,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    INDEX idx_invoice (invoice_id),
    INDEX idx_paid_at (paid_at)
);
```

#### 4. stock_movements
```sql
CREATE TABLE stock_movements (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT UNSIGNED NOT NULL,
    type ENUM('sale', 'return', 'manual_adjust', 'purchase', 'reserve', 'release') NOT NULL,
    qty INT NOT NULL,
    related_type VARCHAR(50),
    related_id BIGINT UNSIGNED,
    moved_at DATETIME NOT NULL,
    note TEXT,
    created_by BIGINT UNSIGNED,
    created_at TIMESTAMP,
    updated_at TIMESTAMP,
    INDEX idx_product (product_id),
    INDEX idx_moved_at (moved_at),
    INDEX idx_related (related_type, related_id)
);
```

#### 5. Update products table
```sql
ALTER TABLE products ADD COLUMN reserved_qty INT DEFAULT 0;
ALTER TABLE products ADD COLUMN reorder_level INT DEFAULT 10;
ALTER TABLE products ADD COLUMN is_active BOOLEAN DEFAULT 1;
```

---

## 🏗️ Backend Structure

### Models

**Invoice.php**
- Relationships: customer, items, payments, creator
- Scopes: unpaid, partiallyPaid, paid, void
- Methods: calculateTotals(), recordPayment(), updateStatus(), generatePDF()

**InvoiceItem.php**
- Relationships: invoice, product
- Methods: calculateLineTotal()

**Payment.php**
- Relationships: invoice, creator
- Methods: processPayment(), updateInvoiceStatus()

**StockMovement.php**
- Relationships: product, creator
- Methods: applyMovement(), reserveStock(), releaseStock()

### Controllers

**InvoiceController.php**
- index() - List with filters and tabs
- store() - Create new invoice
- show() - Invoice details
- update() - Update invoice
- void() - Void invoice
- generatePDF() - Generate PDF
- getWhatsAppMessage() - WhatsApp sharing

**PaymentController.php**
- store() - Record payment
- index() - Payment history
- refund() - Process refund

**StockController.php**
- index() - Stock list
- movements() - Movement history
- adjust() - Manual adjustment
- lowStock() - Low stock alerts

### API Routes

```php
// Invoices
Route::prefix('invoices')->group(function () {
    Route::get('/', [InvoiceController::class, 'index']);
    Route::post('/', [InvoiceController::class, 'store']);
    Route::get('/{id}', [InvoiceController::class, 'show']);
    Route::put('/{id}', [InvoiceController::class, 'update']);
    Route::post('/{id}/void', [InvoiceController::class, 'void']);
    Route::get('/{id}/pdf', [InvoiceController::class, 'generatePDF']);
    Route::get('/{id}/whatsapp', [InvoiceController::class, 'getWhatsAppMessage']);
    
    // Payments
    Route::post('/{id}/payments', [PaymentController::class, 'store']);
    Route::get('/{id}/payments', [PaymentController::class, 'index']);
});

// Stock
Route::prefix('stock')->group(function () {
    Route::get('/', [StockController::class, 'index']);
    Route::get('/movements', [StockController::class, 'movements']);
    Route::post('/adjust', [StockController::class, 'adjust']);
    Route::get('/low-stock', [StockController::class, 'lowStock']);
});
```

---

## 🎨 Frontend Structure

### Vue Components

**Invoices/**
- InvoicesList.vue - Main list with tabs
- InvoiceDetail.vue - Invoice detail page
- InvoiceForm.vue - Create/edit invoice
- PaymentModal.vue - Record payment
- InvoiceFilters.vue - Filter component

**Stock/**
- StockList.vue - Stock overview
- StockMovements.vue - Movement history
- StockAdjustment.vue - Manual adjustment
- LowStockAlerts.vue - Alerts component

### Routes

```javascript
{
  path: '/invoices',
  component: InvoicesList,
  meta: { requiresAuth: true }
},
{
  path: '/invoices/:id',
  component: InvoiceDetail,
  meta: { requiresAuth: true }
},
{
  path: '/stock',
  component: StockList,
  meta: { requiresAuth: true }
}
```

### Sidebar Navigation

```javascript
{
  name: 'الفواتير',
  icon: 'FileText',
  path: '/invoices',
  badge: unpaidCount
},
{
  name: 'المخزون',
  icon: 'Package',
  path: '/stock',
  badge: lowStockCount
}
```

---

## 💰 Partial Payment Logic

### Status Flow

```
draft → issued → partially_paid → paid
                      ↓
                    void
```

### Payment Processing

```php
public function recordPayment($invoiceId, $amount, $method, $reference = null)
{
    DB::transaction(function () use ($invoiceId, $amount, $method, $reference) {
        $invoice = Invoice::findOrFail($invoiceId);
        
        // Create payment record
        $payment = Payment::create([
            'invoice_id' => $invoiceId,
            'amount' => $amount,
            'method' => $method,
            'reference' => $reference,
            'paid_at' => now(),
            'created_by' => auth()->id()
        ]);
        
        // Update invoice totals
        $invoice->paid_sum += $amount;
        $invoice->balance_due = $invoice->total_due - $invoice->paid_sum;
        
        // Update status
        if ($invoice->paid_sum <= 0) {
            $invoice->status = 'issued';
        } elseif ($invoice->paid_sum >= $invoice->total_due) {
            $invoice->status = 'paid';
            // Release reserved stock
            $this->releaseReservedStock($invoice);
        } else {
            $invoice->status = 'partially_paid';
        }
        
        $invoice->save();
        
        return $payment;
    });
}
```

---

## 📦 Stock Management

### Reserve on Issue, Deduct on Payment

```php
// When invoice is issued
public function reserveStock($invoice)
{
    foreach ($invoice->items as $item) {
        $product = $item->product;
        $product->reserved_qty += $item->qty;
        $product->save();
        
        StockMovement::create([
            'product_id' => $product->id,
            'type' => 'reserve',
            'qty' => -$item->qty,
            'related_type' => 'invoice',
            'related_id' => $invoice->id,
            'moved_at' => now(),
            'created_by' => auth()->id()
        ]);
    }
}

// When invoice is fully paid
public function releaseReservedStock($invoice)
{
    foreach ($invoice->items as $item) {
        $product = $item->product;
        
        // Release reservation
        $product->reserved_qty -= $item->qty;
        
        // Deduct from actual stock
        $product->stock_qty -= $item->qty;
        $product->save();
        
        StockMovement::create([
            'product_id' => $product->id,
            'type' => 'sale',
            'qty' => -$item->qty,
            'related_type' => 'invoice',
            'related_id' => $invoice->id,
            'moved_at' => now(),
            'created_by' => auth()->id()
        ]);
    }
}
```

---

## 📊 Reporting & Analytics

### Dashboard Metrics

```php
// Today
$today = [
    'total_sales' => Invoice::whereDate('issue_date', today())->sum('total_due'),
    'collected' => Payment::whereDate('paid_at', today())->sum('amount'),
    'outstanding' => Invoice::whereIn('status', ['issued', 'partially_paid'])->sum('balance_due')
];

// This Month
$thisMonth = [
    'issued' => Invoice::whereMonth('issue_date', now()->month)->count(),
    'paid' => Invoice::where('status', 'paid')->whereMonth('issue_date', now()->month)->count(),
    'unpaid' => Invoice::where('status', 'issued')->count(),
    'partial' => Invoice::where('status', 'partially_paid')->count(),
    'average_ticket' => Invoice::whereMonth('issue_date', now()->month)->avg('total_due')
];
```

---

## 🔐 Permissions

### Roles

- **cashier**: create invoices, record payments
- **manager**: void invoices, adjust stock
- **admin**: all permissions

### Implementation

```php
// Middleware
Route::middleware(['auth:sanctum', 'role:manager'])->group(function () {
    Route::post('/invoices/{id}/void', [InvoiceController::class, 'void']);
    Route::post('/stock/adjust', [StockController::class, 'adjust']);
});
```

---

## 📄 PDF & WhatsApp

### Invoice PDF

```php
public function generatePDF($id)
{
    $invoice = Invoice::with(['customer', 'items', 'payments'])->findOrFail($id);
    
    $pdf = new \TCPDF('P', 'mm', 'A4', true, 'UTF-8');
    $pdf->SetFont('aealarabiya', '', 11);
    $pdf->AddPage();
    $pdf->setRTL(true);
    
    $html = view('invoice-pdf', compact('invoice'))->render();
    $pdf->writeHTML($html, true, false, true, false, '');
    
    $fileName = 'invoice-' . $invoice->number . '.pdf';
    $path = 'invoices/' . $fileName;
    \Storage::disk('public')->put($path, $pdf->Output('', 'S'));
    
    $invoice->update(['pdf_url' => $path]);
    
    return response()->file(storage_path('app/public/' . $path));
}
```

### WhatsApp Message

```php
private function generateWhatsAppMessage($invoice, $pdfUrl)
{
    $msg = "شكراً لتعاملكم معنا\n";
    $msg .= "رقم الفاتورة: {$invoice->number}\n";
    $msg .= "التاريخ: " . $invoice->issue_date->format('d/m/Y') . "\n\n";
    $msg .= "الإجمالي: " . number_format($invoice->total_due, 2) . " EGP\n";
    $msg .= "المدفوع: " . number_format($invoice->paid_sum, 2) . " EGP\n";
    $msg .= "المتبقي: " . number_format($invoice->balance_due, 2) . " EGP\n\n";
    $msg .= "تحميل الفاتورة:\n{$pdfUrl}";
    
    return $msg;
}
```

---

## 🚀 Implementation Timeline

### Phase 1: Database & Models (Day 1)
- Create migrations
- Create models
- Set up relationships

### Phase 2: Backend API (Day 2-3)
- Invoice CRUD
- Payment processing
- Stock management
- PDF generation

### Phase 3: Frontend Components (Day 4-5)
- Invoices list
- Invoice detail
- Stock management
- Navigation

### Phase 4: Testing & Polish (Day 6)
- Test all flows
- Fix bugs
- Optimize queries
- Documentation

---

## ✅ Success Criteria

- ✅ Create invoices with multiple items
- ✅ Record partial payments
- ✅ Track payment history
- ✅ Automatic status updates
- ✅ Stock reservation on issue
- ✅ Stock deduction on payment
- ✅ Low stock alerts
- ✅ PDF generation
- ✅ WhatsApp sharing
- ✅ Comprehensive reporting

---

**Ready to implement! This is a production-ready architecture.**
