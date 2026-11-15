# Instalação das migrações em produção — 15/11/2026

## Resultado: concluída e validada

As migrações originais auditadas foram executadas REALMENTE no projeto
`cyaxnaflvnjnpryryorr`, na ordem SQL 12 → SQL 15 → SQL 10, com autorização
explícita do proprietário. As três transações tiveram COMMIT confirmado.
O SQL 16 foi executado após as três etapas e aprovou 20/20 verificações.
A conferência final terminou às 16:18:52 (America/Sao_Paulo).

| SQL | Arquivo original | Resultado | Exit code psql | COMMIT |
| --- | --- | --- | --- | --- |
| 12 | 12_corrigir_perfis_publicos_supabase.sql | SUCESSO | 0 | Confirmado às 16:16:37 |
| 15 | 15_corrigir_exclusao_animal_supabase.sql | SUCESSO | 0 | Confirmado às 16:16:49 |
| 10 | 10_migrar_adocoes_supabase.sql | SUCESSO | 0 | Confirmado às 16:17:04 |
| 16 | 16_verificar_correcoes_somente_leitura.sql | 20/20 aprovadas; somente leitura | 0 | Não aplicável |

Cada migração utilizou uma conexão psql separada. O executor exigiu código 0,
a resposta final COMMIT e pós-verificação somente de leitura antes da seguinte.
Não houve falha de execução, rollback ou resultado incerto nas três migrações.

## Identidade, segurança e integridade

- Login de conexão fixado e conferido como `postgres.cyaxnaflvnjnpryryorr`,
  host `aws-1-us-west-2.pooler.supabase.com`, porta 5432, banco `postgres`.
- O Session pooler autenticou como o papel backend `postgres`, conforme esperado.
- TLS `verify-full`, certificado original `prod-ca-2021.crt` e conexão SSL confirmados.
- Foi usado exclusivamente o passfile privado original; nenhuma senha foi impressa,
  registrada no relatório ou colocada em argumentos de processo.
- Passfile montado somente para leitura, copiado para tmpfs privado com modo 600.
- `ON_ERROR_STOP=1` em todas as execuções; locks limitados a 5s, comandos a 30s
  e transação ociosa a 60s. SET SESSION e guard conferiram os limites em cada conexão.
- As verificações de leitura e SQL 16 utilizaram default_transaction_read_only=on
  efetivamente conferido, além de BEGIN READ ONLY nas consultas agregadas.
- Os quatro SQLs foram montados somente para leitura e executados pelos arquivos
  originais, sem alterar seus conteúdos ou limites de transação.
- Os quatro arquivos originais de backup/revisão mantiveram os hashes registrados
  na restauração validada. Nenhum backup foi sobrescrito ou apagado.
- O projeto de recuperação `juqnompkixqltwjldzva` não foi acessado ou alterado.

## Conferência antes e depois

| Tabela | Antes | Depois | Resultado |
| --- | ---: | ---: | --- |
| public.cliente | 12 | 12 | Sem alteração |
| public.animal | 11 | 11 | Sem alteração |
| public.adocao | 2 | 2 | Sem alteração |
| public.questionario | 7 | 7 | Sem alteração |
| auth.users | 4 | 4 | Sem alteração |
| auth.identities | 4 | 4 | Sem alteração |
| public.recuperacao_senha | 0 | 0 | Sem alteração |

Além das contagens, os fingerprints SHA-256 dos registros das sete tabelas
acima permaneceram idênticos, sem expor registros individuais. Nenhuma
alteração concorrente nesses conjuntos foi encontrada entre os snapshots.
A sequência de adoções permaneceu em last_value=31, is_called=false.

A comparação final também aprovou 16 grupos estáveis de estrutura e estado:
tabelas, colunas, constraints, políticas, memberships, enums, comprimentos de
status, verificações de dados, totais por status, gatilhos Auth/perfil, metadados,
índices e políticas do questionário, FKs validadas e sequência de adoções.
As mudanças intencionais das migrações foram conferidas separadamente.

## Resultado completo do SQL 16

| Verificação original | Resultado |
| --- | --- |
| DELETE fisico de animal negado | PASSOU |
| Indices unicos de adocao presentes | PASSOU |
| Marca dos helpers SQL 12 presente | PASSOU |
| private.detalhe_publico_responsavel(integer) | PASSOU |
| private.resumo_responsavel(integer) | PASSOU |
| public._ep_adocao_cliente_atual() | PASSOU |
| public._ep_adocoes_json(bigint,bigint) | PASSOU |
| public._ep_proteger_status_adocao_animal() | PASSOU |
| public.buscar_minha_adocao(bigint) | PASSOU |
| public.buscar_perfil_publico(integer) | PASSOU |
| public.buscar_resumo_responsavel(integer) | PASSOU |
| public.excluir_meu_animal(bigint) | PASSOU |
| public.listar_minhas_adocoes() | PASSOU |
| public.responder_adocao(bigint,text) | PASSOU |
| public.solicitar_adocao(bigint) | PASSOU |
| RLS de cliente, animal e adocao mantida | PASSOU |
| Sem overload ambiguo de RPC de perfil ou exclusao | PASSOU |
| Tabela adocao sem DML direto de clientes | PASSOU |
| Trigger protetor de status presente | PASSOU |
| UPDATE direto de animal.ativo negado | PASSOU |

## Verificações adicionais após cada COMMIT e ao final

- SQL 12: corpos das duas funções private idênticos aos originais auditados,
  proprietário privilegiado, search_path vazio, marcas SQL12 v1 e USAGE corretos.
- SQL 15: corpo da função de exclusão idêntico ao original, execução permitida
  a authenticated e negada a anon; DELETE físico e UPDATE direto de ativo negados.
- SQL 10: corpos das sete funções idênticos aos originais; índices únicos válidos,
  prontos e vinculados à tabela adocao; trigger de proteção habilitado e correto.
- Conferência complementar: índices ep_adocao_em_andamento_unica e
  ep_adocao_aceita_unica com colunas e predicados esperados; trigger BEFORE
  INSERT/UPDATE de status apontando à função auditada; TRUNCATE de adocao
  negado a anon/authenticated.
- RLS permaneceu habilitada; permissões dos endpoints e helpers passaram no SQL16.
- Os arquivos auditados e o backup continuaram íntegros em todas as etapas.

## Ajustes somente no executor local, anteriores às migrações

As tentativas anteriores não iniciaram migrações. O campo de senha foi corrigido
pelo proprietário. Nesta retomada foram corrigidos somente problemas do executor:

1. PGOPTIONS não refletia os limites exigidos no pooler; passou-se a aplicar
   SET SESSION e validar os valores na mesma conexão, sem alterar configurações
   permanentes do banco, papéis ou SQLs auditados.
2. O envio da consulta agregada precisava do ponto e vírgula antes de COMMIT;
   a consulta falhou com SQLSTATE 42601 somente em leitura, antes das migrações.
3. As projeções históricas table_grants/column_grants estavam vazias por terem
   sido coletadas como supabase_read_only_user. A conexão postgres as enxerga.
   Essas duas projeções foram substituídas pela comparação de permissões
   efetivas ao backup: 9 funções, 10 políticas, 8 combinações de permissões de
   tabela, 72 linhas de permissões de colunas e RLS de 4 tabelas. Todos passaram;
   os outros 14 grupos de metadados pré-instalação permaneceram estritos.

Nenhuma dessas diferenças foi corrigida por alterações automáticas nos dados ou
permissões da produção. Somente após o preflight final aprovado iniciou-se SQL 12.
Não foram repetidas migrações, nem ignorados erros de execução dos arquivos.

## Pendências e limites do resultado

- Permanecem nove animais de dois responsáveis legados sem vínculo Auth.
  Nenhum vínculo foi criado e nenhuma conta foi reativada automaticamente.
  A regularização continua dependendo de comprovação de titularidade; operações
  que exigem responsável autenticado continuam sujeitas a essa limitação.
- Esta execução validou instalação, catálogo, permissões e preservação de dados.
  Não fez novos testes de escrita de adoções, criação de contas ou login com
  contas reais no original. Não comprova por si só o fluxo visual completo no app.
- Ainda convém confirmar no aplicativo a visualização dos perfis, a exclusão lógica
  de animal próprio e o fluxo de solicitações/notificações com usuários autorizados.
  Os ensaios locais anteriores não foram repetidos desnecessariamente nesta etapa.
- Nenhum commit Git, push ou deploy foi feito. A URL do Flutter não foi alterada.

## Evidências locais

- Executor e registro estruturado: `.dart_tool/instalacao_producao_guarded.mjs`
  e `.dart_tool/instalacao_producao_20261115.json`.
- Estado final: `PRODUCTION_INSTALLATION_VALIDATED`.
- Registro estruturado conserva COMMITs, horários UTC, resultados SQL16, hashes
  dos arquivos e fingerprints agregados antes/depois; sem valores de senha.

### Hashes SHA-256 dos SQLs executados

| Arquivo | SHA-256 |
| --- | --- |
| 12_corrigir_perfis_publicos_supabase.sql | 8b7c1641f9d9d05ee66e81f4e99c10a137a1b725af561f534ab48eab1b7178c7 |
| 15_corrigir_exclusao_animal_supabase.sql | 6d594baf132d4d9c7b53c5f917a7ba27f657ba870353b46f51419ac163202ac7 |
| 10_migrar_adocoes_supabase.sql | d2ff08f94169b92727ff807dfa25a45ae99b7e3c9c1a73b926cab7dee2e176a8 |
| 16_verificar_correcoes_somente_leitura.sql | 7c5310b590a51e65fa4878c191424d6d97dac537a0d9cc71b2c9195718cfb61e |
