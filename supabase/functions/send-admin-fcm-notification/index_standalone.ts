import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

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

// ============================================================================
// FCM Authentication Code (Inlined from _shared/fcm_auth.ts)
// ============================================================================

interface ServiceAccount {
  project_id: string;
  private_key: string;
  client_email: string;
}

interface TokenCache {
  token: string;
  expiresAt: number;
}

// In-memory token cache (tokens are valid for 1 hour)
let tokenCache: TokenCache | null = null;

/**
 * Get Firebase service account from environment variable
 */
function getServiceAccount(): ServiceAccount {
  const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  
  if (!serviceAccountJson) {
    throw new Error(
      "FIREBASE_SERVICE_ACCOUNT environment variable is not set. " +
      "Please set it with your Firebase service account JSON."
    );
  }

  try {
    return JSON.parse(serviceAccountJson) as ServiceAccount;
  } catch (e) {
    throw new Error(`Failed to parse FIREBASE_SERVICE_ACCOUNT JSON: ${e}`);
  }
}

/**
 * Base64 URL encode (without padding)
 */
function base64UrlEncode(data: Uint8Array): string {
  const base64 = btoa(String.fromCharCode(...data));
  return base64
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
}

/**
 * Create JWT header
 */
function createJwtHeader(): string {
  const header = {
    alg: "RS256",
    typ: "JWT",
  };
  const encoded = base64UrlEncode(
    new TextEncoder().encode(JSON.stringify(header))
  );
  return encoded;
}

/**
 * Create JWT payload for OAuth token request
 */
function createJwtPayload(serviceAccount: ServiceAccount): string {
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600, // 1 hour
    iat: now,
  };
  const encoded = base64UrlEncode(
    new TextEncoder().encode(JSON.stringify(payload))
  );
  return encoded;
}

/**
 * Sign JWT using RS256 with service account private key
 * Uses Web Crypto API which is available in Deno
 */
async function signJwt(
  header: string,
  payload: string,
  privateKeyPem: string
): Promise<string> {
  // Remove PEM headers/footers and whitespace
  const privateKeyCleaned = privateKeyPem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");

  // Decode base64 to get the DER format key data
  const keyData = Uint8Array.from(atob(privateKeyCleaned), (c) =>
    c.charCodeAt(0)
  );

  // Import the private key using Web Crypto API
  const key = await crypto.subtle.importKey(
    "pkcs8",
    keyData,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );

  // Create the data to sign (header.payload)
  const data = `${header}.${payload}`;
  const dataBytes = new TextEncoder().encode(data);

  // Sign the data
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    dataBytes
  );

  // Base64 URL encode the signature
  const signatureB64 = base64UrlEncode(new Uint8Array(signature));

  // Return complete JWT: header.payload.signature
  return `${data}.${signatureB64}`;
}

/**
 * Exchange JWT for OAuth 2.0 access token
 */
async function exchangeJwtForToken(signedJwt: string): Promise<string> {
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: signedJwt,
    }),
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(
      `Failed to exchange JWT for access token: ${response.status} ${errorText}`
    );
  }

  const data = await response.json();
  if (!data.access_token) {
    throw new Error("No access token in OAuth response");
  }

  return data.access_token;
}

/**
 * Get OAuth 2.0 access token for FCM v1 API
 * Uses in-memory cache to avoid regenerating tokens unnecessarily
 */
async function getAccessToken(): Promise<string> {
  // Check cache first (with 1 minute buffer to avoid edge cases)
  if (tokenCache && tokenCache.expiresAt > Date.now() + 60000) {
    return tokenCache.token;
  }

  try {
    const serviceAccount = getServiceAccount();

    // Create JWT
    const header = createJwtHeader();
    const payload = createJwtPayload(serviceAccount);
    const signedJwt = await signJwt(
      header,
      payload,
      serviceAccount.private_key
    );

    // Exchange for access token
    const accessToken = await exchangeJwtForToken(signedJwt);

    // Cache the token (expires in 1 hour, but we'll cache for 55 minutes to be safe)
    tokenCache = {
      token: accessToken,
      expiresAt: Date.now() + 55 * 60 * 1000, // 55 minutes
    };

    return accessToken;
  } catch (error) {
    console.error("Error getting access token:", error);
    throw error;
  }
}

/**
 * Get Firebase project ID from service account
 */
function getProjectId(): string {
  const serviceAccount = getServiceAccount();
  return serviceAccount.project_id;
}

// ============================================================================
// Main Edge Function Handler
// ============================================================================

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

