import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../main.dart';
import '../../core/ui/splash_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/password_reset_confirm_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/catalog/presentation/product_detail_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/cart/presentation/checkout_address_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/profile_edit_screen.dart';
import '../../features/profile/presentation/edit_full_profile_screen.dart';
import '../../features/profile/presentation/address_list_screen.dart';
import '../../features/profile/presentation/address_form_screen.dart';
import '../../features/profile/presentation/gst_list_screen.dart';
import '../../features/profile/presentation/gst_form_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/profile/presentation/help_support_screen.dart';
import '../../features/profile/presentation/terms_privacy_screen.dart';
import '../../features/wishlist/presentation/wishlist_screen.dart';
import '../../core/ui/app_scaffold.dart';
import '../../features/catalog/presentation/browse_products_screen.dart';
import '../../features/catalog/presentation/categories_screen.dart';
import '../../features/catalog/presentation/featured_products_screen.dart';
import '../../features/orders/presentation/orders_list_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/orders/presentation/order_confirmation_screen.dart';
import '../../features/orders/presentation/edit_reorder_screen.dart';
import '../../features/catalog/presentation/search_products_screen.dart';
import '../../features/catalog/presentation/compare_products_selection_screen.dart';
import '../../features/catalog/presentation/compare_products_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';

// Admin imports
import '../../features/admin/domain/cash_book_entry.dart';
import '../../features/admin/domain/credit_transaction.dart';
import '../../features/admin/domain/purchase_order.dart';
import '../../features/admin/presentation/admin_login_screen.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/admin_online_store_screen.dart';
import '../../features/admin/presentation/admin_products_screen.dart';
import '../../features/admin/presentation/admin_product_form_screen.dart';
import '../../features/admin/presentation/admin_product_detail_screen.dart';
import '../../features/admin/presentation/admin_orders_screen.dart';
import '../../features/admin/presentation/admin_order_detail_screen.dart';
import '../../features/admin/presentation/admin_create_order_screen.dart';
import '../../features/admin/presentation/orders_dashboard_screen.dart';
import '../../features/admin/presentation/open_orders_screen.dart';
import '../../features/admin/presentation/admin_customers_screen.dart';
import '../../features/admin/presentation/admin_create_customer_screen.dart';
import '../../features/admin/presentation/admin_customer_orders_screen.dart';
import '../../features/admin/presentation/admin_customer_form_screen.dart';
import '../../features/admin/presentation/admin_payment_receipt_screen.dart';
import '../../features/admin/presentation/admin_payment_receipt_detail_screen.dart';
import '../../features/admin/data/payment_receipt_repository.dart';
import '../../features/orders/data/order_model.dart';
import '../../features/admin/presentation/admin_analytics_screen.dart';
import '../../features/admin/presentation/customer_analytics_detail_screen.dart';
import '../../features/admin/presentation/user_location_screen.dart';
import '../../features/admin/presentation/admin_inventory_screen.dart';
import '../../features/admin/presentation/admin_notifications_screen.dart';
import '../../features/admin/presentation/admin_content_screen.dart';
import '../../features/admin/presentation/admin_seo_screen.dart';
import '../../features/admin/presentation/admin_marketing_screen.dart';
import '../../features/admin/presentation/admin_more_screen.dart';
import '../../features/admin/presentation/admin_features_screen.dart';
import '../../features/admin/presentation/admin_accounts_screen.dart';
import '../../features/admin/presentation/admin_account_detail_screen.dart';
import '../../features/admin/presentation/admin_cash_transaction_screen.dart';
import '../../features/admin/presentation/admin_transaction_detail_screen.dart';
import '../../features/admin/presentation/admin_create_account_screen.dart';
import '../../features/admin/presentation/admin_credit_system_screen.dart';
import '../../features/admin/presentation/admin_manufacturers_screen.dart';
import '../../features/admin/presentation/admin_manufacturer_form_screen.dart';
import '../../features/admin/presentation/admin_purchase_orders_screen.dart';
import '../../features/admin/presentation/admin_purchase_order_form_screen.dart';
import '../../features/admin/presentation/admin_purchase_order_detail_screen.dart';
import '../../features/admin/presentation/admin_hero_section_screen.dart';
import '../../features/admin/presentation/admin_featured_products_screen.dart';
import '../../features/admin/presentation/admin_category_management_screen.dart';
import '../../features/admin/presentation/admin_search_results_screen.dart';
import '../../features/admin/presentation/admin_ratings_screen.dart';
import '../../features/admin/presentation/admin_payment_in_list_screen.dart';
import '../../features/admin/presentation/admin_payment_out_list_screen.dart';
import '../../features/admin/presentation/admin_payment_out_screen.dart';
import '../../features/admin/presentation/admin_payment_out_detail_screen.dart';
import '../../features/admin/data/payment_out_pdf_service.dart';
import '../../features/admin/presentation/admin_store_form_screen.dart';
import '../../features/admin/presentation/admin_add_payment_screen.dart';
import '../../features/admin/presentation/admin_chat_screen.dart';
import '../../features/admin/presentation/admin_chat_detail_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'role',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot',
        name: 'forgot',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/password-reset',
        name: 'password-reset',
        builder: (context, state) {
          final qp = state.uri.queryParameters;
          final userId = qp['userId'] ?? '';
          final secret = qp['secret'] ?? '';
          return PasswordResetConfirmScreen(userId: userId, secret: secret);
        },
      ),

      // Admin Routes
      GoRoute(
        path: '/admin/login',
        name: 'admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/online-store',
        name: 'admin-online-store',
        builder: (context, state) => const AdminOnlineStoreScreen(),
      ),
      GoRoute(
        path: '/admin/store-details',
        name: 'admin-store-details',
        builder: (context, state) => const AdminStoreFormScreen(),
      ),
      GoRoute(
        path: '/admin/products',
        name: 'admin-products',
        builder: (context, state) => const AdminProductsScreen(),
        routes: [
          GoRoute(
            path: 'form',
            name: 'admin-product-form',
            builder: (context, state) {
              final product = state.extra as dynamic;
              return AdminProductFormScreen(product: product);
            },
          ),
          GoRoute(
            path: ':id',
            name: 'admin-product-detail',
            builder: (context, state) {
              final productId = state.pathParameters['id']!;
              return AdminProductDetailScreen(productId: productId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin/orders',
        name: 'admin-orders',
        builder: (context, state) => const AdminOrdersScreen(),
        routes: [
          GoRoute(
            path: 'dashboard',
            name: 'admin-orders-dashboard',
            builder: (context, state) => const OrdersDashboardScreen(),
          ),
          GoRoute(
            path: 'open',
            name: 'admin-open-orders',
            builder: (context, state) => const OpenOrdersScreen(),
          ),
          GoRoute(
            path: 'create',
            name: 'admin-create-order',
            builder: (context, state) {
              final customerId = state.uri.queryParameters['customerId'];
              return AdminCreateOrderScreen(customerId: customerId);
            },
          ),
          GoRoute(
            path: ':id',
            name: 'admin-order-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AdminOrderDetailScreen(orderId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin/customers',
        name: 'admin-customers',
        builder: (context, state) => const AdminCustomersScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'admin-create-customer',
            builder: (context, state) => const AdminCreateCustomerScreen(),
          ),
          GoRoute(
            path: ':customerId/edit',
            name: 'admin-customer-edit',
            builder: (context, state) {
              final customerId = state.pathParameters['customerId']!;
              return AdminCustomerFormScreen(customerId: customerId);
            },
          ),
          GoRoute(
            path: ':customerId/orders',
            name: 'admin-customer-orders',
            builder: (context, state) {
              final customerId = state.pathParameters['customerId']!;
              return AdminCustomerOrdersScreen(customerId: customerId);
            },
            routes: [
              GoRoute(
                path: ':orderId/payment',
                name: 'admin-payment-receipt',
                builder: (context, state) {
                  final customerId = state.pathParameters['customerId']!;
                  final orderId = state.pathParameters['orderId']!;
                  // Explicitly handle 'new' order case and ensure type safety
                  final order =
                      (orderId == 'new' || state.extra == null)
                          ? null
                          : (state.extra is Order
                              ? state.extra as Order
                              : null);
                  return AdminPaymentReceiptScreen(
                    customerId: customerId,
                    orderId: orderId,
                    order: order,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/admin/user-location',
        name: 'admin-user-location',
        builder: (context, state) {
          final qp = state.uri.queryParameters;
          final userId = qp['userId'] ?? '';
          final userName = qp['userName'];
          return UserLocationScreen(userId: userId, userName: userName);
        },
      ),
      GoRoute(
        path: '/admin/analytics',
        name: 'admin-analytics',
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
      GoRoute(
        path: '/admin/customer-analytics',
        name: 'admin-customer-analytics',
        builder: (context, state) {
          final args =
              state.extra as Map<String, dynamic>? ??
              (state.uri.queryParameters.isNotEmpty
                  ? {
                    'customerId': state.uri.queryParameters['customerId'] ?? '',
                    'customerName':
                        state.uri.queryParameters['customerName'] ?? '',
                    'customerEmail':
                        state.uri.queryParameters['customerEmail'] ?? '',
                    'customerPhone': state.uri.queryParameters['customerPhone'],
                  }
                  : {});
          return CustomerAnalyticsDetailScreen(
            customerId: args['customerId'] as String,
            customerName: args['customerName'] as String,
            customerEmail: args['customerEmail'] as String,
            customerPhone: args['customerPhone'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/admin/inventory',
        name: 'admin-inventory',
        builder: (context, state) => const AdminInventoryScreen(),
      ),
      GoRoute(
        path: '/admin/notifications',
        name: 'admin-notifications',
        builder: (context, state) => const AdminNotificationsScreen(),
      ),
      GoRoute(
        path: '/admin/content',
        name: 'admin-content',
        builder: (context, state) => const AdminContentScreen(),
      ),
      GoRoute(
        path: '/admin/seo',
        name: 'admin-seo',
        builder: (context, state) => const AdminSEOScreen(),
      ),
      GoRoute(
        path: '/admin/marketing',
        name: 'admin-marketing',
        builder: (context, state) => const AdminMarketingScreen(),
      ),
      GoRoute(
        path: '/admin/categories',
        name: 'admin-categories',
        builder: (context, state) => const AdminCategoryManagementScreen(),
      ),
      GoRoute(
        path: '/admin/more',
        name: 'admin-more',
        builder: (context, state) => const AdminMoreScreen(),
      ),
      GoRoute(
        path: '/admin/features',
        name: 'admin-features',
        builder: (context, state) => const AdminFeaturesScreen(),
      ),
      GoRoute(
        path: '/admin/accounts',
        name: 'admin-accounts',
        builder: (context, state) => const AdminAccountsScreen(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'admin-create-account',
            builder: (context, state) => const AdminCreateAccountScreen(),
          ),
          GoRoute(
            path: ':id',
            name: 'admin-account-detail',
            builder: (context, state) {
              final accountId = state.pathParameters['id']!;
              final extra = state.extra as Map<String, dynamic>?;
              final accountName = extra?['name'] as String? ?? 'Account';
              return AdminAccountDetailScreen(
                accountId: accountId,
                accountName: accountName,
              );
            },
            routes: [
              GoRoute(
                path: 'add-transaction',
                name: 'admin-transaction-add',
                builder: (context, state) {
                  final accountId = state.pathParameters['id']!;
                  final extra = state.extra as Map<String, dynamic>?;
                  final accountName =
                      extra?['accountName'] as String? ?? 'Account';
                  final typeIndex = int.parse(
                    state.uri.queryParameters['type'] ?? '0',
                  );
                  final type = CashBookEntryType.values[typeIndex];

                  return AdminCashTransactionScreen(
                    type: type,
                    accountId: accountId,
                    accountName: accountName,
                  );
                },
              ),
              GoRoute(
                path: 'edit-transaction',
                name: 'admin-transaction-edit',
                builder: (context, state) {
                  final accountId = state.pathParameters['id']!;
                  final extra = state.extra as Map<String, dynamic>?;
                  final accountName =
                      extra?['accountName'] as String? ?? 'Account';
                  final entry = extra?['entry'] as CashBookEntry;

                  return AdminCashTransactionScreen(
                    type: entry.type,
                    accountId: accountId,
                    accountName: accountName,
                    entry: entry,
                  );
                },
              ),
              GoRoute(
                path: 'transaction/:transactionId',
                name: 'admin-transaction-detail',
                builder: (context, state) {
                  final accountId = state.pathParameters['id']!;
                  final extra = state.extra as Map<String, dynamic>?;
                  final entry = extra?['entry'] as CashBookEntry;
                  final accountName =
                      extra?['accountName'] as String? ?? 'Account';

                  return AdminTransactionDetailScreen(
                    entry: entry,
                    accountId: accountId,
                    accountName: accountName,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/admin/payment-receipt-detail',
        name: 'admin-payment-receipt-detail',
        builder: (context, state) {
          final receipt = state.extra as PaymentReceipt;
          return AdminPaymentReceiptDetailScreen(receipt: receipt);
        },
      ),
      GoRoute(
        path: '/admin/payment-in-list',
        name: 'admin-payment-in-list',
        builder: (context, state) => const AdminPaymentInListScreen(),
      ),
      GoRoute(
        path: '/admin/payment-in-list/add',
        name: 'admin-add-payment',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return AdminAddPaymentScreen(
            customerId: args['customerId'] as String?,
            manufacturerId: args['manufacturerId'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/admin/payment-out',
        name: 'admin-payment-out',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return AdminPaymentOutScreen(
            manufacturerId: args['manufacturerId'] as String?,
            customerId: args['customerId'] as String?,
            purchaseOrderId: args['purchaseOrderId'] as String?,
            purchaseOrder: args['purchaseOrder'],
            transaction: args['transaction'] as CreditTransaction?,
          );
        },
      ),
      GoRoute(
        path: '/admin/payment-out-detail',
        name: 'admin-payment-out-detail',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? {};
          return AdminPaymentOutDetailScreen(
            transaction: args['transaction'] as CreditTransaction,
            purchaseOrder: args['purchaseOrder'] as PurchaseOrder?,
            paidTo: args['paidTo'] as PaidToInfo?,
          );
        },
      ),
      GoRoute(
        path: '/admin/payment-out-list',
        name: 'admin-payment-out-list',
        builder: (context, state) {
          final manufacturerId = state.uri.queryParameters['manufacturerId'];
          return AdminPaymentOutListScreen(manufacturerId: manufacturerId);
        },
      ),
      GoRoute(
        path: '/admin/credit-system',
        name: 'admin-credit-system',
        builder: (context, state) => const AdminCreditSystemScreen(),
      ),
      GoRoute(
        path: '/admin/featured-products',
        name: 'admin-featured-products',
        builder: (context, state) => const AdminFeaturedProductsScreen(),
      ),
      GoRoute(
        path: '/admin/search-results',
        name: 'admin-search-results',
        builder: (context, state) => const AdminSearchResultsScreen(),
      ),
      GoRoute(
        path: '/admin/hero-section',
        name: 'admin-hero-section',
        builder: (context, state) => const AdminHeroSectionScreen(),
      ),
      GoRoute(
        path: '/admin/ratings',
        name: 'admin-ratings',
        builder: (context, state) => const AdminRatingsScreen(),
      ),
      GoRoute(
        path: '/admin/chat',
        name: 'admin-chat',
        builder: (context, state) => const AdminChatScreen(),
        routes: [
          GoRoute(
            path: ':conversationId',
            name: 'admin-chat-detail',
            builder: (context, state) {
              final conversationId = state.pathParameters['conversationId']!;
              return AdminChatDetailScreen(conversationId: conversationId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin/manufacturers',
        name: 'admin-manufacturers',
        builder: (context, state) => const AdminManufacturersScreen(),
        routes: [
          GoRoute(
            path: 'add',
            name: 'admin-manufacturers-add',
            builder: (context, state) => const AdminManufacturerFormScreen(),
          ),
          GoRoute(
            path: ':id/edit',
            name: 'admin-manufacturers-edit',
            builder: (context, state) {
              final manufacturerId = state.pathParameters['id']!;
              return AdminManufacturerFormScreen(
                manufacturerId: manufacturerId,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/admin/purchase-orders',
        name: 'admin-purchase-orders',
        builder: (context, state) => const AdminPurchaseOrdersScreen(),
        routes: [
          GoRoute(
            path: 'new',
            name: 'admin-purchase-order-form',
            builder: (context, state) {
              final qp = state.uri.queryParameters;
              final orderId = qp['orderId'];
              final id = qp['id']; // For editing
              final manufacturerId = qp['manufacturerId'];
              final paymentReceiptId = qp['paymentReceiptId'];
              final customerId = qp['customerId'];
              final receiptNumber = qp['receiptNumber'];
              final amount = double.tryParse(qp['amount'] ?? '');
              final shipping = double.tryParse(qp['shipping'] ?? '');

              return AdminPurchaseOrderFormScreen(
                purchaseOrderId: id,
                manufacturerId: manufacturerId,
                orderId: orderId,
                paymentReceiptId: paymentReceiptId,
                customerId: customerId,
                receiptNumber: receiptNumber,
                paymentAmount: amount,
                initialShipping: shipping,
              );
            },
          ),
          GoRoute(
            path: ':id',
            name: 'admin-purchase-order-detail',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return AdminPurchaseOrderDetailScreen(purchaseOrderId: id);
            },
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/catalog',
            name: 'catalog',
            builder: (context, state) => const CategoriesScreen(),
          ),
          GoRoute(
            path: '/featured-products',
            name: 'featured-products',
            builder: (context, state) => const FeaturedProductsScreen(),
          ),
          GoRoute(
            path: '/cart',
            name: 'cart',
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrdersListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'order-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return OrderDetailScreen(orderId: id);
                },
              ),
              GoRoute(
                path: ':id/edit-reorder',
                name: 'edit-reorder',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final templateId = state.uri.queryParameters['templateId'];
                  return EditReorderScreen(orderId: id, templateId: templateId);
                },
              ),
              GoRoute(
                path: 'template/:templateId/edit',
                name: 'edit-template',
                builder: (context, state) {
                  final templateId = state.pathParameters['templateId']!;
                  return EditReorderScreen(
                    orderId: '', // Empty for template-only mode
                    templateId: templateId,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) {
              final conversationId =
                  state.uri.queryParameters['conversationId'];
              return ChatScreen(conversationId: conversationId);
            },
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit-full',
                name: 'profile-edit-full',
                builder: (context, state) => const EditFullProfileScreen(),
              ),
              GoRoute(
                path: 'edit',
                name: 'profile-edit',
                builder: (context, state) => const ProfileEditScreen(),
              ),
              GoRoute(
                path: 'settings',
                name: 'profile-settings',
                builder: (context, state) => const SettingsScreen(),
              ),
              GoRoute(
                path: 'help-support',
                name: 'profile-help-support',
                builder: (context, state) => const HelpSupportScreen(),
              ),
              GoRoute(
                path: 'terms-privacy',
                name: 'profile-terms-privacy',
                builder: (context, state) => const TermsPrivacyScreen(),
              ),
              GoRoute(
                path: 'addresses',
                name: 'profile-addresses',
                builder: (context, state) => const AddressListScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    name: 'profile-address-add',
                    builder: (context, state) => const AddressFormScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    name: 'profile-address-edit',
                    builder: (context, state) {
                      final addressId = state.pathParameters['id'];
                      return AddressFormScreen(editAddressId: addressId);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'gst',
                name: 'profile-gst',
                builder: (context, state) => const GstListScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    name: 'profile-gst-add',
                    builder: (context, state) => const GstFormScreen(),
                  ),
                  GoRoute(
                    path: 'edit/:index',
                    name: 'profile-gst-edit',
                    builder: (context, state) {
                      final index =
                          int.tryParse(state.pathParameters['index'] ?? '0') ??
                          0;
                      return GstFormScreen(editIndex: index);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'wishlist',
                name: 'profile-wishlist',
                builder: (context, state) => const WishlistScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/product/:id',
        name: 'product',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/browse/:kind/:value',
        name: 'browse',
        builder: (context, state) {
          final kind = state.pathParameters['kind']!;
          final value = state.pathParameters['value']!;
          return BrowseProductsScreen(kind: kind, value: value);
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchProductsScreen(),
      ),
      GoRoute(
        path: '/compare/select/:productId',
        name: 'compare-select',
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          return CompareProductsSelectionScreen(currentProductId: productId);
        },
      ),
      GoRoute(
        path: '/compare/:productIds',
        name: 'compare',
        builder: (context, state) {
          final productIds = state.pathParameters['productIds']!;
          return CompareProductsScreen(productIds: productIds);
        },
      ),
      GoRoute(
        path: '/checkout/address',
        name: 'checkout-address',
        builder: (context, state) => const CheckoutAddressScreen(),
      ),
      GoRoute(
        path: '/order-confirmation/:orderId',
        name: 'order-confirmation',
        builder: (context, state) {
          final orderId = state.pathParameters['orderId']!;
          return OrderConfirmationScreen(orderId: orderId);
        },
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Not found')),
          body: Center(child: Text(state.error.toString())),
        ),
    observers: [
      // Add navigator observers here if needed
    ],
    debugLogDiagnostics: false,
  );
});
