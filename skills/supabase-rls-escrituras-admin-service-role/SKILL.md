---
name: supabase-rls-escrituras-admin-service-role
description: Regla de seguridad para TODO SaaS con Supabase + Row Level Security + panel admin. Las escrituras de endpoints admin (INSERT/UPDATE/DELETE) DEBEN usar el cliente SERVICE ROLE tras verifyAdmin, NUNCA la clave ANON. Con ANON, RLS bloquea la escritura, afecta 0 filas SIN lanzar error y el endpoint responde success:true → el admin cree que guardó y no pasó nada (bug silencioso). Activar al crear o auditar endpoints admin de escritura en cualquier app Supabase. Incluye guard anti-silencio + grep para CI.
---

# Skill: Escrituras admin en Supabase = SERVICE ROLE, nunca ANON (RLS)

> **El bug fantasma de Supabase.** Tu panel admin dice "guardado ✅" y en la base de datos no ha pasado nada. Silencioso, sin error, difícil de pillar. Le puede estar pasando a cualquier SaaS con Supabase + Row Level Security + panel de administración.

## El bug (por qué es traicionero)

Un endpoint de administración que **escribe** (INSERT/UPDATE/DELETE) usando el cliente Supabase con la **clave `anon`** (la pública, sujeta a RLS):

- Si la política RLS no permite esa escritura al rol `anon`, Supabase **no lanza error**: la operación simplemente **afecta a 0 filas**.
- El endpoint recibe `{ data: [], error: null }` → responde `success: true`.
- El admin ve "guardado correctamente" en la UI, pero **en la BD no ha pasado nada**.

Es peor que un crash: **falla en silencio**, confías en datos que no existen, y no hay traza de error que investigar.

## La regla dura

1. **Lecturas** (SELECT) de datos públicos → cliente `anon` (RLS protege, correcto).
2. **Escrituras admin** (INSERT/UPDATE/DELETE de panel admin) → cliente **`service_role`** (bypassa RLS), y **SOLO** tras `verifyAdmin()` (comprobar sesión/permiso de admin en el handler ANTES de instanciar el cliente service role).
3. **NUNCA** expongas la `service_role` al cliente/navegador: vive solo en el servidor (route handler / server action / API), leída de variable de entorno del servidor.

```ts
// ❌ MAL: escribe con anon → RLS → 0 filas, success silencioso
const supabase = createClient(URL, ANON_KEY)
await supabase.from('mi_tabla').insert(row)   // afecta 0 filas, error null

// ✅ BIEN: verifyAdmin primero, luego service role en servidor
export async function POST(req) {
  const admin = await verifyAdmin(req)            // 401/403 si no es admin
  if (!admin) return unauthorized()
  const supabase = createClient(URL, SERVICE_ROLE_KEY)  // solo servidor, de env
  const { data, error } = await supabase.from('mi_tabla').insert(row).select()
  if (error) return fail(error)
  if (!data?.length) return fail('0 filas afectadas (revisar RLS/condición)')  // red de seguridad
  return ok(data)
}
```

4. **Red de seguridad anti-silencio**: tras toda escritura admin, comprueba que `data.length > 0` (o el `count` esperado). Si afecta 0 filas → trátalo como **error**, no como éxito. Esto convierte el fallo silencioso en un error visible.

## Detección en CI (grep / lint)

Marca endpoints de escritura que usan la clave ANON (heurística — afina los paths a tu proyecto):

```bash
# Ficheros de API/route/server que mezclan .insert/.update/.delete con la clave ANON
rg -l "ANON_KEY|NEXT_PUBLIC_SUPABASE_ANON" --glob '**/{app/api,pages/api,server,actions}/**' \
  | xargs rg -l "\.(insert|update|delete|upsert)\(" \
  | sed 's/^/⚠️ posible escritura con ANON (revisar service_role): /'
```

Conviértelo en un check de CI que falle el build si una ruta de escritura admin importa la clave ANON.

## Cómo auditarlo en tu código

Revisa todos los endpoints de escritura de tu panel admin: ¿usan `service_role` tras `verifyAdmin`, o se cuela la clave `anon`? Es un anti-patrón que vive silencioso hasta que un día "no se guarda nada y nadie sabe por qué". Mejor cazarlo antes.

---

*Skill publicada por MultiAtlas para la comunidad SaaS Factory. Origen: un bug real cazado en producción de uno de nuestros SaaS (un panel admin que respondía `success:true` sin escribir). Patrón universal para cualquier stack Supabase + RLS.*
