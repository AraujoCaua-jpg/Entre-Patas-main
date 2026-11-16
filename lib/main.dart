import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'controller/clientes_scope.dart';
import 'view/core/app_colors.dart';
import 'view/core/recuperacao_senha_navigation.dart';
import 'view/core/pagina_atual_navigation.dart';
import 'view/core/restaurar_sessao_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialização do Supabase
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://cyaxnaflvnjnpryryorr.supabase.co',
    ),
    publishableKey: const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: 'sb_publishable_o7AOqXaOmZPBOvLkdOaUlA_zOjheN83',
    ),
  );

  // Captura também o link de recuperação recebido na inicialização do app.
  final recuperacaoSenha = RecuperacaoSenhaNavigation();

  // Inicialização do aplicativo
  runApp(MeuApp(recuperacaoSenha: recuperacaoSenha));
}

class MeuApp extends StatefulWidget {
  const MeuApp({super.key, this.recuperacaoSenha});

  final RecuperacaoSenhaNavigation? recuperacaoSenha;

  @override
  State<MeuApp> createState() => _MeuAppState();
}

class _MeuAppState extends State<MeuApp> {
  late final _recuperacaoSenha =
      widget.recuperacaoSenha ?? RecuperacaoSenhaNavigation();
  late final _paginaAtual = PaginaAtualNavigation();

  @override
  void dispose() {
    _recuperacaoSenha.dispose();
    _paginaAtual.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClientesScope(
      child: MaterialApp(
        navigatorKey: _recuperacaoSenha.navigatorKey,
        navigatorObservers: [_recuperacaoSenha, _paginaAtual],
        builder: (context, child) {
          _recuperacaoSenha.navigatorConstruido();
          return child!;
        },
        debugShowCheckedModeBanner: false,
        title: 'Entre Patas',
        theme: ThemeData(
          fontFamily: 'NunitoSans',
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.laranja),
          useMaterial3: true,
        ),
        home: const RestaurarSessaoScreen(),
      ),
    );
  }
}
