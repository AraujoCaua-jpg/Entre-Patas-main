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

Os botões das fichas aceitam `donoId`. As telas de animais e adoções ainda usam
exemplos: seus registros precisam ser integrados para fornecer IDs reais. A aba
de usuários pesquisa o banco; a aba Pets ainda filtra os exemplos locais.

## Testes

```powershell
flutter test
C:\xampp\php\php.exe test\backend_login_test.php
C:\xampp\php\php.exe test\clientes_backend_test.php
```

Os testes PHP usam contas temporárias e as removem ao terminar; o contador de IDs
pode avançar. Não alteram as contas existentes.
