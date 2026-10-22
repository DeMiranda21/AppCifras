import 'detector_tonal.dart';

class ConfiguracaoPoliticaMelhorTom {
  const ConfiguracaoPoliticaMelhorTom({this.habilitada = false});

  final bool habilitada;
}

class ResultadoPoliticaMelhorTom {
  const ResultadoPoliticaMelhorTom({
    required this.aplicada,
    required this.motivo,
    this.candidatoEscolhido,
  });

  final bool aplicada;
  final String motivo;
  final CandidatoTonal? candidatoEscolhido;

  Map<String, Object?> toJson(ResultadoDeteccaoTom deteccao) => {
    'aplicada': aplicada,
    'motivo': motivo,
    'tomEscolhido': candidatoEscolhido?.tom,
    'pontuacao': candidatoEscolhido == null
        ? null
        : double.parse(candidatoEscolhido!.pontuacao.toStringAsFixed(2)),
    'confiancaOriginal': deteccao.confianca.name,
    'possivelModulacao': deteccao.possivelModulacao,
    'quantidadeAcordes': deteccao.quantidadeAcordes,
    'primeiroAcorde': deteccao.primeiroAcorde,
    'ultimoAcorde': deteccao.ultimoAcorde,
  };
}

class PoliticaMelhorTom {
  const PoliticaMelhorTom(this.configuracao);

  final ConfiguracaoPoliticaMelhorTom configuracao;

  ResultadoPoliticaMelhorTom avaliar(ResultadoDeteccaoTom deteccao) {
    if (!configuracao.habilitada) {
      return const ResultadoPoliticaMelhorTom(
        aplicada: false,
        motivo: 'politica_desabilitada',
      );
    }
    final primeiro = deteccao.primeiroCandidato;
    if (primeiro == null) {
      return const ResultadoPoliticaMelhorTom(
        aplicada: false,
        motivo: 'sem_candidato_valido',
      );
    }
    return ResultadoPoliticaMelhorTom(
      aplicada: true,
      motivo: deteccao.possivelModulacao
          ? 'centro_tonal_principal_em_modulacao'
          : 'primeiro_candidato_do_detector',
      candidatoEscolhido: primeiro,
    );
  }
}
