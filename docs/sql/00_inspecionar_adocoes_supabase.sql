-- SOMENTE LEITURA. Executar primeiro no SQL Editor e revisar o resultado.
-- Não cria funções/políticas, não muda grants e não altera registros.
-- O esquema real do Supabase não foi disponibilizado para esta implementação.

-- Tabelas, proprietário e RLS (inclusive FORCE RLS).
select n.nspname as esquema, c.relname as tabela,
       pg_get_userbyid(c.relowner) as proprietario,
       c.relrowsecurity as rls_habilitada, c.relforcerowsecurity as force_rls
from pg_catalog.pg_class c
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relname in ('adocao', 'animal', 'cliente')
order by c.relname;

-- Nomes exatos, tipos, nulabilidade, defaults e identidade.
select table_name, ordinal_position, column_name, data_type,
       udt_schema, udt_name, is_nullable, column_default,
       is_identity, identity_generation
from information_schema.columns
where table_schema = 'public' and table_name in ('adocao', 'animal', 'cliente')
order by table_name, ordinal_position;

-- PKs, FKs, CHECKs, UNIQUEs e ações ON DELETE/UPDATE existentes.
select con.conrelid::regclass as tabela, con.conname, con.contype,
       pg_catalog.pg_get_constraintdef(con.oid, true) as definicao
from pg_catalog.pg_constraint con
where con.conrelid in (
  to_regclass('public.adocao'), to_regclass('public.animal'), to_regclass('public.cliente')
)
order by con.conrelid::regclass::text, con.conname;

select tablename, indexname, indexdef
from pg_catalog.pg_indexes
where schemaname = 'public' and tablename in ('adocao', 'animal', 'cliente')
order by tablename, indexname;

-- Labels reais se status for um ENUM PostgreSQL.
select c.relname as tabela, a.attname as coluna, t.typname as tipo,
       e.enumlabel, e.enumsortorder
from pg_catalog.pg_attribute a
join pg_catalog.pg_class c on c.oid = a.attrelid
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
join pg_catalog.pg_type t on t.oid = a.atttypid
join pg_catalog.pg_enum e on e.enumtypid = t.oid
where n.nspname = 'public' and c.relname in ('adocao', 'animal') and a.attname = 'status'
order by c.relname, e.enumsortorder;

-- Policies são combinadas (políticas permissivas são OR). Revisar TODAS.
select schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
from pg_catalog.pg_policies
where schemaname = 'public' and tablename in ('adocao', 'animal', 'cliente')
order by tablename, policyname;

-- Grants diretos e por coluna. Revisar também grants herdados de outros papéis.
select table_name, grantee, privilege_type, is_grantable
from information_schema.table_privileges
where table_schema = 'public' and table_name in ('adocao', 'animal', 'cliente')
order by table_name, grantee, privilege_type;

select table_name, column_name, grantee, privilege_type, is_grantable
from information_schema.column_privileges
where table_schema = 'public' and table_name in ('adocao', 'animal', 'cliente')
order by table_name, grantee, column_name, privilege_type;

select rolname, rolsuper, rolbypassrls, rolinherit
from pg_catalog.pg_roles
where rolname in ('anon', 'authenticated', 'authenticator', 'service_role', current_user);

select membro.rolname as membro, grupo.rolname as papel_herdado
from pg_catalog.pg_auth_members m
join pg_catalog.pg_roles membro on membro.oid = m.member
join pg_catalog.pg_roles grupo on grupo.oid = m.roleid
where membro.rolname in ('anon', 'authenticated', 'authenticator');

-- Triggers/funções existentes podem alterar estados ou abrir outro caminho de escrita.
select c.relname as tabela, t.tgname,
       pg_catalog.pg_get_triggerdef(t.oid, true) as definicao
from pg_catalog.pg_trigger t
join pg_catalog.pg_class c on c.oid = t.tgrelid
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relname in ('adocao', 'animal', 'cliente')
  and not t.tgisinternal
order by c.relname, t.tgname;

select p.oid::regprocedure as funcao, pg_get_userbyid(p.proowner) as proprietario,
       p.prosecdef as security_definer, p.proconfig as configuracao, p.proacl as acl
from pg_catalog.pg_proc p
join pg_catalog.pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and (
  p.proname ilike '%adocao%' or p.proname ilike '%animal%' or p.prosecdef
)
order by p.oid::regprocedure::text;
