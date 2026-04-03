# Backend API Contract (App + Admin)

This file is designed for Copilot prompts and implementation consistency.

## Base
- Base URL: `APP_API_BASE_URL`
- Auth: `Authorization: Bearer <supabase_access_token>` for user/admin endpoints
- Content type: `application/json`

## Health
- `GET /health`
- Response: `{ ok: true, service, ts }`

## Checkout
- `POST /api/shipping/quote`
- Body:
```json
{
  "destinationCountry": "US",
  "currency": "USD",
  "items": [
    { "productId": "p1", "productName": "Serum", "quantity": 1, "unitPrice": 29.99, "weightKg": 0.4 }
  ]
}
```
- Response:
```json
{
  "provider": "dhl",
  "service": "DHL Express Worldwide",
  "amount": 18.2,
  "currency": "USD",
  "etaDays": "2026-04-05T12:00:00Z",
  "packageWeightKg": 0.4
}
```

- `POST /api/checkout/initialize` (auth required)
- Body:
```json
{
  "currency": "USD",
  "items": [
    { "productId": "p1", "productName": "Serum", "quantity": 1, "unitPrice": 29.99, "weightKg": 0.4 }
  ],
  "shippingAddress": {
    "country": "US",
    "city": "San Francisco",
    "addressLine1": "1 Market St",
    "postalCode": "94105"
  }
}
```
- Response includes `authorizationUrl` and `reference`.

- `POST /api/checkout/verify` (auth required)
- Body: `{ "reference": "DLX-..." }`
- Response: `{ "paid": true|false, "status": "success|...", "reference": "..." }`

## Orders
- `GET /api/orders/me` (auth required)
- Response:
```json
{
  "orders": [
    {
      "id": "...",
      "order_number": "DLX-...",
      "created_at": "...",
      "total": 49.99,
      "status": "processing",
      "order_items": [{ "product_name": "Serum", "quantity": 1 }]
    }
  ]
}
```

## Uploads
- `POST /api/uploads/sign` (auth required)
- Body:
```json
{
  "fileName": "receipt.jpg",
  "contentType": "image/jpeg",
  "folder": "receipts",
  "bucket": "product-images"
}
```
- Response:
```json
{
  "bucket": "product-images",
  "path": "receipts/<userId>/..._receipt.jpg",
  "token": "...",
  "signedUrl": "https://...",
  "publicUrl": "https://...",
  "contentType": "image/jpeg"
}
```

## Admin
Admin authorization is granted if one of these is true:
- `app_metadata.role == "admin"`
- `user_metadata.role == "admin"`
- `profiles.role == "admin"`
- `profiles.is_admin == true`

- `GET /api/admin/orders?status=processing&limit=50` (auth + admin)
- `PATCH /api/admin/orders/:orderId/status` (auth + admin)
- Body: `{ "status": "shipped" }`

- `GET /api/admin/products?limit=100` (auth + admin)
- `POST /api/admin/products` (auth + admin)
- `PATCH /api/admin/products/:productId` (auth + admin)

Allowed order statuses:
- `pending_payment`
- `processing`
- `shipped`
- `delivered`
- `cancelled`

## Required Environment Variables
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `PAYSTACK_SECRET_KEY`
- `DHL_SUBSCRIPTION_KEY` (for international rates)
- `DHL_API_BASE_URL`
- `DHL_ORIGIN_COUNTRY`
- `SUPABASE_STORAGE_BUCKET`
- `APP_API_PORT`
- `PAYSTACK_CALLBACK_URL`
- `CORS_ORIGINS`

## Notes For Copilot
- Do not trust client totals; recompute totals on server.
- Validate auth token on every non-public route.
- Return consistent error shape: `{ "error": "..." }`.
- Keep admin checks centralized in one helper.
- Prefer idempotent verify/update behavior for payment callbacks.
