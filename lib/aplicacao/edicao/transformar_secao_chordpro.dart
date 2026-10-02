import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/servicos/parser_documento_chordpro.dart';
import '../estrutura/estrutura_musica.dart';
import '../estrutura/reconhecedor_secao_musica.dart';
import 'transformar_selecao_chordpro.dart';

/// Converte uma única linha textual em um ambiente ChordPro de seção.
///
/// A transformação é deliberadamente conservadora: ela só opera sobre uma
/// linha inteira fora de um ambiente estrutural explícito e não persiste nada.
class TransformarSecaoChordPro {
  TransformarSecaoChordPro({
    ParserDocumentoChordPro? parserDocumento,
    EstruturadorDocumentoChordPro? estruturador,
    ReconhecedorSecaoMusica? reconhecedor,
  }) : _parserDocumento = parserDocumento ?? ParserDocumentoChordPro(),
       _estruturador = estruturador ?? EstruturadorDocumentoChordPro(),
       _reconhecedor = reconhecedor ?? ReconhecedorSecaoMusica();

  final ParserDocumentoChordPro _parserDocumento;
  final EstruturadorDocumentoChordPro _estruturador;
  final ReconhecedorSecaoMusica _reconhecedor;

  bool podeTransformar(String conteudo, SelecaoTextoChordPro selecao) =>
      _contextoElegivel(conteudo, selecao) != null;

  ResultadoTransformacaoSecaoChordPro transformar({
    required String conteudo,
    required SelecaoTextoChordPro selecao,
    required TipoSecaoMusica tipo,
  }) {
    final contexto = _contextoElegivel(conteudo, selecao);
    if (contexto == null) {
      return ResultadoTransformacaoSecaoChordPro.semTransformacao(
        conteudo: conteudo,
        selecao: selecao,
      );
    }

    final abertura = _reconhecedor.escreverInicioCanonico(
      tipo,
      contexto.rotulo,
    );
    final fechamento = _reconhecedor.escreverFimCanonico(tipo);
    final antesDoMarcador = conteudo.substring(0, contexto.linha.inicio);
    final separador = _separadorDoDocumento(conteudo);
    final inicioDoLimite = contexto.limiteDoConteudo;
    final depoisDaAbertura =
        '$abertura${conteudo.substring(contexto.linha.fim, inicioDoLimite)}';
    final depoisDoLimite = conteudo.substring(inicioDoLimite);
    final separadorAntesDoFechamento =
        inicioDoLimite == conteudo.length &&
            !depoisDaAbertura.endsWith('\n') &&
            !depoisDaAbertura.endsWith('\r')
        ? separador
        : '';
    final novoConteudo =
        '$antesDoMarcador$depoisDaAbertura$separadorAntesDoFechamento$fechamento${inicioDoLimite == conteudo.length ? '' : separador}$depoisDoLimite';

    return ResultadoTransformacaoSecaoChordPro.transformado(
      conteudo: novoConteudo,
      selecao: SelecaoTextoChordPro(
        inicio: contexto.linha.inicio,
        fim: contexto.linha.inicio + abertura.length,
      ),
    );
  }

  _ContextoSecao? _contextoElegivel(
    String conteudo,
    SelecaoTextoChordPro selecao,
  ) {
    if (!selecao.temConteudo ||
        selecao.inicio < 0 ||
        selecao.fim > conteudo.length) {
      return null;
    }
    final linhas = _linhas(conteudo);
    final indiceDaLinha = linhas.indexWhere(
      (linha) => linha.inicio == selecao.inicio && linha.fim == selecao.fim,
    );
    if (indiceDaLinha < 0) {
      return null;
    }
    final linha = linhas[indiceDaLinha];
    if (linha.texto.trim().isEmpty || _ehDiretiva(linha.texto)) {
      return null;
    }

    final documento = _parserDocumento.interpretar(conteudo);
    if (_estaEmAmbienteExplicito(documento.elementos, indiceDaLinha)) {
      return null;
    }
    final estrutura = _estruturador.estruturar(documento);
    final proximosMarcadores = estrutura.secoes
        .map((secao) => secao.indiceMarcador)
        .whereType<int>()
        .where((indice) => indice > indiceDaLinha);
    final proximoMarcador = proximosMarcadores.isEmpty
        ? null
        : proximosMarcadores.reduce(
            (menor, indice) => indice < menor ? indice : menor,
          );
    final limiteDoConteudo = proximoMarcador == null
        ? conteudo.length
        : linhas[proximoMarcador].inicio;
    return _ContextoSecao(
      linha: linha,
      rotulo: linha.texto,
      limiteDoConteudo: limiteDoConteudo,
    );
  }

  bool _estaEmAmbienteExplicito(
    List<ElementoDocumentoChordPro> elementos,
    int indiceSelecionado,
  ) {
    final ambientesAbertos = <String>[];
    for (var indice = 0; indice < elementos.length; indice += 1) {
      final marcador = _reconhecedor.reconhecerDiretiva(
        elementos[indice].conteudoOriginal,
      );
      if (indice == indiceSelecionado) {
        return ambientesAbertos.isNotEmpty || marcador != null;
      }
      if (marcador == null) {
        continue;
      }
      if (marcador.ehInicio) {
        ambientesAbertos.add(marcador.ambiente);
      } else {
        ambientesAbertos.remove(marcador.ambiente);
      }
    }
    return false;
  }

  bool _ehDiretiva(String linha) {
    final aparada = linha.trim();
    return aparada.startsWith('{') && aparada.endsWith('}');
  }

  String _separadorDoDocumento(String conteudo) => conteudo.contains('\r\n')
      ? '\r\n'
      : conteudo.contains('\r')
      ? '\r'
      : '\n';

  List<_LinhaDoDocumento> _linhas(String conteudo) {
    final linhas = <_LinhaDoDocumento>[];
    var inicio = 0;
    for (final separador in RegExp(r'\r\n|\n|\r').allMatches(conteudo)) {
      linhas.add(
        _LinhaDoDocumento(
          inicio: inicio,
          fim: separador.start,
          texto: conteudo.substring(inicio, separador.start),
        ),
      );
      inicio = separador.end;
    }
    linhas.add(
      _LinhaDoDocumento(
        inicio: inicio,
        fim: conteudo.length,
        texto: conteudo.substring(inicio),
      ),
    );
    return linhas;
  }
}

class ResultadoTransformacaoSecaoChordPro {
  const ResultadoTransformacaoSecaoChordPro._({
    required this.conteudo,
    required this.selecao,
    required this.foiTransformado,
  });

  factory ResultadoTransformacaoSecaoChordPro.transformado({
    required String conteudo,
    required SelecaoTextoChordPro selecao,
  }) => ResultadoTransformacaoSecaoChordPro._(
    conteudo: conteudo,
    selecao: selecao,
    foiTransformado: true,
  );

  factory ResultadoTransformacaoSecaoChordPro.semTransformacao({
    required String conteudo,
    required SelecaoTextoChordPro selecao,
  }) => ResultadoTransformacaoSecaoChordPro._(
    conteudo: conteudo,
    selecao: selecao,
    foiTransformado: false,
  );

  final String conteudo;
  final SelecaoTextoChordPro selecao;
  final bool foiTransformado;
}

class _ContextoSecao {
  const _ContextoSecao({
    required this.linha,
    required this.rotulo,
    required this.limiteDoConteudo,
  });

  final _LinhaDoDocumento linha;
  final String rotulo;
  final int limiteDoConteudo;
}

class _LinhaDoDocumento {
  const _LinhaDoDocumento({
    required this.inicio,
    required this.fim,
    required this.texto,
  });

  final int inicio;
  final int fim;
  final String texto;
}
