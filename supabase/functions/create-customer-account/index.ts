import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// CORS headers for Edge Function
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface CreateCustomerRequest {
  name: string;
  mobile: string;
  password: string;
  gstNumber?: string;
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Get Supabase client with service role key for admin operations
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing Supabase environment variables");
    }

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Validate that the request is from an authenticated admin user
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization header" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Verify the user's JWT token and check admin role
    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token);

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired authentication token" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Check if user has admin role
    const { data: profile, error: profileError } = await supabaseAdmin
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();

    if (profileError || !profile) {
      return new Response(
        JSON.stringify({ error: "User profile not found" }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const role = profile.role as string;
    if (role !== "admin" && role !== "manager" && role !== "support") {
      return new Response(
        JSON.stringify({ error: "Access denied. Admin privileges required." }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Parse request body
    const payload: CreateCustomerRequest = await req.json();

    // Validate payload
    if (!payload.name || !payload.mobile || !payload.password) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: name, mobile, password" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate mobile number format (10 digits)
    const cleanMobile = payload.mobile.replace(/\D/g, "");
    if (cleanMobile.length !== 10) {
      return new Response(
        JSON.stringify({ error: "Invalid mobile number. Must be 10 digits." }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate password length
    if (payload.password.length < 6) {
      return new Response(
        JSON.stringify({ error: "Password must be at least 6 characters" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate GST number if provided
    let cleanGstNumber: string | null = null;
    if (payload.gstNumber) {
      // Remove spaces and dashes, convert to uppercase
      cleanGstNumber = payload.gstNumber.replace(/[\s-]/g, '').toUpperCase();
      
      // GST format: 15 characters
      // Format: 22AAAAA0000A1Z5
      // First 2: State code (digits)
      // Next 10: PAN (5 letters + 4 digits + 1 letter)
      // Next 1: Entity number
      // Next 1: Z (default)
      // Last 1: Checksum
      if (cleanGstNumber.length !== 15) {
        return new Response(
          JSON.stringify({ error: "GST number must be 15 characters" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }

      // Validate format: first 2 digits, then 5 letters, 4 digits, 1 letter
      const gstPattern = /^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}/;
      if (!gstPattern.test(cleanGstNumber.substring(0, 12))) {
        return new Response(
          JSON.stringify({ error: "Invalid GST number format" }),
          {
            status: 400,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
    }

    // Convert mobile to email format (91 + mobile @phone.local)
    const email = `91${cleanMobile}@phone.local`;
    const displayMobile = cleanMobile;

    // Create user in auth.users using admin API
    // The createUser method will return an error if the user already exists
    const { data: newUser, error: createUserError } = await supabaseAdmin.auth.admin.createUser({
      email: email,
      password: payload.password,
      email_confirm: true, // Auto-confirm the user
      user_metadata: {
        name: payload.name,
        mobile: cleanMobile,
        display_mobile: displayMobile,
      },
    });

    if (createUserError) {
      console.error("Error creating user:", createUserError);
      // Check if error is due to user already existing
      if (createUserError.message?.includes("already registered") || 
          createUserError.message?.includes("already exists") ||
          createUserError.message?.toLowerCase().includes("duplicate")) {
        return new Response(
          JSON.stringify({ error: "User with this mobile number already exists" }),
          {
            status: 409,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
      return new Response(
        JSON.stringify({ 
          error: "Failed to create user account",
          details: createUserError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (!newUser.user) {
      return new Response(
        JSON.stringify({ error: "Failed to create user account: No user data returned" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Create profile in profiles table
    const profileData: any = {
      id: newUser.user.id,
      name: payload.name,
      email: email,
      mobile: cleanMobile,
      display_mobile: displayMobile,
      role: "user",
      price_visibility_enabled: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    // Add GST number if provided
    if (cleanGstNumber) {
      profileData.gst_number = cleanGstNumber;
    }

    const { error: profileCreateError } = await supabaseAdmin
      .from("profiles")
      .insert(profileData);

    if (profileCreateError) {
      console.error("Error creating profile:", profileCreateError);
      // Try to clean up the auth user if profile creation fails
      try {
        await supabaseAdmin.auth.admin.deleteUser(newUser.user.id);
      } catch (cleanupError) {
        console.error("Error cleaning up user after profile creation failure:", cleanupError);
      }

      return new Response(
        JSON.stringify({ 
          error: "Failed to create user profile",
          details: profileCreateError.message,
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Return success response with user credentials for manual sharing
    return new Response(
      JSON.stringify({
        success: true,
        user: {
          id: newUser.user.id,
          name: payload.name,
          email: email,
          mobile: displayMobile,
          password: payload.password, // Return password for admin to share manually
        },
        message: "Customer account created successfully",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(
      JSON.stringify({ 
        error: "Internal server error",
        details: error instanceof Error ? error.message : String(error),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

