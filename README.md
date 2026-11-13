# 🐾 Entre Patas

![Dart](https://img.shields.io/badge/Dart-259acf?style=for-the-badge&logo=dart&logoColor=white)	
![Flutter](https://img.shields.io/badge/Flutter-259acf?style=for-the-badge&logo=flutter&logoColor=white)	
![PHP](https://img.shields.io/badge/PHP-777BB4?style=for-the-badge&logo=php&logoColor=white)
![XAMPP](https://img.shields.io/badge/XAMPP-FB7A24?style=for-the-badge&logo=xampp&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)

## Sobre o projeto

O **Entre Patas** é um projeto acadêmico de aplicativo para adoção de animais, desenvolvido para apresentação no Summit da Universidade de Mogi das Cruzes (UMC).

A proposta é aproximar adotantes, animais e organizações de acolhimento por meio de uma experiência digital acessível. O aplicativo conta com a proposta de um questionário de compatibilidade, que ajuda o usuário a refletir sobre seu perfil e as necessidades do animal antes de solicitar a adoção.

O projeto busca contribuir para adoções mais conscientes, oferecendo informações sobre os animais, pesquisa por região e acompanhamento das solicitações.

## Objetivos

- Facilitar a descoberta de animais disponíveis para adoção.
- Apoiar escolhas responsáveis por meio de um teste de compatibilidade.
- Disponibilizar perfis detalhados dos animais e dos responsáveis pelas publicações.
- Permitir que adotantes enviem e acompanhem solicitações.
- Oferecer às organizações recursos para cadastrar e gerenciar animais.

## Funcionalidades previstas

| Área | Funcionalidades |
|---|---|
| **Acesso** | Boas-vindas, cadastro, login e recuperação de senha. |
| **Usuário** | Perfil do adotante e edição de dados. |
| **Animais** | Listagem, pesquisa, filtros e ficha detalhada. |
| **Compatibilidade** | Questionário de preferências e indicação de afinidade com os animais. |
| **Adoção** | Solicitação com identificação do animal, publicador e adotante, data/hora e acompanhamento de status. |
| **Organizações** | Perfil de abrigo/lar e cadastro e gestão de animais. |
| **Comunicação** | Notificações sobre atualizações do processo; chat previsto no escopo de telas. |

> **Observação:** esta tabela representa o escopo do produto. A existência de uma tela no Figma não comprova que sua lógica esteja implementada no Flutter.

## Telas e experiência do usuário

O protótipo do Entre Patas foi elaborado no Figma, com foco em navegação simples e identidade visual acolhedora. Entre as telas projetadas estão:

- Boas-vindas, login e cadastro;
- Página inicial com destaques e animais sugeridos;
- Pesquisa e filtros de animais;
- Ficha do animal com fotos, descrição, características, localização e compatibilidade;
- Questionário de compatibilidade;
- Perfil do adotante e perfil do abrigo;
- Solicitação e acompanhamento da adoção;
- Cadastro e gestão de animais;
- Notificações.

### Exemplo de jornada: adoção do Bolt

1. O usuário encontra Bolt na listagem ou na pesquisa.
2. Abre a ficha para consultar fotos, descrição, porte, idade, localização e informações de saúde.
3. Visualiza uma indicação de compatibilidade (por exemplo, **95%**, valor ilustrativo utilizado no protótipo).
4. Seleciona **“Quero adotar o Bolt”**.
5. Confere o animal, quem publicou, seus dados e os detalhes da solicitação.
6. Envia a solicitação e acompanha o andamento até a conclusão do processo.

> Os nomes, percentuais, datas e dados pessoais apresentados nos mockups são exemplos de demonstração, não registros reais.

## Tecnologias e ferramentas

| Tecnologia/Ferramenta | Utilização |
|---|---|
| **Flutter** | Desenvolvimento da interface do aplicativo. |
| **Dart** | Linguagem de programação. |
| **Figma** | Prototipação UX/UI e navegação entre telas. |
| **Git e GitHub** | Versionamento e colaboração. |
| **Trello** | Organização de tarefas e sprints. |
| **Banco de dados** | Persistência de usuários, animais e adoções. A tecnologia e a integração final ainda precisam ser confirmadas. |

A organização do código em `models` e `controllers` faz parte da abordagem de desenvolvimento discutida pela equipe. A estrutura efetiva do repositório deve ser confirmada no código-fonte.

## Prints do aplicativo

| Tela | Imagem |
|---|---|
| Página inicial | `docs/images/home.png` |
| Login e cadastro | `docs/images/login.png` |
| Pesquisa de animais | `docs/images/pesquisa.png` |
| Ficha do animal | `docs/images/ficha-animal.png` |
| Teste de compatibilidade | `docs/images/compatibilidade.png` |
| Solicitação de adoção | `docs/images/adocao.png` |
| Perfil | `docs/images/perfil.png` |

## Planejamento das sprints

| Sprint | Prazo planejado | Entregas previstas |
|---|---|---|
| **Sprint 1** | Até 02/11 | Telas do aplicativo; CRUD de usuários e telas de cadastro; CRUD de animais; CRUD de adoção. |
| **Sprint 2** | Até 09/11 | Conexão com banco de dados; teste de compatibilidade; edição e exibição do perfil; exibição de animais; telas de adoção e notificações. |
| **Sprint 3** | Até 12/11 | Testes, validação de fluxos e correção de bugs. |

> Os prazos acima correspondem ao planejamento informado pela equipe; não indicam, por si só, a conclusão das entregas.

## Testes recomendados

- Cadastro, autenticação e validação de campos;
- Criação, consulta, edição e remoção autorizada de registros;
- Carregamento de animais e filtros de pesquisa;
- Navegação entre telas e carrossel de fotos;
- Cálculo e apresentação da compatibilidade;
- Envio de solicitações sem duplicidade acidental;
- Registro de data/hora, mudanças de status e notificações;
- Tratamento de erros e responsividade.

## Estado do projeto

O projeto possui protótipos de diversas telas no Figma e atividades de desenvolvimento em Flutter/Dart.

A apresentação do Summit descreve a idealização como concluída e a prototipação/desenvolvimento como em andamento na versão revisada. A conclusão da integração com banco de dados, dos CRUDs e dos testes precisa ser validada no repositório.

### Fluxo básico de trabalho

```bash
# Atualize sua branch com as alterações da branch principal
git pull origin main

# Confira os arquivos modificados
git status

# Adicione as alterações
git add .

# Crie um commit
git commit -m "feat: implementa listagem de animais"

# Envie sua branch para o GitHub
git push origin <nome-da-branch>
```

O comando `git pull origin main` pressupõe que a branch principal seja `main`; confirme o nome utilizado pelo grupo. Para evitar conflitos, trabalhem em branches individuais e integrem as alterações por pull request, quando possível.

Revise `git status` antes de adicionar arquivos e não envie senhas, tokens ou arquivos de configuração sensíveis.

### Evidências de participação

- Cada integrante deve usar sua própria conta e configurar `git config user.name` e `git config user.email` com seus dados.
- Fazer commits frequentes ao longo das sprints, em vez de um único commit no fim.
- Manter mensagens que descrevam a alteração realizada.
- Registrar as contribuições de desenvolvimento, prototipação exportada e documentação quando esses arquivos fizerem parte do repositório.
- Verificar o histórico na aba **Commits** do GitHub ou com `git log --oneline --all`.

> Este README documenta a prática esperada; a frequência e a autoria real dos commits precisam ser comprovadas pelo histórico do repositório. Não se deve criar commits artificiais ou atribuir trabalho a outra pessoa.

## Como executar localmente

Estas são instruções gerais para um projeto Flutter. Dependências, variáveis de ambiente e configurações específicas devem ser verificadas no repositório.

### Pré-requisitos

- Flutter SDK;
- Dart SDK;
- Editor compatível, como Visual Studio Code.

### Instalação


```bash
# Clone o repositório (substitua pela URL oficial)
git clone https://github.com/AraujoCaua-jpg/Entre-Patas-main.git

# Entre na pasta do projeto
cd Entre-Patas-main

# Instale as dependências
flutter pub get

# Confira o ambiente
flutter doctor

# Execute o aplicativo
flutter run
```

Caso o aplicativo utilize banco de dados ou serviços externos, configure-os conforme as instruções da equipe antes da execução.

## Próximos passos

- Finalizar as funcionalidades ainda pendentes no Flutter;
- Integrar e validar a persistência de dados;
- Testar o questionário e as regras de compatibilidade;
- Validar o fluxo completo de solicitação e aprovação de adoções;
- Realizar testes com usuários e organizações;
- Preparar uma versão demonstrável para apresentação e avaliação.

## Contexto acadêmico

Esse projeto desenvolvido para o Curso de Engenharia de Software do 4º Semestre da UMC nas disciplinas de Desenvolvimento de Aplicações e Métodos Ágeis e para o SUMMIT da Revista Científica da UMC

---

## 👤 Autores
Equipe de desenvolvimento e respectivas funções:

| Integrante | Atuação apresentada | GitHub |
|---|---|---|
| Cauã Araújo Marques | Desenvolvimento e integração | <a href="https://github.com/AraujoCaua-jpg"><img src="https://img.shields.io/badge/AraujoCaua-181717?style=for-the-badge&logo=github&logoColor=white" alt="AraujoCaua-jpg"></a> |
| Lucas Alves Siqueira | UX/UI Design e prototipação | <a href="https://github.com/LucasSiq31"><img src="https://img.shields.io/badge/LucasSiq31-181717?style=for-the-badge&logo=github&logoColor=white" alt="LucasSiq31"></a> |
| Yasmim Camilli da Silva Pacheco | Planejamento e desenvolvimento | <a href="https://github.com/YasmimPacheco"><img src="https://img.shields.io/badge/YasmimPacheco-181717?style=for-the-badge&logo=github&logoColor=white" alt="YasmimPacheco"></a> |

**Orientadores:** Alessandra da Silva Martins e Higor Barreto Campos.
