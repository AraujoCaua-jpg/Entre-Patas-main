# Revisão do SQL 10 para produção — Entre Patas

> **Atualização:** as três falhas abaixo foram corrigidas e testadas localmente
> na rodada documentada em [Correções finais](correcoes_finais_sql10.md).
> Este relatório preserva as causas e os resultados anteriores. A produção não
> recebeu os scripts; backup atual/restauração continuam pendentes.

Data local: 14/11/2026. Último snapshot de catálogo: 15/11/2026 01:58:31 UTC
(14/11/2026 22:58:31 em São Paulo).

## Veredito

**BLOQUEADO para solicitar instalação neste momento.**

A inspeção real confirmou compatibilidade estrutural e integridade dos dados
atuais para o SQL 10. As quatro RPCs de adoção estão ausentes, explicando a
mensagem do Flutter. O ciclo de adoção passou novamente no Supabase local.

Ainda é necessário obter um backup atual e recuperável, com procedimento de
restauração conferido, e revisar três falhas de integração encontradas. Nenhuma
correção de produção, instalação do SQL 10, alteração de credenciais, commit,
push ou deploy foi executada. O SQL 10 original permanece inalterado.

## 1. Inspeção de produção

**Resultado: APROVADA quanto à compatibilidade estrutural, com ressalvas abaixo.**
Não representa aprovação de funcionamento ponta a ponta ou autorização de instalação.

Projeto inspecionado: `cyaxnaflvnjnpryryorr`.

O CLI 3.1.0 já disponível em cache utilizou uma sessão Management existente.
As consultas foram enviadas com `db query --remote=<ref> --read-only`.
O servidor confirmou `current_user=supabase_read_only_user` e
`transaction_read_only=on`. Esse papel possui BYPASSRLS para inspeção; não foi
usado como sessão de aplicativo nem para modificar dados. O caminho do CLI foi
revisado: usa Management Query com `read_only:true`, sem criar login PostgreSQL.

O SQL 00 foi lido integralmente antes da execução: contém 12 SELECTs de catálogo,
sem DDL, DML ou RPCs de negócio. Foi executado com a proteção read-only. Como
a resposta do CLI para múltiplas instruções não reúne todos os resultados,
o novo SQL 01 agrega as 12 consultas e as auditorias complementares em um SELECT.
O SQL 01 foi validado no PostgreSQL local e depois executado na produção,
também em modo read-only. As verificações adicionais de sequência, funções e
questionário foram exclusivamente SELECTs.

| Item | Evidência real | Resultado |
| --- | --- | --- |
| Tabelas | `cliente`, `animal`, `adocao`; proprietário `postgres`; RLS ativada nas três | PASSOU |
| Colunas exigidas pelo SQL 10 | Presentes; IDs integer, `auth_user_id` uuid, `ativo` boolean | PASSOU |
| `adocao.id` | PK integer, identity BY DEFAULT | PASSOU |
| Sequência de adoção | `adocao_id_seq`: `last_value=31`, `is_called=false`; maior ID existente 30 | PASSOU; próximo valor previsto 31, sem consumir a sequência |
| Data/status | `timestamp without time zone`; status varchar(50), sem CHECK/ENUM conflitante | PASSOU |
| FKs | Quatro vínculos exigidos validados; ações NO ACTION; sem órfãos | PASSOU |
| Estados/dados existentes | Duas adoções, ambas Aguardando | COMPATÍVEL |
| Duplicidades e integridade | Zero grupos ativos duplicados, aceites duplicados, órfãos, campos incompatíveis ou inconsistências Aceito/animal | PASSOU |
| Vínculo Auth | Zero vínculos órfãos ou perfis duplicados por Auth; quatro perfis ativos vinculados | PASSOU |
| Adoções antigas | As duas têm algum participante sem vínculo Auth | RESSALVA; preservar, sem operações por esses participantes até regularização |
| Animais | 11 linhas ativas/Disponível; nove com responsável sem Auth; uma com responsável inativo, possivelmente sobreposta ao grupo anterior | RESSALVA; RLS exclui responsável inativo da leitura pública |
| Objetos do SQL 10 | Quatro RPCs, três helpers, dois índices parciais e trigger de status ainda ausentes | INSTALAÇÃO PENDENTE |
| Acesso direto a `adocao` | anon/authenticated sem SELECT/INSERT/UPDATE/DELETE e sem UPDATE de coluna | PROTEGIDO ATUALMENTE |
| Permissões animal/perfil | Grants por coluna; atualização de status/proprietário não concedida ao aplicativo | COMPATÍVEL com SQL 10 |
| Triggers públicos das três tabelas | Nenhum antes da instalação | SEM COLISÃO |
| Cadastro | Trigger existente em `auth.users` chama `private.criar_cliente_entre_patas()` | PRESENTE; não será substituído pelo SQL 10 |
| Questionário | RLS, policies próprias e índice único em `id_cliente`; nenhuma duplicidade por cliente | PRESENTE; permite o contrato de upsert atual |

`information_schema.table_privileges/column_privileges` retornou vazio sob o
papel de inspeção. Isso **não foi interpretado como ausência de grants**:
foram conferidos `has_table_privilege`, `has_any_column_privilege` e
`has_column_privilege`, que mostraram as permissões efetivas.

`pg_sequences.last_value` retornou nulo porque a sequência ainda está com
`is_called=false`; a leitura direta confirmou o estado acima. Não foi executado
`nextval`, `setval` nem qualquer ajuste de sequência.

O GET público de Auth Settings retornou 200. O catálogo OpenAPI anônimo
retornou 401; isso não foi tratado como chave inválida ou ausência de tabelas.
A inspeção foi concluída pelo canal Management somente leitura.

## 2. Backups

Os arquivos continuam em `EntrePatas-Backups`, no diretório pessoal, **fora do
repositório**. Foram lidos somente em memória para conferir UTF-8, estrutura,
terminadores COPY, tamanho, data e SHA-256. Nenhum conteúdo de registro, senha,
token ou dump foi copiado para a documentação ou para arquivos versionáveis.

| Arquivo externo | Tamanho | Modificação UTC | Constatação |
| --- | ---: | --- | --- |
| `schema.sql` | 24.165 bytes | 14/11 19:38 | Cinco CREATE TABLE, nove funções e dez policies; legível |
| `data.sql` | 44.507 bytes | 14/11 19:41 | 40 blocos COPY completos; já inclui Auth, public e metadados Storage |
| `auth-data.sql` | 35.995 bytes | 14/11 21:21 | 26 blocos COPY completos, incluindo users/identities |
| `roles.sql` | 297 bytes | 14/11 21:53 | Complemento de papéis; legível |
| `auth-trigger.sql` | 141 bytes | 14/11 22:02 | Complemento do trigger de cadastro; legível |
| `public-data.sql` | 6.617 bytes | 14/11 22:19 | Cinco blocos COPY completos |
| `public-data-pre-producao.sql` | 6.617 bytes | 15/11 00:04 | Cinco blocos COPY completos; export público mais recente encontrado |

Os exports públicos têm dez animais; a inspeção atual tem onze. Os componentes
têm horários diferentes e não constituem um novo snapshot coordenado. Não
aplicar `data.sql` e `auth-data.sql` indiscriminadamente na mesma restauração,
pois o primeiro já contém dados Auth. Dumps SQL também não comprovam cópia dos
arquivos binários de Storage nem das configurações/secrets externos do projeto.

A restauração do conjunto atual **não foi repetida nesta rodada**. O ambiente
local restaurado anterior foi usado para testes, mas isso não prova uma
restauração atual do conjunto completo acima.

A listagem oficial de backups foi consultada apenas por GET, via
`backups list --remote=<ref>`. Retornou `walg_enabled=true`, `pitr_enabled=false`
e zero backups listados, sem dados de backup físico. Portanto não foi confirmado
um ponto oficial recuperável/PITR disponível.

**É necessário um novo backup imediatamente antes da instalação**, usando
conexão PostgreSQL já autorizada e procedimento de restauração validado, ou
confirmação de um backup oficial recuperável. Sem uma credencial PostgreSQL
preexistente disponível, não foi executado novo dump: o código do CLI 3.1.0
mostra que `db dump --remote` e até `--dry-run` podem criar um login temporário
privilegiado quando a senha está ausente. Isso contrariaria a restrição de não
alterar credenciais. Não foi tentado contornar esse requisito.

## 3. Revisão do SQL 10

Arquivo definitivo revisado: `docs/sql/10_migrar_adocoes_supabase.sql`.

SHA-256:
`D2FF08F94169B92727FF807DFA25A45AE99B7E3C9C1A73B926CAB7DEE2E176A8`.

### Objetos e permissões que serão alterados

- Dois índices únicos parciais: `ep_adocao_em_andamento_unica`
  (animal/adotante em Aguardando ou Aceito) e `ep_adocao_aceita_unica`
  (um aceite por animal).
- Quatro RPCs SECURITY DEFINER: `listar_minhas_adocoes()`,
  `buscar_minha_adocao(bigint)`, `solicitar_adocao(bigint)` e
  `responder_adocao(bigint,text)`.
- Três funções SECURITY INVOKER: `_ep_adocao_cliente_atual()`,
  `_ep_adocoes_json(bigint,bigint)` e `_ep_proteger_status_adocao_animal()`.
- Trigger `ep_proteger_status_adocao_animal` em INSERT/UPDATE de status do animal.
- RLS habilitada em `adocao`; revogação de privilégios diretos de tabela/colunas
  de PUBLIC/anon/authenticated; execução somente das quatro RPCs a authenticated.
- NOTIFY para atualização do cache PostgREST.

Não cria tabelas ou policies de acesso direto a adoções, não desativa RLS,
não altera cadastro/algoritmo/questionário e não modifica registros durante a
instalação. Os INSERT/UPDATE dentro das funções só ocorrem quando as respectivas
RPCs forem chamadas após uma instalação aprovada.

### Proteções verificadas

- Identidade obtida de `auth.uid()` e perfil ativo, sem confiar em IDs de dono,
  adotante ou status fornecidos pelo Flutter.
- `search_path=''`, referências qualificadas e helpers sem EXECUTE dos clientes.
  Objetos homônimos do SQL 10 não existem atualmente; não há proprietário/ACL
  antigo a preservar inadvertidamente nesta primeira instalação.
- Consulta individual/lista limitada aos participantes; anônimo sem EXECUTE.
- Bloqueio de autossolicitação, duplicidade e nova decisão de pedido finalizado.
- Todas as transições travam primeiro o animal; depois a adoção quando necessário.
  Aprovação atualiza o animal e recusa as outras pendências na mesma transação.
- Índices reforçam a unicidade e testes REST paralelos confirmaram um único aceite.
- Proteção de status usa o papel efetivo no PATCH direto; não aceita marcador
  de usuário ou GUC falsificável para autorizar a mudança.

### Riscos e cuidados

- `BEGIN/COMMIT` envolve preflights, índices, funções e grants: erro aborta a
  transação. A instalação deve parar no primeiro erro e confirmar rollback.
- Locks SHARE ROW EXCLUSIVE em cliente → animal → adocao e criação de índices
  sem CONCURRENTLY bloqueiam gravações. Usar janela de manutenção, sem tráfego
  de publicação/cadastro/adoção e com limites de espera definidos na sessão.
- O SQL não é reaplicável cegamente: índices e trigger já existentes bloqueiam
  a repetição. Se a conexão cair, consultar o catálogo antes de tentar novamente.
- O preflight não cobre sozinho CHECKs, limites varchar, todas as funções
  privilegiadas e efeitos de triggers. Esses pontos foram inspecionados no
  snapshot atual; repetir a leitura imediatamente antes da janela.
- Os dados legados sem Auth permanecem. Solicitar animal de responsável sem
  conta vinculada não fará esse responsável receber uma sessão capaz de aprovar.
  Regularização é atividade separada, sem apagar ou vincular contas por suposição.
- Outros papéis privilegiados e funções administrativas permanecem fora da
  proteção específica do trigger para anon/authenticated. Não expor credenciais
  administrativas no aplicativo.
- Em comparação ao PHP, o SQL exige status exatamente Disponível e impede
  decisões por antigo responsável após transferência. O Flutter atual usa
  Disponível e não concede edição de proprietário.

## 4. Testes locais executados novamente

Nenhum teste funcional com gravação foi feito em produção. O servidor local
usado foi exclusivamente `supabase_db_EntrePatas-Restore-Test`, API
`http://127.0.0.1:54321`. O transporte dos runners rejeita outros destinos.

| Bateria | Passaram | Falharam | Escopo/evidência |
| --- | ---: | ---: | --- |
| Flutter adoção: serviço, controller e widgets | 39 | 0 | `.dart_tool/sql10_revisao_flutter.log`; mocks SDK/UI |
| SQLs 05/10/20 em PGlite | 31 | 0 | `.dart_tool/sql10_revisao_pglite.log`; memória, sem rede |
| REST Supabase local | 27 | 0 | `.dart_tool/sql10_revisao_rest_results.json` |
| SDK/controller/Home contra API local | 9 | 0 | `.dart_tool/sql10_revisao_sdk.log` |
| Impactos com definições reais de perfil e contrato de grants | 4 | 3 | `.dart_tool/sql10_revisao_impacto_perfil_resultados.json` |
| **Total desta rodada** | **110** | **3** | Nenhum caso ignorado nas baterias acima |

O ciclo REST verificou publicar → solicitar → dono consultar → cancelar/recusar/
reenviar/aprovar → adotante consultar resposta, status do animal e notificações.
Também verificou duplicidade, terceiro/anônimo bloqueados, tentativa de decisão
indevida, alteração direta de status negada, pedido finalizado e animal adotado.
Duas aprovações simultâneas retornaram 200/409 e estados Aceito/Recusado.

Foram criados apenas dados fictícios novos no local: perfis 93/94/95; animais
40 e 42 no REST e 41 no SDK; pedidos 46 a 51. Nenhum original foi apagado,
nenhuma limpeza de fixtures foi executada e o SQL 10 não foi reaplicado.

### As três falhas encontradas

1. **P1 — resumo do responsável após aprovação:** as definições reais da produção,
   reproduzidas sem alterações em PGlite com dados fictícios, retornam uma linha
   antes e zero após o único animal disponível passar a Adotado. A expectativa
   de continuar exibindo o responsável falhou.
2. **P1 — perfil do responsável após aprovação:** o mesmo teste encontrou zero
   linhas no perfil para o adotante. O responsável continua vendo o próprio
   resumo/perfil; controles passaram. É integração com helpers já existentes,
   não falha das quatro RPCs de adoção.
3. **P1 — exclusão lógica de animal:** `excluirMeuAnimalSupabase()` atualiza
   `ativo=false` e `imagem=null`, mas authenticated não possui UPDATE em
   `animal.ativo`. Falhou a conferência do contrato código/permissões. Não foi
   tentada exclusão ou atualização de um animal real em produção.

Correções mínimas para revisão separada: permitir que participantes consultem
o resumo/perfil necessário ao histórico de sua adoção, preservando a projeção
sem contatos privados; e avaliar concessão apenas da coluna `animal.ativo` ao
fluxo de soft delete, mantendo a RLS e o bloqueio de proprietário/status.
Não substituir por leitura pública irrestrita nem exclusão física para contornar
o problema. Nenhuma dessas correções foi aplicada.

## 5. Flutter e dependências

| Operação | Chamada/contrato | Situação |
| --- | --- | --- |
| Lista/notificações | `listar_minhas_adocoes()`, array JSON | Correta; RPC ausente na produção |
| Pedido individual | `buscar_minha_adocao(p_adocao_id)`, objeto JSON | Correta; RPC ausente |
| Solicitar | `solicitar_adocao(p_animal_id)` | Correta; IDs das partes determinados no SQL |
| Aceitar/recusar/cancelar | `responder_adocao(p_adocao_id,p_acao)` | Ações coincidem exatamente com SQL 10 |
| DTO | IDs, data, status, informações do animal/localização e solicitante | Compatível; idade nula tratada |
| Erro de instalação | PGRST202/42883/PGRST205/42P01 | Mensagem de configuração pendente; sem fallback PHP |
| Sessões | Respostas antigas descartadas após troca de usuário/token | Coberto pelos testes focados |

Notificações usam a listagem de adoções, refresh e retorno da decisão. Não são
push/realtime e não precisam de uma tabela adicional instalada pelo SQL 10.

### Antes do SQL 10

- Auth, perfil vinculado/ativo e trigger de cadastro: presentes no catálogo.
- RLS de cliente/animal, PK/FKs, tipos e sequência: conferidos e compatíveis.
- Questionário: tabela/RLS/upsert suportados pelo índice único atual.
- Backup atual/restaurável e janela de manutenção: **pendentes**.
- Para teste com a equipe, usar três contas próprias e animal cujo responsável
  tenha Auth vinculado; não usar um responsável legado sem acesso.

### Depois do SQL 10 e revisões independentes

- As quatro RPCs passarão a viabilizar adoções/notificações; instalação e testes
  autenticados de destino ainda exigem autorização explícita.
- Perfil/resumo/pesquisa já existem na produção. As versões de perfil/resumo
  recebem **integer**, não bigint; possuem EXECUTE e USAGE de schema private
  para authenticated. Não foram chamadas para coletar dados reais nesta auditoria.
- `ep_animais_perto_de_mim()` existe no online e filtra pelo perfil autenticado;
  a ausência de sua definição no repositório é uma lacuna de reprodução do
  backend, não prova de função ausente na produção.
- SQL 05: a sincronização `ep_sincronizar_email_auth()` não está instalada; não é
  requisito das quatro RPCs 10. Preservar o trigger de cadastro já existente.
- SQL 20: funções `ep_anonimizar_conta_auth()`/`ep_conta_exclusao_pronta()` ausentes.
  A instalação/configuração da Edge Function de exclusão não foi certificada
  nesta rodada. SQL 10 sozinho não habilita exclusão de conta.
- SQL 20 adquire locks de cliente/pedidos antes do animal em caminhos diferentes
  do SQL 10. Há risco de deadlock em exclusão de conta concorrente à adoção;
  é um achado de revisão a reproduzir antes da instalação separada do SQL 20.
- Callbacks Auth/domínio definitivo/e-mails não foram alterados nem testados
  ponta a ponta nesta auditoria.

**Não aplicar o SQL 30 original automaticamente.** A função existente
`buscar_clientes_publicos(text)` retorna `id integer`; o SQL 30 tenta alterar
esse retorno para bigint com CREATE OR REPLACE, o que pode abortar com 42P13.
As novas versões bigint de perfil/resumo também criariam overloads com os
mesmos parâmetros, com risco de PGRST203. Além disso, o SQL 30 passa a divulgar
contatos/endereço de lares, enquanto a produção os mascara. Exige revisão de
compatibilidade e privacidade separada; não é necessário aplicar SQL 30 para
resolver a ausência das quatro RPCs do SQL 10.

## 6. Plano condicionado de instalação e recuperação

Este plano não autoriza execução. **Nenhuma etapa de escrita abaixo foi realizada.**

1. Resolver/revisar os três achados de integração, preservando layout e
   privacidade. Documentar quais são pré-requisitos da entrega completa.
2. Obter backup atual e coordenado de estrutura/dados/Auth/grants/triggers,
   fora do repositório; conferir hashes e restaurar em ambiente isolado.
   Não criar papel temporário nem resetar senha sob a autorização somente leitura.
3. Reexecutar SQL 00/01 read-only imediatamente antes da janela. Confirmar tipos,
   sequência, ausência de novos objetos/duplicidades e dados legados conhecidos.
4. Registrar os grants/índices/triggers/funções anteriores em armazenamento
   privado e definir responsáveis, janela, limites de espera e critério de abortar.
5. Apresentar evidências resolvidas e **solicitar autorização explícita do usuário**.
   Somente depois, pausar gravações do app durante a janela e executar o arquivo
   original SQL 10, com o hash acima, como administrador autorizado. Nunca usar
   versão copiada de conversa, db push/reset ou credencial administrativa no Flutter.
6. Confirmar COMMIT e revisar catálogo: duas unicidades, sete funções, proprietário
   adequado, search_path vazio, quatro EXECUTEs authenticated, helpers privados,
   nenhum acesso direto à adoção, RLS mantida e trigger de status instalado.
7. Com autorização para testes de escrita no destino, usar duas contas de teste
   vinculadas e um animal fictício novo. Publicar com A, solicitar com B,
   visualizar com A, recusar, reenviar, aceitar e conferir resposta/status/avisos.
   Repetir cancelamento, duplicidade, pedido próprio, acesso de terceiro/anônimo
   e duas aprovações concorrentes usando outra fixture independente.
8. Conferir resumo/perfil após a aprovação, Home, pesquisa, questionário e logout;
   nenhum dado da outra conta pode permanecer na sessão. Não limpar dados reais
   ou fixtures sem instrução separada.

Critérios objetivos: backup restaurável confirmado; inspeção sem incompatibilidade;
instalação confirmada uma única vez; ACL/RLS esperadas; cada fluxo positivo e
negativo acima aprovado; nenhum efeito colateral de perfil/CRUD; zero vazamento
de dados para terceiros; evidências salvas sem credenciais.

Se ocorrer erro **antes do COMMIT**, interromper e confirmar ROLLBACK; não
reaplicar cegamente. Se ocorrer falha **depois do COMMIT**, suspender novos
pedidos e preservar os dados/evidências. Não remover índices, abrir grants ou
executar um rollback genérico que descarte solicitações novas. Preparar reversão
específica dos objetos/ACLs, ou restauração aprovada a partir do backup validado,
considerando os dados criados após a instalação. A recuperação também requer
autorização e validação em ambiente isolado.

## 7. Arquivos alterados e evidências

Arquivos versionáveis alterados/criados nesta rodada:

- `docs/sql/01_validar_sql10_somente_leitura.sql` — novo SELECT de inspeção;
  complementa SQL 00 com integridade, privilégios efetivos e dependências.
- `docs/revisao_sql10_producao.md` — este relatório e plano condicionado.
- `docs/adocoes_supabase.md` — link para o resultado atual da auditoria.

Nenhum arquivo Flutter, credencial, configuração de produção ou SQL 10 foi alterado.
Os demais diffs do workspace antecedem esta tarefa e não foram revertidos.

Artefatos locais ignorados: `sql10_producao_catalogo.json`,
`sql10_producao_sql00.json`, `sql10_producao_privilegios_sequencia.json`,
`sql10_producao_funcoes_detalhes.json`, `sql10_producao_questionario.json`,
`sql10_backups_oficiais.json`, `sql10_backup_inventory.json`,
`sql10_revisao_*` e `sql10_local_catalogo.json`, todos em `.dart_tool/`.
Contêm metadados/contagens ou testes fictícios; não incluem dumps de registros
ou credenciais. Os backups originais continuam exclusivamente na pasta externa.

Os relatórios anteriores permanecem como histórico: [QA local](qa_entrepatas_local_2026-11-14.md),
[correções Web](qa_entrepatas_correcao_web_2026-11-14.md) e
[preparação do repositório](preparacao_producao.md). Suas contagens não foram
somadas a esta execução. `git diff --check` passou (exit 0); os três arquivos
desta rodada também foram conferidos quanto a espaços no fim das linhas.
