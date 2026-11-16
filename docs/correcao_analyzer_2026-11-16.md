# Entre Patas — correção dos diagnósticos do analyzer

Data: 16/11/2026. Branch: `main`. Flutter instalado: **3.50.0**, Dart **3.14.0**,
conforme `C:/dev/flutter/bin/cache/flutter.version.json`.

## A. Diagnóstico inicial

Executados `git status`, conferência da branch e `flutter analyze` antes das
alterações. A saída completa foi capturada em
`%TEMP%/entre_patas_infos_before.log`. O comando terminou com exit 1 devido às
informações, sem erros ou warnings.

| Regra | Ocorrências | Gravidade | Causa | Decisão |
|---|---:|---|---|---|
| `deprecated_member_use` | 92 | info | API antiga de seleção individual dos rádios e leitura/chamada dessa API pelos testes | Corrigir com `RadioGroup` e testes de interação. |
| `file_names` | 18 | info | Arquivos camelCase em vez de snake_case | Preservar nomes; renomeação depende de autorização. |
| **Total** | **110** | **info** | **0 erros e 0 warnings** | **Nenhuma outra regra identificada.** |

Os 92 usos deprecated são 48 leituras/argumentos `groupValue` e 44 usos de
`onChanged`: 80 ocorrências nos 40 rádios do aplicativo e 12 nos testes.

| Arquivo | Deprecated | file_names |
|---|---:|---:|
| `lib/view/animal/cadastroAnimal.dart` | 20 | 1 |
| `lib/view/questionario/testeCompA.dart` | 4 | 1 |
| `lib/view/questionario/testeCompB.dart` | 30 | 1 |
| `lib/view/questionario/testeCompC.dart` | 26 | 1 |
| `test/adocao_fluxo_test.dart` | 6 | 0 |
| `test/animais_telas_test.dart` | 2 | 0 |
| `test/questionario_selecao_test.dart` | 4 | 0 |
| Outros 14 arquivos de telas | 0 | 14 |

São **21 arquivos afetados** no diagnóstico inicial. A classificação completa
por regra, mensagem, arquivo, linha/coluna inicial, gravidade e situação final
está em [analyzer_diagnosticos_iniciais_2026-11-16.csv](analyzer_diagnosticos_iniciais_2026-11-16.csv).
As posições desse inventário correspondem ao código antes da migração.

O resumo das duas regras, causas e estratégia foi apresentado antes das
correções. Não havia diagnósticos de const, contextos assíncronos, null safety,
imports não utilizados ou exceções nesta execução; não foram feitas mudanças
cosméticas nessas áreas.

## B. Correções realizadas

A alternativa foi verificada diretamente na documentação e implementação do
SDK instalado: `packages/flutter/lib/src/widgets/radio_group.dart` e
`packages/flutter/lib/src/material/radio.dart`. `RadioGroup` gerencia a seleção,
o callback e a navegação por teclado de rádios do mesmo tipo em sua subárvore.
Os controles `Radio` continuam responsáveis por cada opção e suas cores.

Foram criados **16 grupos independentes**, um por campo:

- Cadastro/edição de animal: sexo, carência, convivência, castração e vacinação.
- Questionário A: sexo.
- Questionário B: residência, horas sozinho, dedicação e convivência.
- Questionário C: imóvel, apoio, compromisso, moradores, financeiro e rotina.

Cada `groupValue` e `onChanged` saiu dos controles individuais e passou para o
grupo da respectiva pergunta. Nenhum grupo envolve perguntas distintas. Nas
perguntas com opções em várias linhas, as mesmas linhas foram agrupadas em uma
Column. Não houve substituição do componente visual, alteração dos textos ou
mudança dos valores enviados ao questionário/animal.

A migração foi limitada aos quatro arquivos inspecionados e às quantidades
esperadas por campo. Foram verificados os limites de cada Row, a ausência de
mistura de campos e o número de callbacks antes da transformação. Não houve
substituição indiscriminada de todas as propriedades chamadas `onChanged`.

Foi conferida a sequência dos pares valor/cor dos 40 rádios contra a versão
Git desses quatro arquivos, que não tinham mudanças locais no início desta
tarefa: as 40 opções mantêm valores, ordem e `activeColor`.

Arquivos de produção modificados nesta tarefa:

- `lib/view/animal/cadastroAnimal.dart`.
- `lib/view/questionario/testeCompA.dart`.
- `lib/view/questionario/testeCompB.dart`.
- `lib/view/questionario/testeCompC.dart`.

Testes adaptados:

- `test/questionario_selecao_test.dart`: consulta o valor do grupo pela API
  atual; mantém as verificações de todas as escolhas, isolamento e dados da
  próxima etapa. Acrescenta uma regressão de teclado entre perguntas.
- `test/adocao_fluxo_test.dart`: preserva verificação de questionário inicialmente
  vazio e resultado salvo; passa a escolher por clique real.
- `test/animais_telas_test.dart`: preserva valores iniciais de saúde e testa
  interação real nas opções de castração e vacinação.
- Novo `test/support/radio_test_helpers.dart`: leitura do grupo pela API pública
  `RadioGroup.maybeOf` e clique com rolagem/atualização da tela.

Nenhum teste foi removido, nenhuma regra de negócio foi alterada e nenhum
diagnóstico foi ocultado com `ignore` ou alteração de configuração.

## C. Diagnóstico final

| Medida | Inicial | Final |
|---|---:|---:|
| Erros | 0 | 0 |
| Warnings | 0 | 0 |
| Infos deprecated | 92 | **0** |
| Infos file_names | 18 | **18** |
| **Total de infos** | **110** | **18** |

**92 informações corrigidas**, aproximadamente 84% do total. `flutter analyze`
ainda termina com **exit 1**, pois as 18 informações restantes continuam
habilitadas e visíveis. Isso não é apresentado como analyzer totalmente limpo.

## D. Validação

| Verificação | Resultado |
|---|---|
| Testes focados após migrar produção e testes | **12 aprovados**, nenhuma falha. |
| Testes de seleção após preparar foco de teclado | **4 aprovados**, nenhuma falha. |
| `flutter analyze` final | 0 erros, 0 warnings, 18 infos; exit 1 pelas infos. |
| `flutter test --reporter expanded` final | **293 aprovados, 2 ignorados, 0 falhas**, exit 0. |
| `node --test test/*.mjs` | **79 aprovados**, 0 falhas, 0 ignorados. |
| `flutter build web --release --dart-define-from-file=config/production.json` | **Aprovado**, exit 0; `build/web`, compilação em 88,2 segundos. |
| `dart format --output=none --set-exit-if-changed lib test` | **Aprovado**, 93 arquivos, 0 mudanças. |
| `git diff --check` | **Aprovado**; avisos de normalização futura LF/CRLF não são falhas de whitespace. |

A referência anterior era 292 testes Flutter aprovados e 2 ignorados. Essa
referência veio da refatoração anterior, não de uma nova execução integral antes
das mudanças desta tarefa. O diagnóstico inicial do analyzer foi reexecutado.

A primeira rodada completa, após acrescentar o teste de teclado, teve 292
aprovados, 2 ignorados e 1 falha no teste novo: clicar em modo touch não
estabelecia foco de teclado. A preparação foi corrigida para focar o controle
antes da seta e verificar que ele recebeu foco. A expectativa de seleção e o
teste de isolamento das outras perguntas foram mantidos. Não foi necessário
reverter a migração dos controles. A suíte completa foi repetida depois disso.

Os dois testes ignorados continuam relacionados à alteração de e-mail
desabilitada por flag. Não houve alteração dessa flag. O build validou o mesmo
código de produção da rodada final; o ajuste posterior era somente no teste.

Os contratos SQL executam em PGlite e os testes Flutter usam fixtures/mocks.
Não comprovam os fluxos autenticados no Supabase real, entrega de e-mail ou
comportamento visual completo no domínio publicado. Nenhuma operação remota
foi executada.

## E. Nomes preservados e impacto de uma renomeação futura

Todos os candidatos abaixo têm **uma info `file_names` na linha 1**. Não foram
renomeados. A mudança precisa atualizar imports de telas/testes, manter classes
públicas, revisar entrypoints alternativos e ser coordenada com as branches dos
colegas. Os nomes de classes e a navegação não precisam mudar; as referências
aos caminhos precisam mudar juntas.

| Arquivo atual em `lib/view/` | Nome proposto | Impacto esperado |
|---|---|---|
| `animal/animaisCadastrados.dart` | `animais_cadastrados.dart` | Perfis, fichas, gerenciamento e testes. |
| `animal/cadastroAnimal.dart` | `cadastro_animal.dart` | Cadastro, wrapper de edição e testes. |
| `animal/editarAnimal.dart` | `editar_animal.dart` | Navegação de gerenciamento. |
| `animal/fichaAnimal.dart` | `ficha_animal.dart` | Home, pesquisa, perfis, gerenciamento e testes. |
| `autenticacao/bemVindo.dart` | `bem_vindo.dart` | Entrypoint, logout, configurações e testes. |
| `autenticacao/cadastro/cadastroUsuario.dart` | `cadastro_usuario.dart` | Login, boas-vindas e testes. |
| `autenticacao/cadastro/cadastroUsuario2.dart` | `cadastro_usuario_2.dart` | Etapas do cadastro e testes. |
| `autenticacao/cadastro/cadastroUsuario3.dart` | `cadastro_usuario_3.dart` | Etapas do cadastro e testes. |
| `autenticacao/cadastro/cadastroUsuario4.dart` | `cadastro_usuario_4.dart` | Etapas do cadastro e testes. |
| `autenticacao/esqueciSenha.dart` | `esqueci_senha.dart` | Login e testes de recuperação. |
| `questionario/testeComp.dart` | `teste_comp.dart` | Login, Home, configurações e testes. |
| `questionario/testeCompA.dart` | `teste_comp_a.dart` | Questionário, preview e testes. |
| `questionario/testeCompB.dart` | `teste_comp_b.dart` | Questionário e testes. |
| `questionario/testeCompC.dart` | `teste_comp_c.dart` | Questionário e testes. |
| `questionario/testeCompFim.dart` | `teste_comp_fim.dart` | Conclusão e testes. |
| `usuario/alterarSenha.dart` | `alterar_senha.dart` | Configurações, recuperação por evento Auth e testes. |
| `usuario/editarPerfil.dart` | `editar_perfil.dart` | Perfil, configurações e testes. |
| `usuario/fichaPerfil.dart` | `ficha_perfil.dart` | Pesquisa, resumo do responsável e testes. |

Renomeação em conjunto tem impacto transversal em imports e pode gerar conflitos
de integração, por isso depende de autorização específica. Nenhum arquivo foi
movido, excluído ou substituído por um wrapper apenas para eliminar a regra.

## Preservação do workspace e das 19 exclusões

O README, `analysis_options.yaml`, alterações staged/unstaged e arquivos não
rastreados das tarefas anteriores foram preservados. Não houve commit, push,
pull, merge, rebase, reset, clean ou deploy. Credenciais, configurações Vercel,
Supabase, SQL e RLS não foram alterados.

Hashes iniciais e finais conferidos:

- README: `F20B45DC90E773FE91238234053C39B9D0A608CEA764C5CBDA8A9407B3E8500B`.
- analysis_options: `8FBF68801276FCBAD48620F14C35E049FB4ACC384C3BB483108F357AF42ECEB9`.

As seguintes exclusões já estavam no status inicial e continuam sem ação desta
tarefa. Não foram restauradas nem confirmadas por commit:

```text
docs/adocoes_supabase.md
docs/backup_recuperacao_supabase.md
docs/backup_restauracao_atualizado_2026-11-15.md
docs/backup_validacao_2026-11-15.md
docs/checklist_instalacao_sql12_15_10.md
docs/correcoes_finais_sql10.md
docs/ensaio_final_migracoes_2026-11-15.md
docs/instalacao_producao_2026-11-15.md
docs/investigacao_perfis_publicos.md
docs/plano_recuperacao_supabase_gerenciado.md
docs/pre_instalacao_original_2026-11-15.md
docs/preparacao_producao.md
docs/publicacao_github_vercel.md
docs/qa_entrega_flutter_web_2026-11-15.md
docs/qa_entrepatas_correcao_web_2026-11-14.md
docs/qa_entrepatas_local_2026-11-14.md
docs/recuperacao_gerenciada_2026-11-15.md
docs/regularizacao_responsaveis_auth.md
docs/revisao_sql10_producao.md
```

Pendências: decidir sobre os 18 nomes e sobre as exclusões documentais, revisar
as telas manualmente no navegador e manter a validação remota separada. As
correções desta tarefa não autorizam publicar as demais alterações do workspace.

O projeto continua compilando e todos os testes executados na rodada final
passaram. Está pronto para revisão manual antes de publicar. Restam somente as
18 informações de nomes; sua eliminação depende da autorização para renomear
os arquivos e atualizar as referências. Nenhuma publicação foi realizada.
