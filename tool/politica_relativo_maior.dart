import 'dart:convert';
import 'dart:io';

import 'detector_tonal.dart';
import 'politica_melhor_tom.dart';

/// Configuração editorial da preferência pelo relativo maior.
///
/// A margem padrão de quatro pontos reutiliza o corte já empregado pelo
/// detector para separar o primeiro do segundo candidato na confiança média.
class ConfiguracaoPoliticaRelativoMaior {
  const ConfiguracaoPoliticaRelativoMaior({
    this.habilitada = false,
    this.margemTerceiroCompetitivo = 4,
    this.minimoAcordes = 4,
  });

  final bool habilitada;
  final double margemTerceiroCompetitivo;
  final int minimoAcordes;
}

class ConfiguracaoCuradoria {
  const ConfiguracaoCuradoria({
    this.politicaRelativoMaior = const ConfiguracaoPoliticaRelativoMaior(),
    this.politicaMelhorTom = const ConfiguracaoPoliticaMelhorTom(),
    this.origem = 'padrao',
  });

  static const padrao = ConfiguracaoCuradoria();

  final ConfiguracaoPoliticaRelativoMaior politicaRelativoMaior;
  final ConfiguracaoPoliticaMelhorTom politicaMelhorTom;
  final String origem;

  static Future<ConfiguracaoCuradoria> carregar(Directory biblioteca) async {
    final arquivo = File(
      '${biblioteca.path}${Platform.pathSeparator}curadoria_config.json',
    );
    if (!await arquivo.exists()) return padrao;

    late final Object? bruto;
    try {
      bruto = jsonDecode(await arquivo.readAsString());
    } on FormatException catch (erro) {
      throw FormatException('curadoria_config.json inválido: $erro');
    }
    if (bruto is! Map<String, dynamic> ||
        bruto['schema'] != 1 ||
        bruto['politica_relativo_maior'] is! Map ||
        (bruto.containsKey('politica_melhor_tom') &&
            bruto['politica_melhor_tom'] is! Map)) {
      throw const FormatException(
        'curadoria_config.json deve conter schema 1 e '
        'politica_relativo_maior.',
      );
    }
    const camposRaiz = {
      'schema',
      'politica_relativo_maior',
      'politica_melhor_tom',
    };
    final desconhecidosRaiz = bruto.keys.where(
      (chave) => !camposRaiz.contains(chave),
    );
    if (desconhecidosRaiz.isNotEmpty) {
      throw FormatException(
        'Campos desconhecidos em curadoria_config.json: '
        '${desconhecidosRaiz.join(', ')}.',
      );
    }

    final dados = Map<String, dynamic>.from(
      bruto['politica_relativo_maior'] as Map,
    );
    const campos = {
      'habilitada',
      'margem_terceiro_competitivo',
      'minimo_acordes',
    };
    final desconhecidos = dados.keys.where((chave) => !campos.contains(chave));
    if (desconhecidos.isNotEmpty) {
      throw FormatException(
        'Campos desconhecidos em politica_relativo_maior: '
        '${desconhecidos.join(', ')}.',
      );
    }
    final habilitada = dados['habilitada'];
    final margem = dados['margem_terceiro_competitivo'];
    final minimo = dados['minimo_acordes'];
    if (habilitada is! bool ||
        margem is! num ||
        !margem.isFinite ||
        margem <= 0 ||
        minimo is! int ||
        minimo < 4) {
      throw const FormatException(
        'Configuração de politica_relativo_maior inválida.',
      );
    }
    final dadosMelhorTom = bruto['politica_melhor_tom'] == null
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(bruto['politica_melhor_tom'] as Map);
    final desconhecidosMelhorTom = dadosMelhorTom.keys.where(
      (chave) => chave != 'habilitada',
    );
    if (desconhecidosMelhorTom.isNotEmpty) {
      throw FormatException(
        'Campos desconhecidos em politica_melhor_tom: '
        '${desconhecidosMelhorTom.join(', ')}.',
      );
    }
    final habilitadaMelhorTom = dadosMelhorTom['habilitada'] ?? false;
    if (habilitadaMelhorTom is! bool) {
      throw const FormatException(
        'Configuração de politica_melhor_tom inválida.',
      );
    }
    return ConfiguracaoCuradoria(
      politicaRelativoMaior: ConfiguracaoPoliticaRelativoMaior(
        habilitada: habilitada,
        margemTerceiroCompetitivo: margem.toDouble(),
        minimoAcordes: minimo,
      ),
      politicaMelhorTom: ConfiguracaoPoliticaMelhorTom(
        habilitada: habilitadaMelhorTom,
      ),
      origem: arquivo.path,
    );
  }
}

class ResultadoPoliticaRelativoMaior {
  const ResultadoPoliticaRelativoMaior({
    required this.aplicavelAntesDoTerceiro,
    required this.aplicada,
    required this.motivo,
    this.tomMaior,
    this.relativoMenor,
    this.pontuacaoMaior,
    this.pontuacaoMenor,
    this.terceiroCandidato,
    this.diferencaSegundoTerceiro,
  });

  final bool aplicavelAntesDoTerceiro;
  final bool aplicada;
  final String motivo;
  final String? tomMaior;
  final String? relativoMenor;
  final double? pontuacaoMaior;
  final double? pontuacaoMenor;
  final CandidatoTonal? terceiroCandidato;
  final double? diferencaSegundoTerceiro;

  Map<String, Object?> toJson({
    required ResultadoDeteccaoTom deteccao,
    required ConfiguracaoPoliticaRelativoMaior configuracao,
  }) => {
    'aplicavelAntesDoTerceiro': aplicavelAntesDoTerceiro,
    'aplicada': aplicada,
    'motivo': motivo,
    'candidatoMaior': tomMaior,
    'tomMaiorEscolhido': aplicada ? tomMaior : null,
    'relativoMenorDescartado': relativoMenor,
    'candidatosSaoRelativos': tomMaior != null && relativoMenor != null,
    'mesmaArmadura': tomMaior != null && relativoMenor != null,
    'pontuacaoMaior': _duasCasas(pontuacaoMaior),
    'pontuacaoMenor': _duasCasas(pontuacaoMenor),
    'diferencaPontuacaoMaiorMenor':
        pontuacaoMaior == null || pontuacaoMenor == null
        ? null
        : double.parse(
            (pontuacaoMaior! - pontuacaoMenor!).abs().toStringAsFixed(2),
          ),
    'quantidadeAcordes': deteccao.quantidadeAcordes,
    'possivelModulacao': deteccao.possivelModulacao,
    'terceiroCandidatoCompetitivo': motivo == 'terceiro_candidato_competitivo',
    'terceiroCandidato': terceiroCandidato?.toJson(),
    'diferencaSegundoTerceiro': _duasCasas(diferencaSegundoTerceiro),
    'margemTerceiroCompetitivo': configuracao.margemTerceiroCompetitivo,
    'primeiroAcorde': deteccao.primeiroAcorde,
    'ultimoAcorde': deteccao.ultimoAcorde,
  };

  static double? _duasCasas(double? valor) =>
      valor == null ? null : double.parse(valor.toStringAsFixed(2));
}

class PoliticaRelativoMaior {
  const PoliticaRelativoMaior(this.configuracao);

  final ConfiguracaoPoliticaRelativoMaior configuracao;

  ResultadoPoliticaRelativoMaior avaliar(ResultadoDeteccaoTom resultado) {
    if (!configuracao.habilitada) {
      return const ResultadoPoliticaRelativoMaior(
        aplicavelAntesDoTerceiro: false,
        aplicada: false,
        motivo: 'politica_desabilitada',
      );
    }
    if (resultado.confianca != ConfiancaDeteccaoTom.media) {
      return const ResultadoPoliticaRelativoMaior(
        aplicavelAntesDoTerceiro: false,
        aplicada: false,
        motivo: 'confianca_nao_media',
      );
    }
    if (resultado.possivelModulacao) {
      return const ResultadoPoliticaRelativoMaior(
        aplicavelAntesDoTerceiro: false,
        aplicada: false,
        motivo: 'possivel_modulacao',
      );
    }
    if (resultado.quantidadeAcordes < configuracao.minimoAcordes) {
      return const ResultadoPoliticaRelativoMaior(
        aplicavelAntesDoTerceiro: false,
        aplicada: false,
        motivo: 'evidencia_insuficiente',
      );
    }
    if (resultado.candidatosOrdenados.length < 2) {
      return const ResultadoPoliticaRelativoMaior(
        aplicavelAntesDoTerceiro: false,
        aplicada: false,
        motivo: 'menos_de_dois_candidatos',
      );
    }

    final primeiro = resultado.candidatosOrdenados[0];
    final segundo = resultado.candidatosOrdenados[1];
    final par = _parRelativo(primeiro, segundo);
    if (par == null) {
      return const ResultadoPoliticaRelativoMaior(
        aplicavelAntesDoTerceiro: false,
        aplicada: false,
        motivo: 'candidatos_nao_relativos',
      );
    }

    final terceiro = resultado.candidatosOrdenados.length > 2
        ? resultado.candidatosOrdenados[2]
        : null;
    final diferencaSegundoTerceiro = terceiro == null
        ? null
        : segundo.pontuacao - terceiro.pontuacao;
    final terceiroCompetitivo =
        diferencaSegundoTerceiro != null &&
        diferencaSegundoTerceiro < configuracao.margemTerceiroCompetitivo;
    if (terceiroCompetitivo) {
      return ResultadoPoliticaRelativoMaior(
        aplicavelAntesDoTerceiro: true,
        aplicada: false,
        motivo: 'terceiro_candidato_competitivo',
        tomMaior: par.maior.tom,
        relativoMenor: par.menor.tom,
        pontuacaoMaior: par.maior.pontuacao,
        pontuacaoMenor: par.menor.pontuacao,
        terceiroCandidato: terceiro,
        diferencaSegundoTerceiro: diferencaSegundoTerceiro,
      );
    }

    return ResultadoPoliticaRelativoMaior(
      aplicavelAntesDoTerceiro: true,
      aplicada: true,
      motivo: 'maior_e_relativo_menor_sem_terceiro_competitivo',
      tomMaior: par.maior.tom,
      relativoMenor: par.menor.tom,
      pontuacaoMaior: par.maior.pontuacao,
      pontuacaoMenor: par.menor.pontuacao,
      terceiroCandidato: terceiro,
      diferencaSegundoTerceiro: diferencaSegundoTerceiro,
    );
  }

  _ParRelativo? _parRelativo(CandidatoTonal a, CandidatoTonal b) {
    final aMenor = a.tom.endsWith('m');
    final bMenor = b.tom.endsWith('m');
    if (aMenor == bMenor) return null;
    final maior = aMenor ? b : a;
    final menor = aMenor ? a : b;
    final classeMaior = _classe(maior.tom);
    final classeMenor = _classe(menor.tom.substring(0, menor.tom.length - 1));
    return classeMenor == (classeMaior + 9) % 12
        ? _ParRelativo(maior, menor)
        : null;
  }

  int _classe(String tom) {
    const naturais = {'C': 0, 'D': 2, 'E': 4, 'F': 5, 'G': 7, 'A': 9, 'B': 11};
    var classe = naturais[tom[0]]!;
    if (tom.length > 1) classe += tom[1] == '#' ? 1 : -1;
    return classe % 12;
  }
}

class _ParRelativo {
  const _ParRelativo(this.maior, this.menor);

  final CandidatoTonal maior;
  final CandidatoTonal menor;
}
