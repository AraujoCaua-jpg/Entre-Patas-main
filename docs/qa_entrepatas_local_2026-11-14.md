# Relatório de QA — Entre Patas — 14/11/2026

> **Atualização após as correções:** os três defeitos abaixo e a fixture de teste
> foram corrigidos. A suíte completa agora tem 143 aprovações, nenhuma falha e
> dois casos condicionais ignorados. O build Flutter Web release foi gerado.
> Veja o status atual em [Correções e validação Web](qa_entrepatas_correcao_web_2026-11-14.md).
> Os resultados abaixo foram preservados como histórico da rodada inicial.

## Conclusão para a entrega

**Ainda há bloqueios no aplicativo.** O fluxo de adoção do SQL 10 passou nos
testes locais de banco e REST, inclusive tentativas paralelas de aprovação.
Entretanto, o primeiro acesso pode pular o questionário e a Home falha ao
converter um registro disponível com idade nula. A ficha também não encontra
animais do próprio usuário por aplicar filtros de feed.

Nenhuma correção foi aplicada à aplicação. Nenhuma migração, reset, push,
commit ou operação no Supabase de produção foi executada nesta validação.
Foram produzidos somente runners/logs em `.dart_tool` e este relatório.

## Ambiente e limites

- Container: `supabase_db_EntrePatas-Restore-Test`.
- API usada nos testes reais: `http://127.0.0.1:54321`.
- PostgreSQL local: porta 54322; Studio: porta 54323.
- SDK Dart e widget Home foram inicializados por um harness temporário,
  **sem executar `main.dart`**, cujo endpoint ainda é de produção.
- O transporte do harness rejeita outros destinos. Credenciais de contas QA
  novas foram mantidas em memória/ambiente do processo, sem gravá-las no relatório.
- A aplicação completa aberta no navegador/dispositivo, o envio real de e-mail
  e as políticas atuais de produção não foram validados.

## Contagens executadas

| Bateria | PASSOU | FALHOU | Ignorados | Evidência |
| --- | ---: | ---: | ---: | --- |
| `flutter test --no-pub --reporter json` completo | 119 | 1 | 2 | `../.dart_tool/qa_flutter_results.md` e `qa_flutter_test.jsonl` |
| Scripts SQL existentes em PostgreSQL em memória | 31 | 0 | 0 | `../.dart_tool/qa_sql_local_results.md` |
| Assertivas no PostgreSQL Supabase local instalado | 26 | 0 | 0 | `../.dart_tool/qa_sql_local_results.md`, sessão encerrada com ROLLBACK |
| REST local com signup/login e fixtures novas | 25 | 2 | 0 | `../.dart_tool/qa_local_rest_results.json` |
| Serviços/controller/widget Home reais contra API local | 6 | 3 | 0 | `../.dart_tool/qa_local_sdk.log` |
| **Total das cinco baterias finais** | **207** | **6** | **2** | Testes/assertivas de níveis diferentes; não são 207 jornadas distintas |

As seis reprovações representam **três defeitos do aplicativo/dados e uma
fixture de teste desatualizada**, com dois defeitos reproduzidos em REST e SDK.
Reexecuções de diagnóstico da Home e do teste de logout não foram somadas como
novos testes no total. Os dois ignorados são condicionais à flag de troca de e-mail;
não foram considerados aprovados nesta execução.

## Matriz objetiva

| Teste | Resultado | Evidência | Prioridade |
| --- | --- | --- | --- |
| Container local e serviços necessários ativos | PASSOU | Docker informou banco, Auth, REST e gateway locais ativos | P0 |
| Cadastro e criação automática de perfil | PASSOU | Três signups e logins REST na rodada final; cada usuário recebeu exatamente um perfil ativo vinculado ao Auth | P0 |
| Login e leitura do perfil pelo SDK real | PASSOU | `LOCAL SDK: login e perfil autenticado` | P0 |
| RLS impede leitura de perfil privado de outro usuário | PASSOU | REST com JWT do adotante não retornou perfil privado do responsável | P0 |
| Primeiro acesso exige questionário | **FALHOU** | Novo perfil: `questionario_pendente=0`, nenhum questionário; SDK confirma flag falsa; login só abre teste quando flag é verdadeira | **P0** |
| Questionário salva, persiste e pode ser refeito sem duplicação | PASSOU | REST UPSERT/SELECT e SDK real salvar/consultar/refazer; respostas e identidade do questionário conferidas | P0 |
| Fórmula de compatibilidade | PASSOU | Cinco testes específicos da ficha/fórmula na suíte Flutter completa, com respostas simuladas | P1 |
| Home mostra e ordena animais reais | **FALHOU** | `HOME_QA future_state=error error_type=_TypeError cards_count=0`; banco local possui um animal disponível com `idade IS NULL` | **P0** |
| Persistência de percentuais como coluna de banco | NÃO EXECUTADO | A implementação persiste respostas e recalcula percentuais em memória; não há escrita de porcentagens pelo fluxo atual | P2 |
| Pesquisa de animal válido por nome/espécie | PASSOU | REST encontrou o animal QA com filtros; SDK encontrou a ficha pública do animal fictício válido | P1 |
| Pesquisa pública de usuários sem contatos privados | PASSOU | RPC REST e SDK encontraram perfis; projeção sem e-mail/telefone/endereço privados | P0 |
| Publicação de animal com ID automático e vínculo correto | PASSOU na repetição | REST criou animal 34; SDK criou animal 35 e confirmou a listagem própria | P0 |
| Ficha do próprio animal publicado | **FALHOU** | SDK publicou o animal e depois `buscarAnimalPorIdSupabase` não o encontrou; filtro contém o próprio ID e `id_cliente != meuId` | **P1** |
| Animal adotado permanece acessível ao responsável pela busca genérica da ficha | FALHOU na inspeção do código | A mesma busca exige `status='Disponível'`; detalhes históricos de adoção usam DTO separado e continuaram funcionando | P1 |
| Nova solicitação vincula adotante/responsável e começa Aguardando | PASSOU | REST com JWT real criou pedido QA e conferiu os IDs derivados no servidor | P0 |
| Pedido duplicado e solicitação do próprio animal | PASSOU | REST bloqueou os dois cenários; SQL local também validou guardas | P0 |
| Consultar pedido individual como adotante ou responsável | PASSOU | Ambos receberam o próprio pedido via RPC; pedidos fictícios 31/32/33 também conferidos no SQL local | P0 |
| Terceiro não consulta pedido alheio | PASSOU | REST recebeu 404 e SQL autenticado confirmou bloqueio | P0 |
| Anônimo não executa RPCs protegidas de adoção | PASSOU | Quatro chamadas REST anônimas bloqueadas, mais verificação SQL de privilégios | P0 |
| Permissões RPC, helpers privados, RLS e índices únicos | PASSOU | Catálogo local: quatro RPCs protegidas, helpers sem EXECUTE para anon/authenticated, RLS ativa e dois índices únicos parciais | P0 |
| Aprovação não autorizada e PATCH direto no status | PASSOU | REST negou decisão do adotante e alteração direta; SQL confirmou proteção | P0 |
| Cancelamento, recusa e reenvio permitido | PASSOU | Ciclo REST preservou os pedidos finalizados e permitiu novos pedidos após Cancelado/Recusado | P0 |
| Aprovação atualiza animal e recusa outras pendentes | PASSOU | Pedido 36 Aceito, pedido 37 Recusado, animal 34 Adotado, conferidos por REST | P0 |
| Solicitação finalizada não admite nova aprovação | PASSOU | Repetição REST retornou 409; SQL confirmou pedidos 32/33 finalizados | P0 |
| Animal adotado bloqueia novo pedido de outro adotante | PASSOU | REST de outro adotante retornou 409 | P0 |
| Duas aprovações paralelas não aceitam dois adotantes | PASSOU | Duas requisições REST em paralelo retornaram 200/409; pedidos 38/39 ficaram Aceito/Recusado no animal QA 36 | P0 |
| Notificações refletem decisão e são restritas às partes | PASSOU | REST listou Aceito para responsável/adotante e não revelou esse pedido ao outro usuário; SDK conferiu isolamento | P0 |
| Contratos Flutter/RPC coincidem com catálogo instalado | PASSOU | Oito nomes/argumentos/retornos compatíveis; `qa_rpc_audit.md` | P0 |
| Aplicativo completo aberto contra Supabase local | BLOQUEADO | `main.dart:16` tem endpoint de produção fixo; não foi iniciado para evitar acesso indevido a produção | P1/QA |
| `flutter analyze --no-pub` completo | PASSOU quanto a erros/warnings | Zero errors, zero warnings, 113 infos; comando saiu com 1 por infos | P2 |
| `flutter test` completo | **FALHOU** | 119 passaram, uma fixture HTTP antiga falhou antes do logout e dois casos foram ignorados | P1/QA |
| `git diff --check` | PASSOU | Exit 0; apenas avisos de futura conversão LF/CRLF | P2 |
| Scripts PHP legados contra MySQL/API antiga | NÃO EXECUTADO | Fora do Supabase local especificado; não foram iniciados para evitar alterações em outro banco | P2 |
| Validação de produção | NÃO EXECUTADO | Proibida pelo escopo desta tarefa | P0 |

## Defeitos e correções mínimas propostas — não aplicadas

### 1. P0 — Home interrompida por idade nula

`lib/model/animais.dart:45` faz `(d['idade'] as num).toInt()`. O esquema local
permite nulo e a contagem confirmou um registro ativo/disponível com idade nula.
O `FutureBuilder` da própria Home terminou com `_TypeError`, antes de gerar cards.

Correção mínima: regularizar esse dado com a idade real confirmada, sem inventar
zero e sem excluir o registro. Também tratar registros incompletos na conversão
do feed para que uma linha não derrube toda a listagem. Qualquer correção de dado
restaurado ou código precisa de revisão antes de ser aplicada.

### 2. P0 — Primeiro cadastro pula o teste obrigatório

O trigger local cria o perfil sem informar `questionario_pendente`; a coluna tem
default 0. Em `lib/view/autenticacao/login.dart:72` e `:83`, a ausência de
questionário só é consultada/encaminhada quando a flag é verdadeira.
Uma conta nova autenticada foi criada e a condição defeituosa foi reproduzida.

Correção mínima se todo primeiro acesso precisa do teste: consultar a existência
do questionário no login e encaminhar pela ausência dele, independentemente da
flag legada. Se houver exceção intencional para contas antigas, preservar essa
regra e ajustar apenas a criação de novos perfis para marcar pendência, com a
conclusão sincronizada ao salvar respostas. Não atualizar contas antigas em massa.

### 3. P1 — Ficha própria usa filtros de feed

`lib/services/supabase_service.dart:576` chama `buscarAnimais(animalId: ...)`.
Essa função aplica `ativo=true`, `status='Disponível'` e exclui `id_cliente=meuId`
quando não há filtro explícito de responsável. O SDK publicou um animal próprio,
mas a consulta individual não o encontrou.

Correção mínima: buscar o ID diretamente em `animal` com `eq('id', id)` e
`maybeSingle()`, deixando a visibilidade a cargo da RLS existente. Não remover
os filtros de disponibilidade da Home/pesquisa nem ampliar permissões do banco.

### 4. P1/QA — Fixture desatualizada do teste de logout

`test/logout_fluxo_widget_test.dart:79` falha ainda na Home. A fixture
`test/support/logout_supabase_backend.dart` só aceita `id_cliente=eq.<meuId>`,
enquanto o serviço agora usa `neq.<meuId>` corretamente no feed. Correção mínima:
atualizar a fixture para interpretar `eq` e `neq`. Isso não justifica alterar o app.
Os outros testes de logout passaram; essa falha não prova um defeito no logout.

### 5. P1/QA — Configuração fixa impede abrir o app para teste local

Parametrizar URL e chave pública por ambiente antes de iniciar a aplicação para QA.
O harness desta tarefa inicializou SDK/widgets diretamente com localhost e não
executou `main.dart`. A configuração de produção fixa não prova, por si só, um
erro da aplicação em produção; ela bloqueia a execução segura do teste local completo.

## Observação sobre a primeira tentativa de cadastro de animal

A primeira rodada REST teve dois INSERTs recusados com 23505. Não houve ajuste
de sequência. A leitura posterior encontrou `animal_id_seq=33`, `MAX(id)=33` e
próximo ID 34 livre; a única restrição única da tabela era sua chave primária.
A repetição criou o animal 34 automaticamente, e o SDK criou o 35 também com
ID automático. Não há desalinhamento atual comprovado nem justificativa para
executar `setval` automaticamente. O erro inicial foi preservado em
`qa_local_rest_first_attempt.json`; não foi contabilizado como falha persistente
do cadastro na bateria final. O próximo restore deve conferir sequências.

## Dados fictícios e preservação dos originais

- Foram criadas oito contas QA novas, com perfis 82 a 89, sem reutilizar senhas
  das contas de teste anteriores nem alterar seus dados de autenticação.
- Animais QA novos: 34 e 36 na rodada REST; 35 criado pelo SDK.
- Pedidos QA novos: 34 a 39. Foram exercitados cancelamento, recusa e aprovação.
- Nenhuma limpeza foi executada. As fixtures permanecem exclusivamente no local.
- Leitura final confirmou: pedido 31 Cancelado; 32 Aceito; 33 Recusado;
  animal 32 Adotado e animal 33 Disponível. Nenhum original foi apagado.

## Avaliação do SQL 10

**Tecnicamente apto a ser levado para avaliação de instalação em produção**, com
evidências positivas de contrato, autorização, transação, índices e duas decisões
paralelas no ambiente local restaurado. Essa conclusão não é autorização para
instalar e não certifica o estado atual de produção.

Antes de qualquer instalação real: revisar o SQL original, confirmar backup
recuperável e procedimento de restauração, comparar esquema/grants/status/
duplicidades/vínculos Auth com a produção atual e definir janela de execução e
rollback. Não reaplicar cegamente no local: o SQL 10 já está instalado e possui
guardas contra reaplicação. Os defeitos de Home/primeiro acesso/ficha são
independentes do êxito do SQL 10 e precisam ser resolvidos para a entrega do app.

## O que pode ficar para depois

- Infos de depreciação/nomes de arquivos: 113 itens sem erros ou warnings.
- Aprimorar combinação de filtros/paginação de “Perto de mim”: a RPC é retornada
  antes dos filtros restantes. Achado de código, sem reprovação de teste geográfico
  ponta a ponta nesta rodada.
- Ampliar testes de recuperação de senha/troca de e-mail com entrega real de
  mensagens e dispositivos; os testes automatizados existentes são simulados.

## Próximos passos mínimos e checklist manual pendente

1. Revisar/aplicar as correções mínimas da Home e do questionário obrigatório.
2. Corrigir a busca individual do animal e atualizar somente a fixture de teste
   que está incompatível com o filtro atual.
3. Configurar a execução local do aplicativo sem alterar o destino de produção
   por acidente; rerodar os casos reprovados e `flutter test` completo.
4. Confirmar manualmente no app apontando para localhost:
   - [ ] Cadastro novo → perfil → teste obrigatório → conclusão → Home preenchida.
   - [ ] Fechar/abrir sessão → respostas persistidas e compatibilidade reordenada.
   - [ ] Pesquisa → ficha de animal alheio; publicar → visualizar/editar animal próprio.
   - [ ] Conta A solicita; conta B recebe aviso e recusa/cancela/aprova conforme papel.
   - [ ] Voltar à lista de notificações e verificar os estados após a decisão.
   - [ ] Animal adotado não aceita novos pedidos; cada conta vê apenas seus pedidos.
   - [ ] Logout/troca de contas sem dados anteriores nem retorno a rotas protegidas.
5. Só depois avaliar a instalação em produção e fazer o smoke test autorizado.

## Evidências e reprodução

Artefatos temporários não contêm credenciais no texto do relatório:

- `../.dart_tool/qa_flutter_results.md`
- `../.dart_tool/qa_flutter_analyze.log`
- `../.dart_tool/qa_flutter_test.jsonl`
- `../.dart_tool/qa_sql_local_results.md`
- `../.dart_tool/qa_rpc_audit.md`
- `../.dart_tool/qa_local_rest_results.json`
- `../.dart_tool/qa_local_sdk.log`
- `../.dart_tool/qa_home_diagnostic.log`

Comandos executados incluem `flutter analyze --no-pub`,
`flutter test --no-pub --reporter json`, os três testes SQL `.mjs` existentes,
`git diff --check`, consultas `psql` somente no container local e runners Node
temporários com transporte restrito a localhost. Senhas, tokens e chave local
não foram adicionados aos argumentos dos comandos nem a este documento.
