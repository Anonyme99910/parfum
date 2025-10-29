# Authentication Route Fix

## ✅ Problem Fixed

**Error:** `Route [login] not defined`

**Cause:** Laravel's authentication middleware was trying to redirect unauthenticated requests to a named route called 'login', but the route wasn't named in the API routes file.

---

## 🔧 What Was Fixed

### 1. Named the Login Route

**File:** `backend/routes/api.php`

**Before:**
```php
Route::post('/login', [AuthController::class, 'login']);
```

**After:**
```php
Route::post('/login', [AuthController::class, 'login'])->name('login');
```

**Why:** Laravel's `auth:sanctum` middleware needs a named 'login' route to redirect unauthenticated users.

### 2. Added API Exception Handler

**File:** `backend/app/Exceptions/Handler.php`

**Added:**
```php
protected function unauthenticated($request, \Illuminate\Auth\AuthenticationException $exception)
{
    return $request->expectsJson()
        ? response()->json(['message' => 'Unauthenticated.'], 401)
        : redirect()->guest(route('login'));
}
```

**Why:** 
- For API requests (with `Accept: application/json`), return JSON error instead of redirect
- For web requests, redirect to login page
- This prevents the "Route [login] not defined" error for API calls

### 3. Updated PDF Download Method

**File:** `frontend/src/services/api.js`

**Before:**
```javascript
downloadInvoicePdf: (id) => {
  const token = localStorage.getItem('token')
  window.open(`http://localhost/parfumes/backend/public/api/sales/${id}/pdf?token=${token}`, '_blank')
}
```

**After:**
```javascript
downloadInvoicePdf: async (id) => {
  const response = await api.get(`/sales/${id}/pdf`, {
    responseType: 'blob',
    headers: { Accept: 'application/pdf' }
  })
  const blob = new Blob([response.data], { type: 'application/pdf' })
  const url = window.URL.createObjectURL(blob)
  window.open(url, '_blank')
}
```

**Why:**
- Uses Axios with Authorization header (automatically added by interceptor)
- Downloads PDF as blob instead of opening URL directly
- Avoids authentication issues with direct URL access

---

## 🎯 How It Works Now

### Authentication Flow

1. **User logs in** → Token stored in localStorage
2. **API requests** → Axios interceptor adds `Authorization: Bearer {token}` header
3. **If token invalid/missing:**
   - API requests → Return JSON `{"message": "Unauthenticated."}` with 401 status
   - Axios interceptor catches 401 → Redirects to `/login` page
4. **If token valid** → Request proceeds normally

### PDF Download Flow

1. **User completes sale** in POS
2. **Clicks "تحميل الفاتورة PDF"**
3. **Frontend calls** `api.downloadInvoicePdf(saleId)`
4. **Axios sends** GET request to `/api/sales/{id}/pdf` with:
   - `Authorization: Bearer {token}` header
   - `Accept: application/pdf` header
   - `responseType: 'blob'`
5. **Backend validates** token via `auth:sanctum` middleware
6. **If authenticated:**
   - Generates PDF using DomPDF
   - Returns PDF file
7. **Frontend receives** blob data
8. **Creates** blob URL and opens in new tab
9. **User downloads/prints** PDF

---

## ✅ What's Fixed

### Before
- ❌ "Route [login] not defined" error
- ❌ PDF download failed with authentication error
- ❌ API redirected to non-existent login route

### After
- ✅ Named login route exists
- ✅ API returns JSON errors for unauthenticated requests
- ✅ PDF downloads successfully with proper authentication
- ✅ No more route errors

---

## 🧪 Testing

### Test Authentication

1. **Logout** from the app
2. **Try to access** protected route (e.g., `/dashboard`)
3. **Should redirect** to `/login` page
4. **Login** with credentials
5. **Should redirect** to dashboard

### Test PDF Download

1. **Login** to the app
2. **Go to POS**
3. **Create a sale**
4. **Click "تحميل الفاتورة PDF"**
5. **PDF should open** in new tab
6. **No errors** should appear

### Test API Error Handling

1. **Open browser console**
2. **Clear localStorage** (to remove token)
3. **Try to access** any protected page
4. **Should see** 401 error in console
5. **Should redirect** to login page

---

## 📁 Files Modified

### Backend

**Modified:**
- `backend/routes/api.php` - Named login route
- `backend/app/Exceptions/Handler.php` - Added unauthenticated handler

### Frontend

**Modified:**
- `frontend/src/services/api.js` - Updated PDF download method

**Deployed:**
- Frontend build copied to `backend/public/`

---

## 🔒 Security Notes

### Token Handling

- ✅ Token stored in localStorage (client-side)
- ✅ Token sent in Authorization header (not URL)
- ✅ Token validated by Sanctum middleware
- ✅ Token removed on logout

### API Security

- ✅ All protected routes require authentication
- ✅ Unauthenticated requests return 401 JSON error
- ✅ No sensitive data in error messages
- ✅ CORS configured for localhost

### PDF Security

- ✅ PDF generation requires authentication
- ✅ Users can only download their own sales (if implemented)
- ✅ No direct URL access without token
- ✅ Blob URLs are temporary and client-side only

---

## 🚀 Production Considerations

### Before Deploying to Production

1. **Update CORS settings** in `backend/config/cors.php`
   - Change `allowed_origins` from `['*']` to specific domains
   
2. **Update API base URL** in `frontend/src/services/api.js`
   - Change from `http://localhost/parfumes/backend/public/api`
   - To production URL (e.g., `https://yourdomain.com/api`)

3. **Enable HTTPS**
   - Use SSL certificate
   - Force HTTPS in Laravel config

4. **Set secure session cookies**
   - Update `backend/config/session.php`
   - Set `secure` to `true`
   - Set `same_site` to `strict`

5. **Update .env file**
   - Set `APP_ENV=production`
   - Set `APP_DEBUG=false`
   - Use strong `APP_KEY`
   - Update database credentials

---

## 📝 Summary

**Problem:** Route [login] not defined error when accessing protected routes

**Root Cause:** 
1. Login route wasn't named in API routes
2. Exception handler didn't handle API authentication errors properly
3. PDF download used direct URL without proper authentication

**Solution:**
1. Named the login route
2. Added API exception handler for authentication errors
3. Updated PDF download to use Axios with Authorization header

**Result:**
- ✅ No more route errors
- ✅ Proper API error handling
- ✅ PDF downloads work correctly
- ✅ Authentication flow works as expected

**Status:** 🟢 **Fixed and Deployed**

---

**End of Documentation**
