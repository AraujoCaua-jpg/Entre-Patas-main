# Backup e recuperação — resultado de 15/11/2026

> Histórico: este documento trata dos arquivos antigos. Um backup atualizado
> foi posteriormente restaurado e validado em outro cluster isolado, inclusive
> permissões. Consulte [Restauração do backup atualizado](backup_restauracao_atualizado_2026-11-15.md)
> para o resultado atual, sem interpretar o veredito abaixo como avaliação da cópia nova.

## Veredito

**BLOQUEADO para instalar as migrações. Não existe backup atualizado e recuperável
certificado por esta rodada.**

Foi realizado um ensaio real de restauração dos arquivos antigos em containers
novos isolados. Os dados foram recuperados e uma conta fictícia autenticou e
gerou perfil. Porém, a cópia é antiga, depende de uma base managed local e a
equivalência das permissões não passou. Não foi declarada recuperação completa.

Nenhuma alteração no Supabase online, criação de login temporário, migração,
reset de senha, commit, push ou deploy foi executada. Os sete backups originais
não foram sobrescritos e seus hashes foram conferidos novamente ao final.

## 1. Backups existentes e acesso disponível

Os arquivos permanecem em `EntrePatas-Backups` no diretório pessoal, fora do
repositório. UTF-8, terminadores COPY, tamanhos e SHA-256 foram conferidos sem
exibir registros pessoais ou credenciais.

| Arquivo | Bytes | Função/constatação |
| --- | ---: | --- |
| `schema.sql` | 24.165 | Cinco tabelas públicas, nove funções public/private, dez policies, índices/FKs e extensões. |
| `data.sql` | 44.507 | 40 COPYs: 26 Auth, cinco public e nove Storage; também define sequências. |
| `auth-data.sql` | 35.995 | Export adicional de Auth; não foi aplicado junto com data.sql, para evitar duplicações. |
| `public-data.sql` | 6.617 | Export público separado; preservado sem reaplicação. |
| `public-data-pre-producao.sql` | 6.617 | Export público mais recente encontrado, mas ainda com dez animais. |
| `roles.sql` | 297 | Apenas configura timeouts de três papéis; não recria todos os roles/memberships. |
| `auth-trigger.sql` | 141 | Trigger de criação de perfil; aplicado por último no ensaio. |

As cópias têm horários diferentes. Não foram tratadas como um snapshot atual e
coordenado. No export restaurado há dez animais; a consulta atual de produção
confirmou onze.

O usuário confirmou que não existe PGPASSFILE configurado. Também não foram
encontrados PG*/DSN de conexão, pgpass padrão ou senha no metadado de pooler.
Ferramentas PostgreSQL nativas não estão no PATH, embora a imagem Docker local
tenha pg_dump/pg_restore compatíveis. O impedimento principal é a credencial
PostgreSQL preexistente, não a autorização para a tarefa.

O token Management já disponível permite SELECTs read-only e listagem de metadados,
mas não equivale a uma conexão libpq utilizável por pg_dump. O CLI 3.1.0 revisado
pode criar um login temporário privilegiado quando `db dump --remote`, inclusive
`--dry-run`, é usado sem senha. Esse caminho não foi executado.

A nova listagem oficial retornou **zero backups identificados**, PITR desativado
e WAL-G habilitado. WAL-G habilitado, sem ponto recuperável listado, não é prova
de backup disponível. Não foram inventados IDs nem iniciados downloads/restores
de backup remoto. Exportar respostas JSON de consulta tampouco foi apresentado
como um dump completo.

## 2. Leituras feitas na produção

Todas as consultas usaram o projeto explícito e `--read-only`, ou endpoints GET
de metadados. O servidor confirmou `transaction_read_only=on`.

| Item | Resultado atual, sem conteúdo pessoal |
| --- | --- |
| PostgreSQL | 17.11 |
| public.cliente | 12 registros |
| public.animal | 11 registros |
| public.adocao | 2 registros |
| public.questionario | 7 registros |
| auth.users / auth.identities | 4 / 4 registros |
| Storage buckets / objects | 0 / 0 |
| Edge Functions instaladas | 0 |
| Auth público | Cadastro habilitado, provedor e-mail, confirmação automática |
| Imagens de animais | 11 referências HTTP(S) externas; URLs não divulgadas |
| Imagens de perfis | 12 campos vazios |

Nenhuma RPC de negócio foi chamada na produção. Não houve leitura/exposição
de SMTP, segredos OAuth, tokens de usuários, senhas ou corpos de templates.

## 3. Restauração real executada

### Isolamento e artefatos

Foram criados somente recursos novos:

- Banco: `ep-backup-restore-mwh9qau9-b33958-db`.
- Auth: `ep-backup-restore-mwh9qau9-b33958-auth`.
- Rede `ep-backup-restore-mwh9qau9-b33958-net`, com `internal=true`.
- Volume `ep-backup-restore-mwh9qau9-b33958-data`.
- Nenhuma porta publicada no host; nenhuma conexão com produção.

O Supabase de QA `supabase_db_EntrePatas-Restore-Test` não foi sobrescrito nem
parado. Apenas seu DDL managed e marcadores de versão foram lidos para construir
os pré-requisitos do ensaio. Nenhum registro de usuário foi copiado desse QA.

Imagens já disponíveis: PostgreSQL Supabase 17.11.0.019 e GoTrue v2.197.0.
Senha de serviço e chave JWT do novo ambiente foram geradas localmente e
mantidas fora de argumentos/logs; não foram usadas credenciais de produção.

Artefatos e manifesto privado ficam em nova pasta externa:

```text
%USERPROFILE%\EntrePatas-Backups\ensaio-20261115-mwh9qau9-b33958\
```

Contêm pré-requisitos managed, marcadores locais, inventário e evidências. Não
foram adicionados ao Git. Ao terminar, os dois containers novos foram parados;
rede, volume e arquivos foram preservados. O manifesto registra seus nomes e estados.

### Procedimento aplicado

1. Inicializar nova instância e aguardar o processo PostgreSQL final, não apenas
   a primeira resposta do servidor temporário de bootstrap.
2. Conferir rede interna, ausência de portas e volume novo, sem dados de clientes.
3. Preparar schemas auth/storage/extensions/vault a partir de DDL **local** e
   versões managed compatíveis; retirar desse seed os triggers do aplicativo.
4. Restaurar `roles.sql`, `schema.sql` e **somente `data.sql`**.
5. Resetar e conferir `session_replication_role=origin`. O dump usa modo replica;
   por isso a verificação independente de FKs é obrigatória.
6. Instalar `auth-trigger.sql` por último, para não gerar perfis duplicados ao
   carregar os usuários Auth já presentes no export.
7. Comparar contagens e fingerprints de todo o conteúdo de cada COPY, sem
   mostrar ou salvar linhas de dados em logs.
8. Auditar FKs, sequências, funções, RLS, policies e privilégios efetivos.
9. Iniciar Auth isolado com JWT novo e sem SMTP externo; cadastrar, entrar e
   consultar uma conta fictícia criada somente nesse ambiente.

Os sete arquivos não incluem todo o DDL managed nem os marcadores de migração
Auth/Storage. Foi necessário um seed local de 223.720 bytes e seus marcadores.
Portanto é uma **restauração híbrida**, não demonstra que os sete arquivos
sejam autossuficientes para reconstruir todo o Supabase.

Ocorreram erros de preparação antes da carga de dados (stubs, colisões de objetos
e inicialização ainda em curso) e um erro na consulta de validação de sequência.
Foram corrigidos somente os preparativos/SELECTs no ambiente novo. O manifesto
preserva as tentativas; os dados não foram reaplicados após a carga bem-sucedida.

### Resultados observados

| Verificação | Resultado | Evidência |
| --- | --- | --- |
| Sete arquivos originais intactos | PASSOU | SHA-256 inicial/final idênticos |
| Contagens de todos os COPYs | PASSOU | 40 tabelas com valores esperados |
| Conteúdo dos campos exportados | PASSOU | 40 fingerprints ordenados idênticos, calculados em memória |
| Integridade referencial | PASSOU | 40 anti-joins de FKs, zero órfãos |
| Definições de funções do aplicativo | PASSOU | Nove fingerprints iguais ao snapshot auditado |
| RLS/policies | PASSOU quanto à presença | Quatro tabelas com RLS; dez policies públicas |
| Trigger de cadastro | PASSOU | Instalado e criou um perfil na prova de Auth |
| Sequências | PASSOU para o export antigo | adocao 31/false, animal 31/true, cliente 78/true, questionario 22/true antes da conta fictícia |
| Signup / login / GET user local | PASSOU | HTTP 200/200/200, usando somente conta fictícia nova |
| Perfil vinculado criado pelo trigger | PASSOU | Exatamente um perfil ativo para a conta fictícia |
| Equivalência de privilégios | **FALHOU** | Grants mais amplos que a origem auditada |
| Backup atual de produção capturado | **BLOQUEADO** | Conexão PostgreSQL preexistente indisponível |
| Recuperação completa/equivalente certificada | **NÃO APROVADA** | Cópia antiga, seed híbrido e divergência de ACL |

Contagens antes da prova Auth: cliente 12, animal 10, adoção 2, questionário 7,
Auth users 4 e identities 4. A conta fictícia posterior acrescentou um usuário
Auth e um perfil somente no clone. Senhas de usuários restaurados não foram
testadas; o fingerprint dos campos exportados confere sua preservação.

### Falha de segurança que impede certificar a recuperação

O clone apresentou 24 diferenças de privilégios de tabela nas comparações
anon/authenticated × quatro tabelas × SELECT/INSERT/UPDATE/DELETE. Há também
UPDATE direto de ativo e EXECUTE anônimo em quatro RPCs públicas que a origem
auditada não concede. Esses casos não foram contados como aprovações.

Os privilégios padrão da imagem concedem permissões amplas a anon/authenticated
na criação de objetos. O arquivo possui grants restritos e revoga PUBLIC das
funções, mas isso não remove todas as concessões adicionais introduzidas pela
base de destino. RLS habilitada e functions idênticas não garantem ACL equivalente.

Nenhuma concessão foi alterada para esconder a diferença. O processo de restauração
precisa ser ajustado e repetido em ambiente novo, controlando os privilégios
padrão antes da criação e restaurando os grants/owners da origem. Só pode ser
aprovado quando a matriz efetiva de permissões, inclusive de colunas e funções,
for equivalente. Não aplicar esse ajuste diretamente na produção.

## 4. O que o backup SQL não cobre sozinho

- **Storage:** não há objetos/buckets no snapshot atual, mas o banco contém
  referências a imagens externas. O SQL preserva o endereço, não os arquivos
  hospedados por terceiros. Sua disponibilidade não foi certificada.
- **Auth:** Site URL, redirects, SMTP, templates, OAuth/MFA/captcha/hooks, limites
  e chaves de assinatura exigem inventário/recuperação separados e privados.
  Novo JWT local não comprova validade de sessões antigas de produção.
- **Edge Functions:** nenhuma instalada no inventário atual. Código local da
  função `excluir-conta`, `verify_jwt` e seus secrets não são instalados por pg_dump.
  Exclusão de conta é uma pendência independente dos SQLs 12/15/10.
- **Papéis e ambiente gerenciado:** roles, memberships, default ACL, owners,
  extensões e versões precisam acompanhar o plano; `roles.sql` antigo só altera
  timeouts. Senhas de serviço não devem ser enviadas ao GitHub.
- **Aplicativo:** fonte Flutter, assets, SQLs, build/deploy e configuração pública
  continuam no projeto. O dump não publica código nem configura Vercel/domínios.

Metadados sanitizados desses itens não são um backup restaurável dos secrets.

## 5. Procedimento preparado para a captura atualizada

Novo script: `scripts/backup_supabase_readonly.ps1`.

Ele exige PGPASSFILE já existente fora do repositório, ferramentas PostgreSQL
compatíveis, alvo do projeto validado, pooler de sessão/direct na porta 5432,
TLS verify-full e conexão que confirme `transaction_read_only=on`.
Rejeita PGPASSWORD, overrides de destino libpq e caminhos com junction/symlink.

Todos os clientes usam `-w`, sem prompt de senha. Gera arquivo custom completo,
com propriedades de banco (`--create` apenas no arquivo), captura roles sem senhas,
confere o catálogo do arquivo e cria manifesto com hashes. Usa pasta nova externa;
não sobrescreve backups, não cria credenciais e não restaura/limpa banco algum.

Foi validado com parser PowerShell 5.1 (zero erros) e checagens locais negativas.
O `-CheckOnly` no ambiente atual saiu com 1 **por bloqueio esperado**, antes de
abrir conexão/criar pasta. A captura real não foi executada. O script marca
`restore_test_passed=false` mesmo após uma captura, até existir ensaio independente.

```powershell
# Sem conexão: conferir pré-requisitos locais.
powershell.exe -NoProfile -File scripts/backup_supabase_readonly.ps1 -CheckOnly
```

Para avançar, o operador precisa disponibilizar uma conexão PostgreSQL já
autorizada por canal privado, sem enviar senha no chat, ou identificar um backup
oficial recuperável. Não resetar senha, gerar papel temporário ou burlar Auth
para produzir a cópia. Depois, capturar e restaurar uma cópia atual completa em
nova instância, corrigindo o processo de ACL e repetindo as provas acima.

## 6. Ordem confirmada e recuperação de migrações

A ordem proposta permanece **12 → 15 → 10 → 16**, condicionada a:

1. Backup atualizado/restaurável aprovado e matriz de segurança equivalente.
2. Releitura dos SQLs 00/01 e pré-requisitos no destino, sem divergências.
3. Autorização explícita e janela de manutenção definida.

SQL 12 corrige perfis, SQL 15 fornece exclusão lógica segura, SQL 10 instala as
adoções e SQL 16 é apenas leitura de catálogo. SQL 30 é opcional para essas
correções e não entra automaticamente. SQL 20/Edge Function têm revisão separada.

Em falha antes do COMMIT, parar e confirmar rollback; não reaplicar cegamente.
Em desconexão, inspecionar quais objetos realmente existem antes de repetir.
Após COMMIT com problema, suspender novos pedidos/gravações e preservar dados e
evidências. Elaborar correção/reversão específica dos objetos e ACLs, validada
no clone. Não liberar grants amplos para contornar erros.

Uma restauração completa posterior pode perder gravações feitas após o backup.
Não sobrescrever produção com um dump antigo nem usar `--clean`, db reset ou DROP
como recuperação automática. A restauração/reconciliação exige decisão explícita,
retenção dos dados posteriores e backup aprovado, incluindo Auth e configurações.

## 7. Arquivos desta tarefa

- `scripts/backup_supabase_readonly.ps1`: captura futura com guardas, sem CLI que
  cria credenciais e sem executor de restauração.
- `docs/backup_recuperacao_supabase.md`: situação/procedimento atualizado.
- `docs/backup_validacao_2026-11-15.md`: este relatório de resultados reais e limites.

Runners ficaram em `.dart_tool` ignorado. Dumps, seed managed, manifestos e dados
do ensaio ficaram na pasta externa ou no volume Docker isolado. Nenhum arquivo
Flutter, SQL de migração ou backup original foi alterado. Os demais diffs do
workspace foram preservados. Não foram repetidos testes Flutter sem mudança no app.

**Para a entrega: fonte/build podem seguir para revisão, mas as migrações e a
publicação funcional no online ainda dependem da recuperação certificada e de autorização.**
