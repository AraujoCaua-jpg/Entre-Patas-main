-- Fixture for in-memory PGlite only. Function definitions inspected in
-- production on 2026-11-14; no records or credentials. Reproduces the
-- public profile dependency on available animals before SQL 12.

CREATE OR REPLACE FUNCTION private.resumo_responsavel(p_cliente_id integer)
 RETURNS TABLE(id integer, nome text, usuario text, imagem text)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  SELECT
    c.id,
    c.nome::text,
    c.usuario::text,
    c.imagem::text
  FROM public.cliente c
  WHERE c.id = p_cliente_id
    AND (
      c.auth_user_id = (SELECT auth.uid())
      OR EXISTS (
        SELECT 1
        FROM public.animal a
        WHERE a.id_cliente = c.id
          AND a.ativo IS TRUE
          AND a.status = 'Disponível'
      )
    )
  LIMIT 1;
$function$;

CREATE OR REPLACE FUNCTION private.detalhe_publico_responsavel(p_cliente_id integer)
 RETURNS TABLE(id integer, nome text, sobrenome text, usuario text, imagem text, cidade text, estado text, lar_de_adocao boolean)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  SELECT
    c.id,
    c.nome::text,
    c.sobrenome::text,
    c.usuario::text,
    c.imagem::text,
    c."cidadeDeResidencia"::text,
    c.estado::text,
    COALESCE(c."larDeAdocao", false)
  FROM public.cliente AS c
  WHERE c.id = p_cliente_id
    AND c.ativo IS TRUE
    AND (
      c.auth_user_id = (SELECT auth.uid())
      OR EXISTS (
        SELECT 1
        FROM public.animal AS a
        WHERE a.id_cliente = c.id
          AND a.ativo IS TRUE
          AND a.status = 'Disponível'
      )
    )
  LIMIT 1;
$function$;

CREATE OR REPLACE FUNCTION public.buscar_resumo_responsavel(p_cliente_id integer)
 RETURNS TABLE(id integer, nome text, usuario text, imagem text)
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  SELECT *
  FROM private.resumo_responsavel(p_cliente_id);
$function$;

CREATE OR REPLACE FUNCTION public.buscar_perfil_publico(p_cliente_id integer)
 RETURNS TABLE(id integer, nome text, sobrenome text, usuario text, imagem text, cidade text, estado text, lar_de_adocao boolean)
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  SELECT *
  FROM private.detalhe_publico_responsavel(p_cliente_id);
$function$;

CREATE OR REPLACE FUNCTION public.buscar_clientes_publicos(p_termo text DEFAULT NULL::text)
 RETURNS TABLE(id integer, nome text, sobrenome text, email text, telefone text, usuario text, imagem text, estado text, "cidadeDeResidencia" text, endereco text, "larDeAdocao" boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
    v_termo text := btrim(coalesce(p_termo, ''));
BEGIN
    IF auth.uid() IS NULL OR NOT EXISTS (
        SELECT 1
        FROM public.cliente eu
        WHERE eu.auth_user_id = auth.uid()
          AND eu.ativo IS TRUE
    ) THEN
        RAISE EXCEPTION 'Acesso não autorizado.';
    END IF;

    IF length(v_termo) > 100 THEN
        RAISE EXCEPTION 'Pesquisa muito longa.';
    END IF;

    RETURN QUERY
    SELECT
        c.id,
        c.nome::text,
        c.sobrenome::text,
        ''::text,
        ''::text,
        c.usuario::text,
        c.imagem::text,
        c.estado::text,
        c."cidadeDeResidencia"::text,
        ''::text,
        c."larDeAdocao"
    FROM public.cliente c
    WHERE c.ativo IS TRUE
      AND (
          v_termo = ''
          OR c.nome ILIKE '%' || v_termo || '%'
          OR c.usuario ILIKE '%' || v_termo || '%'
      )
    ORDER BY c.nome, c.id
    LIMIT 50;
END;
$function$;
