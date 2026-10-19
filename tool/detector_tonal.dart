import 'package:appcifras/dominio/objetos_de_valor/acorde.dart';
import 'package:appcifras/dominio/servicos/parser_acorde.dart';

enum ConfiancaDeteccaoTom { alta, media, baixa }

class ResultadoCalibracaoTonal {
  const ResultadoCalibracaoTonal({
    required this.totalComTomExplicito,
    required this.porConfianca,
    required this.divergencias,
    required this.casos,
  });

  final int totalComTomExplicito;
  final Map<ConfiancaDeteccaoTom, EstatisticaCalibracaoTonal> porConfianca;
  final List<Map<String, Object?>> divergencias;
  final List<Map<String, Object?>> casos;

  EstatisticaCalibracaoTonal get alta =>
      porConfianca[ConfiancaDeteccaoTom.alta] ??
      const EstatisticaCalibracaoTonal(total: 0, corretos: 0);

  bool get permiteAplicacaoAutomaticaAlta =>
      alta.total > 0 && alta.corretos == alta.total;

  Map<String, Object?> toJson() => {
    'totalComTomExplicito': totalComTomExplicito,
    'altaAutorizada': permiteAplicacaoAutomaticaAlta,
    'porConfianca': {
      for (final item in porConfianca.entries)
        item.key.name: item.value.toJson(totalComTomExplicito),
    },
    'divergencias': divergencias,
    'casos': casos,
  };
}

class EstatisticaCalibracaoTonal {
  const EstatisticaCalibracaoTonal({
    required this.total,
    required this.corretos,
  });

  final int total;
  final int corretos;

  double get precisao => total == 0 ? 0 : corretos / total;

  Map<String, Object> toJson(int universo) => {
    'total': total,
    'corretos': corretos,
    'precisao': double.parse((precisao * 100).toStringAsFixed(2)),
    'cobertura': double.parse(
      (universo == 0 ? 0 : total * 100 / universo).toStringAsFixed(2),
    ),
  };
}

class CandidatoTonal {
  const CandidatoTonal({required this.tom, required this.pontuacao});

  final String tom;
  final double pontuacao;

  Map<String, Object> toJson() => {
    'tom': tom,
    'pontuacao': double.parse(pontuacao.toStringAsFixed(2)),
  };
}

class ResultadoDeteccaoTom {
  const ResultadoDeteccaoTom({
    required this.tomDetectado,
    required this.confianca,
    required this.evidencias,
    required this.segundoCandidato,
    required this.diferencaPontuacao,
    required this.quantidadeAcordes,
    required this.possivelModulacao,
    required this.primeiroCandidato,
    required this.primeiroAcorde,
    required this.ultimoAcorde,
    required this.evidenciasSegundoCandidato,
  });

  final String? tomDetectado;
  final ConfiancaDeteccaoTom confianca;
  final List<String> evidencias;
  final CandidatoTonal? segundoCandidato;
  final double diferencaPontuacao;
  final int quantidadeAcordes;
  final bool possivelModulacao;
  final CandidatoTonal? primeiroCandidato;
  final String? primeiroAcorde;
  final String? ultimoAcorde;
  final List<String> evidenciasSegundoCandidato;

  Map<String, Object?> toJson() => {
    'tomDetectado': tomDetectado,
    'confianca': confianca.name,
    'evidencias': evidencias,
    'segundoCandidato': segundoCandidato?.toJson(),
    'diferencaPontuacao': double.parse(diferencaPontuacao.toStringAsFixed(2)),
    'quantidadeAcordes': quantidadeAcordes,
    'possivelModulacao': possivelModulacao,
    'primeiroCandidato': primeiroCandidato?.toJson(),
    'primeiroAcorde': primeiroAcorde,
    'ultimoAcorde': ultimoAcorde,
    'evidenciasSegundoCandidato': evidenciasSegundoCandidato,
  };
}

/// Estima o centro tonal sem modificar nem normalizar o conteúdo de origem.
///
/// Somente cifras em linhas musicais ou incorporadas à letra entram na
/// análise. Comentários, tablaturas, afinação e dicionários de acordes são
/// descartados antes da pontuação.
class DetectorTonal {
  DetectorTonal({ParserAcorde? parser}) : _parser = parser ?? ParserAcorde();

  final ParserAcorde _parser;

  static final RegExp _cabecalhoDicionario = RegExp(
    r'^\s*[-=]*\s*(?:acordes|dicion[aá]rio\s+(?:de\s+)?acordes)\s*:?[\s-=]*$',
    caseSensitive: false,
  );
  static final RegExp _linhaTab = RegExp(r'^\s*[EADGBe]\s*\|');
  static final RegExp _afinacao = RegExp(
    r'^\s*(?:afina(?:ç|c)[aã]o|tuning|capotraste|capo)\b',
    caseSensitive: false,
  );
  static final RegExp _notaExecucao = RegExp(
    r'^\s*(?:obs(?:erva(?:ç|c)[aã]o)?\.?|nota|dica|aten(?:ç|c)[aã]o|toque|repita|ritmo|batida)\s*:',
    caseSensitive: false,
  );
  static final RegExp _diretivaMetadado = RegExp(
    r'^\s*(?:tom|key|t[ií]tulo|title|artista|artist|cifra)\s*:',
    caseSensitive: false,
  );
  static final RegExp _desenho = RegExp(r'^\s*(?:[xXoO0-9|\-]{4,}\s*)+$');
  static final RegExp _entreColchetes = RegExp(r'\[([^\]\r\n]+)\]');
  static final RegExp _rotuloSecao = RegExp(
    r'^(?:\d+[ªº]?\s*)?(?:intro(?:du(?:ç|c)[aã]o)?|verso|estrofe|primeira parte|segunda parte|terceira parte|pr[eé][ -]?refr[aã]o|refr[aã]o|coro|ponte|bridge|interl[uú]dio|instrumental|solo|final|riff)\b\s*:?',
    caseSensitive: false,
  );
  static final RegExp _marcadorIgnoravel = RegExp(
    r'^(?:x\d+|\d+x|bis|vez(?:es)?|volta|repete|repeat|direto|ou)$',
    caseSensitive: false,
  );

  ResultadoDeteccaoTom detectar(String texto) {
    final extracao = _extrairOcorrencias(texto);
    final ocorrencias = extracao.acordes;
    if (ocorrencias.isEmpty) return _resultadoInsuficiente(0);

    final candidatos = _pontuar(extracao)..sort(_ordenarCandidatos);
    final primeiro = candidatos.first;
    final segundo = candidatos.length > 1 ? candidatos[1] : null;
    final diferenca = segundo == null
        ? primeiro.pontuacao
        : primeiro.pontuacao - segundo.pontuacao;
    final detalhes = _detalhes(primeiro, extracao);
    final possivelModulacao = _detectarModulacao(extracao);

    var confianca = ConfiancaDeteccaoTom.baixa;
    if (!possivelModulacao &&
        ocorrencias.length >= 8 &&
        detalhes.compatibilidade >= 0.78 &&
        detalhes.tonica >= 3 &&
        detalhes.evidenciaAutenticada >= 1 &&
        detalhes.secoesIniciadasNaTonica >= 1 &&
        detalhes.secoesTerminadasNaTonica >= 1 &&
        diferenca >= 12 &&
        diferenca / _raizQuadrada(ocorrencias.length) >= 2.2) {
      confianca = ConfiancaDeteccaoTom.alta;
    } else if (!possivelModulacao &&
        ocorrencias.length >= 4 &&
        detalhes.compatibilidade >= 0.60 &&
        detalhes.tonica >= 1 &&
        detalhes.temEvidenciaResolutiva &&
        diferenca >= 4) {
      confianca = ConfiancaDeteccaoTom.media;
    }

    final evidencias = _evidenciasCandidato(
      primeiro,
      detalhes,
      ocorrencias.length,
    );
    final detalhesSegundo = segundo == null
        ? null
        : _detalhes(segundo, extracao);
    final evidenciasSegundo = segundo == null || detalhesSegundo == null
        ? const <String>[]
        : _evidenciasCandidato(segundo, detalhesSegundo, ocorrencias.length);
    if (possivelModulacao) {
      evidencias.add(
        'Segmentos da música apontam para centros tonais diferentes.',
      );
    }
    return ResultadoDeteccaoTom(
      tomDetectado: primeiro.tom,
      confianca: confianca,
      evidencias: List.unmodifiable(evidencias),
      segundoCandidato: segundo,
      diferencaPontuacao: diferenca,
      quantidadeAcordes: ocorrencias.length,
      possivelModulacao: possivelModulacao,
      primeiroCandidato: primeiro,
      primeiroAcorde: ocorrencias.first.texto,
      ultimoAcorde: ocorrencias.last.texto,
      evidenciasSegundoCandidato: List.unmodifiable(evidenciasSegundo),
    );
  }

  List<String> _evidenciasCandidato(
    CandidatoTonal candidato,
    _DetalhesCandidato detalhes,
    int quantidade,
  ) => <String>[
    '$quantidade acordes musicais analisados.',
    '${(detalhes.compatibilidade * 100).toStringAsFixed(1)}% compatíveis com ${candidato.tom}.',
    'Tônica em ${detalhes.tonica} ocorrência(s).',
    if (detalhes.iniciaNaTonica) 'Acorde inicial na tônica.',
    if (detalhes.terminaNaTonica) 'Acorde final na tônica.',
    if (detalhes.cadenciasV1 > 0) '${detalhes.cadenciasV1} cadência(s) V–I.',
    if (detalhes.cadenciasIV1 > 0) '${detalhes.cadenciasIV1} cadência(s) IV–I.',
    if (detalhes.cadenciasII51 > 0)
      '${detalhes.cadenciasII51} cadência(s) ii–V–I.',
    if (detalhes.dominantesComSetima > 0)
      '${detalhes.dominantesComSetima} dominante(s) com sétima.',
    if (detalhes.cadenciasVII1 > 0)
      '${detalhes.cadenciasVII1} resolução(ões) vii°–I.',
    if (detalhes.dominantesSecundarias > 0)
      '${detalhes.dominantesSecundarias} dominante(s) secundária(s) resolvida(s).',
    if (detalhes.secoesTerminadasNaTonica > 0)
      '${detalhes.secoesTerminadasNaTonica} seção(ões) encerrada(s) na tônica.',
    if (detalhes.secoesIniciadasNaTonica > 0)
      '${detalhes.secoesIniciadasNaTonica} seção(ões) iniciada(s) na tônica.',
  ];

  _ExtracaoTonal _extrairOcorrencias(String texto) {
    final secoes = <_SecaoTonal>[_SecaoTonal('inicial')];
    var secaoAtual = secoes.first;
    var emDicionario = false;
    for (final linhaOriginal in texto.split(RegExp(r'\r\n|\n|\r'))) {
      final linha = linhaOriginal.trim();
      if (linha.isEmpty) continue;
      if (_cabecalhoDicionario.hasMatch(linha)) {
        emDicionario = true;
        continue;
      }
      if (emDicionario ||
          _linhaTab.hasMatch(linha) ||
          _afinacao.hasMatch(linha) ||
          _notaExecucao.hasMatch(linha) ||
          _diretivaMetadado.hasMatch(linha) ||
          _desenho.hasMatch(linha) ||
          _pareceExplicacao(linha)) {
        continue;
      }

      final correspondencias = _entreColchetes.allMatches(linha).toList();
      final incorporados = <_OcorrenciaAcorde>[];
      String? rotuloEncontrado;
      for (final match in correspondencias) {
        final ocorrencia = _interpretar(match.group(1)!.trim());
        if (ocorrencia != null) {
          incorporados.add(ocorrencia);
        } else if (_rotuloSecao.hasMatch(match.group(1)!.trim())) {
          rotuloEncontrado = match.group(1)!.trim();
        }
      }
      if (rotuloEncontrado != null) {
        secaoAtual = _SecaoTonal(_normalizarRotulo(rotuloEncontrado));
        secoes.add(secaoAtual);
      }
      if (incorporados.isNotEmpty) {
        secaoAtual.adicionarLinha(incorporados);
        continue;
      }

      var restante = linha;
      final rotuloCru = _rotuloSecao.firstMatch(restante);
      if (rotuloCru != null) {
        secaoAtual = _SecaoTonal(_normalizarRotulo(rotuloCru.group(0)!));
        secoes.add(secaoAtual);
        restante = restante.substring(rotuloCru.end).trim();
        if (restante.isEmpty) continue;
      }

      final tokens = restante
          .replaceAll(RegExp(r'[|,:;]'), ' ')
          .split(RegExp(r'\s+'))
          .where((token) => token.isNotEmpty)
          .toList();
      if (tokens.isEmpty) continue;
      final acordes = <_OcorrenciaAcorde>[];
      var palavras = 0;
      var candidatosAcorde = 0;
      for (var token in tokens) {
        token = token.replaceAll(RegExp(r'^[()]+|[().]+$'), '');
        if (token.isEmpty || _marcadorIgnoravel.hasMatch(token)) {
          continue;
        }
        final ocorrencia = _interpretar(token);
        if (ocorrencia == null) {
          if (_pareceTokenDeAcorde(token)) {
            candidatosAcorde++;
          } else {
            palavras++;
          }
          continue;
        }
        candidatosAcorde++;
        acordes.add(ocorrencia);
      }
      if (acordes.isNotEmpty &&
          palavras == 0 &&
          acordes.length / candidatosAcorde >= 0.5) {
        secaoAtual.adicionarLinha(acordes);
      }
    }
    final uteis = _removerSecoesRepetidas(secoes);
    return _ExtracaoTonal(List.unmodifiable(uteis));
  }

  bool _pareceExplicacao(String linha) {
    final semColchetes = linha.replaceAll(_entreColchetes, '');
    return RegExp(
      r'\b(?:acorde|forma|posição|posicao|dedilhado|explica|substitu|use|fazer|faça|tocar)\b',
      caseSensitive: false,
    ).hasMatch(semColchetes);
  }

  _OcorrenciaAcorde? _interpretar(String token) {
    final resultado = _parser.interpretar(token);
    if (resultado is AcordeInterpretado) {
      final acorde = resultado.acorde;
      return _OcorrenciaAcorde(
        texto: token,
        fundamental: acorde.notaFundamental.classeDeAltura,
        qualidade: acorde.qualidade,
        dominanteComSetima:
            acorde.qualidade == QualidadeAcorde.maior &&
            acorde.extensoes.contains(ExtensaoAcorde.setima),
      );
    }
    final parcial = RegExp(
      r'^([A-G])([#b]?)(m(?!aj)|dim|[°º]|ø|aug|\+)?([A-Za-z0-9#b()+°ºøΔ/\-]*)$',
    ).firstMatch(token);
    if (parcial == null) return null;
    final sufixo = '${parcial.group(3) ?? ''}${parcial.group(4) ?? ''}';
    final qualidade = sufixo.startsWith('m') && !sufixo.startsWith('maj')
        ? QualidadeAcorde.menor
        : (sufixo.startsWith('dim') ||
              sufixo.startsWith('°') ||
              sufixo.startsWith('º') ||
              sufixo.startsWith('ø'))
        ? QualidadeAcorde.diminuto
        : sufixo.startsWith('aug') || sufixo.startsWith('+')
        ? QualidadeAcorde.aumentado
        : QualidadeAcorde.maior;
    return _OcorrenciaAcorde(
      texto: token,
      fundamental: _classe('${parcial.group(1)!}${parcial.group(2)!}'),
      qualidade: qualidade,
      dominanteComSetima:
          qualidade == QualidadeAcorde.maior &&
          RegExp(r'(^|[^mM])7').hasMatch(sufixo) &&
          !sufixo.contains('7M') &&
          !sufixo.contains('maj7'),
    );
  }

  List<CandidatoTonal> _pontuar(_ExtracaoTonal extracao) => [
    for (var tonica = 0; tonica < 12; tonica++)
      for (final menor in [false, true])
        CandidatoTonal(
          tom: _nomeTom(tonica, menor, extracao.acordes),
          pontuacao: _pontuacao(tonica, menor, extracao),
        ),
  ];

  double _pontuacao(int tonica, bool menor, _ExtracaoTonal extracao) {
    final acordes = extracao.acordes;
    var pontos = 0.0;
    for (var indice = 0; indice < acordes.length; indice++) {
      final acorde = acordes[indice];
      final resolucaoSecundaria = _ehDominanteSecundariaResolvida(
        acorde,
        indice + 1 < acordes.length ? acordes[indice + 1] : null,
        tonica,
        menor,
      );
      if (_compativel(acorde, tonica, menor)) {
        pontos += 2;
      } else if (_emprestadoComum(acorde, tonica, menor)) {
        pontos += 0.2;
      } else if (resolucaoSecundaria) {
        pontos += 0.5;
      } else {
        pontos -= 2.2;
      }
      if (acorde.fundamental == tonica && _qualidadeTonica(acorde, menor)) {
        pontos += 2.2;
      }
    }
    final detalhes = _detalhesPorEstrutura(tonica, menor, extracao);
    if (detalhes.iniciaNaTonica) pontos += 2.5;
    if (detalhes.terminaNaTonica) pontos += 3.5;
    pontos += detalhes.secoesIniciadasNaTonica * 0.5;
    pontos += detalhes.secoesTerminadasNaTonica * 0.5;
    // Sem sétima ou preparação, V–I também pode ser ouvido como I–IV no
    // candidato concorrente; a resolução autêntica recebe reforço separado.
    pontos += detalhes.cadenciasV1 * 4;
    pontos += detalhes.cadenciasIV1 * 3;
    pontos += detalhes.cadenciasII51 * 8;
    pontos += detalhes.cadenciasVII1 * 4;
    pontos += detalhes.dominantesComSetima * 1.5;
    pontos += detalhes.dominantesSecundarias * 0.8;
    return pontos;
  }

  _DetalhesCandidato _detalhes(
    CandidatoTonal candidato,
    _ExtracaoTonal extracao,
  ) {
    final menor = candidato.tom.endsWith('m');
    final raiz = menor
        ? candidato.tom.substring(0, candidato.tom.length - 1)
        : candidato.tom;
    return _detalhesPorEstrutura(_classe(raiz), menor, extracao);
  }

  _DetalhesCandidato _detalhesPorEstrutura(
    int tonica,
    bool menor,
    _ExtracaoTonal extracao,
  ) {
    final acordes = extracao.acordes;
    final compativeis = acordes
        .where((a) => _compativel(a, tonica, menor))
        .length;
    final tonicas = acordes
        .where((a) => a.fundamental == tonica && _qualidadeTonica(a, menor))
        .length;
    final quinto = (tonica + 7) % 12;
    final quarto = (tonica + 5) % 12;
    final segundo = (tonica + 2) % 12;
    var v1 = 0;
    var iv1 = 0;
    var ii51 = 0;
    var dominantes7 = 0;
    var vii1 = 0;
    var secundarias = 0;
    var finaisTonica = 0;
    var iniciosTonica = 0;
    for (final secao in extracao.secoes) {
      final sequencia = secao.acordes;
      if (sequencia.isEmpty) continue;
      if (sequencia.last.fundamental == tonica &&
          _qualidadeTonica(sequencia.last, menor)) {
        finaisTonica++;
      }
      if (sequencia.first.fundamental == tonica &&
          _qualidadeTonica(sequencia.first, menor)) {
        iniciosTonica++;
      }
      for (var i = 0; i < sequencia.length - 1; i++) {
        final atual = sequencia[i];
        final proximo = sequencia[i + 1];
        final resolveTonica =
            proximo.fundamental == tonica && _qualidadeTonica(proximo, menor);
        if (atual.fundamental == quinto &&
            resolveTonica &&
            (!menor || atual.qualidade == QualidadeAcorde.maior)) {
          v1++;
          if (atual.dominanteComSetima) dominantes7++;
        }
        if (atual.fundamental == quarto && resolveTonica) iv1++;
        if (atual.fundamental == (tonica + 11) % 12 &&
            atual.qualidade == QualidadeAcorde.diminuto &&
            resolveTonica) {
          vii1++;
        }
        if (_ehDominanteSecundariaResolvida(atual, proximo, tonica, menor)) {
          secundarias++;
        }
        if (i < sequencia.length - 2 &&
            atual.fundamental == segundo &&
            sequencia[i + 1].fundamental == quinto &&
            sequencia[i + 2].fundamental == tonica &&
            _qualidadeTonica(sequencia[i + 2], menor)) {
          ii51++;
        }
      }
    }
    return _DetalhesCandidato(
      compatibilidade: compativeis / acordes.length,
      tonica: tonicas,
      iniciaNaTonica:
          acordes.first.fundamental == tonica &&
          _qualidadeTonica(acordes.first, menor),
      terminaNaTonica:
          acordes.last.fundamental == tonica &&
          _qualidadeTonica(acordes.last, menor),
      cadenciasV1: v1,
      cadenciasIV1: iv1,
      cadenciasII51: ii51,
      dominantesComSetima: dominantes7,
      cadenciasVII1: vii1,
      dominantesSecundarias: secundarias,
      secoesTerminadasNaTonica: finaisTonica,
      secoesIniciadasNaTonica: iniciosTonica,
    );
  }

  bool _detectarModulacao(_ExtracaoTonal extracao) {
    final centros = <String>[];
    for (final secao in extracao.secoes) {
      if (secao.acordes.length < 8) continue;
      final trecho = _ExtracaoTonal([secao]);
      final candidatos = _pontuar(trecho)..sort(_ordenarCandidatos);
      final detalhes = _detalhes(candidatos.first, trecho);
      if (detalhes.resolucoesFortes >= 2 &&
          detalhes.secoesTerminadasNaTonica > 0 &&
          candidatos.first.pontuacao - candidatos[1].pontuacao >= 8) {
        centros.add(candidatos.first.tom);
      }
    }
    if (centros.length < 2 && extracao.acordes.length >= 12) {
      final meio = extracao.acordes.length ~/ 2;
      for (final parte in [
        extracao.acordes.sublist(0, meio),
        extracao.acordes.sublist(meio),
      ]) {
        final secao = _SecaoTonal('janela')..adicionarLinha(parte);
        final trecho = _ExtracaoTonal([secao]);
        final candidatos = _pontuar(trecho)..sort(_ordenarCandidatos);
        final detalhes = _detalhes(candidatos.first, trecho);
        if (detalhes.resolucoesFortes >= 2 &&
            detalhes.secoesTerminadasNaTonica > 0 &&
            candidatos.first.pontuacao - candidatos[1].pontuacao >= 4) {
          centros.add(candidatos.first.tom);
        }
      }
    }
    if (centros.length < 2) return false;
    final primeiro = centros.first;
    return centros.any((centro) => !_tonsRelativosOuIguais(primeiro, centro));
  }

  bool _ehDominanteSecundariaResolvida(
    _OcorrenciaAcorde acorde,
    _OcorrenciaAcorde? proximo,
    int tonica,
    bool menor,
  ) {
    if (proximo == null ||
        acorde.qualidade != QualidadeAcorde.maior ||
        acorde.fundamental != (proximo.fundamental + 7) % 12 ||
        proximo.fundamental == tonica) {
      return false;
    }
    return _grausDiatonicos(menor)
        .contains((proximo.fundamental - tonica) % 12);
  }

  bool _emprestadoComum(_OcorrenciaAcorde acorde, int tonica, bool menor) {
    final grau = (acorde.fundamental - tonica) % 12;
    if (!menor) {
      return (grau == 5 && acorde.qualidade == QualidadeAcorde.menor) ||
          (grau == 8 && acorde.qualidade == QualidadeAcorde.maior) ||
          (grau == 10 && acorde.qualidade == QualidadeAcorde.maior);
    }
    return grau == 5 && acorde.qualidade == QualidadeAcorde.maior;
  }

  Set<int> _grausDiatonicos(bool menor) =>
      menor ? const {0, 2, 3, 5, 7, 8, 10, 11} : const {0, 2, 4, 5, 7, 9, 11};

  bool _pareceTokenDeAcorde(String token) =>
      RegExp(r'^[A-G][#b]?[A-Za-z0-9#b()+°ºøΔ/\-]*$').hasMatch(token);

  List<_SecaoTonal> _removerSecoesRepetidas(List<_SecaoTonal> secoes) {
    final resultado = <_SecaoTonal>[];
    String? anterior;
    for (final secao in secoes.where((s) => s.acordes.isNotEmpty)) {
      final assinatura = '${secao.rotulo}|${secao.assinatura}';
      if (assinatura == anterior) continue;
      resultado.add(secao);
      anterior = assinatura;
    }
    return resultado;
  }

  String _normalizarRotulo(String rotulo) => rotulo
      .toLowerCase()
      .replaceAll(RegExp(r'\d+|[ªº:]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  bool _tonsRelativosOuIguais(String a, String b) {
    final menorA = a.endsWith('m');
    final menorB = b.endsWith('m');
    final raizA = menorA ? a.substring(0, a.length - 1) : a;
    final raizB = menorB ? b.substring(0, b.length - 1) : b;
    final classeA = _classe(raizA);
    final classeB = _classe(raizB);
    if (classeA == classeB && menorA == menorB) return true;
    return menorA != menorB &&
        ((menorA ? classeA - classeB : classeB - classeA) % 12 == 9);
  }

  double _raizQuadrada(num valor) {
    if (valor <= 0) return 0;
    var estimativa = valor.toDouble();
    for (var i = 0; i < 12; i++) {
      estimativa = (estimativa + valor / estimativa) / 2;
    }
    return estimativa;
  }

  bool _compativel(_OcorrenciaAcorde acorde, int tonica, bool menor) {
    final grau = (acorde.fundamental - tonica) % 12;
    if (acorde.qualidade == QualidadeAcorde.quinta ||
        acorde.qualidade == QualidadeAcorde.aumentado ||
        acorde.texto.contains('sus')) {
      return (menor
              ? const {0, 2, 3, 5, 7, 8, 10, 11}
              : const {0, 2, 4, 5, 7, 9, 11})
          .contains(grau);
    }
    final permitidas = menor
        ? const <int, Set<QualidadeAcorde>>{
            0: {QualidadeAcorde.menor},
            2: {QualidadeAcorde.diminuto, QualidadeAcorde.menor},
            3: {QualidadeAcorde.maior},
            5: {QualidadeAcorde.menor, QualidadeAcorde.maior},
            7: {QualidadeAcorde.maior, QualidadeAcorde.menor},
            8: {QualidadeAcorde.maior},
            10: {QualidadeAcorde.maior},
            11: {QualidadeAcorde.diminuto},
          }
        : const <int, Set<QualidadeAcorde>>{
            0: {QualidadeAcorde.maior},
            2: {QualidadeAcorde.menor},
            4: {QualidadeAcorde.menor},
            5: {QualidadeAcorde.maior},
            7: {QualidadeAcorde.maior},
            9: {QualidadeAcorde.menor},
            11: {QualidadeAcorde.diminuto},
          };
    return permitidas[grau]?.contains(acorde.qualidade) ?? false;
  }

  bool _qualidadeTonica(_OcorrenciaAcorde acorde, bool menor) => menor
      ? acorde.qualidade == QualidadeAcorde.menor
      : acorde.qualidade == QualidadeAcorde.maior;

  int _ordenarCandidatos(CandidatoTonal a, CandidatoTonal b) =>
      b.pontuacao.compareTo(a.pontuacao);

  String _nomeTom(int classe, bool menor, List<_OcorrenciaAcorde> acordes) {
    final grafiaObservada = acordes
        .where((a) => a.fundamental == classe)
        .map((a) => RegExp(r'^[A-G][#b]?').firstMatch(a.texto)?.group(0))
        .whereType<String>()
        .firstOrNull;
    final raiz =
        grafiaObservada ??
        const [
          'C',
          'C#',
          'D',
          'Eb',
          'E',
          'F',
          'F#',
          'G',
          'Ab',
          'A',
          'Bb',
          'B',
        ][classe];
    return '$raiz${menor ? 'm' : ''}';
  }

  int _classe(String nota) {
    const naturais = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
    var valor = naturais[nota[0]]!;
    if (nota.length > 1) valor += nota[1] == '#' ? 1 : -1;
    return valor % 12;
  }

  ResultadoDeteccaoTom _resultadoInsuficiente(int quantidade) =>
      ResultadoDeteccaoTom(
        tomDetectado: null,
        confianca: ConfiancaDeteccaoTom.baixa,
        evidencias: const ['Nenhum acorde musical confiável foi identificado.'],
        segundoCandidato: null,
        diferencaPontuacao: 0,
        quantidadeAcordes: quantidade,
        possivelModulacao: false,
        primeiroCandidato: null,
        primeiroAcorde: null,
        ultimoAcorde: null,
        evidenciasSegundoCandidato: const [],
      );
}

class _OcorrenciaAcorde {
  const _OcorrenciaAcorde({
    required this.texto,
    required this.fundamental,
    required this.qualidade,
    required this.dominanteComSetima,
  });

  final String texto;
  final int fundamental;
  final QualidadeAcorde qualidade;
  final bool dominanteComSetima;

  String get assinatura => '$fundamental:${qualidade.name}';
}

class _SecaoTonal {
  _SecaoTonal(this.rotulo);

  final String rotulo;
  final List<List<_OcorrenciaAcorde>> linhas = [];

  List<_OcorrenciaAcorde> get acordes => [for (final linha in linhas) ...linha];

  String get assinatura => acordes.map((a) => a.assinatura).join(',');

  void adicionarLinha(List<_OcorrenciaAcorde> acordes) {
    if (acordes.isNotEmpty) linhas.add(List.unmodifiable(acordes));
  }
}

class _ExtracaoTonal {
  const _ExtracaoTonal(this.secoes);

  final List<_SecaoTonal> secoes;

  List<_OcorrenciaAcorde> get acordes => [
    for (final secao in secoes) ...secao.acordes,
  ];
}

class _DetalhesCandidato {
  const _DetalhesCandidato({
    required this.compatibilidade,
    required this.tonica,
    required this.iniciaNaTonica,
    required this.terminaNaTonica,
    required this.cadenciasV1,
    required this.cadenciasIV1,
    required this.cadenciasII51,
    required this.dominantesComSetima,
    required this.cadenciasVII1,
    required this.dominantesSecundarias,
    required this.secoesTerminadasNaTonica,
    required this.secoesIniciadasNaTonica,
  });

  final double compatibilidade;
  final int tonica;
  final bool iniciaNaTonica;
  final bool terminaNaTonica;
  final int cadenciasV1;
  final int cadenciasIV1;
  final int cadenciasII51;
  final int dominantesComSetima;
  final int cadenciasVII1;
  final int dominantesSecundarias;
  final int secoesTerminadasNaTonica;
  final int secoesIniciadasNaTonica;

  int get resolucoesFortes =>
      cadenciasV1 + cadenciasII51 + cadenciasVII1 + dominantesComSetima;

  int get evidenciaAutenticada =>
      cadenciasII51 + cadenciasVII1 + dominantesComSetima;

  bool get temEvidenciaResolutiva =>
      cadenciasV1 > 0 ||
      cadenciasIV1 > 0 ||
      cadenciasII51 > 0 ||
      cadenciasVII1 > 0 ||
      (iniciaNaTonica && terminaNaTonica);
}
