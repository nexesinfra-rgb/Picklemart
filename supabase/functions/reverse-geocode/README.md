# Reverse Geocode Edge Function

This Edge Function acts as a proxy for the Nominatim OpenStreetMap API to resolve CORS issues when calling from Flutter web applications.

## Usage

The function accepts GET requests with the following query parameters:

- `lat` (required): Latitude coordinate (-90 to 90)
- `lon` (required): Longitude coordinate (-180 to 180)

## Example Request

```
GET /functions/v1/reverse-geocode?lat=17.38525262813028&lon=78.4315327186839
```

## Response

Returns the Nominatim API response in JSON format with the same structure as the original API.

## Deployment

Deploy this function using the Supabase CLI:

```bash
supabase functions deploy reverse-geocode
```

Or deploy all functions:

```bash
supabase functions deploy
```

## Error Handling

The function returns appropriate HTTP status codes:
- `400`: Invalid or missing parameters
- `500`: Internal server error
- `200`: Success with Nominatim response data

