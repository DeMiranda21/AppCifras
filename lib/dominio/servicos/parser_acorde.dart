import '../objetos_de_valor/acorde.dart';
import '../objetos_de_valor/nota.dart';

/// Resultado da interpretação de uma cifra individual.
sealed class ResultadoParserAcorde {
  const ResultadoParserAcorde();
}

/// Resultado para uma cifra que pertence ao subconjunto interpretável do MVP.
class AcordeInterpretado extends ResultadoParserAcorde {
  const AcordeInterpretado(this.acorde);

  final Acorde acorde;
}

/// Resultado para uma cifra preservada sem interpretação estrutural.
class AcordeNaoInterpretavel extends ResultadoParserAcorde {
  const AcordeNaoInterpretavel(this.textoOriginal);

  final String textoOriginal;
}

/// Interpreta uma cifra individual segundo o subconjunto aprovado do MVP.
class ParserAcorde {
  static final _fundamental = RegExp(r'^([A-G])([#b]?)(.*)$');
  static final _baixo = RegExp(r'^([A-G])([#b]?)$');

  /// Interpreta [texto] integralmente ou preserva-o como não interpretável.
  ResultadoParserAcorde interpretar(String texto) {
    final partesDaInversao = texto.split('/');
    if (partesDaInversao.length > 2) {
      return AcordeNaoInterpretavel(texto);
    }

    final estrutura = _interpretarEstrutura(partesDaInversao.first);
    if (estrutura == null) {
      return AcordeNaoInterpretavel(texto);
    }

    Nota? baixo;
    if (partesDaInversao.length == 2) {
      baixo = _interpretarNotaCompleta(partesDaInversao.last);
      if (baixo == null) {
        return AcordeNaoInterpretavel(texto);
      }
    }

    return AcordeInterpretado(
      Acorde(
        notaFundamental: estrutura.notaFundamental,
        qualidade: estrutura.qualidade,
        extensoes: estrutura.extensoes,
        alteracoes: estrutura.alteracoes,
        suspensoes: estrutura.suspensoes,
        adicoes: estrutura.adicoes,
        baixo: baixo,
      ),
    );
  }

  _EstruturaAcorde? _interpretarEstrutura(String texto) {
    final correspondencia = _fundamental.firstMatch(texto);
    if (correspondencia == null) {
      return null;
    }

    final notaFundamental = _criarNota(
      correspondencia.group(1)!,
      correspondencia.group(2)!,
    );
    final sufixo = correspondencia.group(3)!;
    final partes = _separarSufixoEParenteses(sufixo);
    if (partes == null) {
      return null;
    }

    final estrutura = _interpretarBase(notaFundamental, partes.base);
    if (estrutura == null) {
      return null;
    }

    for (final componente in partes.componentesEntreParenteses) {
      if (!_adicionarComponenteEntreParenteses(estrutura, componente)) {
        return null;
      }
    }

    return estrutura;
  }

  _PartesDoSufixo? _separarSufixoEParenteses(String sufixo) {
    final indiceDoPrimeiroParenteses = sufixo.indexOf('(');
    if (indiceDoPrimeiroParenteses == -1) {
      return _PartesDoSufixo(sufixo, const []);
    }

    final base = sufixo.substring(0, indiceDoPrimeiroParenteses);
    var restante = sufixo.substring(indiceDoPrimeiroParenteses);
    final componentes = <String>[];
    final grupo = RegExp(r'^\(([^()]+)\)');

    while (restante.isNotEmpty) {
      final correspondencia = grupo.firstMatch(restante);
      if (correspondencia == null) {
        return null;
      }
      componentes.add(correspondencia.group(1)!);
      restante = restante.substring(correspondencia.end);
    }

    return _PartesDoSufixo(base, componentes);
  }

  _EstruturaAcorde? _interpretarBase(Nota notaFundamental, String base) {
    final estrutura = _EstruturaAcorde(notaFundamental);

    switch (base) {
      case '':
        return estrutura;
      case 'm':
        estrutura.qualidade = QualidadeAcorde.menor;
        return estrutura;
      case '5':
        estrutura.qualidade = QualidadeAcorde.quinta;
        return estrutura;
      case '6':
        estrutura.extensoes.add(ExtensaoAcorde.sexta);
        return estrutura;
      case 'm6':
        estrutura.qualidade = QualidadeAcorde.menor;
        estrutura.extensoes.add(ExtensaoAcorde.sexta);
        return estrutura;
      case '7':
        estrutura.extensoes.add(ExtensaoAcorde.setima);
        return estrutura;
      case 'm7':
        estrutura.qualidade = QualidadeAcorde.menor;
        estrutura.extensoes.add(ExtensaoAcorde.setima);
        return estrutura;
      case 'maj7':
      case '7M':
      case 'M7':
      case 'Δ7':
        estrutura.extensoes.add(ExtensaoAcorde.setimaMaior);
        return estrutura;
      case '9':
        estrutura.extensoes.addAll({
          ExtensaoAcorde.setima,
          ExtensaoAcorde.nona,
        });
        return estrutura;
      case 'm9':
        estrutura.qualidade = QualidadeAcorde.menor;
        estrutura.extensoes.addAll({
          ExtensaoAcorde.setima,
          ExtensaoAcorde.nona,
        });
        return estrutura;
      case '11':
        estrutura.extensoes.addAll({
          ExtensaoAcorde.setima,
          ExtensaoAcorde.nona,
          ExtensaoAcorde.decimaPrimeira,
        });
        return estrutura;
      case '13':
        estrutura.extensoes.addAll({
          ExtensaoAcorde.setima,
          ExtensaoAcorde.nona,
          ExtensaoAcorde.decimaPrimeira,
          ExtensaoAcorde.decimaTerceira,
        });
        return estrutura;
      case 'add9':
        estrutura.adicoes.add(AdicaoAcorde.nona);
        return estrutura;
      case 'add11':
        estrutura.adicoes.add(AdicaoAcorde.decimaPrimeira);
        return estrutura;
      case 'sus2':
        estrutura.suspensoes.add(SuspensaoAcorde.segunda);
        return estrutura;
      case 'sus4':
      case '4':
        estrutura.suspensoes.add(SuspensaoAcorde.quarta);
        return estrutura;
      case 'dim':
      case '°':
        estrutura.qualidade = QualidadeAcorde.diminuto;
        return estrutura;
      case 'aug':
      case '+':
        estrutura.qualidade = QualidadeAcorde.aumentado;
        return estrutura;
      case 'ø':
        estrutura.qualidade = QualidadeAcorde.menor;
        estrutura.extensoes.add(ExtensaoAcorde.setima);
        estrutura.alteracoes.add(
          AlteracaoAcorde(grau: 5, alteracao: AlteracaoNota.bemol),
        );
        return estrutura;
      default:
        return null;
    }
  }

  bool _adicionarComponenteEntreParenteses(
    _EstruturaAcorde estrutura,
    String componente,
  ) {
    switch (componente) {
      case 'b5':
        estrutura.alteracoes.add(
          AlteracaoAcorde(grau: 5, alteracao: AlteracaoNota.bemol),
        );
        return true;
      case '#5':
        estrutura.alteracoes.add(
          AlteracaoAcorde(grau: 5, alteracao: AlteracaoNota.sustenido),
        );
        return true;
      case 'b9':
        estrutura.alteracoes.add(
          AlteracaoAcorde(grau: 9, alteracao: AlteracaoNota.bemol),
        );
        return true;
      case '#9':
        estrutura.alteracoes.add(
          AlteracaoAcorde(grau: 9, alteracao: AlteracaoNota.sustenido),
        );
        return true;
      case '9':
        estrutura.extensoes.add(ExtensaoAcorde.nona);
        return true;
      case '13':
        estrutura.extensoes.add(ExtensaoAcorde.decimaTerceira);
        return true;
      default:
        return false;
    }
  }

  Nota? _interpretarNotaCompleta(String texto) {
    final correspondencia = _baixo.firstMatch(texto);
    if (correspondencia == null) {
      return null;
    }
    return _criarNota(correspondencia.group(1)!, correspondencia.group(2)!);
  }

  Nota _criarNota(String nome, String acidente) => Nota(
    nome: switch (nome) {
      'A' => NomeNota.a,
      'B' => NomeNota.b,
      'C' => NomeNota.c,
      'D' => NomeNota.d,
      'E' => NomeNota.e,
      'F' => NomeNota.f,
      'G' => NomeNota.g,
      _ => throw ArgumentError.value(nome, 'nome'),
    },
    alteracao: switch (acidente) {
      '' => AlteracaoNota.natural,
      '#' => AlteracaoNota.sustenido,
      'b' => AlteracaoNota.bemol,
      _ => throw ArgumentError.value(acidente, 'acidente'),
    },
  );
}

class _PartesDoSufixo {
  const _PartesDoSufixo(this.base, this.componentesEntreParenteses);

  final String base;
  final List<String> componentesEntreParenteses;
}

class _EstruturaAcorde {
  _EstruturaAcorde(this.notaFundamental);

  final Nota notaFundamental;
  var qualidade = QualidadeAcorde.maior;
  final extensoes = <ExtensaoAcorde>{};
  final alteracoes = <AlteracaoAcorde>{};
  final suspensoes = <SuspensaoAcorde>{};
  final adicoes = <AdicaoAcorde>{};
}
