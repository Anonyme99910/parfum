<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Customer extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'email',
        'phone',
        'address',
        'total_purchases',
        'total_orders'
    ];

    protected $casts = [
        'total_purchases' => 'decimal:2',
        'total_orders' => 'integer',
    ];

    public function sales()
    {
        return $this->hasMany(Sale::class);
    }
}
