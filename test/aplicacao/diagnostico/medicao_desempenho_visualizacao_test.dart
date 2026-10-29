import 'package:appcifras/aplicacao/diagnostico/medicao_desempenho_visualizacao.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'agrega abertura e emite uma única linha após o primeiro frame',
    () async {
      final mensagens = <String>[];
      final medicao = MedicaoDesempenhoVisualizacao.iniciar(
        origem: OrigemAberturaVisualizacao.listaCulto,
        registrar: mensagens.add,
      )!;

      await medicao.executarNoContexto(() async {
        expect(MedicaoDesempenhoVisualizacao.atual, same(medicao));
        await medicao.medirCarregamentoCatalogo(() async => 1);
        await medicao.medirCarregamentoVersao(() async => 1);
        await medicao.medirSqlite(() async => 1);
        await medicao.medirLeituraArquivo(() async => 'conteudo');
        medicao.medirInterpretacaoChordPro(() => Object());
        medicao.medirProcessamentoMusical(() => Object());
        medicao.medirConstrucaoInterface(() => Object());
      });
      medicao.marcarDadosProntos();
      medicao.concluirApresentacao();
      medicao.concluirApresentacao();

      expect(mensagens, hasLength(1));
      expect(mensagens.single, startsWith('[QX-02][Visualizacao]'));
      expect(mensagens.single, contains('origem=listaCulto'));
      expect(mensagens.single, contains('consultas_sqlite=1'));
      expect(mensagens.single, contains('arquivos_lidos=1'));
      expect(mensagens.single, contains('documentos_interpretados=1'));
      expect(mensagens.single, contains('total_ate_cifra_ms='));
      expect(mensagens.single, contains('dados_prontos_ate_frame_ms='));
    },
  );

  test('registra falha mesmo sem dados prontos', () {
    final mensagens = <String>[];
    final medicao = MedicaoDesempenhoVisualizacao.iniciar(
      origem: OrigemAberturaVisualizacao.biblioteca,
      registrar: mensagens.add,
    )!;

    medicao.concluirApresentacao(sucesso: false);

    expect(mensagens.single, contains('origem=biblioteca'));
    expect(mensagens.single, contains('sucesso=false'));
  });
}
