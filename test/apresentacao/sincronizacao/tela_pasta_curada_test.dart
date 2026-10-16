import 'dart:typed_data';

import 'package:appcifras/aplicacao/portas/pasta_curada_externa.dart';
import 'package:appcifras/aplicacao/portas/repositorio_sincronizacao.dart';
import 'package:appcifras/aplicacao/sincronizacao/configuracao_pasta_sincronizada.dart';
import 'package:appcifras/aplicacao/sincronizacao/gerenciar_pasta_curada.dart';
import 'package:appcifras/apresentacao/sincronizacao/tela_pasta_curada.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('seleciona pasta e mostra quantidade de arquivos .cho', (
    tester,
  ) async {
    final repositorio = _RepositorioConfiguracaoMemoria();
    final externa = _PastaExternaFake(
      selecao: PastaCuradaSelecionada(
        uriArvore: 'content://provider/tree/curada',
        nomeLegivel: 'Cifras do Drive',
      ),
      filhos: [
        _documento('um.cho'),
        _documento('dois.CHO'),
        _documento('leia-me.txt'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TelaPastaCurada(
          gerenciarPastaCurada: GerenciarPastaCurada(externa, repositorio),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Nenhuma pasta selecionada'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('selecionar-pasta-curada')));
    await tester.pump();
    expect(find.text('Cifras do Drive'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ler-pasta-curada')));
    await tester.pump();
    expect(find.text('2 arquivos .cho encontrados.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('leitura-pasta-curada-confirmada')),
      findsOneWidget,
    );
    expect(externa.leituras, 1);
  });

  testWidgets('mostra autorização revogada sem limpar a pasta configurada', (
    tester,
  ) async {
    final configuracao = ConfiguracaoPastaSincronizada(
      uriArvore: 'content://provider/tree/curada',
      autorizacaoPersistente: true,
      nomeLegivel: 'Cifras',
    );
    final repositorio = _RepositorioConfiguracaoMemoria()
      ..configuracao = configuracao;
    final externa = _PastaExternaFake(
      erro: const FalhaPastaCurada(
        TipoFalhaPastaCurada.autorizacaoRevogada,
        'revogada',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TelaPastaCurada(
          gerenciarPastaCurada: GerenciarPastaCurada(externa, repositorio),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('ler-pasta-curada')));
    await tester.pump();

    expect(find.textContaining('perdida ou revogada'), findsOneWidget);
    expect(repositorio.configuracao, same(configuracao));
  });
}

DocumentoPastaCurada _documento(String nome) => DocumentoPastaCurada(
  localizador: 'content://provider/document/$nome',
  nome: nome,
  ehDiretorio: false,
);

class _RepositorioConfiguracaoMemoria
    implements RepositorioConfiguracaoPastaSincronizada {
  ConfiguracaoPastaSincronizada? configuracao;

  @override
  Future<ConfiguracaoPastaSincronizada?> obter() async => configuracao;

  @override
  Future<void> salvarConfiguracao(
    ConfiguracaoPastaSincronizada configuracao,
  ) async {
    this.configuracao = configuracao;
  }

  @override
  Future<void> limpar() async => configuracao = null;
}

class _PastaExternaFake implements PastaCuradaExterna {
  _PastaExternaFake({this.selecao, this.filhos = const [], this.erro});

  final PastaCuradaSelecionada? selecao;
  final List<DocumentoPastaCurada> filhos;
  final FalhaPastaCurada? erro;
  int leituras = 0;

  @override
  Future<PastaCuradaSelecionada?> selecionarPasta() async => selecao;

  @override
  Future<void> verificarAcesso(String uriArvore) async {
    if (erro != null) throw erro!;
  }

  @override
  Future<List<DocumentoPastaCurada>> listarFilhosDiretos(
    String uriArvore,
  ) async => filhos;

  @override
  Future<Uint8List> lerBytes(DocumentoPastaCurada documento) async {
    leituras++;
    return Uint8List(0);
  }
}
