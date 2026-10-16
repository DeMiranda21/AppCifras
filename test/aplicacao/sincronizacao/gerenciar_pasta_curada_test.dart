import 'dart:typed_data';

import 'package:appcifras/aplicacao/portas/pasta_curada_externa.dart';
import 'package:appcifras/aplicacao/portas/repositorio_sincronizacao.dart';
import 'package:appcifras/aplicacao/sincronizacao/configuracao_pasta_sincronizada.dart';
import 'package:appcifras/aplicacao/sincronizacao/gerenciar_pasta_curada.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _RepositorioConfiguracaoMemoria repositorio;
  late _PastaCuradaExternaFake pastaExterna;
  late GerenciarPastaCurada gerenciar;

  setUp(() {
    repositorio = _RepositorioConfiguracaoMemoria();
    pastaExterna = _PastaCuradaExternaFake();
    gerenciar = GerenciarPastaCurada(pastaExterna, repositorio);
  });

  test('seleção salva configuração com autorização persistente', () async {
    pastaExterna.selecao = PastaCuradaSelecionada(
      uriArvore: 'content://com.google.android.apps.docs/tree/curada',
      nomeLegivel: 'Cifras',
    );

    final resultado = await gerenciar.selecionarPasta();

    expect(resultado?.uriArvore, pastaExterna.selecao?.uriArvore);
    expect(repositorio.configuracao?.autorizacaoPersistente, isTrue);
    expect(repositorio.configuracao?.nomeLegivel, 'Cifras');
    expect(repositorio.configuracao?.ultimaSincronizacaoConcluida, isNull);
    expect(pastaExterna.uriVerificada, pastaExterna.selecao?.uriArvore);
  });

  test('cancelar seletor não altera configuração existente', () async {
    final existente = _configuracao('content://provider/tree/anterior');
    repositorio.configuracao = existente;

    expect(await gerenciar.selecionarPasta(), isNull);
    expect(repositorio.configuracao, same(existente));
    expect(repositorio.salvamentos, 0);
  });

  test('URI da árvore é preservada como valor opaco', () async {
    const uri =
        'content://provider/tree/id%2Fcom%3Asegmentos/document/sem-caminho-real';
    pastaExterna.selecao = PastaCuradaSelecionada(uriArvore: uri);

    await gerenciar.selecionarPasta();

    expect(repositorio.configuracao?.uriArvore, uri);
    expect(pastaExterna.uriVerificada, uri);
  });

  test('lista somente arquivos .cho filhos diretos e ignora outros', () async {
    repositorio.configuracao = _configuracao('content://provider/tree/curada');
    pastaExterna.filhos = [
      _documento('content://provider/document/1', 'primeira.cho'),
      _documento('content://provider/document/2', 'SEGUNDA.CHO'),
      _documento('content://provider/document/3', 'notas.txt'),
      _documento(
        'content://provider/document/subpasta',
        'subpasta.cho',
        ehDiretorio: true,
      ),
    ];

    final arquivos = await gerenciar.listarArquivosCho();

    expect(arquivos.map((arquivo) => arquivo.nome), [
      'primeira.cho',
      'SEGUNDA.CHO',
    ]);
    expect(pastaExterna.listagens, 1);
  });

  test('erro de acesso não remove nem modifica configuração', () async {
    final existente = _configuracao('content://provider/tree/curada');
    repositorio.configuracao = existente;
    pastaExterna.erroAcesso = const FalhaPastaCurada(
      TipoFalhaPastaCurada.provedorIndisponivel,
      'indisponível',
    );

    await expectLater(
      gerenciar.listarArquivosCho(),
      throwsA(
        isA<FalhaPastaCurada>().having(
          (erro) => erro.tipo,
          'tipo',
          TipoFalhaPastaCurada.provedorIndisponivel,
        ),
      ),
    );
    expect(repositorio.configuracao, same(existente));
    expect(repositorio.limpezas, 0);
  });

  test('reabertura usa configuração persistida sem nova seleção', () async {
    final existente = _configuracao('content://provider/tree/curada');
    repositorio.configuracao = existente;
    final novaInstancia = GerenciarPastaCurada(pastaExterna, repositorio);

    await novaInstancia.listarArquivosCho();

    expect(pastaExterna.selecoes, 0);
    expect(pastaExterna.uriVerificada, existente.uriArvore);
    expect(pastaExterna.uriListada, existente.uriArvore);
  });

  test('enumeração não altera configuração nem marca sincronização', () async {
    final concluida = DateTime.utc(2026, 10, 1);
    final existente = ConfiguracaoPastaSincronizada(
      uriArvore: 'content://provider/tree/curada',
      autorizacaoPersistente: true,
      ultimaSincronizacaoConcluida: concluida,
    );
    repositorio.configuracao = existente;

    await gerenciar.listarArquivosCho();

    expect(repositorio.configuracao, same(existente));
    expect(repositorio.salvamentos, 0);
    expect(repositorio.configuracao?.ultimaSincronizacaoConcluida, concluida);
  });

  test('leitura devolve os bytes exatos do documento opaco', () async {
    final documento = _documento(
      'content://provider/document/id%2Fopaco',
      'musica.cho',
    );
    pastaExterna.bytes = Uint8List.fromList([0, 1, 2, 127, 255]);

    final resultado = await gerenciar.lerBytes(documento);

    expect(resultado, [0, 1, 2, 127, 255]);
    expect(pastaExterna.documentoLido, same(documento));
  });
}

ConfiguracaoPastaSincronizada _configuracao(String uri) =>
    ConfiguracaoPastaSincronizada(uriArvore: uri, autorizacaoPersistente: true);

DocumentoPastaCurada _documento(
  String localizador,
  String nome, {
  bool ehDiretorio = false,
}) => DocumentoPastaCurada(
  localizador: localizador,
  nome: nome,
  ehDiretorio: ehDiretorio,
);

class _RepositorioConfiguracaoMemoria
    implements RepositorioConfiguracaoPastaSincronizada {
  ConfiguracaoPastaSincronizada? configuracao;
  int salvamentos = 0;
  int limpezas = 0;

  @override
  Future<ConfiguracaoPastaSincronizada?> obter() async => configuracao;

  @override
  Future<void> salvarConfiguracao(
    ConfiguracaoPastaSincronizada configuracao,
  ) async {
    salvamentos++;
    this.configuracao = configuracao;
  }

  @override
  Future<void> limpar() async {
    limpezas++;
    configuracao = null;
  }
}

class _PastaCuradaExternaFake implements PastaCuradaExterna {
  PastaCuradaSelecionada? selecao;
  List<DocumentoPastaCurada> filhos = [];
  Uint8List bytes = Uint8List(0);
  FalhaPastaCurada? erroAcesso;
  String? uriVerificada;
  String? uriListada;
  DocumentoPastaCurada? documentoLido;
  int selecoes = 0;
  int listagens = 0;

  @override
  Future<PastaCuradaSelecionada?> selecionarPasta() async {
    selecoes++;
    return selecao;
  }

  @override
  Future<void> verificarAcesso(String uriArvore) async {
    uriVerificada = uriArvore;
    final erro = erroAcesso;
    if (erro != null) throw erro;
  }

  @override
  Future<List<DocumentoPastaCurada>> listarFilhosDiretos(
    String uriArvore,
  ) async {
    listagens++;
    uriListada = uriArvore;
    return filhos;
  }

  @override
  Future<Uint8List> lerBytes(DocumentoPastaCurada documento) async {
    documentoLido = documento;
    return bytes;
  }
}
