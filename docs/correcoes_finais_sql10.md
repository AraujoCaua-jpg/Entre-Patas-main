# Correções finais de perfis e exclusão lógica — Entre Patas

> Ampliação em 15/11/2026: a falha de quase todos os perfis foi comparada com
> IDs reais em produção somente leitura e recebeu regressões explícitas de
> legados sem Auth/animais e tratamento Flutter. Veja
> [Investigação dos perfis públicos](investigacao_perfis_publicos.md).
> As contagens abaixo preservam a rodada anterior; produção continua sem os scripts.

Rodada posterior à auditoria de 110 aprovações e três falhas, em 14/11/2026.

## Resultado e limites

**As três falhas foram corrigidas e validadas localmente.** Não houve acesso
ao Supabase de produção nesta rodada, alteração de dados reais, vínculo Auth
automático, reativação de usuários, commit, push ou deploy.

Os SQLs 12, 15 e 30 revisado foram instalados apenas no container
`supabase_db_EntrePatas-Restore-Test`. O SQL 10 já estava instalado nesse ambiente
e não foi reaplicado. Seu arquivo original continua inalterado.

O frontend Web compilou em release com a configuração pública do Supabase online.
Isso confirma a compilação, **não o funcionamento das correções no online**:
os scripts ainda não foram instalados na produção. A instalação permanece
bloqueada por backup atual/recuperação e autorização explícita.

## 1. Causas exatas e correções

### Resumo e perfil depois da adoção

As funções `private.resumo_responsavel(integer)` e
`private.detalhe_publico_responsavel(integer)` condicionavam a consulta de
terceiros à existência de um animal ativo com status Disponível. Depois da
aprovação do único animal, o perfil deixava de satisfazer essa condição.

O SQL 12 mantém as assinaturas INTEGER e os wrappers públicos existentes,
substituindo apenas os helpers privados. Agora exige:

- Auth válido e exatamente um perfil ativo do chamador.
- Perfil de destino ativo, independentemente da existência/status de animais.
- Projeção pública restrita: nome, usuário, imagem e, no detalhe, sobrenome,
  município/UF e indicação de lar. Sem e-mail, telefone, endereço ou Auth ID.

Contas inativas, chamadores sem perfil ativo e anônimos permanecem bloqueados.
Não são alteradas policies, registros ou vínculos. O script aborta caso encontre
overloads, assinaturas, retornos, owners ou wrappers diferentes da base auditada;
não usa DROP/CASCADE para substituir versões divergentes.

### Exclusão lógica

O Flutter enviava PATCH em `animal.ativo` e `imagem`, mas authenticated só
possuía UPDATE em colunas editáveis como nome/imagem; `ativo` não estava concedido.

O SQL 15 cria `excluir_meu_animal(p_animal_id bigint)`, retornando JSON
`{id, ativo:false}`. A RPC identifica o perfil pelo Auth, exige conta ativa,
filtra propriedade, trava o animal próprio e revalida o perfil. Atualiza somente
`ativo=false` e `imagem=null`; preserva ID, responsável, status e adoções.
Repetir a exclusão de um animal próprio já inativo é seguro.

Não é concedido UPDATE em `ativo`. DELETE físico direto é revogado dos clientes.
A RPC é SECURITY DEFINER com owner privilegiado e `search_path=''`, EXECUTE
somente a authenticated, e a RLS permanece habilitada. Os demais grants de
edição não são ampliados. Permissões herdadas incompatíveis abortam a instalação.

O serviço Flutter agora chama apenas essa RPC, confere o ID e `ativo=false`,
descarta respostas após troca/logout e só permite notificação de sucesso após
confirmação. O filtro `ativo=true` foi acrescentado à listagem dos próprios
animais para evitar que o excluído reapareça ao atualizar. A ficha individual
e o histórico continuam sujeitos às permissões existentes. Nenhum layout foi alterado.

## 2. SQL 30 e serviços Flutter

O SQL 30 original tinha dois problemas de compatibilidade: tentava trocar o
retorno de pesquisa `id integer` por bigint e criar versões bigint das RPCs de
perfil, gerando erro de retorno/possíveis overloads ambíguos. Também passava a
divulgar contatos de lares que a produção atualmente mascara.

A versão revisada:

- Exige SQLs 10 e 12; SQL 20 não é uma dependência real desse script.
- Preserva os wrappers de perfil/resumo INTEGER corrigidos pelo SQL 12.
- Mantém `buscar_clientes_publicos(text)` com ID integer e os mesmos campos.
- Mascara e-mail, telefone e endereço para todos os perfis, inclusive lares.
- Preserva `ep_buscar_animais` e seus filtros; nenhuma definição conflitante
  de perfil bigint é criada.

As chamadas Flutter de perfil/resumo/pesquisa de usuários continuam com os
mesmos nomes e parâmetros. O Dart já interpreta IDs recebidos como números.
`ep_animais_perto_de_mim()` continua sendo a chamada do Flutter para localização;
ela já existe na base auditada. O SQL 30 não a substitui nem precisa ser
instalado para resolver as três falhas desta rodada.

## 3. Testes executados

Os números abaixo são somente a rodada final de cada bateria, sem somar
reexecuções de diagnóstico ou a auditoria anterior.

| Bateria | Passaram | Falharam | Ignorados | Evidência local |
| --- | ---: | ---: | ---: | --- |
| Flutter completo | 168 | 0 | 2 | `.dart_tool/correcoes_finais_flutter.jsonl` |
| SQL em PGlite, cinco arquivos | 69 | 0 | 0 | `.dart_tool/correcoes_finais_sql.log` |
| REST Supabase local | 39 | 0 | 0 | `.dart_tool/correcoes_finais_rest_results.json` |
| SDK/controller/widgets contra API local | 12 | 0 | 0 | `.dart_tool/correcoes_finais_sdk.log` |
| **Total das quatro baterias** | **288** | **0** | **2** | Casos de diferentes níveis, sem duplicar reexecuções |

Os dois ignorados são condicionais à configuração de sincronização de e-mail;
não foram considerados aprovados. O script histórico de reprodução das três
falhas foi preservado como evidência anterior, sem ser alterado para fingir aprovação.

Verificações complementares:

- `flutter analyze --no-pub`: zero erros, zero warnings e 113 infos existentes.
  Exit 1 apenas pelos infos; `.dart_tool/correcoes_finais_analyze.log`.
- Build Web release: exit 0, saída `build/web`, endpoint online e configuração
  pública conferidos; `.dart_tool/correcoes_finais_build.log`.
- SQL 16 de catálogo no local: **20 verificações aprovadas**, nenhuma reprovada;
  `.dart_tool/correcoes_finais_catalogo.csv`.
- Instalação/reaplicação idempotente dos SQLs 12/15/30 no local: sem erros.
  Arquivos enviados como bytes UTF-8, preservando filtros e mensagens acentuadas.
- `git diff --check`: passou, exit 0; arquivos novos também conferidos sem
  espaços no fim das linhas.

### Cobertura importante

- Reprodução das funções anteriores com dados fictícios → único animal Adotado
  → SQL 12 mantém resumo/perfil; perfis ativos sem animais também são consultáveis.
- Alvos/chamadores inativos, ausência de Auth, anônimo, IDs inválidos e privacidade
  de lares; wrappers preservados, sem novos overloads.
- Exclusão própria/idempotente, negação a terceiros, status/proprietário/histórico
  preservados, imagem nula, registro mantido e removido da listagem própria.
- PATCH direto em ativo e DELETE físico negados; edição de metadados permitida
  conforme grants existentes; transação aborta por configuração insegura.
- SQL 15 funciona antes e depois do SQL 10. SQL 30 revisado aplica sem 42P13 e
  retorna animais Disponível com os filtros esperados.
- Solicitação/cancelamento/recusa/aceite/notificações, consulta de participantes,
  isolamento de terceiros e duas aprovações simultâneas: 200/409, um só aceite.
- Exclusão simultânea à aprovação: estado final consistente, histórico mantido,
  sem deadlock observado na rodada. Não equivale a teste de carga prolongado.

Somente fixtures novas foram modificadas no servidor local. Rodada final: perfis
99/100/101, animais REST 47/49/50, animal SDK 48 e pedidos 59 a 65. A primeira
rodada de diagnóstico criou perfis 96/97/98, animais 43 a 46 e pedidos 52 a 58.
Os perfis QA 98/101 foram desativados para testar negação de acesso e permaneceram
inativos; nenhum usuário foi reativado. Não houve limpeza de registros restaurados.

Os testes de API/SDK usam transporte limitado a `127.0.0.1:54321`, credenciais
fictícias mantidas em memória e logs sanitizados. Testes SQL usam memória sem
rede. Não houve execução do aplicativo contra produção para testar gravações.

## 4. Scripts, pré-requisitos e ordem segura

### Dependências reais do SQL 10

Auth, criação de perfil, vínculo único UUID, perfil ativo, tabelas cliente/animal/
adocao, tipos/status compatíveis, PK/FKs validadas, RLS e sequência íntegra são
pré-requisitos estruturais. A auditoria anterior os conferiu no snapshot online.
Repetir leitura antes da janela: não presumir que permaneçam iguais.

SQLs 12 e 15 são correções independentes do SQL 10 e necessárias à entrega dos
fluxos correspondentes. SQL 10 fornece as quatro RPCs de adoção e a listagem
usada pelas notificações. SQL 05 (sincronização de e-mail) e SQL 20/Edge Function
(exclusão de conta) são revisões separadas; não instalar automaticamente.

### Ordem proposta, condicionada a autorização

1. **Backup atual e restauração isolada aprovados.** Ver procedimento abaixo.
2. SQLs 00/01 somente leitura; confirmar schema, assinatura INTEGER, ACL/RLS,
   estados, vínculos, índices e sequência no ambiente de destino.
3. SQL **12** — corrigir helpers de perfil/resumo, com pre/postflight.
4. SQL **15** — instalar exclusão lógica segura e restringir DELETE direto,
   com pre/postflight. Instalar antes de publicar o Flutter que usa a nova RPC.
5. SQL **10 original** — instalar uma única vez, somente após revisão/autorização;
   não reaplicar se já existir. Continua com SHA-256
   `D2FF08F94169B92727FF807DFA25A45AE99B7E3C9C1A73B926CAB7DEE2E176A8`.
6. SQL **16**, somente leitura — todas as verificações devem retornar true.
7. Testes autorizados no destino com duas contas/animal fictício novo; depois
   conferir perfil/resumo após aceite e exclusão lógica/histórico.
8. Só então revisar a publicação do frontend. SQL **30 revisado é opcional**
   para estas correções e demanda autorização própria se sua pesquisa RPC for instalada.

Não há executor automático de produção. O build Flutter/Vercel não aplica SQL.
As correções são transacionais e abortam divergências antes de prosseguir.
Em erro antes do COMMIT, confirmar rollback. Depois do COMMIT, suspender novas
operações e preparar reversão específica/recuperação aprovada, sem abrir grants,
apagar histórico ou restaurar cegamente um backup por cima de dados novos.

## 5. Nove animais sem responsável autenticado

Essa é a contagem do último snapshot auditado; não foi refeita leitura de
produção nesta rodada. Nove animais não significam nove pessoas. Nenhum perfil,
animal ou pedido real foi vinculado, reatribuído ou reativado.

Instalar as RPCs não dará acesso aos responsáveis sem Auth. É necessário
inventário privado por perfil, prova de identidade/propriedade, consentimento e
reconciliação individual que preserve cliente.id, animais e adoções. Não casar
por e-mail/nome nem repetir cadastro sem revisar o trigger, pois ele pode criar
perfil novo ou colidir com unicidades do legado. Plano completo em
[Regularização dos responsáveis](regularizacao_responsaveis_auth.md).

Para a demonstração local, usar contas próprias vinculadas e animais fictícios
novos. Isso não representa regularização dos registros antigos no online.

## 6. Backup e recuperação: pendência mantida

Existe um procedimento documentado em
[Backup e recuperação](backup_recuperacao_supabase.md). Ele exige conexão
PostgreSQL já autorizada, PGPASSFILE externo, TLS, pg_dump consistente em modo
somente leitura, conferência de escopo/hashes e restauração em instância nova
isolada, com validação de Auth, perfis, RLS, grants, funções, sequências e API.

**O procedimento ainda não foi executado e aprovado com um backup atual.** Os
dumps existentes têm horários diferentes e não representam o estado mais recente;
o último inventário oficial não confirmou ponto recuperável/PITR disponível.
Não foi criado um novo dump pelo CLI para evitar o caminho que cria login
temporário na ausência de senha. Não foram alteradas credenciais.

Portanto: **bloqueios funcionais corrigidos localmente; produção ainda bloqueada
por backup/restauração, regularização operacional dos dados legados e autorização.**
Nenhuma instalação de produção é recomendada antes de cumprir esse requisito.

## 7. Arquivos alterados nesta rodada

| Arquivo | Motivo |
| --- | --- |
| `lib/services/supabase_service.dart` | RPC de exclusão, tratamento seguro e filtro de ativos na listagem própria. |
| `docs/sql/12_corrigir_perfis_publicos_supabase.sql` | Correção dos helpers, com privacidade/status e assinaturas preservadas. |
| `docs/sql/15_corrigir_exclusao_animal_supabase.sql` | RPC autorizada e idempotente; sem UPDATE direto em ativo nem DELETE físico. |
| `docs/sql/16_verificar_correcoes_somente_leitura.sql` | Verificações de catálogo pós-instalação, sem dados pessoais. |
| `docs/sql/30_migrar_pesquisa_publica_supabase.sql` | Compatibilidade INTEGER, dependências reais e contatos mascarados. |
| `test/exclusao_animal_supabase_test.dart` | 25 regressões de transporte, sessão, erros e listagem própria. |
| `test/exclusao_animal_supabase_sql_test.mjs` | 26 casos de autorização, integridade, preflights e ordem de instalação. |
| `test/perfis_publicos_supabase_sql_test.mjs` | 12 casos de perfil, privacidade, assinaturas e SQL 30. |
| `test/support/perfis_publicos_producao.sql` | Definições anteriores para reprodução, sem registros ou credenciais. |
| `docs/backup_recuperacao_supabase.md` | Procedimento e critérios de aprovação de recuperação. |
| `docs/regularizacao_responsaveis_auth.md` | Processo individual sem vínculos/reativação automáticos. |
| `docs/correcoes_finais_sql10.md` | Este relatório. |
| `README.md`, `docs/revisao_sql10_producao.md`, `docs/adocoes_supabase.md`, `docs/preparacao_producao.md` | Links/status e dependências atualizados, histórico preservado. |

`pubspec`, assets, layouts e o SQL 10 não foram alterados. Outros diffs existentes
no workspace foram preservados. Runners/evidências de API ficaram em `.dart_tool`
ignorado; os backups externos não foram adicionados ao repositório.

## 8. Antes da apresentação/publicação

- [ ] Cumprir os requisitos de backup/instalação autorizada para usar o online.
- [ ] Abrir o build no navegador e confirmar visual e navegação da versão final.
- [ ] Duas contas: publicar, solicitar, recusar/reenviar/aceitar e consultar histórico.
- [ ] Conferir perfil/resumo após último animal adotado e exclusão lógica sem reaparecer.
- [ ] Logout/troca de contas sem dados anteriores; contas inativas sem acesso.
- [ ] Revisar os arquivos novos junto dos demais diffs antes do futuro commit da equipe.

Os testes de navegador/destino acima não foram declarados aprovados por esta rodada.
