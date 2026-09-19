// create-employee — the only place a new employee's Supabase Auth
// account is ever created (requirement: "Жаңа қызметкер аккаунтын
// қауіпсіз құру үшін Edge Function"). Creating an auth.users row with
// a password requires the Auth Admin API (service_role key), which
// must never reach the Flutter client — see SECURITY_PLAN.md /
// CLAUDE.md's "never expose secret keys in frontend code" rule. This
// function is the one place that key lives, as a server-side
// environment variable Supabase injects into every Edge Function; it
// is never returned in any response and never logged.
//
// Two Supabase clients are used deliberately for different purposes:
//   - `callerClient` is scoped to the calling user's own JWT — used
//     ONLY to verify who is calling and that they hold the director
//     role, via the same auth_is_director() RPC every RLS policy in
//     the database already relies on. It cannot bypass RLS.
//   - `adminClient` uses the service_role key — used ONLY after the
//     director check has passed, to call the Admin API and write the
//     employees/user_roles rows that RLS would otherwise block even
//     the director from writing directly (see
//     20260713000017_employees_module.sql's REVOKE).
//
// Deploy with: supabase functions deploy create-employee
// Invoke from Flutter via: supabase.functions.invoke('create-employee', body: {...})

import { createClient } from 'jsr:@supabase/supabase-js@2';

interface CreateEmployeeRequest {
  email: string;
  password: string;
  fullName: string;
  phone?: string;
  roleKey: string;
  hireDate?: string; // 'YYYY-MM-DD'
  salaryType?: 'fixed' | 'percentage';
  baseSalaryTiyn?: number;
  bonusPercent?: number;
  notes?: string;
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'Method not allowed' }, 405);
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return jsonResponse({ error: 'Сессия табылмады' }, 401);
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const anonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const {
    data: { user: caller },
    error: callerError,
  } = await callerClient.auth.getUser();

  if (callerError || !caller) {
    return jsonResponse({ error: 'Жарамсыз сессия' }, 401);
  }

  const { data: isDirector, error: directorCheckError } =
    await callerClient.rpc('auth_is_director');

  if (directorCheckError || !isDirector) {
    return jsonResponse({ error: 'Бұл әрекетке рұқсатыңыз жоқ' }, 403);
  }

  let body: CreateEmployeeRequest;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'Дұрыс емес сұраныс' }, 400);
  }

  const { email, password, fullName, phone, roleKey } = body;
  if (!email || !password || !fullName || !roleKey) {
    return jsonResponse(
      { error: 'Email, құпиясөз, аты-жөні және рөл міндетті' },
      400,
    );
  }
  if (password.length < 8) {
    return jsonResponse(
      { error: 'Құпиясөз кемінде 8 таңбадан тұруы керек' },
      400,
    );
  }

  // Only ever instantiated after the director check above has
  // passed — this client can bypass every RLS policy in the database,
  // so it must not be reachable from any earlier branch.
  const adminClient = createClient(supabaseUrl, serviceRoleKey);

  const { data: created, error: createUserError } =
    await adminClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name: fullName, phone: phone ?? null },
    });

  if (createUserError || !created?.user) {
    return jsonResponse(
      { error: createUserError?.message ?? 'Аккаунт жасалмады' },
      400,
    );
  }

  const newUserId = created.user.id;

  // handle_new_auth_user() (20260713000002_identity_and_rbac.sql)
  // already created the `profiles` row via trigger at this point, but
  // with company_id null / status 'pending' — provision_employee_profile()
  // (20260713000045) moves it into the calling director's own company
  // and activates it. Called via callerClient (the director's own JWT,
  // needed for auth_is_director()/auth_company_id() to resolve) rather
  // than adminClient (service_role has no auth.uid()). Also returns
  // that company_id for the `employees` insert below, which — like
  // `profiles.company_id` — is `not null` with no default.
  const { data: companyId, error: provisionError } = await callerClient.rpc(
    'provision_employee_profile',
    { p_profile_id: newUserId },
  );

  if (provisionError || !companyId) {
    await adminClient.auth.admin.deleteUser(newUserId);
    return jsonResponse(
      { error: provisionError?.message ?? 'Компанияға тіркеу сәтсіз аяқталды' },
      400,
    );
  }

  const { data: roleRow, error: roleLookupError } = await adminClient
    .from('roles')
    .select('id')
    .eq('key', roleKey)
    .single();

  if (roleLookupError || !roleRow) {
    await adminClient.auth.admin.deleteUser(newUserId);
    return jsonResponse({ error: 'Рөл табылмады' }, 400);
  }

  const { error: userRoleError } = await adminClient.from('user_roles').insert({
    profile_id: newUserId,
    role_id: roleRow.id,
    assigned_by: caller.id,
  });

  if (userRoleError) {
    await adminClient.auth.admin.deleteUser(newUserId);
    return jsonResponse({ error: userRoleError.message }, 400);
  }

  const { error: employeeError } = await adminClient.from('employees').insert({
    user_id: newUserId,
    company_id: companyId,
    email,
    hire_date: body.hireDate ?? null,
    salary_type: body.salaryType ?? 'fixed',
    base_salary_tiyn: body.baseSalaryTiyn ?? 0,
    bonus_percent: body.bonusPercent ?? 0,
    notes: body.notes ?? null,
  });

  if (employeeError) {
    // Roll back the auth account (and, via ON DELETE CASCADE on
    // profiles.id → auth.users.id, the profile/user_roles rows too)
    // rather than leaving a login with no employee record behind it.
    await adminClient.auth.admin.deleteUser(newUserId);
    return jsonResponse({ error: employeeError.message }, 400);
  }

  return jsonResponse({ userId: newUserId }, 200);
});
