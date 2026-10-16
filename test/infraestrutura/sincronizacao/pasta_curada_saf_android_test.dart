import 'package:appcifras/aplicacao/portas/pasta_curada_externa.dart';
import 'package:appcifras/infraestrutura/sincronizacao/pasta_curada_saf_android.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const canal = MethodChannel('teste/pasta_curada');
  const pasta = PastaCuradaSafAndroid(canal: canal);

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, null);
  });

  test('mantém URIs opacas ao selecionar e enumerar documentos', () async {
    final chamadas = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canal, (chamada) async {
          chamadas.add(chamada);
          return switch (chamada.method) {
            'selecionarPasta' => {
              'uri': 'content://provider/tree/id%2Fopaco',
              'nome': 'Cifras',
            },
            'listarFilhosDiretos' => [
              {
                'localizador': 'content://provider/document/id%3Aarquivo',
                'nome': 'musica.cho',
                'tipoMime': 'text/plain',
                'ehDiretorio': false,
              },
            ],
            _ => null,
          };
        });

    final selecionada = await pasta.selecionarPasta();
    final documentos = await pasta.listarFilhosDiretos(selecionada!.uriArvore);

    expect(selecionada.uriArvore, 'content://provider/tree/id%2Fopaco');
    expect(
      documentos.single.localizador,
      'content://provider/document/id%3Aarquivo',
    );
    expect((chamadas.last.arguments as Map)['uri'], selecionada.uriArvore);
  });

  test('leitura pelo canal preserva os bytes exatos', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          canal,
          (_) async => Uint8List.fromList([0, 10, 13, 255]),
        );
    final documento = DocumentoPastaCurada(
      localizador: 'content://provider/document/arquivo',
      nome: 'arquivo.cho',
      ehDiretorio: false,
    );

    expect(await pasta.lerBytes(documento), [0, 10, 13, 255]);
  });

  test('traduz autorização revogada sem apagar estado local', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          canal,
          (_) async => throw PlatformException(
            code: 'access_revoked',
            message: 'revogada',
          ),
        );

    await expectLater(
      pasta.verificarAcesso('content://provider/tree/curada'),
      throwsA(
        isA<FalhaPastaCurada>().having(
          (erro) => erro.tipo,
          'tipo',
          TipoFalhaPastaCurada.autorizacaoRevogada,
        ),
      ),
    );
  });
}
