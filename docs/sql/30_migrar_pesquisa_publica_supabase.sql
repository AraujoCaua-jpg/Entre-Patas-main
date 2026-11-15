-- REVISAR E APLICAR MANUALMENTE, DEPOIS DAS MIGRAÇÕES 10 E 12.
-- Requer backup recuperável e revisão específica antes de instalar.
-- O SQL 20 (exclusão de conta) é independente desta pesquisa: sua instalação
-- exige revisão e autorização separadas, não é um pré-requisito deste script.
-- Não executado pelo aplicativo. Mantém as regras de backend/animais.php e
-- backend/clientes.php: somente perfis/animais ativos, busca de pessoas pública
-- limitada e "Perto de mim" por cidade + UF exatas do perfil autenticado.
-- Perfil/resumo são mantidos pelo SQL 12 com as assinaturas INTEGER reais.
-- Não cria overloads BIGINT nem muda o retorno de buscar_clientes_publicos(text).
-- Contatos privados são sempre mascarados, inclusive para lares de adoção.

begin;

do $preflight$
declare item record;
begin
  if not exists (
    select 1 from pg_catalog.pg_roles
    where rolname=current_user and (rolsuper or rolbypassrls)
  ) then
    raise exception 'Executar com administrador do banco, nunca pelo aplicativo.';
  end if;
  if to_regprocedure('public._ep_adocao_cliente_atual()') is null then
    raise exception 'A migração 10 de adoções precisa estar aplicada primeiro.';
  end if;
  if to_regprocedure('public.buscar_perfil_publico(integer)') is null
     or to_regprocedure('public.buscar_resumo_responsavel(integer)') is null
     or to_regprocedure('public.buscar_perfil_publico(bigint)') is not null
     or to_regprocedure('public.buscar_resumo_responsavel(bigint)') is not null
     or coalesce(obj_description(to_regprocedure('private.resumo_responsavel(integer)'),'pg_proc'),'')
        <> 'Entre Patas SQL12 v1: perfil ativo, chamador Auth ativo, sem filtro de animais e sem contatos privados.'
     or coalesce(obj_description(to_regprocedure('private.detalhe_publico_responsavel(integer)'),'pg_proc'),'')
        <> 'Entre Patas SQL12 v1: perfil ativo, chamador Auth ativo, sem filtro de animais e sem contatos privados.' then
    raise exception 'Revisar/aplicar SQL 12 primeiro. Não remover overloads BIGINT automaticamente; reconciliar versões locais separadamente.';
  end if;
  if to_regprocedure('public.buscar_clientes_publicos(text)') is not null and exists (
    select 1 from pg_catalog.pg_proc p
    where p.oid=to_regprocedure('public.buscar_clientes_publicos(text)')
      and (pg_catalog.pg_get_function_result(p.oid)<>
        'TABLE(id integer, nome text, sobrenome text, email text, telefone text, usuario text, imagem text, estado text, "cidadeDeResidencia" text, endereco text, "larDeAdocao" boolean)'
        or p.proargnames is distinct from
          array['p_termo','id','nome','sobrenome','email','telefone','usuario','imagem','estado','cidadeDeResidencia','endereco','larDeAdocao']::text[])
  ) then
    raise exception 'Retorno/argumentos existentes de buscar_clientes_publicos(text) divergentes. Revisar sem DROP nem alteração implícita de assinatura.';
  end if;
  for item in select * from (values
    ('cliente','id'),('cliente','ativo'),('cliente','nome'),
    ('cliente','sobrenome'),('cliente','usuario'),('cliente','imagem'),
    ('cliente','estado'),('cliente','cidadeDeResidencia'),
    ('cliente','larDeAdocao'),('cliente','email'),('cliente','telefone'),
    ('cliente','endereco'),
    ('animal','id'),('animal','id_cliente'),('animal','ativo'),
    ('animal','status'),('animal','nome'),('animal','idade'),
    ('animal','imagem'),('animal','tipo'),('animal','descricao'),
    ('animal','sexo'),('animal','energia'),('animal','porte'),
    ('animal','convivencia'),('animal','carencia'),('animal','vacinado'),
    ('animal','castrado')
  ) as esperados(tabela,coluna)
  loop
    if not exists (
      select 1 from information_schema.columns
      where table_schema='public' and table_name=item.tabela
        and column_name=item.coluna
    ) then
      raise exception 'Coluna public.%.% ausente. Adaptar a migração após revisar o esquema.',
        item.tabela,item.coluna;
    end if;
  end loop;
  if exists (
    select 1 from pg_catalog.pg_class
    where oid in ('public.cliente'::regclass,'public.animal'::regclass)
      and not relrowsecurity
  ) then
    raise exception 'RLS de cliente e animal deve permanecer habilitada.';
  end if;
end;
$preflight$;

create or replace function public.ep_buscar_animais(
  p_tipo text default null,
  p_termo text default null,
  p_estado text default null,
  p_cidade text default null,
  p_sexo text default null,
  p_porte text default null,
  p_energia text default null,
  p_convivencia text default null,
  p_carencia text default null,
  p_status text default null,
  p_cliente_id bigint default null,
  p_somente_proprios boolean default false,
  p_animal_id bigint default null,
  p_pagina integer default 1
)
returns table (
  id bigint,
  nome text,
  idade integer,
  imagem text,
  tipo text,
  descricao text,
  sexo text,
  status text,
  energia text,
  porte text,
  convivencia text,
  carencia text,
  vacinado text,
  castrado text,
  id_cliente bigint,
  estado text,
  "cidadeDeResidencia" text
)
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_cliente_atual bigint := public._ep_adocao_cliente_atual();
  v_termo text := nullif(btrim(p_termo), '');
begin
  if p_pagina is null or p_pagina < 1 or p_pagina > 1000 then
    raise sqlstate 'PT400' using message='Página inválida.';
  end if;
  if p_animal_id is not null and p_animal_id <= 0 then
    raise sqlstate 'PT400' using message='ID inválido.';
  end if;
  if p_cliente_id is not null and p_cliente_id <= 0 then
    raise sqlstate 'PT400' using message='ID inválido.';
  end if;
  if p_somente_proprios and p_cliente_id is not null
     and p_cliente_id <> v_cliente_atual then
    raise sqlstate 'PT403' using message='Você não pode consultar os animais de outra conta.';
  end if;
  if v_termo is not null and char_length(v_termo) > 100 then
    raise sqlstate 'PT400' using message='Pesquisa muito longa.';
  end if;

  return query
  select a.id::bigint,a.nome::text,a.idade::integer,a.imagem::text,
         a.tipo::text,a.descricao::text,a.sexo::text,a.status::text,
         a.energia::text,a.porte::text,a.convivencia::text,a.carencia::text,
         a.vacinado::text,a.castrado::text,a.id_cliente::bigint,
         c.estado::text,c."cidadeDeResidencia"::text
    from public.animal a
    join public.cliente c on c.id=a.id_cliente
   where a.ativo is true and c.ativo is true
     and (
       (p_animal_id is not null and a.id=p_animal_id)
       or
       (p_animal_id is null and (
         (p_somente_proprios and a.id_cliente=v_cliente_atual)
         or
         (not p_somente_proprios and p_cliente_id is not null
          and a.id_cliente=p_cliente_id and a.status::text='Disponível')
         or
         (not p_somente_proprios and p_cliente_id is null
          and a.id_cliente<>v_cliente_atual and a.status::text='Disponível')
       ))
     )
     and (p_tipo is null or p_tipo='' or
          (p_tipo='Outros' and a.tipo::text not in ('Cachorro','Gato')) or
          (p_tipo<>'Outros' and a.tipo::text=p_tipo))
     and (v_termo is null or position(lower(v_termo) in lower(a.nome))>0)
     and (p_estado is null or p_estado='' or lower(c.estado)=lower(p_estado))
     and (p_cidade is null or p_cidade='' or
          lower(c."cidadeDeResidencia")=lower(p_cidade))
     and (p_sexo is null or p_sexo='' or a.sexo::text=p_sexo)
     and (p_porte is null or p_porte='' or a.porte::text=p_porte)
     and (p_energia is null or p_energia='' or a.energia::text=p_energia)
     and (p_convivencia is null or p_convivencia='' or a.convivencia::text=p_convivencia)
     and (p_carencia is null or p_carencia='' or a.carencia::text=p_carencia)
     and (p_status is null or p_status='' or a.status::text=p_status)
   order by a.nome,a.id
   limit 50 offset ((p_pagina-1)*50);
end;
$function$;

create or replace function public.buscar_clientes_publicos(p_termo text default null)
returns table (
  id integer,
  nome text,
  sobrenome text,
  email text,
  telefone text,
  usuario text,
  imagem text,
  estado text,
  "cidadeDeResidencia" text,
  endereco text,
  "larDeAdocao" boolean
)
language plpgsql
security definer
set search_path = ''
as $function$
declare v_termo text := nullif(ltrim(btrim(p_termo), '@'), '');
begin
  perform public._ep_adocao_cliente_atual();
  if v_termo is not null and char_length(v_termo)>100 then
    raise sqlstate 'PT400' using message='Pesquisa muito longa.';
  end if;
  return query
  select c.id::integer,c.nome::text,c.sobrenome::text,
         ''::text,
         ''::text,
         c.usuario::text,c.imagem::text,c.estado::text,
         c."cidadeDeResidencia"::text,
         ''::text,
         c."larDeAdocao"::boolean
    from public.cliente c
   where c.ativo is true
     and (v_termo is null or
          position(lower(v_termo) in lower(c.nome))>0 or
          position(lower(v_termo) in lower(c.usuario))>0)
   order by c.nome,c.id
   limit 50;
end;
$function$;

revoke all on function public.ep_buscar_animais(
  text,text,text,text,text,text,text,text,text,text,bigint,boolean,bigint,integer
) from public,anon,authenticated;
revoke all on function public.buscar_clientes_publicos(text)
  from public,anon,authenticated;
grant execute on function public.ep_buscar_animais(
  text,text,text,text,text,text,text,text,text,text,bigint,boolean,bigint,integer
) to authenticated;
grant execute on function public.buscar_clientes_publicos(text)
  to authenticated;

notify pgrst, 'reload schema';
commit;
