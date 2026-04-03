# Copilot Prompts For Backend API Work

Use these prompts directly in Copilot Chat when extending `backend/src/server.js`.

## 1) Add A New Authenticated User Endpoint
Implement a new authenticated endpoint in backend/src/server.js.
Requirements:
- Route: POST /api/orders/:orderId/cancel
- Require Bearer auth via getAuthenticatedUser(req)
- Ensure order belongs to current user
- Allow cancel only when status is pending_payment or processing
- Update status to cancelled
- Return { order: { id, order_number, status } }
- Use existing error response style { error: string }
- Keep code style consistent with existing file.

## 2) Add A New Admin Endpoint
Implement a new admin endpoint in backend/src/server.js.
Requirements:
- Route: GET /api/admin/users?limit=50
- Use getAuthenticatedUser + isAdminUser helpers
- Query profiles table for id, role, is_admin, created_at
- Order by created_at desc
- Limit max 200
- Return { users: [...] }

## 3) Add Upload Completion Metadata Endpoint
Implement POST /api/uploads/complete.
Requirements:
- Require auth
- Body: bucket, path, kind (receipt|avatar|product)
- Store a record in uploads table with user_id, bucket, path, kind, created_at
- Return { ok: true }
- Validate safe path values before insert

## 4) Hardening Pass Prompt
Perform a security hardening pass on backend/src/server.js.
Requirements:
- Add rate limiting for checkout/verify/upload/admin routes
- Add request body validation for each route
- Add structured request logging with request id
- Ensure no secrets are logged
- Keep API contracts backward compatible

## 5) Webhook Prompt
Implement POST /api/paystack/webhook.
Requirements:
- Verify signature with PAYSTACK_WEBHOOK_SECRET
- Handle charge.success event
- Mark matching order status to processing
- Idempotent update (safe on retries)
- Return 200 quickly
