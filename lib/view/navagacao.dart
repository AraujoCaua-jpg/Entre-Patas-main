import 'package:material_ui/material_ui.dart';

import '../controller/navegacao_controller.dart';
import './principal/home.dart';
import './principal/pesquisa.dart';
import './principal/perfil.dart';
import './principal/notificacoes.dart';

class NavegacaoScreen extends StatefulWidget {
  const NavegacaoScreen({super.key});

  @override
  State<NavegacaoScreen> createState() => _NavegacaoScreenState();
}

class _NavegacaoScreenState extends State<NavegacaoScreen> {
  final NavegacaoController controller = NavegacaoController();

  final List<Widget> paginas = const [
    HomeScreen(),
    PesquisaScreen(),
    PerfilScreen(),
  ];

  final List<String> titulos = const ['Início', 'Pesquisa', 'Perfil'];

  @override
  void initState() {
    super.initState();
    controller.addListener(atualizarTela);
  }

  void atualizarTela() {
    setState(() {});
  }

  @override
  void dispose() {
    controller.removeListener(atualizarTela);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logo.png', height: 25, fit: BoxFit.contain),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFFD96C3F),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificacoesScreen(),
                ),
              );
            },
          ),
        ],
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFD96C3F), width: 2),
        ),
      ),

      body: IndexedStack(index: controller.paginaAtual, children: paginas),

      bottomNavigationBar: NavigationBar(
        selectedIndex: controller.paginaAtual,

        onDestinationSelected: (indice) {
          controller.mudarPagina(indice);
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Pesquisa',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
