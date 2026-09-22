import 'package:appcifras/aplicacao/entrada/reanalisador_conteudo_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final reanalisador = ReanalisadorConteudoChordPro();

  test('preserva documento totalmente ChordPro', () {
    const conteudo =
        '{title: Música}\n{artist: Artista}\n{key: E}\n[E]Letra [D2(6)]\n{comment: Solo}';
    expect(reanalisador.analisar(conteudo).chordProSugerido, conteudo);
  });

  test('converte somente par textual entre trechos ChordPro', () {
    const conteudo = '[E]Antes\n\nAm       F\nNova letra\n\n[G]Depois';
    expect(
      reanalisador.analisar(conteudo).chordProSugerido,
      '[E]Antes\n\n[Am]Nova [F]letra\n\n[G]Depois',
    );
  });

  test('preserva rótulos, diretivas, tablatura e acordes não interpretáveis', () {
    const conteudo =
        '[Ponte]\n[Intro]\n[Refrão]\n{desconhecida: x}\n{comment: Solo}\n{start_of_tab}\nE|--0--|\n{end_of_tab}\n[H7]Preservar';
    expect(reanalisador.analisar(conteudo).chordProSugerido, conteudo);
  });

  test('converte vários pares textuais e preserva caso ambíguo', () {
    const conteudo =
        'Am       F\nPrimeira letra\n\nC       G\nSegunda letra\n\nAm F';
    expect(
      reanalisador.analisar(conteudo).chordProSugerido,
      '[Am]Primeira [F]letra\n\n[C]Segunda [G]letra\n\nAm F',
    );
  });
}
