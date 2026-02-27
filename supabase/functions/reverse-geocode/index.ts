import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// CORS headers for Edge Function
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
};

interface NominatimResponse {
  display_name?: string;
  address?: {
    house_number?: string;
    road?: string;
    suburb?: string;
    neighbourhood?: string;
    city?: string;
    town?: string;
    village?: string;
    state?: string;
    region?: string;
    postcode?: string;
    country?: string;
  };
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Parse query parameters
    const url = new URL(req.url);
    const lat = url.searchParams.get("lat");
    const lon = url.searchParams.get("lon");

    // Validate required parameters
    if (!lat || !lon) {
      return new Response(
        JSON.stringify({ error: "Missing required parameters: lat and lon" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate latitude and longitude are valid numbers
    const latitude = parseFloat(lat);
    const longitude = parseFloat(lon);

    if (isNaN(latitude) || isNaN(longitude)) {
      return new Response(
        JSON.stringify({ error: "Invalid latitude or longitude values" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate latitude range (-90 to 90)
    if (latitude < -90 || latitude > 90) {
      return new Response(
        JSON.stringify({ error: "Latitude must be between -90 and 90" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate longitude range (-180 to 180)
    if (longitude < -180 || longitude > 180) {
      return new Response(
        JSON.stringify({ error: "Longitude must be between -180 and 180" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Build Nominatim API URL
    const nominatimUrl = new URL("https://nominatim.openstreetmap.org/reverse");
    nominatimUrl.searchParams.set("format", "json");
    nominatimUrl.searchParams.set("lat", lat);
    nominatimUrl.searchParams.set("lon", lon);
    nominatimUrl.searchParams.set("addressdetails", "1");

    // Make request to Nominatim API
    const response = await fetch(nominatimUrl.toString(), {
      method: "GET",
      headers: {
        "User-Agent": "FlutterApp/1.0", // Required by Nominatim
        "Accept": "application/json",
      },
    });

    if (!response.ok) {
      return new Response(
        JSON.stringify({
          error: `Nominatim API returned status ${response.status}`,
        }),
        {
          status: response.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse and return the response
    const data: NominatimResponse = await response.json();

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Error in reverse-geocode function:", error);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        message: error instanceof Error ? error.message : String(error),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

