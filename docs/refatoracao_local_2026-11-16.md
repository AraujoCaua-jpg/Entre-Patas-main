# Entre Patas — refatoração local e organização

Data: 16/11/2026. Branch: `main`. Nenhum commit, push, pull, merge, rebase,
deploy, SQL remoto, alteração RLS ou gravação em dados reais foi executado.

## Estado inicial e preservação

O trabalho começou com as alterações da auditoria anterior ainda no workspace,
incluindo mudanças em README, telas e testes, o relatório de auditoria e o
serviço Storage local não rastreado. Nenhuma dessas alterações foi descartada.
O usuário confirmou que somente o README estava reservado aos colegas.

O README **não foi modificado nesta refatoração**, embora já aparecesse como
modificado no Git. SHA-256 registrado no início e conferido na retomada:
`F20B45DC90E773FE91238234053C39B9D0A608CEA764C5CBDA8A9407B3E8500B`.

Após a interrupção apareceram 19 documentos Markdown rastreados como excluídos
em `docs/`, além de `.claude/` e `CLAUDE.md` não rastreados. O relatório não
rastreado da auditoria anterior também deixou de existir. Essas mudanças não
foram executadas por esta refatoração, nem restauradas automaticamente. Os SQLs
históricos continuam presentes. O presente arquivo é um relatório novo.

## A. Arquitetura: antes e depois

Mantida a arquitetura Flutter existente, sem Provider, Riverpod ou Bloc.

| Área | Uso e dependências | Decisão |
|---|---|---|
| `lib/main.dart` | Inicializa Supabase, scope, tema e recuperação de senha; abre boas-vindas | Removido desvio morto `logado = false` e import de navegação usado só nesse desvio. A tela inicial é a mesma. |
| `lib/view/` | Telas e componentes; chamam controller e serviços Auth; navegação entre telas | Preservada a estrutura e o visual. Pesquisa recebeu paginação. Formulários reutilizam validações e UFs. |
| `lib/controller/` | `ClienteController` com `ChangeNotifier`, `ClientesScope` com `InheritedNotifier`, navegação local | Consulta e mapeamento duplicados do perfil foram retirados do controller. Polling só notifica mudanças efetivas. |
| `lib/model/` | Cliente, Animal e Adocao; sem dependência da UI | Nova constante `estadosBrasil`, compartilhada por cadastro, edição e validação. |
| `lib/services/` | Auth, PostgREST/RPC, regras e URLs de fotos | Validação extraída para `validacao_perfil.dart`; filtragem local da proximidade em `filtros_animais.dart`. Interfaces públicas existentes mantidas. |
| `lib/service/` | Validação de senha ativa e clientes PHP legados | Preservado: senha é usada em runtime; wrappers têm testes, exportações e dependências entre si. |
| `lib/main_preview_comp.dart` | Entrypoint alternativo da prévia do questionário | Preservado; entrypoints não precisam ser importados pelo app principal. |
| `test/` | Testes Flutter, mocks HTTP, contratos SQL em PGlite e PHP legado | Preservados; acrescentadas regressões de comportamento. |
| `assets/` | Logo, animais de boas-vindas, foto do banner de pesquisa, banners da Home e NunitoSans | Preservados todos os arquivos e as declarações no manifest. |
| `scripts/` e `config/` | Build Vercel com SDK fixado, configuração pública e backup somente leitura | Preservados; arquivos não importados pelo Dart podem ser necessários ao build e à operação. |
| `supabase/` e `docs/sql/` | Configuração, Edge Function de exclusão e contratos/migrações históricos | Preservados integralmente. Nenhuma execução remota. |

Fluxo principal de dependências: telas → controller → serviços → SDK Supabase;
modelos são compartilhados pelas camadas. `ClientesScope` observa o controller
acima do Navigator. A recuperação de senha precisa observar eventos Auth na
camada de navegação; esse uso foi mantido. Não foram introduzidos ciclos entre
os novos módulos de dados, validação e persistência.

Antes, o controller consultava a tabela `cliente` e construía manualmente o
modelo no login, enquanto o serviço tinha outra implementação para recarregar o
perfil. Agora ambos usam `buscarMeuPerfilSupabase`, que mantém os filtros Auth e
ativo, traduz erros PostgREST e resolve foto por URL. A verificação da versão da
sessão no controller continua bloqueando respostas iniciadas antes do logout.

O serviço ainda é grande e contém vários domínios. A extração foi limitada às
responsabilidades com separação clara e verificável; não houve divisão massiva
em repositórios ou alteração dos construtores públicos.

## B. Limpeza

| Categoria | Resultado desta refatoração |
|---|---|
| Arquivos excluídos pelo trabalho | Nenhum. As 19 exclusões de documentos observadas na retomada pertencem ao estado externo desta sessão. |
| Classes removidas | Nenhuma; as classes públicas e wrappers foram preservados. |
| Funções removidas | `_validarPerfil` foi extraída do serviço para `validarPerfil`; o comportamento foi preservado. Não foram removidos métodos públicos do controller. |
| Código morto | Removidos `logado = false` e seu ternário inatingível em `main.dart`; removido ramo da categoria “Outros” da UI de pesquisa, que já não possuía opção selecionável. O suporte “Outros” no serviço público continua disponível. |
| Imports removidos | Import da navegação em `main.dart`, que só atendia o ramo morto. Removido import comentado de tela inexistente na recuperação de senha. |
| Dependência removida | `image_picker`: nenhuma chamada a ImagePicker/XFile/import do pacote em código, testes ou scripts. Fotos atuais usam URL; o legado usa bytes próprios, sem esse pacote. |
| Lockfile | `flutter pub get` removeu o pacote direto e 13 pacotes transitivos que deixaram de ser necessários, sem atualizar as versões dos pacotes mantidos. |
| Duplicações eliminadas | Consulta/mapeamento de perfil no controller, três listas de UFs e regex repetidas de e-mail/usuário/telefone nos formulários e serviço. |
| Widgets | Reutilizados os componentes existentes. Não foi criada uma nova abstração visual apenas para reorganizar arquivos. |

Dependências mantidas: `http` é usado nos wrappers e mocks; `material_ui` compõe
as telas; `supabase_flutter` atende ao runtime; `flutter_test` e `flutter_lints`
atendem à validação. Não houve atualização de SDK ou alteração de credenciais.

Arquivos preservados e candidatos a uma decisão futura da equipe:

- `lib/services/foto_perfil_storage_service.dart`: local e sem chamadas no fluxo
  atual. Pode conter trabalho em andamento; não foi removido nem integrado.
- `lib/service/animais_api.dart`: wrapper sem chamadas identificadas no fluxo
  ativo, mas parte da superfície de compatibilidade PHP preservada.
- `lib/main_preview_comp.dart`: ponto de entrada alternativo, utilidade distinta
  do aplicativo de produção.
- `assets/banners/boas_vindas.png` e `boas_vindas_hd.png`: a Home usa a variante
  corrigida, mas o diretório inteiro é declarado em `pubspec.yaml`; a equipe
  pode manter os originais como material visual.
- Métodos públicos locais `editarCliente` e `excluirCliente`: não têm chamadas
  identificadas no fluxo ativo. Permanecem para respeitar a interface pública.

Não há comprovação suficiente para excluir esses itens por preferência de
limpeza. Qualquer remoção dos candidatos exige autorização específica antes
de ser executada. Backend PHP, wrappers, `fotoCadastro`, SQLs e assets não foram
apagados. `fotoCadastro` ainda participa dos testes de compatibilidade PHP.

## C. Qualidade e comportamento

### Pesquisa e proximidade

Antes, o ramo `ep_animais_perto_de_mim` retornava imediatamente e ignorava
nome, espécie, sexo, porte e outros filtros. Agora `filtrarAnimaisProximos`
aplica esses filtros ao conjunto retornado pelo servidor. A RPC continua
responsável pela localização e autorização; nenhum parâmetro, SQL ou permissão
remota foi alterado.

A consulta paginada próxima divide o resultado filtrado em páginas de 50.
`buscarAnimaisModel` consulta a RPC uma única vez quando pede o conjunto completo;
antes poderia repetir o mesmo conjunto de 50 ou mais animais até atingir o limite
de segurança de 1.000 páginas. Na consulta comum, ID desempata a ordenação por
nome para estabilizar as páginas; a direção padrão já usada pelo SDK foi mantida.

A UI oferece “Carregar mais”, acrescenta a próxima página e conserva a lista se
a rede falhar nessa etapa. A repetição tenta a mesma página. Troca de filtros
retorna à primeira página; respostas de consultas antigas continuam invalidadas
por versão. Cliques na categoria já selecionada não refazem a pesquisa. O estado
local dos filtros continua no `IndexedStack` existente ao trocar de aba.

Limites: a paginação por offset ainda pode mudar sob inserções/exclusões remotas.
A busca próxima pagina localmente o conjunto que a RPC realmente devolve; se o
servidor limitar esse conjunto, obter dados além do limite exige contrato SQL
paginado e revisão própria. Cada página próxima solicitada pela UI ainda pode
refazer a RPC; não foi introduzido cache duradouro que arrisque dados de outra
sessão ou resultados desatualizados.

### Notificações

Antes, todo polling chamava `notifyListeners`, mesmo com resultado idêntico,
provocando novas consultas nas telas dependentes. Agora a comparação considera
IDs, participantes, data, status e campos do DTO antes de notificar. Alterações
reais continuam atualizando a UI. Marcar a mesma versão de uma notificação como
lida tornou-se idempotente. O polling de 15 segundos, histórico, proteções contra
respostas antigas e separação entre badge e lista foram preservados.

A leitura continua em memória por sessão, pois persistência exigiria contrato
de backend. Dados aninhados novos no DTO podem causar rebuilds adicionais, pois
a comparação do mapa é superficial; isso não suprime mudanças do payload atual.

### Validações, perfil e compatibilidade

`validacao_perfil.dart` reúne as regras de perfil e funções usadas no login,
recuperação, cadastro e edição. Telefone com DDD aceita 10 ou 11 dígitos, como
já exigido pelo serviço, em vez de a UI verificar apenas o limite mínimo. As
mensagens existentes foram mantidas.

`estadosBrasil` é a fonte das 27 UFs para os dois dropdowns e a validação. O
perfil usa a URL válida do banco e, na ausência dela, a URL dos metadados Auth;
isso agora também ocorre no login. Não há upload Storage no fluxo ativo.

O questionário obrigatório, upsert por cliente e reuso das respostas salvas
foram preservados. O cálculo 50/30/20 e a ordenação da Home não foram alterados.
As respostas são persistidas; os percentuais são derivados delas ao consultar
os animais. Não foi criado um novo snapshot de pontuação no banco. Uma exigência
de armazenar percentuais históricos, além das respostas, precisa de decisão de
produto e contrato de dados separado.

Não houve novo cache de questionário nem redução de consultas que pudesse
ocultar respostas atualizadas. O descarte de controllers, listeners e timers
existentes foi mantido. A pesquisa continua verificando `mounted` e a versão da
consulta após operações assíncronas. Não houve revisão extensa dos controles
Radio deprecated para evitar alterar a seleção de dezenas de campos nesta tarefa.

### Erros e estados

Login e recarga do perfil passam pelo mesmo tratamento de erros. A busca de
proximidade passou a reutilizar a tradução de erro RPC e valida o formato da
resposta antes da filtragem. A paginação mostra falha sem apagar a lista anterior.
Persistem mensagens genéricas em alguns métodos de animais/questionário; não
foram substituídos contratos de erro em massa. Os estados vazios existentes
de pesquisa e notificações foram mantidos.

## Arquivos desta refatoração

Novos módulos:

- `lib/model/estados_brasil.dart`.
- `lib/services/validacao_perfil.dart`.
- `lib/services/filtros_animais.dart`.

Arquivos ativos alterados:

- `lib/controller/cliente_controller.dart`.
- `lib/services/supabase_service.dart`.
- `lib/main.dart`.
- `lib/view/principal/pesquisa.dart`.
- `lib/view/autenticacao/login.dart`, `esqueciSenha.dart`.
- `lib/view/autenticacao/cadastro/cadastroUsuario.dart`, `cadastroUsuario3.dart`,
  `cadastroUsuario4.dart`.
- `lib/view/usuario/editarPerfil.dart`.
- `pubspec.yaml` e `pubspec.lock`.

Testes novos:

- `test/notificacoes_estado_test.dart`: polling igual/vazio, mudanças reais,
  leitura repetida e resposta posterior ao logout.
- `test/pesquisa_proximidade_service_test.dart`: filtros combinados, paginação,
  uma RPC para consulta completa, desempate, erro e ordenação comum.
- `test/pesquisa_paginacao_test.dart`: anexar página, repetir após erro e descartar
  resposta antiga ao trocar de espécie.
- `test/validacao_perfil_test.dart`: regras compartilhadas e limites de perfil.

`test/conta_supabase_migration_test.dart` ganhou dois cenários de foto por URL no
login/recarga. Isso totaliza **19 novos testes** nesta refatoração. Os arquivos
da auditoria anterior continuam no diff do workspace; não devem ser atribuídos
novamente a este trabalho. `test/pesquisa_layout_test.dart` apresenta uma troca
equivalente para sintaxe null-aware no estado final da sessão; foi preservada.

## D. Validação antes e depois

| Verificação | Antes da refatoração | Depois |
|---|---|---|
| `flutter pub get` | Sucesso | Sucesso; lockfile sem image_picker e dependências exclusivas dele. |
| `flutter analyze --no-fatal-infos` | Exit 0; 111 infos, 0 warnings, 0 erros | Exit 0; 110 infos, 0 warnings, 0 erros. |
| `flutter test --reporter expanded` | 273 aprovados, 2 ignorados, 0 falhas | **292 aprovados, 2 ignorados, 0 falhas**. |
| `node --test test/*.mjs` | 79 aprovados, 0 falhas | **79 aprovados, 0 falhas**. |
| `flutter build web --release --dart-define-from-file=config/production.json` | Release aprovado | **Release aprovado**, exit 0, gerado em `build/web`; compilação em 91,2 segundos. |
| Formatação | Estado anterior preservado como base | `dart format --output=none --set-exit-if-changed lib test`: exit 0; 92 arquivos, 0 mudanças. |
| `git diff --check` | Sem erro | Sem erro; avisos LF/CRLF não são falhas de whitespace. |

Os dois testes ignorados dependem da funcionalidade de alteração de e-mail
desabilitada por flag. Não foram removidos nem marcados como aprovados.

Durante o desenvolvimento, a primeira rodada dos testes novos teve duas falhas:
uma expectativa assumia ordenação ascendente, enquanto o SDK instalado usa
`nome.desc.nullslast`; a outra tentava tocar no botão ainda coberto pelo SnackBar.
As expectativas foram corrigidas para o comportamento real, sem remover
assertivas de paginação, dados preservados ou isolamento. A segunda rodada
focada terminou com 14 aprovados; a suíte completa posterior passou.

Os testes SQL usam PostgreSQL em memória (PGlite), sem tocar Supabase remoto.
Os testes Flutter usam fixtures/mocks locais. O build não comprova fluxos reais
no domínio publicado, recebimento de e-mail, catálogo/RLS remoto ou concorrência
entre conexões. Android/iOS não foram compilados nesta sessão.

## E. Impacto acadêmico estimado

| Critério | Máximo | Antes | Depois estimado | Evidência e limite |
|---|---:|---:|---:|---|
| Arquitetura e organização | 10 | 8,5 | 9 | Perfil fora do controller, regras/UFs compartilhadas e filtragem separada; serviço principal ainda concentra vários domínios. |
| Qualidade Dart/Flutter | 9 | 7,5 | 8 | Dependência sem uso removida, menos duplicação, atualizações idempotentes e 19 regressões novas; depreciações e padronização parcial de erros permanecem. |
| Funcionalidade | 12 | 10,5 | 11 | Filtros próximos e páginas seguintes passam a funcionar de forma verificável; pendem contratos/fluxos remotos e limites do conjunto da RPC. |
| UI/UX | 9 | 8 | 8,5 | Carregar mais, preservar lista em erro e evitar rebuilds sem mudança; não houve revisão visual completa ou auditoria de acessibilidade. |

Estimativas técnicas, sem garantia da nota do professor. Os critérios de README
e versionamento e de complexidade/integrações não receberam novo crédito por
mudanças de documentação dos colegas ou integrações não verificadas.

## F. Pendências e revisão manual

- Conferir no navegador móvel/desktop a pesquisa com filtros próximos e mais
  de 50 animais, a manutenção dos filtros após abrir uma ficha e o retry de rede.
- Validar login, foto por URL, recuperação por e-mail real, primeiro questionário,
  logins posteriores, cadastro/edição/exclusão de animais e adoções com duas
  contas de demonstração autorizadas.
- Validar notificações em ambas as contas e confirmar atualização após mudança
  real sem recarregamento desnecessário no polling estável.
- Revisar com a equipe as 19 exclusões de documentos observadas na retomada:
  há links do README que apontam para esses documentos. Esta refatoração não
  os restaurou nem alterou o README para contornar as exclusões.
- Decidir separadamente sobre os candidatos de remoção preservados; nenhuma
  autorização de exclusão de arquivos incertos foi presumida.
- Melhorar paginação remota da RPC próxima e da lista de animais próprios em
  uma tarefa com revisão dos contratos. A lista própria ainda carrega o conjunto
  completo antes de paginar visualmente.
- Revisar APIs Radio deprecated, acessibilidade, limites de listas/imagens e
  fallback de erro de inicialização do SDK em tarefas próprias.

O projeto continua compilando e todos os testes locais executados passaram.
Está pronto para revisão manual, com as limitações remotas explicitadas acima.
O README manteve o mesmo hash ao final. Nenhuma publicação foi realizada;
commit, push e deploy continuam dependendo de autorização do usuário.
