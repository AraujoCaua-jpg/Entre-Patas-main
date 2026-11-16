# Entre Patas — padronização final dos nomes Dart

Data: 16/11/2026. Branch preservada: `main`.

## Verificação inicial

`git status` confirmou alterações unstaged e arquivos não rastreados das tarefas
anteriores, incluindo README, refatoração, migração de RadioGroup e relatórios.
O índice não tinha alterações staged. As 19 exclusões documentais estavam
presentes antes desta tarefa e foram preservadas sem restauração ou confirmação.

O `flutter analyze` foi executado antes de modificar os arquivos: **0 erros,
0 warnings e 18 infos `file_names`**, exit 1. Foram confirmadas 18 ocorrências
em **18 arquivos distintos**, todas na linha 1. A lista foi comparada com o
relatório `correcao_analyzer_2026-11-16.md` antes da renomeação.

## A. Arquivos renomeados

Todos os caminhos abaixo são relativos a `lib/view/`. Motivo comum: corrigir
`file_names` usando snake_case, com a autorização explícita deste pedido.

| Nome antigo | Nome novo |
|---|---|
| `animal/animaisCadastrados.dart` | `animal/animais_cadastrados.dart` |
| `animal/cadastroAnimal.dart` | `animal/cadastro_animal.dart` |
| `animal/editarAnimal.dart` | `animal/editar_animal.dart` |
| `animal/fichaAnimal.dart` | `animal/ficha_animal.dart` |
| `autenticacao/bemVindo.dart` | `autenticacao/bem_vindo.dart` |
| `autenticacao/cadastro/cadastroUsuario.dart` | `autenticacao/cadastro/cadastro_usuario.dart` |
| `autenticacao/cadastro/cadastroUsuario2.dart` | `autenticacao/cadastro/cadastro_usuario_2.dart` |
| `autenticacao/cadastro/cadastroUsuario3.dart` | `autenticacao/cadastro/cadastro_usuario_3.dart` |
| `autenticacao/cadastro/cadastroUsuario4.dart` | `autenticacao/cadastro/cadastro_usuario_4.dart` |
| `autenticacao/esqueciSenha.dart` | `autenticacao/esqueci_senha.dart` |
| `questionario/testeComp.dart` | `questionario/teste_comp.dart` |
| `questionario/testeCompA.dart` | `questionario/teste_comp_a.dart` |
| `questionario/testeCompB.dart` | `questionario/teste_comp_b.dart` |
| `questionario/testeCompC.dart` | `questionario/teste_comp_c.dart` |
| `questionario/testeCompFim.dart` | `questionario/teste_comp_fim.dart` |
| `usuario/alterarSenha.dart` | `usuario/alterar_senha.dart` |
| `usuario/editarPerfil.dart` | `usuario/editar_perfil.dart` |
| `usuario/fichaPerfil.dart` | `usuario/ficha_perfil.dart` |

Antes de cada movimento foram conferidos arquivo de origem, limites do
workspace, referências, existência do destino e colisões sem diferenciar
maiúsculas/minúsculas. Não houve colisões. Foram feitos movimentos individuais
com `Move-Item`, sem sobrescrever destinos.

Classes, métodos, variáveis, conteúdo das telas, layout e regras de negócio
foram preservados. Uma comparação inversa das substituições reproduziu o
conteúdo anterior de cada arquivo Dart: as mudanças de conteúdo se limitam
aos caminhos nas diretivas de bibliotecas.

## B. Referências atualizadas

Foram atualizados **59 imports em 39 arquivos**: 35 referências em produção
e 24 nos testes. Os 39 arquivos se dividem em 24 arquivos de `lib/` e 15 de
`test/`. Entre eles estão `main.dart`, o entrypoint alternativo de preview,
as rotas das telas, a navegação da recuperação de senha e os testes existentes.

Não foi necessário alterar exports, scripts, configuração Vercel, Supabase,
assets ou definições de rotas. A pesquisa pelos nomes antigos em todo o
repositório de trabalho, excluindo Git, builds e caches, encontrou somente
documentos históricos preservados:

- `docs/analyzer_diagnosticos_iniciais_2026-11-16.csv`.
- `docs/correcao_analyzer_2026-11-16.md`.
- `docs/refatoracao_local_2026-11-16.md`.

Esses registros descrevem o estado anterior e não foram reescritos. As tabelas
deste relatório também mantêm os nomes antigos para documentar o mapeamento.
Os responsáveis pelos documentos podem atualizar referências de navegação
posteriormente; o inventário histórico deve continuar identificado como inicial.
O README não foi modificado.

Uma verificação de **374 imports/exports locais** confirmou a existência de
todos os destinos e correspondência exata de maiúsculas/minúsculas, incluindo
imports relativos e `package:entre_patas/`. Não restaram referências antigas
no código ativo, testes, scripts ou configurações examinados.

Os testes receberam somente mudanças nos caminhos de imports. Nenhum teste,
assertiva ou caso ignorado foi removido ou alterado para obter aprovação.

## C. Analyzer

| Medida | Antes | Depois |
|---|---:|---:|
| Erros | 0 | **0** |
| Warnings | 0 | **0** |
| Infos | 18 | **0** |
| Exit code | 1 | **0** |

Resultado real do comando: **`No issues found!`**.
Não foram adicionados `ignore` nem alterado `analysis_options.yaml`.

## D. Testes e build

| Comando ou conferência | Resultado |
|---|---|
| `flutter pub get` | Sucesso, sem upgrade de dependências. |
| `flutter analyze` | Sucesso; 0 erros, 0 warnings, 0 infos. |
| `flutter test --reporter expanded` | **293 aprovados, 2 ignorados, 0 falhas**, exit 0. |
| `node --test test/*.mjs` | **79 aprovados, 0 ignorados, 0 falhas**, exit 0. |
| `flutter build web --release --dart-define-from-file=config/production.json` | **Aprovado**, exit 0; gerado em `build/web`, compilação em 69,4 segundos. |
| `dart format --output=none --set-exit-if-changed lib test` | Aprovado; 93 arquivos, 0 mudanças, sem gravar alterações. |
| `git diff --check` | Aprovado; avisos de normalização LF/CRLF não são falhas de whitespace. |
| Verificação de imports com case exato | 374 referências locais válidas. |
| Comparação inversa do conteúdo | Nenhuma mudança além das referências. |

Os dois testes ignorados continuam dependendo da funcionalidade de alteração
de e-mail desabilitada por flag; a flag não foi alterada. Os 293 testes anteriores
continuaram aprovados. Não houve nova refatoração ou novo caso de teste nesta
tarefa, pois as alterações se limitam a nomes e referências.

Os testes SQL usam PGlite isolado e os testes Flutter usam fixtures/mocks.
O build local não equivale a deploy ou validação dos fluxos autenticados online.

## E. Git e preservação

Não foram executados commit, push, pull, merge, rebase, reset, clean, restore,
troca de branch ou deploy. O índice permaneceu sem alterações staged.

Os movimentos foram feitos no workspace, sem `git add`. Por isso, `git status`
mostra os caminhos antigos como `D` e os novos como `??`, além das modificações
anteriores. Para confirmar as renomeações sem alterar o índice, foram comparados
snapshots antes/depois com `git diff --no-index --find-renames=50% --summary`:
**o Git identificou as 18 renomeações**, com similaridade entre 90% e 100%.
As diferenças detectadas nos conteúdos são os imports atualizados.

Quando houver autorização futura para preparar um commit, origens e destinos
precisam ser selecionados juntos. As outras alterações locais e exclusões
documentais precisam de revisão própria; não foram incluídas em staging.

Hashes do início e do fim desta tarefa permanecem iguais:

- README: `F20B45DC90E773FE91238234053C39B9D0A608CEA764C5CBDA8A9407B3E8500B`.
- analysis_options: `8FBF68801276FCBAD48620F14C35E049FB4ACC384C3BB483108F357AF42ECEB9`.

Nenhum documento existente foi removido. As 19 exclusões preexistentes de
Markdown continuam sem alteração por esta tarefa. O serviço Storage local e
demais arquivos não rastreados foram preservados.

## F. Pendências

- Nenhum dos 18 arquivos ficou sem renomear; nenhuma colisão foi encontrada.
- Os imports foram conferidos com case exato para reduzir risco em Linux/Vercel.
  O build foi executado neste ambiente Windows, sem publicação ou execução de
  um build em host Linux nesta sessão.
- A equipe deve sincronizar os novos caminhos nas branches de outros integrantes
  quando integrar as mudanças; imports antigos em branches externas não foram
  acessados nem modificados.
- Documentos históricos mantêm referências antigas conforme registrado acima.
- Recomenda-se revisão manual de cadastro, login/logout, recuperação de senha,
  questionário, pesquisa, fichas, perfil e adoções no navegador antes de publicar.
- Revisar separadamente as 19 exclusões documentais e todo o diff preexistente.

O projeto continua compilando e os 293 testes anteriores passaram. O analyzer
está limpo, com 0 erros, 0 warnings e 0 infos. Está pronto para revisão manual
antes de publicar; não foi realizado commit, push ou deploy.

## Arquivos com imports atualizados

- `lib/main.dart`.
- `lib/main_preview_comp.dart`.
- `lib/view/animal/adocao.dart`.
- `lib/view/animal/animais_cadastrados.dart`.
- `lib/view/animal/compatibilidade_animal.dart`.
- `lib/view/animal/editar_animal.dart`.
- `lib/view/animal/ficha_animal.dart`.
- `lib/view/autenticacao/bem_vindo.dart`.
- `lib/view/autenticacao/cadastro/cadastro_usuario.dart`.
- `lib/view/autenticacao/cadastro/cadastro_usuario_2.dart`.
- `lib/view/autenticacao/cadastro/cadastro_usuario_3.dart`.
- `lib/view/autenticacao/esqueci_senha.dart`.
- `lib/view/autenticacao/login.dart`.
- `lib/view/core/recuperacao_senha_navigation.dart`.
- `lib/view/core/usuario_resumo.dart`.
- `lib/view/principal/home.dart`.
- `lib/view/principal/perfil.dart`.
- `lib/view/principal/pesquisa.dart`.
- `lib/view/questionario/teste_comp.dart`.
- `lib/view/questionario/teste_comp_a.dart`.
- `lib/view/questionario/teste_comp_b.dart`.
- `lib/view/questionario/teste_comp_c.dart`.
- `lib/view/usuario/configuracoes.dart`.
- `lib/view/usuario/ficha_perfil.dart`.
- `test/adocao_fluxo_test.dart`.
- `test/animais_telas_test.dart`.
- `test/cadastro_foto_supabase_test.dart`.
- `test/cadastro_layout_test.dart`.
- `test/compatibilidade_ficha_test.dart`.
- `test/idade_nula_home_test.dart`.
- `test/logout_fluxo_widget_test.dart`.
- `test/logout_supabase_test.dart`.
- `test/perfil_publico_supabase_service_test.dart`.
- `test/perfil_publico_test.dart`.
- `test/primeiro_login_test.dart`.
- `test/primeiro_questionario_supabase_test.dart`.
- `test/questionario_layout_test.dart`.
- `test/questionario_selecao_test.dart`.
- `test/recuperacao_senha_ui_test.dart`.
