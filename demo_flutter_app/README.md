# demo_flutter_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Environment Setup

1. Open `.env` and paste your keys.
2. Keep `.env` private (already gitignored).
3. For Supabase use the HTTPS project URL in `SUPABASE_URL`, not the raw Postgres connection string.
4. Use your Supabase publishable/anon key in `SUPABASE_ANON_KEY`.
5. Run the app with env injection every time:

```bash
flutter run --dart-define-from-file=.env
```

For release builds:

```bash
flutter build apk --dart-define-from-file=.env
flutter build web --dart-define-from-file=.env
```

Notes:

- `PAYSTACK_PUBLIC_KEY` can be used by the Flutter client.
- `SUPABASE_URL` + `SUPABASE_ANON_KEY` are the Flutter client credentials.
- `PAYSTACK_SECRET_KEY` and all `DHL_*` keys are backend-only secrets.
- Do not commit secrets into source control.

## Supabase Storage

Supabase includes multiple products under one project: Postgres database, Auth, Storage, Realtime, and Edge Functions.

- For product images, you can keep external image URLs (works now), or use Supabase Storage buckets.
- If you use Storage, upload images to a bucket (for example `product-images`) and store the public URL in `products.image_url`.
- The app already reads `products.image_url`, so no Flutter code change is needed to switch image source.

## Android Release And Play Console Upload Key

Generate a new upload keystore and Play Console upload certificate:

```bash
./scripts/generate_upload_keystore.sh
```

This creates:

- `android/upload-keystore.jks`
- `android/key.properties`
- `signing_export/genesis-upload-keystore.jks`
- `signing_export/CM_KEYSTORE_BASE64_ONE_LINE.txt`
- `signing_export/upload_certificate.pem`

In Google Play Console, use `signing_export/upload_certificate.pem` when registering or resetting your upload key.

In Codemagic, set these environment variables:

- `CM_KEY_ALIAS`
- `CM_KEYSTORE_PASSWORD`
- `CM_KEY_PASSWORD`
- `CM_KEYSTORE_BASE64` (paste the content of `signing_export/CM_KEYSTORE_BASE64_ONE_LINE.txt`)

Build AAB for Play upload:

```bash
flutter build appbundle --release --dart-define-from-file=codemagic_defines.json
```
