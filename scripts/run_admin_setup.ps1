# PowerShell script to run admin setup SQL using Supabase CLI
# Make sure you're logged in: supabase login
# Make sure the project is linked: supabase link --project-ref bgqcuykvsiejgqeiefpi

Write-Host "🚀 Setting up admin user and storage bucket..." -ForegroundColor Green

# Check if Supabase CLI is installed
if (!(Get-Command supabase -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Supabase CLI is not installed. Please install it first." -ForegroundColor Red
    Write-Host "   Install via: scoop install supabase" -ForegroundColor Yellow
    exit 1
}

# Check if logged in
Write-Host "📋 Checking Supabase login status..." -ForegroundColor Cyan
$loginCheck = supabase projects list 2>&1
if ($LASTEXITCODE -ne 0 -and $loginCheck -match "not authenticated") {
    Write-Host "❌ Not logged in. Please run: supabase login" -ForegroundColor Red
    exit 1
}

# Ensure migrations directory exists
if (!(Test-Path "supabase/migrations")) {
    New-Item -ItemType Directory -Path "supabase/migrations" -Force | Out-Null
    Write-Host "✅ Created supabase/migrations directory" -ForegroundColor Green
}

# Copy migration file if it doesn't exist
$migrationFile = "supabase/migrations/20250112000000_setup_admin_user.sql"
if (!(Test-Path $migrationFile)) {
    if (Test-Path "supabase_migrations/006_setup_admin_user_id.sql") {
        Copy-Item "supabase_migrations/006_setup_admin_user_id.sql" $migrationFile
        Write-Host "✅ Copied migration file" -ForegroundColor Green
    } else {
        Write-Host "❌ Migration file not found: supabase_migrations/006_setup_admin_user_id.sql" -ForegroundColor Red
        exit 1
    }
}

# Link project if not linked
Write-Host "🔗 Linking to Supabase project..." -ForegroundColor Cyan
$linkCheck = supabase link --project-ref bgqcuykvsiejgqeiefpi 2>&1
if ($LASTEXITCODE -ne 0 -and $linkCheck -notmatch "already linked") {
    Write-Host "⚠️  Could not link project. Error: $linkCheck" -ForegroundColor Yellow
    Write-Host "   You may need to link manually: supabase link --project-ref bgqcuykvsiejgqeiefpi" -ForegroundColor Yellow
}

# Push migration
Write-Host "📤 Pushing migration to Supabase..." -ForegroundColor Cyan
supabase db push --linked --include-all --yes

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Admin setup completed successfully!" -ForegroundColor Green
    Write-Host "   - Admin user role updated" -ForegroundColor Green
    Write-Host "   - Storage bucket created" -ForegroundColor Green
    Write-Host "   - Storage policies created" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to push migration. Please check the error above." -ForegroundColor Red
    Write-Host "   You can also run the SQL manually in Supabase SQL Editor:" -ForegroundColor Yellow
    Write-Host "   File: supabase_migrations/006_setup_admin_user_id.sql" -ForegroundColor Yellow
    exit 1
}










