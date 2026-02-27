import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/layout/responsive.dart';
import '../../ratings/data/rating_repository.dart';
import '../../ratings/presentation/widgets/star_rating_widget.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../admin/data/admin_features.dart';

class DeliveredOrdersRatingScreen extends ConsumerStatefulWidget {
  const DeliveredOrdersRatingScreen({super.key});

  @override
  ConsumerState<DeliveredOrdersRatingScreen> createState() =>
      _DeliveredOrdersRatingScreenState();
}

class _DeliveredOrdersRatingScreenState
    extends ConsumerState<DeliveredOrdersRatingScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _orders = [];
  Map<String, int> _ratings = {}; // product_id -> rating (submitted)
  Map<String, int> _pendingRatings = {}; // product_id -> rating (pending, not yet submitted)
  Map<String, String> _feedbacks = {}; // product_id -> feedback
  Map<String, TextEditingController> _feedbackControllers = {}; // product_id -> controller
  Map<String, ProductRating?> _existingRatings = {}; // product_id -> existing rating
  Map<String, bool> _submitting = {}; // product_id -> is submitting

  @override
  void initState() {
    super.initState();
    // Ensure all maps are initialized (handles hot reload issues)
    _ratings = _ratings ?? {};
    _pendingRatings = _pendingRatings ?? {};
    _feedbacks = _feedbacks ?? {};
    _submitting = _submitting ?? {};
    _existingRatings = _existingRatings ?? {};
    _feedbackControllers = _feedbackControllers ?? {};
    _loadDeliveredOrders();
  }

  @override
  void dispose() {
    for (final controller in _feedbackControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDeliveredOrders() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to rate products')),
          );
          context.pop();
        }
        return;
      }

      final repository = ref.read(ratingRepositoryProvider);
      final orders = await repository.getDeliveredOrdersForRating(userId);
      
      if (!mounted) return;
      
      // Collect all product IDs that have existing ratings (batch optimization)
      final productIdsToLoad = <String>[];
      for (final order in orders) {
        final products = order['products'] as List<dynamic>? ?? [];
        for (final product in products) {
          final productData = product as Map<String, dynamic>;
          final productId = productData['product_id'] as String;
          final existingRating = productData['existing_rating'] as int?;
          
          if (existingRating != null) {
            productIdsToLoad.add(productId);
          }
        }
      }
      
      // Load all existing ratings in a single batch query
      final existingRatingsMap = <String, ProductRating?>{};
      if (productIdsToLoad.isNotEmpty) {
        try {
          final ratingsBatch = await repository.getUserRatingsBatch(productIdsToLoad, userId);
          existingRatingsMap.addAll(ratingsBatch);
        } catch (e) {
          // Ignore errors loading batch ratings
          if (kDebugMode) {
            print('Error loading ratings batch: $e');
          }
        }
      }
      
      // Initialize state maps with the loaded ratings
      // Ensure maps are initialized before accessing (critical for hot reload)
      _feedbackControllers ??= {};
      _feedbacks ??= {};
      _ratings ??= {};
      _pendingRatings ??= {};
      
      for (final entry in existingRatingsMap.entries) {
        final productId = entry.key;
        final rating = entry.value;
        if (rating != null && mounted) {
          _feedbackControllers[productId] = TextEditingController(text: rating.feedback ?? '');
          _feedbacks[productId] = rating.feedback ?? '';
          _ratings[productId] = rating.rating;
          _pendingRatings[productId] = rating.rating; // Initialize pending with existing
        }
      }
      
      if (mounted) {
        setState(() {
          _orders = orders;
          _existingRatings = existingRatingsMap;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading orders: $e')),
        );
      }
    }
  }

  Future<void> _submitRating(String productId) async {
    // Ensure maps are initialized
    _pendingRatings ??= {};
    _feedbacks ??= {};
    _submitting ??= {};
    final pendingRating = _pendingRatings[productId];
    if (pendingRating == null || pendingRating == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a rating first'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _submitting[productId] = true;
    });

    try {
      final userId = ref.read(supabaseClientProvider).auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          setState(() {
            _submitting[productId] = false;
          });
        }
        return;
      }

      final repository = ref.read(ratingRepositoryProvider);
      
      // Find the order ID for this product
      String? orderId;
      for (final order in _orders) {
        final products = order['products'] as List<dynamic>?;
        if (products != null) {
          for (final product in products) {
            if ((product as Map<String, dynamic>)['product_id'] == productId) {
              orderId = order['order_id'] as String?;
              break;
            }
          }
        }
        if (orderId != null) break;
      }

      final feedbackText = _feedbacks[productId] ?? '';
      
      await repository.createOrUpdateRating(
        productId: productId,
        userId: userId,
        rating: pendingRating,
        orderId: orderId,
        feedback: feedbackText.isNotEmpty ? feedbackText : null,
      );

      if (mounted) {
        setState(() {
          _ratings[productId] = pendingRating;
          _pendingRatings.remove(productId);
          _submitting[productId] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting[productId] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting rating: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final features = ref.watch(adminFeaturesProvider);
    if (!features.starRatingsEnabled) {
      return SafeScaffold(
        appBar: AppBar(title: const Text('Rate Products')),
        body: const Center(
          child: Text('Star ratings feature is currently disabled'),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final padding = Responsive.getCardPadding(width);
    final spacing = Responsive.getSectionSpacing(width);

    return SafeScaffold(
      appBar: AppBar(
        title: const Text('Rate Products'),
        leading: IconButton(
          icon: const Icon(Ionicons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Ionicons.star_outline,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No delivered orders found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can only rate products from delivered orders',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(padding),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final orderNumber = order['order_number'] as String? ?? 'N/A';
                    final products = order['products'] as List<dynamic>? ?? [];
                    
                    // Get full order number for display
                    String getDisplayOrderNumber(String orderNum) {
                      return orderNum;
                    }
                    final displayOrderNumber = getDisplayOrderNumber(orderNumber);

                    return Card(
                      margin: EdgeInsets.only(bottom: spacing),
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Ionicons.receipt_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    displayOrderNumber,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...products.map((product) {
                              final productData =
                                  product as Map<String, dynamic>;
                              final productId =
                                  productData['product_id'] as String;
                              final productName =
                                  productData['product_name'] as String? ??
                                      'Unknown Product';
                              final productImage =
                                  productData['product_image'] as String? ?? '';
                              final existingRating =
                                  productData['existing_rating'] as int?;
                              
                              // Ensure maps are initialized before accessing (critical for hot reload)
                              _ratings ??= {};
                              _feedbackControllers ??= {};
                              _feedbacks ??= {};
                              _pendingRatings ??= {};
                              _submitting ??= {};
                              
                              final currentRating = _ratings[productId] ??
                                  existingRating ??
                                  0;
                              
                              // Initialize feedback controller if not exists
                              if (!_feedbackControllers.containsKey(productId)) {
                                final existingRatingObj = _existingRatings[productId];
                                _feedbackControllers[productId] = TextEditingController(
                                  text: existingRatingObj?.feedback ?? '',
                                );
                                if (existingRatingObj?.feedback != null) {
                                  _feedbacks[productId] = existingRatingObj!.feedback!;
                                }
                                // Initialize pending rating with existing or 0
                                if (!_pendingRatings.containsKey(productId)) {
                                  _pendingRatings[productId] = currentRating;
                                }
                              }

                              // Safely get pending rating, ensuring maps are initialized
                              _pendingRatings ??= {};
                              _ratings ??= {};
                              _feedbacks ??= {};
                              _submitting ??= {};
                              final pendingRating = _pendingRatings[productId] ?? currentRating;
                              final isSubmitting = _submitting[productId] ?? false;
                              final hasPendingChanges = pendingRating != currentRating || 
                                  (_feedbacks[productId]?.isNotEmpty ?? false) && 
                                  _feedbacks[productId] != (_existingRatings[productId]?.feedback ?? '');

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 1,
                                child: Padding(
                                  padding: EdgeInsets.all(padding * 0.75),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: double.infinity,
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                      // Product header with image and name
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (productImage.isNotEmpty)
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                productImage,
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    Container(
                                                      width: 60,
                                                      height: 60,
                                                      color: Colors.grey.shade200,
                                                      child: const Icon(Ionicons.image_outline),
                                                    ),
                                              ),
                                            ),
                                          if (productImage.isNotEmpty) const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    context.push('/product/$productId');
                                                  },
                                                  child: Text(
                                                    productName,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall
                                                        ?.copyWith(
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    StarRatingInput(
                                                      initialRating: pendingRating,
                                                      onRatingChanged: (rating) {
                                                        if (mounted) {
                                                          setState(() {
                                                            // Ensure map is initialized
                                                            _pendingRatings ??= {};
                                                            _pendingRatings[productId] = rating;
                                                          });
                                                        }
                                                      },
                                                      starSize: 24,
                                                    ),
                                                    if (pendingRating > 0) ...[
                                                      const SizedBox(width: 8),
                                                      Flexible(
                                                        child: Text(
                                                          '$pendingRating star${pendingRating > 1 ? 's' : ''}',
                                                          style: Theme.of(context)
                                                              .textTheme
                                                              .bodySmall,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Feedback field
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _feedbackControllers[productId],
                                        decoration: InputDecoration(
                                          hintText: 'Add your feedback (optional)',
                                          labelText: 'Feedback',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          prefixIcon: const Icon(Ionicons.chatbubble_outline, size: 20),
                                          counterText: '',
                                        ),
                                        maxLines: 3,
                                        maxLength: 500,
                                      onChanged: (value) {
                                        if (mounted) {
                                          setState(() {
                                            // Ensure map is initialized
                                            _feedbacks ??= {};
                                            _feedbacks[productId] = value;
                                          });
                                        }
                                      },
                                      ),
                                      // Show existing feedback if available
                                      if (_existingRatings[productId]?.feedback != null &&
                                          _existingRatings[productId]!.feedback!.isNotEmpty &&
                                          (_feedbackControllers[productId]?.text.isEmpty ?? true)) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Ionicons.information_circle_outline,
                                                size: 16,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Previous feedback: ${_existingRatings[productId]!.feedback}',
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      // Submit button
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton.icon(
                                          onPressed: (isSubmitting || pendingRating == 0) 
                                              ? null 
                                              : () => _submitRating(productId),
                                          icon: isSubmitting
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : const Icon(Ionicons.checkmark_outline),
                                          label: Text(
                                            isSubmitting
                                                ? 'Submitting...'
                                                : currentRating > 0
                                                    ? 'Update Rating'
                                                    : 'Submit Rating',
                                          ),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.amber,
                                            foregroundColor: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

