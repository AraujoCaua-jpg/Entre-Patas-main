# Validação final do Flutter Web — 15/11/2026

## Veredito

O release Web de produção foi compilado e inicializou no Chrome com perfil
isolado. A suíte final aprovou 258 testes, sem falhas; dois testes de uma
funcionalidade de alteração de e-mail desabilitada foram ignorados pelas
condições já existentes. Não foram ignorados testes para esconder falhas.

O código e a configuração de publicação estão preparados. A validação completa
com usuários autenticados no Supabase real continua dependendo de login manual
e, para operações que gravam adoções, de autorização específica. Não houve
commit, push ou deploy nesta etapa.

## Resultados executados nesta rodada

| Verificação | Resultado | Evidência e limite |
| --- | --- | --- |
| flutter analyze | 0 erros, 0 avisos, 113 informações; exit 1 | O comando padrão trata as informações como falha. São nomes de arquivos, APIs depreciadas e sugestões de estilo; não foram silenciadas nem apresentadas como exit 0. |
| flutter test --reporter expanded | PASSOU: 258 aprovados, 0 falhas, 2 ignorados; exit 0 | Suíte completa com SDK e fixtures locais. Os dois ignorados dependem da alteração de e-mail habilitada. |
| Configuração de produção Node | PASSOU: 5/5; exit 0 | node --test test/production_build_config_test.mjs. Rejeita ambiente local, chave administrativa e SDK divergente. |
| flutter build web --release | PASSOU; exit 0 | Executado pelo script de produção, com --no-pub e --dart-define-from-file=.dart_tool/production-build.json. Artefato em build/web. |
| SDK e dependências | PASSOU | Flutter 3.50.0 na revisão fixada em config/toolchain.json; flutter pub get --enforce-lockfile. |
| Bundle de produção | PASSOU | Endpoint original e configuração pública conferidos pelo script; nenhum deploy. |
| Chrome headless, perfil novo | PASSOU | Flutter, canvas e semântica inicializados; tela de boas-vindas, Fazer Login e Criar Conta presentes. |
| Recursos HTTP locais do release | PASSOU: 6/6 | index.html, flutter_bootstrap.js, main.dart.js, manifest.json, logo e NunitoSans carregaram com HTTP 200. |
| Erros de runtime no smoke | PASSOU | Zero exceções JavaScript, erros de console ou recursos com falha registrados durante a inicialização. Não abrange telas autenticadas. |
| RPC listar_minhas_adocoes, API real, GET sem login | PASSOU para reconhecimento/proteção | HTTP 401, SQLSTATE 42501; função reconhecida e execução anônima negada. Não houve erro PGRST202. |
| RPC buscar_minha_adocao, API real, GET sem login | PASSOU para reconhecimento/proteção | HTTP 401, SQLSTATE 42501; sem leitura de solicitação de usuário e sem erro PGRST202. |
| Contratos Flutter/RPC | PASSOU na revisão e nos testes locais | Nomes, parâmetros, ações e respostas correspondem aos SQLs originais já instalados. Não equivale a executar operações de negócio em produção. |
| git diff --check | PASSOU; exit 0 | Sem problemas de whitespace no diff rastreado. Avisos anteriores LF/CRLF são informativos. |
| Arquivos sensíveis no Git atual | PASSOU no inventário desta rodada | Nenhum passfile, certificado, dump, chave administrativa ou URL PostgreSQL com senha encontrado entre candidatos rastreados/novos. Não certifica todo o histórico remoto. |
| Adoção autenticada real, decisões e cancelamento | PENDENTE de teste manual/autorização | Não foram usados usuários reais, contas fictícias ou RPCs de escrita no original. |
| Build remoto e domínio Vercel | NÃO EXECUTADO | A publicação permanece aguardando autorização; o build validado foi local. |

O script utilizado foi `node scripts/build_web.mjs`. Ele gera somente as duas
definições públicas do cliente, valida o SDK, respeita o lockfile e chama:

```text
flutter pub get --enforce-lockfile
flutter build web --release --no-pub --dart-define-from-file=.dart_tool/production-build.json
```

A sugestão de build Wasm e a existência de duas versões de pacotes mais novas
foram mensagens informativas. Nenhuma dependência foi atualizada para resolver
essas mensagens. Não houve alteração ampla de nomes de arquivo ou dos controles
Radio depreciados, para preservar o escopo e o visual na entrega.

## Problemas encontrados e corrigidos

1. **Perfil mantinha animais antigos após mudanças em outra tela.** A lista
   agora é consultada novamente quando o ClienteController notifica adoções,
   exclusões ou atualizações, inclusive com a tela preservada no IndexedStack.
   O teste de regressão verifica nova consulta, erro de carregamento e recuperação.
2. **Renovação normal do token invalidava RPCs já concluídas.** A comparação
   estrita do access token podia mostrar erro após uma operação legítima. Um
   guard de sessão compartilhado agora aceita tokenRefreshed em adoções,
   perfis públicos e exclusão lógica, mantendo o descarte de respostas após
   logout, troca de conta e novo login da mesma conta.
3. **Histórico dos eventos Auth precisava ser distinguido de mudanças novas.**
   A primeira versão do ajuste foi reprovada pela suíte e não foi entregue.
   O guard final aguarda a sessão atual no histórico do SDK, drena eventos e
   confere a sessão antes e depois da RPC, com espera limitada e cancelamento
   do observador. As regressões incluem renovação antes/durante a operação,
   histórico anterior, logout e novo login.
4. **Três fixtures de interface misturavam o relógio simulado com I/O do SDK.**
   Os testes de perfil público agora aguardam a leitura real simulada em runAsync
   antes de conferir a interface. A detecção nativa de links fica desativada
   somente nessa fixture, cujo objetivo não é testar o plugin de deep links.
   As validações de resposta, privacidade e erro da interface foram mantidas.
5. **Documentação e proteção do Git estavam incompletas.** README e checklist
   de publicação refletem as migrações já instaladas; .gitignore protege
   passfiles, certificados e exports adicionais.

As falhas das rodadas iniciais foram investigadas e corrigidas. O resultado
258/0/2 é da suíte completa executada depois dessas correções. Nenhum SQL,
política RLS, projeto Supabase ou dado real foi alterado nesta tarefa.

## Telas e integração revisadas

| Fluxo | Conferência |
| --- | --- |
| Quero Adotar | Busca individual do animal, questionário/compatibilidade, confirmação e solicitar_adocao com somente p_animal_id. |
| Minhas adoções / Notificações | A interface atual usa Notificações para listar os pedidos do usuário e abrir cada solicitação; leitura e atualização ao retornar foram revisadas. |
| Aceitar, recusar e cancelar | responder_adocao com p_adocao_id/p_acao; estados Aguardando, Aceito, Recusado e Cancelado e erros conhecidos cobertos nas fixtures. |
| Perfil | Atualização após notifyListeners e retorno das telas de animais; sessão ausente e falha de consulta tratadas. |
| Detalhes do animal | Consulta direta por ID, compatibilidade pelo mesmo serviço da Home e ausência de porcentagem nos próprios animais. |
| Login, questionário e logout | Suíte completa cobre primeiro acesso, progresso existente, recuperação e limpeza da conta anterior; não foi realizado login real automatizado. |

As quatro RPCs de adoção são listar_minhas_adocoes, buscar_minha_adocao,
solicitar_adocao e responder_adocao. As duas primeiras foram verificadas pela
API real exclusivamente com GET sem login. As duas últimas NÃO foram chamadas
em produção nesta rodada. Os erros de função ausente não apareceram nas duas
chamadas reais; a inexistência de erro em um fluxo autenticado completo ainda
precisa de confirmação pelo aplicativo. O mapeamento de erro permanece no
código para tratar indisponibilidade real, sem esconder falhas do servidor.

Os clientes PHP legados foram preservados. Os caminhos atuais dessas telas
usam o Supabase; nenhuma migração ou SQL foi executado novamente.

## Arquivos alterados nesta finalização

- lib/services/supabase_service.dart — proteção de sessão compartilhada nas RPCs.
- lib/view/principal/perfil.dart — recarga da lista por notificação do controller.
- test/adocao_supabase_service_test.dart — regressões de renovação/troca de sessão.
- test/perfil_publico_supabase_service_test.dart — mesmas regressões e I/O das fixtures de interface.
- test/exclusao_animal_supabase_test.dart — renovação e novo login durante exclusão.
- test/perfil_recarregar_test.dart — atualização do Perfil após mudança externa.
- .gitignore — proteção adicional de credenciais/exports.
- README.md — estado atual de produção, QA e orientações de publicação.
- docs/publicacao_github_vercel.md — checklist de Git, Vercel e Auth.
- docs/qa_entrega_flutter_web_2026-11-15.md — este relatório.

As outras alterações já presentes no workspace pertencem à preparação anterior.
Os SQLs originais, a configuração de produção, vercel.json e o script de build
foram reaproveitados sem modificações nesta rodada. Evidências e scripts
operacionais em .dart_tool estão ignorados pelo Git.

## Git e Vercel

O checklist completo está em [publicacao_github_vercel.md](publicacao_github_vercel.md).
Incluir código, testes, assets, lockfile, configurações públicas, script de build,
vercel.json e documentação útil. Não incluir build/, .dart_tool/, caches, backups,
certificados, .pgpass, senhas ou chaves administrativas.

Há três exclusões preexistentes que não foram feitas nem revertidas nesta etapa:
lib/controller/adocao_controller.dart, lib/controller/animal_controller.dart e
.claude/cloude-code-toolbox-mcp-skills-awareness.md. Os dois controllers não
possuem referências em lib/test. Revisar essas exclusões antes de selecionar o
commit; não usar git add -A indiscriminadamente.

Configuração preparada: Framework Other, build `node scripts/build_web.mjs`,
saída `build/web`, raiz do projeto e fallback SPA em vercel.json. O build remoto
exigirá rede para obter Flutter e pacotes. Não inserir credencial PostgreSQL ou
chave administrativa na Vercel. Nenhuma migração faz parte do deploy.

Depois de definir o domínio HTTPS, conferir Site URL e Redirect URLs do Auth
para recuperação/confirmação. Essa configuração externa não foi modificada.

## Checklist manual exato

1. Executar `flutter run -d chrome --dart-define-from-file=config/production.json`
   ou abrir o domínio após a publicação autorizada. Entrar com uma conta própria
   ativa e vinculada ao Auth, sem enviar senha à conversa.
2. Se a conta for nova, conferir o direcionamento obrigatório ao questionário;
   se já respondeu, conferir que o progresso não foi reiniciado. Na Home,
   conferir animais ordenados por compatibilidade e abrir um perfil público.
3. Abrir o animal de outra conta vinculada e conferir a ficha/Quero Adotar sem
   enviar uma solicitação nesta conferência de leitura. Abrir animal próprio
   e confirmar ausência de compatibilidade. Abrir o sino/Notificações e seus
   pedidos existentes, sem decidir ou cancelar ainda.
4. Sair, usar Voltar e entrar em outra conta própria, se disponível; confirmar
   que perfil, animais e notificações não mantêm dados da conta anterior.
   O retorno inicial à tela de boas-vindas ao recarregar a página é comportamento
   atual do main.dart; entrada automática na sessão restaurada não foi criada.
5. Somente com autorização específica para gravações: usar duas contas próprias
   vinculadas e animal disponível de um responsável autenticado; enviar pedido,
   aceitar/recusar/cancelar conforme o caso, conferir notificações e atualização
   da Home/Perfil. Não usar os nove animais legados como teste geral de falha.
6. No domínio HTTPS definitivo, conferir F5, carregamento das fontes/imagens e
   recuperação de senha pelo e-mail. Validar o link efetivo, não apenas a mensagem
   de envio. O cadastro real e e-mails dependem também das configurações Auth.

Permanecem nove animais de responsáveis sem vínculo Auth. Essa limitação
conhecida não foi tratada como falha geral do banco nem regularizada
automaticamente. Nenhuma conta fictícia foi criada nesta etapa.

## Evidências locais, fora do Git

- .dart_tool/delivery_flutter_analyze.log
- .dart_tool/delivery_flutter_test.log
- .dart_tool/delivery_flutter_build_web.log
- .dart_tool/delivery_rpc_readonly.json
- .dart_tool/delivery_web_smoke.json

O smoke utilizou o main.dart.js do novo release, SHA-256
9246001214b6986aa10961ecf68ee3c4d6564f22f812d57edfbdc4a1778249bf,
modificado às 19:40:42 UTC. A inicialização no Chrome foi conferida às
19:41:51 UTC em 15/11/2026, sem sessão anterior e sem requisições de escrita.
