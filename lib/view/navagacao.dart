import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../controller/clientes_scope.dart';
import '../controller/cliente_controller.dart';

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
  Timer? _timer;
  ClienteController? _clientes;
  bool _consultando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _clientes = ClientesScope.of(context);
    if (_timer == null) {
      _atualizarNotificacoes();
      _timer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => _atualizarNotificacoes(),
      );
    }
  }

  Future<void> _atualizarNotificacoes() async {
    if (_consultando || _clientes?.clienteLogado == null) return;
    _consultando = true;
    try {
      await _clientes!.atualizarNotificacoes();
    } catch (_) {
      // Mantém a última contagem e tenta novamente na próxima atualização.
    } finally {
      _consultando = false;
    }
  }

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
    _timer?.cancel();
    controller.removeListener(atualizarTela);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 1000;
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
            tooltip: 'Notificações: ${_clientes?.totalNotificacoes ?? 0} novas',
            icon: Badge(
              isLabelVisible: (_clientes?.totalNotificacoes ?? 0) > 0,
              backgroundColor: const Color(0xFFD96C3F),
              textColor: Colors.white,
              label: Text('${_clientes?.totalNotificacoes ?? 0}'),
              child: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFFD96C3F),
              ),
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificacoesScreen(),
                ),
              );
              if (mounted) await _atualizarNotificacoes();
            },
          ),
        ],
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFD96C3F), width: 2),
        ),
      ),

      body: Row(
        children: [
          SizedBox(
            width: desktop ? 220 : 0,
            child: desktop
                ? NavigationRail(
                    extended: true,
                    backgroundColor: const Color(0xFFFFF3ED),
                    selectedIndex: controller.paginaAtual,
                    onDestinationSelected: controller.mudarPagina,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.home_outlined),
                        label: Text('Início'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.search),
                        label: Text('Pesquisa'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.person_outline),
                        label: Text('Perfil'),
                      ),
                    ],
                  )
                : null,
          ),
          Expanded(
            child: IndexedStack(
              index: controller.paginaAtual,
              children: paginas,
            ),
          ),
        ],
      ),

      bottomNavigationBar: desktop
          ? null
          : NavigationBarTheme(
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
