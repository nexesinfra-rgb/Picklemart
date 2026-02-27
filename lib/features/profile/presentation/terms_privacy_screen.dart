import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/ui/safe_scaffold.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/config/environment.dart';

class TermsPrivacyScreen extends ConsumerWidget {
  const TermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final sectionSpacing = Responsive.getSectionSpacing(width);
    final cardPadding = Responsive.getCardPadding(width);

    return SafeScaffold(
      appBar: AppBar(
        title: const Text('Terms & Privacy'),
      ),
      body: ListView(
        padding: EdgeInsets.all(cardPadding),
        children: [
          // Terms of Service Section
          _buildSectionHeader(context, 'Terms of Service', Ionicons.document_text_outline),
          SizedBox(height: cardPadding * 0.75),
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContentSection(
                    context,
                    '1. Acceptance of Terms',
                    'By accessing and using the Pickle Mart application, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '2. User Accounts and Registration',
                    'To access certain features, you must register for an account. You agree to provide accurate, current, and complete information during registration and to update such information to keep it accurate, current, and complete. You are responsible for safeguarding your password and for all activities that occur under your account.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '3. App Usage Rules',
                    'You agree not to use the app in any way that violates any applicable laws or regulations, infringes on the rights of others, or interferes with the operation of the app. Prohibited activities include but are not limited to: fraud, harassment, unauthorized access, or distribution of malicious code.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '4. Product Ordering and Payment',
                    'All product orders are subject to acceptance and availability. Prices are displayed in the applicable currency and are subject to change without notice. Payment must be made at the time of order. We accept various payment methods as displayed during checkout. By placing an order, you authorize us to charge your payment method for the total amount.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '5. Shipping and Delivery',
                    'We will make every effort to deliver products within the estimated timeframes. Delivery times are estimates and not guaranteed. Risk of loss and title for products pass to you upon delivery to the carrier. You are responsible for filing any claims with carriers for damaged or lost shipments.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '6. Returns, Refunds, and Cancellations',
                    'You may return eligible products within the specified return period as stated in our return policy. Refunds will be processed to the original payment method. Cancellation requests must be made before the order is processed. We reserve the right to refuse returns that do not meet our return policy requirements.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '7. Intellectual Property Rights',
                    'All content, features, and functionality of the app, including but not limited to text, graphics, logos, icons, images, audio clips, and software, are the exclusive property of Pickle Mart and its licensors and are protected by copyright, trademark, and other intellectual property laws.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '8. Limitation of Liability',
                    'To the maximum extent permitted by law, Pickle Mart shall not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, goodwill, or other intangible losses resulting from your use of the app.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '9. Dispute Resolution',
                    'Any disputes arising out of or relating to these terms shall be resolved through binding arbitration in accordance with applicable arbitration rules, except where prohibited by law. You waive any right to participate in a class-action lawsuit or class-wide arbitration.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '10. Contact Information',
                    'For questions about these Terms of Service, please contact us at: picklemartapp@gmail.com or through the contact information provided in the app.',
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: sectionSpacing),

          // Privacy Policy Section
          _buildSectionHeader(context, 'Privacy Policy', Ionicons.shield_checkmark_outline),
          SizedBox(height: cardPadding * 0.75),
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContentSection(
                    context,
                    '1. Information We Collect',
                    'We collect information that you provide directly to us, including: name, email address, phone number, shipping address, payment information, and account credentials. We also automatically collect information about your device, usage patterns, location data (with your permission), and interactions with the app through cookies and similar technologies.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '2. How We Use Your Information',
                    'We use the information we collect to: process and fulfill your orders, communicate with you about your orders and our services, provide customer support, improve our app and services, send you marketing communications (with your consent), prevent fraud and ensure security, comply with legal obligations, and personalize your experience.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '3. Data Sharing with Third Parties',
                    'We may share your information with: payment processors to complete transactions, shipping carriers to deliver products, service providers who assist in our operations (under strict confidentiality agreements), legal authorities when required by law, and business partners with your explicit consent. We do not sell your personal information to third parties.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '4. Data Security Measures',
                    'We implement appropriate technical and organizational security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the Internet or electronic storage is 100% secure, and we cannot guarantee absolute security.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '5. Your Rights and Choices',
                    'You have the right to: access your personal information, request correction of inaccurate data, request deletion of your data (subject to legal requirements), object to processing of your data, request data portability, withdraw consent where processing is based on consent, and opt out of marketing communications. You can exercise these rights by contacting us or through your account settings.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '6. Cookies and Tracking Technologies',
                    'We use cookies, web beacons, and similar tracking technologies to collect information about your browsing behavior, preferences, and device. You can control cookies through your device or browser settings, though disabling cookies may limit functionality of the app.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '7. Third-Party Services',
                    'Our app may contain links to third-party websites or integrate with third-party services (such as payment processors, analytics providers, and social media platforms). We are not responsible for the privacy practices of these third parties. We encourage you to review their privacy policies.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '8. International Data Transfers',
                    'Your information may be transferred to and processed in countries other than your country of residence. These countries may have data protection laws that differ from those in your country. We take appropriate safeguards to ensure your information is protected in accordance with this Privacy Policy.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '9. Children\'s Privacy',
                    'Our app is not intended for children under the age of 13 (or the applicable age in your jurisdiction). We do not knowingly collect personal information from children. If we become aware that we have collected information from a child without parental consent, we will take steps to delete such information.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '10. Data Retention',
                    'We retain your personal information for as long as necessary to fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required or permitted by law. When we no longer need your information, we will securely delete or anonymize it.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '11. Changes to This Privacy Policy',
                    'We may update this Privacy Policy from time to time to reflect changes in our practices or for legal, operational, or regulatory reasons. We will notify you of any material changes by posting the new Privacy Policy in the app and updating the "Last Updated" date. Your continued use of the app after such changes constitutes acceptance of the updated policy.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  _buildContentSection(
                    context,
                    '12. Contact Information for Privacy Inquiries',
                    'If you have questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us at: picklemartapp@gmail.com or through the contact information provided in the app. For users in the European Union, you also have the right to lodge a complaint with your local data protection authority.',
                  ),
                  SizedBox(height: cardPadding * 0.75),
                  // Privacy Policy URL Link
                  InkWell(
                    onTap: () async {
                      final url = Uri.parse(Environment.privacyPolicyUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: cardPadding * 0.5),
                      child: Row(
                        children: [
                          Icon(
                            Ionicons.link_outline,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'View Full Privacy Policy Online',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: sectionSpacing),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

