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
        toolbarHeight: 88,
        centerTitle: false,
        titleSpacing: 24,
        surfaceTintColor: Colors.transparent,
        title: Image.asset('assets/logo.png', height: 32, fit: BoxFit.contain),
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

      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: const Color(0xFFFFF3ED),
          indicatorColor: Colors.transparent,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              size: 30,
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFFFF642F)
                  : const Color(0xFF909090),
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontSize: 11,
              color: states.contains(WidgetState.selected)
                  ? const Color(0xFFFF642F)
                  : const Color(0xFF909090),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: controller.paginaAtual,

          onDestinationSelected: (indice) {
            controller.mudarPagina(indice);
          },

          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_outlined),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'Pesquisa',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_outline),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
