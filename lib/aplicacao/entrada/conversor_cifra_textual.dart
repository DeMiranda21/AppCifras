import '../../dominio/servicos/parser_acorde.dart';

enum TipoTrechoConversaoCifra {
  tomConvertido,
  letraComAcordes,
  linhaInstrumental,
  rotuloPreservado,
  preservado,
}

enum TipoAvisoConversaoCifra {
  linhaInstrumental,
  associacaoNaoSegura,
  acordeAposLetra,
  acordesConvergentes,
  tomExplicitoAmbiguo,
  tomExplicitoInvalido,
  rotuloComConteudo,
}

class AvisoConversaoCifra {
  const AvisoConversaoCifra({required this.tipo, required this.linha});

  final TipoAvisoConversaoCifra tipo;
  final int linha;
}

class TrechoConversaoCifra {
  const TrechoConversaoCifra({required this.linhaOriginal, required this.tipo});

  final int linhaOriginal;
  final TipoTrechoConversaoCifra tipo;
}

class ResultadoConversaoCifraTextual {
  ResultadoConversaoCifraTextual({
    required this.conteudoOriginal,
    required this.chordProSugerido,
    Iterable<AvisoConversaoCifra> avisos = const [],
    Iterable<TrechoConversaoCifra> trechos = const [],
  }) : avisos = List.unmodifiable(avisos),
       trechos = List.unmodifiable(trechos);

  final String conteudoOriginal;
  final String chordProSugerido;
  final List<AvisoConversaoCifra> avisos;
  final List<TrechoConversaoCifra> trechos;

  String trechoOriginal(AvisoConversaoCifra aviso) =>
      conteudoOriginal.split(RegExp(r'\r\n|\n|\r')).elementAt(aviso.linha);
}

/// Converte somente padrões textuais conservadores para uma sugestão ChordPro.
///
/// Colunas são calculadas em texto monoespaçado: cada rune ocupa uma coluna e
/// tabulações avançam até a próxima parada de quatro colunas. Não há medição de
/// fonte proporcional, nem tentativa de determinar largura de caracteres
/// combinados ou de largura dupla. Quando não existe letra imediatamente após
/// uma linha de acordes, a sequência é preservada como linha instrumental.
class ConversorCifraTextual {
  ConversorCifraTextual({ParserAcorde? parserAcorde})
    : _parserAcorde = parserAcorde ?? ParserAcorde();

  final ParserAcorde _parserAcorde;

  static final _linhaTom = RegExp(
    r'^\s*(?:tom|key)\s*:\s*([A-G](?:[#b])?m?)\s*$',
    caseSensitive: false,
  );
  static final _rotulo = RegExp(r'^\s*\[([^\]]+)\](.*)$');
  static final _candidatoAcorde = RegExp(
    r'^[A-G](?:[#b])?(?:[A-Za-z0-9#b()+/°Δø-]*)$',
  );
  static const _nomesSecao = {
    'intro',
    'primeira parte',
    'verso',
    'pré-refrão',
    'refrão',
    'ponte',
    'final',
  };

  ResultadoConversaoCifraTextual converter(String conteudo) {
    final separador = conteudo.contains('\r\n') ? '\r\n' : '\n';
    final linhas = conteudo.split(RegExp(r'\r\n|\n|\r'));
    final saida = <String>[];
    final avisos = <AvisoConversaoCifra>[];
    final trechos = <TrechoConversaoCifra>[];
    final linhasTom = <int>[];
    String? tomExplicito;

    for (var indice = 0; indice < linhas.length; indice += 1) {
      final tom = _linhaTom.firstMatch(linhas[indice]);
      if (tom != null) {
        linhasTom.add(indice);
        tomExplicito ??= _normalizarTom(tom.group(1)!);
      }
    }
    if (linhasTom.length > 1) {
      avisos.add(
        AvisoConversaoCifra(
          tipo: TipoAvisoConversaoCifra.tomExplicitoAmbiguo,
          linha: linhasTom.first,
        ),
      );
      tomExplicito = null;
    }

    var indice = 0;
    while (indice < linhas.length) {
      final linha = linhas[indice];
      final tom = _linhaTom.firstMatch(linha);
      if (tom != null && linhasTom.length == 1) {
        trechos.add(
          TrechoConversaoCifra(
            linhaOriginal: indice,
            tipo: TipoTrechoConversaoCifra.tomConvertido,
          ),
        );
        indice += 1;
        continue;
      }

      final rotulo = _obterRotulo(linha);
      if (rotulo != null) {
        final restante = rotulo.restante.trim();
        saida.add('{comment: [${rotulo.nome}]}');
        trechos.add(
          TrechoConversaoCifra(
            linhaOriginal: indice,
            tipo: TipoTrechoConversaoCifra.rotuloPreservado,
          ),
        );
        if (restante.isNotEmpty) {
          final acordes = _interpretarLinhaDeAcordes(restante);
          if (acordes != null) {
            saida.add(_converterLinhaInstrumental(acordes));
            trechos.add(
              TrechoConversaoCifra(
                linhaOriginal: indice,
                tipo: TipoTrechoConversaoCifra.linhaInstrumental,
              ),
            );
          } else {
            saida.add(restante);
          }
          avisos.add(
            AvisoConversaoCifra(
              tipo: TipoAvisoConversaoCifra.rotuloComConteudo,
              linha: indice,
            ),
          );
        }
        indice += 1;
        continue;
      }

      if (_contemMarcacaoChordPro(linha)) {
        saida.add(linha);
        trechos.add(
          TrechoConversaoCifra(
            linhaOriginal: indice,
            tipo: TipoTrechoConversaoCifra.preservado,
          ),
        );
        indice += 1;
        continue;
      }

      final acordes = _interpretarLinhaDeAcordes(linha);
      if (acordes == null) {
        saida.add(linha);
        trechos.add(
          TrechoConversaoCifra(
            linhaOriginal: indice,
            tipo: TipoTrechoConversaoCifra.preservado,
          ),
        );
        indice += 1;
        continue;
      }

      if (_podeAssociarComLetra(linhas, indice)) {
        final letra = linhas[indice + 1];
        final mapeamento = _mapearAcordesNaLetra(acordes, letra);
        if (mapeamento != null) {
          saida.add(mapeamento.linha);
          trechos.add(
            TrechoConversaoCifra(
              linhaOriginal: indice,
              tipo: TipoTrechoConversaoCifra.letraComAcordes,
            ),
          );
          trechos.add(
            TrechoConversaoCifra(
              linhaOriginal: indice + 1,
              tipo: TipoTrechoConversaoCifra.letraComAcordes,
            ),
          );
          if (mapeamento.possuiAcordeAposLetra) {
            avisos.add(
              AvisoConversaoCifra(
                tipo: TipoAvisoConversaoCifra.acordeAposLetra,
                linha: indice,
              ),
            );
          }
          if (mapeamento.possuiAcordesConvergentes) {
            avisos.add(
              AvisoConversaoCifra(
                tipo: TipoAvisoConversaoCifra.acordesConvergentes,
                linha: indice,
              ),
            );
          }
          indice += 2;
          continue;
        }
        avisos.add(
          AvisoConversaoCifra(
            tipo: TipoAvisoConversaoCifra.associacaoNaoSegura,
            linha: indice,
          ),
        );
      }

      saida.add(_converterLinhaInstrumental(acordes));
      trechos.add(
        TrechoConversaoCifra(
          linhaOriginal: indice,
          tipo: TipoTrechoConversaoCifra.linhaInstrumental,
        ),
      );
      avisos.add(
        AvisoConversaoCifra(
          tipo: TipoAvisoConversaoCifra.linhaInstrumental,
          linha: indice,
        ),
      );
      indice += 1;
    }

    if (tomExplicito != null) {
      saida.insert(0, '{key: $tomExplicito}');
    }
    return ResultadoConversaoCifraTextual(
      conteudoOriginal: conteudo,
      chordProSugerido: saida.join(separador),
      avisos: avisos,
      trechos: trechos,
    );
  }

  _RotuloSecao? _obterRotulo(String linha) {
    final correspondencia = _rotulo.firstMatch(linha);
    if (correspondencia == null) {
      return null;
    }
    final nome = correspondencia.group(1)!.trim();
    if (!_nomesSecao.contains(nome.toLowerCase())) {
      return null;
    }
    return _RotuloSecao(nome, correspondencia.group(2) ?? '');
  }

  bool _contemMarcacaoChordPro(String linha) =>
      RegExp(r'\[[^\]]+\]').hasMatch(linha);

  _LinhaDeAcordes? _interpretarLinhaDeAcordes(String linha) {
    final tokens = <_TokenAcorde>[];
    var coluna = 0;
    var inicioToken = -1;
    var inicioColuna = 0;
    final buffer = <int>[];

    void concluirToken() {
      if (inicioToken == -1) {
        return;
      }
      final texto = String.fromCharCodes(buffer);
      final resultado = _parserAcorde.interpretar(texto);
      if (resultado is! AcordeInterpretado &&
          !_candidatoAcorde.hasMatch(texto)) {
        tokens.clear();
        inicioToken = -2;
        return;
      }
      tokens.add(_TokenAcorde(texto, inicioColuna));
      buffer.clear();
      inicioToken = -1;
    }

    for (final rune in linha.runes) {
      if (_eEspaco(rune)) {
        concluirToken();
        if (inicioToken == -2) {
          return null;
        }
        coluna = _avancarColuna(coluna, rune);
        continue;
      }
      if (inicioToken == -1) {
        inicioToken = 0;
        inicioColuna = coluna;
      }
      buffer.add(rune);
      coluna += 1;
    }
    concluirToken();
    if (inicioToken == -2 || tokens.isEmpty) {
      return null;
    }
    return _LinhaDeAcordes(tokens);
  }

  bool _podeAssociarComLetra(List<String> linhas, int indice) {
    if (indice + 1 >= linhas.length) {
      return false;
    }
    final proxima = linhas[indice + 1];
    return proxima.trim().isNotEmpty &&
        _obterRotulo(proxima) == null &&
        !_contemMarcacaoChordPro(proxima) &&
        _interpretarLinhaDeAcordes(proxima) == null &&
        !_pareceDiretiva(proxima);
  }

  bool _pareceDiretiva(String linha) =>
      linha.trim().startsWith('{') || linha.trim().endsWith('}');

  _MapeamentoLinha? _mapearAcordesNaLetra(
    _LinhaDeAcordes acordes,
    String letra,
  ) {
    final colunas = _ColunasDaLinha(letra);
    final insercoes = <int, List<String>>{};
    var possuiAcordeAposLetra = false;
    var possuiAcordesConvergentes = false;

    for (var indice = 0; indice < acordes.tokens.length; indice += 1) {
      final acorde = acordes.tokens[indice];
      final posicao = colunas.posicaoPara(
        acorde.coluna,
        primeiroAcorde: indice == 0,
      );
      if (posicao == null) {
        return null;
      }
      if (posicao.aposFim) {
        possuiAcordeAposLetra = true;
      }
      final acordesNaPosicao = insercoes.putIfAbsent(posicao.indice, () => []);
      if (acordesNaPosicao.isNotEmpty) {
        possuiAcordesConvergentes = true;
      }
      acordesNaPosicao.add(acorde.texto);
    }

    final indices = insercoes.keys.toList()..sort((a, b) => b.compareTo(a));
    var resultado = letra;
    for (final indice in indices) {
      resultado = resultado.replaceRange(
        indice,
        indice,
        insercoes[indice]!.map((acorde) => '[$acorde]').join(),
      );
    }
    return _MapeamentoLinha(
      resultado,
      possuiAcordeAposLetra,
      possuiAcordesConvergentes,
    );
  }

  String _converterLinhaInstrumental(_LinhaDeAcordes linha) =>
      linha.tokens.map((acorde) => '[${acorde.texto}]').join(' ');

  bool _eEspaco(int rune) => rune == 0x20 || rune == 0x09;

  String _normalizarTom(String tom) =>
      '${tom.substring(0, 1).toUpperCase()}${tom.substring(1)}';

  int _avancarColuna(int coluna, int rune) =>
      rune == 0x09 ? coluna + 4 - (coluna % 4) : coluna + 1;
}

class _RotuloSecao {
  const _RotuloSecao(this.nome, this.restante);

  final String nome;
  final String restante;
}

class _LinhaDeAcordes {
  const _LinhaDeAcordes(this.tokens);

  final List<_TokenAcorde> tokens;
}

class _TokenAcorde {
  const _TokenAcorde(this.texto, this.coluna);

  final String texto;
  final int coluna;
}

class _MapeamentoLinha {
  const _MapeamentoLinha(
    this.linha,
    this.possuiAcordeAposLetra,
    this.possuiAcordesConvergentes,
  );

  final String linha;
  final bool possuiAcordeAposLetra;
  final bool possuiAcordesConvergentes;
}

class _PosicaoNaLinha {
  const _PosicaoNaLinha(this.indice, {this.aposFim = false});

  final int indice;
  final bool aposFim;
}

class _ColunasDaLinha {
  _ColunasDaLinha(String texto) {
    var coluna = 0;
    var indice = 0;
    var anteriorEraEspaco = true;
    _PontoInsercao? inicioDaPalavra;
    for (final rune in texto.runes) {
      final espaco = rune == 0x20 || rune == 0x09;
      _limites[coluna] = indice;
      if (!espaco && anteriorEraEspaco) {
        inicioDaPalavra = _PontoInsercao(coluna, indice);
        _iniciosDePalavra.add(inicioDaPalavra);
      } else if (espaco && !anteriorEraEspaco) {
        _palavras.add(_FaixaPalavra(inicioDaPalavra!, coluna));
        inicioDaPalavra = null;
      }
      indice += String.fromCharCode(rune).length;
      coluna = rune == 0x09 ? coluna + 4 - (coluna % 4) : coluna + 1;
      anteriorEraEspaco = espaco;
    }
    if (inicioDaPalavra != null) {
      _palavras.add(_FaixaPalavra(inicioDaPalavra, coluna));
    }
    _limites[coluna] = indice;
    _largura = coluna;
    _inicio = _iniciosDePalavra.isEmpty ? 0 : _iniciosDePalavra.first.indice;
  }

  final Map<int, int> _limites = {};
  final List<_PontoInsercao> _iniciosDePalavra = [];
  final List<_FaixaPalavra> _palavras = [];
  late final int _largura;
  late final int _inicio;

  _PosicaoNaLinha? posicaoPara(int coluna, {required bool primeiroAcorde}) {
    if (coluna > _largura) {
      return _PosicaoNaLinha(_limites[_largura]!, aposFim: true);
    }
    final inicioDaPalavra = _inicioDaPalavraNaColuna(coluna);
    if (inicioDaPalavra != null) {
      return _PosicaoNaLinha(inicioDaPalavra.indice);
    }
    if (primeiroAcorde && coluna > 0) {
      return _PosicaoNaLinha(_inicio);
    }
    final indice = _limites[coluna];
    if (indice != null) {
      return _PosicaoNaLinha(indice);
    }
    final proximoInicio = _inicioMaisProximo(coluna);
    if (proximoInicio != null && (proximoInicio.coluna - coluna).abs() <= 2) {
      return _PosicaoNaLinha(proximoInicio.indice);
    }
    return null;
  }

  _PontoInsercao? _inicioMaisProximo(int coluna) {
    _PontoInsercao? maisProximo;
    for (final inicio in _iniciosDePalavra) {
      if (maisProximo == null ||
          (inicio.coluna - coluna).abs() <
              (maisProximo.coluna - coluna).abs()) {
        maisProximo = inicio;
      }
    }
    return maisProximo;
  }

  _PontoInsercao? _inicioDaPalavraNaColuna(int coluna) {
    for (final palavra in _palavras) {
      if (coluna >= palavra.inicio.coluna && coluna < palavra.fimColuna) {
        return palavra.inicio;
      }
    }
    return null;
  }
}

class _PontoInsercao {
  const _PontoInsercao(this.coluna, this.indice);

  final int coluna;
  final int indice;
}

class _FaixaPalavra {
  const _FaixaPalavra(this.inicio, this.fimColuna);

  final _PontoInsercao inicio;
  final int fimColuna;
}
