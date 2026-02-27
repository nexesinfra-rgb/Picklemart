# Keystore Setup Instructions

## Overview
To sign your Android app for release on Google Play Console, you need to create a keystore file. This file is used to sign your app and must be kept secure.

## Step 1: Generate the Keystore

Open a terminal/command prompt and navigate to the `android` directory, then run:

### Windows (PowerShell):
```powershell
cd android
keytool -genkey -v -keystore app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### macOS/Linux:
```bash
cd android
keytool -genkey -v -keystore app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

## Step 2: Fill in the Information

When prompted, enter:
- **Keystore password**: Choose a strong password (you'll need this later)
- **Key password**: Use the same password or a different one
- **First and last name**: Your name or company name
- **Organizational unit**: Your department (optional)
- **Organization**: Your company name
- **City**: Your city
- **State**: Your state/province
- **Country code**: Two-letter country code (e.g., US, IN, GB)

## Step 3: Create key.properties

1. Copy `key.properties.example` to `key.properties`:
   ```bash
   cp key.properties.example key.properties
   ```

2. Open `key.properties` and replace the placeholder values:
   ```
   storePassword=your_actual_keystore_password
   keyPassword=your_actual_key_password
   keyAlias=upload
   storeFile=app/upload-keystore.jks
   ```

## Step 4: Verify Setup

After creating the keystore and key.properties file, try building a release:

```bash
flutter build appbundle --release
```

If everything is configured correctly, the build will use your release keystore for signing.

## Important Security Notes

- **NEVER commit** `key.properties` or `upload-keystore.jks` to version control
- **Backup your keystore** - if you lose it, you cannot update your app on Google Play
- Store the keystore password securely (password manager)
- The keystore file is already added to `.gitignore`

## Troubleshooting

### "Keystore file does not exist"
- Make sure the `storeFile` path in `key.properties` is correct
- The path should be relative to the `android` directory

### "Password was incorrect"
- Double-check the passwords in `key.properties` match what you used when creating the keystore

### Build still uses debug signing
- Make sure `key.properties` exists in the `android` directory (not `android/app`)
- Verify the file paths in `key.properties` are correct

