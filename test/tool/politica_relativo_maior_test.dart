import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/detector_tonal.dart';
import '../../tool/politica_relativo_maior.dart';

void main() {
  const configuracao = ConfiguracaoPoliticaRelativoMaior(
    habilitada: true,
    margemTerceiroCompetitivo: 4,
    minimoAcordes: 4,
  );
  const politica = PoliticaRelativoMaior(configuracao);

  test('C e Am escolhem C', () {
    final decisao = politica.avaliar(_resultado(['C', 'Am', 'F']));
    expect(decisao.aplicada, isTrue);
    expect(decisao.tomMaior, 'C');
    expect(decisao.relativoMenor, 'Am');
  });

  test('G e Em escolhem G', () {
    final decisao = politica.avaliar(_resultado(['G', 'Em', 'C']));
    expect(decisao.aplicada, isTrue);
    expect(decisao.tomMaior, 'G');
  });

  test('D e Bm escolhem D', () {
    final decisao = politica.avaliar(_resultado(['D', 'Bm', 'G']));
    expect(decisao.aplicada, isTrue);
    expect(decisao.tomMaior, 'D');
  });

  test('ordem inversa e relativo menor superior ainda escolhem o maior', () {
    final decisao = politica.avaliar(
      _resultado(['Am', 'C', 'F'], pontuacoes: [100, 95, 88]),
    );
    expect(decisao.aplicada, isTrue);
    expect(decisao.tomMaior, 'C');
    expect(decisao.pontuacaoMenor, 100);
    expect(decisao.pontuacaoMaior, 95);
  });

  test('maior e menor paralelos não acionam a política', () {
    final decisao = politica.avaliar(_resultado(['C', 'Cm', 'G']));
    expect(decisao.aplicada, isFalse);
    expect(decisao.motivo, 'candidatos_nao_relativos');
  });

  test('candidatos não relativos não acionam a política', () {
    final decisao = politica.avaliar(_resultado(['C', 'Em', 'G']));
    expect(decisao.aplicada, isFalse);
    expect(decisao.motivo, 'candidatos_nao_relativos');
  });

  test('inferência de confiança alta mantém precedência', () {
    final decisao = politica.avaliar(
      _resultado(['C', 'Am', 'F'], confianca: ConfiancaDeteccaoTom.alta),
    );
    expect(decisao.aplicada, isFalse);
    expect(decisao.motivo, 'confianca_nao_media');
  });

  test('possível modulação impede a política', () {
    final decisao = politica.avaliar(
      _resultado(['C', 'Am', 'F'], possivelModulacao: true),
    );
    expect(decisao.aplicada, isFalse);
    expect(decisao.motivo, 'possivel_modulacao');
  });

  test('terceiro candidato competitivo impede a política', () {
    final decisao = politica.avaliar(
      _resultado(['C', 'Am', 'F'], pontuacoes: [100, 95, 92]),
    );
    expect(decisao.aplicavelAntesDoTerceiro, isTrue);
    expect(decisao.aplicada, isFalse);
    expect(decisao.motivo, 'terceiro_candidato_competitivo');
    expect(decisao.diferencaSegundoTerceiro, 3);
    expect(
      decisao.toJson(
        deteccao: _resultado(['C', 'Am', 'F'], pontuacoes: [100, 95, 92]),
        configuracao: configuracao,
      )['candidatoMaior'],
      'C',
    );
  });

  test('pouca evidência impede a política', () {
    final decisao = politica.avaliar(
      _resultado(['C', 'Am', 'F'], quantidadeAcordes: 3),
    );
    expect(decisao.aplicada, isFalse);
    expect(decisao.motivo, 'evidencia_insuficiente');
  });

  test('comportamento padrão permanece desabilitado', () {
    const desabilitada = PoliticaRelativoMaior(
      ConfiguracaoPoliticaRelativoMaior(),
    );
    final decisao = desabilitada.avaliar(_resultado(['C', 'Am', 'F']));
    expect(decisao.aplicada, isFalse);
    expect(decisao.motivo, 'politica_desabilitada');
  });

  test('carrega configuração explícita', () async {
    final pasta = await Directory.systemTemp.createTemp('config_curadoria_');
    addTearDown(() => pasta.delete(recursive: true));
    await File('${pasta.path}${Platform.pathSeparator}curadoria_config.json')
        .writeAsString('''
{"schema":1,"politica_relativo_maior":{"habilitada":true,"margem_terceiro_competitivo":4,"minimo_acordes":4}}
''');

    final carregada = await ConfiguracaoCuradoria.carregar(pasta);

    expect(carregada.politicaRelativoMaior.habilitada, isTrue);
    expect(carregada.politicaRelativoMaior.margemTerceiroCompetitivo, 4);
    expect(carregada.politicaRelativoMaior.minimoAcordes, 4);
    expect(carregada.origem, endsWith('curadoria_config.json'));
  });

  test('rejeita campos de configuração desconhecidos', () async {
    final pasta = await Directory.systemTemp.createTemp('config_curadoria_');
    addTearDown(() => pasta.delete(recursive: true));
    await File('${pasta.path}${Platform.pathSeparator}curadoria_config.json')
        .writeAsString('''
{"schema":1,"politica_relativo_maior":{"habilitada":true,"margem_terceiro_competitivo":4,"minimo_acordes":4,"oculto":true}}
''');

    expect(
      () => ConfiguracaoCuradoria.carregar(pasta),
      throwsA(isA<FormatException>()),
    );
  });
}

ResultadoDeteccaoTom _resultado(
  List<String> tons, {
  List<double> pontuacoes = const [100, 95, 88],
  ConfiancaDeteccaoTom confianca = ConfiancaDeteccaoTom.media,
  int quantidadeAcordes = 8,
  bool possivelModulacao = false,
}) {
  final candidatos = [
    for (var i = 0; i < tons.length; i++)
      CandidatoTonal(tom: tons[i], pontuacao: pontuacoes[i]),
  ];
  return ResultadoDeteccaoTom(
    tomDetectado: candidatos.first.tom,
    confianca: confianca,
    evidencias: const [],
    segundoCandidato: candidatos[1],
    diferencaPontuacao: candidatos.first.pontuacao - candidatos[1].pontuacao,
    quantidadeAcordes: quantidadeAcordes,
    possivelModulacao: possivelModulacao,
    primeiroCandidato: candidatos.first,
    primeiroAcorde: tons.first,
    ultimoAcorde: tons[1],
    evidenciasSegundoCandidato: const [],
    candidatosOrdenados: candidatos,
  );
}
