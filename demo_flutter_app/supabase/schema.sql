create extension if not exists pgcrypto;

drop table if exists public.routine_step_logs cascade;
drop table if exists public.routine_steps cascade;
drop table if exists public.routine_plans cascade;
drop table if exists public.routine_profiles cascade;
drop table if exists public.support_requests cascade;
drop table if exists public.product_reviews cascade;
drop table if exists public.wishlist_items cascade;
drop table if exists public.cart_items cascade;
drop table if exists public.carts cascade;
drop table if exists public.payment_methods cascade;
drop table if exists public.addresses cascade;
drop table if exists public.order_items cascade;
drop table if exists public.orders cascade;
drop table if exists public.notification_preferences cascade;
drop table if exists public.user_preferences cascade;
drop table if exists public.profiles cascade;
drop table if exists public.shipment_events cascade;
drop table if exists public.shipments cascade;
drop table if exists public.drivers cascade;
drop table if exists public.vehicles cascade;
drop table if exists public.products cascade;

drop function if exists public.handle_new_user() cascade;
drop function if exists public.set_updated_at() cascade;

create function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create table public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null check (category in ('skincare', 'hair_styling', 'makeup', 'fragrance', 'bodycare')),
  description text not null default '',
  price numeric(10,2) not null,
  original_price numeric(10,2) not null,
  rating numeric(3,2) not null default 0,
  reviews_count integer not null default 0,
  image_url text not null,
  badge text,
  size text,
  details jsonb not null default '[]'::jsonb,
  included jsonb not null default '[]'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  phone text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  language_code text not null default 'en',
  currency_code text not null default 'GHS',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.notification_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  push_enabled boolean not null default true,
  marketing_enabled boolean not null default true,
  order_updates_enabled boolean not null default true,
  routine_reminder_enabled boolean not null default false,
  routine_reminder_time time not null default '21:00:00',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  label text not null default 'Home',
  full_name text,
  phone text,
  line_1 text not null,
  line_2 text,
  city text not null,
  region text,
  postal_code text,
  country_code text not null default 'GH',
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider text not null default 'paystack',
  method_type text not null default 'card',
  label text,
  brand text,
  last4 text,
  token_ref text,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.carts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  status text not null default 'active' check (status in ('active', 'converted', 'abandoned')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.cart_items (
  id uuid primary key default gen_random_uuid(),
  cart_id uuid not null references public.carts(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  quantity integer not null default 1 check (quantity > 0),
  unit_price numeric(10,2) not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (cart_id, product_id)
);

create table public.wishlist_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, product_id)
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  order_number text not null unique,
  address_id uuid references public.addresses(id) on delete set null,
  payment_method_id uuid references public.payment_methods(id) on delete set null,
  payment_provider text,
  payment_reference text,
  subtotal numeric(10,2) not null default 0,
  delivery_fee numeric(10,2) not null default 0,
  total numeric(10,2) not null,
  notes text,
  status text not null check (status in ('processing', 'paid', 'shipped', 'delivered', 'cancelled')) default 'processing',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(10,2) not null,
  created_at timestamptz not null default now()
);

create table public.product_reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  title text,
  body text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (product_id, user_id)
);

create table public.routine_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  skin_type text,
  main_concern text,
  primary_goal text,
  routine_depth text default 'Balanced',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.routine_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default 'Routine Studio Plan',
  skin_type text,
  concern text,
  goal text,
  routine_depth text,
  is_ai_generated boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.routine_steps (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.routine_plans(id) on delete cascade,
  period text not null check (period in ('morning', 'evening')),
  position integer not null check (position > 0),
  title text not null,
  description text not null default '',
  icon text,
  step_category text,
  is_optional boolean not null default false,
  created_at timestamptz not null default now(),
  unique (plan_id, period, position)
);

create table public.routine_step_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  step_id uuid not null references public.routine_steps(id) on delete cascade,
  completed_on date not null default current_date,
  completed_at timestamptz not null default now(),
  unique (user_id, step_id, completed_on)
);

create table public.support_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  subject text not null,
  message text not null,
  status text not null default 'open' check (status in ('open', 'in_progress', 'resolved', 'closed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger products_set_updated_at
before update on public.products
for each row execute procedure public.set_updated_at();

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute procedure public.set_updated_at();

create trigger user_preferences_set_updated_at
before update on public.user_preferences
for each row execute procedure public.set_updated_at();

create trigger notification_preferences_set_updated_at
before update on public.notification_preferences
for each row execute procedure public.set_updated_at();

create trigger addresses_set_updated_at
before update on public.addresses
for each row execute procedure public.set_updated_at();

create trigger payment_methods_set_updated_at
before update on public.payment_methods
for each row execute procedure public.set_updated_at();

create trigger carts_set_updated_at
before update on public.carts
for each row execute procedure public.set_updated_at();

create trigger cart_items_set_updated_at
before update on public.cart_items
for each row execute procedure public.set_updated_at();

create trigger orders_set_updated_at
before update on public.orders
for each row execute procedure public.set_updated_at();

create trigger product_reviews_set_updated_at
before update on public.product_reviews
for each row execute procedure public.set_updated_at();

create trigger routine_profiles_set_updated_at
before update on public.routine_profiles
for each row execute procedure public.set_updated_at();

create trigger routine_plans_set_updated_at
before update on public.routine_plans
for each row execute procedure public.set_updated_at();

create trigger support_requests_set_updated_at
before update on public.support_requests
for each row execute procedure public.set_updated_at();

alter table public.products enable row level security;
alter table public.profiles enable row level security;
alter table public.user_preferences enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.addresses enable row level security;
alter table public.payment_methods enable row level security;
alter table public.carts enable row level security;
alter table public.cart_items enable row level security;
alter table public.wishlist_items enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.product_reviews enable row level security;
alter table public.routine_profiles enable row level security;
alter table public.routine_plans enable row level security;
alter table public.routine_steps enable row level security;
alter table public.routine_step_logs enable row level security;
alter table public.support_requests enable row level security;

create policy "products are readable by everyone"
on public.products for select
using (true);

create policy "reviews are readable by everyone"
on public.product_reviews for select
using (true);

create policy "users can read own profile"
on public.profiles for select
using (auth.uid() = id);

create policy "users can insert own profile"
on public.profiles for insert
with check (auth.uid() = id);

create policy "users can update own profile"
on public.profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);

create policy "users can read own preferences"
on public.user_preferences for select
using (auth.uid() = user_id);

create policy "users can insert own preferences"
on public.user_preferences for insert
with check (auth.uid() = user_id);

create policy "users can update own preferences"
on public.user_preferences for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users can read own notification preferences"
on public.notification_preferences for select
using (auth.uid() = user_id);

create policy "users can insert own notification preferences"
on public.notification_preferences for insert
with check (auth.uid() = user_id);

create policy "users can update own notification preferences"
on public.notification_preferences for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users can manage own addresses"
on public.addresses for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users can manage own payment methods"
on public.payment_methods for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users can manage own carts"
on public.carts for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users can manage own cart items"
on public.cart_items for all
using (
  exists (
    select 1
    from public.carts
    where public.carts.id = public.cart_items.cart_id
      and public.carts.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.carts
    where public.carts.id = public.cart_items.cart_id
      and public.carts.user_id = auth.uid()
  )
);

create policy "users can manage own wishlist"
on public.wishlist_items for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users can manage own orders"
on public.orders for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users can manage own order items"
on public.order_items for all
using (
  exists (
    select 1
    from public.orders
    where public.orders.id = public.order_items.order_id
      and public.orders.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.orders
    where public.orders.id = public.order_items.order_id
      and public.orders.user_id = auth.uid()
  )
);

create policy "users can create own reviews"
on public.product_reviews for insert
with check (auth.uid() = user_id);

create policy "users can update own reviews"
on public.product_reviews for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users can delete own reviews"
on public.product_reviews for delete
using (auth.uid() = user_id);

create policy "users can manage own routine profile"
on public.routine_profiles for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users can manage own routine plans"
on public.routine_plans for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "users can manage own routine steps"
on public.routine_steps for all
using (
  exists (
    select 1
    from public.routine_plans
    where public.routine_plans.id = public.routine_steps.plan_id
      and public.routine_plans.user_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.routine_plans
    where public.routine_plans.id = public.routine_steps.plan_id
      and public.routine_plans.user_id = auth.uid()
  )
);

create policy "users can manage own routine logs"
on public.routine_step_logs for all
using (auth.uid() = user_id)
with check (
  auth.uid() = user_id
  and exists (
    select 1
    from public.routine_steps
    join public.routine_plans on public.routine_plans.id = public.routine_steps.plan_id
    where public.routine_steps.id = public.routine_step_logs.step_id
      and public.routine_plans.user_id = auth.uid()
  )
);

create policy "users can manage own support requests"
on public.support_requests for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do update
  set email = excluded.email,
      full_name = coalesce(public.profiles.full_name, excluded.full_name),
      updated_at = now();

  insert into public.user_preferences (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  insert into public.notification_preferences (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  insert into public.carts (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  insert into public.routine_profiles (user_id)
  values (new.id)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do update
set public = true;

drop policy if exists "public read product images" on storage.objects;
create policy "public read product images"
on storage.objects for select
using (bucket_id = 'product-images');

drop policy if exists "authenticated upload product images" on storage.objects;
create policy "authenticated upload product images"
on storage.objects for insert
to authenticated
with check (bucket_id = 'product-images');

drop policy if exists "authenticated update product images" on storage.objects;
create policy "authenticated update product images"
on storage.objects for update
to authenticated
using (bucket_id = 'product-images')
with check (bucket_id = 'product-images');

drop policy if exists "authenticated delete product images" on storage.objects;
create policy "authenticated delete product images"
on storage.objects for delete
to authenticated
using (bucket_id = 'product-images');

insert into public.products (
  id,
  name,
  category,
  description,
  price,
  original_price,
  rating,
  reviews_count,
  image_url,
  badge,
  size,
  details,
  included
) values
  (
    'a8e7a9e8-bf03-4ec9-8141-42f60ea4ef01',
    'Vitamin C Brightening Serum',
    'skincare',
    'Powerful antioxidant serum that brightens, evens skin tone, and protects against environmental damage.',
    89.00,
    120.00,
    4.8,
    142,
    'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=400&q=80',
    'BEST SELLER',
    '30ml',
    '["15% Vitamin C (L-Ascorbic Acid)", "Hyaluronic Acid for deep hydration", "Niacinamide to minimize pores", "Ferulic Acid for stability"]'::jsonb,
    '["30ml Serum", "Dropper applicator", "Instructions card"]'::jsonb
  ),
  (
    'a8e7a9e8-bf03-4ec9-8141-42f60ea4ef02',
    'Deep Hydration Moisturizer',
    'skincare',
    'Rich, non-greasy moisturizer with ceramides and peptides for all-day hydration and skin barrier repair.',
    65.00,
    65.00,
    4.6,
    98,
    'https://images.unsplash.com/photo-1617897903246-719242758050?w=400&q=80',
    null,
    '50ml',
    '["Triple ceramide complex", "Peptide blend for anti-aging", "Fragrance-free formula", "Suitable for sensitive skin"]'::jsonb,
    '["50ml Moisturizer"]'::jsonb
  ),
  (
    'a8e7a9e8-bf03-4ec9-8141-42f60ea4ef03',
    'Flawless Foundation',
    'makeup',
    'Medium-to-full buildable coverage foundation with a natural satin finish. Available in 20 shades.',
    75.00,
    99.00,
    4.7,
    211,
    'https://images.unsplash.com/photo-1586495777744-4e6232bf2f9d?w=400&q=80',
    'NEW',
    '30ml',
    '["SPF 15 sun protection", "Lasts up to 16 hours", "Oil-control formula", "20 inclusive shades"]'::jsonb,
    '["30ml Foundation", "Shade guide"]'::jsonb
  ),
  (
    'a8e7a9e8-bf03-4ec9-8141-42f60ea4ef04',
    'Smoky Eyeshadow Palette',
    'makeup',
    '12 highly-pigmented shades ranging from matte nudes to dazzling shimmers for endless eye looks.',
    110.00,
    150.00,
    4.9,
    334,
    'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=400&q=80',
    'TRENDING',
    null,
    '["8 matte + 4 shimmer shades", "Micro-pigment formula", "Blendable and long-lasting", "Mirror included in palette"]'::jsonb,
    '["12-pan palette", "Double-ended brush"]'::jsonb
  ),
  (
    'a8e7a9e8-bf03-4ec9-8141-42f60ea4ef05',
    'Hydrating Face Mask',
    'skincare',
    'Intensive overnight mask with hyaluronic acid and aloe vera that replenishes moisture while you sleep.',
    55.00,
    70.00,
    4.5,
    87,
    'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=400&q=80',
    null,
    '100ml',
    '["Hyaluronic acid triple complex", "Aloe vera + green tea extract", "No-rinse overnight formula", "Vegan & cruelty-free"]'::jsonb,
    '["100ml Face Mask", "Spatula"]'::jsonb
  ),
  (
    'a8e7a9e8-bf03-4ec9-8141-42f60ea4ef06',
    'Velvet Matte Lipstick Set',
    'makeup',
    'Luxurious set of 6 long-wearing matte lipsticks in curated shades from nudes to deep berries.',
    130.00,
    180.00,
    4.8,
    256,
    'https://images.unsplash.com/photo-1619451334792-150fd785ee74?w=400&q=80',
    'SALE',
    null,
    '["6 iconic shades", "Up to 12-hour wear", "Vitamin E enriched", "Smooth, non-drying formula"]'::jsonb,
    '["6 x 3.5g Lipsticks", "Gift box", "Shade card"]'::jsonb
  ),
  (
    'a8e7a9e8-bf03-4ec9-8141-42f60ea4ef07',
    'Argan Oil Hair Serum',
    'hair_styling',
    'Lightweight, frizz-taming serum with pure Moroccan argan oil for glossy, manageable hair.',
    48.00,
    48.00,
    4.6,
    74,
    'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400&q=80',
    null,
    '100ml',
    '["100% pure argan oil", "Heat protection up to 230°C", "Anti-frizz formula", "Lightweight, non-greasy"]'::jsonb,
    '["100ml Hair Serum"]'::jsonb
  ),
  (
    'a8e7a9e8-bf03-4ec9-8141-42f60ea4ef08',
    'Rose & Oud Eau de Parfum',
    'fragrance',
    'A captivating blend of Bulgarian rose and smoky oud, with notes of amber and sandalwood.',
    195.00,
    240.00,
    4.9,
    128,
    'https://images.unsplash.com/photo-1541643600914-78b084683702?w=400&q=80',
    'LUXURY',
    '50ml',
    '["Top: Bulgarian Rose, Bergamot", "Middle: Oud, Jasmine", "Base: Amber, Sandalwood, Musk", "Long-lasting 8-10 hours"]'::jsonb,
    '["50ml EDP", "Gift box", "Sample card"]'::jsonb
  ),
  (
    'a8e7a9e8-bf03-4ec9-8141-42f60ea4ef09',
    'Coconut Body Butter',
    'bodycare',
    'Ultra-rich body butter with shea and coconut oil that deeply nourishes dry skin for 24-hour softness.',
    58.00,
    79.00,
    4.7,
    176,
    'https://images.unsplash.com/photo-1601049541289-9b1b7bbbfe19?w=400&q=80',
    null,
    '250ml',
    '["Shea butter + coconut oil", "24-hour moisture", "Fast-absorbing finish", "Warm coconut scent"]'::jsonb,
    '["250ml Body Butter"]'::jsonb
  );
