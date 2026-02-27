import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// CORS headers for Edge Function
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  // Handle CORS preflight request
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Create a Supabase admin client with the service role key
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );

    // Get the authorization header from the request
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      throw new Error("Missing authorization header");
    }

    // Verify the user's session
    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token);

    if (userError || !user) {
      throw new Error("Invalid token or unauthorized");
    }

    // Check if the user is an admin
    const { data: profile, error: profileError } = await supabaseAdmin
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();

    if (profileError || profile?.role !== "admin") {
      throw new Error("Unauthorized: Only admins can update customer accounts");
    }

    // Parse the request body
    const { userId, password, mobile, name } = await req.json();

    if (!userId) {
      throw new Error("Missing userId in request body");
    }

    const updateData: any = {};
    if (password) updateData.password = password;
    
    if (mobile) {
      const cleanMobile = mobile.replace(/\D/g, "");
      if (cleanMobile.length !== 10) {
        throw new Error("Invalid mobile number. Must be 10 digits.");
      }
      updateData.email = `91${cleanMobile}@phone.local`;
      updateData.user_metadata = {
        ...updateData.user_metadata,
        mobile: cleanMobile,
        display_mobile: cleanMobile,
      };
    }

    if (name) {
      updateData.user_metadata = {
        ...updateData.user_metadata,
        name: name,
      };
    }

    if (Object.keys(updateData).length === 0) {
      throw new Error("No update data provided");
    }

    // Update the user using the admin API
    const { error: updateError } = await supabaseAdmin.auth.admin.updateUserById(
      userId,
      updateData
    );

    if (updateError) {
      throw updateError;
    }

    return new Response(
      JSON.stringify({ success: true, message: "Customer account updated successfully" }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200,
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400,
      }
    );
  }
});
