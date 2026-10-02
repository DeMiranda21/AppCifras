import '../../dominio/servicos/parser_documento_chordpro.dart';
import '../estrutura/estrutura_musica.dart';
import '../estrutura/reconhecedor_secao_musica.dart';
import 'transformar_selecao_chordpro.dart';

enum EstadoEdicaoSecaoChordPro { alterado, semAlteracao, invalido }

class ContextoEdicaoSecaoChordPro {
  const ContextoEdicaoSecaoChordPro({required this.tipo, required this.label});

  final TipoSecaoMusica tipo;
  final String? label;
}

class ResultadoEdicaoSecaoChordPro {
  const ResultadoEdicaoSecaoChordPro({
    required this.conteudo,
    required this.selecao,
    required this.estado,
  });

  final String conteudo;
  final SelecaoTextoChordPro selecao;
  final EstadoEdicaoSecaoChordPro estado;

  bool get foiAlterado => estado == EstadoEdicaoSecaoChordPro.alterado;
}

/// Edita somente os delimitadores de uma seção explícita já reconhecida.
///
/// A estrutura derivada identifica a seção; o texto interno continua sendo
/// copiado literalmente. Assim, aliases e ambientes externos só são
/// normalizados após uma mudança semântica explícita.
class EditarSecaoChordPro {
  EditarSecaoChordPro({
    ParserDocumentoChordPro? parserDocumento,
    EstruturadorDocumentoChordPro? estruturador,
    ReconhecedorSecaoMusica? reconhecedor,
  }) : _parserDocumento = parserDocumento ?? ParserDocumentoChordPro(),
       _estruturador = estruturador ?? EstruturadorDocumentoChordPro(),
       _reconhecedor = reconhecedor ?? ReconhecedorSecaoMusica();

  final ParserDocumentoChordPro _parserDocumento;
  final EstruturadorDocumentoChordPro _estruturador;
  final ReconhecedorSecaoMusica _reconhecedor;

  ContextoEdicaoSecaoChordPro? contextoAtual({
    required String conteudo,
    required SelecaoTextoChordPro selecao,
  }) {
    final alvo = _encontrarAlvo(conteudo, selecao);
    return alvo == null
        ? null
        : ContextoEdicaoSecaoChordPro(
            tipo: alvo.secao.tipo,
            label: alvo.labelAtual,
          );
  }

  ResultadoEdicaoSecaoChordPro editar({
    required String conteudo,
    required SelecaoTextoChordPro selecao,
    required TipoSecaoMusica novoTipo,
    required String novoLabel,
  }) {
    final alvo = _encontrarAlvo(conteudo, selecao);
    if (alvo == null || novoLabel.trim().isEmpty) {
      return _resultado(conteudo, selecao, EstadoEdicaoSecaoChordPro.invalido);
    }

    if (alvo.secao.tipo == novoTipo && alvo.labelAtual == novoLabel) {
      return _resultado(
        conteudo,
        selecao,
        EstadoEdicaoSecaoChordPro.semAlteracao,
      );
    }

    final abertura = _reconhecedor.escreverInicioCanonico(novoTipo, novoLabel);
    final fechamento = _reconhecedor.escreverFimCanonico(novoTipo);
    final antes = conteudo.substring(0, alvo.linhaInicio.inicio);
    final interno = conteudo.substring(
      alvo.linhaInicio.fimComSeparador,
      alvo.inicioFechamento,
    );
    final separador = _separadorDoDocumento(conteudo);
    final separadorAposInicio = alvo.linhaInicio.separadorApos.isEmpty
        ? separador
        : alvo.linhaInicio.separadorApos;
    final precisaSeparadorAntesFechamento =
        interno.isNotEmpty && !_terminaComQuebraDeLinha(interno);
    final depois = alvo.linhaFechamento == null
        ? ''
        : conteudo.substring(alvo.linhaFechamento!.fimComSeparador);
    final separadorAposFechamento = alvo.linhaFechamento?.separadorApos ?? '';
    final novoConteudo =
        '$antes$abertura$separadorAposInicio$interno'
        '${precisaSeparadorAntesFechamento ? separador : ''}'
        '$fechamento$separadorAposFechamento$depois';
    final novoInicioConteudo =
        antes.length + abertura.length + separadorAposInicio.length;
    final novoInicioFechamento =
        novoInicioConteudo +
        interno.length +
        (precisaSeparadorAntesFechamento ? separador.length : 0);

    return ResultadoEdicaoSecaoChordPro(
      conteudo: novoConteudo,
      selecao: _recalcularSelecao(
        alvo,
        selecao,
        abertura,
        fechamento,
        novoInicioConteudo,
        novoInicioFechamento,
      ),
      estado: EstadoEdicaoSecaoChordPro.alterado,
    );
  }

  ResultadoEdicaoSecaoChordPro _resultado(
    String conteudo,
    SelecaoTextoChordPro selecao,
    EstadoEdicaoSecaoChordPro estado,
  ) => ResultadoEdicaoSecaoChordPro(
    conteudo: conteudo,
    selecao: selecao,
    estado: estado,
  );

  _AlvoEdicaoSecao? _encontrarAlvo(
    String conteudo,
    SelecaoTextoChordPro selecao,
  ) {
    if (selecao.inicio < 0 ||
        selecao.fim < selecao.inicio ||
        selecao.fim > conteudo.length) {
      return null;
    }
    final documento = _parserDocumento.interpretar(conteudo);
    final estrutura = _estruturador.estruturar(documento);
    final linhas = _linhas(conteudo);
    for (final secao in estrutura.secoes) {
      final indiceInicio = secao.indiceMarcador;
      if (indiceInicio == null || indiceInicio >= linhas.length) {
        continue;
      }
      final linhaInicio = linhas[indiceInicio];
      final marcadorInicio = _reconhecedor.reconhecerDiretiva(
        documento.elementos[indiceInicio].conteudoOriginal,
      );
      if (marcadorInicio == null || !marcadorInicio.ehInicio) {
        continue;
      }
      final indicePossivelFechamento = secao.fimConteudoExclusivo;
      final marcadorFim = indicePossivelFechamento < documento.elementos.length
          ? _reconhecedor.reconhecerDiretiva(
              documento.elementos[indicePossivelFechamento].conteudoOriginal,
            )
          : null;
      final possuiFechamento =
          marcadorFim != null &&
          !marcadorFim.ehInicio &&
          marcadorFim.ambiente == marcadorInicio.ambiente;
      final linhaFechamento = possuiFechamento
          ? linhas[indicePossivelFechamento]
          : null;
      final fimDaSecao = linhaFechamento?.fim ?? conteudo.length;
      if (!_selecaoEstaNaFaixa(selecao, linhaInicio.inicio, fimDaSecao)) {
        continue;
      }
      return _AlvoEdicaoSecao(
        secao: secao,
        linhaInicio: linhaInicio,
        linhaFechamento: linhaFechamento,
        inicioFechamento: linhaFechamento?.inicio ?? conteudo.length,
        labelAtual: _reconhecedor.extrairLabelDaDiretiva(
          documento.elementos[indiceInicio].conteudoOriginal,
        ),
      );
    }
    return null;
  }

  bool _selecaoEstaNaFaixa(SelecaoTextoChordPro selecao, int inicio, int fim) =>
      selecao.inicio >= inicio &&
      selecao.fim <= fim &&
      (selecao.inicio != fim || inicio == fim);

  SelecaoTextoChordPro _recalcularSelecao(
    _AlvoEdicaoSecao alvo,
    SelecaoTextoChordPro selecao,
    String abertura,
    String fechamento,
    int novoInicioConteudo,
    int novoInicioFechamento,
  ) => SelecaoTextoChordPro(
    inicio: _recalcularOffset(
      alvo,
      selecao.inicio,
      abertura,
      fechamento,
      novoInicioConteudo,
      novoInicioFechamento,
    ),
    fim: _recalcularOffset(
      alvo,
      selecao.fim,
      abertura,
      fechamento,
      novoInicioConteudo,
      novoInicioFechamento,
    ),
  );

  int _recalcularOffset(
    _AlvoEdicaoSecao alvo,
    int offset,
    String abertura,
    String fechamento,
    int novoInicioConteudo,
    int novoInicioFechamento,
  ) {
    final inicioAntigo = alvo.linhaInicio.inicio;
    final fimInicioAntigo = alvo.linhaInicio.fim;
    if (offset <= fimInicioAntigo) {
      return inicioAntigo +
          (offset - inicioAntigo).clamp(0, abertura.length).toInt();
    }
    final linhaFim = alvo.linhaFechamento;
    final inicioAntigoConteudo = alvo.linhaInicio.fimComSeparador;
    if (linhaFim == null || offset < linhaFim.inicio) {
      return novoInicioConteudo + (offset - inicioAntigoConteudo);
    }
    return novoInicioFechamento +
        (offset - linhaFim.inicio).clamp(0, fechamento.length).toInt();
  }

  bool _terminaComQuebraDeLinha(String texto) =>
      texto.endsWith('\n') || texto.endsWith('\r');

  String _separadorDoDocumento(String conteudo) => conteudo.contains('\r\n')
      ? '\r\n'
      : conteudo.contains('\r')
      ? '\r'
      : '\n';

  List<_LinhaChordPro> _linhas(String conteudo) {
    final linhas = <_LinhaChordPro>[];
    var inicio = 0;
    for (final separador in RegExp(r'\r\n|\n|\r').allMatches(conteudo)) {
      linhas.add(
        _LinhaChordPro(
          inicio: inicio,
          fim: separador.start,
          fimComSeparador: separador.end,
          separadorApos: separador.group(0)!,
        ),
      );
      inicio = separador.end;
    }
    linhas.add(
      _LinhaChordPro(
        inicio: inicio,
        fim: conteudo.length,
        fimComSeparador: conteudo.length,
        separadorApos: '',
      ),
    );
    return linhas;
  }
}

class _AlvoEdicaoSecao {
  const _AlvoEdicaoSecao({
    required this.secao,
    required this.linhaInicio,
    required this.linhaFechamento,
    required this.inicioFechamento,
    required this.labelAtual,
  });

  final SecaoMusica secao;
  final _LinhaChordPro linhaInicio;
  final _LinhaChordPro? linhaFechamento;
  final int inicioFechamento;
  final String? labelAtual;
}

class _LinhaChordPro {
  const _LinhaChordPro({
    required this.inicio,
    required this.fim,
    required this.fimComSeparador,
    required this.separadorApos,
  });

  final int inicio;
  final int fim;
  final int fimComSeparador;
  final String separadorApos;
}
