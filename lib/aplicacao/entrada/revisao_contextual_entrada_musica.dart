import '../../dominio/servicos/parser_acorde.dart';
import 'classificador_linha_cifra_textual.dart';
import 'conversor_cifra_textual.dart';

class FaixaNoRascunho {
  const FaixaNoRascunho({required this.inicio, required this.fim});
  final int inicio;
  final int fim;
  bool cabeEm(String conteudo) =>
      inicio >= 0 && fim >= inicio && fim <= conteudo.length;
}

class ContextoProblemaDeCifra {
  const ContextoProblemaDeCifra({required this.antes, required this.depois});
  final String antes;
  final String depois;
  String comAlvo(String alvo) => '$antes[$alvo]$depois';
}

enum TipoProblemaDeCifra { acordeOuTextoAmbiguo, acordeNaoInterpretavel }

enum AcaoProblemaDeCifra { ehAcorde, ehTexto, corrigirAcorde }

enum GravidadeProblemaDeCifra { informativo, limitaFuncionalidade, bloqueia }

class RevisaoDoRascunho {
  const RevisaoDoRascunho({required this.numero, required this.assinatura});
  final int numero;
  final String assinatura;
  @override
  bool operator ==(Object other) =>
      other is RevisaoDoRascunho &&
      other.numero == numero &&
      other.assinatura == assinatura;
  @override
  int get hashCode => Object.hash(numero, assinatura);
}

class ProblemaDeCifra {
  ProblemaDeCifra({
    required this.tipo,
    required this.faixaNoRascunho,
    required this.textoEncontrado,
    required this.contexto,
    required this.motivo,
    required Iterable<AcaoProblemaDeCifra> acoesPermitidas,
    required this.revisaoDoRascunho,
    required this.gravidade,
    this.linhaDeAvisoConversao,
  }) : acoesPermitidas = Set.unmodifiable(acoesPermitidas);

  final TipoProblemaDeCifra tipo;
  final FaixaNoRascunho faixaNoRascunho;
  final String textoEncontrado;
  final ContextoProblemaDeCifra contexto;
  final String motivo;
  final Set<AcaoProblemaDeCifra> acoesPermitidas;
  final RevisaoDoRascunho revisaoDoRascunho;
  final GravidadeProblemaDeCifra gravidade;
  final int? linhaDeAvisoConversao;
}

class AvisoConversaoNaoAcionavel {
  const AvisoConversaoNaoAcionavel({required this.aviso, required this.motivo});
  final AvisoConversaoCifra aviso;
  final String motivo;
}

class RevisaoContextualEntradaMusica {
  RevisaoContextualEntradaMusica._({
    required this.conteudoChordPro,
    required this.revisao,
    required Iterable<ProblemaDeCifra> problemas,
    required Iterable<AvisoConversaoNaoAcionavel> avisosNaoAcionaveis,
    required Iterable<AvisoConversaoCifra> avisosConversaoPendentes,
  }) : problemas = List.unmodifiable(problemas),
       avisosNaoAcionaveis = List.unmodifiable(avisosNaoAcionaveis),
       _avisosConversaoPendentes = List.unmodifiable(avisosConversaoPendentes);

  final String conteudoChordPro;
  final RevisaoDoRascunho revisao;
  final List<ProblemaDeCifra> problemas;
  final List<AvisoConversaoNaoAcionavel> avisosNaoAcionaveis;
  final List<AvisoConversaoCifra> _avisosConversaoPendentes;
}

class ProblemaDeCifraObsoleto implements Exception {
  const ProblemaDeCifraObsoleto();
}

class AcaoProblemaDeCifraNaoPermitida implements Exception {
  const AcaoProblemaDeCifraNaoPermitida();
}

class CorrecaoDeAcordeInvalida implements Exception {
  const CorrecaoDeAcordeInvalida(this.texto);
  final String texto;
}

class ResultadoAcaoProblemaDeCifra {
  const ResultadoAcaoProblemaDeCifra({
    required this.revisao,
    required this.conteudoAlterado,
  });
  final RevisaoContextualEntradaMusica revisao;
  final bool conteudoAlterado;
}

class AnalisadorProblemasDeCifra {
  AnalisadorProblemasDeCifra({ParserAcorde? parserAcorde})
    : _parserAcorde = parserAcorde ?? ParserAcorde();
  final ParserAcorde _parserAcorde;
  final _classificador = ClassificadorLinhaCifraTextual();
  static final _acordeMarcado = RegExp(r'\[([^\]\r\n]+)\]');
  static const _limiteContexto = 40;

  RevisaoContextualEntradaMusica analisar({
    required String conteudoChordPro,
    Iterable<AvisoConversaoCifra> avisosConversao = const [],
    int numeroRevisao = 0,
  }) {
    final revisao = RevisaoDoRascunho(
      numero: numeroRevisao,
      assinatura: _assinatura(conteudoChordPro),
    );
    final linhas = _localizarLinhas(conteudoChordPro);
    final avisos = List<AvisoConversaoCifra>.unmodifiable(avisosConversao);
    final problemas = <ProblemaDeCifra>[];
    final naoAcionaveis = <AvisoConversaoNaoAcionavel>[];
    final avisosPorLinha = <int, List<AvisoConversaoCifra>>{};

    for (final aviso in avisos) {
      final numeroLinha = aviso.linhaChordPro;
      if (numeroLinha == null ||
          numeroLinha < 0 ||
          numeroLinha >= linhas.length) {
        naoAcionaveis.add(
          AvisoConversaoNaoAcionavel(
            aviso: aviso,
            motivo: 'O aviso não identifica uma faixa segura no ChordPro.',
          ),
        );
      } else {
        avisosPorLinha.putIfAbsent(numeroLinha, () => []).add(aviso);
      }
    }

    for (final entry in avisosPorLinha.entries) {
      final linha = linhas[entry.key];
      final texto = conteudoChordPro.substring(linha.inicio, linha.fim);
      if (!_ehLinhaSomenteDeAcordesMarcados(texto)) {
        for (final aviso in entry.value) {
          naoAcionaveis.add(
            AvisoConversaoNaoAcionavel(
              aviso: aviso,
              motivo: 'O aviso abrange associação ou alinhamento.',
            ),
          );
        }
        continue;
      }
      final faixa = FaixaNoRascunho(inicio: linha.inicio, fim: linha.fim);
      problemas.add(
        ProblemaDeCifra(
          tipo: TipoProblemaDeCifra.acordeOuTextoAmbiguo,
          faixaNoRascunho: faixa,
          textoEncontrado: texto,
          contexto: _contexto(conteudoChordPro, faixa),
          motivo: 'Confirme se esta linha representa acordes ou texto.',
          acoesPermitidas: const {
            AcaoProblemaDeCifra.ehAcorde,
            AcaoProblemaDeCifra.ehTexto,
          },
          revisaoDoRascunho: revisao,
          gravidade: GravidadeProblemaDeCifra.informativo,
          linhaDeAvisoConversao: entry.key,
        ),
      );
    }

    for (final linha in linhas) {
      final textoLinha = conteudoChordPro.substring(linha.inicio, linha.fim);
      for (final correspondencia in _acordeMarcado.allMatches(textoLinha)) {
        final textoAcorde = correspondencia.group(1)!;
        if (_parserAcorde.interpretar(textoAcorde) is AcordeInterpretado ||
            _classificador.ehNomeDeSecao(textoAcorde)) {
          continue;
        }
        final faixa = FaixaNoRascunho(
          inicio: linha.inicio + correspondencia.start,
          fim: linha.inicio + correspondencia.end,
        );
        problemas.add(
          ProblemaDeCifra(
            tipo: TipoProblemaDeCifra.acordeNaoInterpretavel,
            faixaNoRascunho: faixa,
            textoEncontrado: correspondencia.group(0)!,
            contexto: _contexto(conteudoChordPro, faixa),
            motivo: 'O conteúdo entre colchetes não é um acorde reconhecido.',
            acoesPermitidas: const {
              AcaoProblemaDeCifra.ehTexto,
              AcaoProblemaDeCifra.corrigirAcorde,
            },
            revisaoDoRascunho: revisao,
            gravidade: GravidadeProblemaDeCifra.limitaFuncionalidade,
          ),
        );
      }
    }
    problemas.sort(
      (a, b) => a.faixaNoRascunho.inicio.compareTo(b.faixaNoRascunho.inicio),
    );
    return RevisaoContextualEntradaMusica._(
      conteudoChordPro: conteudoChordPro,
      revisao: revisao,
      problemas: problemas,
      avisosNaoAcionaveis: naoAcionaveis,
      avisosConversaoPendentes: avisos,
    );
  }

  bool _ehLinhaSomenteDeAcordesMarcados(String linha) {
    final acordes = _acordeMarcado.allMatches(linha).toList();
    if (acordes.isEmpty) return false;
    if (acordes.any(
      (acorde) =>
          _parserAcorde.interpretar(acorde.group(1)!) is! AcordeInterpretado,
    )) {
      return false;
    }
    return linha.replaceAll(_acordeMarcado, '').trim().isEmpty;
  }

  ContextoProblemaDeCifra _contexto(String conteudo, FaixaNoRascunho faixa) =>
      ContextoProblemaDeCifra(
        antes: conteudo.substring(
          (faixa.inicio - _limiteContexto).clamp(0, faixa.inicio),
          faixa.inicio,
        ),
        depois: conteudo.substring(
          faixa.fim,
          (faixa.fim + _limiteContexto).clamp(faixa.fim, conteudo.length),
        ),
      );

  List<_LinhaLocalizada> _localizarLinhas(String conteudo) {
    if (conteudo.isEmpty) return const [_LinhaLocalizada(0, 0)];
    final linhas = <_LinhaLocalizada>[];
    var inicio = 0;
    for (final quebra in RegExp(r'\r\n|\r|\n').allMatches(conteudo)) {
      linhas.add(_LinhaLocalizada(inicio, quebra.start));
      inicio = quebra.end;
    }
    linhas.add(_LinhaLocalizada(inicio, conteudo.length));
    return linhas;
  }

  String _assinatura(String conteudo) {
    var hash = 0x811c9dc5;
    for (final unidade in conteudo.codeUnits) {
      hash ^= unidade;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return '${conteudo.length}:${hash.toRadixString(16)}';
  }
}

class AplicarAcaoProblemaDeCifra {
  AplicarAcaoProblemaDeCifra({
    ParserAcorde? parserAcorde,
    AnalisadorProblemasDeCifra? analisador,
  }) : _parserAcorde = parserAcorde ?? ParserAcorde(),
       _analisador = analisador ?? AnalisadorProblemasDeCifra();
  final ParserAcorde _parserAcorde;
  final AnalisadorProblemasDeCifra _analisador;
  static final _acordeMarcado = RegExp(r'\[([^\]\r\n]+)\]');

  ResultadoAcaoProblemaDeCifra executar({
    required RevisaoContextualEntradaMusica estado,
    required ProblemaDeCifra problema,
    required AcaoProblemaDeCifra acao,
    String? correcao,
  }) {
    final faixa = problema.faixaNoRascunho;
    if (problema.revisaoDoRascunho != estado.revisao ||
        !faixa.cabeEm(estado.conteudoChordPro) ||
        estado.conteudoChordPro.substring(faixa.inicio, faixa.fim) !=
            problema.textoEncontrado) {
      throw const ProblemaDeCifraObsoleto();
    }
    if (!problema.acoesPermitidas.contains(acao)) {
      throw const AcaoProblemaDeCifraNaoPermitida();
    }
    final substituto = switch (acao) {
      AcaoProblemaDeCifra.ehAcorde => _comoAcorde(problema.textoEncontrado),
      AcaoProblemaDeCifra.ehTexto => _comoTexto(problema.textoEncontrado),
      AcaoProblemaDeCifra.corrigirAcorde => _corrigirAcorde(correcao),
    };
    final novoConteudo =
        '${estado.conteudoChordPro.substring(0, faixa.inicio)}'
        '$substituto'
        '${estado.conteudoChordPro.substring(faixa.fim)}';
    final avisosPendentes = estado._avisosConversaoPendentes.where(
      (aviso) =>
          problema.linhaDeAvisoConversao == null ||
          aviso.linhaChordPro != problema.linhaDeAvisoConversao,
    );
    final novaRevisao = _analisador.analisar(
      conteudoChordPro: novoConteudo,
      avisosConversao: avisosPendentes,
      numeroRevisao: estado.revisao.numero + 1,
    );
    return ResultadoAcaoProblemaDeCifra(
      revisao: novaRevisao,
      conteudoAlterado: novoConteudo != estado.conteudoChordPro,
    );
  }

  String _comoAcorde(String texto) {
    final acordes = _acordeMarcado.allMatches(texto).toList();
    if (acordes.isNotEmpty &&
        texto.replaceAll(_acordeMarcado, '').trim().isEmpty) {
      for (final acorde in acordes) {
        _validarAcorde(acorde.group(1)!);
      }
      return texto;
    }
    _validarAcorde(texto);
    return '[$texto]';
  }

  String _comoTexto(String texto) =>
      texto.replaceAllMapped(_acordeMarcado, (acorde) => acorde.group(1)!);

  String _corrigirAcorde(String? correcao) {
    final texto = correcao?.trim() ?? '';
    _validarAcorde(texto);
    return '[$texto]';
  }

  void _validarAcorde(String texto) {
    if (_parserAcorde.interpretar(texto) is! AcordeInterpretado) {
      throw CorrecaoDeAcordeInvalida(texto);
    }
  }
}

class _LinhaLocalizada {
  const _LinhaLocalizada(this.inicio, this.fim);
  final int inicio;
  final int fim;
}
