import 'package:appcifras/aplicacao/diagnostico/medicao_desempenho_biblioteca.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('agrega etapas e emite somente uma linha ao apresentar', () async {
    final mensagens = <String>[];
    final medicao = MedicaoDesempenhoBiblioteca.iniciar(
      motivo: MotivoCarregamentoBiblioteca.retornoMusica,
      registrar: mensagens.add,
    )!;

    await medicao.executarNoContexto(() async {
      expect(MedicaoDesempenhoBiblioteca.atual, same(medicao));
      await medicao.medirSqlite(() async => 1);
      await medicao.medirLeituraArquivo(() async => 'conteudo');
      medicao.medirInterpretacaoChordPro(() => Object());
      medicao.medirCriacaoIndice(() => Object());
      medicao.registrarQuantidadeMusicas(1);
    });

    medicao.concluirCarregamento();
    medicao.concluirApresentacao();
    medicao.concluirApresentacao();

    expect(MedicaoDesempenhoBiblioteca.atual, isNull);
    expect(mensagens, hasLength(1));
    expect(mensagens.single, contains('motivo=retornoMusica'));
    expect(mensagens.single, contains('sucesso=true'));
    expect(mensagens.single, contains('musicas=1'));
    expect(mensagens.single, contains('arquivos_lidos=1'));
    expect(mensagens.single, contains('documentos_interpretados=1'));
    expect(mensagens.single, contains('sqlite_acumulado_ms='));
    expect(mensagens.single, contains('ate_primeiro_frame_ms='));
  });

  test('registra conclusão com falha sem exigir primeiro frame', () {
    final mensagens = <String>[];
    final medicao = MedicaoDesempenhoBiblioteca.iniciar(
      motivo: MotivoCarregamentoBiblioteca.primeiraAbertura,
      registrar: mensagens.add,
    )!;

    medicao.concluirCarregamento();
    medicao.concluirApresentacao(sucesso: false);

    expect(mensagens.single, contains('sucesso=false'));
  });
}
