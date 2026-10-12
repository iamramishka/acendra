// Hard release gate until a reviewed email provider and trusted scheduler are
// configured. Importable worker implements delivery through trusted injection.
Deno.serve(() => Response.json({ error: { code: 'NOTIFICATIONS_UNAVAILABLE' } },
 { status: 503, headers: { 'Cache-Control': 'no-store' } }));
