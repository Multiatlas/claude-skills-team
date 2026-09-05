---
name: supabase-escrituras-admin-service-role
description: Las escrituras de un endpoint admin en Supabase con RLS (INSERT/UPDATE/DELETE) DEBEN usar el cliente service_role tras verificar que quien llama es admin, NUNCA la clave anon. Con anon, RLS bloquea la escritura, afecta 0 filas SIN lanzar error y el endpoint responde success:true — el admin ve "guardado" y en la base de datos no hay nada. Invocar al crear o auditar cualquier endpoint admin de escritura en un proyecto Supabase con Row Level Security.
---

# Escrituras admin en Supabase: `service_role`, nunca `anon`

> **El bug más traicionero que te puede dejar RLS**, porque no se cae: responde que sí.
> Si tienes un panel de administración sobre Supabase con Row Level Security, esto puede estar
> pasando ahora mismo sin que nadie se haya dado cuenta.

## El bug, y por qué no lo ves

Un endpoint de administración que **escribe** (INSERT / UPDATE / DELETE) usando el cliente Supabase
con la clave **`anon`** —la pública, la que está sujeta a RLS—:

- Si la política de RLS no permite esa escritura al rol `anon`, Supabase **no lanza error**. La
  operación simplemente **afecta a 0 filas**.
- El endpoint recibe `{ data: [], error: null }`. Como no hay error, responde `success: true`.
- El administrador ve **«guardado correctamente»** en la interfaz. En la base de datos **no ha
  pasado nada**.

Es peor que un fallo que rompe: **falla en silencio**, quien lo usa confía en datos que no existen,
y no queda ni una traza de error que mirar después.

## La regla

1. **Lecturas** de datos públicos → cliente `anon`. RLS te protege, es lo correcto.
2. **Escrituras de administración** → cliente **`service_role`** (que se salta RLS), y **solo**
   después de comprobar en el propio handler que quien llama es administrador.
3. **La clave `service_role` NUNCA sale del servidor.** Ni en el navegador, ni en una variable
   pública, ni en el bundle del cliente. Vive en el entorno del servidor y punto.

```ts
// ❌ MAL: escribe con anon → RLS lo bloquea → 0 filas, y encima "éxito"
const supabase = createClient(URL, ANON_KEY)
await supabase.from('mi_tabla').insert(fila)     // 0 filas afectadas, error null

// ✅ BIEN: primero se comprueba quién llama, luego service_role, y solo en servidor
export async function POST(req) {
  const admin = await verificarAdmin(req)         // 401/403 si no lo es
  if (!admin) return noAutorizado()

  const supabase = createClient(URL, SERVICE_ROLE_KEY)   // SOLO en el servidor
  const { data, error } = await supabase.from('mi_tabla').insert(fila).select()

  if (error) return fallo(error)
  // 🔑 La red de seguridad: 0 filas es un FALLO, no un éxito
  if (!data?.length) return fallo('0 filas afectadas — revisa la política RLS o la condición')
  return ok(data)
}
```

## La red de seguridad, que es lo que de verdad lo cierra

Aunque uses `service_role`, **después de toda escritura comprueba que afectó a las filas que
esperabas**. Si `data.length === 0` (o el `count` no cuadra), trátalo como error.

Esa línea es la que convierte un fallo silencioso en un fallo ruidoso, que es justo lo que quieres.
Un `UPDATE` con un `WHERE` mal escrito también afecta a 0 filas, y ahí `service_role` no te salva.

## Cómo buscarlo en un proyecto que ya existe

Heurística para encontrar endpoints de escritura que estén usando la clave pública:

```bash
# Ficheros de API/servidor que mezclan una escritura con la clave anon
rg -l "ANON_KEY|NEXT_PUBLIC_SUPABASE_ANON" --glob '**/{app/api,pages/api,server,actions}/**' \
  | xargs rg -l "\.(insert|update|delete|upsert)\(" \
  | sed 's/^/⚠️  posible escritura con ANON (revisar service_role): /'
```

Merece la pena convertirlo en un check de integración continua que **falle la build** si una ruta de
escritura de administración importa la clave anónima. Es de las pocas reglas que se pueden
automatizar del todo.

## Checklist

- [ ] Todo endpoint admin de escritura usa `service_role`
- [ ] …y comprueba **antes** que quien llama es administrador
- [ ] La `service_role` no aparece en ninguna variable pública ni llega al navegador
- [ ] Después de cada escritura se verifica el número de filas afectadas
- [ ] 0 filas se trata como error, nunca como éxito
- [ ] Hay un check en CI que lo vigila

> Origen: un panel de administración donde una lista de bloqueo «se guardaba» y no se guardaba.
> El endpoint respondía `success: true` y la tabla estaba vacía. Tardamos en verlo justamente
> porque no fallaba nada.
