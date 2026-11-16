# 🐾 Entre Patas

![Dart](https://img.shields.io/badge/Dart-259acf?style=for-the-badge&logo=dart&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-259acf?style=for-the-badge&logo=flutter&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)

O **Entre Patas** é um aplicativo de adoção de animais, desenvolvido para o Summit
da Universidade de Mogi das Cruzes (UMC). Aproxima adotantes, animais e
organizações de acolhimento com cadastro, teste de compatibilidade e
acompanhamento das solicitações de adoção.

Repositório: [AraujoCaua-jpg/Entre-Patas-main](https://github.com/AraujoCaua-jpg/Entre-Patas-main).
O endereço definitivo da aplicação Vercel não foi identificado nos arquivos
versionados; falta informá-lo e validar os fluxos nesse domínio.

## Aplicativo e backend

O aplicativo atual utiliza **Flutter/Dart e Supabase Auth/PostgreSQL**, com
permissões de acesso protegidas por RLS e funções RPC. A Home calcula a
compatibilidade com as respostas do questionário: Rotina 50%, Ambiente 30% e
Preferências 20%. Animais sem informações suficientes continuam visíveis sem
uma porcentagem inventada.

Os fluxos implementados incluem cadastro/login, recuperação de senha, perfil,
questionário, pesquisa de animais e usuários, publicação/edição de animais,
solicitação/cancelamento/aprovação/recusa e notificações. A disponibilidade no
ambiente online depende da instalação das respectivas funções e políticas no
banco; compilar o Flutter não instala essas dependências.

**Os SQLs 12, 15 e 10 foram instalados no Supabase de produção em 15/11/2026**,
com três COMMITs confirmados e **20/20 verificações do SQL 16 aprovadas**.
As contagens e os fingerprints dos dados foram preservados. Consulte o
[relatório da instalação](docs/instalacao_producao_2026-11-15.md).
O build e a publicação do aplicativo não executam migrações.

A confirmação visual dos fluxos no aplicativo publicado continua necessária.
Nove animais antigos pertencem a responsáveis sem vínculo Auth; esses vínculos
precisam de regularização comprovada e não são criados automaticamente.

O backend PHP e seus testes foram preservados para consulta e manutenção do
legado. Apache, XAMPP, MySQL e `API_BASE_URL` **não são necessários para executar
o fluxo atual do aplicativo**.

## Executar em outro computador

Pré-requisitos: Git, Chrome e **Flutter 3.50.0**, que inclui o Dart 3.14. Não é
necessário instalar Dart separadamente. Android/iOS exigem também as ferramentas
indicadas por `flutter doctor`; suas configurações foram preservadas.

```powershell
git clone https://github.com/AraujoCaua-jpg/Entre-Patas-main.git
cd Entre-Patas-main
flutter --version
flutter doctor
flutter pub get
flutter run -d chrome --dart-define-from-file=config/production.json
```

Mantenha `pubspec.lock` no Git e utilize a versão de Flutter indicada. Não execute
`flutter pub upgrade` como parte da instalação normal. Caso o SDK não esteja no
PATH, use o executável `flutter` da instalação correspondente.

### Um mesmo Supabase para os três integrantes

O projeto compartilhado é `https://cyaxnaflvnjnpryryorr.supabase.co`. O arquivo
`config/production.json` contém somente a URL pública e a chave publicável do
cliente. O `main.dart` lê `SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY` com
`String.fromEnvironment`; os valores padrão também apontam para esse projeto
online, portanto `flutter run -d chrome` não depende de localhost.

Cada integrante pode criar ou acessar sua própria conta no app usando o mesmo
backend. **Não é necessário importar um banco, instalar Docker ou receber convite
para o painel do Supabase para usar o aplicativo.** As contas de usuários e as
contas administrativas do painel são diferentes.

Convide alguém para o painel somente se precisar administrar o backend, com o
menor privilégio necessário. Nunca compartilhe a conta administrativa, senhas,
tokens de acesso, chave `service_role` ou chave `secret` com os usuários do app.
Somente a URL e a chave pública podem integrar o bundle Web; a proteção dos dados
depende da autenticação e da RLS, não do sigilo dessa chave pública.

Os dados desse ambiente são compartilhados: alterações feitas no app afetam o
mesmo banco. Testes que criam ou alteram dados e scripts de migração devem ser
executados no ambiente local isolado, nunca automaticamente em produção.

### Outra configuração ou QA local

As variáveis são definidas na compilação, não lidas automaticamente de um `.env`
no navegador. Para outro ambiente, crie um JSON local ignorado pelo Git com
`SUPABASE_URL` e `SUPABASE_PUBLISHABLE_KEY` e passe
`--dart-define-from-file=<arquivo>`. Não coloque credenciais administrativas
nesse arquivo nem em qualquer `dart-define`.

`SUPABASE_AUTH_REDIRECT_URL` é opcional para recuperação de senha. Sem essa
variável, o Web usa a URL atual e o mobile usa `entrepatas://auth-callback`.
O domínio definitivo e os callbacks permitidos precisam ser revisados no Auth do
Supabase antes da publicação; não houve alteração automática dessas configurações.

## Validação e build Web

```powershell
flutter pub get
flutter analyze
flutter test
flutter build web --release --dart-define-from-file=config/production.json
git diff --check
```

O resultado Web fica em `build/web`. O comando acima compila para o Supabase
online sem executar migrações nem gravar dados. Um build feito com configuração
de QA em `127.0.0.1` não é um build de produção.

A validação final de 15/11/2026 registrou **258 testes aprovados, nenhuma falha e
dois casos ignorados** por uma funcionalidade de alteração de e-mail desabilitada.
O release Web de produção compilou e abriu no Chrome isolado sem erros de runtime.
O analisador retornou 0 erros, 0 avisos e 113 informações de estilo/depreciação
(o comando padrão termina com exit 1 por essas informações). Consulte o
[relatório final de entrega](docs/qa_entrega_flutter_web_2026-11-15.md).
Fluxos autenticados e gravações no Supabase real ainda precisam de validação
manual autorizada; testes locais não substituem essa confirmação.

A revisão local de **16/11/2026**, com correções e avaliação pelos seis critérios
acadêmicos, está no [relatório de auditoria](docs/auditoria_avaliacao_final_2026-11-16.md).
Os resultados de 15/11 acima são históricos, não a contagem da revisão atual.

Para os contratos SQL isolados e a configuração de build, com Node e as
dependências locais de testes disponíveis, execute `node --test test/*.mjs`.
Esses testes usam PostgreSQL em memória e não executam migrações em produção.
Em uma instalação nova, prepare a dependência isolada com
`npm install --prefix .dart_tool/adocao_sql_test --no-save @electric-sql/pglite@0.5.16`.
O teste unitário PHP legado pode ser executado com
`php test/validacao_cliente_test.php`; os demais testes PHP de integração
exigem Apache/MySQL e banco isolado, conforme `backend/README.md`.

## Exemplos de uso e evidências visuais

1. Cadastre uma conta nas quatro etapas e confirme o e-mail, se solicitado.
2. Entre e responda ao questionário antes da Home. Nos próximos logins, as
   respostas salvas são reutilizadas, inclusive para contas legadas.
3. Consulte as recomendações da espécie preferida, ordenadas pela maior
   compatibilidade, ou use Pesquisa para encontrar outros animais.
4. Abra uma ficha e solicite a adoção; o responsável acompanha a solicitação
   nas notificações e pode aprovar ou recusar. O adotante pode cancelar.
5. No perfil, edite os dados e informe uma URL HTTP/HTTPS para a foto.
   Publique um animal e gerencie suas próprias publicações.

**Prints reais ainda pendentes:** login, quatro etapas do cadastro,
questionário, Home com percentuais ordenados, pesquisa com filtros, ficha do
animal, perfil/edição, cadastro de animal e adoções/notificações. Capture o
aplicativo em execução, com dados de demonstração autorizados, em celular e
desktop. Banners e imagens de animais em `assets/` não comprovam essas telas.
Não foram adicionados prints fictícios nem links para imagens inexistentes.

### Vercel

O repositório prepara a configuração em `vercel.json`:

- Framework: **Other**.
- Build: `node scripts/build_web.mjs`.
- Saída: `build/web`.
- SDK de build: Flutter **3.50.0**, fixado pelo script.
- Configuração do cliente: `config/production.json`, somente valores públicos.

O script prepara o SDK em cache quando necessário, instala as dependências pelo
lockfile e gera o build Web. Ele rejeita outro endpoint Supabase, chaves
administrativas e um SDK divergente. A configuração de rotas permite que o
aplicativo seja aberto por URL direta. Confira o
[checklist de publicação](docs/publicacao_github_vercel.md), incluindo os
callbacks de Auth do domínio definitivo. **Preparar esses arquivos não publica
na Vercel.**

## Estrutura e arquivos que devem ser preservados

| Caminho | Finalidade |
| --- | --- |
| `lib/controller/`, `lib/model/`, `lib/services/`, `lib/view/` | Estado, modelos, integração Supabase e telas do app. |
| `lib/service/` | Validação de senha ativa e clientes PHP legados cobertos por testes. |
| `assets/`, `web/`, `android/`, `ios/` | Recursos, fontes e configurações das plataformas. |
| `test/` | Regressões Flutter, fixtures e verificações SQL/legadas. |
| `docs/`, `docs/sql/` | Relatórios de QA, instruções e SQLs de inspeção/migração para revisão. |
| `supabase/functions/` | Funções de backend, incluindo exclusão de conta; nunca substituir por código administrativo no Flutter. |
| `backend/` | Implementação PHP legada preservada. |
| `pubspec.yaml`, `pubspec.lock` | Dependências e suas versões resolvidas. |

`build/`, `.dart_tool/`, caches, logs descartáveis e `supabase/.temp/` são
artefatos locais ignorados pelo Git. Backups/dumps de banco, `.env`, tokens e
chaves privadas não devem entrar no repositório. Preserve os SQLs de instalação
e manutenção; eles não são descartáveis por não serem compilados pelo Flutter.

Não execute `supabase db push`, `db reset` nem os SQLs 05, 10, 20 ou 30 em produção
como etapa de instalação do app. Qualquer instalação do backend exige revisão
separada, backup recuperável e validação das permissões.

## Colaboração

Cada integrante deve usar sua própria conta do GitHub e uma branch por tarefa.
Revise `git status` e o diff antes de selecionar arquivos para um commit e
integre as mudanças por pull request. Não envie builds, caches ou credenciais.
Mensagens e autoria devem refletir contribuições reais; não crie commits
artificiais para simular participação.

## Contexto acadêmico e autores

Projeto do 4º semestre de Engenharia de Software da UMC, nas disciplinas de
Desenvolvimento de Aplicações e Métodos Ágeis e para o SUMMIT da Revista
Científica da UMC. O protótipo de UX/UI foi elaborado no Figma.

| Integrante | Atuação apresentada | GitHub |
| --- | --- | --- |
| Cauã Araújo Marques | Desenvolvimento e integração | [AraujoCaua-jpg](https://github.com/AraujoCaua-jpg) |
| Lucas Alves Siqueira | UX/UI Design e prototipação | [LucasSiq31](https://github.com/LucasSiq31) |
| Yasmim Camilli da Silva Pacheco | Planejamento e desenvolvimento | [YasmimPacheco](https://github.com/YasmimPacheco) |

**Orientadores:** Alessandra da Silva Martins e Higor Barreto Campos.

O histórico local confirma contribuições dos três integrantes. Exemplos:
Cauã — integração Supabase (`6f8e63f`); Lucas — prévia da foto (`60b2f58`)
e README (`476ac3e`); Yasmim — recomendações/notificações (`0240f96`) e
ajustes de seleção (`bdc343f`). A tabela de atuação acima mantém o contexto
declarado pelo grupo; os commits comprovam apenas as mudanças registradas.
