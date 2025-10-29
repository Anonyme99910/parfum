<template>
  <div class="space-y-6">
    <!-- Stats -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="card bg-gradient-to-br from-blue-500 to-blue-600 text-white">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-blue-100 text-sm">إجمالي المنتجات</p>
            <h3 class="text-3xl font-bold mt-2">{{ toLatinNumbers(inventoryStats.total_products || 0) }}</h3>
          </div>
          <Package :size="48" class="text-blue-200" />
        </div>
      </div>

      <div class="card bg-gradient-to-br from-yellow-500 to-yellow-600 text-white">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-yellow-100 text-sm">منتجات منخفضة</p>
            <h3 class="text-3xl font-bold mt-2">{{ toLatinNumbers(inventoryStats.low_stock_count || 0) }}</h3>
          </div>
          <AlertTriangle :size="48" class="text-yellow-200" />
        </div>
      </div>

      <div class="card bg-gradient-to-br from-green-500 to-green-600 text-white">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-green-100 text-sm">قيمة المخزون</p>
            <h3 class="text-2xl font-bold mt-2">{{ formatCurrencyLatin(inventoryStats.total_value || 0) }}</h3>
          </div>
          <DollarSign :size="48" class="text-green-200" />
        </div>
      </div>
    </div>

    <!-- Tabs and Add Button -->
    <div class="card">
      <div class="flex items-center justify-between mb-4">
        <div class="flex gap-2 w-full md:w-auto">
          <button
            @click="activeTab = 'all'"
            :class="['flex-1 text-center px-3 py-2 text-sm md:text-base rounded-lg font-semibold transition-colors', activeTab === 'all' ? 'bg-primary-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200']"
          >
            جميع المنتجات ({{ toLatinNumbers(allProducts.length) }})
          </button>
          <button
            @click="activeTab = 'low'"
            :class="['flex-1 text-center px-3 py-2 text-sm md:text-base rounded-lg font-semibold transition-colors', activeTab === 'low' ? 'bg-yellow-600 text-white' : 'bg-gray-100 text-gray-700 hover:bg-gray-200']"
          >
            منتجات منخفضة ({{ toLatinNumbers(lowStockProducts.length) }})
          </button>
        </div>
        <button @click="openAddModal" class="btn btn-primary flex items-center gap-2 whitespace-nowrap ml-2">
          <Plus :size="20" />
          إضافة منتج
        </button>
      </div>

      <!-- Products Table -->
      <div class="overflow-x-auto">
        <table class="table">
          <thead>
            <tr>
              <th>المنتج</th>
              <th>التصنيف</th>
              <th>العلامة التجارية</th>
              <th>السعر</th>
              <th>الكمية الحالية</th>
              <th>الحد الأدنى</th>
              <th>الإجراءات</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="product in displayedProducts" :key="product.id">
              <td>
                <div>
                  <p class="font-medium">{{ product.name_ar }}</p>
                  <p class="text-xs text-gray-500">{{ product.size }}</p>
                </div>
              </td>
              <td>{{ product.category?.name_ar }}</td>
              <td>{{ product.brand?.name_ar }}</td>
              <td class="font-bold text-green-600">{{ formatCurrencyLatin(product.selling_price) }}</td>
              <td>
                <span
                  :class="[
                    'badge',
                    product.stock_quantity === 0 ? 'badge-danger' : 
                    product.stock_quantity <= product.min_stock_level ? 'badge-warning' : 
                    'badge-success'
                  ]"
                >
                  {{ toLatinNumbers(product.stock_quantity) }} قطعة
                </span>
              </td>
              <td>{{ toLatinNumbers(product.min_stock_level) }} قطعة</td>
              <td>
                <div class="flex items-center gap-2">
                  <button @click="openAdjustModal(product)" class="text-blue-600 hover:text-blue-800">
                    <Edit :size="18" />
                  </button>
                  <button @click="openEditModal(product)" class="text-green-600 hover:text-green-800">
                    <Settings :size="18" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Adjust Stock Modal -->
    <div v-if="adjustingProduct" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50" @click.self="adjustingProduct = null">
      <div class="bg-white rounded-xl p-6 w-full max-w-md">
        <h3 class="text-2xl font-bold mb-6">تعديل مخزون: {{ adjustingProduct.name_ar }}</h3>
        
        <form @submit.prevent="submitAdjustment" class="space-y-4">
          <div>
            <label class="block text-sm font-medium mb-2">نوع العملية</label>
            <select v-model="adjustmentForm.type" required class="input">
              <option value="in">إضافة للمخزون</option>
              <option value="out">خصم من المخزون</option>
              <option value="adjustment">تعديل المخزون</option>
            </select>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">الكمية</label>
            <input v-model.number="adjustmentForm.quantity" type="number" required class="input" />
            <p class="text-sm text-gray-500 mt-1">
              المخزون الحالي: {{ toLatinNumbers(adjustingProduct.stock_quantity) }}
            </p>
          </div>

          <div>
            <label class="block text-sm font-medium mb-2">ملاحظات</label>
            <textarea v-model="adjustmentForm.notes" rows="3" class="input"></textarea>
          </div>
          
          <div class="flex gap-3 justify-end mt-6">
            <button type="button" @click="adjustingProduct = null" class="btn btn-secondary">إلغاء</button>
            <button type="submit" class="btn btn-primary">تأكيد</button>
          </div>
        </form>
      </div>
    </div>

    <!-- Add/Edit Product Modal -->
    <div v-if="showProductModal" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 overflow-y-auto" @click.self="closeProductModal">
      <div class="bg-white rounded-xl p-6 w-full max-w-2xl m-4 max-h-[90vh] overflow-y-auto">
        <h3 class="text-2xl font-bold mb-6">{{ editingProduct ? 'تعديل منتج' : 'إضافة منتج جديد' }}</h3>
        
        <form @submit.prevent="submitProduct" class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium mb-2">الاسم بالعربية *</label>
              <input v-model="productForm.name_ar" type="text" required class="input" />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">الاسم بالإنجليزية *</label>
              <input v-model="productForm.name" type="text" required class="input" />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">الباركود *</label>
              <input v-model="productForm.barcode" type="text" required class="input" />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">SKU *</label>
              <input v-model="productForm.sku" type="text" required class="input" />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">التصنيف *</label>
              <select v-model="productForm.category_id" required class="input">
                <option value="">اختر التصنيف</option>
                <option v-for="cat in categories" :key="cat.id" :value="cat.id">{{ cat.name_ar }}</option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">العلامة التجارية *</label>
              <select v-model="productForm.brand_id" required class="input">
                <option value="">اختر العلامة</option>
                <option v-for="brand in brands" :key="brand.id" :value="brand.id">{{ brand.name_ar }}</option>
              </select>
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">سعر التكلفة *</label>
              <input v-model.number="productForm.cost_price" type="number" step="0.01" required class="input" />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">سعر البيع *</label>
              <input v-model.number="productForm.selling_price" type="number" step="0.01" required class="input" />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">الكمية *</label>
              <input v-model.number="productForm.stock_quantity" type="number" required class="input" />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">الحد الأدنى *</label>
              <input v-model.number="productForm.min_stock_level" type="number" required class="input" />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">الحجم</label>
              <input v-model="productForm.size" type="text" class="input" placeholder="100ml" />
            </div>
            <div>
              <label class="block text-sm font-medium mb-2">الحالة</label>
              <select v-model="productForm.is_active" class="input">
                <option :value="true">نشط</option>
                <option :value="false">غير نشط</option>
              </select>
            </div>
          </div>
          
          <div class="flex gap-3 justify-end mt-6">
            <button type="button" @click="closeProductModal" class="btn btn-secondary">إلغاء</button>
            <button type="submit" class="btn btn-primary">{{ editingProduct ? 'تحديث' : 'إضافة' }}</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Package, AlertTriangle, DollarSign, Plus, Edit, Settings } from 'lucide-vue-next'
import api from '@/services/api'
import { useToast } from 'vue-toastification'
import { toLatinNumbers, formatCurrencyLatin } from '@/utils/numbers'

const toast = useToast()
const allProducts = ref([])
const lowStockProducts = ref([])
const inventoryStats = ref({})
const categories = ref([])
const brands = ref([])
const activeTab = ref('all')
const adjustingProduct = ref(null)
const showProductModal = ref(false)
const editingProduct = ref(null)

const adjustmentForm = ref({
  type: 'in',
  quantity: 0,
  notes: ''
})

const productForm = ref({
  name: '',
  name_ar: '',
  barcode: '',
  sku: '',
  category_id: '',
  brand_id: '',
  cost_price: 0,
  selling_price: 0,
  stock_quantity: 0,
  min_stock_level: 10,
  size: '',
  is_active: true
})

const displayedProducts = computed(() => {
  return activeTab.value === 'all' ? allProducts.value : lowStockProducts.value
})


const fetchAllProducts = async () => {
  try {
    const response = await api.getProducts({ per_page: 1000 })
    allProducts.value = response.data.data || response.data || []
  } catch (error) {
    console.error('Failed to load products:', error)
    allProducts.value = []
  }
}

const fetchLowStockProducts = async () => {
  try {
    const response = await api.getLowStockProducts()
    lowStockProducts.value = response.data.data || response.data || []
  } catch (error) {
    console.error('Failed to load low stock products:', error)
    lowStockProducts.value = []
  }
}

const fetchInventoryStats = async () => {
  try {
    const response = await api.getInventoryReport()
    inventoryStats.value = response.data.summary
  } catch (error) {
    toast.error('فشل تحميل الإحصائيات')
  }
}

const fetchCategories = async () => {
  try {
    const response = await api.getCategories()
    categories.value = response.data.data || response.data || []
  } catch (error) {
    console.error('Failed to load categories:', error)
    categories.value = []
  }
}

const fetchBrands = async () => {
  try {
    const response = await api.getBrands()
    brands.value = response.data.data || response.data || []
  } catch (error) {
    console.error('Failed to load brands:', error)
    brands.value = []
  }
}

const openAdjustModal = (product) => {
  adjustingProduct.value = product
  adjustmentForm.value = {
    type: 'in',
    quantity: 0,
    notes: ''
  }
}

const openAddModal = () => {
  editingProduct.value = null
  productForm.value = {
    name: '',
    name_ar: '',
    barcode: '',
    sku: '',
    category_id: '',
    brand_id: '',
    cost_price: 0,
    selling_price: 0,
    stock_quantity: 0,
    min_stock_level: 10,
    size: '',
    is_active: true
  }
  showProductModal.value = true
}

const openEditModal = (product) => {
  editingProduct.value = product
  productForm.value = { ...product }
  showProductModal.value = true
}

const closeProductModal = () => {
  showProductModal.value = false
  editingProduct.value = null
}

const submitProduct = async () => {
  try {
    if (editingProduct.value) {
      await api.updateProduct(editingProduct.value.id, productForm.value)
      toast.success('تم تحديث المنتج بنجاح')
    } else {
      await api.createProduct(productForm.value)
      toast.success('تم إضافة المنتج بنجاح')
    }
    closeProductModal()
    fetchAllProducts()
    fetchLowStockProducts()
    fetchInventoryStats()
  } catch (error) {
    toast.error('حدث خطأ أثناء الحفظ')
  }
}

const submitAdjustment = async () => {
  try {
    await api.adjustStock(adjustingProduct.value.id, adjustmentForm.value)
    toast.success('تم تعديل المخزون بنجاح')
    adjustingProduct.value = null
    fetchAllProducts()
    fetchLowStockProducts()
    fetchInventoryStats()
  } catch (error) {
    toast.error(error.response?.data?.error || 'فشل تعديل المخزون')
  }
}

onMounted(() => {
  fetchAllProducts()
  fetchLowStockProducts()
  fetchInventoryStats()
  fetchCategories()
  fetchBrands()
})
</script>
