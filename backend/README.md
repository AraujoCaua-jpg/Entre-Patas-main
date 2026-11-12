# API local do Entre Patas

Copie os arquivos PHP e `.htaccess` desta pasta para `C:\xampp\htdocs\entrepatas-api`.
Mantenha Apache e MySQL ligados. O banco `entrepatas` deve ter as tabelas originais
e `cliente.id` com AUTO_INCREMENT. Não coloque dumps com dados reais no repositório.

Prepare a tabela auxiliar de recuperação pela linha de comando:

```powershell
C:\xampp\php\php.exe backend\migrar.php
```

O padrão local é MySQL `localhost`, banco `entrepatas`, usuário `root` sem senha.
O login e as novas rotas aceitam `DB_USER` e `DB_PASSWORD` no ambiente do servidor.
A rota de cadastro ainda usa a configuração local no próprio arquivo.

## Rotas

Todas retornam JSON. Login retorna `token` e `cliente`; não retorna senha nem hash.
Nas rotas autenticadas use o cabeçalho `Authorization: Bearer TOKEN`.
A sessão vale por uma hora e fica em memória no aplicativo: após fechar/recarregar,
faça login novamente. Trocar a senha ou desativar a conta invalida sessões anteriores.

| Método | Rota | Uso |
| --- | --- | --- |
| POST | cadastrar_cliente.php | Cadastro |
| POST | login.php | Entrar com email e senha |
| GET | sessao.php | Conferir sessão |
| POST | logout.php | Encerrar sessão |
| GET | clientes.php | Próprio perfil completo |
| GET | clientes.php?acao=id&id=1 | Perfil público ou próprio perfil completo |
| GET | clientes.php?acao=basico&id=1 | ID, nome, usuário e imagem |
| GET | clientes.php?acao=buscar&q=ana | Nome ou usuário; até 50 resultados ativos |
| POST | clientes.php?acao=editar | Atualizar apenas o usuário da sessão |
| POST | clientes.php?acao=apagar | Exclusão lógica (`ativo=0`) |
| POST | senha.php | `senhaAtual`, `novaSenha`; exige sessão |
| POST | senha.php?acao=solicitar | `email`; solicita código |
| POST | senha.php?acao=recuperar | `codigo`, `novaSenha`; código de uso único |

Perfis públicos comuns não incluem e-mail, telefone ou endereço. Lares de adoção
exibem os contatos previstos pela tela do produto. Senhas e seus hashes não são
retornados por nenhuma dessas consultas.

## Recuperação por e-mail: configuração ainda necessária

O e-mail na tabela não fornece um serviço de envio. É necessário configurar o
transporte de e-mail do PHP/XAMPP (SMTP ou sendmail com um provedor) e definir no
ambiente do Apache `RECOVERY_MAIL_ENABLED=1` e `RECOVERY_FROM` com um remetente válido.
Reinicie o Apache após alterar seu ambiente. Não salve credenciais no Git.
Sem configuração a tela informa indisponibilidade; não libera troca apenas por e-mail.

Quando configurado, o código é enviado por e-mail, expira em 15 minutos e não é
retornado à tela nem armazenado em texto puro no banco. O teste automatizado
insere um código temporário diretamente no banco para validar o consumo, sem
simular que o e-mail foi entregue. Entrega real ainda precisa ser validada.

## Aplicativo

Navegador: `flutter run -d chrome`.
Emulador Android: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2/entrepatas-api`.
Os endereços HTTP e a lista CORS local servem ao desenvolvimento. Publicação em
servidor requer configurar HTTPS, origens permitidas e proteção contra tentativas
repetidas de login antes de disponibilizar autenticação publicamente.

As telas de animais (início, pesquisa, ficha, publicação, edição e animais do
responsável) consultam `animais.php`. A região vem de `cliente.estado` e
`cliente.cidadeDeResidencia`, pelo vínculo `animal.id_cliente`. As solicitações
de adoção e notificações consultam `adocoes.php`; o questionário é persistido
por `questionario.php`. As telas mantêm as cores e os componentes do projeto.

## Animais

Copie `animais.php`, `compatibilidade.php`, `questionario.php` e `adocoes.php`
para a pasta da API no XAMPP. Execute uma vez (pode repetir sem apagar dados):

```powershell
C:\xampp\php\php.exe backend\migrar_animais.php
```

Essa migração coloca AUTO_INCREMENT nos IDs de `questionario` e `adocao` e
adiciona ao questionário as respostas de preparo (`imovel`, `apoio`,
`compromisso`, `moradores`, `financeiro`, `rotina`). Cria também
`cliente.questionario_pendente` com padrão 0, dispensando contas existentes.
Novos cadastros pela API recebem 1; salvar o teste muda para 0.
Adiciona ainda `animal.vacinado` e `animal.castrado` (VARCHAR(5), NULL por
padrão). Registros antigos ficam sem informação até serem editados.
A tabela `animal` deve
ter `id` com AUTO_INCREMENT e `ativo` NOT NULL DEFAULT 1. O vínculo com o
responsável é `animal.id_cliente` → `cliente.id`. Idade é inteira em anos:
zero representa menos de um ano. Todos os endpoints exigem sessão Bearer.

| Método | Rota | Uso |
| --- | --- | --- |
| GET | animais.php | Animais ativos de responsáveis ativos |
| GET | animais.php?acao=id&id=1 | Ficha por ID |
| GET | animais.php?acao=usuario&id_cliente=1 | Animais por responsável |
| GET | animais.php?q=lua | Pesquisa parcial pelo nome |
| POST | animais.php?acao=cadastrar | Cadastro vinculado à sessão |
| POST | animais.php?acao=editar&id=1 | Editar o próprio animal |
| POST | animais.php?acao=apagar&id=1 | Exclusão lógica do próprio animal |

Filtros combináveis: `estado`, `cidade`, `tipo`, `sexo`, `porte`, `energia`,
`convivencia`, `carencia`, `status`, `id_cliente`, `q`. A listagem retorna até
50 registros por página; use `pagina=2` para continuar. A interface oferece
"Carregar mais" na lista principal e na lista por responsável.

Cadastro e edição recebem JSON com `nome`, `idade`, `imagem` (URL HTTP/HTTPS
opcional), `tipo`, `descricao`, `sexo`, `status`, `energia`, `porte`, `convivencia`
e `carencia`, além de `vacinado` e `castrado` (`Sim`, `Não` ou `null` para dados
não informados). O servidor define o responsável e o estado ativo. Apenas o
responsável pode editar ou desativar o animal. Os controles originais de
vacinação e castração salvam as respostas, recuperam os valores na edição e
exibem os dados na ficha. A interface exige ambas as respostas para salvar.
Clientes antigos que omitem esses campos na edição não apagam os valores
existentes. Esses dados não modificam a fórmula de compatibilidade.

## Compatibilidade e solicitações de adoção

`GET questionario.php` recupera apenas as respostas do usuário da sessão.
`POST questionario.php` salva ou atualiza seu teste completo. O usuário não pode
alterar respostas de outra pessoa enviando um ID no corpo. Respostas antigas
incompletas são tratadas como teste não concluído.

As respostas das etapas A, B e C passam entre as telas; a conclusão só aparece
após a confirmação do banco. Após autenticar, somente contas com
`questionario_pendente=1` consultam o questionário e abrem automaticamente a
introdução se ele estiver incompleto. Contas anteriores à migração entram
direto no Início, mesmo sem respostas. Novas contas que concluíram o teste
também entram direto. Se a consulta necessária falhar, o login exibe o erro.
Não há botão de teste no Início; a ficha permite refazer o questionário.
As rotas de animais retornam `compatibilidade`
com `rotina`, `ambiente`, `preferencias`, `total` e `versao`, ou `null` sem teste
completo. O início usa `animais.php?acao=melhores`, que ordena por nota antes de
paginar. Os cartões mostram o percentual real; a ficha detalha as três notas.
Para animais do próprio usuário, a API retorna compatibilidade `null` mesmo
com questionário concluído. Na ficha, o responsável vê "Publicado por você",
sem botão de adoção ou seção de compatibilidade.

A regra de afinidade, versão 1, usa `(Rotina*5 + Ambiente*3 + Preferências*2)/10`:

- Rotina: dedicação versus energia, tempo sozinho versus carência, e preparo
  informado na etapa C. As seis respostas de preparo têm o mesmo peso; o
  financeiro usa 0, 0,5 ou 1 para as três opções.
- Ambiente: espaço em relação à espécie/porte e convivência com outros animais.
  Gatos e animais pequenos têm nota de espaço 100. Para os demais, quintal
  recebe 100; casa sem quintal recebe 80 (médio) ou 60 (grande); apartamento
  recebe 60 (médio) ou 40 (grande); outro recebe 50. Incompatibilidade de
  convivência recebe 0 nesse item, com peso igual ao espaço.
- Preferências: espécie, sexo, faixa etária, porte e energia têm pesos iguais.
  Porte e energia descontam metade por nível de distância; os demais são
  correspondência completa ou zero.

O cálculo é uma regra explicável do produto, não uma garantia de adaptação.
A nota não aprova nem impede automaticamente uma solicitação.

| Método | Rota | Uso |
| --- | --- | --- |
| GET | adocoes.php | Solicitações enviadas e recebidas pela sessão |
| GET | adocoes.php?acao=id&id=1 | Detalhes, só para solicitante/responsável |
| POST | adocoes.php?acao=solicitar | JSON `{"id_animal":1}`; cria Aguardando |
| POST | adocoes.php?acao=aceitar&id=1 | Responsável aprova |
| POST | adocoes.php?acao=recusar&id=1 | Responsável recusa |
| POST | adocoes.php?acao=cancelar&id=1 | Solicitante cancela |

O servidor define IDs de solicitante e responsável, data e status. Não permite
solicitar o próprio animal nem duplicar pedido pendente. Apenas pedidos
Aguardando podem mudar. A aprovação trava o registro do animal em transação,
marca `animal.status=Adotado` e recusa os demais pedidos pendentes; editar a
ficha não reabre um animal adotado. Animais ou responsáveis inativos não
recebem novos pedidos. As solicitações permanecem como histórico.

Antes do envio, a tela confirma o compartilhamento de nome, e-mail e telefone
do solicitante com o responsável. Esses dados só aparecem nos detalhes/listas
das duas partes. Notificações são consultadas ao abrir a tela ou tocar em
Atualizar; não há push ou e-mail automático de adoção.

Para conferir visualmente com duas contas:

1. Na primeira conta, publique um animal.
2. Crie uma segunda conta e faça login; o teste abrirá automaticamente.
   Conclua as três etapas e toque em Concluir para entrar no Início.
3. Abra a ficha, confira a nota e toque em Quero Adotar → Enviar solicitação.
4. Na primeira conta, abra o sino de notificações e aprove ou recuse o pedido.
5. Na segunda, consulte o resultado pelo sino. Para testar cancelamento,
   envie outro pedido e cancele antes da decisão do responsável.

## Testes

```powershell
flutter test
C:\xampp\php\php.exe test\backend_login_test.php
C:\xampp\php\php.exe test\clientes_backend_test.php
C:\xampp\php\php.exe test\animais_backend_test.php
C:\xampp\php\php.exe test\adocoes_backend_test.php
```

Os testes PHP usam contas temporárias e as removem ao terminar; o contador de IDs
pode avançar. Não alteram as contas existentes.
Os testes de animais e adoções usam `http://127.0.0.1:8091` por padrão: execute antes
`C:\xampp\php\php.exe -S 127.0.0.1:8091 -t backend`, ou defina `API_BASE_URL`
com o endereço da API que contém `animais.php`.
