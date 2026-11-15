# Conferência pré-instalação do original — 15/11/2026

**Pronto tecnicamente para instalação, condicionada à autorização explícita.**
Esta rodada executou apenas consultas de leitura. Nenhuma migração, alteração de
dados/permissões, criação de login temporário, commit Git, push ou deploy foi feita.

Revalidado em **15/11/2026 às 15:10 (America/Sao_Paulo)** com um único SELECT
agregado em modo read-only. Catálogo, privilégios, compatibilidade e fingerprints
continuaram iguais; backups e scripts permaneceram intactos. Evidência adicional:
`.dart_tool/pre_instalacao_original_revalidacao_20261115.json`.

## Identidade, transporte e limites

- Projeto confirmado pela API autenticada: `cyaxnaflvnjnpryryorr`, ACTIVE_HEALTHY,
  com hostname de banco correspondente ao identificador original.
- Transporte: Management API HTTPS, certificado validado, TLS 1.3.
- Todas as consultas usaram o identificador original explícito e `--read-only`;
  o CLI envia `read_only=true`. O banco confirmou `transaction_read_only=on`,
  papel `supabase_read_only_user`, banco postgres e PostgreSQL 17.11.
- Não foi utilizada nem testada uma conexão PostgreSQL direta com senha.
  Caso esse seja o método de instalação escolhido posteriormente, sua credencial
  e TLS precisam ser conferidos separadamente antes da escrita autorizada.
- Não foram chamadas RPCs de negócio, nextval/setval, DO, locks ou trechos dos
  scripts de migração. Os requisitos foram avaliados por SELECTs de catálogo
  e agregados. A identidade do operador de leitura não foi confundida com a
  autorização do futuro instalador administrativo.

## Resultado das verificações

| Conferência | Resultado |
| --- | --- |
| Backup e arquivos de revisão disponíveis | PASSOU; quatro arquivos com os mesmos SHA-256 |
| Evidência de restauração gerenciada | Disponível; destino de recuperação previamente validado |
| SQLs 12, 15, 10 e 16 | Mesmos hashes das versões ensaiadas; nenhum arquivo foi alterado |
| Catálogo | 16 grupos comparados; nenhuma diferença real |
| Contratos e segurança | Nove funções, dez policies, oito entradas de privilégio de tabela e 72 de coluna iguais ao baseline |
| SQL 12 | Quatro contratos INTEGER exatos, wrappers, STABLE, owners privilegiados, search_path e acesso a private compatíveis |
| SQL 15 | Tipos/RLS compatíveis, imagem anulável, UPDATE de ativo negado, nenhum overload/objeto conflitante |
| SQL 10 | Quatro FKs necessárias validadas, sequência segura, nenhum novo RPC, índice ou trigger já instalado |
| Histórico de adoção | Zero incompatibilidades, duplicidades, órfãos ou inconsistências Aceito/Adotado |
| Conteúdo selecionado | Sete fingerprints iguais ao backup original, sem retornar registros pessoais |

Contagens atuais e do backup:

| Tabela | Backup | Original atual | Conteúdo comparado |
| --- | ---: | ---: | --- |
| public.cliente | 12 | 12 | Igual |
| public.animal | 11 | 11 | Igual |
| public.adocao | 2 | 2 | Igual |
| public.questionario | 7 | 7 | Igual |
| public.recuperacao_senha | 0 | 0 | Igual |
| auth.users | 4 | 4 | Igual |
| auth.identities | 4 | 4 | Igual |

Esses fingerprints foram calculados no servidor e comparados ao COPY original,
incluindo UUIDs, hashes e demais campos selecionados. Nenhum valor pessoal ou
credencial foi retornado ao relatório. Não se usou a cópia Auth sanitizada do
projeto de recuperação como referência para a produção.

A comparação tratou booleanos no formato t/f do COPY. Índices e policies do
questionário foram comparados ao baseline dedicado, pois não constavam do JSON
antigo do catálogo. As diferenças iniciais de representação/baseline foram
resolvidas sem modificar o banco nem repetir os testes funcionais já aprovados.

## Ordem e validação posterior

Após autorização específica: **SQL 12 → SQL 15 → SQL 10**. Cada arquivo possui
seu próprio COMMIT; falha no 10 não desfaz 12/15 já confirmados. Interromper no
primeiro erro e inspecionar o estado se houver dúvida sobre o COMMIT.

O SQL 16 foi conferido por hash e revisão existente; não foi executado
prematuramente. A expectativa de 20/20 aprovadas só vale depois dos três COMMITs.
Antes disso, a ausência dos novos objetos é esperada. Complementar o SQL 16 com
as definições de funções, índices, trigger e privilégios previstas no checklist.

## Riscos que permanecem

- A conferência não congela o banco. Aplicar os preflights na hora da instalação
  e usar janela adequada, com limites de espera para os locks do SQL 10.
- Nove animais pertencem a dois responsáveis sem vínculo Auth; duas adoções
  históricas envolvem participantes sem Auth. São pendências conhecidas,
  preservadas, sem regularização ou reativação automática.
- Configurações externas de recuperação, SMTP/redirects/provedores e o teste
  visual Flutter Web continuam separados da compatibilidade dos SQLs.
- Nenhuma garantia de atomicidade conjunta dos três arquivos ou de rollback
  instantâneo é inferida desta leitura. Preservar o procedimento de recuperação
  e reconciliar gravações posteriores ao backup se ele precisar ser utilizado.

## Evidências

Metadados, hashes e histórico da conferência:
`.dart_tool/pre_instalacao_original_20261115.json`, ignorado pelo Git.
Os scripts auxiliares desta rodada aceitam somente SELECTs e o modo read-only.

Referências: [checklist](checklist_instalacao_sql12_15_10.md),
[ensaio local](ensaio_final_migracoes_2026-11-15.md) e
[recuperação gerenciada comprovada](recuperacao_gerenciada_2026-11-15.md).

**A execução no original permanece parada, aguardando autorização explícita.**
