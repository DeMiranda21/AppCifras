import 'package:appcifras/aplicacao/entrada/preparar_entrada_musica.dart';
import 'package:appcifras/aplicacao/entrada/revisao_contextual_entrada_musica.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final analisador = AnalisadorProblemasDeCifra();
  final aplicar = AplicarAcaoProblemaDeCifra(analisador: analisador);

  ProblemaDeCifra problemaManual(
    RevisaoContextualEntradaMusica estado,
    String texto,
    Set<AcaoProblemaDeCifra> acoes,
  ) => ProblemaDeCifra(
    tipo: TipoProblemaDeCifra.acordeOuTextoAmbiguo,
    faixaNoRascunho: FaixaNoRascunho(inicio: 0, fim: texto.length),
    textoEncontrado: texto,
    contexto: const ContextoProblemaDeCifra(antes: '', depois: ''),
    motivo: 'Teste de transformação pura.',
    acoesPermitidas: acoes,
    revisaoDoRascunho: estado.revisao,
    gravidade: GravidadeProblemaDeCifra.informativo,
  );

  group('infraestrutura contextual da entrada', () {
    test('localiza separadamente duas ocorrências idênticas', () {
      const conteudo = 'Antes [H7] depois\nOutra [H7] linha';

      final estado = analisador.analisar(conteudoChordPro: conteudo);

      expect(estado.problemas, hasLength(2));
      expect(estado.problemas.map((p) => p.textoEncontrado), ['[H7]', '[H7]']);
      expect(
        estado.problemas[0].faixaNoRascunho.inicio,
        isNot(estado.problemas[1].faixaNoRascunho.inicio),
      );
      expect(
        estado.problemas[1].contexto.comAlvo('[H7]'),
        contains('Outra [[H7]] linha'),
      );
    });

    test('altera somente a ocorrência alvo e preserva o restante', () {
      const conteudo = 'Antes [H7] depois\nOutra [H7] linha\nINALTERADO';
      final estado = analisador.analisar(conteudoChordPro: conteudo);

      final resultado = aplicar.executar(
        estado: estado,
        problema: estado.problemas[1],
        acao: AcaoProblemaDeCifra.corrigirAcorde,
        correcao: 'Am7',
      );

      expect(
        resultado.revisao.conteudoChordPro,
        'Antes [H7] depois\nOutra [Am7] linha\nINALTERADO',
      );
      expect(resultado.revisao.problemas, hasLength(1));
      expect(resultado.revisao.problemas.single.textoEncontrado, '[H7]');
    });

    test('rejeita problema de revisão antiga após mudança do rascunho', () {
      final antigo = analisador.analisar(conteudoChordPro: '[H7] primeira');
      final atual = analisador.analisar(
        conteudoChordPro: 'prefixo [H7] primeira',
        numeroRevisao: antigo.revisao.numero + 1,
      );

      expect(
        () => aplicar.executar(
          estado: atual,
          problema: antigo.problemas.single,
          acao: AcaoProblemaDeCifra.ehTexto,
        ),
        throwsA(isA<ProblemaDeCifraObsoleto>()),
      );
    });

    test('É acorde produz marcação ChordPro validada', () {
      final estado = analisador.analisar(conteudoChordPro: 'Am7');
      final problema = problemaManual(estado, 'Am7', {
        AcaoProblemaDeCifra.ehAcorde,
      });

      final resultado = aplicar.executar(
        estado: estado,
        problema: problema,
        acao: AcaoProblemaDeCifra.ehAcorde,
      );

      expect(resultado.revisao.conteudoChordPro, '[Am7]');
      expect(resultado.conteudoAlterado, isTrue);
    });

    test('É texto remove marcação sem destruir conteúdo literal', () {
      final estado = analisador.analisar(conteudoChordPro: 'Antes [H7] depois');

      final resultado = aplicar.executar(
        estado: estado,
        problema: estado.problemas.single,
        acao: AcaoProblemaDeCifra.ehTexto,
      );

      expect(resultado.revisao.conteudoChordPro, 'Antes H7 depois');
      expect(resultado.revisao.problemas, isEmpty);
    });

    test('Corrigir acorde aceita valor válido e resolve o problema', () {
      final estado = analisador.analisar(conteudoChordPro: '[H7]Letra');

      final resultado = aplicar.executar(
        estado: estado,
        problema: estado.problemas.single,
        acao: AcaoProblemaDeCifra.corrigirAcorde,
        correcao: 'G/B',
      );

      expect(resultado.revisao.conteudoChordPro, '[G/B]Letra');
      expect(resultado.revisao.problemas, isEmpty);
    });

    test('Corrigir acorde rejeita valor inválido sem produzir estado', () {
      final estado = analisador.analisar(conteudoChordPro: '[H7]Letra');

      expect(
        () => aplicar.executar(
          estado: estado,
          problema: estado.problemas.single,
          acao: AcaoProblemaDeCifra.corrigirAcorde,
          correcao: 'SOL',
        ),
        throwsA(isA<CorrecaoDeAcordeInvalida>()),
      );
      expect(estado.conteudoChordPro, '[H7]Letra');
    });

    test('reanálise recalcula problemas e mantém somente os pendentes', () {
      final estado = analisador.analisar(
        conteudoChordPro: '[H7] primeira e [X9] segunda',
      );

      final resultado = aplicar.executar(
        estado: estado,
        problema: estado.problemas.first,
        acao: AcaoProblemaDeCifra.corrigirAcorde,
        correcao: 'C',
      );

      expect(resultado.revisao.revisao.numero, estado.revisao.numero + 1);
      expect(resultado.revisao.problemas, hasLength(1));
      expect(resultado.revisao.problemas.single.textoEncontrado, '[X9]');
      expect(
        resultado.revisao.problemas.single.revisaoDoRascunho,
        resultado.revisao.revisao,
      );
    });

    test('pipeline expõe avisos instrumentais como problemas acionáveis', () {
      final entrada = PrepararEntradaMusica().executar('Am7 G/B');

      expect(entrada.problemasDeCifra, hasLength(1));
      final problema = entrada.problemasDeCifra.single;
      expect(problema.textoEncontrado, '[Am7] [G/B]');
      expect(problema.acoesPermitidas, {
        AcaoProblemaDeCifra.ehAcorde,
        AcaoProblemaDeCifra.ehTexto,
      });

      final resultado = aplicar.executar(
        estado: entrada.revisaoContextual!,
        problema: problema,
        acao: AcaoProblemaDeCifra.ehTexto,
      );
      expect(resultado.revisao.conteudoChordPro, 'Am7 G/B');
      expect(resultado.revisao.problemas, isEmpty);
    });

    test('linhas idênticas convertidas mantêm localizações distintas', () {
      final entrada = PrepararEntradaMusica().executar('Am7 G/B\n\nAm7 G/B');

      expect(entrada.problemasDeCifra, hasLength(2));
      expect(
        entrada.problemasDeCifra[0].faixaNoRascunho.inicio,
        isNot(entrada.problemasDeCifra[1].faixaNoRascunho.inicio),
      );

      final resultado = aplicar.executar(
        estado: entrada.revisaoContextual!,
        problema: entrada.problemasDeCifra.first,
        acao: AcaoProblemaDeCifra.ehAcorde,
      );
      expect(resultado.conteudoAlterado, isFalse);
      expect(resultado.revisao.problemas, hasLength(1));
      expect(
        resultado.revisao.conteudoChordPro,
        entrada.revisaoContextual!.conteudoChordPro,
      );
    });

    test('aviso composto permanece não acionável sem offset frágil', () {
      final entrada = PrepararEntradaMusica().executar('C          G\nOi');

      expect(entrada.avisosConversaoNaoAcionaveis, isNotEmpty);
      expect(
        entrada.avisosConversaoNaoAcionaveis.first.motivo,
        contains('associação ou alinhamento'),
      );
    });
  });
}
