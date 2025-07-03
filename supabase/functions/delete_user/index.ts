// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.
// @ts-ignore

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

console.log("Hello from Functions!")

serve(async (req) => {
  // Récupère le body JSON
  let userId: string | undefined;
  try {
    const { user } = await req.json();
    userId = user?.id;
  } catch (_) {}

  if (!userId) {
    return new Response(JSON.stringify({ error: 'Missing user id' }), { status: 400 });
  }

  // Récupère les variables d'environnement
  const service_role_key = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  const project_url = Deno.env.get('SUPABASE_URL');

  if (!service_role_key || !project_url) {
    return new Response(JSON.stringify({ error: 'Missing env vars' }), { status: 500 });
  }

  // Appelle l'API admin pour supprimer l'utilisateur
  const res = await fetch(`${project_url}/auth/v1/admin/users/${userId}`, {
    method: 'DELETE',
    headers: {
      'apikey': service_role_key,
      'Authorization': `Bearer ${service_role_key}`,
    },
  });

  if (res.ok) {
    return new Response(JSON.stringify({ success: true }), { status: 200 });
  } else {
    const error = await res.text();
    return new Response(JSON.stringify({ error }), { status: 500 });
  }
});

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/delete_user' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
