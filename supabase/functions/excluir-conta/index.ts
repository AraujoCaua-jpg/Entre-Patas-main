import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, x-client-info, content-type, x-account-cleanup-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: Record<string, unknown>, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function decodeClaims(token: string): Record<string, unknown> | null {
  try {
    const payload = token.split(".")[1];
    if (!payload) return null;
    const base64 = payload.replace(/-/g, "+").replace(/_/g, "/");
    const padded = base64.padEnd(Math.ceil(base64.length / 4) * 4, "=");
    return JSON.parse(atob(padded)) as Record<string, unknown>;
  } catch {
    return null;
  }
}

function secretMatches(provided: string | null, expected: string): boolean {
  if (!provided || provided.length !== expected.length) return false;
  let difference = 0;
  for (let index = 0; index < expected.length; index++) {
    difference |= provided.charCodeAt(index) ^ expected.charCodeAt(index);
  }
  return difference === 0;
}

async function retryStorageCleanup(
  admin: ReturnType<typeof createClient>,
): Promise<{ pending: boolean }> {
  let pending = false;

  for (let batch = 0; batch < 10; batch++) {
    const { data: objects, error } = await admin
      .from("ep_account_storage_cleanup")
      .select("id,user_id,bucket_id,object_name,attempts")
      .is("completed_at", null)
      .order("id")
      .limit(500);
    if (error) {
      console.error("Could not read the account storage cleanup queue.");
      return { pending: true };
    }
    if (!objects?.length) return { pending };

    let failed = false;
    for (const object of objects) {
      const { error: removeError } = await admin.storage
        .from(object.bucket_id)
        .remove([object.object_name]);
      if (removeError) {
        failed = true;
        const { error: updateError } = await admin
          .from("ep_account_storage_cleanup")
          .update({
            attempts: Number(object.attempts) + 1,
            last_error: "storage_remove_failed",
          })
          .eq("id", object.id);
        if (updateError) {
          console.error("Could not record an account storage cleanup failure.");
        }
        continue;
      }

      const { error: updateError } = await admin
        .from("ep_account_storage_cleanup")
        .update({
          attempts: Number(object.attempts) + 1,
          last_error: null,
          completed_at: new Date().toISOString(),
        })
        .eq("id", object.id);
      if (updateError) {
        failed = true;
        console.error("Could not complete an account storage cleanup job.");
      }
    }

    if (failed || objects.length < 500) {
      const { count, error: countError } = await admin
        .from("ep_account_storage_cleanup")
        .select("id", { count: "exact", head: true })
        .is("completed_at", null);
      return { pending: countError !== null || (count ?? 0) > 0 };
    }
  }

  return { pending: true };
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    console.error("Account deletion function secrets are not configured.");
    return json({ error: "server_not_configured" }, 500);
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const rawBody = await request.text();
  let body: unknown = {};
  if (rawBody.trim().length > 0) {
    try {
      body = JSON.parse(rawBody);
    } catch {
      return json({ error: "invalid_request" }, 400);
    }
  }
  if (!isRecord(body)) {
    return json({ error: "invalid_request" }, 400);
  }
  if (
    Object.keys(body).some((key) => key !== "action") ||
    (body.action !== undefined &&
      body.action !== "delete" &&
      body.action !== "retry_storage")
  ) {
    return json({ error: "invalid_request" }, 400);
  }

  if (body.action === "retry_storage") {
    const cleanupSecret = Deno.env.get("ACCOUNT_CLEANUP_SECRET");
    if (!cleanupSecret || !secretMatches(
      request.headers.get("x-account-cleanup-secret"),
      cleanupSecret,
    )) {
      return json({ error: "not_authorized" }, 403);
    }
    const result = await retryStorageCleanup(admin);
    return json({ retried: true, storageCleanupPending: result.pending });
  }

  const authorization = request.headers.get("authorization");
  const accessToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
  if (!accessToken) return json({ error: "not_authenticated" }, 401);

  const caller = createClient(supabaseUrl, anonKey, {
    auth: { autoRefreshToken: false, persistSession: false },
    global: { headers: { Authorization: `Bearer ${accessToken}` } },
  });
  const { data: authData, error: authError } = await caller.auth.getUser(
    accessToken,
  );
  const claims = decodeClaims(accessToken);
  if (
    authError ||
    !authData.user ||
    claims?.sub !== authData.user.id ||
    claims?.role !== "authenticated"
  ) {
    return json({ error: "not_authenticated" }, 401);
  }

  const authTime = claims.auth_time;
  const now = Math.floor(Date.now() / 1000);
  if (
    typeof authTime !== "number" ||
    authTime > now + 30 ||
    now - authTime > 5 * 60
  ) {
    return json({ error: "recent_authentication_required" }, 401);
  }

  const { data: ready, error: readinessError } = await caller.rpc(
    "ep_conta_exclusao_pronta",
  );
  if (readinessError || ready !== true) {
    return json({ error: "account_deletion_not_configured" }, 503);
  }

  const { error: deleteError } = await admin.auth.admin.deleteUser(
    authData.user.id,
    false,
  );
  if (deleteError) {
    console.error("Supabase Auth account deletion failed.");
    return json({ error: "account_deletion_failed" }, 500);
  }

  const cleanup = await retryStorageCleanup(admin);
  return json({ deleted: true, storageCleanupPending: cleanup.pending });
});
