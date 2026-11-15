# Recuperação gerenciada do Entre Patas — 15/11/2026

## Resultado e escopo

**A restauração seletiva do banco da aplicação e a prova técnica de Auth foram
concluídas no Supabase gerenciado de recuperação.** Foram aprovadas 29 verificações
finais, sem falha funcional pendente. Isso não equivale a copiar todas as
configurações externas do projeto ou a aprovar o cadastro público por e-mail.

- Destino exclusivo: `juqnompkixqltwjldzva`.
- Projeto original protegido: `cyaxnaflvnjnpryryorr`; não foi acessado nem modificado.
- Banco/cliente PostgreSQL: 17.11, via Docker.
- Nenhum SQL 10, 12 ou 15 foi executado, no destino ou no original.
- Nenhuma URL/chave do Flutter foi alterada. Não houve commit, push ou deploy.

## Identidade e proteção da conexão

Foi confirmado o login cliente **`postgres.juqnompkixqltwjldzva`**, no session
pooler informado, porta 5432, com `sslmode=verify-full` e o certificado fornecido.
O PostgreSQL retorna `session_user/current_user=postgres`, mapeamento esperado do
pooler; o projeto é selecionado pelo login cliente explicitamente fixado.

O driver rejeita outro projeto, credencial ambígua, wildcard ou referência ao
original no arquivo de conexão. Não reutiliza o vínculo CLI da origem. A credencial
foi montada somente para leitura e copiada para tmpfs com modo **600**, removido ao
encerrar cada cliente Docker. Senhas e chaves não foram impressas nem gravadas
em arquivos versionados.

Antes da escrita, a leitura comprovou: tabelas da aplicação ausentes, schema private
ausente, Auth users/identities vazios, usuário administrativo e permissões de
INSERT, REFERENCES e TRIGGER necessárias. O mesmo estado foi exigido novamente
dentro da transação. O destino não forneceu um GUC de project_ref; a identificação
usou login cliente fixado, TLS, configuração explícita e os guards de destino vazio.

## Seleção revisada e execução

O inventário completo foi confrontado com o arquivo custom e os hashes originais.
`roles.sql` foi revisado e **não foi executado**. `schema-app-revisao.sql` também
não foi executado integralmente: continha a rotina administrativa de auto-RLS e
defaults que não fazem parte da seleção final.

Selecionados 106 itens TOC:

- Schema private, cinco tabelas da aplicação, cinco sequências e oito funções.
- Sete conjuntos de dados: Auth users/identities e cinco tabelas públicas;
  **40 registros selecionados** do dump completo de 45 COPYs/417 registros.
- Constraints, índices, sete FKs da aplicação, dez policies, RLS, ACLs de objetos
  e concessões de coluna.
- O trigger `on_entre_patas_auth_user_created ON auth.users`, instalado por último.

Ficaram fora: DDL de Auth/Storage/Realtime/Vault, papéis e marcadores gerenciados,
DEFAULT ACLs globais e eventos administrativos da origem. A rotina
`public.rls_auto_enable()` não existe no destino e não foi recriada: é uma
exclusão administrativa declarada. As cinco tabelas restauradas estão
explicitamente com RLS ativa; os oito contratos de aplicação foram preservados.

Os SQLs foram preparados previamente em pasta externa com ACL restrita, revisados
e executados pelo wrapper guardado. Houve uma única transação de escrita,
`ON_ERROR_STOP=1`, locks Auth, timeouts e verificações antes do COMMIT. Nenhum
DROP CASCADE, limpeza de schemas ou elevação de SUPERUSER foi utilizado.

### Auth e prevenção de duplicação

O destino não permite alterar `session_replication_role`. Esse comando não foi
tentado. A alternativa foi verificada: zero triggers de usuário nas duas tabelas
Auth antes da carga, ordem users → identities → cliente → demais tabelas e trigger
de criação de perfil somente depois dos dados e constraints.

Foram preservados os quatro UUIDs, hashes de senha, identities e vínculos com
cliente. Não houve confirmação, reativação ou login das quatro contas originais.
As colunas geradas `confirmed_at` e `identities.email` ficaram sob controle do
schema gerenciado do destino.

Não foram importadas sessões, refresh tokens, MFA AMR, flow_state ou one-time
tokens antigos. **Um confirmation_token pendente foi limpo intencionalmente na
cópia de trabalho.** Portanto, Auth users não é uma cópia byte a byte desse campo
do original; os demais dados selecionados e hashes de senha foram preservados.
Nenhum arquivo de backup foi alterado.

## Contagens comprovadas

| Objeto | Backup esperado | Após restaurar, antes do teste | Atual, com conta fictícia |
| --- | ---: | ---: | ---: |
| public.cliente | 12 | 12 | 13 |
| public.animal | 11 | 11 | 11 |
| public.adocao | 2 | 2 | 2 |
| public.questionario | 7 | 7 | 7 |
| public.recuperacao_senha | 0 | 0 | 0 |
| auth.users | 4 | 4 | 5 |
| auth.identities | 4 | 4 | 5 |

O acréscimo atual é **um único usuário/perfil fictício**, mantido como evidência
do teste. Não é divergência dos registros recuperados. As sete tabelas foram
comparadas novamente após a prova, excluindo somente esse ator fictício:
todos os registros migrados continuaram iguais à cópia revisada.

## Verificações executadas no destino

| Teste | Resultado | Evidência |
| --- | --- | --- |
| Seleção e dados | PASSOU | Sete fingerprints/contagens equivalentes à cópia revisada |
| Identidades e perfis | PASSOU | Quatro vínculos únicos, quatro identities; zero órfãos |
| Integridade | PASSOU | Sete FKs da aplicação validadas; zero constraints da aplicação pendentes |
| Sequências | PASSOU | Cinco valores/estados is_called iguais ao snapshot, antes da conta fictícia |
| Funções e segurança | PASSOU | Oito funções de aplicação, dez policies, oito entradas de tabela e 72 entradas de coluna equivalentes |
| RLS | PASSOU | Cinco tabelas com RLS; cliente autenticado lê só seu perfil, inclusive ocultando legados sem Auth |
| Componentes gerenciados | PASSOU | Dez fingerprints de catálogo, incluindo roles/defaults, iguais antes/depois; adição esperada do trigger da aplicação |
| Criação de conta fictícia | PASSOU | API administrativa suportada retornou HTTP 200; sem envio de e-mail |
| Login normal da conta fictícia | PASSOU | Endpoint de senha HTTP 200; consulta /user HTTP 200 |
| Trigger de cadastro | PASSOU | Exatamente um perfil ativo para o novo usuário |
| Acesso aos dados via API | PASSOU | Perfil próprio HTTP 200; outros perfis privados não retornados |
| Acesso anônimo a cliente | PASSOU | HTTP 401/SQLSTATE 42501: SELECT não concedido ao anônimo |
| Schema private na API | PASSOU | HTTP 406: não exposto pelo PostgREST |
| Preservação dos originais | PASSOU | Quatro arquivos de entrada com os mesmos SHA-256 |
| Cadastro público/e-mail e recuperação de senha | NÃO EXECUTADO | Dependem de confirmação, SMTP e redirects; não foram enviados e-mails |
| Login dos quatro usuários recuperados | NÃO EXECUTADO | Nenhuma senha real foi solicitada ou utilizada |
| Flutter Web no destino | NÃO EXECUTADO | A URL do aplicativo foi preservada conforme a restrição |

### Ocorrências e correções do validador

- A primeira sondagem não encaminhou stdin ao Docker e não produziu a evidência
  SQL esperada. O runner foi corrigido antes de qualquer escrita.
- A revisão detectou 16 comandos de timeout zero nos cabeçalhos extraídos.
  Foram removidos somente na cópia final, preservando limites durante o restore.
- A primeira asserção anônima esperava HTTP 200/lista vazia, mas o destino negou
  corretamente com HTTP 401/42501. A execução parou; a expectativa foi corrigida
  e a negação foi novamente comprovada por leitura. Nenhuma permissão foi relaxada
  e nenhuma segunda conta foi criada.

Não houve erro de restauração SQL, de constraints ou de trigger deixado sem solução.
O histórico completo dessas ocorrências foi preservado, sem dados pessoais.

## Configurações e trabalho ainda separados

- Site URL, redirects, SMTP, templates, provedores, chaves/secrets e demais ajustes
  Auth não foram copiados ou certificados. O teste criou administrativamente só
  a conta fictícia com confirmação explícita; não prova envio/recebimento de e-mail.
- Storage e Edge Functions estavam vazios no snapshot/inventário anterior.
  Nenhuma função foi publicada. O código local de exclusão de conta e SQL 20
  continuam escopo independente.
- As onze referências externas de imagens foram preservadas; os arquivos e sua
  disponibilidade não fazem parte do dump e não foram baixados.
- Os responsáveis dos nove animais sem vínculo Auth permanecem sem vínculo,
  conforme o backup. Não houve associação ou reativação automática.
- O destino reproduz o estado **anterior às migrações 12/15/10**. Não foi aplicado
  SQL 16 como prova de pós-migração, pois ele esperaria objetos ainda não instalados.
- Uma eventual mudança de tráfego exige compatibilizar banco/Flutter, reconciliar
  gravações posteriores ao snapshot e obter autorização explícita.

A lacuna anterior de demonstrar uma restauração seletiva no serviço gerenciado
foi resolvida neste destino. Isso não autoriza modificar o original: as migrações
online continuam proibidas até uma instrução explícita posterior.

## Arquivos de revisão e evidências

Diretório privado, fora do Git:

`%USERPROFILE%\EntrePatas-Backups\restauracao-seletiva-2026-11-15T16-54-52-497Z-6f90ff`.

Contém a seleção TOC, SQLs individuais, manifesto e:

- `09_restauracao_revisionada_apenas_recuperacao.sql`: script efetivamente usado.
- `10_resultado_restauracao_online.json`: resultado e histórico sanitizados.

Os arquivos SQL de dados incluem informação confidencial restaurada e devem
permanecer nessa pasta protegida; não anexar ao GitHub ou à conversa.

Os originais database.dump, roles.sql, inventario-restauracao.txt e
schema-app-revisao.sql mantiveram seus hashes. Apenas documentação e artefatos
de trabalho foram criados nesta rodada; o código e a configuração Flutter não mudaram.
