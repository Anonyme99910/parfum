<template>
  <div class="stock-container">
    <div class="header">
      <h1>إدارة المخزون</h1>
      <button @click="showAdjustModal = true" class="btn-primary">
        <Plus :size="18" />
        تعديل المخزون
      </button>
    </div>

    <!-- Filters -->
    <div class="filters">
      <input 
        v-model="filters.search" 
        type="text" 
        placeholder="بحث بالاسم أو SKU..."
        class="search-input"
        @input="loadStock"
      >
      <label class="checkbox-label">
        <input type="checkbox" v-model="filters.lowStock" @change="loadStock">
        <span>عرض المنتجات منخفضة المخزون فقط</span>
        <span v-if="lowStockCount > 0" class="badge-danger">{{ lowStockCount }}</span>
      </label>
    </div>

    <!-- Table -->
    <div class="table-container">
      <table>
        <thead>
          <tr>
            <th>SKU</th>
            <th>المنتج</th>
            <th>الفئة</th>
            <th>الكمية المتاحة</th>
            <th>محجوز</th>
            <th>المتاح للبيع</th>
            <th>حد إعادة الطلب</th>
            <th>الحالة</th>
            <th>الإجراءات</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="product in products" :key="product.id">
            <td>{{ product.sku }}</td>
            <td>{{ product.name_ar }}</td>
            <td>{{ product.category?.name_ar }}</td>
            <td>{{ product.stock_quantity }}</td>
            <td>{{ product.reserved_qty }}</td>
            <td :class="{ 'text-danger': product.available_qty <= 0 }">
              {{ product.available_qty }}
            </td>
            <td>{{ product.min_stock_level }}</td>
            <td>
              <span 
                :class="['status-badge', getStockStatus(product)]"
              >
                {{ getStockStatusLabel(product) }}
              </span>
            </td>
            <td class="actions">
              <button 
                @click="openAdjustModal(product)" 
                class="btn-icon" 
                title="تعديل"
              >
                <Edit :size="18" />
              </button>
              <button 
                @click="viewMovements(product)" 
                class="btn-icon" 
                title="الحركات"
              >
                <History :size="18" />
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Adjust Stock Modal -->
    <div v-if="showAdjustModal" class="modal-overlay" @click="showAdjustModal = false">
      <div class="modal" @click.stop>
        <div class="modal-header">
          <h3>تعديل المخزون</h3>
          <button @click="showAdjustModal = false" class="btn-close">×</button>
        </div>
        <div class="modal-body">
          <div class="form-group" v-if="!selectedProduct">
            <label>المنتج *</label>
            <select v-model="adjustForm.product_id">
              <option value="">اختر المنتج</option>
              <option v-for="p in allProducts" :key="p.id" :value="p.id">
                {{ p.name_ar }} ({{ p.sku }})
              </option>
            </select>
          </div>
          <div v-else class="selected-product">
            <strong>{{ selectedProduct.name_ar }}</strong>
            <span>المخزون الحالي: {{ selectedProduct.stock_quantity }}</span>
          </div>
          <div class="form-group">
            <label>الكمية * (استخدم + للإضافة أو - للطرح)</label>
            <input 
              v-model.number="adjustForm.quantity" 
              type="number" 
              placeholder="مثال: +10 أو -5"
            >
          </div>
          <div class="form-group">
            <label>السبب *</label>
            <textarea 
              v-model="adjustForm.note" 
              rows="3" 
              placeholder="اذكر سبب التعديل..."
              required
            ></textarea>
          </div>
        </div>
        <div class="modal-footer">
          <button @click="showAdjustModal = false" class="btn-secondary">إلغاء</button>
          <button @click="adjustStock" class="btn-primary">حفظ</button>
        </div>
      </div>
    </div>

    <!-- Movements Modal -->
    <div v-if="showMovementsModal" class="modal-overlay" @click="showMovementsModal = false">
      <div class="modal modal-large" @click.stop>
        <div class="modal-header">
          <h3>حركات المخزون - {{ selectedProduct?.name_ar }}</h3>
          <button @click="showMovementsModal = false" class="btn-close">×</button>
        </div>
        <div class="modal-body">
          <table>
            <thead>
              <tr>
                <th>التاريخ</th>
                <th>النوع</th>
                <th>الكمية</th>
                <th>المخزون السابق</th>
                <th>المخزون الجديد</th>
                <th>الملاحظات</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="movement in movements" :key="movement.id">
                <td>{{ formatDateTime(movement.moved_at || movement.created_at) }}</td>
                <td>{{ getMovementTypeLabel(movement.type) }}</td>
                <td :class="movement.quantity > 0 ? 'text-success' : 'text-danger'">
                  {{ movement.quantity > 0 ? '+' : '' }}{{ movement.quantity }}
                </td>
                <td>{{ movement.previous_stock }}</td>
                <td>{{ movement.new_stock }}</td>
                <td>{{ movement.notes || movement.note || '-' }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Plus, Edit, History } from 'lucide-vue-next'
import api from '../../services/api'
import { useToast } from 'vue-toastification'

const toast = useToast()

const products = ref([])
const allProducts = ref([])
const movements = ref([])
const lowStockCount = ref(0)
const showAdjustModal = ref(false)
const showMovementsModal = ref(false)
const selectedProduct = ref(null)

const filters = ref({
  search: '',
  lowStock: false
})

const adjustForm = ref({
  product_id: '',
  quantity: 0,
  note: ''
})

const loadStock = async () => {
  try {
    const params = {
      search: filters.value.search || undefined,
      low_stock: filters.value.lowStock || undefined
    }
    const response = await api.getStock(params)
    products.value = response.data.products.data
    lowStockCount.value = response.data.low_stock_count
  } catch (error) {
    toast.error('فشل تحميل المخزون')
    console.error(error)
  }
}

const loadAllProducts = async () => {
  try {
    const response = await api.getProducts()
    allProducts.value = response.data.data || response.data
  } catch (error) {
    console.error('Failed to load products:', error)
  }
}

const openAdjustModal = (product) => {
  selectedProduct.value = product
  adjustForm.value = {
    product_id: product.id,
    quantity: 0,
    note: ''
  }
  showAdjustModal.value = true
}

const adjustStock = async () => {
  if (!adjustForm.value.product_id) {
    toast.error('الرجاء اختيار المنتج')
    return
  }

  if (!adjustForm.value.quantity || adjustForm.value.quantity === 0) {
    toast.error('الرجاء إدخال كمية صحيحة')
    return
  }

  if (!adjustForm.value.note) {
    toast.error('الرجاء إدخال سبب التعديل')
    return
  }

  try {
    await api.adjustStock(adjustForm.value)
    toast.success('تم تعديل المخزون بنجاح')
    showAdjustModal.value = false
    selectedProduct.value = null
    adjustForm.value = {
      product_id: '',
      quantity: 0,
      note: ''
    }
    loadStock()
  } catch (error) {
    toast.error('فشل تعديل المخزون')
    console.error(error)
  }
}

const viewMovements = async (product) => {
  selectedProduct.value = product
  try {
    const response = await api.getStockMovements({ product_id: product.id })
    movements.value = response.data.data || response.data
    showMovementsModal.value = true
  } catch (error) {
    toast.error('فشل تحميل الحركات')
    console.error(error)
  }
}

const getStockStatus = (product) => {
  if (product.available_qty <= 0) return 'out'
  if (product.stock_quantity <= product.min_stock_level) return 'low'
  return 'ok'
}

const getStockStatusLabel = (product) => {
  const status = getStockStatus(product)
  const labels = {
    out: 'نفذ',
    low: 'منخفض',
    ok: 'متوفر'
  }
  return labels[status]
}

const getMovementTypeLabel = (type) => {
  const labels = {
    sale: 'بيع',
    return: 'إرجاع',
    manual_adjust: 'تعديل يدوي',
    purchase: 'شراء',
    reserve: 'حجز',
    release: 'إطلاق'
  }
  return labels[type] || type
}

const formatDateTime = (date) => {
  return new Date(date).toLocaleString('ar-EG')
}

onMounted(() => {
  loadStock()
  loadAllProducts()
})
</script>

<style scoped>
.stock-container {
  padding: 20px;
  direction: rtl;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.header h1 {
  font-size: 24px;
  color: #1e293b;
}

.filters {
  display: flex;
  gap: 15px;
  margin-bottom: 20px;
  align-items: center;
}

.search-input {
  flex: 1;
  padding: 8px 12px;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  font-size: 14px;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}

.badge-danger {
  background: #ef4444;
  color: white;
  padding: 2px 8px;
  border-radius: 12px;
  font-size: 12px;
}

.table-container {
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

table {
  width: 100%;
  border-collapse: collapse;
}

th {
  background: #f8fafc;
  padding: 12px;
  text-align: right;
  font-weight: 600;
  color: #475569;
  border-bottom: 2px solid #e2e8f0;
}

td {
  padding: 12px;
  border-bottom: 1px solid #f1f5f9;
}

.text-danger {
  color: #dc2626;
  font-weight: 600;
}

.text-success {
  color: #059669;
}

.status-badge {
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 500;
}

.status-badge.ok {
  background: #d1fae5;
  color: #065f46;
}

.status-badge.low {
  background: #fef3c7;
  color: #92400e;
}

.status-badge.out {
  background: #fee2e2;
  color: #991b1b;
}

.actions {
  display: flex;
  gap: 8px;
}

.btn-icon {
  padding: 6px;
  background: #f1f5f9;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-icon:hover {
  background: #e2e8f0;
}

.btn-primary,
.btn-secondary {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 14px;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.2s;
}

.btn-primary {
  background: #3b82f6;
  color: white;
}

.btn-primary:hover {
  background: #2563eb;
}

.btn-secondary {
  background: #f1f5f9;
  color: #475569;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal {
  background: white;
  border-radius: 8px;
  width: 90%;
  max-width: 500px;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-large {
  max-width: 800px;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #e2e8f0;
}

.modal-header h3 {
  margin: 0;
  font-size: 18px;
}

.btn-close {
  background: none;
  border: none;
  font-size: 24px;
  cursor: pointer;
  color: #64748b;
}

.modal-body {
  padding: 20px;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding: 20px;
  border-top: 1px solid #e2e8f0;
}

.form-group {
  margin-bottom: 15px;
}

.form-group label {
  display: block;
  margin-bottom: 5px;
  font-size: 14px;
  font-weight: 500;
  color: #475569;
}

.form-group input,
.form-group select,
.form-group textarea {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  font-size: 14px;
}

.selected-product {
  background: #f8fafc;
  padding: 15px;
  border-radius: 6px;
  margin-bottom: 15px;
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.selected-product strong {
  font-size: 16px;
  color: #1e293b;
}

.selected-product span {
  font-size: 14px;
  color: #64748b;
}
</style>
