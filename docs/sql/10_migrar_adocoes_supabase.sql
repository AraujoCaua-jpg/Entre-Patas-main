-- REVISÃO E APLICAÇÃO MANUAL NO SUPABASE. NÃO EXECUTADO POR ESTA ENTREGA.
-- Primeiro revisar 00_inspecionar_adocoes_supabase.sql e docs/adocoes_supabase.md.
-- Baseado nos campos/regras de backend/adocoes.php; não presume esquema remoto verificado.
-- Tudo é transacional: qualquer incompatibilidade aborta sem alteração parcial.
-- Não apaga registros, não cria tabelas e não desativa RLS.

begin;

-- Impede modificações concorrentes entre as auditorias e a criação dos índices.
-- Esses locks são de instalação, não do aplicativo: agendar em janela adequada.
lock table public.cliente, public.animal, public.adocao in share row exclusive mode;

do $preflight$
declare
  campo record;
  fk record;
  tipo oid;
  classe "char";
  labels text[];
begin
  if not exists (
    select 1 from pg_catalog.pg_roles
    where rolname = current_user and (rolsuper or rolbypassrls)
  ) then
    raise exception 'Executar esta migração com o administrador do banco, nunca pelo Flutter.';
  end if;
  if to_regprocedure('auth.uid()') is null or
     not exists (select 1 from pg_catalog.pg_roles where rolname = 'authenticated') or
     not exists (select 1 from pg_catalog.pg_roles where rolname = 'anon') then
    raise exception 'Ambiente Supabase Auth/papéis esperados não encontrado. Revisar a inspeção.';
  end if;

  for campo in select * from (values
    ('cliente','id'), ('cliente','auth_user_id'), ('cliente','ativo'),
    ('cliente','nome'), ('cliente','sobrenome'), ('cliente','email'),
    ('cliente','telefone'), ('cliente','estado'), ('cliente','cidadeDeResidencia'),
    ('animal','id'), ('animal','id_cliente'), ('animal','ativo'), ('animal','status'),
    ('animal','nome'), ('animal','imagem'), ('animal','idade'), ('animal','sexo'),
    ('adocao','id'), ('adocao','data'), ('adocao','status'),
    ('adocao','id_animal'), ('adocao','id_cliente'), ('adocao','id_dono')
  ) as esperados(tabela, coluna)
  loop
    if not exists (
      select 1 from information_schema.columns
      where table_schema = 'public' and table_name = campo.tabela and column_name = campo.coluna
    ) then
      raise exception 'Coluna obrigatória public.%.% ausente. Adaptar a migração à estrutura real.', campo.tabela, campo.coluna;
    end if;
  end loop;

  for campo in select * from (values
    ('cliente','id'), ('animal','id'), ('animal','id_cliente'),
    ('adocao','id'), ('adocao','id_animal'), ('adocao','id_cliente'), ('adocao','id_dono')
  ) as ids(tabela,coluna)
  loop
    select a.atttypid into tipo from pg_catalog.pg_attribute a
    where a.attrelid = format('public.%I', campo.tabela)::regclass and a.attname = campo.coluna;
    if tipo not in ('smallint'::regtype, 'integer'::regtype, 'bigint'::regtype) then
      raise exception 'Tipo de public.%.% não suportado automaticamente; revisar esquema.', campo.tabela, campo.coluna;
    end if;
  end loop;
  if (select atttypid from pg_catalog.pg_attribute where attrelid='public.cliente'::regclass and attname='auth_user_id') <> 'uuid'::regtype or
     (select atttypid from pg_catalog.pg_attribute where attrelid='public.cliente'::regclass and attname='ativo') <> 'boolean'::regtype or
     (select atttypid from pg_catalog.pg_attribute where attrelid='public.animal'::regclass and attname='ativo') <> 'boolean'::regtype then
    raise exception 'Esperados auth_user_id uuid e ativo boolean. Não converter dados sem revisão.';
  end if;
  if (select atttypid from pg_catalog.pg_attribute where attrelid='public.adocao'::regclass and attname='data') not in
     ('timestamp'::regtype, 'timestamptz'::regtype, 'date'::regtype) then
    raise exception 'Tipo de adocao.data incompatível. Revisar a inspeção.';
  end if;
  if not exists (
    select 1 from pg_catalog.pg_attribute
    where attrelid='public.adocao'::regclass and attname='id'
      and (atthasdef or attidentity <> '')
  ) then
    raise exception 'adocao.id precisa de default/identity existente; não será criado automaticamente.';
  end if;
  if exists (
    select 1 from pg_catalog.pg_attribute
    where attrelid='public.adocao'::regclass and attnum>0 and not attisdropped
      and attnotnull and not atthasdef and attidentity=''
      and attname not in ('data','status','id_animal','id_cliente','id_dono')
  ) then
    raise exception 'adocao possui outra coluna obrigatória sem default. Adaptar INSERT à estrutura real.';
  end if;

  for campo in select * from (values
    ('adocao', array['Aguardando','Aceito','Recusado','Cancelado']::text[]),
    ('animal', array['Disponível','Adotado']::text[])
  ) as estados(tabela,obrigatorios)
  loop
    select a.atttypid, t.typtype into tipo, classe
    from pg_catalog.pg_attribute a join pg_catalog.pg_type t on t.oid=a.atttypid
    where a.attrelid=format('public.%I',campo.tabela)::regclass and a.attname='status';
    if classe='e' then
      select array_agg(enumlabel::text) into labels from pg_catalog.pg_enum where enumtypid=tipo;
      if not campo.obrigatorios <@ labels then
        raise exception 'ENUM %.status não contém os estados exigidos; revisar sem reescrever históricos.', campo.tabela;
      end if;
    elsif tipo not in ('text'::regtype,'varchar'::regtype) then
      raise exception 'Tipo de %.status não suportado automaticamente.', campo.tabela;
    end if;
  end loop;

  for fk in select * from (values
    ('adocao','id_animal','animal'), ('adocao','id_cliente','cliente'),
    ('adocao','id_dono','cliente'), ('animal','id_cliente','cliente')
  ) as ligacoes(tabela,coluna,referencia)
  loop
    if not exists (
      select 1 from pg_catalog.pg_constraint k
      join pg_catalog.pg_attribute origem on origem.attrelid=k.conrelid and origem.attnum=k.conkey[1]
      join pg_catalog.pg_attribute destino on destino.attrelid=k.confrelid and destino.attnum=k.confkey[1]
      where k.contype='f' and k.convalidated and cardinality(k.conkey)=1
        and k.conrelid=format('public.%I',fk.tabela)::regclass and origem.attname=fk.coluna
        and k.confrelid=format('public.%I',fk.referencia)::regclass and destino.attname='id'
    ) then
      raise exception 'FK validada de %.% para %.id ausente. Revisar/aplicar separadamente após auditoria dos dados.', fk.tabela,fk.coluna,fk.referencia;
    end if;
  end loop;
  if exists (
    select 1 from pg_catalog.pg_class
    where oid in ('public.cliente'::regclass,'public.animal'::regclass) and not relrowsecurity
  ) then
    raise exception 'RLS de cliente e animal deve estar habilitada e revisada antes desta migração.';
  end if;
  if exists (select 1 from public.cliente where auth_user_id is not null group by auth_user_id having count(*)>1) then
    raise exception 'Perfis duplicados por auth_user_id. Revisar sem apagar registros automaticamente.';
  end if;
  if exists (select 1 from public.adocao where status::text not in ('Aguardando','Aceito','Recusado','Cancelado') or status is null
      or id_animal is null or id_cliente is null or id_dono is null or data is null or id_cliente=id_dono) then
    raise exception 'Histórico de adoção incompatível ou com campos nulos/autossolicitações. Revisar os registros existentes.';
  end if;
  if exists (select 1 from public.adocao where status::text in ('Aguardando','Aceito') group by id_animal,id_cliente having count(*)>1) then
    raise exception 'Pedidos Aguardando/Aceito duplicados por animal/adotante. Resolver manualmente preservando histórico.';
  end if;
  if exists (select 1 from public.adocao where status::text='Aceito' group by id_animal having count(*)>1) then
    raise exception 'Mais de um pedido Aceito para o mesmo animal. Resolver manualmente antes de criar o índice.';
  end if;
  if exists (
    select 1 from public.adocao d join public.animal a on a.id=d.id_animal
    where d.status::text='Aceito' and a.status::text is distinct from 'Adotado'
  ) or exists (
    select 1 from public.adocao aceita join public.adocao pendente
      on pendente.id_animal=aceita.id_animal
    where aceita.status::text='Aceito' and pendente.status::text='Aguardando'
  ) then
    raise exception 'Histórico Aceito inconsistente com animal/pendências. Revisar sem reabrir ou excluir registros.';
  end if;
  if to_regclass('public.ep_adocao_em_andamento_unica') is not null or
     to_regclass('public.ep_adocao_aceita_unica') is not null then
    raise exception 'Índices desta migração já existem. Não reaplicar; conferir versão e definições antes de atualizar.';
  end if;
end;
$preflight$;

create unique index ep_adocao_em_andamento_unica
on public.adocao (id_animal,id_cliente) where status in ('Aguardando','Aceito');
create unique index ep_adocao_aceita_unica
on public.adocao (id_animal) where status='Aceito';

-- Sem acesso direto à tabela de solicitações: todas as leituras/escritas usam RPC.
alter table public.adocao enable row level security;
revoke all privileges on table public.adocao from public, anon, authenticated;
do $permissoes$
declare colunas text;
begin
  select string_agg(format('%I',attname),', ') into colunas
  from pg_catalog.pg_attribute
  where attrelid='public.adocao'::regclass and attnum>0 and not attisdropped;
  execute format('revoke all privileges (%s) on table public.adocao from public, anon, authenticated', colunas);
  if has_table_privilege('authenticated','public.adocao','SELECT,INSERT,UPDATE,DELETE,TRUNCATE') or
     has_any_column_privilege('authenticated','public.adocao','SELECT,INSERT,UPDATE') or
     has_table_privilege('anon','public.adocao','SELECT,INSERT,UPDATE,DELETE,TRUNCATE') or
     has_any_column_privilege('anon','public.adocao','SELECT,INSERT,UPDATE') then
    raise exception 'Permissões herdadas ainda dão acesso direto a adocao; revisar memberships/grants antes de continuar.';
  end if;
end;
$permissoes$;

create or replace function public._ep_adocao_cliente_atual()
returns bigint language plpgsql security invoker set search_path=''
as $function$
declare v_id bigint;
begin
  if auth.uid() is null then
    raise sqlstate 'PT401' using message='Entre novamente para continuar.';
  end if;
  begin
    select c.id into strict v_id from public.cliente c
    where c.auth_user_id=auth.uid() and c.ativo is true;
  exception
    when no_data_found then
      raise sqlstate 'PT403' using message='Perfil não encontrado ou inativo.';
    when too_many_rows then
      raise sqlstate 'PT403' using message='Não foi possível identificar seu perfil. Entre novamente.';
  end;
  return v_id;
end;
$function$;

-- DTO equivalente ao PHP, limitado às duas partes. Nenhum perfil é público aqui.
create or replace function public._ep_adocoes_json(p_cliente_id bigint,p_adocao_id bigint default null)
returns jsonb language sql stable security invoker set search_path=''
as $function$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',d.id,'data',d.data,'status',d.status,
    'id_animal',d.id_animal,'id_cliente',d.id_cliente,'id_dono',d.id_dono,
    'animal_nome',a.nome,'animal_imagem',a.imagem,'animal_idade',a.idade,'animal_sexo',a.sexo,
    'estado',dono.estado,'cidadeDeResidencia',dono."cidadeDeResidencia",
    'solicitante_nome',pretendente.nome,'solicitante_sobrenome',pretendente.sobrenome,
    'solicitante_email',pretendente.email,'solicitante_telefone',pretendente.telefone
  ) order by d.data desc,d.id desc),'[]'::jsonb)
  from public.adocao d
  join public.animal a on a.id=d.id_animal
  join public.cliente dono on dono.id=d.id_dono
  join public.cliente pretendente on pretendente.id=d.id_cliente
  where (d.id_cliente=p_cliente_id or d.id_dono=p_cliente_id)
    and (p_adocao_id is null or d.id=p_adocao_id);
$function$;

create or replace function public.listar_minhas_adocoes()
returns jsonb language plpgsql security definer set search_path=''
as $function$
begin
  return public._ep_adocoes_json(public._ep_adocao_cliente_atual());
end;
$function$;

create or replace function public.buscar_minha_adocao(p_adocao_id bigint)
returns jsonb language plpgsql security definer set search_path=''
as $function$
declare v_resultado jsonb;
begin
  if p_adocao_id is null or p_adocao_id<=0 then
    raise sqlstate 'PT400' using message='ID inválido.';
  end if;
  v_resultado := public._ep_adocoes_json(public._ep_adocao_cliente_atual(),p_adocao_id)->0;
  if v_resultado is null then
    raise sqlstate 'PT404' using message='Solicitação não encontrada.';
  end if;
  return v_resultado;
end;
$function$;

create or replace function public.solicitar_adocao(p_animal_id bigint)
returns jsonb language plpgsql security definer set search_path=''
as $function$
declare
  v_cliente bigint := public._ep_adocao_cliente_atual();
  v_animal public.animal%rowtype;
  v_id bigint;
begin
  if p_animal_id is null or p_animal_id<=0 then
    raise sqlstate 'PT400' using message='ID inválido.';
  end if;
  -- Mesmo lock/ordem do PHP: animal primeiro, nunca uma adoção antes dele.
  select a.* into v_animal from public.animal a where a.id=p_animal_id for update;
  if not found then raise sqlstate 'PT404' using message='Animal não encontrado.'; end if;
  if v_animal.id_cliente=v_cliente then
    raise sqlstate 'PT400' using message='Você não pode solicitar a adoção do próprio animal.';
  end if;
  perform 1 from public.cliente where id=v_cliente and ativo is true for share;
  if not found then raise sqlstate 'PT403' using message='Perfil não encontrado ou inativo.'; end if;
  perform 1 from public.cliente where id=v_animal.id_cliente and ativo is true for share;
  if not found or v_animal.ativo is not true or v_animal.status::text is distinct from 'Disponível' then
    raise sqlstate 'PT409' using message='Este animal não está disponível para adoção.';
  end if;
  if exists (select 1 from public.adocao where id_animal=p_animal_id and id_cliente=v_cliente
      and status::text in ('Aguardando','Aceito')) then
    raise sqlstate 'PT409' using message='Você já possui uma solicitação em andamento para este animal.';
  end if;
  insert into public.adocao (data,status,id_animal,id_cliente,id_dono)
  values (now(),'Aguardando',p_animal_id,v_cliente,v_animal.id_cliente) returning id into v_id;
  return public._ep_adocoes_json(v_cliente,v_id)->0;
exception when unique_violation then
  raise sqlstate 'PT409' using message='Você já possui uma solicitação em andamento para este animal.';
end;
$function$;

create or replace function public.responder_adocao(p_adocao_id bigint,p_acao text)
returns jsonb language plpgsql security definer set search_path=''
as $function$
declare
  v_cliente bigint := public._ep_adocao_cliente_atual();
  v_animal_id bigint;
  v_animal public.animal%rowtype;
  v_pedido public.adocao%rowtype;
  v_status public.adocao.status%type;
begin
  if p_adocao_id is null or p_adocao_id<=0 then
    raise sqlstate 'PT400' using message='ID inválido.';
  end if;
  if p_acao is null or p_acao not in ('aceitar','recusar','cancelar') then
    raise sqlstate 'PT400' using message='Operação não encontrada.';
  end if;
  select id_animal into v_animal_id from public.adocao
  where id=p_adocao_id and (id_cliente=v_cliente or id_dono=v_cliente);
  if not found then raise sqlstate 'PT404' using message='Solicitação não encontrada.'; end if;
  -- A consulta anterior não trava o pedido. Todas as transições serializam pelo animal.
  select a.* into v_animal from public.animal a where a.id=v_animal_id for update;
  if not found then raise sqlstate 'PT404' using message='Animal não encontrado.'; end if;
  select d.* into v_pedido from public.adocao d where d.id=p_adocao_id for update;
  if not found or v_pedido.id_animal<>v_animal_id then
    raise sqlstate 'PT404' using message='Solicitação não encontrada.';
  end if;
  perform 1 from public.cliente where id=v_cliente and ativo is true for share;
  if not found then raise sqlstate 'PT403' using message='Perfil não encontrado ou inativo.'; end if;
  if (p_acao='cancelar' and v_pedido.id_cliente<>v_cliente) or
     (p_acao<>'cancelar' and (v_pedido.id_dono<>v_cliente or v_animal.id_cliente<>v_cliente)) then
    raise sqlstate 'PT403' using message='Você não pode realizar esta ação.';
  end if;
  if v_pedido.status::text<>'Aguardando' then
    raise sqlstate 'PT409' using message='Esta solicitação já foi finalizada.';
  end if;
  if p_acao='aceitar' then
    perform 1 from public.cliente where id=v_pedido.id_cliente and ativo is true for share;
    if not found or v_animal.ativo is not true or v_animal.status::text is distinct from 'Disponível' or
       exists (select 1 from public.adocao where id_animal=v_animal_id and status::text='Aceito') then
      raise sqlstate 'PT409' using message='Não é possível aprovar esta adoção.';
    end if;
    update public.animal set status='Adotado' where id=v_animal_id;
    update public.adocao set status='Recusado'
    where id_animal=v_animal_id and id<>p_adocao_id and status::text='Aguardando';
    v_status := 'Aceito';
  elsif p_acao='recusar' then
    v_status := 'Recusado';
  else
    v_status := 'Cancelado';
  end if;
  update public.adocao set status=v_status where id=p_adocao_id;
  return public._ep_adocoes_json(v_cliente,p_adocao_id)->0;
exception when unique_violation then
  raise sqlstate 'PT409' using message='Não é possível aprovar esta adoção.';
end;
$function$;

-- SECURITY INVOKER é deliberado: current_user é authenticated no PATCH direto,
-- mas é o proprietário privilegiado ao executar a RPC SECURITY DEFINER.
-- Não usa custom GUC, metadados de usuário ou outros marcadores falsificáveis.
create or replace function public._ep_proteger_status_adocao_animal()
returns trigger language plpgsql security invoker set search_path=''
as $function$
begin
  if current_user in ('authenticated','anon') then
    if tg_op='INSERT' then
      if new.status::text is distinct from 'Disponível' then
        raise sqlstate 'PT403' using message='O estado de adoção deve ser alterado pela solicitação.';
      end if;
    elsif new.status is distinct from old.status then
      raise sqlstate 'PT403' using message='O estado de adoção deve ser alterado pela solicitação.';
    end if;
  end if;
  return new;
end;
$function$;

create trigger ep_proteger_status_adocao_animal
before insert or update of status on public.animal
for each row execute function public._ep_proteger_status_adocao_animal();

-- Helpers não são endpoints. Revogar o EXECUTE padrão concedido a PUBLIC.
revoke all on function public._ep_adocao_cliente_atual() from public,anon,authenticated;
revoke all on function public._ep_adocoes_json(bigint,bigint) from public,anon,authenticated;
revoke all on function public._ep_proteger_status_adocao_animal() from public,anon,authenticated;
revoke all on function public.listar_minhas_adocoes() from public,anon,authenticated;
revoke all on function public.buscar_minha_adocao(bigint) from public,anon,authenticated;
revoke all on function public.solicitar_adocao(bigint) from public,anon,authenticated;
revoke all on function public.responder_adocao(bigint,text) from public,anon,authenticated;
grant execute on function public.listar_minhas_adocoes() to authenticated;
grant execute on function public.buscar_minha_adocao(bigint) to authenticated;
grant execute on function public.solicitar_adocao(bigint) to authenticated;
grant execute on function public.responder_adocao(bigint,text) to authenticated;

-- Atualiza apenas o cache de esquema da API, sem modificar dados.
notify pgrst, 'reload schema';
commit;
