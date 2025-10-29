# نظام إدارة متجر العطور

نظام متكامل لإدارة متجر العطور مبني باستخدام Vue.js و Laravel و MySQL

## المميزات

### إدارة المنتجات
- ✅ إضافة/تعديل/حذف المنتجات
- ✅ إدارة التصنيفات والعلامات التجارية
- ✅ نظام الباركود للمنتجات
- ✅ تتبع المخزون والتنبيهات

### نظام المبيعات والفواتير
- ✅ نقطة بيع POS سهلة الاستخدام
- ✅ إنشاء فواتير البيع
- ✅ طباعة الفواتير بأناقة
- ✅ إدارة العملاء
- ✅ تقارير المبيعات اليومية والشهرية

### إدارة المخزون
- ✅ تنبيهات نفاد المنتجات
- ✅ إشعارات الوصول للحد الأدنى
- ✅ سجل حركة المخزون
- ✅ تعديل المخزون

### التقارير والإحصائيات
- ✅ تقارير المبيعات والأرباح
- ✅ إحصائيات المنتجات الأكثر مبيعاً
- ✅ تقارير الأداء الشامل
- ✅ تقارير المخزون

### واجهة المستخدم
- ✅ تصميم عربي بالكامل
- ✅ واجهة سهلة الاستخدام
- ✅ دعم البحث والتصفية
- ✅ تصميم متجاوب

## التقنيات المستخدمة

### Backend
- Laravel 10
- MySQL
- Laravel Sanctum (Authentication)

### Frontend
- Vue.js 3
- TailwindCSS
- Pinia
- Vue Router
- Axios

## التثبيت والتشغيل

### Backend

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan db:seed
php artisan serve
```

### Frontend

```bash
cd frontend
npm install
npm run dev
```

## بيانات الدخول الافتراضية

- Email: admin@perfume.com
- Password: password

## الهيكل

```
parfumes/
├── backend/          # Laravel API
│   ├── app/
│   ├── database/
│   ├── routes/
│   └── ...
├── frontend/         # Vue.js App
│   ├── src/
│   ├── public/
│   └── ...
└── README.md
```

## الترخيص

MIT License
