# Publicação do Entre Patas no GitHub e na Vercel

Preparação local em 15/11/2026. Nenhum commit, push ou deploy foi executado nesta
etapa. O Supabase original continua sendo o backend do aplicativo.

Rodada final: 258 testes Flutter aprovados, dois ignorados e nenhuma falha;
release Web de produção compilado e inicializado no Chrome isolado. Analyze:
0 erros/0 avisos/113 informações, com exit 1 no comando padrão. Consulte os
limites e as evidências em [qa_entrega_flutter_web_2026-11-15.md](qa_entrega_flutter_web_2026-11-15.md).

## Configuração pronta no repositório

| Campo | Valor |
| --- | --- |
| Framework Preset | Other |
| Root Directory | Raiz que contém pubspec.yaml |
| Build Command | node scripts/build_web.mjs |
| Output Directory | build/web |
| Flutter | 3.50.0; revisão fixada em config/toolchain.json |
| Configuração pública | config/production.json |
| Rotas Web | vercel.json, fallback para index.html |

O script instala o SDK fixado quando Flutter não está disponível, respeita o
pubspec.lock, gera o release e verifica o endpoint online no bundle. A URL e a
chave publishable são públicas por definição; autenticação, RLS e RPCs protegem
os dados. Não informe senha PostgreSQL, JWT administrativo, service_role,
sb_secret, certificado ou passfile à Vercel ou ao Flutter.

As variáveis SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY são opcionais no build da
Vercel: os defaults públicos já estão no arquivo versionável. Se forem
configuradas no painel, precisam corresponder ao projeto original; uma URL local
ou chave administrativa fará o build parar. A instalação do SDK e das
dependências exige acesso da plataforma ao GitHub e aos servidores do Flutter/Pub.

## Seleção de arquivos para o Git

- Incluir aplicação, assets, fontes, configurações de plataforma, pubspec.yaml e
  pubspec.lock, testes e fixtures, serviços Supabase, SQLs auditados em docs/sql,
  documentação útil, config/production.json, config/toolchain.json,
  scripts/build_web.mjs e vercel.json.
- Preservar o backend PHP e métodos legados usados por funcionalidades ou testes.
- Manter fora build/, .dart_tool/, coverage/, .vercel/, supabase/.temp/ e
  supabase/.branches/, logs e configurações locais.
- Manter fora arquivos .pgpass, certificados, chaves privadas, dumps, exports
  SQL de banco, roles.sql de backup e o diretório externo EntrePatas-Backups.
- Revisar individualmente as exclusões já existentes no Git: controllers antigos
  e arquivo de instruções local não foram apagados por esta preparação. Não usar
  git add -A antes dessa revisão.
- Revisar git diff e arquivos novos antes de selecionar o commit. A presença de
  nomes como backup em relatórios ou scripts de manutenção não transforma esses
  documentos em backups de dados; o conteúdo é o critério.

A varredura de candidatos rastreados e novos não ignorados desta rodada não
encontrou .pgpass, certificados ou dumps, chaves administrativas Supabase, URLs
PostgreSQL com senha ou private keys. O hash bcrypt identificado no backend PHP
é o fallback de verificação para conta inexistente, não um registro exportado.
Essa varredura atual não certifica todo o histórico remoto do Git.

## Antes de publicar

1. Confirmar os resultados atuais de flutter analyze, flutter test e build Web
   no relatório final; os resultados históricos não substituem essa rodada.
2. Conferir git diff --check e revisar o diff selecionado. Autorizar commit/push
   somente após essa revisão; nenhum desses comandos foi executado aqui.
3. Importar o repositório na Vercel apenas quando o push estiver autorizado,
   usando os campos da tabela acima. Não adicionar configuração PHP/PostgreSQL.
4. Depois de conhecer o domínio HTTPS definitivo, conferir manualmente o Site
   URL e os Redirect URLs autorizados no Supabase Auth para recuperação e
   confirmação de e-mail. Nenhuma configuração Auth foi alterada nesta tarefa.
   Evitar depender de URLs temporárias de preview para a entrega final.
5. Após publicar, validar carregamento inicial, atualização da página e links
   de recuperação no domínio HTTPS. Navegar com duas contas próprias autorizadas
   para confirmar que logout e retorno pelo navegador não misturam perfis.
6. Confirmar no app Quero Adotar, Minhas Adoções, notificações, perfil e ficha do
   animal. Criar/aprovar/recusar/cancelar solicitações altera o banco real e exige
   autorização específica para esses dados; não foi realizado automaticamente.

Os SQLs 12 → 15 → 10 já foram instalados e o SQL 16 aprovou 20/20 verificações;
nunca executar migrações como parte do build/deploy. Os nove animais de
responsáveis antigos sem vínculo Auth continuam com a limitação conhecida,
sem invalidar os fluxos das contas vinculadas.

## Referências oficiais consultadas

- [Configuração do projeto Vercel](https://vercel.com/docs/project-configuration).
- [Configuração de build e saída](https://vercel.com/docs/builds/configure-a-build).
- [Build e publicação de Flutter Web](https://docs.flutter.dev/deployment/web).
