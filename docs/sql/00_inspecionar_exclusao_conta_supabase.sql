-- Somente leitura. Execute no SQL Editor para revisar o esquema antes de
-- considerar a migração 20. Este arquivo não altera dados nem configurações.

-- Colunas, tipos, nulabilidade e limites dos dados envolvidos.
select table_schema, table_name, ordinal_position, column_name, data_type,
       udt_name, is_nullable, character_maximum_length, column_default
from information_schema.columns
where (table_schema = 'public' and table_name in
       ('cliente', 'animal', 'adocao', 'questionario'))
   or (table_schema = 'auth' and table_name = 'users')
   or (table_schema = 'storage' and table_name = 'objects')
order by table_schema, table_name, ordinal_position;

-- Todas as FKs entre Auth, perfil, animais, adoções e questionário,
-- incluindo a ação ON DELETE configurada.
select fk.conname,
       fk.conrelid::regclass as tabela_origem,
       pg_get_constraintdef(fk.oid) as definicao
from pg_catalog.pg_constraint fk
where fk.contype = 'f'
  and (
    fk.conrelid in (
      to_regclass('public.cliente'), to_regclass('public.animal'),
      to_regclass('public.adocao'), to_regclass('public.questionario')
    )
    or fk.confrelid in (
      to_regclass('auth.users'), to_regclass('public.cliente'),
      to_regclass('public.animal'), to_regclass('public.adocao'),
      to_regclass('public.questionario')
    )
  )
order by fk.conrelid::regclass::text, fk.conname;

-- Check constraints e índices únicos que podem rejeitar os valores do tombstone.
select conrelid::regclass as tabela, conname, contype,
       pg_get_constraintdef(oid) as definicao
from pg_catalog.pg_constraint
where conrelid in (
  to_regclass('public.cliente'), to_regclass('public.animal'),
  to_regclass('public.adocao'), to_regclass('public.questionario')
)
order by conrelid::regclass::text, conname;

select schemaname, tablename, indexname, indexdef
from pg_catalog.pg_indexes
where schemaname = 'public'
  and tablename in ('cliente', 'animal', 'adocao', 'questionario')
order by tablename, indexname;

-- RLS, políticas e permissões atuais. A migração não desativa a RLS.
select n.nspname as esquema, c.relname as tabela, c.relrowsecurity as rls,
       c.relforcerowsecurity as force_rls
from pg_catalog.pg_class c
join pg_catalog.pg_namespace n on n.oid = c.relnamespace
where (n.nspname = 'public' and c.relname in
       ('cliente', 'animal', 'adocao', 'questionario'))
   or (n.nspname = 'storage' and c.relname = 'objects')
order by n.nspname, c.relname;

select schemaname, tablename, policyname, roles, cmd, qual, with_check
from pg_catalog.pg_policies
where (schemaname = 'public' and tablename in
       ('cliente', 'animal', 'adocao', 'questionario'))
   or (schemaname = 'storage' and tablename = 'objects')
order by schemaname, tablename, policyname;

-- Triggers de usuário sobre Auth e tabelas públicas relacionadas.
-- Investigar manualmente qualquer trigger que também altere estes dados.
select t.tgrelid::regclass as tabela, t.tgname,
       pg_get_triggerdef(t.oid) as definicao,
       pg_get_functiondef(t.tgfoid) as funcao
from pg_catalog.pg_trigger t
where not t.tgisinternal
  and t.tgrelid in (
    to_regclass('auth.users'), to_regclass('public.cliente'),
    to_regclass('public.animal'), to_regclass('public.adocao'),
    to_regclass('public.questionario')
  )
order by t.tgrelid::regclass::text, t.tgname;

-- Contagem de arquivos por proprietário e bucket (não retorna nomes de objetos).
select bucket_id, owner_id, count(*) as quantidade
from storage.objects
group by bucket_id, owner_id
order by bucket_id, owner_id;

-- Buckets configurados e visibilidade. Revisar quais podem conter imagens pessoais.
select id, name, public, file_size_limit, allowed_mime_types
from storage.buckets
order by id;
