# How to Delete Locked Build Directory

## Quick Solution

The build directory is locked by a running process (likely Cursor IDE or Android Studio).

### Option 1: Close and Reopen Cursor (Recommended)
1. **Save all your work**
2. Close Cursor IDE completely
3. Run this command in PowerShell:
   ```powershell
   cd "C:\Users\Venky\OneDrive\Desktop\optimize\pickle mart deployed version\Pickle mart19022026(deployed one)\Pickle mart(25-02-2026)\sm"
   Remove-Item -Path build -Recurse -Force
   ```
4. Reopen Cursor

### Option 2: Use Flutter Clean (After Closing Cursor)
1. Close Cursor IDE
2. Run:
   ```powershell
   flutter clean
   ```

### Option 3: Restart Computer
If the above doesn't work, restart your computer and then delete the build directory.

## Current Locking Processes Detected
- **Cursor IDE** (multiple instances running)
- **Java/Android Studio** processes
- **Windows Explorer** (if you have the build folder open)

## Alternative: Ignore the Error
If you just need to clean and rebuild, you can often ignore this error and run:
```powershell
flutter pub get
flutter build apk --release
```
Flutter will create a new build even if the old one exists.


