import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async () => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseServiceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !supabaseServiceRole) {
    return new Response(JSON.stringify({ error: "Missing Supabase env vars" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(supabaseUrl, supabaseServiceRole);

  const now = new Date();
  const target = new Date(now.getTime() + 24 * 60 * 60 * 1000);
  const windowStart = new Date(target.getTime() - 15 * 60 * 1000).toISOString();
  const windowEnd = new Date(target.getTime() + 15 * 60 * 1000).toISOString();

  const { data, error } = await supabase
    .from("appointments")
    .select("id,scheduled_at,patient_id,staff_id")
    .gte("scheduled_at", windowStart)
    .lte("scheduled_at", windowEnd)
    .in("status", ["pending", "confirmed"]);

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(
    JSON.stringify({
      success: true,
      reminderCandidates: data?.length ?? 0,
      note: "Hook FCM send here in production setup.",
    }),
    {
      status: 200,
      headers: { "Content-Type": "application/json" },
    },
  );
});
