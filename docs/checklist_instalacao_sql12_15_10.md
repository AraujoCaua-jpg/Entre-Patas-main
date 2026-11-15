# Checklist condicionado — SQL 12 → 15 → 10 → 16

Este documento **não autoriza execução em produção**. O
[ensaio isolado de 15/11/2026](ensaio_final_migracoes_2026-11-15.md) passou, mas cada
item operacional precisa ser confirmado antes da instalação online.

Procedimento para um destino novo e limites ainda não demonstrados:
[Plano de recuperação no Supabase gerenciado](plano_recuperacao_supabase_gerenciado.md).

Atualização: [restauração gerenciada comprovada](recuperacao_gerenciada_2026-11-15.md)
no projeto exclusivo `juqnompkixqltwjldzva`. Nenhuma migração foi executada no original.

Conferência atual do original, somente leitura:
[pré-instalação de 15/11/2026](pre_instalacao_original_2026-11-15.md).
Compatibilidade e fingerprints conferidos; a escrita continua sem autorização.

## Antes de solicitar a instalação

- [ ] Aprovar os arquivos originais e conferir os quatro hashes registrados no
  relatório. Não usar SQL copiado de Markdown, nem instalar SQL 30 como substituto.
- [ ] Confirmar que o backup continua atual para o momento da instalação e que
  seus dois arquivos permanecem externos e protegidos. Se houve novas gravações,
  avaliar uma nova captura e seu ensaio antes da janela.
- [x] Comprovar restauração seletiva em um destino Supabase gerenciado: conexão,
  permissões, dados, Auth e segurança validados no projeto de recuperação.
- [ ] Revalidar operador, destino e credenciais numa futura recuperação; não
  reproduzir a elevação local de SUPERUSER em produção. O destino atual ainda
  precisa das configurações externas para substituir o serviço original completo.
- [ ] Preservar por canal privado configurações Auth, redirects, SMTP/OAuth,
  chaves/secrets, funções externas e dependências de imagens. Senhas de papéis
  não constam de roles.sql e precisarão de configuração segura no destino.
- [ ] Registrar aprovação explícita para instalar **SQL 12, SQL 15 e SQL 10**,
  executar as verificações de leitura e, separadamente, eventuais testes de escrita
  online com contas fictícias. Sem aprovação, manter somente revisão local.

## Preflight na janela autorizada

- [ ] Reexecutar as inspeções somente de metadados/contagens previstas nos SQLs
  00 e 01. Não publicar nomes, contatos, tokens ou registros individuais.
- [ ] Confirmar tipos, FKs validadas, RLS, grants e os quatro contratos INTEGER
  existentes de perfil, sem overloads divergentes.
- [ ] Confirmar zero duplicidades de Auth, pedidos ativos por par ou aceites por
  animal; histórico sem status/campos incompatíveis ou inconsistência Aceito/Adotado.
- [ ] Confirmar que os índices/trigger do SQL 10 ainda não existem. Se existirem,
  inspecionar definições e estado da instalação; não executar novamente por tentativa.
- [ ] Conferir a pendência dos responsáveis sem Auth. Não criar vínculos, reativar
  contas ou apagar solicitações automaticamente. Planejar regularização verificada.
- [ ] Confirmar acesso administrativo apropriado e o cliente Flutter coordenado
  com as novas RPCs. SQL 15 revoga DELETE direto de animal; clientes antigos que
  ainda usarem essa operação precisarão ser atualizados.
- [ ] Planejar janela sem gravações concorrentes. Configurar e conferir limites
  de sessão para locks e execução do SQL 10; ele não define seus próprios limites.
  Definir tempo e critério de interrupção antes de começar.

## Instalação, uma etapa por vez

- [ ] Executar o original `12_corrigir_perfis_publicos_supabase.sql` e confirmar COMMIT.
- [ ] Executar o original `15_corrigir_exclusao_animal_supabase.sql` e confirmar COMMIT.
- [ ] Executar o original `10_migrar_adocoes_supabase.sql` uma única vez e confirmar COMMIT.
- [ ] Interromper no primeiro erro. Cada arquivo tem transação independente:
  rollback do SQL 10 não desfaz SQL 12/15 já confirmados. Se a conexão cair ou o
  COMMIT ficar incerto, inspecionar o catálogo antes de qualquer repetição.
- [ ] Executar `16_verificar_correcoes_somente_leitura.sql` em transação de leitura:
  esperar **20/20 aprovadas**, sem tratar esse resultado como teste funcional completo.

## Pós-verificações complementares

- [ ] Conferir corpos, retornos, nomes de parâmetros, owner, SECURITY DEFINER/INVOKER,
  search_path, grants efetivos e ausência de overloads das RPCs revisadas.
- [ ] Conferir `pg_get_indexdef`: dois índices únicos válidos em `adocao`, com
  colunas e predicados Aguardando/Aceito e Aceito conforme os originais.
- [ ] Conferir `pg_get_triggerdef`: BEFORE INSERT OR UPDATE OF status, na tabela
  animal, por linha, função esperada e modo normal O/A; nome isolado não basta.
- [ ] Conferir RLS de cliente, animal, adoção e questionário; preservar as políticas
  do questionário e seus dados. Confirmar ausência de SELECT/DML/TRUNCATE direto
  em adoção e de DELETE físico/UPDATE de ativo/status/proprietário no animal.
- [ ] Confirmar USAGE necessário em private, sem expor esse schema no PostgREST.
  Helpers internos não devem ser endpoints executáveis pelo usuário.
- [ ] Confirmar que os perfis públicos não retornam email, telefone, endereço ou
  auth_user_id; alvo inativo fica oculto; chamador anônimo/inativo é negado.

## Prova funcional autorizada e entrega

- [ ] Usar somente contas e animais fictícios identificados, sem operar pedidos reais.
- [ ] No Flutter Web, testar duas contas: perfil, publicação, solicitação, recebimento,
  aprovação, recusa, cancelamento e atualização das notificações.
- [ ] Confirmar perfil/resumo após adoção do único animal e perfil ativo sem animais.
- [ ] Confirmar exclusão lógica e histórico; edição/publicação legítimas continuam
  funcionando e terceiros não conseguem alterar ou consultar informações privadas.
- [ ] Conferir build/publicação e configurações da URL/chave pública em etapa
  separada. Somente após autorização realizar commit, push ou deploy.

## Se houver falha

- [ ] Suspender as próximas etapas e gravações pertinentes; guardar evidências
  sanitizadas e identificar quais transações realmente confirmaram.
- [ ] Preferir uma correção pontual revisada quando preservar dados for seguro;
  não remover RPCs, grants, índices ou triggers por tentativa.
- [ ] Se for necessária recuperação, restaurar primeiro em destino novo autorizado,
  com as dependências gerenciadas e configurações privadas apropriadas. Repetir
  checks de dados, owners, ACL/RLS, integridade e Auth antes de propor o corte.
- [ ] Preservar e reconciliar gravações posteriores ao backup. Não sobrescrever
  a produção com o snapshot antigo nem perder novos pedidos para reverter DDL.
- [ ] Exigir aprovação explícita do plano de reversão/corte. A restauração local
  validada é evidência de recuperabilidade lógica, não uma autorização de rollback.
