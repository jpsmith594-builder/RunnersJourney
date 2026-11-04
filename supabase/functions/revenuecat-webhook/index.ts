// Supabase Edge Function: receives RevenueCat webhooks and keeps the
// `subscriptions` table in step with the store.
//
// Setup:
//   supabase secrets set REVENUECAT_WEBHOOK_SECRET=<a long random string>
//   supabase functions deploy revenuecat-webhook --no-verify-jwt
// In RevenueCat: Project settings > Integrations > Webhooks, set the URL to
//   https://<project-ref>.supabase.co/functions/v1/revenuecat-webhook
// and the Authorization header to the same secret.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ACTIVATE = new Set([
  "INITIAL_PURCHASE",
  "RENEWAL",
  "PRODUCT_CHANGE",
  "UNCANCELLATION",
  "NON_RENEWING_PURCHASE",
  "TEMPORARY_ENTITLEMENT_GRANT",
]);

Deno.serve(async (req) => {
  const secret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
  if (!secret || req.headers.get("Authorization") !== secret) {
    return new Response("unauthorized", { status: 401 });
  }
  const body = await req.json();
  const e = body.event;
  const userId: string | undefined = e?.app_user_id;
  // Anonymous RevenueCat ids are not our users.
  if (!userId || userId.startsWith("$RCAnonymousID")) {
    return new Response("ignored", { status: 200 });
  }

  const db = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const expires = e.expiration_at_ms
    ? new Date(e.expiration_at_ms).toISOString()
    : null;

  let active: boolean | null = null;
  if (ACTIVATE.has(e.type)) active = true;
  // A cancelled subscription stays active until it expires.
  if (e.type === "EXPIRATION") active = false;
  if (e.type === "CANCELLATION") active = null; // keep as is, just record expiry
  if (active === null && e.type !== "CANCELLATION") {
    return new Response("ignored", { status: 200 });
  }

  const row: Record<string, unknown> = {
    user_id: userId,
    plan: e.product_id ?? null,
    expires_at: expires,
    updated_at: new Date().toISOString(),
  };
  if (active !== null) row.active = active;

  const { error } = await db.from("subscriptions").upsert(row, {
    onConflict: "user_id",
  });
  if (error) return new Response(error.message, { status: 500 });
  return new Response("ok", { status: 200 });
});
