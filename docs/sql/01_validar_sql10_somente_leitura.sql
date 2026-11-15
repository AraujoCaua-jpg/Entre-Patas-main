-- SOMENTE LEITURA: catálogo e contagens agregadas, sem dados pessoais.
-- Complementa e inclui todas as consultas do SQL 00 original.
-- Executar com o CLI db query --read-only no projeto explicitamente escolhido.
-- Não chama RPCs de negócio, nextval, setval ou funções de escrita.
-- Não substitui revisão privada dos corpos das funções/backup/instalação aprovada.

select jsonb_build_object(
  'captured_at', current_timestamp,
  'transaction_read_only', current_setting('transaction_read_only'),
  'inspection_role', current_user,
  'tables', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select n.nspname as esquema, c.relname as tabela,
       pg_get_userbyid(c.relowner) as proprietario,
       c.relrowsecurity as rls_habilitada, c.relforcerowsecurity as force_rls
from pg_catalog.pg_class c
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relname in ('adocao', 'animal', 'cliente')
order by c.relname
  ) q),
  'columns', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select table_name, ordinal_position, column_name, data_type,
       udt_schema, udt_name, is_nullable, column_default,
       is_identity, identity_generation
from information_schema.columns
where table_schema = 'public' and table_name in ('adocao', 'animal', 'cliente')
order by table_name, ordinal_position
  ) q),
  'constraints', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select con.conrelid::regclass as tabela, con.conname, con.contype,
       pg_catalog.pg_get_constraintdef(con.oid, true) as definicao
from pg_catalog.pg_constraint con
where con.conrelid in (
  to_regclass('public.adocao'), to_regclass('public.animal'), to_regclass('public.cliente')
)
order by con.conrelid::regclass::text, con.conname
  ) q),
  'indexes', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select tablename, indexname, indexdef
from pg_catalog.pg_indexes
where schemaname = 'public' and tablename in ('adocao', 'animal', 'cliente')
order by tablename, indexname
  ) q),
  'enums', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select c.relname as tabela, a.attname as coluna, t.typname as tipo,
       e.enumlabel, e.enumsortorder
from pg_catalog.pg_attribute a
join pg_catalog.pg_class c on c.oid = a.attrelid
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
join pg_catalog.pg_type t on t.oid = a.atttypid
join pg_catalog.pg_enum e on e.enumtypid = t.oid
where n.nspname = 'public' and c.relname in ('adocao', 'animal') and a.attname = 'status'
order by c.relname, e.enumsortorder
  ) q),
  'policies', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_catalog.pg_policies
where schemaname = 'public' and tablename in ('adocao', 'animal', 'cliente')
order by tablename, policyname
  ) q),
  'table_grants', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select table_name, grantee, privilege_type, is_grantable
from information_schema.table_privileges
where table_schema = 'public' and table_name in ('adocao', 'animal', 'cliente')
order by table_name, grantee, privilege_type
  ) q),
  'column_grants', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select table_name, column_name, grantee, privilege_type, is_grantable
from information_schema.column_privileges
where table_schema = 'public' and table_name in ('adocao', 'animal', 'cliente')
order by table_name, grantee, column_name, privilege_type
  ) q),
  'roles', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select rolname, rolsuper, rolbypassrls, rolinherit
from pg_catalog.pg_roles
where rolname in ('anon', 'authenticated', 'authenticator', 'service_role', current_user)
  ) q),
  'memberships', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select membro.rolname as membro, grupo.rolname as papel_herdado
from pg_catalog.pg_auth_members m
join pg_catalog.pg_roles membro on membro.oid = m.member
join pg_catalog.pg_roles grupo on grupo.oid = m.roleid
where membro.rolname in ('anon', 'authenticated', 'authenticator')
  ) q),
  'triggers', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select c.relname as tabela, t.tgname,
       pg_catalog.pg_get_triggerdef(t.oid, true) as definicao
from pg_catalog.pg_trigger t
join pg_catalog.pg_class c on c.oid = t.tgrelid
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relname in ('adocao', 'animal', 'cliente')
  and not t.tgisinternal
order by c.relname, t.tgname
  ) q),
  'functions', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select p.oid::regprocedure as funcao, pg_get_userbyid(p.proowner) as proprietario,
       p.prosecdef as security_definer, p.proconfig as configuracao, p.proacl as acl
from pg_catalog.pg_proc p
join pg_catalog.pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and (
  p.proname ilike '%adocao%' or p.proname ilike '%animal%' or p.prosecdef
)
order by p.oid::regprocedure::text
  ) q),
  'adoption_status_counts', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select status::text as status, count(*) as total from public.adocao group by status::text order by status::text
  ) q),
  'animal_status_counts', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select status::text as status, count(*) as total from public.animal group by status::text order by status::text
  ) q),
  'data_checks', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select
  (select count(*) from public.adocao) as adoption_count,
  (select count(*) from public.adocao where status is null or status::text not in ('Aguardando','Aceito','Recusado','Cancelado') or data is null or id_animal is null or id_cliente is null or id_dono is null or id_cliente=id_dono) as incompatible_adoptions,
  (select count(*) from (select 1 from public.adocao where status::text in ('Aguardando','Aceito') group by id_animal,id_cliente having count(*)>1) d) as duplicate_active_groups,
  (select count(*) from (select 1 from public.adocao where status::text='Aceito' group by id_animal having count(*)>1) d) as duplicate_accepted_animals,
  (select count(*) from (select 1 from public.cliente where auth_user_id is not null group by auth_user_id having count(*)>1) d) as duplicate_auth_profiles,
  (select count(*) from public.adocao d left join public.animal a on a.id=d.id_animal left join public.cliente c on c.id=d.id_cliente left join public.cliente dono on dono.id=d.id_dono where a.id is null or c.id is null or dono.id is null) as orphan_adoptions,
  (select count(*) from public.adocao d join public.animal a on a.id=d.id_animal where d.status::text='Aceito' and a.status::text is distinct from 'Adotado') as accepted_animal_mismatch,
  (select count(*) from public.adocao a join public.adocao p on p.id_animal=a.id_animal where a.status::text='Aceito' and p.status::text='Aguardando') as pending_after_acceptance,
  (select count(*) from public.adocao d join public.animal a on a.id=d.id_animal where d.id_dono is distinct from a.id_cliente) as historical_owner_mismatch,
  (select count(*) from public.adocao d join public.cliente c on c.id=d.id_cliente join public.cliente dono on dono.id=d.id_dono where c.auth_user_id is null or dono.auth_user_id is null) as legacy_adoptions_without_auth,
  (select count(*) from public.cliente c left join auth.users u on u.id=c.auth_user_id where c.auth_user_id is not null and u.id is null) as orphan_auth_links,
  (select count(*) from public.cliente where ativo is true and auth_user_id is not null) as active_linked_profiles
  ) q),
  'status_lengths', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select table_name,column_name,data_type,character_maximum_length from information_schema.columns where table_schema='public' and table_name in ('adocao','animal') and column_name='status' order by table_name
  ) q),
  'rpc_and_helper_privileges', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select e.signature, p.oid is not null as present, p.prosecdef as security_definer,
  pg_get_userbyid(p.proowner) as owner, coalesce(r.rolsuper or r.rolbypassrls,false) as privileged_owner,
  case when p.oid is not null then has_function_privilege('anon',p.oid,'EXECUTE') end as anon_execute,
  case when p.oid is not null then has_function_privilege('authenticated',p.oid,'EXECUTE') end as authenticated_execute,
  case when p.oid is not null then md5(pg_get_functiondef(p.oid)) end as definition_md5
from (values
  ('public.listar_minhas_adocoes()'),('public.buscar_minha_adocao(bigint)'),
  ('public.solicitar_adocao(bigint)'),('public.responder_adocao(bigint,text)'),
  ('public._ep_adocao_cliente_atual()'),('public._ep_adocoes_json(bigint,bigint)'),
  ('public._ep_proteger_status_adocao_animal()'),
  ('public.ep_sincronizar_email_auth()'),('public.ep_anonimizar_conta_auth()'),
  ('public.ep_conta_exclusao_pronta()'),('public.buscar_clientes_publicos(text)'),
  ('public.buscar_perfil_publico(bigint)'),('public.buscar_resumo_responsavel(bigint)'),
  ('public.ep_animais_perto_de_mim()')
) e(signature) left join pg_catalog.pg_proc p on p.oid=to_regprocedure(e.signature)
left join pg_catalog.pg_roles r on r.oid=p.proowner order by e.signature
  ) q),
  'adoption_sequence', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select pg_get_serial_sequence('public.adocao','id') as sequence_name,
  s.last_value,s.increment_by,s.cache_size,(select max(id) from public.adocao) as max_existing_id
from (values(1)) v(n) left join pg_catalog.pg_sequences s
 on format('%I.%I',s.schemaname,s.sequencename)=pg_get_serial_sequence('public.adocao','id')
  ) q),
  'auth_profile_triggers', (select coalesce(jsonb_agg(to_jsonb(q)), '[]'::jsonb) from (
select t.tgname,pg_get_triggerdef(t.oid,true) as definition,p.oid::regprocedure::text as function,
  pg_get_userbyid(p.proowner) as owner,p.prosecdef as security_definer,md5(pg_get_functiondef(p.oid)) as function_md5
from pg_catalog.pg_trigger t join pg_catalog.pg_proc p on p.oid=t.tgfoid
where t.tgrelid=to_regclass('auth.users') and not t.tgisinternal order by t.tgname
  ) q),
  -- information_schema pode omitir grants para o papel de leitura da API.
  -- Estes testes usam os privilégios efetivos dos papéis do aplicativo.
  'effective_table_privileges', (select jsonb_agg(to_jsonb(q)) from (
    select r.role, t.table_name,
      has_table_privilege(r.role,format('public.%I',t.table_name),'SELECT') as can_select,
      has_table_privilege(r.role,format('public.%I',t.table_name),'INSERT') as can_insert,
      has_table_privilege(r.role,format('public.%I',t.table_name),'UPDATE') as can_update,
      has_table_privilege(r.role,format('public.%I',t.table_name),'DELETE') as can_delete,
      has_any_column_privilege(r.role,format('public.%I',t.table_name),'UPDATE') as column_update
    from (values('anon'),('authenticated')) r(role)
    cross join (values('adocao'),('animal'),('cliente'),('questionario')) t(table_name)
  ) q),
  'column_update_privileges', (select jsonb_agg(to_jsonb(q)) from (
    select t.relname as table_name, a.attname as column_name, r.role,
      has_column_privilege(r.role,t.oid,a.attnum,'UPDATE') as update_allowed
    from pg_catalog.pg_class t
    join pg_catalog.pg_namespace n on n.oid=t.relnamespace
    join pg_catalog.pg_attribute a on a.attrelid=t.oid and a.attnum>0 and not a.attisdropped
    cross join (values('anon'),('authenticated')) r(role)
    where n.nspname='public' and t.relname in ('animal','cliente','adocao')
  ) q),
  'application_function_signatures', (select jsonb_agg(to_jsonb(q)) from (
    select n.nspname as schema, p.oid::regprocedure::text as signature,
      p.proargnames, pg_get_function_result(p.oid) as result,
      p.prosecdef as security_definer, pg_get_userbyid(p.proowner) as owner,
      p.proconfig, has_function_privilege('anon',p.oid,'EXECUTE') as anon_execute,
      has_function_privilege('authenticated',p.oid,'EXECUTE') as authenticated_execute,
      md5(pg_get_functiondef(p.oid)) as definition_md5
    from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
    where n.nspname in ('public','private') and p.prokind='f'
    order by n.nspname,p.proname
  ) q),
  'validated_foreign_keys', (select jsonb_agg(to_jsonb(q)) from (
    select con.conrelid::regclass::text as table_name, con.conname,
      con.convalidated, con.confdeltype, con.confupdtype
    from pg_catalog.pg_constraint con
    where con.contype='f' and con.conrelid in
      ('public.adocao'::regclass,'public.animal'::regclass,'public.cliente'::regclass)
  ) q),
  'available_animal_ownership', (select to_jsonb(q) from (
    select count(*) as available_count,
      count(*) filter (where c.auth_user_id is null) as owner_without_auth,
      count(*) filter (where c.ativo is not true) as inactive_owner
    from public.animal a left join public.cliente c on c.id=a.id_cliente
    where a.ativo is true and a.status::text='Disponível'
  ) q),
  'private_schema_usage', jsonb_build_object(
    'anon', has_schema_privilege('anon','private','USAGE'),
    'authenticated', has_schema_privilege('authenticated','private','USAGE')
  ),
  'questionnaire_metadata', (select jsonb_agg(to_jsonb(q)) from (
    select con.conname, con.contype, pg_get_constraintdef(con.oid,true) as definition
    from pg_catalog.pg_constraint con where con.conrelid=to_regclass('public.questionario')
  ) q),
  'questionnaire_indexes', (select jsonb_agg(to_jsonb(q)) from (
    select indexname,indexdef from pg_catalog.pg_indexes
    where schemaname='public' and tablename='questionario'
  ) q),
  'questionnaire_policies', (select jsonb_agg(to_jsonb(q)) from (
    select policyname,roles,cmd,qual,with_check from pg_catalog.pg_policies
    where schemaname='public' and tablename='questionario'
  ) q),
  -- Nome confirmado pela inspeção do identity no projeto de destino.
  -- SELECT não avança nem realinha a sequência.
  'adoption_sequence_state', (select to_jsonb(q) from (
    select last_value,is_called from public.adocao_id_seq
  ) q)
) as sql10_audit;
