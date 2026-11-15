-- SOMENTE LEITURA: IDs, flags e contagens; não retorna nome, contato ou Auth UUID.
-- Referências internas identificadas na investigação: 1 e 38 (carregam).
-- O ID 1 abaixo representa o observador para COMPARAR o predicado antigo.
-- A elegibilidade calculada modela o PERFIL (detalhe_publico_responsavel).
-- Não é resultado de RPC executada como esse usuário ou teste de sessão real.
-- Não altera auth.uid(), não assume sessão de outra pessoa e não chama RPCs.
-- Executar pelo CLI com --read-only no projeto explicitamente indicado.
with observador as (
  select 1::integer as id,
    exists(select 1 from public.cliente where id=1 and ativo is true
      and auth_user_id is not null) as perfil_auth_ativo
), perfis as (
  select c.id,c.ativo is true as ativo,c.auth_user_id is not null as possui_auth,
    count(a.id) as animais,
    count(a.id) filter(where a.ativo is true and a.status::text='Disponível') as disponiveis
  from public.cliente c left join public.animal a on a.id_cliente=c.id
  group by c.id,c.ativo,c.auth_user_id
), comparacao as (
  select p.*,o.id as observador_id,
    o.perfil_auth_ativo and p.ativo and (p.id=o.id or p.disponiveis>0)
      as elegivel_pelo_predicado_antigo,
    o.perfil_auth_ativo and p.ativo as elegivel_apos_sql12
  from perfis p cross join observador o
)
select jsonb_build_object(
  'captured_at',current_timestamp,
  'read_only',current_setting('transaction_read_only'),
  'inspection_role',current_user,
  'profiles',(select jsonb_agg(to_jsonb(c) order by c.id) from comparacao c),
  'functions',(select jsonb_agg(to_jsonb(f)) from (
    select n.nspname as schema,p.oid::regprocedure::text as signature,
      pg_get_function_result(p.oid) as result,p.prosecdef,p.proconfig,
      md5(pg_get_functiondef(p.oid)) as definition_md5
    from pg_catalog.pg_proc p join pg_catalog.pg_namespace n on n.oid=p.pronamespace
    where (n.nspname='public' and p.proname in
      ('buscar_perfil_publico','buscar_resumo_responsavel'))
      or (n.nspname='private' and p.proname in
        ('detalhe_publico_responsavel','resumo_responsavel'))
  ) f)
) as profile_audit;
