<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'name_ar',
        'description',
        'barcode',
        'sku',
        'category_id',
        'brand_id',
        'cost_price',
        'selling_price',
        'stock_quantity',
        'min_stock_level',
        'size',
        'image',
        'images',
        'is_active'
    ];

    protected $casts = [
        'cost_price' => 'decimal:2',
        'selling_price' => 'decimal:2',
        'stock_quantity' => 'integer',
        'min_stock_level' => 'integer',
        'images' => 'array',
        'is_active' => 'boolean',
    ];

    protected $appends = ['profit_margin', 'is_low_stock'];

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function brand()
    {
        return $this->belongsTo(Brand::class);
    }

    public function saleItems()
    {
        return $this->hasMany(SaleItem::class);
    }

    public function inventoryMovements()
    {
        return $this->hasMany(InventoryMovement::class);
    }

    public function getProfitMarginAttribute()
    {
        if ($this->cost_price > 0) {
            return round((($this->selling_price - $this->cost_price) / $this->cost_price) * 100, 2);
        }
        return 0;
    }

    public function getIsLowStockAttribute()
    {
        return $this->stock_quantity <= $this->min_stock_level;
    }
}
