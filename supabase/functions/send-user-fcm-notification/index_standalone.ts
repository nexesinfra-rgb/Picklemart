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
  type: "order_status_changed" | "chat_message" | "delivery_update" | "order_confirmed";
  title: string;
  message: string;
  order_id?: string;
  conversation_id?: string;
  order_number?: string;
  user_id?: string;
}

interface ServiceAccount {
  project_id: string;
  private_key: string;
  client_email: string;
}

interface TokenCache {
  token: string;
  expiresAt: number;
}

let tokenCache: TokenCache | null = null;

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

function base64UrlEncode(data: Uint8Array): string {
  const base64 = btoa(String.fromCharCode(...data));
  return base64
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
}

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

function createJwtPayload(serviceAccount: ServiceAccount): string {
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };
  const encoded = base64UrlEncode(
    new TextEncoder().encode(JSON.stringify(payload))
  );
  return encoded;
}

async function signJwt(
  header: string,
  payload: string,
  privateKeyPem: string
): Promise<string> {
  const privateKeyCleaned = privateKeyPem
    .replace(/-----BEGIN PRIVATE KEY-----/g, "")
    .replace(/-----END PRIVATE KEY-----/g, "")
    .replace(/\s/g, "");

  const keyData = Uint8Array.from(atob(privateKeyCleaned), (c) =>
    c.charCodeAt(0)
  );

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

  const data = `${header}.${payload}`;
  const dataBytes = new TextEncoder().encode(data);

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    dataBytes
  );

  const signatureB64 = base64UrlEncode(new Uint8Array(signature));

  return `${data}.${signatureB64}`;
}

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

async function getAccessToken(): Promise<string> {
  if (tokenCache && tokenCache.expiresAt > Date.now() + 60000) {
    return tokenCache.token;
  }

  try {
    const serviceAccount = getServiceAccount();

    const header = createJwtHeader();
    const payload = createJwtPayload(serviceAccount);
    const signedJwt = await signJwt(
      header,
      payload,
      serviceAccount.private_key
    );

    const accessToken = await exchangeJwtForToken(signedJwt);

    tokenCache = {
      token: accessToken,
      expiresAt: Date.now() + 55 * 60 * 1000,
    };

    return accessToken;
  } catch (error) {
    console.error("Error getting access token:", error);
    throw error;
  }
}

function getProjectId(): string {
  const serviceAccount = getServiceAccount();
  return serviceAccount.project_id;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  console.log("[FCM] send-user-fcm-notification function called");
  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("Missing Supabase environment variables");
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const payload: NotificationPayload = await req.json();
    console.log("[FCM] Received payload:", JSON.stringify({ type: payload.type, title: payload.title, user_id: payload.user_id }));

    if (!payload.type || !payload.title || !payload.message) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: type, title, message" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    let accessToken: string;
    try {
      console.log("[FCM] Getting FCM access token...");
      accessToken = await getAccessToken();
      console.log("[FCM] ✅ FCM access token obtained successfully");
    } catch (error) {
      console.error("[FCM] ❌ Error getting FCM access token:", error);
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

    const projectId = getProjectId();
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
    console.log("[FCM] Firebase project ID:", projectId);

    console.log("[FCM] Building query for user FCM tokens...");
    let tokensQuery = supabase
      .from("user_fcm_tokens")
      .select("fcm_token, user_id")
      .eq("is_active", true);

    if (payload.user_id) {
      console.log("[FCM] Filtering tokens for user_id:", payload.user_id);
      tokensQuery = tokensQuery.eq("user_id", payload.user_id);
    }

    console.log("[FCM] Executing query to fetch active user FCM tokens...");
    const { data: tokens, error: tokensError } = await tokensQuery;

    if (tokensError) {
      console.error("[FCM] Error fetching FCM tokens:", tokensError);
      return new Response(
        JSON.stringify({ error: "Failed to fetch FCM tokens" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    console.log(`[FCM] Query result: ${tokens?.length || 0} active token(s) found`);
    if (!tokens || tokens.length === 0) {
      console.log("[FCM] No active FCM tokens found in database");
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

    console.log(`[FCM] Starting to send notifications to ${tokens.length} token(s)...`);
    for (const tokenData of tokens) {
      try {
        console.log(`[FCM] Sending notification to token: ${tokenData.fcm_token.substring(0, 20)}...`);
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
            },
            android: {
              priority: "high",
              notification: {
                channel_id: "user_notifications",
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
          successCount++;
          console.log(`[FCM] ✅ Notification sent successfully! Message ID: ${responseData.name}`);
        } else {
          console.error(`[FCM] ❌ FCM send failed:`, responseData);
          failureCount++;
          const errorMsg = responseData.error?.message || responseData.error || "Unknown error";
          errors.push(
            `Token ${tokenData.fcm_token.substring(0, 20)}...: ${errorMsg}`
          );
        }
      } catch (error) {
        console.error(`[FCM] ❌ Error sending to token:`, error);
        failureCount++;
        errors.push(
          `Token ${tokenData.fcm_token.substring(0, 20)}...: ${error instanceof Error ? error.message : String(error)}`
        );
      }
    }

    console.log(`[FCM] 📊 Summary: ${successCount} sent, ${failureCount} failed, ${tokens.length} total`);
    return new Response(
      JSON.stringify({
        message: "Notifications processed",
        sent: successCount,
        failed: failureCount,
        total: tokens.length,
        ...(errors.length > 0 && { errors: errors.slice(0, 5) }),
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("[FCM] ❌ Error in send-user-fcm-notification:", error);
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

