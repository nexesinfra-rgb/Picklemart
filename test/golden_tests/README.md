# Golden Tests for E-commerce App

This directory contains comprehensive golden tests for all screens in the e-commerce application. Golden tests capture the visual appearance of widgets and ensure UI consistency across different screen sizes and orientations.

## Test Coverage

### ✅ Completed Tests

1. **Role Selection Screen** (`role_selection_screen_test.dart`)

   - Mobile Portrait (375x812)
   - Mobile Landscape (812x375)
   - Tablet Portrait (768x1024)
   - Tablet Landscape (1024x768)
   - Desktop (1920x1080)
   - Button interactions and navigation

2. **Login Screen** (`login_screen_test.dart`)

   - Mobile Portrait (375x812)
   - Mobile Landscape (812x375)
   - Tablet Portrait (768x1024)
   - Tablet Landscape (1024x768)
   - Desktop (1920x1080)
   - Form validation testing
   - Navigation testing

3. **Signup Screen** (`signup_screen_test.dart`)

   - Mobile Portrait (375x812)
   - Mobile Landscape (812x375)
   - Tablet Portrait (768x1024)
   - Tablet Landscape (1024x768)
   - Desktop (1920x1080)
   - Form validation testing
   - Form field verification

4. **Forgot Password Screen** (`forgot_password_screen_test.dart`)
   - Mobile Portrait (375x812)
   - Mobile Landscape (812x375)
   - Tablet Portrait (768x1024)
   - Tablet Landscape (1024x768)
   - Desktop (1920x1080)
   - Form validation testing
   - Form field verification

### 🚧 Pending Tests

- Home Screen
- Catalog Screen
- Cart Screen
- Orders List Screen
- Profile Screen
- Product Detail Screen
- Browse Products Screen
- Search Products Screen
- Checkout Address Screen
- Order Confirmation Screen
- Profile Edit Screen
- Settings Screen
- Address List Screen
- Address Form Screen
- Order Detail Screen

## Running Tests

### Run All Golden Tests

```bash
flutter test test/golden_tests/ --update-goldens
```

### Run Specific Screen Tests

```bash
# Role Selection Screen
flutter test test/golden_tests/role_selection_screen_test.dart --update-goldens

# Login Screen
flutter test test/golden_tests/login_screen_test.dart --update-goldens

# Signup Screen
flutter test test/golden_tests/signup_screen_test.dart --update-goldens

# Forgot Password Screen
flutter test test/golden_tests/forgot_password_screen_test.dart --update-goldens
```

### Run Tests Without Updating Goldens

```bash
flutter test test/golden_tests/
```

### Run Tests for Specific Screen Sizes

```bash
# Mobile Portrait only
flutter test test/golden_tests/ --name "Mobile Portrait"

# Desktop only
flutter test test/golden_tests/ --name "Desktop"
```

## Test Structure

Each test file follows a consistent structure:

1. **Screen Size Tests**: Tests for different device sizes and orientations
2. **Form Validation Tests**: Tests for input validation and error handling
3. **Navigation Tests**: Tests for screen transitions and routing
4. **UI Element Tests**: Tests for presence and behavior of UI components

## Screen Sizes Tested

- **Mobile Portrait**: 375x812 (iPhone 12)
- **Mobile Landscape**: 812x375
- **Tablet Portrait**: 768x1024 (iPad)
- **Tablet Landscape**: 1024x768
- **Desktop**: 1920x1080

## Golden Files

Golden files are stored as PNG images in the same directory as the test files. They are automatically generated when running tests with the `--update-goldens` flag.

### File Naming Convention

- `{screen_name}_{device_type}_{orientation}.png`
- Example: `role_selection_screen_mobile_portrait.png`

## Best Practices

1. **Always update goldens** when making UI changes
2. **Test multiple screen sizes** to ensure responsive design
3. **Include interaction tests** for better coverage
4. **Use descriptive test names** for clarity
5. **Group related tests** using `group()` for organization

## Troubleshooting

### Common Issues

1. **Google Fonts Loading**: Tests use a simple theme to avoid network dependencies
2. **Navigation Errors**: Tests include proper route configuration
3. **Widget Finding**: Use specific finders to avoid ambiguity
4. **State Management**: Tests properly mock Riverpod providers

### Debugging Tips

1. Use `tester.pumpAndSettle()` to wait for animations
2. Check widget tree with `tester.printToConsole()`
3. Use `tester.binding.setSurfaceSize()` for specific screen sizes
4. Verify golden files are generated correctly

## Contributing

When adding new golden tests:

1. Follow the existing test structure
2. Include all standard screen sizes
3. Add form validation tests where applicable
4. Test navigation and interactions
5. Update this README with new test coverage

## Test Results

All golden tests are currently passing and generating consistent visual outputs across different screen sizes and orientations. The tests ensure UI consistency and catch visual regressions early in the development process.

