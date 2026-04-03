import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import axios from 'axios';
import rateLimit from 'express-rate-limit';
import { createClient } from '@supabase/supabase-js';

const app = express();
const port = Number(process.env.APP_API_PORT || 3000);
const isProduction = String(process.env.NODE_ENV || 'development').toLowerCase() === 'production';

const corsOrigins = String(process.env.CORS_ORIGINS || '')
  .split(',')
  .map((v) => v.trim())
  .filter(Boolean);

if (isProduction && corsOrigins.length === 0) {
  console.warn('CORS_ORIGINS is empty in production. Browser origins will be blocked except non-browser clients.');
}

app.set('trust proxy', 1);

const checkoutRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 40,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many checkout requests. Please try again shortly.' },
});

const aiRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many AI requests. Please wait and try again.' },
});

const adminRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 120,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many admin requests. Please try again shortly.' },
});

app.use(
  cors({
    origin(origin, callback) {
      if (isAllowedOrigin(origin)) {
        return callback(null, true);
      }
      return callback(new Error('CORS blocked for this origin'));
    },
    credentials: true,
  }),
);
app.use(express.json({ limit: '1mb' }));
app.use('/api/checkout', checkoutRateLimiter);
app.use('/api/uploads/sign', checkoutRateLimiter);
app.use('/api/ai/routine', aiRateLimiter);
app.use('/api/admin', adminRateLimiter);

const required = [
  'SUPABASE_URL',
  'SUPABASE_SERVICE_ROLE_KEY',
  'PAYSTACK_SECRET_KEY',
];

const missing = required.filter((key) => !String(process.env[key] || '').trim());
if (missing.length > 0) {
  console.warn(`Missing required environment variables: ${missing.join(', ')}`);
}

const supabaseUrl = String(process.env.SUPABASE_URL || '').trim();
const supabaseServiceRoleKey = String(process.env.SUPABASE_SERVICE_ROLE_KEY || '').trim();

const supabaseAdmin =
  supabaseUrl && supabaseServiceRoleKey
    ? createClient(supabaseUrl, supabaseServiceRoleKey, {
        auth: { autoRefreshToken: false, persistSession: false },
      })
    : null;

const paystackClient = axios.create({
  baseURL: 'https://api.paystack.co',
  timeout: 15000,
  headers: {
    Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY || ''}`,
    'Content-Type': 'application/json',
  },
});

const dhlClient = axios.create({
  baseURL: process.env.DHL_API_BASE_URL || 'https://api-mock.dhl.com',
  timeout: 20000,
});

const openAiClient = axios.create({
  baseURL: 'https://api.openai.com/v1',
  timeout: 25000,
});

const defaultStorageBucket = String(
  process.env.SUPABASE_STORAGE_BUCKET || 'product-images',
).trim();

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'delix-backend', ts: new Date().toISOString() });
});

app.post('/api/ai/routine', async (req, res) => {
  try {
    const apiKey = String(process.env.OPENAI_API_KEY || '').trim();
    if (!apiKey) {
      return res.status(503).json({ error: 'AI routine service is not configured.' });
    }

    const body = req.body || {};
    const skinType = String(body.skinType || '').trim();
    const concern = String(body.concern || '').trim();
    const goal = String(body.goal || '').trim();
    const routineDepth = String(body.routineDepth || '').trim();

    if (!skinType || !concern || !goal || !routineDepth) {
      return res.status(400).json({
        error: 'skinType, concern, goal and routineDepth are required.',
      });
    }

    const model = String(process.env.OPENAI_MODEL || 'gpt-4o-mini').trim();
    const prompt = [
      'You are a skincare expert. Generate one AM routine and one PM routine.',
      'Return strict JSON only with keys morning and evening.',
      'Each key must be an array of short step strings. No markdown.',
      '',
      'User profile:',
      `- Skin type: ${skinType}`,
      `- Main concern: ${concern}`,
      `- Goal: ${goal}`,
      `- Depth: ${routineDepth}`,
    ].join('\n');

    const aiRes = await openAiClient.post(
      '/chat/completions',
      {
        model,
        messages: [
          {
            role: 'system',
            content: 'Return only valid minified JSON with morning and evening string arrays.',
          },
          {
            role: 'user',
            content: prompt,
          },
        ],
        temperature: 0.4,
      },
      {
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
      },
    );

    const content = String(aiRes.data?.choices?.[0]?.message?.content || '').trim();
    if (!content) {
      return res.status(502).json({ error: 'AI provider returned an empty response.' });
    }

    const parsed = parseJsonObject(content);
    const morning = Array.isArray(parsed?.morning)
      ? parsed.morning.map((step) => String(step).trim()).filter(Boolean)
      : [];
    const evening = Array.isArray(parsed?.evening)
      ? parsed.evening.map((step) => String(step).trim()).filter(Boolean)
      : [];

    if (morning.length === 0 || evening.length === 0) {
      return res.status(502).json({ error: 'AI provider returned an invalid routine format.' });
    }

    return res.json({ morning, evening });
  } catch (error) {
    const upstreamMessage =
      error?.response?.data?.error?.message ||
      error?.response?.data?.message ||
      error?.message ||
      'Could not generate AI routine';

    if (Number(error?.response?.status) === 429) {
      return res.status(429).json({ error: 'AI service is busy. Please try again shortly.' });
    }

    return res.status(502).json({ error: upstreamMessage });
  }
});

app.post('/api/shipping/quote', async (req, res) => {
  try {
    const body = req.body || {};
    const destinationCountry = String(body.destinationCountry || '').trim().toUpperCase();
    const currency = String(body.currency || 'USD').trim().toUpperCase();
    const items = Array.isArray(body.items) ? body.items : [];

    if (!destinationCountry) {
      return res.status(400).json({ error: 'destinationCountry is required' });
    }

    const packageWeightKg = Math.max(
      0.2,
      items.reduce((sum, item) => sum + Number(item.weightKg || 0.35) * Number(item.quantity || 1), 0),
    );

    if (destinationCountry === 'GH') {
      const amount = convertCurrency(15, 'GHS', currency);
      return res.json({
        provider: 'local',
        service: 'Standard Domestic',
        amount,
        currency,
        etaDays: '1-3',
        packageWeightKg,
      });
    }

    const dhlKey = String(process.env.DHL_SUBSCRIPTION_KEY || '').trim();
    if (!dhlKey) {
      return res.status(500).json({
        error: 'DHL_SUBSCRIPTION_KEY is missing. Cannot quote international shipping.',
      });
    }

    const payload = {
      customerDetails: {
        shipperDetails: {
          postalAddress: {
            countryCode: String(process.env.DHL_ORIGIN_COUNTRY || 'GH').toUpperCase(),
          },
        },
        receiverDetails: {
          postalAddress: {
            countryCode: destinationCountry,
          },
        },
      },
      accounts: [],
      plannedShippingDateAndTime: new Date(Date.now() + 24 * 3600 * 1000).toISOString(),
      unitOfMeasurement: 'metric',
      isCustomsDeclarable: true,
      packages: [
        {
          weight: packageWeightKg,
          dimensions: {
            length: 20,
            width: 20,
            height: 15,
          },
        },
      ],
    };

    const dhlRes = await dhlClient.post('/mydhlapi/rates', payload, {
      headers: {
        'DHL-API-Key': dhlKey,
      },
    });

    const products = dhlRes.data?.products || [];
    if (!Array.isArray(products) || products.length === 0) {
      return res.status(502).json({ error: 'No DHL shipping products returned.' });
    }

    const best = products
      .map((product) => ({
        service: product?.productName || 'DHL Express',
        amount: Number(
          product?.totalPrice?.find((p) => p?.currencyType === 'BILLC')?.price ||
            product?.totalPrice?.[0]?.price ||
            0,
        ),
        currency: String(
          product?.totalPrice?.find((p) => p?.currencyType === 'BILLC')?.priceCurrency ||
            product?.totalPrice?.[0]?.priceCurrency ||
            'USD',
        ).toUpperCase(),
        etaDays: product?.deliveryCapabilities?.estimatedDeliveryDateAndTime || null,
      }))
      .filter((p) => Number.isFinite(p.amount) && p.amount > 0)
      .sort((a, b) => a.amount - b.amount)[0];

    if (!best) {
      return res.status(502).json({ error: 'DHL response did not include a valid rate.' });
    }

    return res.json({
      provider: 'dhl',
      service: best.service,
      amount: best.currency === currency ? best.amount : convertCurrency(best.amount, best.currency, currency),
      currency,
      etaDays: best.etaDays,
      packageWeightKg,
    });
  } catch (error) {
    const message =
      error?.response?.data?.detail ||
      error?.response?.data?.message ||
      error?.message ||
      'Unable to quote shipping';
    return res.status(502).json({ error: message });
  }
});

app.post('/api/checkout/initialize', async (req, res) => {
  try {
    const user = await getAuthenticatedUser(req);
    const body = req.body || {};
    const currency = String(body.currency || 'USD').trim().toUpperCase();
    const items = Array.isArray(body.items) ? body.items : [];
    const shippingAddress = body.shippingAddress || {};

    if (items.length === 0) {
      return res.status(400).json({ error: 'Checkout requires at least one item.' });
    }

    const payerEmail = String(user.email || body.email || '').trim();
    if (!payerEmail) {
      return res.status(400).json({ error: 'Authenticated user email is required for checkout.' });
    }

    if (!shippingAddress.country || !shippingAddress.addressLine1 || !shippingAddress.city) {
      return res.status(400).json({
        error: 'shippingAddress.country, shippingAddress.addressLine1 and shippingAddress.city are required.',
      });
    }

    const subtotal = items.reduce(
      (sum, item) => sum + Number(item.unitPrice || 0) * Number(item.quantity || 1),
      0,
    );

    const shippingQuote = await quoteShippingInternal({
      destinationCountry: String(shippingAddress.country).toUpperCase(),
      currency,
      items,
    });

    const total = roundMoney(subtotal + shippingQuote.amount);
    if (total <= 0) {
      return res.status(400).json({ error: 'Invalid total amount.' });
    }

    const orderNumber = `DLX-${Date.now()}`;

    const sb = requireSupabaseAdmin();

    const { data: orderRow, error: orderError } = await sb
      .from('orders')
      .insert({
        user_id: user.id,
        order_number: orderNumber,
        total,
        status: 'pending_payment',
      })
      .select('id, order_number')
      .single();

    if (orderError) {
      return res.status(500).json({ error: `Could not create order: ${orderError.message}` });
    }

    const orderItemsRows = items.map((item) => ({
      order_id: orderRow.id,
      product_name: String(item.productName || 'Item'),
      quantity: Number(item.quantity || 1),
    }));

    const { error: itemsError } = await sb.from('order_items').insert(orderItemsRows);
    if (itemsError) {
      return res.status(500).json({ error: `Could not save order items: ${itemsError.message}` });
    }

    const callbackUrl = String(process.env.PAYSTACK_CALLBACK_URL || '').trim();

    const initPayload = {
      email: payerEmail,
      amount: toSmallestUnit(total, currency),
      reference: orderNumber,
      currency,
      metadata: {
        order_number: orderNumber,
        order_id: orderRow.id,
        user_id: user.id,
        shipping: shippingAddress,
        shipping_quote: shippingQuote,
      },
      callback_url: callbackUrl || undefined,
    };

    const paystackRes = await paystackClient.post('/transaction/initialize', initPayload);
    const data = paystackRes.data?.data;

    if (!data?.authorization_url || !data?.reference) {
      return res.status(502).json({ error: 'Paystack did not return an authorization URL.' });
    }

    return res.json({
      orderId: orderRow.id,
      orderNumber,
      authorizationUrl: data.authorization_url,
      accessCode: data.access_code,
      reference: data.reference,
      amount: total,
      currency,
      shipping: shippingQuote,
    });
  } catch (error) {
    const message = error?.message || 'Could not initialize checkout';
    const status = message.toLowerCase().includes('authorization') ? 401 : 500;
    return res.status(status).json({ error: message });
  }
});

app.post('/api/checkout/verify', async (req, res) => {
  try {
    const user = await getAuthenticatedUser(req);
    const reference = String(req.body?.reference || '').trim();
    if (!reference) {
      return res.status(400).json({ error: 'reference is required.' });
    }

    const verifyRes = await paystackClient.get(`/transaction/verify/${encodeURIComponent(reference)}`);
    const status = verifyRes.data?.data?.status;

    if (status !== 'success') {
      return res.status(400).json({
        paid: false,
        status,
        message: 'Payment is not successful yet.',
      });
    }

    const sb = requireSupabaseAdmin();
    const { data: existingOrder, error: findOrderError } = await sb
      .from('orders')
      .select('id')
      .eq('order_number', reference)
      .eq('user_id', user.id)
      .maybeSingle();

    if (findOrderError) {
      return res.status(500).json({ error: `Could not validate order ownership: ${findOrderError.message}` });
    }
    if (!existingOrder) {
      return res.status(404).json({ error: 'Order not found for the authenticated user.' });
    }

    const { error: updateError } = await sb
      .from('orders')
      .update({ status: 'processing' })
      .eq('id', existingOrder.id)
      .eq('user_id', user.id);

    if (updateError) {
      return res.status(500).json({ error: `Payment verified but order update failed: ${updateError.message}` });
    }

    return res.json({ paid: true, status: 'success', reference });
  } catch (error) {
    const message = error?.message || 'Could not verify payment';
    const status = message.toLowerCase().includes('authorization') ? 401 : 500;
    return res.status(status).json({ error: message });
  }
});

app.get('/api/orders/me', async (req, res) => {
  try {
    const user = await getAuthenticatedUser(req);
    const sb = requireSupabaseAdmin();
    const { data, error } = await sb
      .from('orders')
      .select('id, order_number, created_at, total, status, order_items(product_name, quantity)')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false });

    if (error) {
      return res.status(500).json({ error: `Could not fetch user orders: ${error.message}` });
    }

    return res.json({ orders: data || [] });
  } catch (error) {
    const message = error?.message || 'Could not fetch orders';
    const status = message.toLowerCase().includes('authorization') ? 401 : 500;
    return res.status(status).json({ error: message });
  }
});

app.post('/api/uploads/sign', async (req, res) => {
  try {
    const user = await getAuthenticatedUser(req);
    const body = req.body || {};
    const fileName = safeFileName(body.fileName || 'upload.bin');
    const folder = safePathSegment(body.folder || 'user-uploads');
    const bucket = safePathSegment(body.bucket || defaultStorageBucket);
    const contentType = String(body.contentType || 'application/octet-stream').trim();

    const path = `${folder}/${user.id}/${Date.now()}_${fileName}`;

    const sb = requireSupabaseAdmin();
    const { data, error } = await sb.storage
      .from(bucket)
      .createSignedUploadUrl(path);

    if (error || !data) {
      return res.status(500).json({ error: `Could not create upload URL: ${error?.message || 'unknown error'}` });
    }

    const { data: publicUrlData } = sb.storage.from(bucket).getPublicUrl(path);

    return res.json({
      bucket,
      path,
      token: data.token,
      signedUrl: data.signedUrl,
      publicUrl: publicUrlData?.publicUrl || null,
      contentType,
    });
  } catch (error) {
    const message = error?.message || 'Could not create signed upload URL';
    const status = message.toLowerCase().includes('authorization') ? 401 : 500;
    return res.status(status).json({ error: message });
  }
});

app.get('/api/admin/orders', async (req, res) => {
  try {
    const user = await getAuthenticatedUser(req);
    const admin = await isAdminUser(user);
    if (!admin) {
      return res.status(403).json({ error: 'Admin access required.' });
    }

    const statusFilter = String(req.query.status || '').trim();
    const limit = Math.min(200, Math.max(1, Number(req.query.limit || 50)));

    const sb = requireSupabaseAdmin();
    let query = sb
      .from('orders')
      .select('id, user_id, order_number, created_at, total, status, order_items(product_name, quantity)')
      .order('created_at', { ascending: false })
      .limit(limit);

    if (statusFilter) {
      query = query.eq('status', statusFilter);
    }

    const { data, error } = await query;
    if (error) {
      return res.status(500).json({ error: `Could not fetch admin orders: ${error.message}` });
    }

    return res.json({ orders: data || [] });
  } catch (error) {
    const message = error?.message || 'Could not fetch admin orders';
    const status = message.toLowerCase().includes('authorization') ? 401 : 500;
    return res.status(status).json({ error: message });
  }
});

app.patch('/api/admin/orders/:orderId/status', async (req, res) => {
  try {
    const user = await getAuthenticatedUser(req);
    const admin = await isAdminUser(user);
    if (!admin) {
      return res.status(403).json({ error: 'Admin access required.' });
    }

    const orderId = String(req.params.orderId || '').trim();
    const nextStatus = String(req.body?.status || '').trim();
    const allowed = new Set(['pending_payment', 'processing', 'shipped', 'delivered', 'cancelled']);

    if (!orderId) {
      return res.status(400).json({ error: 'orderId is required.' });
    }
    if (!allowed.has(nextStatus)) {
      return res.status(400).json({ error: `Invalid status. Allowed: ${Array.from(allowed).join(', ')}` });
    }

    const sb = requireSupabaseAdmin();
    const { data, error } = await sb
      .from('orders')
      .update({ status: nextStatus })
      .eq('id', orderId)
      .select('id, order_number, status')
      .single();

    if (error) {
      return res.status(500).json({ error: `Could not update order status: ${error.message}` });
    }

    return res.json({ order: data });
  } catch (error) {
    const message = error?.message || 'Could not update order status';
    const status = message.toLowerCase().includes('authorization') ? 401 : 500;
    return res.status(status).json({ error: message });
  }
});

app.get('/api/admin/products', async (req, res) => {
  try {
    const user = await getAuthenticatedUser(req);
    const admin = await isAdminUser(user);
    if (!admin) {
      return res.status(403).json({ error: 'Admin access required.' });
    }

    const limit = Math.min(200, Math.max(1, Number(req.query.limit || 100)));
    const { data, error } = await requireSupabaseAdmin()
      .from('products')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(limit);

    if (error) {
      return res.status(500).json({ error: `Could not fetch products: ${error.message}` });
    }

    return res.json({ products: data || [] });
  } catch (error) {
    const message = error?.message || 'Could not fetch products';
    const status = message.toLowerCase().includes('authorization') ? 401 : 500;
    return res.status(status).json({ error: message });
  }
});

app.post('/api/admin/products', async (req, res) => {
  try {
    const user = await getAuthenticatedUser(req);
    const admin = await isAdminUser(user);
    if (!admin) {
      return res.status(403).json({ error: 'Admin access required.' });
    }

    const body = req.body || {};
    const name = String(body.name || '').trim();
    const category = String(body.category || '').trim().toLowerCase();
    const description = String(body.description || '').trim();
    const imageUrl = String(body.imageUrl || '').trim();
    const size = String(body.size || '').trim() || null;
    const badge = String(body.badge || '').trim() || null;
    const details = Array.isArray(body.details)
      ? body.details.map((v) => String(v)).filter(Boolean)
      : [];
    const included = Array.isArray(body.included)
      ? body.included.map((v) => String(v)).filter(Boolean)
      : [];
    const price = roundMoney(body.price);
    const originalPrice = roundMoney(body.originalPrice ?? body.price);
    const rating = Math.max(0, Math.min(5, Number(body.rating ?? 0)));
    const reviewsCount = Math.max(0, Number(body.reviewsCount ?? 0));

    const allowedCategories = new Set([
      'skincare',
      'hair_styling',
      'makeup',
      'fragrance',
      'bodycare',
    ]);

    if (!name || !category || !description) {
      return res.status(400).json({ error: 'name, category and description are required.' });
    }
    if (!allowedCategories.has(category)) {
      return res.status(400).json({ error: 'Invalid category.' });
    }
    if (price <= 0 || originalPrice <= 0) {
      return res.status(400).json({ error: 'price and originalPrice must be greater than zero.' });
    }
    if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
      return res.status(400).json({ error: 'imageUrl must be a valid http(s) URL.' });
    }

    const { data, error } = await requireSupabaseAdmin()
      .from('products')
      .insert({
        name,
        category,
        description,
        price,
        original_price: originalPrice,
        image_url: imageUrl,
        size,
        badge,
        details,
        included,
        rating,
        reviews_count: reviewsCount,
        is_active: body.isActive == null ? true : body.isActive === true,
      })
      .select('*')
      .single();

    if (error) {
      return res.status(500).json({ error: `Could not create product: ${error.message}` });
    }

    return res.status(201).json({ product: data });
  } catch (error) {
    const message = error?.message || 'Could not create product';
    const status = message.toLowerCase().includes('authorization') ? 401 : 500;
    return res.status(status).json({ error: message });
  }
});

app.patch('/api/admin/products/:productId', async (req, res) => {
  try {
    const user = await getAuthenticatedUser(req);
    const admin = await isAdminUser(user);
    if (!admin) {
      return res.status(403).json({ error: 'Admin access required.' });
    }

    const productId = String(req.params.productId || '').trim();
    if (!productId) {
      return res.status(400).json({ error: 'productId is required.' });
    }

    const body = req.body || {};
    const updates = {};

    if (body.name != null) updates.name = String(body.name).trim();
    if (body.description != null) updates.description = String(body.description).trim();
    if (body.category != null) updates.category = String(body.category).trim().toLowerCase();
    if (body.price != null) updates.price = roundMoney(body.price);
    if (body.originalPrice != null) updates.original_price = roundMoney(body.originalPrice);
    if (body.imageUrl != null) updates.image_url = String(body.imageUrl).trim();
    if (body.badge != null) updates.badge = String(body.badge).trim() || null;
    if (body.size != null) updates.size = String(body.size).trim() || null;
    if (body.details != null && Array.isArray(body.details)) {
      updates.details = body.details.map((v) => String(v));
    }
    if (body.included != null && Array.isArray(body.included)) {
      updates.included = body.included.map((v) => String(v));
    }
    if (body.isActive != null) {
      updates.is_active = body.isActive === true;
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ error: 'No valid fields to update.' });
    }

    const { data, error } = await requireSupabaseAdmin()
      .from('products')
      .update(updates)
      .eq('id', productId)
      .select('*')
      .single();

    if (error) {
      return res.status(500).json({ error: `Could not update product: ${error.message}` });
    }

    return res.json({ product: data });
  } catch (error) {
    const message = error?.message || 'Could not update product';
    const status = message.toLowerCase().includes('authorization') ? 401 : 500;
    return res.status(status).json({ error: message });
  }
});

app.listen(port, () => {
  console.log(`Delix backend listening on http://0.0.0.0:${port}`);
});

class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.name = 'HttpError';
    this.status = status;
  }
}

async function getAuthenticatedUser(req) {
  const authHeader = String(req.headers.authorization || '');
  if (!authHeader.startsWith('Bearer ')) {
    throw new HttpError(401, 'Authorization header is required.');
  }

  const token = authHeader.replace('Bearer ', '').trim();
  if (!token) {
    throw new HttpError(401, 'Authorization token is missing.');
  }

  const sb = requireSupabaseAdmin();
  const { data, error } = await sb.auth.getUser(token);
  if (error || !data?.user) {
    throw new HttpError(401, 'Authorization failed.');
  }

  return data.user;
}

async function isAdminUser(user) {
  const metadataRole =
    String(user?.app_metadata?.role || user?.user_metadata?.role || '').trim().toLowerCase();
  const metadataFlag =
    user?.app_metadata?.is_admin === true || user?.user_metadata?.is_admin === true;

  if (metadataFlag || metadataRole === 'admin') {
    return true;
  }

  const sb = requireSupabaseAdmin();
  const { data, error } = await sb
    .from('profiles')
    .select('role, is_admin')
    .eq('id', user.id)
    .maybeSingle();

  if (error || !data) {
    return false;
  }

  const profileRole = String(data.role || '').trim().toLowerCase();
  return data.is_admin === true || profileRole === 'admin';
}

function requireSupabaseAdmin() {
  if (!supabaseAdmin) {
    throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required.');
  }
  return supabaseAdmin;
}

function isAllowedOrigin(origin) {
  if (!origin) {
    // Mobile clients and server-to-server calls generally do not send an Origin header.
    return true;
  }

  if (corsOrigins.includes(origin)) {
    return true;
  }

  if (!isProduction) {
    return /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i.test(origin);
  }

  return false;
}

function parseJsonObject(source) {
  try {
    return JSON.parse(source);
  } catch {
    const match = source.match(/\{[\s\S]*\}/);
    if (!match) return null;
    try {
      return JSON.parse(match[0]);
    } catch {
      return null;
    }
  }
}

function safePathSegment(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/[^a-z0-9-_]/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '') || 'default';
}

function safeFileName(value) {
  const sanitized = String(value || '')
    .replace(/[^a-zA-Z0-9._-]/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '');
  return sanitized || 'file.bin';
}

async function quoteShippingInternal({ destinationCountry, currency, items }) {
  const packageWeightKg = Math.max(
    0.2,
    items.reduce((sum, item) => sum + Number(item.weightKg || 0.35) * Number(item.quantity || 1), 0),
  );

  if (destinationCountry === 'GH') {
    return {
      provider: 'local',
      service: 'Standard Domestic',
      amount: convertCurrency(15, 'GHS', currency),
      currency,
      etaDays: '1-3',
      packageWeightKg,
    };
  }

  const dhlKey = String(process.env.DHL_SUBSCRIPTION_KEY || '').trim();
  if (!dhlKey) {
    throw new Error('DHL_SUBSCRIPTION_KEY is missing for international shipping.');
  }

  const payload = {
    customerDetails: {
      shipperDetails: {
        postalAddress: {
          countryCode: String(process.env.DHL_ORIGIN_COUNTRY || 'GH').toUpperCase(),
        },
      },
      receiverDetails: {
        postalAddress: {
          countryCode: destinationCountry,
        },
      },
    },
    plannedShippingDateAndTime: new Date(Date.now() + 24 * 3600 * 1000).toISOString(),
    unitOfMeasurement: 'metric',
    isCustomsDeclarable: true,
    packages: [
      {
        weight: packageWeightKg,
        dimensions: {
          length: 20,
          width: 20,
          height: 15,
        },
      },
    ],
  };

  const dhlRes = await dhlClient.post('/mydhlapi/rates', payload, {
    headers: {
      'DHL-API-Key': dhlKey,
    },
  });

  const products = dhlRes.data?.products || [];
  if (!Array.isArray(products) || products.length === 0) {
    throw new Error('No DHL shipping products returned.');
  }

  const best = products
    .map((product) => ({
      service: product?.productName || 'DHL Express',
      amount: Number(
        product?.totalPrice?.find((p) => p?.currencyType === 'BILLC')?.price ||
          product?.totalPrice?.[0]?.price ||
          0,
      ),
      currency: String(
        product?.totalPrice?.find((p) => p?.currencyType === 'BILLC')?.priceCurrency ||
          product?.totalPrice?.[0]?.priceCurrency ||
          'USD',
      ).toUpperCase(),
      etaDays: product?.deliveryCapabilities?.estimatedDeliveryDateAndTime || null,
    }))
    .filter((p) => Number.isFinite(p.amount) && p.amount > 0)
    .sort((a, b) => a.amount - b.amount)[0];

  if (!best) {
    throw new Error('DHL response did not include a valid rate.');
  }

  return {
    provider: 'dhl',
    service: best.service,
    amount: best.currency === currency ? best.amount : convertCurrency(best.amount, best.currency, currency),
    currency,
    etaDays: best.etaDays,
    packageWeightKg,
  };
}

function roundMoney(value) {
  return Math.round((Number(value) + Number.EPSILON) * 100) / 100;
}

function toSmallestUnit(amount, currency) {
  const upper = String(currency || 'USD').toUpperCase();
  // Paystack expects kobo/pesewas for supported currencies.
  if (upper === 'JPY') return Math.round(amount);
  return Math.round(amount * 100);
}

function convertCurrency(amount, fromCode, toCode) {
  const from = String(fromCode || 'USD').toUpperCase();
  const to = String(toCode || 'USD').toUpperCase();

  if (from === to) return roundMoney(amount);

  const usdRates = {
    USD: 1,
    GHS: 14.8,
    EUR: 0.92,
    GBP: 0.79,
  };

  const fromRate = usdRates[from] || 1;
  const toRate = usdRates[to] || 1;
  const usdValue = Number(amount) / fromRate;
  return roundMoney(usdValue * toRate);
}
