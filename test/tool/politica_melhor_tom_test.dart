import 'package:flutter_test/flutter_test.dart';

import '../../tool/detector_tonal.dart';
import '../../tool/politica_melhor_tom.dart';

void main() {
  test('política fica desabilitada por padrão', () {
    final resultado = const PoliticaMelhorTom(ConfiguracaoPoliticaMelhorTom())
        .avaliar(_deteccao(ConfiancaDeteccaoTom.media));

    expect(resultado.aplicada, isFalse);
    expect(resultado.motivo, 'politica_desabilitada');
  });

  for (final confianca in [
    ConfiancaDeteccaoTom.media,
    ConfiancaDeteccaoTom.baixa,
  ]) {
    test('seleciona primeiro candidato com confiança ${confianca.name}', () {
      final deteccao = _deteccao(confianca);
      final resultado = const PoliticaMelhorTom(
        ConfiguracaoPoliticaMelhorTom(habilitada: true),
      ).avaliar(deteccao);

      expect(resultado.aplicada, isTrue);
      expect(resultado.candidatoEscolhido, same(deteccao.primeiroCandidato));
      expect(resultado.candidatoEscolhido!.tom, 'D');
    });
  }

  test('possível modulação usa o centro tonal principal', () {
    final deteccao = _deteccao(
      ConfiancaDeteccaoTom.baixa,
      possivelModulacao: true,
    );
    final resultado = const PoliticaMelhorTom(
      ConfiguracaoPoliticaMelhorTom(habilitada: true),
    ).avaliar(deteccao);

    expect(resultado.candidatoEscolhido, same(deteccao.primeiroCandidato));
    expect(resultado.motivo, 'centro_tonal_principal_em_modulacao');
  });

  test('ausência de candidato válido preserva exclusão', () {
    final resultado = const PoliticaMelhorTom(
      ConfiguracaoPoliticaMelhorTom(habilitada: true),
    ).avaliar(_deteccao(ConfiancaDeteccaoTom.baixa, semCandidatos: true));

    expect(resultado.aplicada, isFalse);
    expect(resultado.motivo, 'sem_candidato_valido');
  });
}

ResultadoDeteccaoTom _deteccao(
  ConfiancaDeteccaoTom confianca, {
  bool possivelModulacao = false,
  bool semCandidatos = false,
}) {
  const primeiro = CandidatoTonal(tom: 'D', pontuacao: 12);
  const segundo = CandidatoTonal(tom: 'Bm', pontuacao: 10);
  final candidatos = semCandidatos
      ? const <CandidatoTonal>[]
      : const [primeiro, segundo];
  return ResultadoDeteccaoTom(
    tomDetectado: semCandidatos ? null : primeiro.tom,
    confianca: confianca,
    evidencias: const [],
    segundoCandidato: semCandidatos ? null : segundo,
    diferencaPontuacao: semCandidatos ? 0 : 2,
    quantidadeAcordes: semCandidatos ? 0 : 4,
    possivelModulacao: possivelModulacao,
    primeiroCandidato: semCandidatos ? null : primeiro,
    primeiroAcorde: semCandidatos ? null : 'D',
    ultimoAcorde: semCandidatos ? null : 'D',
    evidenciasSegundoCandidato: const [],
    candidatosOrdenados: candidatos,
  );
}
