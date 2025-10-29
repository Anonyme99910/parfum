<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-2xl font-bold">بيانات العميل</h2>
        <p class="text-gray-500">عرض معلومات العميل وتاريخ المشتريات</p>
      </div>
      <router-link to="/clients" class="btn btn-secondary">عودة للعملاء</router-link>
    </div>

    <!-- Client Info -->
    <div class="card">
      <div class="grid sm:grid-cols-2 gap-4">
        <div>
          <p class="text-sm text-gray-500">الاسم</p>
          <p class="font-medium text-lg">{{ client?.name }}</p>
        </div>
        <div>
          <p class="text-sm text-gray-500">الهاتف</p>
          <p class="font-medium font-mono text-lg">{{ toLatinNumbers(client?.phone) }}</p>
        </div>
        <div>
          <p class="text-sm text-gray-500">العنوان</p>
          <p class="font-medium">{{ client?.address || '-' }}</p>
        </div>
        <div>
          <p class="text-sm text-gray-500">إجمالي المشتريات</p>
          <p class="font-medium text-green-600 text-lg">{{ formatCurrencyLatin(client?.total_purchases || 0) }}</p>
        </div>
        <div>
          <p class="text-sm text-gray-500">عدد الطلبات</p>
          <p class="font-medium text-lg">{{ toLatinNumbers(client?.total_orders || 0) }}</p>
        </div>
      </div>
    </div>

    <!-- Purchase History -->
    <div class="card overflow-hidden">
      <h3 class="text-lg font-bold mb-4">سجل المشتريات</h3>
      <table class="table">
        <thead>
          <tr>
            <th>رقم الفاتورة</th>
            <th>التاريخ</th>
            <th>المنتجات</th>
            <th>الإجمالي</th>
            <th>الحالة</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="s in client?.sales || []" :key="s.id">
            <td>{{ s.invoice_number }}</td>
            <td>{{ formatDate(s.created_at) }}</td>
            <td>
              <ul class="list-disc pr-5">
                <li v-for="i in s.items" :key="i.id">{{ i.product?.name }} × {{ toLatinNumbers(i.quantity) }}</li>
              </ul>
            </td>
            <td class="font-bold">{{ formatCurrencyLatin(s.total) }}</td>
            <td>
              <span :class="['px-2 py-1 text-xs rounded-full', s.status === 'completed' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800']">
                {{ s.status === 'completed' ? 'مكتملة' : 'ملغاة' }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import api from '@/services/api'
import { toLatinNumbers, formatCurrencyLatin } from '@/utils/numbers'

const route = useRoute()
const client = ref(null)

const formatDate = (v) => toLatinNumbers(new Date(v).toLocaleString('en-EG'))

onMounted(async () => {
  const { id } = route.params
  const res = await api.getCustomer(id)
  client.value = res.data
})
</script>
