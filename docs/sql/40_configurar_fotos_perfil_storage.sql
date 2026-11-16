-- PROPOSTA LOCAL: não executada automaticamente. Revisar antes de aplicar.
-- Cria somente um bucket NOVO. Se avatars já existir, inspecionar suas políticas
-- e limites; este script aborta sem modificar o bucket nem arquivos existentes.
begin;

do $$
begin
  if exists (select 1 from storage.buckets where id = 'avatars') then
    raise exception 'O bucket avatars já existe. Revise a configuração existente; nenhuma alteração foi aplicada.';
  end if;
end $$;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152,
        array['image/jpeg', 'image/png', 'image/webp']);

-- Somente o usuário autenticado com perfil ativo publica na própria pasta.
create policy ep_avatar_inserir_proprio on storage.objects
for insert to authenticated with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and owner_id = (select auth.uid())::text
  and exists (
    select 1 from public.cliente c
    where c.auth_user_id = (select auth.uid()) and c.ativo = true
  )
);

-- O bucket público atende às imagens dos perfis. A leitura dos metadados pelo
-- SDK e a limpeza de um envio que falhou ficam limitadas ao próprio usuário.
create policy ep_avatar_consultar_proprio on storage.objects
for select to authenticated using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and owner_id = (select auth.uid())::text
);

create policy ep_avatar_excluir_proprio on storage.objects
for delete to authenticated using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and owner_id = (select auth.uid())::text
);

-- Sem UPDATE/upsert: cada foto nova recebe um caminho diferente.
commit;
