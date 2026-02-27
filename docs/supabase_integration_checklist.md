# 🗄️ Supabase Backend Integration Checklist

## 📋 Overview

This document provides a comprehensive, flow-by-flow checklist for integrating Supabase as the backend for the Standard Marketing (SM) e-commerce application. Each section is organized by user flow and screen, with complete backend requirements, database schema, RLS policies, and implementation steps.

---

## 🚀 Phase 1: Supabase Setup & Configuration

### 1.1 Project Setup
- [ ] Create Supabase project
- [ ] Configure project settings (name, region, plan)
- [ ] Get project URL and anon/public keys
- [ ] Add Supabase credentials to `lib/core/config/environment.dart`
- [ ] Install `supabase_flutter` package in `pubspec.yaml`
- [ ] Initialize Supabase client in `main.dart`
- [ ] Create Supabase client provider in `lib/core/providers/supabase_provider.dart`

### 1.2 Environment Configuration
- [ ] Add `SUPABASE_URL` to environment config
- [ ] Add `SUPABASE_ANON_KEY` to environment config
- [ ] Add `SUPABASE_SERVICE_ROLE_KEY` (for admin operations, server-side only)
- [ ] Configure password reset redirect URL
- [ ] Set up email templates in Supabase dashboard

---

## 🗃️ Phase 2: Database Schema Setup

### 2.1 Authentication Tables (Supabase Auth)
- [ ] **users** (managed by Supabase Auth)
  - Fields: `id`, `email`, `phone`, `user_metadata`, `created_at`, `updated_at`
  - Custom metadata: `name`, `mobile`, `display_mobile`, `role`

### 2.2 Core User Tables

#### **profiles** Table
- [ ] Create table with fields:
  ```sql
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT,
  mobile TEXT,
  display_mobile TEXT,
  avatar_url TEXT,
  role TEXT DEFAULT 'user' CHECK (role IN ('user', 'admin', 'manager', 'support')),
  gender TEXT CHECK (gender IN ('male', 'female', 'others', 'prefer_not_to_say')),
  date_of_birth DATE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
  ```
- [ ] Create indexes:
  - `idx_profiles_email` on `email`
  - `idx_profiles_mobile` on `mobile`
  - `idx_profiles_role` on `role`
- [ ] Create RLS policies:
  - Users can SELECT their own profile
  - Users can UPDATE their own profile
  - Users can INSERT their own profile (on signup)
  - Admins can SELECT/UPDATE all profiles
- [ ] Create trigger for `updated_at` auto-update

#### **addresses** Table
- [ ] Create table with fields:
  ```sql
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  address TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  pincode TEXT NOT NULL,
  coordinates POINT, -- PostGIS extension for lat/lng
  notes TEXT,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
  ```
- [ ] Create indexes:
  - `idx_addresses_user_id` on `user_id`
  - `idx_addresses_is_default` on `is_default`
- [ ] Create RLS policies:
  - Users can SELECT/INSERT/UPDATE/DELETE their own addresses
  - Admins can SELECT all addresses
- [ ] Create trigger to ensure only one default address per user
- [ ] Create trigger for `updated_at` auto-update

#### **gst_records** Table
- [ ] Create table with fields:
  ```sql
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  gst_number TEXT NOT NULL,
  business_name TEXT NOT NULL,
  business_address TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  pincode TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, gst_number)
  ```
- [ ] Create indexes:
  - `idx_gst_records_user_id` on `user_id`
  - `idx_gst_records_gst_number` on `gst_number`
- [ ] Create RLS policies:
  - Users can SELECT/INSERT/UPDATE/DELETE their own GST records
  - Admins can SELECT all GST records
- [ ] Create trigger to ensure only one default GST per user
- [ ] Create trigger for `updated_at` auto-update

### 2.3 Product & Catalog Tables

#### **categories** Table
- [ ] Create table with fields:
  ```sql
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  image_url TEXT,
  parent_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  sort_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
  ```
- [ ] Create indexes:
  - `idx_categories_name` on `name`
  - `idx_categories_parent_id` on `parent_id`
  - `idx_categories_is_active` on `is_active`
- [ ] Create RLS policies:
  - Public can SELECT active categories
  - Admins can SELECT/INSERT/UPDATE/DELETE all categories
- [ ] Create trigger for `updated_at` auto-update

#### **products** Table
- [ ] Create table with fields:
  ```sql
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  subtitle TEXT,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  brand TEXT,
  sku TEXT UNIQUE,
  stock INTEGER DEFAULT 0,
  image_url TEXT NOT NULL, -- Primary image
  images TEXT[], -- Array of image URLs
  categories TEXT[], -- Array of category names
  tags TEXT[], -- Array of tags
  alternative_names TEXT[], -- For search
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
  ```
- [ ] Create indexes:
  - `idx_products_name` on `name` (GIN for full-text search)
  - `idx_products_sku` on `sku`
  - `idx_products_categories` on `categories` (GIN)
  - `idx_products_tags` on `tags` (GIN)
  - `idx_products_is_active` on `is_active`
  - Full-text search index on `name`, `description`, `alternative_names`
- [ ] Create RLS policies:
  - Public can SELECT active products
  - Admins can SELECT/INSERT/UPDATE/DELETE all products
- [ ] Create trigger for `updated_at` auto-update

#### **product_variants** Table
- [ ] Create table with fields:
  ```sql
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  sku TEXT NOT NULL,
  attributes JSONB NOT NULL, -- e.g., {"Size": "M", "Color": "Black"}
  price DECIMAL(10,2) NOT NULL,
  stock INTEGER DEFAULT 0,
  images TEXT[], -- Variant-specific images
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(product_id, sku)
  ```
- [ ] Create indexes:
  - `idx_product_variants_product_id` on `product_id`
  - `idx_product_variants_sku` on `sku`
- [ ] Create RLS policies:
  - Public can SELECT variants for active products
  - Admins can SELECT/INSERT/UPDATE/DELETE all variants
- [ ] Create trigger for `updated_at` auto-update

#### **product_measurements** Table
- [ ] Create table with fields:
  ```sql
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  unit TEXT NOT NULL, -- 'kg', 'gram', 'liter', 'ml', 'piece', etc.
  price DECIMAL(10,2) NOT NULL,
  stock INTEGER DEFAULT 0,
  weight DECIMAL(10,3), -- in grams
  volume DECIMAL(10,3), -- in ml
  length DECIMAL(10,3), -- in cm
  count INTEGER, -- for countable items
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(product_id, unit)
  ```
- [ ] Create indexes:
  - `idx_product_measurements_product_id` on `product_id`
- [ ] Create RLS policies:
  - Public can SELECT measurements for active products
  - Admins can SELECT/INSERT/UPDATE/DELETE all measurements
- [ ] Create trigger for `updated_at` auto-update

### 2.4 Order Management Tables

#### **orders** Table
- [ ] Create table with fields:
  ```sql
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_number TEXT NOT NULL UNIQUE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'confirmed' 
    CHECK (status IN ('confirmed', 'processing', 'shipped', 'delivered', 'cancelled')),
  subtotal DECIMAL(10,2) NOT NULL,
  shipping DECIMAL(10,2) NOT NULL DEFAULT 0,
  tax DECIMAL(10,2) NOT NULL DEFAULT 0,
  total DECIMAL(10,2) NOT NULL,
  delivery_address JSONB NOT NULL, -- Full address snapshot
  tracking_number TEXT,
  estimated_delivery TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
  ```
- [ ] Create indexes:
  - `idx_orders_user_id` on `user_id`
  - `idx_orders_order_number` on `order_number`
  - `idx_orders_status` on `status`
  - `idx_orders_created_at` on `created_at` DESC
- [ ] Create RLS policies:
  - Users can SELECT their own orders
  - Users can INSERT their own orders
  - Users can UPDATE their own orders (limited fields, e.g., cancel)
  - Admins can SELECT/UPDATE all orders
- [ ] Create trigger for `updated_at` auto-update
- [ ] Create trigger to generate order_number on insert

#### **order_items** Table
- [ ] Create table with fields:
  ```sql
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id),
  variant_id UUID REFERENCES product_variants(id),
  measurement_unit TEXT, -- If measurement-based pricing
  name TEXT NOT NULL, -- Product name snapshot
  image TEXT NOT NULL, -- Product image snapshot
  price DECIMAL(10,2) NOT NULL, -- Price at time of order
  quantity INTEGER NOT NULL,
  size TEXT,
  color TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
  ```
- [ ] Create indexes:
  - `idx_order_items_order_id` on `order_id`
  - `idx_order_items_product_id` on `product_id`
- [ ] Create RLS policies:
  - Users can SELECT items for their own orders
  - Users can INSERT items for their own orders
  - Admins can SELECT all order items
- [ ] Create trigger to prevent updates/deletes (orders are immutable)

### 2.5 Cart Management Table

#### **carts** Table
- [ ] Create table with fields:
  ```sql
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  items JSONB NOT NULL DEFAULT '[]'::jsonb, -- Array of cart items
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
  ```
- [ ] Create indexes:
  - `idx_carts_user_id` on `user_id`
- [ ] Create RLS policies:
  - Users can SELECT/INSERT/UPDATE/DELETE their own cart
  - Admins can SELECT all carts (for analytics)
- [ ] Create trigger for `updated_at` auto-update

### 2.6 Admin & Analytics Tables

#### **admin_features** Table
- [ ] Create table with fields:
  ```sql
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_name TEXT NOT NULL UNIQUE,
  is_enabled BOOLEAN DEFAULT TRUE,
  settings JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
  ```
- [ ] Create RLS policies:
  - Public can SELECT enabled features
  - Admins can SELECT/INSERT/UPDATE/DELETE all features
- [ ] Create trigger for `updated_at` auto-update

#### **product_views** Table (Analytics)
- [ ] Create table with fields:
  ```sql
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  session_id TEXT,
  viewed_at TIMESTAMPTZ DEFAULT NOW(),
  duration_seconds INTEGER,
  source TEXT -- 'home', 'search', 'category', 'related', etc.
  ```
- [ ] Create indexes:
  - `idx_product_views_product_id` on `product_id`
  - `idx_product_views_user_id` on `user_id`
  - `idx_product_views_viewed_at` on `viewed_at` DESC
- [ ] Create RLS policies:
  - Users can INSERT their own views
  - Admins can SELECT all views
- [ ] Create partition by month (for performance)

#### **search_queries** Table (Analytics)
- [ ] Create table with fields:
  ```sql
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  query TEXT NOT NULL,
  results_count INTEGER,
  clicked_product_id UUID REFERENCES products(id),
  searched_at TIMESTAMPTZ DEFAULT NOW()
  ```
- [ ] Create indexes:
  - `idx_search_queries_user_id` on `user_id`
  - `idx_search_queries_searched_at` on `searched_at` DESC
- [ ] Create RLS policies:
  - Users can INSERT their own queries
  - Admins can SELECT all queries

#### **notifications** Table
- [ ] Create table with fields:
  ```sql
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL,
  subject TEXT NOT NULL,
  body TEXT NOT NULL,
  recipients TEXT[] NOT NULL,
  priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'scheduled')),
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  data JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
  ```
- [ ] Create indexes:
  - `idx_notifications_status` on `status`
  - `idx_notifications_scheduled_at` on `scheduled_at`
- [ ] Create RLS policies:
  - Admins can SELECT/INSERT/UPDATE/DELETE all notifications

#### **email_templates** Table
- [ ] Create table with fields:
  ```sql
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  type TEXT NOT NULL,
  subject TEXT NOT NULL,
  body TEXT NOT NULL,
  variables TEXT[],
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
  ```
- [ ] Create RLS policies:
  - Admins can SELECT/INSERT/UPDATE/DELETE all templates
- [ ] Create trigger for `updated_at` auto-update

#### **inventory_alerts** Table
- [ ] Create table with fields:
  ```sql
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  product_name TEXT NOT NULL,
  current_stock INTEGER NOT NULL,
  threshold INTEGER NOT NULL,
  is_resolved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
  ```
- [ ] Create indexes:
  - `idx_inventory_alerts_product_id` on `product_id`
  - `idx_inventory_alerts_is_resolved` on `is_resolved`
- [ ] Create RLS policies:
  - Admins can SELECT/INSERT/UPDATE/DELETE all alerts

---

## 📦 Phase 3: Storage Buckets Setup

### 3.1 Storage Buckets
- [ ] Create `product-images` bucket
  - Public access: Yes
  - File size limit: 10MB
  - Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`
  - RLS policies: Public read, Admin write
- [ ] Create `category-images` bucket
  - Public access: Yes
  - File size limit: 5MB
  - Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`
  - RLS policies: Public read, Admin write
- [ ] Create `profile-avatars` bucket
  - Public access: Yes
  - File size limit: 2MB
  - Allowed MIME types: `image/jpeg`, `image/png`, `image/webp`
  - RLS policies: Users can upload their own, Public read
- [ ] Create `order-documents` bucket (optional)
  - Public access: No
  - File size limit: 5MB
  - RLS policies: Users can read their own, Admins can read all

---

## 🔐 Phase 4: Authentication Flow Integration

### 4.1 Splash Screen → Role Selection
**Screen**: `lib/features/auth/presentation/role_selection_screen.dart`
- [ ] No backend integration needed (UI only)
- [ ] Navigate to login or admin login based on selection

### 4.2 User Login Flow
**Screen**: `lib/features/auth/presentation/login_screen.dart`
- [ ] Update `AuthRepository.signIn()` to use Supabase Auth
  - [ ] Call `supabase.auth.signInWithPassword(email, password)`
  - [ ] Handle email and mobile number login
  - [ ] Convert mobile to email format for auth
  - [ ] Store session in secure storage
  - [ ] Update `AuthState` with user info
- [ ] Update `AuthRepository.signInWithMobile()` 
  - [ ] Convert mobile to email format
  - [ ] Call Supabase Auth with converted email
  - [ ] Extract mobile from user metadata
- [ ] Handle errors: invalid credentials, network errors
- [ ] After successful login:
  - [ ] Call `ensureProfileExists()` to sync profile
  - [ ] Navigate to home screen
- [ ] Test: Login with email
- [ ] Test: Login with mobile number
- [ ] Test: Invalid credentials handling
- [ ] Test: Network error handling

### 4.3 User Signup Flow
**Screen**: `lib/features/auth/presentation/signup_screen.dart`
- [ ] Update `AuthRepository.signUp()` to use Supabase Auth
  - [ ] Call `supabase.auth.signUp(email, password, data: {name, mobile})`
  - [ ] Handle email confirmation (if enabled)
  - [ ] Store session
- [ ] Update `AuthRepository.signUpWithMobile()`
  - [ ] Convert mobile to email format
  - [ ] Call Supabase Auth with converted email
  - [ ] Store mobile in user metadata
- [ ] After successful signup:
  - [ ] Auto-create profile in `profiles` table
  - [ ] Navigate to home screen
- [ ] Test: Signup with email
- [ ] Test: Signup with mobile
- [ ] Test: Duplicate email/mobile handling
- [ ] Test: Password validation

### 4.4 Password Reset Flow
**Screen**: `lib/features/auth/presentation/forgot_password_screen.dart`
- [ ] Update `AuthRepository.resetPassword()` to use Supabase Auth
  - [ ] Call `supabase.auth.resetPasswordForEmail(email)`
  - [ ] Configure redirect URL in Supabase dashboard
- [ ] Update `AuthRepository.resetPasswordWithMobile()`
  - [ ] Convert mobile to email format
  - [ ] Call password reset with converted email
- [ ] Test: Password reset email sent
- [ ] Test: Password reset link handling

**Screen**: `lib/features/auth/presentation/password_reset_confirm_screen.dart`
- [ ] Update `AuthRepository.confirmRecovery()` to use Supabase Auth
  - [ ] Call `supabase.auth.updateUser({password: newPassword})`
  - [ ] Handle recovery token from URL
- [ ] Test: Password reset confirmation
- [ ] Test: Invalid/expired token handling

### 4.5 Admin Login Flow
**Screen**: `lib/features/admin/presentation/admin_login_screen.dart`
- [ ] Update `AdminAuthController` to use Supabase Auth
  - [ ] Call `supabase.auth.signInWithPassword(email, password)`
  - [ ] Verify user role from `profiles` table (role = 'admin' or 'manager' or 'support')
  - [ ] Reject login if not admin role
- [ ] Store admin session separately (optional)
- [ ] Test: Admin login with valid credentials
- [ ] Test: Admin login with user credentials (should fail)
- [ ] Test: Role verification

---

## 👤 Phase 5: Profile Management Flow Integration

### 5.1 Profile Screen
**Screen**: `lib/features/profile/presentation/profile_screen.dart`
- [ ] Update `ProfileRepository.getCurrentProfile()` to query Supabase
  - [ ] Get current user from `supabase.auth.currentUser`
  - [ ] Query `profiles` table: `SELECT * FROM profiles WHERE id = user.id`
  - [ ] Return `Profile` model
- [ ] Update `ProfileController.loadCurrentProfile()` to use repository
- [ ] Display profile data: name, email, mobile, avatar
- [ ] Handle loading state
- [ ] Handle error state
- [ ] Test: Load profile for authenticated user
- [ ] Test: Handle missing profile (create on first load)

### 5.2 Profile Edit Screen
**Screen**: `lib/features/profile/presentation/profile_edit_screen.dart`
- [ ] Update `ProfileRepository.updateProfile()` to use Supabase
  - [ ] Update `profiles` table: `UPDATE profiles SET name=?, email=?, mobile=?, ... WHERE id=?`
  - [ ] Update `updated_at` timestamp
  - [ ] Return updated profile
- [ ] Handle avatar upload:
  - [ ] Upload image to `profile-avatars` bucket
  - [ ] Get public URL
  - [ ] Update `avatar_url` in profile
- [ ] Update `ProfileController.updateProfile()` to use repository
- [ ] Form validation: name required, email format, mobile format
- [ ] Show success message on save
- [ ] Navigate back on success
- [ ] Test: Update profile name
- [ ] Test: Update profile email
- [ ] Test: Update profile mobile
- [ ] Test: Upload avatar image
- [ ] Test: Form validation

### 5.3 Address List Screen
**Screen**: `lib/features/profile/presentation/address_list_screen.dart`
- [ ] Update `AddressRepository.getAllAddresses()` to query Supabase
  - [ ] Query: `SELECT * FROM addresses WHERE user_id = ? ORDER BY is_default DESC, created_at DESC`
  - [ ] Return list of `Address` models
- [ ] Display addresses with default indicator
- [ ] Handle empty state
- [ ] Test: Load user addresses
- [ ] Test: Display default address first

### 5.4 Address Form Screen (Add/Edit)
**Screen**: `lib/features/profile/presentation/address_form_screen.dart`
- [ ] Update `AddressRepository.createAddress()` to use Supabase
  - [ ] Insert: `INSERT INTO addresses (user_id, name, phone, address, city, state, pincode, coordinates, is_default) VALUES (...)`
  - [ ] If `is_default = true`, update other addresses to `is_default = false`
  - [ ] Return created address
- [ ] Update `AddressRepository.updateAddress()` to use Supabase
  - [ ] Update: `UPDATE addresses SET ... WHERE id = ? AND user_id = ?`
  - [ ] Handle default address logic
- [ ] Update `AddressRepository.deleteAddress()` to use Supabase
  - [ ] Delete: `DELETE FROM addresses WHERE id = ? AND user_id = ?`
- [ ] Handle map picker for coordinates (lat/lng)
- [ ] Form validation: all fields required, pincode format
- [ ] Test: Create new address
- [ ] Test: Update existing address
- [ ] Test: Delete address
- [ ] Test: Set default address
- [ ] Test: Map picker coordinates

### 5.5 GST List Screen
**Screen**: `lib/features/profile/presentation/gst_list_screen.dart`
- [ ] Update `GstRepository.getAllGstRecords()` to query Supabase
  - [ ] Query: `SELECT * FROM gst_records WHERE user_id = ? ORDER BY is_default DESC, created_at DESC`
  - [ ] Return list of `GstDetails` models
- [ ] Display GST records with default indicator
- [ ] Handle empty state
- [ ] Test: Load user GST records

### 5.6 GST Form Screen (Add/Edit)
**Screen**: `lib/features/profile/presentation/gst_form_screen.dart`
- [ ] Update `GstRepository.createGstRecord()` to use Supabase
  - [ ] Insert: `INSERT INTO gst_records (user_id, gst_number, business_name, ...) VALUES (...)`
  - [ ] Validate GST number format (15 characters, alphanumeric)
  - [ ] Handle default GST logic
- [ ] Update `GstRepository.updateGstRecord()` to use Supabase
  - [ ] Update: `UPDATE gst_records SET ... WHERE id = ? AND user_id = ?`
- [ ] Update `GstRepository.deleteGstRecord()` to use Supabase
  - [ ] Delete: `DELETE FROM gst_records WHERE id = ? AND user_id = ?`
- [ ] Form validation: GST number format, business name, address fields
- [ ] Test: Create new GST record
- [ ] Test: Update existing GST record
- [ ] Test: Delete GST record
- [ ] Test: GST number validation

### 5.7 Settings Screen
**Screen**: `lib/features/profile/presentation/settings_screen.dart`
- [ ] Update password functionality:
  - [ ] Use `supabase.auth.updateUser({password: newPassword})`
  - [ ] Verify current password first
- [ ] Sign out functionality:
  - [ ] Call `supabase.auth.signOut()`
  - [ ] Clear local state
  - [ ] Navigate to role selection
- [ ] Test: Update password
- [ ] Test: Sign out

---

## 🛍️ Phase 6: Catalog & Product Flow Integration

### 6.1 Home Screen
**Screen**: `lib/features/home/presentation/home_screen.dart`
- [ ] Update featured products loading:
  - [ ] Query: `SELECT * FROM products WHERE is_active = true ORDER BY created_at DESC LIMIT 6`
  - [ ] Load product images from storage
- [ ] Update categories loading:
  - [ ] Query: `SELECT * FROM categories WHERE is_active = true ORDER BY sort_order, name`
  - [ ] Load category images from storage
- [ ] Update category product rows:
  - [ ] For each category, query: `SELECT * FROM products WHERE categories @> ARRAY[?] AND is_active = true LIMIT 6`
- [ ] Handle loading states
- [ ] Handle error states
- [ ] Test: Load featured products
- [ ] Test: Load categories
- [ ] Test: Load category products

### 6.2 Categories Screen
**Screen**: `lib/features/catalog/presentation/categories_screen.dart`
- [ ] Update `CategoryService.getAllCategories()` to query Supabase
  - [ ] Query: `SELECT * FROM categories WHERE is_active = true ORDER BY sort_order, name`
  - [ ] Return list of `Category` models
- [ ] Display categories in grid/list view
- [ ] Handle search functionality (client-side filter)
- [ ] Test: Load all categories
- [ ] Test: Search categories
- [ ] Test: Navigate to browse products

### 6.3 Browse Products Screen
**Screen**: `lib/features/catalog/presentation/browse_products_screen.dart`
- [ ] Update `ProductRepository.fetchByCategory()` to query Supabase
  - [ ] Query: `SELECT * FROM products WHERE categories @> ARRAY[?] AND is_active = true ORDER BY created_at DESC`
  - [ ] Implement pagination: `LIMIT ? OFFSET ?`
  - [ ] Return paginated products
- [ ] Update infinite scroll provider to use repository
- [ ] Load product images from storage
- [ ] Handle loading states
- [ ] Handle empty state
- [ ] Test: Browse by category
- [ ] Test: Pagination
- [ ] Test: Infinite scroll

### 6.4 Product Detail Screen
**Screen**: `lib/features/catalog/presentation/product_detail_screen.dart`
- [ ] Update `ProductRepository.fetchById()` to query Supabase
  - [ ] Query: `SELECT * FROM products WHERE id = ? AND is_active = true`
  - [ ] Query variants: `SELECT * FROM product_variants WHERE product_id = ?`
  - [ ] Query measurements: `SELECT * FROM product_measurements WHERE product_id = ?`
  - [ ] Return complete `Product` model
- [ ] Track product view:
  - [ ] Insert into `product_views` table
  - [ ] Record user_id, session_id, source, timestamp
- [ ] Load product images from storage (gallery)
- [ ] Display product info: name, price, description, variants, measurements
- [ ] Handle variant selection
- [ ] Handle measurement unit selection
- [ ] Add to cart functionality (local state, see cart section)
- [ ] Test: Load product details
- [ ] Test: Load variants
- [ ] Test: Load measurements
- [ ] Test: Track product view
- [ ] Test: Add to cart

### 6.5 Search Products Screen
**Screen**: `lib/features/catalog/presentation/search_products_screen.dart`
- [ ] Update search functionality to query Supabase
  - [ ] Use full-text search: `SELECT * FROM products WHERE is_active = true AND (name ILIKE ? OR description ILIKE ? OR alternative_names @> ARRAY[?])`
  - [ ] Or use Postgres full-text search: `to_tsvector('english', name || ' ' || description) @@ plainto_tsquery('english', ?)`
  - [ ] Search in alternative_names array
- [ ] Track search query:
  - [ ] Insert into `search_queries` table
  - [ ] Record query, user_id, results_count
- [ ] Display search results
- [ ] Handle loading states
- [ ] Handle empty results
- [ ] Test: Search by product name
- [ ] Test: Search by alternative name
- [ ] Test: Search by description
- [ ] Test: Track search queries

---

## 🛒 Phase 7: Cart Flow Integration

### 7.1 Cart Screen
**Screen**: `lib/features/cart/presentation/cart_screen.dart`
- [ ] Update cart persistence:
  - [ ] Option A: Keep cart in local state only (simpler)
  - [ ] Option B: Sync cart to `carts` table (recommended for multi-device)
- [ ] If using Option B:
  - [ ] On app start: Load cart from `carts` table for authenticated user
  - [ ] On cart change: Upsert cart to `carts` table
  - [ ] Merge local cart with server cart on login
- [ ] Calculate totals:
  - [ ] Subtotal: sum of (price * quantity) for all items
  - [ ] Shipping: free if subtotal >= 500, else 50
  - [ ] Tax: 18% of subtotal
  - [ ] Total: subtotal + shipping + tax
- [ ] Handle measurement-based pricing in calculations
- [ ] Display cart items with images from storage
- [ ] Handle empty cart state
- [ ] Test: Add item to cart
- [ ] Test: Update item quantity
- [ ] Test: Remove item from cart
- [ ] Test: Calculate totals correctly
- [ ] Test: Cart persistence (if Option B)

### 7.2 Sticky Cart Button
**Widget**: `lib/core/ui/sticky_cart_button.dart`
- [ ] Display cart item count from cart provider
- [ ] Navigate to cart screen on tap
- [ ] No backend integration needed (UI only)

---

## 📋 Phase 8: Checkout & Order Flow Integration

### 8.1 Checkout Address Screen
**Screen**: `lib/features/cart/presentation/checkout_address_screen.dart`
- [ ] Load user addresses:
  - [ ] Query: `SELECT * FROM addresses WHERE user_id = ? ORDER BY is_default DESC`
  - [ ] Display address list
- [ ] Allow selecting existing address or creating new one
- [ ] Handle map picker for new address coordinates
- [ ] Validate address before proceeding
- [ ] Test: Select existing address
- [ ] Test: Create new address during checkout
- [ ] Test: Map picker for coordinates

### 8.2 Order Creation
**Controller**: `lib/features/orders/application/order_controller.dart`
- [ ] Update `OrderRepository.createOrder()` to use Supabase
  - [ ] Generate unique order number: `ORD-{timestamp}-{random}`
  - [ ] Calculate totals (subtotal, shipping, tax, total)
  - [ ] Insert into `orders` table:
    ```sql
    INSERT INTO orders (order_number, user_id, status, subtotal, shipping, tax, total, delivery_address, notes)
    VALUES (?, ?, 'confirmed', ?, ?, ?, ?, ?, ?)
    RETURNING *
    ```
  - [ ] Insert order items into `order_items` table:
    ```sql
    INSERT INTO order_items (order_id, product_id, variant_id, measurement_unit, name, image, price, quantity, size, color)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ```
  - [ ] Update product stock (decrement)
  - [ ] Clear user cart
  - [ ] Return created order
- [ ] Handle errors: insufficient stock, network errors
- [ ] Test: Create order with items
- [ ] Test: Create order with variants
- [ ] Test: Create order with measurements
- [ ] Test: Stock decrement
- [ ] Test: Cart clearing

### 8.3 Order Confirmation Screen
**Screen**: `lib/features/orders/presentation/order_confirmation_screen.dart`
- [ ] Display order details from created order
- [ ] Show order number, items, totals, delivery address
- [ ] Navigate to orders list or home
- [ ] Test: Display order confirmation
- [ ] Test: Navigation after confirmation

### 8.4 Orders List Screen
**Screen**: `lib/features/orders/presentation/orders_list_screen.dart`
- [ ] Update `OrderRepository.getUserOrders()` to query Supabase
  - [ ] Query: `SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC`
  - [ ] Join with `order_items` to get item details
  - [ ] Return list of `Order` models
- [ ] Display orders with status chips
- [ ] Handle loading states
- [ ] Handle empty state
- [ ] Pull to refresh
- [ ] Test: Load user orders
- [ ] Test: Display order status
- [ ] Test: Refresh orders

### 8.5 Order Detail Screen
**Screen**: `lib/features/orders/presentation/order_detail_screen.dart`
- [ ] Update `OrderRepository.getOrderById()` to query Supabase
  - [ ] Query: `SELECT * FROM orders WHERE id = ? AND user_id = ?`
  - [ ] Query: `SELECT * FROM order_items WHERE order_id = ?`
  - [ ] Return complete `Order` model
- [ ] Display order details: items, totals, address, status, tracking
- [ ] Allow cancel order (if status = 'confirmed')
  - [ ] Update order status to 'cancelled'
  - [ ] Restore product stock
- [ ] Test: Load order details
- [ ] Test: Cancel order
- [ ] Test: Display tracking number

---

## 👨‍💼 Phase 9: Admin Panel Flow Integration

### 9.1 Admin Dashboard Screen
**Screen**: `lib/features/admin/presentation/admin_dashboard_screen.dart`
- [ ] Update `AdminDashboardController` to query Supabase
  - [ ] Total orders: `SELECT COUNT(*) FROM orders`
  - [ ] Total revenue: `SELECT SUM(total) FROM orders WHERE status != 'cancelled'`
  - [ ] Total products: `SELECT COUNT(*) FROM products`
  - [ ] Total customers: `SELECT COUNT(*) FROM profiles WHERE role = 'user'`
  - [ ] Recent orders: `SELECT * FROM orders ORDER BY created_at DESC LIMIT 10`
  - [ ] Top products: Aggregate from `order_items` with `product_id` grouping
- [ ] Display metrics cards
- [ ] Display recent orders list
- [ ] Display top products list
- [ ] Real-time updates (optional: use Supabase Realtime)
- [ ] Test: Load dashboard metrics
- [ ] Test: Display recent orders
- [ ] Test: Display top products

### 9.2 Admin Products Screen
**Screen**: `lib/features/admin/presentation/admin_products_screen.dart`
- [ ] Update `AdminProductController.loadProducts()` to query Supabase
  - [ ] Query: `SELECT * FROM products ORDER BY created_at DESC`
  - [ ] Implement search: `WHERE name ILIKE ? OR sku ILIKE ? OR alternative_names @> ARRAY[?]`
  - [ ] Implement category filter: `WHERE categories @> ARRAY[?]`
- [ ] Update `AdminProductController.addProduct()` to use Supabase
  - [ ] Upload images to `product-images` bucket
  - [ ] Get image URLs
  - [ ] Insert: `INSERT INTO products (name, subtitle, description, price, ...) VALUES (...) RETURNING *`
  - [ ] Insert variants if any
  - [ ] Insert measurements if any
- [ ] Update `AdminProductController.updateProduct()` to use Supabase
  - [ ] Update: `UPDATE products SET ... WHERE id = ?`
  - [ ] Handle image updates
  - [ ] Update variants
  - [ ] Update measurements
- [ ] Update `AdminProductController.deleteProduct()` to use Supabase
  - [ ] Soft delete: `UPDATE products SET is_active = false WHERE id = ?`
  - [ ] Or hard delete: `DELETE FROM products WHERE id = ?` (cascades to variants/measurements)
- [ ] Test: Load all products
- [ ] Test: Search products
- [ ] Test: Filter by category
- [ ] Test: Add product
- [ ] Test: Update product
- [ ] Test: Delete product
- [ ] Test: Upload product images

### 9.3 Admin Product Form Screen
**Screen**: `lib/features/admin/presentation/admin_product_form_screen.dart`
- [ ] Form fields: name, subtitle, description, price, brand, SKU, stock, categories, tags, images
- [ ] Variant management:
  - [ ] Add/remove variants
  - [ ] Variant attributes (Size, Color, etc.)
  - [ ] Variant price and stock
- [ ] Measurement pricing management:
  - [ ] Add/remove measurement units
  - [ ] Unit price and stock
- [ ] Image upload:
  - [ ] Upload to `product-images` bucket
  - [ ] Set primary image
  - [ ] Manage image gallery
- [ ] Save product (create or update)
- [ ] Test: Create product with all fields
- [ ] Test: Create product with variants
- [ ] Test: Create product with measurements
- [ ] Test: Upload multiple images
- [ ] Test: Update existing product

### 9.4 Admin Orders Screen
**Screen**: `lib/features/admin/presentation/admin_orders_screen.dart`
- [ ] Update `AdminOrderController.loadOrders()` to query Supabase
  - [ ] Query: `SELECT * FROM orders ORDER BY created_at DESC`
  - [ ] Implement search: `WHERE order_number ILIKE ? OR delivery_address->>'name' ILIKE ?`
  - [ ] Implement status filter: `WHERE status = ?`
  - [ ] Implement date range filter
- [ ] Display orders with status, customer, total, date
- [ ] Update order status:
  - [ ] `UPDATE orders SET status = ?, tracking_number = ?, updated_at = NOW() WHERE id = ?`
- [ ] Test: Load all orders
- [ ] Test: Search orders
- [ ] Test: Filter by status
- [ ] Test: Update order status

### 9.5 Admin Order Detail Screen
**Screen**: `lib/features/admin/presentation/admin_order_detail_screen.dart`
- [ ] Load order details (same as user order detail)
- [ ] Load customer profile from `profiles` table
- [ ] Update order status with dropdown
- [ ] Add/update tracking number
- [ ] Add order notes
- [ ] Cancel order (if allowed)
- [ ] Test: Load order details
- [ ] Test: Update order status
- [ ] Test: Add tracking number
- [ ] Test: View customer details

### 9.6 Admin Customers Screen
**Screen**: `lib/features/admin/presentation/admin_customers_screen.dart`
- [ ] Update `AdminCustomerController.loadCustomers()` to query Supabase
  - [ ] Query: `SELECT p.*, COUNT(o.id) as total_orders, SUM(o.total) as total_spent, MAX(o.created_at) as last_order_date FROM profiles p LEFT JOIN orders o ON p.id = o.user_id WHERE p.role = 'user' GROUP BY p.id ORDER BY p.created_at DESC`
  - [ ] Implement search: `WHERE name ILIKE ? OR email ILIKE ? OR mobile ILIKE ?`
- [ ] Display customers with order stats
- [ ] Update customer status (activate/deactivate)
  - [ ] Add `is_active` field to profiles table if not exists
  - [ ] `UPDATE profiles SET is_active = ? WHERE id = ?`
- [ ] Test: Load all customers
- [ ] Test: Search customers
- [ ] Test: View customer details
- [ ] Test: Update customer status

### 9.7 Admin Category Management Screen
**Screen**: `lib/features/admin/presentation/admin_category_management_screen.dart`
- [ ] Update `CategoryService` to use Supabase
  - [ ] Load: `SELECT * FROM categories ORDER BY sort_order, name`
  - [ ] Create: `INSERT INTO categories (name, description, image_url, parent_id, sort_order) VALUES (...)`
  - [ ] Update: `UPDATE categories SET ... WHERE id = ?`
  - [ ] Delete: `UPDATE categories SET is_active = false WHERE id = ?` (soft delete)
- [ ] Upload category images to `category-images` bucket
- [ ] Handle parent categories (hierarchy)
- [ ] Test: Load categories
- [ ] Test: Create category
- [ ] Test: Update category
- [ ] Test: Delete category
- [ ] Test: Upload category image

### 9.8 Admin Analytics Screen
**Screen**: `lib/features/admin/presentation/admin_analytics_screen.dart`
- [ ] Update analytics queries:
  - [ ] Revenue metrics: Aggregate from `orders` table
  - [ ] Order metrics: Count and group by status
  - [ ] Product metrics: Aggregate from `order_items`
  - [ ] Customer metrics: Aggregate from `profiles` and `orders`
  - [ ] Product views: Aggregate from `product_views`
  - [ ] Search queries: Aggregate from `search_queries`
- [ ] Date range filtering
- [ ] Chart data generation
- [ ] Test: Load analytics data
- [ ] Test: Filter by date range
- [ ] Test: Display charts

### 9.9 Admin Inventory Screen
**Screen**: `lib/features/admin/presentation/admin_inventory_screen.dart`
- [ ] Update inventory queries:
  - [ ] Load: `SELECT p.id, p.name, p.stock, pv.stock as variant_stock, pm.stock as measurement_stock FROM products p LEFT JOIN product_variants pv ON p.id = pv.product_id LEFT JOIN product_measurements pm ON p.id = pm.product_id WHERE p.is_active = true`
  - [ ] Low stock alerts: `SELECT * FROM inventory_alerts WHERE is_resolved = false`
- [ ] Update stock:
  - [ ] `UPDATE products SET stock = ? WHERE id = ?`
  - [ ] `UPDATE product_variants SET stock = ? WHERE id = ?`
  - [ ] `UPDATE product_measurements SET stock = ? WHERE id = ?`
- [ ] Create stock alerts when stock < threshold
- [ ] Test: Load inventory
- [ ] Test: Update stock
- [ ] Test: View low stock alerts

### 9.10 Admin Notifications Screen
**Screen**: `lib/features/admin/presentation/admin_notifications_screen.dart`
- [ ] Load notifications: `SELECT * FROM notifications ORDER BY created_at DESC`
- [ ] Create notification:
  - [ ] `INSERT INTO notifications (type, subject, body, recipients, priority, status) VALUES (...)`
- [ ] Send notification (integrate with email service or Supabase Edge Functions)
- [ ] Update notification status
- [ ] Test: Load notifications
- [ ] Test: Create notification
- [ ] Test: Send notification

### 9.11 Admin Content Screen
**Screen**: `lib/features/admin/presentation/admin_content_screen.dart`
- [ ] Create `content_items` table if needed:
  ```sql
  id UUID PRIMARY KEY,
  title TEXT NOT NULL,
  slug TEXT UNIQUE,
  content TEXT,
  type TEXT,
  status TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
  ```
- [ ] CRUD operations for content
- [ ] Test: Manage content items

### 9.12 Admin SEO Screen
**Screen**: `lib/features/admin/presentation/admin_seo_screen.dart`
- [ ] Create SEO-related tables if needed
- [ ] Manage meta tags, sitemaps, robots.txt
- [ ] Test: SEO management

### 9.13 Admin Marketing Screen
**Screen**: `lib/features/admin/presentation/admin_marketing_screen.dart`
- [ ] Create `marketing_campaigns` table if needed
- [ ] Manage campaigns, templates, rules
- [ ] Test: Marketing campaign management

### 9.14 Customer Browsing Analytics Screen
**Screen**: `lib/features/admin/presentation/customer_browsing_analytics_screen.dart`
- [ ] Query `product_views` table:
  - [ ] Group by user_id, product_id
  - [ ] Aggregate view counts, durations
  - [ ] Filter by date range
- [ ] Display analytics charts and tables
- [ ] Test: Load browsing analytics

---

## 🔄 Phase 10: Real-time Features (Optional)

### 10.1 Real-time Order Updates
- [ ] Subscribe to `orders` table changes
  - [ ] Use Supabase Realtime: `supabase.from('orders').stream(primaryKey: ['id']).listen(...)`
  - [ ] Update order status in real-time
- [ ] Test: Real-time order status updates

### 10.2 Real-time Inventory Updates
- [ ] Subscribe to `products` table stock changes
- [ ] Update inventory screen in real-time
- [ ] Test: Real-time stock updates

### 10.3 Real-time Dashboard Metrics
- [ ] Subscribe to orders, products, customers tables
- [ ] Update dashboard metrics in real-time
- [ ] Test: Real-time dashboard updates

---

## 🧪 Phase 11: Testing & Validation

### 11.1 Unit Tests
- [ ] Update all repository unit tests to use Supabase mocks
- [ ] Test authentication flows
- [ ] Test profile CRUD operations
- [ ] Test product queries
- [ ] Test order creation
- [ ] Test cart operations
- [ ] Test admin operations

### 11.2 Integration Tests
- [ ] Test complete user signup → login → browse → cart → checkout flow
- [ ] Test admin login → product management → order management flow
- [ ] Test profile management flow
- [ ] Test address management flow
- [ ] Test order tracking flow

### 11.3 E2E Tests
- [ ] Test complete shopping journey
- [ ] Test admin product creation
- [ ] Test order processing
- [ ] Test customer management

### 11.4 Performance Tests
- [ ] Test product list loading with large datasets
- [ ] Test search performance
- [ ] Test order creation performance
- [ ] Test image loading performance

---

## 🔒 Phase 12: Security & Optimization

### 12.1 RLS Policy Review
- [ ] Review all RLS policies for security
- [ ] Test unauthorized access attempts
- [ ] Verify user data isolation
- [ ] Verify admin-only operations

### 12.2 Index Optimization
- [ ] Review all indexes for query performance
- [ ] Add missing indexes for frequently queried fields
- [ ] Monitor query performance

### 12.3 Image Optimization
- [ ] Implement image compression on upload
- [ ] Use CDN for image delivery
- [ ] Implement lazy loading
- [ ] Optimize image sizes

### 12.4 Caching Strategy
- [ ] Implement caching for product lists
- [ ] Implement caching for categories
- [ ] Cache user profile data
- [ ] Cache order history

### 12.5 Error Handling
- [ ] Implement comprehensive error handling
- [ ] Handle network errors gracefully
- [ ] Handle authentication errors
- [ ] Handle validation errors
- [ ] Log errors for debugging

---

## 📝 Phase 13: Documentation & Deployment

### 13.1 Code Documentation
- [ ] Document all repository methods
- [ ] Document database schema
- [ ] Document RLS policies
- [ ] Document API endpoints (if using Edge Functions)

### 13.2 Deployment Checklist
- [ ] Set up production Supabase project
- [ ] Run database migrations
- [ ] Configure production RLS policies
- [ ] Set up production storage buckets
- [ ] Configure production environment variables
- [ ] Test production deployment
- [ ] Set up monitoring and alerts

### 13.3 Migration Plan
- [ ] Plan data migration from mock to Supabase
- [ ] Create migration scripts
- [ ] Test migration on staging
- [ ] Execute production migration
- [ ] Verify data integrity

---

## ✅ Completion Checklist

### Critical Path (Must Complete)
- [ ] Phase 1: Supabase Setup
- [ ] Phase 2: Database Schema (Core tables)
- [ ] Phase 4: Authentication Flow
- [ ] Phase 5: Profile Management
- [ ] Phase 6: Catalog & Products
- [ ] Phase 7: Cart
- [ ] Phase 8: Checkout & Orders
- [ ] Phase 9: Admin Panel (Core features)

### Important (Should Complete)
- [ ] Phase 3: Storage Buckets
- [ ] Phase 9: Admin Panel (All features)
- [ ] Phase 11: Testing
- [ ] Phase 12: Security

### Optional (Nice to Have)
- [ ] Phase 10: Real-time Features
- [ ] Phase 13: Advanced Documentation

---

## 📊 Progress Tracking

**Overall Progress**: 0% (0/200+ tasks completed)

**Phase Completion**:
- Phase 1: 0%
- Phase 2: 0%
- Phase 3: 0%
- Phase 4: 0%
- Phase 5: 0%
- Phase 6: 0%
- Phase 7: 0%
- Phase 8: 0%
- Phase 9: 0%
- Phase 10: 0%
- Phase 11: 0%
- Phase 12: 0%
- Phase 13: 0%

---

## 🎯 Next Steps

1. **Start with Phase 1**: Set up Supabase project and configuration
2. **Complete Phase 2**: Create all database tables and RLS policies
3. **Implement Phase 4**: Get authentication working end-to-end
4. **Build incrementally**: Complete one feature flow at a time
5. **Test thoroughly**: Test each phase before moving to the next

---

**Last Updated**: [Current Date]
**Status**: Planning Phase
**Estimated Completion**: [TBD]
















