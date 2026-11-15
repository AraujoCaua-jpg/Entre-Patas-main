# Entre Patas — correções para entrega Web — 14/11/2026

## Resultado

Os três defeitos do relatório inicial foram corrigidos localmente e a fixture
HTTP foi atualizada. **O Flutter Web compilou em release com sucesso**, com saída
em `build/web` e destino explícito `http://127.0.0.1:54321`.

Não houve acesso ou alteração no Supabase de produção, instalação de SQL,
alteração de registros originais, commit ou push. Os testes REST/SDK criaram
apenas dados fictícios novos no Supabase local.

## Correções

### Questionário no primeiro acesso

O trigger atual usa default 0 para `cliente.questionario_pendente`. A aplicação
já marca seus cadastros com `Auth.user_metadata.origem_cadastro=entre_patas`.
O controller agora reconhece esse marcador, além da flag legada, ao carregar
o perfil. Assim, cadastros do app não dependem do default errado para exigir o teste.

As respostas existentes têm precedência: o login consulta o questionário e,
se ele já foi respondido, segue para a Home sem reiniciar ou regravar respostas.
Ler um questionário existente ou salvá-lo com sucesso limpa a pendência apenas
em memória. A regra anterior das contas legadas sem marcador e sem pendência
foi preservada. Nenhum perfil antigo foi atualizado em massa.

Não é necessária uma migração SQL para essa correção Flutter. A coluna legada
pode continuar em 0; o fluxo efetivo foi testado com esse mesmo valor. O marcador
é uma regra de navegação do app, não uma autorização ou substituto de RLS.

### Idade desconhecida e Home

`Animal.idade` agora é `int?`. Um valor nulo continua nulo; não é convertido em
zero nem escrito no banco. As telas apresentam “Idade não informada” com os
estilos existentes. Na edição, o campo começa vazio e continua obrigatório
para salvar, em vez de preencher uma idade fictícia.

Sem idade suficiente para calcular preferências, a compatibilidade desse
animal fica nula. A fórmula de animais com dados completos permanece igual.
A Home preserva a ordenação por nota, nome e ID; animais sem cálculo continuam
visíveis ao final. O feed misto não falha por uma idade desconhecida.

### Ficha do próprio animal

`buscarAnimalPorIdSupabase()` faz `SELECT` diretamente em `animal`, com o ID
solicitado e `maybeSingle()`. Não aplica os filtros de recomendação que excluem
o proprietário ou exigem status Disponível. A RLS continua decidindo quais
registros podem ser lidos. ID inválido é rejeitado e ausência tem mensagem legível.

### Fixture e configuração Web

O mock interpreta `id_cliente=eq/neq`, ID e paginação. O fluxo de logout/troca
de contas voltou a passar sem mudar a regra do feed.

`main.dart` aceita `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY` por dart-define,
preservando os valores padrão existentes. Isso permitiu compilar para o
ambiente local sem trocar manualmente o endpoint padrão nem expor credenciais
nos argumentos dos comandos.

## Validações executadas

| Teste | Resultado | Evidência |
| --- | --- | --- |
| `flutter test --no-pub --reporter json` completo | **143 PASSOU, 0 FALHOU, 2 ignorados** | `.dart_tool/qa_fix_flutter_test.jsonl` |
| Primeiro login: novo com default 0, antigo, respondido e falha de consulta | PASSOU | Seis regressões novas e quatro testes anteriores incluídos na suíte |
| Idade nula, zero legítimo, feed misto, ordenação e edição | PASSOU | Cinco testes em `test/idade_nula_home_test.dart` |
| Ficha direta por ID, ausência, permissão e ID inválido | PASSOU | Quatro testes em `test/animal_por_id_supabase_test.dart` |
| Fixture eq/neq e login A → logout → login B | PASSOU | Oito testes da fixture e fluxo de logout incluídos na suíte |
| REST com signup/login reais na API local | **27 PASSOU, 0 FALHOU, 0 BLOQUEADO** | `.dart_tool/qa_local_rest_results.json` |
| SDK/controller e widget Home reais contra API local | **9 PASSOU, 0 FALHOU** | `.dart_tool/qa_local_sdk.log` |
| Home com o registro restaurado de idade nula | PASSOU | Future concluído, 12 animais e 12 cards; ordenação conferida |
| Solicitar, cancelar, recusar, aprovar e notificações | PASSOU | REST com JWTs reais de contas QA novas; novas aprovações simultâneas retornaram 200/409 |
| `flutter analyze --no-pub` completo | **0 erros, 0 warnings, 113 infos** | `.dart_tool/qa_fix_flutter_analyze.log`; exit 1 apenas pelos infos |
| `git diff --check` | PASSOU | Exit 0; avisos de futura conversão LF/CRLF não são erros de whitespace |
| Build Flutter Web release local | **PASSOU** | `Built build/web`, exit 0; `main.dart.js` gerado e endpoint local conferido |

Total das três baterias de testes desta rodada: **179 casos aprovados, nenhum
reprovado e dois ignorados**. Testes específicos acima já estão incluídos na suíte
completa; não foram somados novamente. Os dois ignorados dependem da flag de
troca de e-mail e não foram considerados aprovados nesta execução.

O analyzer mantém os mesmos 113 itens informativos anteriores; não surgiram
erros ou warnings. As mensagens de tree shaking de fontes e de dry run WASM
durante o build são informativas; o build release JavaScript foi concluído.

## Compilação para apresentação local

Com a configuração local preparada em `.dart_tool/qa_local_web_defines.json`,
o comando executado foi:

```powershell
flutter build web --release --no-pub --dart-define-from-file=.dart_tool/qa_local_web_defines.json
```

O arquivo de configuração fica em diretório ignorado pelo Git e contém somente
o endpoint e a chave pública do ambiente local. Não foram usadas chaves
administrativas no aplicativo. O bundle desta rodada aponta para localhost;
o Docker/Supabase local deve estar ativo na máquina da apresentação. Para outro
destino, compilar com a configuração aprovada desse ambiente.

## Arquivos alterados nesta correção

Aplicação:

- `lib/controller/cliente_controller.dart`
- `lib/model/animais.dart`
- `lib/services/compatibilidade_service.dart`
- `lib/services/supabase_service.dart`
- `lib/main.dart`
- `lib/view/animal/cadastroAnimal.dart`
- `lib/view/animal/fichaAnimal.dart`
- `lib/view/animal/animaisCadastrados.dart`
- `lib/view/animal/adocao.dart`
- `lib/view/principal/home.dart`
- `lib/view/principal/pesquisa.dart`
- `lib/view/principal/perfil.dart`
- `lib/view/usuario/fichaPerfil.dart`

Testes:

- `test/support/logout_supabase_backend.dart`
- `test/logout_fixture_filter_test.dart` (novo)
- `test/primeiro_questionario_supabase_test.dart` (novo)
- `test/idade_nula_home_test.dart` (novo)
- `test/animal_por_id_supabase_test.dart` (novo)

Documentação:

- `docs/qa_entrepatas_local_2026-11-14.md` (anotação do novo status; histórico preservado)
- `docs/qa_entrepatas_correcao_web_2026-11-14.md` (este relatório)

Runners/logs temporários em `.dart_tool` foram utilizados para a validação local;
não são mudanças na aplicação nem foram adicionados ao Git.

## Produção e dados preservados

- Estas três correções **não exigem novo SQL em produção**.
- Não foram executados SQLs 05, 10, 20 ou 30 em produção ou reaplicados no local.
- O SQL 10 continua tendo sua instalação em produção sujeita à revisão separada;
  esta rodada não autoriza nem valida implantação em produção.
- O registro disponível de idade nula continua no banco local, sem idade inventada.
- Leitura final confirmou os pedidos originais de teste: 31 Cancelado, 32 Aceito,
  33 Recusado; animal 32 Adotado e animal 33 Disponível.
- Novos perfis QA da rodada: 90, 91 e 92. Animais: 37/39 pelo REST e 38 pelo SDK.
  Pedidos novos: 40 a 45. Nenhum registro original foi apagado.

## Smoke visual antes da apresentação

Os testes validaram API, serviços, widgets e compilação; ainda é recomendado
confirmar a experiência de navegador com o bundle final:

- [ ] Abrir o build Web com a API local ativa e conferir o visual nas dimensões da apresentação.
- [ ] Cadastro novo → questionário obrigatório → concluir → Home preenchida.
- [ ] Sair/entrar novamente e confirmar que o questionário respondido não reinicia.
- [ ] Conferir “Idade não informada”, a ordenação e a ficha do animal próprio.
- [ ] Com duas contas, abrir notificações e solicitar/recusar/aprovar um pedido.

Nenhuma aprovação manual de usuário real ou validação de produção foi presumida.
