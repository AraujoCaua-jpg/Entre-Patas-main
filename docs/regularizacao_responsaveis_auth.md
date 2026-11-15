# Regularização de responsáveis sem vínculo Auth

## Situação conhecida

O snapshot de 14/11/2026 encontrou **nove animais ativos/Disponível cujo
responsável não possui `auth_user_id`**. Isso não significa nove pessoas: um
mesmo perfil pode ser responsável por vários animais. Uma das onze linhas de
animais ativos/Disponível tem responsável inativo; os grupos podem se sobrepor.
As duas solicitações antigas também têm algum participante sem vínculo Auth.

Nenhum desses registros foi excluído, reatribuído, vinculado ou reativado. A RLS
continua filtrando contas inativas. Os dados agregados não provam identidade,
propriedade de conta ou consentimento para um novo vínculo.

## Consequência no uso do aplicativo

O SQL 10 identifica o usuário por Auth e exige um perfil ativo. Um responsável
sem vínculo não consegue entrar como proprietário desses animais para receber
e decidir pedidos. Instalar SQL 10 não cria esse vínculo. Um pedido antigo deve
continuar preservado até a regularização; não atribuí-lo a uma das contas da
equipe para tornar uma demonstração funcional.

Para testar a entrega, cada integrante usa sua própria conta e publica um animal
fictício **apenas no ambiente de testes**, com responsável corretamente vinculado.
A demonstração não comprova regularização dos animais antigos.

## Processo proposto, sem execução automática

1. Gerar inventário privado agrupado por `cliente.id`, com quantidade de animais
   e pedidos relacionados, situação da conta e presença de vínculo Auth. Não
   incluir nomes, e-mails, documentos ou telefones em issues/relatórios públicos.
2. Confirmar identidade e responsabilidade por canal privado e confiável. Nome
   ou e-mail coincidente, isoladamente, não autoriza associação. Verificar também
   se o registro representa pessoa, lar de adoção ou organização com operador
   autorizado. Não compartilhar senhas nem a conta de outro integrante.
3. Determinar se essa pessoa já possui Auth e se o Auth já está associado a outro
   `cliente.id`. Conferir unicidade, status e dependências antes de propor mudança.
4. Se precisar criar Auth, revisar antes o trigger atual de cadastro. O cadastro
   normal do app cria um perfil novo e pode colidir com e-mail/telefone/usuário
   do legado. Não orientar simplesmente repetir o cadastro nem contornar o gatilho.
   Planejar com o responsável pelo backend um fluxo controlado de recuperação
   que preserve a identidade do perfil antigo e os controles de autenticação.
5. Se já houver perfil novo e perfil legado para a mesma pessoa, interromper o
   vínculo simples. Inventariar ambos: animais, adoções como dono/adotante,
   questionários e demais referências. Preparar reconciliação transacional
   específica, com backup e autorização separados; não apagar perfil ou mover
   FKs automaticamente para contornar a restrição única de Auth.
6. Registrar proposta individual com `cliente.id` preservado, Auth de destino
   confirmado, prova de autorização fora do Git, impacto esperado e recuperação.
   Obter aprovação explícita antes de qualquer escrita. Não atribuir um Auth
   usado por outra pessoa nem fazer associação em massa por nome/e-mail.
7. Aplicar apenas a mudança individual aprovada, com verificações de pré/pós,
   sem alterar `animal.id`, `animal.id_cliente`, IDs/participantes de adoções ou
   histórico por conveniência. Mudanças adicionais precisam de plano próprio.
8. A pessoa autentica-se normalmente e confirma acesso somente ao próprio perfil,
   animais e solicitações, enquanto outra conta continua sem acesso privado.
   Registrar sucesso/falha sem tokens, senhas ou dados pessoais no relatório público.

## Status da conta e preservação

Vincular Auth não autoriza ativar um perfil desabilitado. Caso `ativo` esteja
falso ou nulo, investigar a razão e a legitimidade da conta; eventual ativação
exige decisão e autorização próprias. Não reativar usuários automaticamente,
alterar status de adoções, liberar RLS ou conceder privilégios administrativos.

Manter os registros sem comprovação no estado atual e registrar a pendência.
Se o responsável não puder ser identificado, a política de exibição/recebimento
de novos pedidos desses animais precisa de decisão do produto e revisão própria;
não excluir os animais ou criar contas/vínculos fictícios para encerrar a fila.

## Critérios de conclusão por responsável

- Identidade, responsabilidade e autorização comprovadas em registro privado.
- Um vínculo Auth legítimo e único, sem conflito com outro perfil.
- Perfil antigo e seus identificadores preservados; dependências reconciliadas
  somente quando houver plano individual aprovado.
- Nenhuma alteração involuntária de `ativo`, propriedade, histórico ou respostas.
- Login, listagem própria, consulta/decisão de pedidos e isolamento entre contas
  confirmados com o responsável, sem exposição de contatos a terceiros.
- Backup e recuperação preparados antes da operação e resultado documentado.

**Situação atual: pendente de comprovação e autorização individual.** Nenhuma
regularização foi executada nesta tarefa. Ver também
[revisão do SQL 10](revisao_sql10_producao.md) e
[backup e recuperação](backup_recuperacao_supabase.md).
