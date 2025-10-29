<template>
  <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
    <!-- Products Section -->
    <div class="lg:col-span-2 space-y-4">
      <!-- Search -->
      <div class="card">
        <div class="flex gap-3">
          <div class="flex-1 relative">
            <input
              v-model="searchQuery"
              @input="searchProducts"
              type="text"
              placeholder="ابحث بالاسم أو الباركود..."
              class="input pl-10"
            />
            <Search class="absolute left-3 top-3 text-gray-400" :size="20" />
          </div>
          <button @click="scanBarcode" class="btn btn-primary flex items-center gap-2">
            <Scan :size="20" />
            مسح الباركود
          </button>
        </div>
      </div>

      <!-- Products Grid -->
      <div class="grid grid-cols-2 md:grid-cols-3 gap-4">
        <div
          v-for="product in displayProducts"
          :key="product.id"
          @click="addToCart(product)"
          class="card hover:shadow-lg cursor-pointer transition-all hover:scale-105"
        >
          <div class="aspect-square bg-gray-100 rounded-lg mb-3 flex items-center justify-center">
            <Package :size="48" class="text-gray-400" />
          </div>
          <h4 class="font-bold text-gray-900 mb-1 truncate">{{ product.name_ar }}</h4>
          <p class="text-sm text-gray-500 mb-2">{{ product.brand?.name_ar }}</p>
          <div class="flex items-center justify-between">
            <span class="text-lg font-bold text-primary-600">{{ formatCurrencyLatin(product.selling_price) }}</span>
            <span class="text-xs badge" :class="product.stock_quantity > 0 ? 'badge-success' : 'badge-danger'">
              {{ toLatinNumbers(product.stock_quantity) }} قطعة
            </span>
          </div>
        </div>
      </div>
    </div>

    <!-- Cart Section -->
    <div class="space-y-4">
      <div class="card sticky top-24">
        <h3 class="text-xl font-bold mb-4 flex items-center gap-2">
          <ShoppingCart :size="24" />
          سلة المشتريات
        </h3>

        <!-- Cart Items -->
        <div class="space-y-3 mb-4 max-h-64 overflow-y-auto">
          <div v-if="cart.length === 0" class="text-center py-8 text-gray-500">
            السلة فارغة
          </div>
          <div
            v-for="item in cart"
            :key="item.product.id"
            class="flex items-center gap-3 p-3 bg-gray-50 rounded-lg"
          >
            <div class="flex-1">
              <p class="font-medium text-sm">{{ item.product.name_ar }}</p>
              <p class="text-xs text-gray-500">{{ formatCurrencyLatin(item.product.selling_price) }}</p>
            </div>
            <div class="flex items-center gap-2">
              <button @click="decreaseQuantity(item)" class="w-7 h-7 rounded bg-gray-200 hover:bg-gray-300">
                <Minus :size="16" class="mx-auto" />
              </button>
              <span class="w-8 text-center font-bold">{{ toLatinNumbers(item.quantity) }}</span>
              <button @click="increaseQuantity(item)" class="w-7 h-7 rounded bg-gray-200 hover:bg-gray-300">
                <Plus :size="16" class="mx-auto" />
              </button>
            </div>
            <button @click="removeFromCart(item)" class="text-red-600 hover:text-red-800">
              <Trash2 :size="18" />
            </button>
          </div>
        </div>

        <!-- Customer Selection -->
        <div class="mb-4">
          <label class="block text-sm font-medium mb-2">العميل (اختياري)</label>
          <div class="flex gap-2">
            <select v-model="selectedCustomer" class="input flex-1">
              <option value="">عميل عادي</option>
              <option v-for="customer in customers" :key="customer.id" :value="customer.id">
                {{ customer.name }} - {{ toLatinNumbers(customer.phone) }}
              </option>
            </select>
            <button @click="showCustomerModal = true" class="btn btn-secondary">
              <UserPlus :size="18" />
            </button>
          </div>
        </div>

        <!-- Totals -->
        <div class="border-t pt-4 space-y-2">
          <div class="flex justify-between text-sm">
            <span>المجموع الفرعي:</span>
            <span class="font-bold">{{ formatCurrencyLatin(subtotal) }}</span>
          </div>
          <div class="flex justify-between text-sm">
            <span>الخصم:</span>
            <input
              v-model.number="discount"
              type="number"
              step="0.01"
              class="input w-32 text-left py-1"
            />
          </div>
          <div class="flex justify-between text-sm">
            <span>الضريبة:</span>
            <input
              v-model.number="tax"
              type="number"
              step="0.01"
              class="input w-32 text-left py-1"
            />
          </div>
          <div class="flex justify-between text-lg font-bold border-t pt-2">
            <span>الإجمالي:</span>
            <span class="text-primary-600">{{ formatCurrencyLatin(total) }}</span>
          </div>
          <div class="flex justify-between text-sm bg-blue-50 p-2 rounded">
            <span>المبلغ المدفوع:</span>
            <input
              v-model.number="paidAmount"
              type="number"
              step="0.01"
              :placeholder="total.toString()"
              class="input w-32 text-left py-1"
            />
          </div>
          <div v-if="remainingAmount > 0" class="flex justify-between text-sm text-red-600 font-bold">
            <span>المتبقي:</span>
            <span>{{ formatCurrencyLatin(remainingAmount) }}</span>
          </div>
        </div>

        <!-- Payment Method -->
        <div class="mt-4">
          <label class="block text-sm font-medium mb-2">طريقة الدفع</label>
          <div class="grid grid-cols-3 gap-2">
            <button
              v-for="method in paymentMethods"
              :key="method.value"
              @click="paymentMethod = method.value"
              :class="paymentMethod === method.value ? 'bg-primary-600 text-white' : 'bg-gray-100'"
              class="py-2 rounded-lg font-medium transition-all"
            >
              {{ method.label }}
            </button>
          </div>
        </div>

        <!-- Actions -->
        <div class="mt-4 space-y-2">
          <button
            @click="completeSale"
            :disabled="cart.length === 0"
            class="btn btn-success w-full py-3 text-lg"
          >
            إتمام البيع
          </button>
          <button @click="clearCart" class="btn btn-secondary w-full">
            مسح السلة
          </button>
        </div>
      </div>
    </div>

    <!-- Barcode Scanner Modal -->
    <div v-if="showBarcodeModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-xl p-6 w-full max-w-md">
        <h3 class="text-2xl font-bold mb-4">مسح الباركود</h3>
        <input
          ref="barcodeInput"
          v-model="barcodeValue"
          @keyup.enter="searchByBarcode"
          type="text"
          placeholder="امسح أو اكتب الباركود..."
          class="input mb-4"
          autofocus
        />
        <div class="flex gap-3">
          <button @click="showBarcodeModal = false" class="btn btn-secondary flex-1">إلغاء</button>
          <button @click="searchByBarcode" class="btn btn-primary flex-1">بحث</button>
        </div>
      </div>
    </div>

    <!-- Add Customer Modal -->
    <div v-if="showCustomerModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" @click.self="showCustomerModal = false">
      <div class="bg-white rounded-xl p-6 w-full max-w-md">
        <h3 class="text-2xl font-bold mb-4">إضافة عميل</h3>
        <form @submit.prevent="addCustomer" class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-2">الاسم *</label>
            <input v-model="customerForm.name" type="text" required class="input" />
          </div>
          <div>
            <label class="block text-sm font-medium mb-2">رقم الهاتف *</label>
            <input v-model="customerForm.phone" type="tel" required class="input" />
          </div>
          <div class="flex gap-3">
            <button type="button" @click="showCustomerModal = false" class="btn btn-secondary flex-1">إلغاء</button>
            <button type="submit" class="btn btn-primary flex-1">حفظ</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Search, Scan, ShoppingCart, Plus, Minus, Trash2, Package, UserPlus } from 'lucide-vue-next'
import api from '@/services/api'
import { useToast } from 'vue-toastification'
import { toLatinNumbers, formatCurrencyLatin } from '@/utils/numbers'

const toast = useToast()

const products = ref([])
const customers = ref([])
const cart = ref([])
const searchQuery = ref('')
const selectedCustomer = ref('')
const discount = ref(0)
const tax = ref(0)
const paidAmount = ref(null)
const paymentMethod = ref('cash')
const showBarcodeModal = ref(false)
const showCustomerModal = ref(false)
const barcodeValue = ref('')
const barcodeInput = ref(null)

const customerForm = ref({
  name: '',
  phone: ''
})

const paymentMethods = [
  { value: 'cash', label: 'نقدي' },
  { value: 'card', label: 'بطاقة' },
  { value: 'transfer', label: 'تحويل' }
]

const displayProducts = computed(() => {
  if (!searchQuery.value) return products.value.slice(0, 12)
  return products.value.filter(p =>
    p.name_ar.includes(searchQuery.value) ||
    p.barcode.includes(searchQuery.value)
  )
})

const subtotal = computed(() => {
  return cart.value.reduce((sum, item) => sum + (item.product.selling_price * item.quantity), 0)
})

const total = computed(() => {
  return subtotal.value + tax.value - discount.value
})

const remainingAmount = computed(() => {
  const paid = paidAmount.value || total.value
  return Math.max(0, total.value - paid)
})

const formatCurrency = (value) => {
  return new Intl.NumberFormat('ar-EG', {
    style: 'currency',
    currency: 'EGP'
  }).format(value)
}

const searchProducts = async () => {
  if (searchQuery.value.length < 2) {
    fetchProducts()
    return
  }
  try {
    const response = await api.getProducts({ search: searchQuery.value })
    products.value = response.data
  } catch (error) {
    toast.error('فشل البحث')
  }
}

const scanBarcode = () => {
  showBarcodeModal.value = true
  barcodeValue.value = ''
  setTimeout(() => {
    barcodeInput.value?.focus()
  }, 100)
}

const searchByBarcode = async () => {
  if (!barcodeValue.value) return
  
  try {
    const response = await api.searchByBarcode(barcodeValue.value)
    addToCart(response.data)
    showBarcodeModal.value = false
    barcodeValue.value = ''
  } catch (error) {
    toast.error('المنتج غير موجود')
  }
}

const addToCart = (product) => {
  if (product.stock_quantity === 0) {
    toast.error('المنتج غير متوفر في المخزون')
    return
  }

  const existingItem = cart.value.find(item => item.product.id === product.id)
  
  if (existingItem) {
    if (existingItem.quantity >= product.stock_quantity) {
      toast.error('الكمية المطلوبة غير متوفرة')
      return
    }
    existingItem.quantity++
  } else {
    cart.value.push({
      product,
      quantity: 1
    })
  }
  toast.success('تم إضافة المنتج للسلة')
}

const increaseQuantity = (item) => {
  if (item.quantity >= item.product.stock_quantity) {
    toast.error('الكمية المطلوبة غير متوفرة')
    return
  }
  item.quantity++
}

const decreaseQuantity = (item) => {
  if (item.quantity > 1) {
    item.quantity--
  } else {
    removeFromCart(item)
  }
}

const removeFromCart = (item) => {
  cart.value = cart.value.filter(i => i.product.id !== item.product.id)
}

const clearCart = () => {
  if (cart.value.length === 0) return
  if (confirm('هل أنت متأكد من مسح السلة؟')) {
    cart.value = []
    discount.value = 0
    tax.value = 0
  }
}

const addCustomer = async () => {
  try {
    const response = await api.createCustomer(customerForm.value)
    toast.success('تم إضافة العميل بنجاح')
    customers.value.push(response.data)
    selectedCustomer.value = response.data.id
    showCustomerModal.value = false
    customerForm.value = { name: '', phone: '' }
  } catch (error) {
    toast.error('فشل إضافة العميل')
  }
}

const completeSale = async () => {
  if (cart.value.length === 0) return

  const saleData = {
    customer_id: selectedCustomer.value || null,
    items: cart.value.map(item => ({
      product_id: item.product.id,
      quantity: item.quantity,
      unit_price: item.product.selling_price
    })),
    tax: tax.value,
    discount: discount.value,
    paid_amount: paidAmount.value || total.value,
    payment_method: paymentMethod.value
  }

  try {
    const response = await api.createSale(saleData)
    const invoiceNum = toLatinNumbers(response.data.invoice_number)
    toast.success(`تم إنشاء الفاتورة ${invoiceNum}`)
    
    const actions = []
    if (confirm('هل تريد تحميل الفاتورة PDF؟')) {
      try {
        await api.downloadInvoicePdf(response.data.id)
        toast.success('تم تحميل الفاتورة بنجاح')
      } catch (error) {
        console.error('PDF Error:', error)
        toast.error('فشل تحميل الفاتورة PDF')
      }
    }
    
    if (response.data.customer?.phone && confirm('هل تريد مشاركة الفاتورة عبر واتساب؟')) {
      shareViaWhatsApp(response.data)
    }
    
    // Clear cart
    cart.value = []
    discount.value = 0
    tax.value = 0
    paidAmount.value = null
    selectedCustomer.value = ''
    
    // Refresh products
    fetchProducts()
  } catch (error) {
    toast.error(error.response?.data?.error || 'فشل إنشاء الفاتورة')
  }
}

const shareViaWhatsApp = async (sale) => {
  try {
    // Get WhatsApp message (already includes the public PDF link) and phone from backend
    const response = await api.getWhatsAppMessage(sale.id)
    const { message, phone } = response.data
    
    if (!phone) {
      toast.error('لا يوجد رقم هاتف للعميل')
      return
    }
    
    // Clean phone number (remove any non-digit characters)
    const cleanPhone = phone.replace(/[^0-9]/g, '')
    
    // Open WhatsApp with minimal pre-filled message from backend
    const whatsappUrl = `https://wa.me/${cleanPhone}?text=${encodeURIComponent(message)}`
    window.open(whatsappUrl, '_blank')
    
    toast.success('تم فتح واتساب بنجاح')
  } catch (error) {
    console.error('WhatsApp Error:', error)
    console.error('Error details:', error.response?.data)
    toast.error('فشل مشاركة الفاتورة عبر واتساب: ' + (error.response?.data?.message || error.message))
  }
}

const fetchProducts = async () => {
  try {
    const response = await api.getProducts()
    products.value = response.data.data || response.data || []
  } catch (error) {
    console.error('Failed to load products:', error)
    products.value = []
  }
}

const fetchCustomers = async () => {
  try {
    const response = await api.getCustomers()
    customers.value = response.data.data || response.data || []
  } catch (error) {
    console.error('Failed to load customers:', error)
    customers.value = []
  }
}

onMounted(() => {
  fetchProducts()
  fetchCustomers()
})
</script>
