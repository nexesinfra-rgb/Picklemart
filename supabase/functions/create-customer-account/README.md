# Create Customer Account Edge Function

This Edge Function allows admins to create customer/store accounts programmatically. It uses Supabase Admin API to create users in the authentication system and their corresponding profiles.

## Deployment

Deploy this function using the Supabase CLI:

```bash
# Make sure you're logged in and linked
supabase login
supabase link --project-ref bgqcuykvsiejgqeiefpi

# Deploy the function
supabase functions deploy create-customer-account
```

Or deploy via Supabase Dashboard → Edge Functions → Deploy.

## Usage

Send a POST request to the function:

```bash
curl -X POST 'https://bgqcuykvsiejgqeiefpi.supabase.co/functions/v1/create-customer-account' \
  -H 'Authorization: Bearer YOUR_ACCESS_TOKEN' \
  -H 'Content-Type: application/json' \
  -H 'apikey: YOUR_ANON_KEY' \
  -d '{
    "name": "Customer Name",
    "mobile": "9876543210",
    "password": "securepassword123"
  }'
```

**Important:** You must include a valid JWT token in the Authorization header from an authenticated admin user.

## Payload Format

```typescript
{
  name: string;      // Customer/store name (required)
  mobile: string;    // 10-digit mobile number (required)
  password: string;  // Password, minimum 6 characters (required)
}
```

## Response Format

### Success (200)
```json
{
  "success": true,
  "user": {
    "id": "user-uuid",
    "name": "Customer Name",
    "email": "919876543210@phone.local",
    "mobile": "9876543210",
    "password": "securepassword123"
  },
  "message": "Customer account created successfully"
}
```

### Error Responses

- **400**: Invalid request (missing fields, invalid mobile format, password too short)
- **401**: Missing or invalid authentication token
- **403**: User doesn't have admin privileges
- **409**: User with this mobile number already exists
- **500**: Internal server error

## Features

- ✅ Validates admin authentication and role
- ✅ Creates user in Supabase Auth with auto-confirmation
- ✅ Creates corresponding profile in profiles table
- ✅ Converts mobile numbers to email format (`91{mobile}@phone.local`)
- ✅ Validates mobile number format (10 digits)
- ✅ Validates password length (minimum 6 characters)
- ✅ Returns credentials for manual sharing with customer
- ✅ Handles duplicate user errors gracefully
- ✅ Cleans up auth user if profile creation fails

## Security

- Only users with `admin`, `manager`, or `support` roles can create accounts
- Requires valid JWT token in Authorization header
- Uses Supabase Admin API (service role key) for user creation
- Passwords are not logged or stored in logs

## Notes

- Mobile numbers are converted to email format: `91{mobile}@phone.local`
- Users are automatically confirmed (no email verification needed)
- Created users have role `user` (regular customer, not admin)
- The password is returned in the response for the admin to share manually with the customer
- Credentials should be shared securely (email, SMS, or in-person)

