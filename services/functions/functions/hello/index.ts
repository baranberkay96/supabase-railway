// Example Edge Function shipped with the Railway template.
//
// Invoke through the API gateway:
//   curl "https://<your-gateway-domain>/functions/v1/hello?name=Railway" \
//     -H "Authorization: Bearer <anon key>"
//
// Add more functions as folders next to this one (functions/<name>/index.ts) and push to git;
// Railway rebuilds the Edge Functions service. Set VERIFY_JWT=true on that service to
// require a valid Supabase JWT (anon, service_role or a signed-in user) for every function.

Deno.serve((req: Request) => {
  const name = new URL(req.url).searchParams.get('name') ?? 'world'
  return Response.json({
    message: `Hello ${name} from Supabase Edge Functions on Railway`,
    function: Deno.env.get('SUPABASE_FUNCTION_SLUG') ?? 'hello',
  })
})
