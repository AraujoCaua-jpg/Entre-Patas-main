# Adoções no Supabase: revisão e instalação

O Flutter utiliza RPCs autenticadas para solicitar, cancelar, aprovar e recusar
adoções e consultar pedidos/notificações. O PHP em `backend/adocoes.php` foi
preservado como referência das regras anteriores, não como dependência do app.

## Estado conhecido

Atualização da inspeção somente leitura: veja
[revisão do SQL 10 para produção](revisao_sql10_producao.md). A estrutura online
foi inspecionada, as quatro RPCs de adoção continuam ausentes e a instalação
permanece bloqueada pelas pendências de backup e integração descritas no relatório.

As três falhas de integração foram posteriormente corrigidas **somente no local**;
os SQLs 12/15, a revisão do SQL 30 e seus testes estão em
[Correções finais](correcoes_finais_sql10.md). O SQL 20 não é pré-requisito dos
SQLs 12/15/30 corrigidos; sua instalação e recuperação precisam de revisão separada.

- O SQL `10_migrar_adocoes_supabase.sql` foi instalado e testado no Supabase
  **local** restaurado, inclusive com duas aprovações concorrentes.
- **O SQL 10 ainda não foi instalado em produção.** Um build que aponta para o
  projeto online não comprova o funcionamento das adoções nesse ambiente.
- Nesta preparação não foram executados SQLs, migrações ou alterações no servidor.
- Os testes PGlite em `test/adocao_supabase_sql_test.mjs` verificam regras e
  permissões em memória. Não substituem a validação do esquema real, concorrência
  entre conexões ou configuração remota.

## Antes de instalar em produção

1. Confirmar backup recuperável e procedimento de restauração. Não presumir que
   o teste de restauração local comprove a existência de um backup atual de produção.
2. Revisar o arquivo original `docs/sql/00_inspecionar_adocoes_supabase.sql` e
   conferir estrutura, RLS, grants, índices, valores de status, duplicações e
   vínculos `auth_user_id` no ambiente de destino, somente com leitura.
3. Comparar as evidências com os preflights do **arquivo original**
   `docs/sql/10_migrar_adocoes_supabase.sql`. Revisar locks, índices, triggers,
   funções e permissões com o responsável pelo banco.
4. Planejar instalação separada, em janela adequada, com autorização explícita.
   Não incluir a migração no build Flutter/Vercel nem executar `db push`/`db reset`.
5. Após uma instalação aprovada, validar com contas fictícias autorizadas:
   solicitação, duplicidade, cancelamento, aprovação, recusa, notificações,
   isolamento entre participantes, usuário anônimo e aprovação concorrente.

Manter a RLS ativada. Nunca colocar credenciais administrativas no app para
contornar uma permissão ou uma RPC ausente. Solicitações antigas sem vínculo
Auth precisam de tratamento separado; não apagar esses registros.

## Dependências relacionadas

- `05_vincular_perfil_auth_supabase.sql`: valida o vínculo e a criação de perfil;
  não cria um banco completo a partir do zero.
- `20_excluir_conta_supabase.sql`: depende das estruturas do SQL 10. A função
  `supabase/functions/excluir-conta/index.ts` também precisa estar instalada e
  configurada no servidor para exclusão de conta.
- `12_corrigir_perfis_publicos_supabase.sql`: corrige os perfis independentemente
  do SQL 10, mantendo assinaturas e privacidade.
- `15_corrigir_exclusao_animal_supabase.sql`: fornece exclusão lógica autorizada,
  sem UPDATE direto de ativo e sem DELETE físico dos clientes.
- `30_migrar_pesquisa_publica_supabase.sql`: a versão revisada exige SQLs 10 e 12;
  SQL 20 é independente. Fornece pesquisa com contatos privados mascarados.

Preservar todos os arquivos e revisar cada instalação separadamente. Nenhuma
etapa desta documentação constitui autorização de execução em produção.

Evidências: [QA local](qa_entrepatas_local_2026-11-14.md),
[correções Web](qa_entrepatas_correcao_web_2026-11-14.md) e
[preparação do repositório](preparacao_producao.md).
