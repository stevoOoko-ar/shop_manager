# Shop Manager Debugging Guide

## Problem Summary
- ✅ Products load (GET works)
- ❌ Adding products doesn't save (POST fails)
- Likely cause: Field validation error (422) due to extra `isDeleted` field

---

## Issues Found & Fixed

### Issue 1: Extra Field in Request ❌→✅
**Problem**: Flutter sends `isDeleted` field that FastAPI doesn't expect.

**Original Error**: 422 Unprocessable Entity
```json
{
  "detail": [
    {
      "type": "extra_forbidden",
      "loc": ["body", "isDeleted"],
      "msg": "Extra inputs are not permitted"
    }
  ]
}
```

**Fix Applied**: Updated Pydantic model to ignore extra fields
```python
class Product(BaseModel):
    model_config = ConfigDict(
        from_attributes=True,
        populate_by_name=True,
        ser_by_alias=False,
        extra='ignore'  # ✅ Added this line
    )
```

### Issue 2: No Logging/Error Visibility ❌→✅
**Problem**: Can't see what error the backend is returning.

**Fix Applied**: Added detailed logging to both Flutter and FastAPI:
- **Flutter**: Logs request body and response status/body to debug console
- **FastAPI**: Logs incoming requests and errors with emoji indicators

### Issue 3: SQLite on Render (Persistent Issue) ⚠️
**Problem**: Render's ephemeral filesystem means SQLite data is lost on app restart/redeploy.

**Current Status**: Using SQLite (data loss possible)
**Recommended**: Migrate to PostgreSQL (see below)

---

## Testing Your Endpoint

### Option 1: Quick Test with curl

```bash
# Make the backend URL executable in your terminal
BACKEND="https://shop-manager-backend-xe9d.onrender.com"

# 1. Test GET (check existing products)
curl -X GET "$BACKEND/products"

# 2. Test POST (add a product)
curl -X POST "$BACKEND/products" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "TEST-001",
    "name": "Test Product",
    "buyingPrice": 10.0,
    "sellingPrice": 20.0,
    "quantity": 5,
    "lowStockThreshold": 2,
    "category": "Test"
  }'

# 3. Verify product was saved
curl -X GET "$BACKEND/products"
```

### Option 2: Test Script (Automated)
```bash
chmod +x test_backend.sh
./test_backend.sh https://shop-manager-backend-xe9d.onrender.com
```

### Option 3: Postman (GUI)
1. Download Postman from https://www.postman.com/downloads/
2. Import the collection: `Shop_Manager_API.postman_collection.json`
3. Test each endpoint in the collection

---

## Reading Flutter Debug Output

After the fixes, your Flutter debug console should show:

**When Adding a Product:**
```
📤 POST https://shop-manager-backend-xe9d.onrender.com/products
   Body: {"id":"...", "name":"...", "buyingPrice":...}
📥 Response Status: 200
   Body: {"id":"...", "name":"...", ...}
✅ Success
```

**If There's an Error:**
```
📤 POST https://shop-manager-backend-xe9d.onrender.com/products
📥 Response Status: 422
   Body: {"detail":[{"type":"validation_error", ...}]}
❌ Error: [error details]
```

---

## Common FastAPI Error Codes

| Code | Meaning | Cause |
|------|---------|-------|
| **200** | ✅ Success | Product saved |
| **400** | ❌ Bad Request | Invalid data (e.g., quantity is negative) |
| **404** | ❌ Not Found | Product doesn't exist (for PUT/DELETE) |
| **422** | ❌ Validation Error | Missing/wrong field type or extra fields |
| **500** | ❌ Server Error | Backend crashed (check logs on Render) |

---

## Field Name Mapping: Flutter → FastAPI

The backend accepts **both** camelCase and snake_case:

| Flutter (Sent) | Backend Accepts |
|---|---|
| `buyingPrice` | ✅ `buyingPrice` or `buying_price` |
| `sellingPrice` | ✅ `sellingPrice` or `selling_price` |
| `lowStockThreshold` | ✅ `lowStockThreshold` or `low_stock_threshold` |
| `isDeleted` | ✅ Now **ignored** (not sent to DB) |

---

## Debugging Checklist

- [ ] Run `test_backend.sh` - verify basic connectivity
- [ ] Check Flutter debug console - look for error messages (📤📥❌)
- [ ] Use curl/Postman to test endpoint directly
- [ ] Check Render logs: https://dashboard.render.com → Logs
- [ ] Verify database file exists: `/home/steven/shop_manager/backend/shop_manager.db`
- [ ] Check if products appear in database after adding: `sqlite3 shop_manager.db "SELECT * FROM products;"`

---

## Next Steps

### 1. Deploy Backend Changes to Render
```bash
cd backend
git add app.py
git commit -m "Fix: Add extra='ignore' to Product model, add logging"
git push  # This should auto-deploy to Render
```

### 2. Rebuild Flutter APK
```bash
flutter build apk --release --dart-define=BACKEND_URL=https://shop-manager-backend-xe9d.onrender.com
```

### 3. Test in App
- Open Flutter app
- Try adding a product
- **Check debug console** for logs (in VS Code or Android Studio)

### 4. (Optional) Migrate to PostgreSQL
See "Database Persistence" section below.

---

## Database Persistence Issue & Solution

### Current Problem: SQLite on Render
Render has an **ephemeral filesystem** - files are deleted when the app:
- Restarts
- Redeploys
- Auto-sleeps (free tier)

Your `shop_manager.db` will be lost!

### Solution 1: Keep SQLite (Testing/Development Only)
- Works fine locally
- Will lose data on Render restart
- Only use for testing

### Solution 2: Migrate to PostgreSQL (Recommended for Production)

#### Step 1: Create PostgreSQL Database on Render
1. Go to https://dashboard.render.com
2. Click "New" → "PostgreSQL"
3. Name: `shop-manager-db`
4. Copy the `DATABASE_URL`

#### Step 2: Update Python Requirements
```bash
cd backend
pip install psycopg2-binary  # PostgreSQL driver
pip freeze > requirements.txt
```

#### Step 3: Update FastAPI Code
```python
# Replace:
DATABASE_URL = "sqlite:///./shop_manager.db"

# With:
DATABASE_URL = "postgresql://user:password@host:5432/shop_manager"
# (Use the Render-provided DATABASE_URL)
```

#### Step 4: Deploy
```bash
git add -A
git commit -m "Migrate to PostgreSQL"
git push  # Render auto-deploys
```

### Solution 3: Use Supabase (Easier PostgreSQL Alternative)
1. Create free account at https://supabase.com
2. Get connection string
3. Use same PostgreSQL migration as above

---

## Files Modified
- ✅ `backend/app.py` - Added `extra='ignore'` to Pydantic model, added logging
- ✅ `lib/services/backend_service.dart` - Added detailed logging
- ✅ `test_backend.sh` - New testing script
- ✅ `Shop_Manager_API.postman_collection.json` - Postman collection for testing

---

## Quick Reference

**To see what's happening:**
1. Open Flutter app's debug console
2. Add a product
3. Look for 📤📥 logs and error messages

**If POST still fails:**
1. Run `test_backend.sh` to test directly
2. Check backend logs on Render dashboard
3. Run: `sqlite3 backend/shop_manager.db "SELECT * FROM products;"` to verify DB

**If database isn't persisting:**
- Migrate to PostgreSQL (see section above)
