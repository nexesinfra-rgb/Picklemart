import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { getAccessToken, getProjectId } from "../_shared/fcm_auth.ts";

// CORS headers for Edge Function
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

interface NotificationPayload {
  type: "order_status_changed" | "chat_message" | "new_order";
  title: string;
  message: string;
  order_id?: string;
  conversation_id?: string;
  order_number?: string;
  user_name?: string;
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight requests
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // Get Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing Supabase environment variables");
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Parse request body
    const payload: NotificationPayload = await req.json();

    // Validate payload
    if (!payload.type || !payload.title || !payload.message) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: type, title, message" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get OAuth access token for FCM v1 API
    let accessToken: string;
    try {
      accessToken = await getAccessToken();
    } catch (error) {
      console.error("Error getting FCM access token:", error);
      return new Response(
        JSON.stringify({ 
          error: "Firebase authentication failed. Please ensure FIREBASE_SERVICE_ACCOUNT secret is set correctly in Supabase." 
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Get Firebase project ID
    const projectId = getProjectId();
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;

    // Get all active admin FCM tokens
    const { data: tokens, error: tokensError } = await supabase
      .from("admin_fcm_tokens")
      .select("fcm_token, admin_id")
      .eq("is_active", true);

    if (tokensError) {
      console.error("Error fetching FCM tokens:", tokensError);
      return new Response(
        JSON.stringify({ error: "Failed to fetch FCM tokens" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (!tokens || tokens.length === 0) {
      console.log("No active FCM tokens found");
      return new Response(
        JSON.stringify({ message: "No active tokens", sent: 0 }),
        {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    let successCount = 0;
    let failureCount = 0;
    const errors: string[] = [];

    // Send notification to each token using FCM HTTP v1 API
    for (const tokenData of tokens) {
      try {
        // Build FCM v1 API message payload
        const fcmMessage = {
          message: {
            token: tokenData.fcm_token,
            notification: {
              title: payload.title,
              body: payload.message,
            },
            data: {
              type: payload.type,
              ...(payload.order_id && { order_id: payload.order_id }),
              ...(payload.conversation_id && {
                conversation_id: payload.conversation_id,
              }),
              ...(payload.order_number && { order_number: payload.order_number }),
              ...(payload.user_name && { user_name: payload.user_name }),
            },
            android: {
              priority: "high",
              notification: {
                channel_id: "admin_notifications",
                sound: "default",
              },
            },
            apns: {
              payload: {
                aps: {
                  sound: "default",
                  badge: 1,
                },
              },
            },
          },
        };

        const response = await fetch(fcmEndpoint, {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify(fcmMessage),
        });

        const responseData = await response.json();

        if (response.ok && responseData.name) {
          // v1 API returns { name: "projects/.../messages/..." } on success
          successCount++;
        } else {
          console.error(`FCM send failed:`, responseData);
          failureCount++;
          const errorMsg = responseData.error?.message || responseData.error || "Unknown error";
          errors.push(
            `Token ${tokenData.fcm_token.substring(0, 20)}...: ${errorMsg}`
          );
        }
      } catch (error) {
        console.error(`Error sending to token:`, error);
        failureCount++;
        errors.push(
          `Token ${tokenData.fcm_token.substring(0, 20)}...: ${error instanceof Error ? error.message : String(error)}`
        );
      }
    }

    return new Response(
      JSON.stringify({
        message: "Notifications processed",
        sent: successCount,
        failed: failureCount,
        total: tokens.length,
        ...(errors.length > 0 && { errors: errors.slice(0, 5) }), // Limit errors in response
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error in send-admin-fcm-notification:", error);
    return new Response(
      JSON.stringify({ 
        error: error instanceof Error ? error.message : String(error) 
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
