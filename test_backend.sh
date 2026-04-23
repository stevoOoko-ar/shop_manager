#!/bin/bash
# Test script for Shop Manager API
# Usage: ./test_backend.sh [backend_url]
# Example: ./test_backend.sh https://shop-manager-backend-xe9d.onrender.com

BACKEND_URL="${1:-https://shop-manager-backend-xe9d.onrender.com}"
echo "🧪 Testing Backend: $BACKEND_URL"
echo "=================================================="

# Test 1: GET Products (empty list expected)
echo -e "\n1️⃣ GET /products (list all products)"
echo "Command: curl -X GET $BACKEND_URL/products"
curl -s "$BACKEND_URL/products" | jq . || echo "Failed"

# Test 2: POST Product (create new)
echo -e "\n\n2️⃣ POST /products (add new product)"
PRODUCT_DATA='{
  "id": "TEST-001",
  "name": "Test Product",
  "buyingPrice": 10.0,
  "sellingPrice": 20.0,
  "quantity": 5,
  "lowStockThreshold": 2,
  "category": "Test"
}'
echo "Command: curl -X POST $BACKEND_URL/products"
echo "Body:"
echo "$PRODUCT_DATA" | jq .
echo ""
curl -s -X POST "$BACKEND_URL/products" \
  -H "Content-Type: application/json" \
  -d "$PRODUCT_DATA" | jq .

# Test 3: GET Products (should now have 1)
echo -e "\n\n3️⃣ GET /products (verify product was saved)"
echo "Command: curl -X GET $BACKEND_URL/products"
curl -s "$BACKEND_URL/products" | jq .

# Test 4: Test with extra field (isDeleted - should be ignored)
echo -e "\n\n4️⃣ POST /products (with extra 'isDeleted' field - should be ignored)"
PRODUCT_DATA_WITH_EXTRA='{
  "id": "TEST-002",
  "name": "Test Product 2",
  "buyingPrice": 15.0,
  "sellingPrice": 30.0,
  "quantity": 10,
  "lowStockThreshold": 3,
  "category": "Test",
  "isDeleted": 0
}'
echo "Body (with extra isDeleted field):"
echo "$PRODUCT_DATA_WITH_EXTRA" | jq .
echo ""
curl -s -X POST "$BACKEND_URL/products" \
  -H "Content-Type: application/json" \
  -d "$PRODUCT_DATA_WITH_EXTRA" | jq .

# Test 5: Test validation error (missing required field)
echo -e "\n\n5️⃣ POST /products (missing 'name' - should return 422)"
PRODUCT_DATA_INVALID='{
  "id": "TEST-003",
  "buyingPrice": 15.0,
  "sellingPrice": 30.0,
  "quantity": 10,
  "lowStockThreshold": 3
}'
echo "Body (missing 'name' field):"
echo "$PRODUCT_DATA_INVALID" | jq .
echo ""
echo "Expected: 422 Unprocessable Entity"
curl -s -X POST "$BACKEND_URL/products" \
  -H "Content-Type: application/json" \
  -d "$PRODUCT_DATA_INVALID" | jq .

echo -e "\n\n=================================================="
echo "✅ Testing complete!"
