<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-2xl font-bold text-gray-900">الأدوار والصلاحيات</h2>
        <p class="text-gray-500 mt-1">إدارة أدوار المستخدمين وصلاحياتهم</p>
      </div>
    </div>

    <div class="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
      <div
        v-for="role in roles"
        :key="role.id"
        class="card hover:shadow-lg transition-shadow"
      >
        <div class="flex items-center justify-between mb-4">
          <div class="w-12 h-12 rounded-full bg-primary-100 flex items-center justify-center">
            <svg class="w-6 h-6 text-primary-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
          </div>
        </div>
        
        <h3 class="text-xl font-bold text-gray-900 mb-2">{{ role.name_ar }}</h3>
        <p class="text-sm text-gray-500 mb-4">{{ role.name }}</p>
        
        <div class="space-y-2">
          <p class="text-xs font-medium text-gray-700">الصلاحيات:</p>
          <div class="flex flex-wrap gap-1">
            <span 
              v-for="(permission, index) in role.permissions" 
              :key="index"
              class="badge badge-primary text-xs"
            >
              {{ translatePermission(permission) }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import api from '@/services/api'
import { useToast } from 'vue-toastification'

const toast = useToast()
const roles = ref([])

const translatePermission = (permission) => {
  const translations = {
    'all': 'جميع الصلاحيات',
    'sales': 'المبيعات',
    'customers': 'العملاء',
    'reports': 'التقارير',
    'products': 'المنتجات',
    'inventory': 'المخزون'
  }
  return translations[permission] || permission
}

onMounted(async () => {
  try {
    const res = await api.getRoles()
    roles.value = res.data || []
  } catch (error) {
    console.error('Failed to load roles:', error)
    toast.error('فشل تحميل الأدوار')
    roles.value = []
  }
})
</script>
