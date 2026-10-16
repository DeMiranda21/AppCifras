import 'dart:async';
import 'dart:typed_data';

import 'package:appcifras/aplicacao/portas/pasta_curada_externa.dart';
import 'package:appcifras/aplicacao/portas/repositorio_sincronizacao.dart';
import 'package:appcifras/aplicacao/sincronizacao/configuracao_pasta_sincronizada.dart';
import 'package:appcifras/aplicacao/sincronizacao/gerenciar_pasta_curada.dart';
import 'package:appcifras/aplicacao/sincronizacao/sincronizar_pasta_curada.dart';
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

  testWidgets('mostra Sincronizar agora, pasta e última sincronização', (
    tester,
  ) async {
    final repositorio = _RepositorioConfiguracaoMemoria()
      ..configuracao = ConfiguracaoPastaSincronizada(
        uriArvore: 'content://provider/tree/curada',
        autorizacaoPersistente: true,
        nomeLegivel: 'Cifras do Drive',
        ultimaSincronizacaoConcluida: DateTime(2026, 10, 15, 18, 30),
      );
    await tester.pumpWidget(
      MaterialApp(
        home: TelaPastaCurada(
          gerenciarPastaCurada: GerenciarPastaCurada(
            _PastaExternaFake(),
            repositorio,
          ),
          sincronizarPastaCurada: () async => _resultado(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cifras do Drive'), findsOneWidget);
    expect(find.text('Sincronizar agora'), findsOneWidget);
    expect(find.textContaining('Última sincronização:'), findsOneWidget);
    expect(find.textContaining('content://'), findsNothing);
  });

  testWidgets('mostra loading e impede execução duplicada', (tester) async {
    final repositorio = _RepositorioConfiguracaoMemoria()
      ..configuracao = ConfiguracaoPastaSincronizada(
        uriArvore: 'content://provider/tree/curada',
        autorizacaoPersistente: true,
      );
    final pendente = Completer<ResultadoSincronizacao>();
    var execucoes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TelaPastaCurada(
          gerenciarPastaCurada: GerenciarPastaCurada(
            _PastaExternaFake(),
            repositorio,
          ),
          sincronizarPastaCurada: () {
            execucoes++;
            return pendente.future;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final botao = find.byKey(const ValueKey('sincronizar-pasta-curada'));
    await tester.tap(botao);
    await tester.pump();
    await tester.tap(botao, warnIfMissed: false);
    expect(
      find.byKey(const ValueKey('carregando-pasta-curada')),
      findsOneWidget,
    );
    expect(execucoes, 1);

    pendente.complete(_resultado(inalteradas: 1));
    await tester.pumpAndSettle();
    expect(find.text('Sincronização concluída'), findsOneWidget);
  });

  testWidgets('apresenta resumo, erros, avisos e atualiza a data', (
    tester,
  ) async {
    final repositorio = _RepositorioConfiguracaoMemoria()
      ..configuracao = ConfiguracaoPastaSincronizada(
        uriArvore: 'content://provider/tree/curada',
        autorizacaoPersistente: true,
        nomeLegivel: 'Cifras',
      );
    await tester.pumpWidget(
      MaterialApp(
        home: TelaPastaCurada(
          gerenciarPastaCurada: GerenciarPastaCurada(
            _PastaExternaFake(),
            repositorio,
          ),
          sincronizarPastaCurada: () async {
            repositorio.configuracao = ConfiguracaoPastaSincronizada(
              uriArvore: 'content://provider/tree/curada',
              autorizacaoPersistente: true,
              nomeLegivel: 'Cifras',
              ultimaSincronizacaoConcluida: DateTime(2026, 10, 16, 18, 30),
            );
            return _resultado(
              adicionadas: 2,
              atualizadas: 1,
              inalteradas: 3,
              ausentes: 1,
              erros: const [
                ErroSincronizacao(
                  codigo: CodigoErroSincronizacao.arquivoInvalido,
                  localizador: 'content://provider/document/invalida.cho',
                  mensagem: 'schema inválido',
                ),
              ],
              avisos: const [
                AvisoSincronizacao(
                  codigo: CodigoAvisoSincronizacao.principalExternaDivergente,
                  localizador: 'content://provider/document/principal.cho',
                  mensagem: 'principal externa difere da principal local',
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sincronizar-pasta-curada')));
    await tester.pumpAndSettle();

    expect(find.text('2 adicionadas'), findsOneWidget);
    expect(find.text('1 atualizada'), findsOneWidget);
    expect(find.text('3 inalteradas'), findsOneWidget);
    expect(find.text('1 ausente'), findsOneWidget);
    expect(find.text('1 erro'), findsOneWidget);
    expect(
      find.textContaining('invalida.cho: schema inválido'),
      findsOneWidget,
    );
    expect(find.textContaining('principal externa difere'), findsOneWidget);
    expect(find.textContaining('Última sincronização:'), findsOneWidget);
  });

  testWidgets('erro global não conclui nem apaga a configuração', (
    tester,
  ) async {
    final configuracao = ConfiguracaoPastaSincronizada(
      uriArvore: 'content://provider/tree/curada',
      autorizacaoPersistente: true,
      nomeLegivel: 'Cifras',
    );
    final repositorio = _RepositorioConfiguracaoMemoria()
      ..configuracao = configuracao;
    await tester.pumpWidget(
      MaterialApp(
        home: TelaPastaCurada(
          gerenciarPastaCurada: GerenciarPastaCurada(
            _PastaExternaFake(),
            repositorio,
          ),
          sincronizarPastaCurada: () async => _resultado(
            completa: false,
            erros: const [
              ErroSincronizacao(
                codigo: CodigoErroSincronizacao.acessoPasta,
                mensagem: 'A autorização da pasta foi revogada.',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sincronizar-pasta-curada')));
    await tester.pumpAndSettle();

    expect(find.text('Sincronização não concluída'), findsOneWidget);
    expect(find.textContaining('autorização da pasta'), findsOneWidget);
    expect(find.textContaining('Última sincronização:'), findsNothing);
    expect(repositorio.configuracao, same(configuracao));
  });

  testWidgets('permite reexecutar e mostra segunda execução inalterada', (
    tester,
  ) async {
    final repositorio = _RepositorioConfiguracaoMemoria()
      ..configuracao = ConfiguracaoPastaSincronizada(
        uriArvore: 'content://provider/tree/curada',
        autorizacaoPersistente: true,
      );
    var execucoes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TelaPastaCurada(
          gerenciarPastaCurada: GerenciarPastaCurada(
            _PastaExternaFake(),
            repositorio,
          ),
          sincronizarPastaCurada: () async {
            execucoes++;
            return execucoes == 1
                ? _resultado(adicionadas: 1)
                : _resultado(inalteradas: 1);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final botao = find.byKey(const ValueKey('sincronizar-pasta-curada'));
    await tester.tap(botao);
    await tester.pumpAndSettle();
    expect(find.text('1 adicionada'), findsOneWidget);

    await tester.tap(botao);
    await tester.pumpAndSettle();
    expect(find.text('0 adicionadas'), findsOneWidget);
    expect(find.text('0 atualizadas'), findsOneWidget);
    expect(find.text('1 inalterada'), findsOneWidget);
    expect(execucoes, 2);
  });
}

ResultadoSincronizacao _resultado({
  int adicionadas = 0,
  int atualizadas = 0,
  int inalteradas = 0,
  int ausentes = 0,
  List<ErroSincronizacao> erros = const [],
  List<AvisoSincronizacao> avisos = const [],
  bool completa = true,
}) => ResultadoSincronizacao(
  adicionadas: adicionadas,
  atualizadas: atualizadas,
  inalteradas: inalteradas,
  origensAusentes: ausentes,
  erros: erros,
  avisos: avisos,
  enumeracaoCompleta: completa,
);

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
