import 'package:appcifras/aplicacao/entrada/classificador_linha_cifra_textual.dart';
import 'package:appcifras/aplicacao/entrada/conversor_cifra_textual.dart';
import 'package:appcifras/dominio/servicos/parser_acorde.dart';

enum EstrategiaLinhaCuradoria {
  embutida,
  preservadaEmLinhaSeparada,
  mantidaLiteralmente,
  exigeRevisao,
}

class DecisaoLinhaCuradoria {
  const DecisaoLinhaCuradoria({
    required this.linhaOrigem,
    required this.estrategia,
    required this.descricao,
    this.linhaLetraAssociada,
    this.conteudoOrigem,
  });

  final int linhaOrigem;
  final int? linhaLetraAssociada;
  final EstrategiaLinhaCuradoria estrategia;
  final String descricao;
  final String? conteudoOrigem;

  Map<String, Object?> toJson() => {
    'linhaOrigem': linhaOrigem,
    'linhaLetraAssociada': linhaLetraAssociada,
    'estrategia': estrategia.name,
    'descricao': descricao,
    'conteudoOrigem': conteudoOrigem,
  };
}

class ResultadoConversaoCuradoria {
  ResultadoConversaoCuradoria({
    required this.chordPro,
    required Iterable<DecisaoLinhaCuradoria> decisoes,
    required Iterable<String> motivosRevisao,
    required this.paresPreservadosEmLinhaSeparada,
  }) : decisoes = List.unmodifiable(decisoes),
       motivosRevisao = List.unmodifiable(motivosRevisao);

  final String chordPro;
  final List<DecisaoLinhaCuradoria> decisoes;
  final List<String> motivosRevisao;
  final int paresPreservadosEmLinhaSeparada;
}

class ConversorCuradoriaConservador {
  ConversorCuradoriaConservador({ConversorCifraTextual? conversor})
    : _conversor = conversor ?? ConversorCifraTextual();

  final ConversorCifraTextual _conversor;
  final ClassificadorLinhaCifraTextual _classificador =
      ClassificadorLinhaCifraTextual();
  final ParserAcorde _parser = ParserAcorde();

  ResultadoConversaoCuradoria converter(String conteudo) {
    final linhas = conteudo.split(RegExp(r'\r\n|\n|\r'));
    final saida = <String>[];
    final decisoes = <DecisaoLinhaCuradoria>[];
    final motivos = <String>[];
    var preservadasSeparadas = 0;
    var indice = 0;

    while (indice < linhas.length) {
      final linha = linhas[indice];
      if (_classificador.ehLinhaDeAcordes(linha) &&
          _podeReceberAssociacao(linhas, indice)) {
        final letra = linhas[indice + 1];
        final tentativa = _conversor.converter('$linha\n$letra');
        final insegura = tentativa.avisos.any(
          (aviso) =>
              aviso.tipo == TipoAvisoConversaoCifra.acordeAposLetra ||
              aviso.tipo == TipoAvisoConversaoCifra.acordesConvergentes ||
              aviso.tipo == TipoAvisoConversaoCifra.associacaoNaoSegura,
        );
        final embutiu = tentativa.trechos.any(
          (trecho) => trecho.tipo == TipoTrechoConversaoCifra.letraComAcordes,
        );

        if (insegura || !embutiu) {
          saida.add(_linhaChordProSeparada(linha));
          saida.add(letra);
          preservadasSeparadas++;
          decisoes
            ..add(
              DecisaoLinhaCuradoria(
                linhaOrigem: indice + 1,
                linhaLetraAssociada: indice + 2,
                estrategia: EstrategiaLinhaCuradoria.preservadaEmLinhaSeparada,
                descricao: 'Sequência de acordes preservada antes da letra por associação posicional insegura.',
              ),
            )
            ..add(
              DecisaoLinhaCuradoria(
                linhaOrigem: indice + 2,
                estrategia: EstrategiaLinhaCuradoria.mantidaLiteralmente,
                descricao: 'Linha de letra associada preservada integralmente.',
              ),
            );
        } else {
          saida.add(tentativa.chordProSugerido);
          decisoes
            ..add(
              DecisaoLinhaCuradoria(
                linhaOrigem: indice + 1,
                linhaLetraAssociada: indice + 2,
                estrategia: EstrategiaLinhaCuradoria.embutida,
                descricao: 'Acordes inseridos em posições distintas e seguras.',
              ),
            )
            ..add(
              DecisaoLinhaCuradoria(
                linhaOrigem: indice + 2,
                estrategia: EstrategiaLinhaCuradoria.embutida,
                descricao: 'Letra preservada com acordes embutidos.',
              ),
            );
        }
        indice += 2;
        continue;
      }

      final instrumental = _converterInstrumentalAnotada(linha);
      if (instrumental != null) {
        if (instrumental.invalidos.isEmpty) {
          saida.add(instrumental.convertida);
          decisoes.add(
            DecisaoLinhaCuradoria(
              linhaOrigem: indice + 1,
              estrategia: EstrategiaLinhaCuradoria.preservadaEmLinhaSeparada,
              descricao:
                  'Linha instrumental com marcadores preservada separadamente.',
            ),
          );
        } else {
          saida.add(linha);
          for (final invalido in instrumental.invalidos) {
            motivos.add(
              'Token de acorde inválido "$invalido" na linha ${indice + 1}.',
            );
          }
          decisoes.add(
            DecisaoLinhaCuradoria(
              linhaOrigem: indice + 1,
              estrategia: EstrategiaLinhaCuradoria.exigeRevisao,
              descricao: 'Linha instrumental contém notação fora do subconjunto aceito.',
              conteudoOrigem: linha,
            ),
          );
        }
        indice++;
        continue;
      }

      final ambigua = _pareceMisturaAmbigua(linha);
      final colchetesInvalidos =
          '['.allMatches(linha).length != ']'.allMatches(linha).length;
      final tokenInvalido = _tokenDeAcordeInequivocamenteInvalido(linha);
      final conversaoLinha = _conversor.converter(linha);
      saida.add(
        colchetesInvalidos || tokenInvalido != null
            ? linha
            : conversaoLinha.chordProSugerido,
      );
      if (ambigua || colchetesInvalidos || tokenInvalido != null) {
        final motivo = colchetesInvalidos
            ? 'Colchetes malformados na linha ${indice + 1}.'
            : tokenInvalido != null
            ? 'Token de acorde inválido "$tokenInvalido" na linha ${indice + 1}.'
            : 'Mistura ambígua de texto e acordes na linha ${indice + 1}.';
        motivos.add(motivo);
        decisoes.add(
          DecisaoLinhaCuradoria(
            linhaOrigem: indice + 1,
            estrategia: EstrategiaLinhaCuradoria.exigeRevisao,
            descricao: motivo,
            conteudoOrigem: linha,
          ),
        );
      } else if (_classificador.ehLinhaDeAcordes(linha)) {
        decisoes.add(
          DecisaoLinhaCuradoria(
            linhaOrigem: indice + 1,
            estrategia: EstrategiaLinhaCuradoria.preservadaEmLinhaSeparada,
            descricao: 'Linha inequivocamente instrumental preservada.',
          ),
        );
      } else {
        decisoes.add(
          DecisaoLinhaCuradoria(
            linhaOrigem: indice + 1,
            estrategia: EstrategiaLinhaCuradoria.mantidaLiteralmente,
            descricao: conversaoLinha.chordProSugerido == linha
                ? 'Conteúdo mantido literalmente.'
                : 'Conteúdo semântico preservado em estrutura ChordPro.',
          ),
        );
      }
      indice++;
    }

    return ResultadoConversaoCuradoria(
      chordPro: saida.join('\n'),
      decisoes: decisoes,
      motivosRevisao: motivos,
      paresPreservadosEmLinhaSeparada: preservadasSeparadas,
    );
  }

  bool _podeReceberAssociacao(List<String> linhas, int indice) {
    if (indice + 1 >= linhas.length) return false;
    final proxima = linhas[indice + 1];
    return proxima.trim().isNotEmpty &&
        !_classificador.ehRotuloDeSecao(proxima) &&
        !_classificador.ehLinhaDeAcordes(proxima) &&
        !RegExp(r'\[[^\]]+\]').hasMatch(proxima) &&
        !proxima.trim().startsWith('{') &&
        !proxima.trim().endsWith('}') &&
        !proxima.trim().startsWith('(') &&
        !proxima.trim().startsWith('*') &&
        !RegExp(
          r'^(?:obs|observa[cç][aã]o)\s*:',
          caseSensitive: false,
        ).hasMatch(proxima.trim()) &&
        !RegExp(r'^[EADGBe]\|').hasMatch(proxima.trim());
  }

  String _linhaChordProSeparada(String linha) =>
      linha.trim().split(RegExp(r'\s+')).map((acorde) => '[$acorde]').join(' ');

  bool _pareceMisturaAmbigua(String linha) {
    if (linha.trim().isEmpty ||
        linha.contains('[') ||
        linha.contains(']') ||
        _classificador.ehRotuloDeSecao(linha) ||
        _classificador.ehLinhaDeAcordes(linha)) {
      return false;
    }
    final tokens = linha.trim().split(RegExp(r'\s+'));
    final acordes = tokens
        .where((token) => _classificador.ehLinhaDeAcordes(token))
        .length;
    return acordes >= 2 &&
        acordes < tokens.length &&
        acordes * 2 >= tokens.length;
  }

  String? _tokenDeAcordeInequivocamenteInvalido(String linha) {
    final limpa = linha.trim();
    if (limpa.contains(' ') || limpa.contains('[') || limpa.contains(']')) {
      return null;
    }
    return RegExp(r'^H(?:[#b])?(?:m|maj|min|dim|aug|sus|add)?\d*(?:/\w+)?$')
            .hasMatch(limpa)
        ? limpa
        : null;
  }

  _InstrumentalAnotada? _converterInstrumentalAnotada(String linha) {
    var prefixo = '';
    var conteudo = linha.trim();
    final comRotulo = RegExp(r'^([^:]+):\s*(.+)$').firstMatch(conteudo);
    if (comRotulo != null &&
        _classificador.ehNomeDeSecao(comRotulo.group(1)!.trim())) {
      prefixo = '{comment: [${comRotulo.group(1)!.trim()}]}\n';
      conteudo = comRotulo.group(2)!;
    }
    final tokens = conteudo.split(RegExp(r'\s+'));
    final saida = <String>[];
    final invalidos = <String>[];
    var quantidadeAcordes = 0;
    for (final original in tokens) {
      final candidato = _removerMarcadoresDeGrupo(original);
      if (candidato.isEmpty ||
          RegExp(
            r'^(?:x\d+|\d+x)$',
            caseSensitive: false,
          ).hasMatch(candidato)) {
        saida.add(original);
        continue;
      }
      if (_parser.interpretar(candidato) is AcordeInterpretado) {
        quantidadeAcordes++;
        saida.add(original.replaceFirst(candidato, '[$candidato]'));
        continue;
      }
      if (_pareceTokenDeAcorde(candidato)) {
        quantidadeAcordes++;
        invalidos.add(candidato);
        saida.add(original);
        continue;
      }
      return null;
    }
    if (quantidadeAcordes == 0 || tokens.length == 1) return null;
    return _InstrumentalAnotada(
      '$prefixo${saida.join(' ')}',
      invalidos.toSet().toList(),
    );
  }

  bool _pareceTokenDeAcorde(String token) =>
      RegExp(r'^[A-H][#b]?[A-Za-z0-9º°()+#b/-]*$').hasMatch(token);

  String _removerMarcadoresDeGrupo(String original) {
    var candidato = original.replaceAll(RegExp(r'^,+|,+$'), '');
    if (candidato == '(' || candidato == ')') return '';
    if (candidato.startsWith('(')) candidato = candidato.substring(1);
    final abre = '('.allMatches(candidato).length;
    final fecha = ')'.allMatches(candidato).length;
    if (candidato.endsWith(')') && fecha > abre) {
      candidato = candidato.substring(0, candidato.length - 1);
    }
    return candidato;
  }
}

class _InstrumentalAnotada {
  const _InstrumentalAnotada(this.convertida, this.invalidos);

  final String convertida;
  final List<String> invalidos;
}
