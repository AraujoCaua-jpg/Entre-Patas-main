# Preparação do Entre Patas para GitHub e Vercel

> Status posterior das integrações e scripts: [Correções finais](correcoes_finais_sql10.md).
> Este documento preserva a rodada de organização e compilação do repositório.

Data: 14/11/2026. Escopo: limpeza segura, configuração pública reproduzível,
documentação de colaboração e build Web. Nenhuma alteração no Supabase online,
commit, push ou publicação na Vercel foi executada.

## O que foi removido

| Caminho | Arquivos removidos | Bytes | Motivo |
| --- | ---: | ---: | --- |
| `build/` | 91 | 379.324.415 | Artefatos gerados por compilação/testes; incluíam o bundle anterior de QA local. |
| `.dart_tool/flutter_build/` | 29 | 55.017.060 | Cache de compilação gerado pelo SDK. |
| **Total** | **120** | **434.341.475** | Somente arquivos regeneráveis, aproximadamente 414 MiB. |

Antes da exclusão foram conferidos os caminhos absolutos dentro do workspace,
ausência de links/junctions e ausência de arquivos rastreados pelo Git nessas
pastas. O inventário individual com caminho relativo e tamanho está no arquivo
local ignorado `.dart_tool/preparacao_cleanup_manifest.json`.

As pastas são recriadas pela validação. O objetivo é remover artefatos antigos,
não manter o workspace sem cache depois de compilar. Não houve exclusão nova de
fontes, documentação, testes, assets, SQLs ou arquivos de integrantes da equipe.
Exclusões e alterações já existentes no Git antes desta tarefa foram preservadas.

## O que foi preservado e deve integrar a revisão do GitHub

| Pasta/arquivo | Finalidade e decisão |
| --- | --- |
| `lib/controller/`, `lib/model/`, `lib/services/`, `lib/view/` | Aplicação e regras atuais. Preservados. |
| `lib/service/` | Validação de senha usada em runtime e clientes PHP cobertos por testes. Nenhuma exclusão segura identificada. |
| `lib/main_preview_comp.dart` | Entrypoint alternativo de preview; ausência de import não comprova inutilidade. Preservado. |
| `backend/` e testes PHP | Referência e manutenção do legado, com regras ainda documentadas por testes. Não necessários ao runtime Supabase atual. |
| `docs/` e `docs/sql/` | QA, inspeção, instalação e manutenção do backend. Todos preservados. |
| `supabase/config.toml` e `supabase/functions/` | Configuração e função de exclusão de conta. Preservados. |
| `test/` | Regressões Flutter, fixtures, SQL em memória e legado. Preservados. |
| `assets/`, `web/`, `android/`, `ios/` | Recursos, fontes e plataformas existentes. Preservados. |
| `pubspec.yaml`, `pubspec.lock`, `.metadata`, `analysis_options.yaml` | Manifesto, versões resolvidas e configuração Flutter. Preservados. |

Todas as dependências diretas têm referências reais. `http`, `material_ui` e
`supabase_flutter` permanecem. A restrição `material_ui: any` passou a
`^1.11.0`, sem mudar a versão 1.11.0 resolvida no lock. Não houve `pub upgrade`.
Os avisos sobre duas versões mais recentes de dependências transitivas não
exigem upgrade para esta entrega.

Arquivos úteis de `docs/`, `supabase/`, serviços e testes já estavam não
rastreados no início. Eles não foram descartados nem adicionados ao índice:
precisam integrar a seleção/revisão futura da equipe antes de compartilhar o Git.

## O que fica fora do Git

- `build/`, `.dart_tool/`, `coverage/`, caches Flutter e arquivos de plugins gerados.
- `supabase/.temp/` e `supabase/.branches/`: metadados/conexões locais do CLI.
- `.vercel/`: cache de SDK e metadados locais do deploy.
- `.env` e variantes reais, JSON/YAML `*.local.*`, chaves `.pem`/`.key` e
  proteções Android/iOS já existentes para keystores e configuração gerada.
- Diretórios `backups/`, `EntrePatas-Backups/`, dumps `*.dump`/`*.backup`, SQLs
  compactados e exports de raiz `schema.sql`, `data.sql`, `auth-data.sql`.

Exemplos `.env.example` podem ser versionados se contiverem somente placeholders.
`config/production.json` é deliberadamente versionável: contém **somente URL e
chave publishable públicas**. Os SQLs em `docs/sql/` não são dumps descartáveis.
Um dump com outro nome/local também deve ficar fora do repositório: o `.gitignore`
não reconhece o conteúdo de um backup automaticamente.

O cache `.dart_tool/adocao_sql_test` foi mantido para executar os testes PGlite;
os runners/logs de QA anteriores foram preservados como evidência e permanecem
ignorados. A pasta `supabase/.temp/` também foi mantida localmente para não
desvincular o CLI, com sua proteção de Git confirmada.

## Alterações desta tarefa

| Arquivo | Alteração |
| --- | --- |
| `.gitignore` | Proteção adicional para configurações locais, credenciais, exports e cache Vercel. |
| `README.md` | Instalação, equipe, backend compartilhado, validação e Vercel; contexto acadêmico e autores mantidos. |
| `pubspec.yaml` | Descrição do app e restrição explícita de `material_ui`. |
| `lib/main.dart` | Removidos import e consulta/logs de diagnóstico antes de `runApp`; inicialização Auth e navegação preservadas. |
| `config/production.json` (novo) | Endpoint online e chave pública para execução/build reproduzíveis. |
| `config/toolchain.json` (novo) | Flutter 3.50.0 e revisão exata do SDK. |
| `scripts/build_web.mjs` (novo) | Instala SDK quando ausente, valida versão/configuração, respeita lock, compila e confere bundle. Não executa deploy ou SQL. |
| `vercel.json` (novo) | Build personalizado, saída `build/web` e fallback de SPA. |
| `test/production_build_config_test.mjs` (novo) | Regressões contra endpoint local, chave administrativa, propagação de variáveis privadas e SDK divergente. |
| `docs/adocoes_supabase.md` (novo) | Documentação referenciada pelo SQL 10; revisão e dependências, sem execução automática. |
| `docs/preparacao_producao.md` (novo) | Este relatório. |

`pubspec.lock` foi mantido com as versões existentes. Outras mudanças anteriores
no workspace não foram revertidas ou atribuídas a esta limpeza.

## Segurança e configurações

O app e o arquivo público apontam para
`https://cyaxnaflvnjnpryryorr.supabase.co`. Não é necessário localhost, Docker,
XAMPP ou banco importado para que os três integrantes usem o mesmo backend.
Cada pessoa usa sua conta do aplicativo. Convite ao painel Supabase só é
necessário para trabalho administrativo, com acesso individual e mínimo.

A chave publishable identifica o cliente; Auth e RLS controlam os dados. Chaves
secret/service_role ficam exclusivamente no servidor. A função de exclusão foi
preservada com validação explícita de identidade e autenticação recente; não
foi transferida para o Flutter nem teve suas permissões alteradas.

O build Vercel aceita apenas o endpoint online esperado e chave com prefixo
publishable. Somente essas duas variáveis são gravadas no arquivo de defines
temporário. Configuração de QA local, JWT legado e chave administrativa são
rejeitados antes da compilação. O teste também confere que os defaults de
`main.dart` correspondem ao JSON público.

A tag pública oficial `3.50.0` foi consultada somente para leitura e corresponde
à revisão `ab2912035e160d9cad6306df307576da6128ebdb`, fixada no projeto. O caminho
de build com SDK instalado foi executado no Windows; a instalação em uma Vercel
sem SDK e a hospedagem ainda precisam ser confirmadas no primeiro deploy autorizado.

O scan sanitizado examinou 161 arquivos de texto existentes rastreados/não
ignorados e 397 blobs do histórico Git local, dos quais 364 eram texto. Não
encontrou chaves secret, JWT service_role, chaves privadas, tokens GitHub ou
access keys AWS nos padrões pesquisados. Não foram encontrados dumps nos arquivos
candidatos ao Git. É uma verificação por padrões, não uma garantia contra todo
formato possível de segredo ou refs remotas não presentes localmente.

O único endpoint PHP local identificado no Dart fica em
`lib/service/cliente_api.dart`, legado preservado por seus testes. O controller
atual delega as operações remotas aos serviços Supabase. Fixtures fictícias
permanecem em testes e no entrypoint de preview; não foram promovidas ao app.

## Validação executada após a limpeza

| Verificação | Resultado | Evidência local |
| --- | --- | --- |
| `flutter pub get` | PASSOU; sem upgrade das versões resolvidas | `.dart_tool/preparacao_pub_get.log` |
| `flutter analyze --no-pub` | 0 erros, 0 warnings e 113 infos existentes; exit 1 pelos infos | `.dart_tool/preparacao_analyze.log` |
| `flutter test --no-pub --reporter json` | 143 passaram, 0 falharam, 2 ignorados | `.dart_tool/preparacao_flutter_test.jsonl` |
| Três suítes SQL PGlite em memória | 31 passaram, 0 falharam | `.dart_tool/preparacao_sql_test.log` |
| `node --test test/production_build_config_test.mjs` | 5 passaram, 0 falharam | Saída do runner Node |
| Build Web release online | PASSOU; Flutter 3.50.0, saída `build/web`, endpoint online e configuração pública conferidos | `.dart_tool/preparacao_web_build.log` |
| `git diff --check` | PASSOU; avisos LF/CRLF sem erro de whitespace | Exit 0 |

Os dois testes Flutter ignorados dependem da flag de sincronização de e-mail e
não foram contados como aprovados. Total das suítes executadas nesta rodada:
**179 testes aprovados, nenhuma falha e dois ignorados** (143 Flutter + 31 SQL +
5 configuração). É uma bateria diferente dos 179 casos do QA local anterior:
os testes REST/SDK com o servidor local não foram repetidos nesta limpeza.

A inspeção do JavaScript gerado confirmou o endpoint online e a chave
publishable esperados. Não encontrou endpoint Supabase local, URL PHP local,
endereço do emulador Android, chave secret ou JWT service_role no bundle.
Evidência: `.dart_tool/preparacao_bundle_audit.json`. O build final usa JavaScript;
as mensagens de dry run WASM e tree shaking de fontes são informativas.

Para reproduzir os testes SQL sem Docker ou servidor, com Node.js compatível
com `node --test`, instalar a dependência isolada e fixada:

```powershell
npm install --prefix .dart_tool/adocao_sql_test --no-save @electric-sql/pglite@0.5.16
node --test test/adocao_supabase_sql_test.mjs test/perfil_auth_supabase_sql_test.mjs test/exclusao_conta_supabase_sql_test.mjs
node --test test/production_build_config_test.mjs
```

Esses comandos usam PostgreSQL WASM em memória, não o Supabase online.

## O que ainda impede considerar a publicação funcional em produção

1. **SQL 10 não instalado em produção:** as operações de adoção dependem de suas
   RPCs e políticas. Revisar [adoções no Supabase](adocoes_supabase.md), backup
   recuperável e esquema real antes de qualquer instalação separada.
2. Confirmar as dependências já instaladas dos SQLs 05/20/30, funções de perfil,
   questionário, pesquisa/localização e Edge Function de exclusão de conta.
   Não presumir que existam só porque os arquivos estão no repositório.
3. Revisar Site URL e Redirect URLs do Supabase Auth para o domínio final e as
   origens de desenvolvimento autorizadas; validar e-mails e recuperação no
   domínio real. Nenhuma configuração foi alterada nesta tarefa.
4. Executar smoke visual do bundle e, após instalação aprovada do backend,
   validar fluxos completos no ambiente de destino com contas autorizadas.

O frontend pode ser compilado e compartilhado; isso não certifica as dependências
de produção. Não foi realizado teste destrutivo, migração, cadastro ou consulta de
dados no projeto online nesta tarefa.

## Clonar e executar

```powershell
git clone https://github.com/AraujoCaua-jpg/Entre-Patas-main.git
cd Entre-Patas-main
flutter pub get
flutter run -d chrome --dart-define-from-file=config/production.json
```

Pré-requisitos: Git, Chrome e Flutter 3.50.0 no PATH. Para gerar o pacote com a
mesma validação usada pela Vercel, usar Node.js 20 ou superior e executar
`node scripts/build_web.mjs`. Conferir `build/web`, sem publicar automaticamente.

Referências oficiais: [chaves Supabase](https://supabase.com/docs/guides/getting-started/api-keys),
[configuração Vercel](https://vercel.com/docs/project-configuration/vercel-json) e
[build Flutter Web](https://docs.flutter.dev/deployment/web).
