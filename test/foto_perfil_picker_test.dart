import 'dart:typed_data';
import 'dart:async';

import 'package:entre_patas/view/core/foto_perfil_picker.dart';
import 'package:entre_patas/services/foto_perfil_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import 'support/foto_perfil_fixture.dart';

void main() {
  testWidgets(
    'escolhe, mostra a prévia e permite remover a foto sem campo de link',
    (tester) async {
      Uint8List? foto;
      final selecionada = Completer<void>.sync();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => FotoPerfilPicker(
                foto: foto,
                onChanged: (_) {},
                onFotoChanged: (valor) {
                  setState(() => foto = valor);
                  if (!selecionada.isCompleted) selecionada.complete();
                },
                selecionarImagem: () async =>
                    XFile.fromData(fotoPng(), name: 'foto.png'),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
      await tester.runAsync(() async {
        await tester.tap(find.text('Escolher foto'));
        // A decodificação utiliza o codec nativo do engine.
        await selecionada.future.timeout(const Duration(seconds: 3));
      });
      await tester.pumpAndSettle();
      expect(foto, fotoPng());
      expect(find.byType(Image), findsOneWidget);
      expect(
        tester.widget<Image>(find.byType(Image)).image,
        isA<ResizeImage>().having(
          (imagem) => imagem.imageProvider,
          'imagem local',
          isA<MemoryImage>(),
        ),
      );
      await tester.tap(find.text('Remover foto'));
      await tester.pumpAndSettle();
      expect(foto, isNull);
      expect(find.byType(Image), findsNothing);
    },
  );

  testWidgets('cancelar seleção mantém foto anterior', (tester) async {
    var chamadas = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FotoPerfilPicker(
            foto: fotoPng(),
            onChanged: (_) {},
            onFotoChanged: (_) => chamadas++,
            selecionarImagem: () async => null,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Escolher foto'));
    await tester.pumpAndSettle();
    expect(chamadas, 0);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('arquivo inválido preserva a seleção anterior e mostra erro', (
    tester,
  ) async {
    var chamadas = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FotoPerfilPicker(
            foto: fotoPng(),
            onChanged: (_) {},
            onFotoChanged: (_) => chamadas++,
            selecionarImagem: () async =>
                XFile.fromData(Uint8List.fromList([1, 2]), name: 'arquivo.svg'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Escolher foto'));
    await tester.pumpAndSettle();
    expect(chamadas, 0);
    expect(find.text('Escolha uma imagem JPG, PNG ou WebP.'), findsOneWidget);
  });

  test('arquivo vazio, SVG e foto acima de 2 MB são recusados', () {
    for (final foto in [
      Uint8List(0),
      Uint8List.fromList('<svg/>'.codeUnits),
      Uint8List(FotoPerfilStorageService.limiteBytes + 1),
    ]) {
      expect(() => FotoPerfilStorageService.validarFoto(foto), throwsException);
    }
    expect(FotoPerfilStorageService.validarFoto(fotoPng()).mime, 'image/png');
  });
}
