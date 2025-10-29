import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/Login.vue'),
    meta: { guest: true }
  },
  {
    path: '/',
    component: () => import('@/layouts/MainLayout.vue'),
    meta: { requiresAuth: true },
    children: [
      {
        path: '',
        name: 'Dashboard',
        component: () => import('@/views/Dashboard.vue')
      },
      {
        path: 'clients',
        name: 'Clients',
        component: () => import('@/views/Customers.vue')
      },
      {
        path: 'clients/:id',
        name: 'ClientDetails',
        component: () => import('@/views/ClientDetails.vue')
      },
      {
        path: 'employees',
        name: 'Employees',
        component: () => import('@/views/Employees.vue')
      },
      {
        path: 'roles',
        name: 'Roles',
        component: () => import('@/views/Roles.vue')
      },
      {
        path: 'pos',
        name: 'POS',
        component: () => import('@/views/POS.vue')
      },
      {
        path: 'inventory',
        name: 'Inventory',
        component: () => import('@/views/Inventory.vue')
      },
      {
        path: 'invoices',
        name: 'Invoices',
        component: () => import('@/views/Invoices/InvoicesList.vue')
      },
      {
        path: 'invoices/:id',
        name: 'InvoiceDetail',
        component: () => import('@/views/Invoices/InvoiceDetail.vue')
      },
      {
        path: 'stock',
        name: 'Stock',
        component: () => import('@/views/Stock/StockList.vue')
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory('/parfumes/'),
  routes
})

router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next('/login')
  } else if (to.meta.guest && authStore.isAuthenticated) {
    next('/')
  } else {
    next()
  }
})

export default router
