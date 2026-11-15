# Ensaio final das migrações — 15/11/2026

## Veredito

**SQL 12 → SQL 15 → SQL 10 passaram no ensaio local com a cópia atualizada.
SQL 16 passou nas 20 verificações, em transação somente de leitura.**

Não foi identificado bloqueio funcional ou de autorização no escopo testado.
As migrações estão tecnicamente prontas para **solicitar autorização de instalação**,
condicionadas ao checklist operacional abaixo. Nenhuma instalação online foi feita.
Este resultado não substitui autorização explícita nem comprova rollback instantâneo
do serviço Supabase gerenciado.

## Ambiente e preservação

- Origem: backup externo `pre-migracao-20261115-014557`, já
  [validado por restauração](backup_restauracao_atualizado_2026-11-15.md).
- Imagem PostgreSQL `public.ecr.aws/supabase/postgres:17.11.0.019`, cluster novo
  sem inicialização automática do Supabase e sem copiar o ambiente de QA.
- Contêiner `ep-migration-rehearsal-mwhecx23-f4a4c2-db`, banco `entre_patas_rehearsal`.
- Rede interna e volume novos; zero portas publicadas; backup montado somente
  para leitura. Auth e PostgREST exclusivos do ensaio, com credenciais novas locais.
- Cópia inicial comprovada: **45 blocos COPY, 417 registros**, com fingerprints
  equivalentes ao backup. As três migrações não alteraram esses dados.
- Migrações executadas como `postgres`, com seus atributos originais NOSUPERUSER.
  A elevação temporária necessária ao restore foi revertida antes das migrações.
- Após as escritas fictícias, os registros originais de cliente, animal, adoção,
  questionário, Auth users e identities continuaram iguais ao backup.
- Os 19 contêineres preexistentes foram preservados; o QA continuou em execução.
  Apenas os cinco serviços/contêineres criados neste ensaio foram parados ao final,
  incluindo os da tentativa inicial de preparação. Volumes não foram apagados.

Nenhuma conexão à produção foi feita. Nenhum SQL ou arquivo Flutter foi alterado.
Os hashes dos dois backups e dos quatro SQLs permaneceram iguais.

## Resultados executados

| Teste | Resultado | Evidência |
| --- | --- | --- |
| Instalação 12 → 15 → 10 | PASSOU | Três COMMITs, preflights satisfeitos no snapshot restaurado |
| SQL 16 somente leitura | PASSOU | 20/20; repetido após os fluxos, sempre em `BEGIN READ ONLY` |
| Ensaio PostgreSQL/API | PASSOU | 94 asserções finais, nenhuma falha final; inclui preparação e verificações de catálogo |
| Perfil ativo sem Auth e sem animais | PASSOU | RPC de perfil e resumo: HTTP 200, uma linha, sem campos privados |
| Responsável após adoção do único animal | PASSOU | Perfil e resumo continuam retornando uma linha |
| Perfis inativos e chamadores inativos | PASSOU | Alvo inativo não retornado; chamador inativo recebe PT403 |
| Solicitação e bloqueio de duplicidade | PASSOU | Pedido criado; repetição HTTP 409/PT409 |
| Aprovação | PASSOU | Pedido Aceito e animal Adotado; nova aprovação e novo pedido bloqueados |
| Recusa e cancelamento | PASSOU | Estados finais corretos; animal recusado continua Disponível |
| Exclusão lógica | PASSOU | `ativo=false`, `imagem=null`; proprietário, status e histórico preservados |
| Histórico de pedido pendente excluído | PASSOU | Aprovação bloqueada; cancelamento continua permitido |
| Acesso anônimo/terceiros | PASSOU | RPCs protegidas negadas; consulta de pedido alheio PT404; listas limitadas aos participantes |
| Acesso privado direto | PASSOU | RLS oculta perfil alheio; tabela adoção e helpers internos sem acesso direto |
| Alterações diretas perigosas | PASSOU | UPDATE de ativo/status/proprietário e DELETE físico de animal negados |
| Edição/publicação legítimas | PASSOU | Operações do proprietário permitidas; edição/publicação para outro dono bloqueadas |
| Notificações | PASSOU | Listas da API contêm Aceito/Recusado/Cancelado e somente participações do chamador |
| Concorrência real | PASSOU | Três disputas em duas conexões PostgreSQL, com bloqueio observado por `pg_blocking_pids` |
| Definições instaladas | PASSOU | Dez corpos de função iguais aos SQLs; índices, trigger, overloads e grants complementares conferidos |
| Testes Flutter pertinentes | PASSOU | 148 testes de serviço/widgets com mocks; zero falhas |
| Testes SQL PGlite existentes | PASSOU | 69 testes; zero falhas e zero skips |
| Flutter analyze pertinente | PASSOU | Nove arquivos; zero erros, warnings ou infos |
| Teste Flutter Web no navegador com duas contas | NÃO EXECUTADO | Testes Flutter usaram mocks; a API real foi exercitada separadamente no clone |

Não somar os 20 itens do SQL 16 novamente às 94 asserções do ensaio: eles são
parte da validação de catálogo. As execuções Flutter e PGlite são baterias distintas.

### Concorrência comprovada

Foram usadas duas conexões PostgreSQL reais com papel `authenticated` e claims
das contas exclusivamente fictícias, após provar cadastro/login pela API Auth.
Não foram utilizadas credenciais de contas restauradas para executar operações.

1. Mesmo adotante e animal: a segunda conexão aguardou o lock, terminou PT409,
   e restou exatamente um pedido Aguardando.
2. Dois pedidos, duas aprovações: uma aprovação venceu, o outro pedido foi
   Recusado e a segunda chamada terminou PT409. Restou um único Aceito.
3. Exclusão antes de aprovação: a aprovação aguardou e terminou PT409; animal
   inativo e pedido preservado. O adotante conseguiu cancelar depois.

Ao final não havia dois aceites por animal, pares ativos duplicados ou aceite
associado a animal ainda Disponível.

### Problemas de preparação encontrados

A primeira preparação reutilizou um telefone fictício em duas contas. O gatilho
de cadastro respeitou `cliente_telefone_unique`, e a segunda criação falhou. A
fixture foi corrigida para usar telefones fictícios distintos, sem alterar a regra
do banco ou o aplicativo. As quatro contas seguintes cadastraram e autenticaram.

Também houve uma referência de catálogo ambígua no runner de diagnóstico
(SQLSTATE 42702), corrigida antes da repetição. Essas falhas de preparação foram
preservadas no histórico; não foram contabilizadas como aprovação do aplicativo.
Não houve falha pendente das migrações ou dos testes funcionais finais.

## Revisão das dependências e segurança

- SQL 12 preserva os wrappers INTEGER e seus retornos. Permite consultar alvos
  ativos sem Auth ou animais, exige chamador Auth ativo e não retorna contatos.
- SQL 15 identifica o dono por Auth, revalida propriedade e perfil, trava o animal
  e mantém o histórico. Não concede UPDATE de `ativo` e revoga DELETE direto.
- SQL 10 depende de Auth, tabelas/FKs/RLS e histórico compatível. Serializa as
  transições pelo animal e usa dois índices únicos como proteção adicional.
- SQL 12 e 15 independem do 10, mas a ordem ensaiada é adequada. SQL 05, 20 e 30
  não são pré-requisitos deste conjunto.
- Cada migração tem transação própria: falha no SQL 10 não desfaz SQL 12/15 já
  confirmados. A reaplicação do SQL 10 foi testada e abortou no preflight, sem
  alterar parcialmente dados ou objetos. Não reaplicar por tentativa.
- SQL 10 não define limites de espera; configurar limites de sessão e janela de
  manutenção antes de sua futura execução.

SQL 16 foi revisado como um único WITH/VALUES/SELECT com funções de catálogo/ACL,
sem RPCs de negócio ou comandos de escrita. Seus checks de nome não bastam para
provar toda a definição dos objetos. Por isso este ensaio conferiu adicionalmente:
corpos de funções, tabela/colunas/predicados dos índices, modo O/A e função/eventos
do trigger, ausência de overloads, TRUNCATE negado, USAGE de private e preservação
da RLS e das três políticas do questionário. Não foi necessário modificar SQL 16.

## Compatibilidade Flutter

Os contratos conferidos correspondem ao serviço atual:

| RPC | Parâmetros/retorno esperados |
| --- | --- |
| listar_minhas_adocoes | Sem parâmetros; array JSON |
| buscar_minha_adocao | p_adocao_id; objeto JSON |
| solicitar_adocao | p_animal_id; objeto JSON |
| responder_adocao | p_adocao_id e p_acao: aceitar/recusar/cancelar |
| buscar_perfil_publico / buscar_resumo_responsavel | p_cliente_id; lista de registros públicos |
| excluir_meu_animal | p_animal_id; objeto com id e ativo=false |

Nomes, argumentos e formatos foram confrontados com o Flutter, com os testes de
mock e com respostas reais do PostgREST local. Não foi encontrada incompatibilidade
que exija corrigir o código atual.

Comandos executados:

```powershell
flutter test --no-pub --reporter compact test/adocao_supabase_service_test.dart test/adocao_supabase_ui_test.dart test/adocao_fluxo_test.dart test/perfil_publico_supabase_service_test.dart test/perfil_publico_test.dart test/exclusao_animal_supabase_test.dart test/perfil_recarregar_test.dart

node --test --test-concurrency=1 test/adocao_supabase_sql_test.mjs test/perfis_publicos_supabase_sql_test.mjs test/exclusao_animal_supabase_sql_test.mjs

flutter analyze --no-pub lib/services/supabase_service.dart lib/controller/cliente_controller.dart lib/model/adocao.dart lib/view/animal/adocao.dart lib/view/animal/animaisCadastrados.dart lib/view/principal/notificacoes.dart lib/view/principal/perfil.dart lib/view/usuario/fichaPerfil.dart lib/view/core/usuario_resumo.dart
```

## Pendências antes da instalação/entrega

1. Cumprir o [checklist de instalação e recuperação](checklist_instalacao_sql12_15_10.md),
   obter autorização explícita e repetir os preflights no estado online atualizado.
2. Confirmar a recuperação no provedor e a custódia das configurações externas:
   a restauração lógica local não fornece secrets, SMTP, redirects, chaves ou um
   procedimento de administração gerenciada já testado.
3. Regularizar manualmente os responsáveis dos nove animais sem vínculo Auth,
   após confirmar identidade. Os perfis ativos podem ser exibidos, mas esses
   responsáveis não conseguem entrar e operar pedidos enquanto não regularizados.
   As migrações não criam vínculos nem reativam usuários automaticamente.
4. Executar o teste visual no Flutter Web com duas contas fictícias no ambiente
   autorizado: publicar → solicitar → aceitar/recusar/cancelar → notificações,
   perfil do responsável e exclusão lógica. Não foi declarado aprovado no navegador.
5. Commit, push e deploy continuam fora desta autorização e não foram realizados.

## Evidências e versões

Evidência externa sanitizada, sem senhas, tokens ou registros pessoais:

`pre-migracao-20261115-014557/ensaio-migracoes-2026-11-15T05-43-18-563Z-d60c88/resultado.json`.

| SQL | SHA-256 ensaiado |
| --- | --- |
| 12 | `8b7c1641f9d9d05ee66e81f4e99c10a137a1b725af561f534ab48eab1b7178c7` |
| 15 | `6d594baf132d4d9c7b53c5f917a7ba27f657ba870353b46f51419ac163202ac7` |
| 10 | `d2ff08f94169b92727ff807dfa25a45ae99b7e3c9c1a73b926cab7dee2e176a8` |
| 16 | `7c5310b590a51e65fa4878c191424d6d97dac537a0d9cc71b2c9195718cfb61e` |

O runner e os logs estão em `.dart_tool/`, ignorada pelo Git. Nesta rodada foram
criados apenas documentação e artefatos locais de validação; os SQLs, o código
Flutter, os backups e os ambientes anteriores não foram modificados.
