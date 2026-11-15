# Investigação dos perfis públicos — 15/11/2026

## Conclusão

O comportamento informado foi explicado pelo código e pela leitura real da
produção. A função instalada aceita terceiros somente quando o responsável
possui animal ativo/Disponível, além de permitir o próprio perfil. O resultado
não depende diretamente de o perfil consultado possuir Auth.

No snapshot examinado, somente os IDs **1 e 38** satisfazem esse filtro para o
observador de referência 1. O primeiro corresponde ao segundo perfil informado
pelo usuário e o segundo ao primeiro. Os nomes foram usados somente para
confirmar essas referências; não foram exportados contatos, endereços ou UUIDs.

O SQL 12 já preparado e instalado no ambiente local corrige essa regra. Ele
**ainda não está instalado na produção**, que mantém a definição antiga.
Nesta rodada, sua cobertura foi ampliada explicitamente para alvos legados
sem Auth/animais, e o Flutter foi corrigido para tratar respostas vazias ou
inválidas de forma segura e legível.

Não houve alteração, migração, reativação, vínculo Auth, cadastro ou teste de
escrita em produção. Não houve commit, push ou deploy.

## 1. Comparação real por IDs

Snapshot de produção: **15/11/2026 02:55:30 UTC**
(14/11/2026 23:55:30 em São Paulo). Consulta pelo CLI no projeto explicitamente
indicado, com `--read-only`; o servidor confirmou `transaction_read_only=on`
e papel `supabase_read_only_user`.

O novo arquivo `docs/sql/02_diagnosticar_perfis_publicos_somente_leitura.sql`
retorna somente IDs, flags, contagens e metadados de função. A elegibilidade
abaixo reproduz o predicado do helper de **perfil**, considerando observador 1.
Não foi forjada sessão/JWT ou executada RPC como um usuário real.

| ID | Ativo | Possui Auth | Animais disponíveis | Predicado instalado | Após regra SQL 12 |
| ---: | --- | --- | ---: | --- | --- |
| 1 | Sim | Sim | 2 | Permite | Permite |
| 38 | Sim | **Não** | 8 | Permite | Permite |
| 6 | Sim | **Não** | 0 | **Exclui** | Permite |
| 76 | Sim | **Sim** | 0 | **Exclui** | Permite |
| 22 | **Não** | Não | 1 | Exclui | **Continua excluído** |
| 15 | **Não** | Não | 0 | Exclui | **Continua excluído** |

O ID 38 carregar sem Auth e o ID 76 falhar com Auth demonstram que ausência de
login no alvo não explica o filtro. O fator indevido é exigir animal disponível.
Ter animal disponível tampouco autoriza mostrar uma conta inativa, como o ID 22.

Coorte completa: 12 perfis, dez ativos e dois inativos. Os oito ativos excluídos
pelo predicado antigo são 6, 37, 44, 57, 73, 76, 77 e 78; todos têm zero animais
disponíveis. A regra corrigida os permite sem modificar seus registros.

O próprio perfil pode ser permitido pela regra antiga mesmo sem animais. A
matriz explicita o observador para não confundir esse caso com consulta de terceiros.

Evidências locais ignoradas: `.dart_tool/perfis_producao_comparacao.json` e
`.dart_tool/perfis_producao_referencias.json`. As contagens são do snapshot,
não uma promessa de que os dados online nunca mudarão.

## 2. Funções realmente instaladas e SQLs do repositório

### Produção

`public.buscar_perfil_publico(integer)` é um wrapper SQL STABLE,
SECURITY INVOKER, que delega a
`private.detalhe_publico_responsavel(integer)`.

O helper privado usa SECURITY DEFINER, `search_path=''`, referências
qualificadas e projeta apenas campos públicos. Sua restrição efetiva é:

```text
perfil de destino ativo
e (é o próprio usuário OU possui animal ativo com status Disponível)
```

`private.resumo_responsavel(integer)` também tem a dependência de animais
disponíveis. A versão antiga não aplica a mesma checagem de atividade do destino
em todos os caminhos; o SQL 12 padroniza a proteção de contas inativas nos dois helpers.

O fingerprint atual do helper de detalhe é
`dde86b97b1d8e2adaf2d4f943539a12d`, igual à definição anterior auditada e usada
na fixture de reprodução. O helper de resumo também mantém seu fingerprint
anterior, `d0f9d3d912b77cf5f837eb0b1861a385`.

O retorno do perfil instalado é uma lista de registros com ID integer e os
campos nome, sobrenome, usuário, imagem, cidade, estado e lar_de_adocao. Esse
formato é compatível com o Dart. Não foi encontrada diferença de formato que
explique os dois perfis funcionarem e os demais ativos sem animais falharem.

### SQL 30 e SQL 12 locais

A versão atual do SQL 30 preserva os wrappers INTEGER existentes e exige o
SQL 12 para perfil/resumo. Não recria versões BIGINT. A versão antiga do arquivo
não era a função instalada na produção e poderia provocar conflitos de retorno
e overloads; essa incompatibilidade foi corrigida na rodada anterior.

O SQL 12 atual já usa, no **destino**, somente ID e `ativo=true`.
Não exige `auth_user_id`, animal ou status Disponível no alvo. Quem consulta
continua precisando de Auth e exatamente um perfil ativo. Nenhuma mudança
adicional de SQL 12/30 foi necessária nesta investigação.

Assim, publicar apenas o Flutter não retirará o filtro instalado. A instalação
do SQL 12, após backup/restauração e autorização, é a correção do backend online.
O SQL 30 não precisa ser instalado para resolver esta falha de perfil.

## 3. Por que o Flutter mostrava a mensagem genérica

O serviço recebia `[]`, convertia para lista e lançava `Exception` quando não
encontrava perfil. A tela só exibia a mensagem específica de `LoginException`;
para essa outra exceção mostrava “Não foi possível carregar o perfil”.

Além disso, a conversão anterior pressupunha uma lista de mapas válida. Uma
resposta com ID/campos de tipo errado poderia alcançar `_PerfilPublico.fromMap`
ou os casts de `UsuarioResumo` e gerar erro de tipo.

Os dois métodos do serviço agora usam um contrato explícito:

- ID solicitado positivo, sessão presente e resposta descartada após troca/logout.
- Lista com exatamente um mapa e ID numérico integral correspondente ao pedido.
- Campos públicos opcionais aceitam string/null; lar_de_adocao aceita bool/null.
  Campos omitidos continuam omitidos, sem dados fabricados.
- Lista vazia gera `LoginException('Perfil público indisponível.')` ou a mensagem
  específica de responsável. Resposta malformada tem mensagem própria e segura.
- Erros de acesso, sessão, RPC ausente e rede são tratados sem expor SQL/contatos.
- Somente chaves públicas conhecidas são devolvidas; contatos inesperados não
  são propagados. Isso complementa, sem substituir, a proteção do banco.

Não há consulta à tabela privada para tentar contornar resultado vazio ou RLS.
Não se exige Auth no alvo e não se usa a lista de animais para decidir se o
perfil será mostrado. As telas e seu layout não foram alterados.

Uma conta inativa/inexistente continua indisponível; a mensagem pública não
precisa revelar qual dessas situações ocorreu. Ninguém foi reativado.

## 4. Testes executados nesta rodada

| Bateria | Passaram | Falharam | Ignorados | Evidência |
| --- | ---: | ---: | ---: | --- |
| Flutter completo | 245 | 0 | 2 | `.dart_tool/perfis_final_flutter.jsonl` |
| SQL completo em PGlite | 74 | 0 | 0 | `.dart_tool/perfis_final_sql.log` |
| API Supabase local, sessão legítima | 11 | 0 | 0 | `.dart_tool/perfis_legados_local_results.json` |
| **Total das três baterias** | **330** | **0** | **2** | Sem duplicar testes focados/reexecuções |

Os dois ignorados são condicionais à flag de sincronização de e-mail, não
considerados aprovados. Os 77 testes Flutter novos e as cinco novas regressões
SQL já estão incluídos nas respectivas suítes completas.

As regressões SQL carregam as definições anteriores reais com dados fictícios:
reproduzem a exclusão antes do SQL 12 e confirmam visibilidade depois, inclusive
para Auth NULL e zero animais/único animal adotado. Alvos inativos com animal
disponível continuam ocultos. Snapshots confirmam preservação de dados/vínculos.

Os testes Flutter incluem widgets reais de ficha e resumo, lista vazia, contratos
inválidos, erros SQL/permissão/rede, sessão antiga e ausência de contatos privados.
Confirmam que dados malformados não chegam ao cast de `fromMap` e não travam a tela.

No Supabase local foram inseridos apenas dados fictícios novos:

- Chamador Auth legítimo, perfil 102, ativo e sem animais.
- Legado 103, ativo e Auth NULL: começa sem animais, recebe depois apenas um
  novo animal Adotado. Perfil e resumo continuam retornando uma linha.
- Legado 104, inativo e Auth NULL: possui novo animal Disponível, mas perfil e
  resumo continuam vazios.
- Novos animais 51 e 52. Nenhum UPDATE/DELETE, vínculo ou reativação foi feito.

Também passaram: perfil próprio do chamador sem animais, perfil inexistente,
negação de anônimo, RLS da tabela privada e pesquisa com contatos mascarados.
Não foram usadas credenciais de pessoas reais nos testes locais.

Validações complementares: análise completa sem erros/warnings, com os mesmos
113 infos anteriores (exit 1 somente pelos infos). Build Web release passou,
exit 0, com endpoint online e chave pública conferidos; `git diff --check`
também passou, exit 0. Evidências: `.dart_tool/perfis_final_analyze.log`,
`.dart_tool/perfis_final_build.log` e `.dart_tool/perfis_final_diff_check.log`.
A leitura administrativa de produção não é teste de navegação no aplicativo
nem prova de uma instalação de correção que ainda não aconteceu.

## 5. Arquivos desta investigação

- `lib/services/supabase_service.dart`: validação/erros dos métodos de perfil e resumo.
- `test/perfil_publico_supabase_service_test.dart`: 77 casos novos de serviço/widgets.
- `test/perfis_publicos_supabase_sql_test.mjs`: cinco regressões novas de legados.
- `docs/sql/02_diagnosticar_perfis_publicos_somente_leitura.sql`: comparação por
  IDs/flags/contagens, sem dados privados ou mudança de sessão.
- `docs/investigacao_perfis_publicos.md`: este relatório.
- `docs/correcoes_finais_sql10.md`: link para esta ampliação da investigação.

SQLs 12/30, policies, dados de produção, algoritmo, layouts e configuração de
credenciais foram preservados. Os demais diffs existentes não foram revertidos.

## 6. Próximo passo para produção

1. Confirmar backup atual/restaurável e ensaio isolado, conforme
   [Backup e recuperação](backup_recuperacao_supabase.md).
2. Revisar o snapshot/assinaturas com os SQLs de leitura e o SQL 12 original.
3. Obter autorização explícita e só então instalar SQL 12 no destino. Ele é
   independente do SQL 10 para essa correção de perfil.
4. Com sessão normal, conferir os IDs ativos sem animais, com e sem Auth,
   inclusive 6 e 76; contas 15/22 devem continuar indisponíveis.

Visualizar um perfil legado não cria login, não atribui propriedade a outra
conta e não regulariza as adoções desse responsável. Essa atividade segue o
[plano de regularização](regularizacao_responsaveis_auth.md), sem vínculo por
coincidência de nome/e-mail ou reativação automática.

**Correção local validada; produção permanece sem alterações e ainda usa o filtro antigo.**
