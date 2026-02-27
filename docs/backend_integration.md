Backend Integration Plan (Appwrite)

Overview
- Goal: Integrate Appwrite as the backend for the existing Flutter app without changing current UX flows.
- Scope: Configure Appwrite client, define data models/collections, map features to backend operations, and outline testing plans. No new UI changes in this phase.
- Status: Appwrite client initialisation is in place via `appwriteClientProvider` using credentials from `Environment`.

Appwrite Setup
- Client: `Client` initialised with `Environment.appwritePublicEndpoint` and `Environment.appwriteProjectId`.
- Providers: `appwriteClientProvider` and `accountProvider` (Riverpod).
- Next: Add providers for `Databases`, `Storage`, `Functions` as needed per features.

Data Models and Collections (Suggested)
- Users (Account + Profiles collection)
  - Collection: `profiles`
  - Fields: `userId` (string, PK/unique), `name` (string), `email` (string), `phone` (string, optional), `alias` (string, optional), `gender` (string, optional), `dateOfBirth` (datetime, optional), `createdAt` (datetime)
  - Indexes: `email`, `alias`, `phone`
- Addresses
  - Collection: `addresses`
  - Fields: `userId`, `name`, `phone`, `addressLine`, `city`, `state`, `pincode`, `notes` (optional), `location` (lat,lng optional), `isDefault` (bool), `createdAt`
  - Indexes: `userId`, `isDefault`
- GST Records
  - Collection: `gst_records`
  - Fields: `userId`, `gstNumber`, `businessName`, `businessAddress`, `city`, `state`, `pincode`, `email`, `phone`, `isDefault` (bool), `createdAt`
  - Indexes: `userId`, `gstNumber`
- Products
  - Collection: `products`
  - Fields: `id`, `title`, `description`, `price`, `images` (array of file IDs), `category`, `collections` (array), `stock`, `attributes` (json), `createdAt`
  - Indexes: `category`, `collections`, text search on `title/description`
- Categories
  - Collection: `categories`
  - Fields: `id`, `name`, `image` (file ID), `createdAt`
  - Indexes: `name`
- Orders
  - Collection: `orders`
  - Fields: `id`, `userId`, `status`, `items` (array of item JSON), `total`, `deliveryAddress` (embedded: name, phone, address, alias), `createdAt`
  - Indexes: `userId`, `status`, `createdAt`
- Customers (Admin view)
  - Collection: `customers` (optional if not deriving directly from profiles + orders)
  - Fields: `userId`, `name`, `alias`, `email`, `phone`, `createdAt`, `lastOrderDate`, `totalOrders`, `totalSpent`, `isActive`
  - Indexes: `email`, `alias`, `phone`, `isActive`
- Analytics (optional)
  - Collections: `product_views`, `search_queries`, etc., or compute via Functions.

Feature-to-Screen Map and Backend Requirements

Authentication (User)
- Screens: `role_selection_screen`, `login_screen`, `signup_screen`, `forgot_password_screen`
- Backend:
  - Sign Up: `Account.create` (email/password, name)
  - Sign In: `Account.createEmailPasswordSession`
  - Reset Password: `Account.createRecovery` + `Account.updateRecovery`
  - Update Password: `Account.updatePassword`
- Testing:
  - Unit: Auth repository methods call Account APIs and handle errors
  - Widget: Loading/error states; successful navigation after login
  - Integration: End-to-end session creation and sign-out with a test Appwrite project

Authentication (Admin)
- Screens: `admin_login_screen`
- Backend:
  - Sign In: Separate admin account or Appwrite Teams/roles; `Account.createEmailPasswordSession`
  - Authorisation: Admin role verification (custom `admins` collection or `Teams`)
- Testing:
  - Unit: Admin auth repository role checks
  - Widget: Guard redirects via `AdminAuthGuard`
  - Integration: Session creation + role gating to admin routes

Profile Management
- Screens: `profile_screen`, `profile_edit_screen`
- Backend:
  - Fetch/Update: `profiles` collection (read/write by `userId`)
  - Alias: persist in `profiles.alias` and reflect across orders/customers
- Testing:
  - Unit: Profile repo CRUD and field mapping
  - Widget: Edit form populates and saves; overview shows alias
  - Integration: Update profile, read back, and verify downstream alias sync

Addresses
- Screens: `address_list_screen`, `address_form_screen`, `checkout_address_screen`
- Backend:
  - CRUD: `addresses` collection
  - Default selection for checkout
- Testing:
  - Unit: Address repo CRUD and default logic
  - Widget: List rendering, form validation, save success/error
  - Integration: Create/edit/delete and use during checkout flow

GST Details
- Screens: `gst_list_screen`, `gst_form_screen`
- Backend:
  - CRUD: `gst_records` collection
- Testing:
  - Unit: GST repo CRUD and validation (format checks)
  - Widget: List rendering, form validation
  - Integration: Create/edit/delete GST records

Catalog and Search
- Screens: `categories_screen`, `browse_products_screen`, `product_detail_screen`, `search_products_screen`
- Backend:
  - Products: `products` collection read/list/filter
  - Categories: `categories` collection
  - Images: Appwrite `Storage` for product/category images
- Testing:
  - Unit: Query builders and repository filters
  - Widget: Grid/list rendering across breakpoints
  - Integration: Fetch lists, detail pages, search queries with indexes

Cart
- Screens: `cart_screen` (+ `StickyCartButton` control)
- Backend:
  - Option A (Simple): Local-only cart (no backend)
  - Option B (Recommended): `carts` collection by `userId` with `items` array
- Testing:
  - Unit: Cart item add/remove/update logic
  - Widget: Rendering totals and item interactions
  - Integration: Persist and restore cart for authenticated users

Checkout and Orders
- Screens: `checkout_address_screen`, `orders_list_screen`, `order_confirmation_screen`
- Backend:
  - Create Order: `orders` collection; compute totals server-side via `Functions`
  - Attach delivery address (with `alias`) to the order at creation
  - List Orders by `userId`
- Testing:
  - Unit: Order creation mapping, totals, statuses
  - Widget: Confirmation page shows accurate data
  - Integration: Create order, verify persistence and listing

Admin Orders and Customers
- Screens: `admin_orders_screen`, `admin_order_detail_screen`, `admin_customers_screen`, `admin_features_screen`, `admin_dashboard_screen` (implicit via tests), `customer_browsing_analytics_screen`
- Backend:
  - Orders: List/search by `status`, `createdAt`, `alias|name|phone`
  - Customers: Derived from `profiles` + `orders` or a `customers` collection
  - Dashboard: Aggregations via `Functions` (totals, revenue, low stock)
  - Analytics: Product view sessions via a `product_views` collection
- Testing:
  - Unit: Admin repos for filtering/sorting and aggregation adapters
  - Widget: List and detail screens across responsive layouts
  - Integration: Search filters, aggregates, and navigation

Storage (Media)
- Features: Profile pictures, product images, category icons
- Backend:
  - Upload/Read: Appwrite `Storage`
- Testing:
  - Unit: Storage wrapper functions
  - Integration: Upload/download cycles with test buckets

Functions (Server-side)
- Use Cases: Order totals validation, dashboard metrics, analytics processing
- Testing:
  - Unit: Function logic
  - Integration: Trigger via Appwrite SDK and validate outputs

SDK Providers to Add (Next)
- `databasesProvider`: `Databases(ref.read(appwriteClientProvider))`
- `storageProvider`: `Storage(ref.read(appwriteClientProvider))`
- `functionsProvider`: `Functions(ref.read(appwriteClientProvider))`

Testing Strategy (Per Feature)
- General
  - Use a separate Appwrite project/environment for tests
  - Clean up test data after runs; use unique IDs
- Auth
  - Sign up/in/out flows; recovery link handling (mock URL)
- Profile
  - Create/update/read profile; alias propagation
- Addresses/GST
  - Full CRUD with validation and default flags
- Catalog/Search
  - List/filter/search performance and correctness
- Cart
  - Persistence and merge logic post-login
- Orders
  - Creation with address snapshot; status transitions
- Admin
  - Role gating; listing/search; aggregation results
- Storage
  - Upload, list, retrieve, delete lifecycle

MCP Prompt Rules for Appwrite (Usage Guidelines)
- General
  - Always pass required parameters exactly as specified (e.g., `user_id`, `email`, `password`).
  - Prefer plain-text password `users.create` for new users; use hashed variants only for migrations.
  - Use `users.create_session` or `users.create_jwt` for authentication flows; set `duration` responsibly.
  - Never embed secrets or tokens in prompts; store them in secure config.
  - Validate lengths and allowed characters (e.g., `user_id` max 36, name max 128).
- Safety
  - Avoid leaking PII in logs; return minimal fields where possible.
  - Do not hardcode production endpoints or IDs in tests.
- Examples (Concise)
  - Create user:
    - Provide: `user_id`, `email`, `password`, `name`
  - Create session:
    - Provide: `user_id` (or `recent` session), `duration` if JWT
  - Update email/phone/name:
    - Provide new value and the target `user_id`
  - Enable MFA / recovery codes:
    - Use recovery code generation and factor listing endpoints as needed

Rollout Plan
- Phase 1: Profiles/Addresses/GST CRUD
- Phase 2: Products/Categories read-only integration + Storage for images
- Phase 3: Auth flows (user + admin) with role gating
- Phase 4: Orders creation/listing
- Phase 5: Admin aggregates and analytics via Functions

Notes
- Current client initialization is ready; enabling feature integrations requires adding repositories that call Appwrite providers and wiring them into controllers.
- Maintain consistent field names to align UI with backend documents (e.g., `alias`).