/**
 * Firebase Cloud Messaging HTTP v1 API Authentication Utility
 * 
 * This module handles OAuth 2.0 token generation for FCM v1 API using service account credentials.
 */

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
export async function getAccessToken(): Promise<string> {
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
export function getProjectId(): string {
  const serviceAccount = getServiceAccount();
  return serviceAccount.project_id;
}
