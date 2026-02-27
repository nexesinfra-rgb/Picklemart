class Environment {
  // Supabase Configuration
  static const String supabaseUrl = 'https://db.picklemart.cloud';

  // IMPORTANT: If you get "Invalid API key" errors, update this key:
  // 1. Go to Supabase Dashboard → Settings → API
  // 2. Copy the "anon/public" key (not the service_role key!)
  // 3. Replace the value below
  // 4. Restart your app
  static const String supabaseAnonKey =
      'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJzdXBhYmFzZSIsImlhdCI6MTc3MDg4MTc2MCwiZXhwIjo0OTI2NTU1MzYwLCJyb2xlIjoiYW5vbiJ9.yW0F7LtfldnjQzwnlqQRsvoc2iKFycfgmUOPT1f-Sxs';

  // Redirect URL used for password recovery flow
  static const String passwordResetRedirectUrl = 'app://password-reset';

  // Domain suffix used to convert phone numbers to deterministic emails
  static const String phoneEmailDomain = 'phone.local';

  // Default country code for phone normalization (without '+')
  static const String phoneDefaultCountryCode = '91';

  // App Base URL for sharing and deep linking
  // IMPORTANT: Update this with your actual production domain before release
  // Example: 'https://standardmarketing.com' or 'https://app.standardmarketing.com'
  // For development, can use localhost or a placeholder
  static const String appBaseUrl = 'https://picklemart.app';

  // Deep link scheme (for mobile apps)
  // IMPORTANT: Update this with your actual app scheme before release
  // Should match your app's package name or a custom scheme (e.g., 'standardmarketing' or 'sm')
  // This is used for deep linking: standardmarketing://product/123
  static const String appDeepLinkScheme = 'picklemart';

  // Privacy Policy URL
  // IMPORTANT: Update this with your actual privacy policy URL before release
  // This URL will be used in the Terms & Privacy screen
  static const String privacyPolicyUrl =
      'https://picklemart-9a4b0.web.app/privacy_policy.html'; // Hosted on Firebase

  // Admin email addresses for notifications
  // IMPORTANT: Update these with your actual admin email addresses
  static const String adminEmail =
      'admin@picklemart.app'; // TODO: Update with actual admin email
  static const String salesEmail =
      'sales@picklemart.app'; // TODO: Update with actual sales email
  static const String inventoryEmail =
      'inventory@picklemart.app'; // TODO: Update with actual inventory email
}
