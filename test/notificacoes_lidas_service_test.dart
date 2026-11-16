import 'package:entre_patas/services/notificacoes_lidas_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('serviço novo recupera leitura gravada pelo serviço anterior', () async {
    await NotificacoesLidasService().marcarComoLida(1, 7, 'Aceito');
    expect(await NotificacoesLidasService().carregar(1), {(7, 'Aceito')});
  });

  test('leitura é isolada entre perfis', () async {
    final service = NotificacoesLidasService();
    await service.marcarComoLida(1, 7, 'Aceito');
    expect(await service.carregar(2), isEmpty);
    await service.marcarComoLida(2, 8, 'Recusado');
    expect(await service.carregar(1), {(7, 'Aceito')});
    expect(await service.carregar(2), {(8, 'Recusado')});
  });

  test('registro inválido não apaga as demais leituras salvas', () async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setStringList('entre_patas.notificacoes_lidas.v1.1', [
      'json inválido',
      '[7,"Aceito"]',
      '["8","Recusado"]',
    ]);
    expect(await NotificacoesLidasService().carregar(1), {(7, 'Aceito')});
  });

  test(
    'cliques concorrentes e repetidos preservam todas as leituras',
    () async {
      final service = NotificacoesLidasService();
      await Future.wait([
        service.marcarComoLida(1, 7, 'Aceito'),
        service.marcarComoLida(1, 8, 'Recusado'),
        service.marcarComoLida(1, 7, 'Aceito'),
      ]);
      expect(await service.carregar(1), {(7, 'Aceito'), (8, 'Recusado')});
    },
  );

  test(
    'dados persistidos sobrevivem a uma reinicialização do cache do plugin',
    () async {
      await NotificacoesLidasService().marcarComoLida(1, 7, 'Aceito');
      final preferencias = await SharedPreferences.getInstance();
      final persistidos = <String, Object>{
        for (final chave in preferencias.getKeys())
          chave: preferencias.get(chave)!,
      };
      SharedPreferences.setMockInitialValues(persistidos);
      expect(await NotificacoesLidasService().carregar(1), {(7, 'Aceito')});
    },
  );
}
