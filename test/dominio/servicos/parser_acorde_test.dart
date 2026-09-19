import 'package:appcifras/dominio/objetos_de_valor/acorde.dart';
import 'package:appcifras/dominio/objetos_de_valor/nota.dart';
import 'package:appcifras/dominio/servicos/parser_acorde.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserAcorde();

  group('ParserAcorde - subconjunto básico', () {
    final casos = <String, Acorde>{
      'C': Acorde(notaFundamental: const Nota(nome: NomeNota.c)),
      'Cm': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        qualidade: QualidadeAcorde.menor,
      ),
      'C#': Acorde(
        notaFundamental: const Nota(
          nome: NomeNota.c,
          alteracao: AlteracaoNota.sustenido,
        ),
      ),
      'Bb': Acorde(
        notaFundamental: const Nota(
          nome: NomeNota.b,
          alteracao: AlteracaoNota.bemol,
        ),
      ),
      'F#m': Acorde(
        notaFundamental: const Nota(
          nome: NomeNota.f,
          alteracao: AlteracaoNota.sustenido,
        ),
        qualidade: QualidadeAcorde.menor,
      ),
      'C5': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        qualidade: QualidadeAcorde.quinta,
      ),
      'C6': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        extensoes: {ExtensaoAcorde.sexta},
      ),
      'Cm6': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        qualidade: QualidadeAcorde.menor,
        extensoes: {ExtensaoAcorde.sexta},
      ),
      'C7': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        extensoes: {ExtensaoAcorde.setima},
      ),
      'Cm7': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        qualidade: QualidadeAcorde.menor,
        extensoes: {ExtensaoAcorde.setima},
      ),
      'Cmaj7': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        extensoes: {ExtensaoAcorde.setimaMaior},
      ),
      'C9': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        extensoes: {ExtensaoAcorde.setima, ExtensaoAcorde.nona},
      ),
      'Cm9': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        qualidade: QualidadeAcorde.menor,
        extensoes: {ExtensaoAcorde.setima, ExtensaoAcorde.nona},
      ),
      'C11': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        extensoes: {
          ExtensaoAcorde.setima,
          ExtensaoAcorde.nona,
          ExtensaoAcorde.decimaPrimeira,
        },
      ),
      'C13': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        extensoes: {
          ExtensaoAcorde.setima,
          ExtensaoAcorde.nona,
          ExtensaoAcorde.decimaPrimeira,
          ExtensaoAcorde.decimaTerceira,
        },
      ),
      'Cadd9': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        adicoes: {AdicaoAcorde.nona},
      ),
      'Cadd11': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        adicoes: {AdicaoAcorde.decimaPrimeira},
      ),
      'Csus2': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        suspensoes: {SuspensaoAcorde.segunda},
      ),
      'Csus4': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        suspensoes: {SuspensaoAcorde.quarta},
      ),
      'Cdim': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        qualidade: QualidadeAcorde.diminuto,
      ),
      'Caug': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        qualidade: QualidadeAcorde.aumentado,
      ),
      'Cm7(b5)': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        qualidade: QualidadeAcorde.menor,
        extensoes: {ExtensaoAcorde.setima},
        alteracoes: {AlteracaoAcorde(grau: 5, alteracao: AlteracaoNota.bemol)},
      ),
      'C7(b9)': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        extensoes: {ExtensaoAcorde.setima},
        alteracoes: {AlteracaoAcorde(grau: 9, alteracao: AlteracaoNota.bemol)},
      ),
      'C7(#9)': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        extensoes: {ExtensaoAcorde.setima},
        alteracoes: {
          AlteracaoAcorde(grau: 9, alteracao: AlteracaoNota.sustenido),
        },
      ),
      'C7(b9)(#5)': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        extensoes: {ExtensaoAcorde.setima},
        alteracoes: {
          AlteracaoAcorde(grau: 9, alteracao: AlteracaoNota.bemol),
          AlteracaoAcorde(grau: 5, alteracao: AlteracaoNota.sustenido),
        },
      ),
      'C7(#9)(b5)': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        extensoes: {ExtensaoAcorde.setima},
        alteracoes: {
          AlteracaoAcorde(grau: 9, alteracao: AlteracaoNota.sustenido),
          AlteracaoAcorde(grau: 5, alteracao: AlteracaoNota.bemol),
        },
      ),
      'C7(9)': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        extensoes: {ExtensaoAcorde.setima, ExtensaoAcorde.nona},
      ),
      'Cm7(9)': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        qualidade: QualidadeAcorde.menor,
        extensoes: {ExtensaoAcorde.setima, ExtensaoAcorde.nona},
      ),
      'C7M(9)': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        extensoes: {ExtensaoAcorde.setimaMaior, ExtensaoAcorde.nona},
      ),
      'C7(13)': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        extensoes: {ExtensaoAcorde.setima, ExtensaoAcorde.decimaTerceira},
      ),
      'G/B': Acorde(
        notaFundamental: const Nota(nome: NomeNota.g),
        baixo: const Nota(nome: NomeNota.b),
      ),
      'D/F#': Acorde(
        notaFundamental: const Nota(nome: NomeNota.d),
        baixo: const Nota(nome: NomeNota.f, alteracao: AlteracaoNota.sustenido),
      ),
      'C7/E': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        extensoes: {ExtensaoAcorde.setima},
        baixo: const Nota(nome: NomeNota.e),
      ),
      'Cadd9/G': Acorde(
        notaFundamental: const Nota(nome: NomeNota.c),
        adicoes: {AdicaoAcorde.nona},
        baixo: const Nota(nome: NomeNota.g),
      ),
    };

    for (final caso in casos.entries) {
      test('interpreta ${caso.key}', () {
        expect(_acordeInterpretado(parser, caso.key), caso.value);
      });
    }
  });

  group('ParserAcorde - aliases', () {
    final equivalencias = <String, String>{
      'C7M': 'Cmaj7',
      'CM7': 'Cmaj7',
      'CΔ7': 'Cmaj7',
      'C°': 'Cdim',
      'C+': 'Caug',
      'Cø': 'Cm7(b5)',
      'C4': 'Csus4',
    };

    for (final equivalencia in equivalencias.entries) {
      test('${equivalencia.key} equivale a ${equivalencia.value}', () {
        expect(
          _acordeInterpretado(parser, equivalencia.key),
          _acordeInterpretado(parser, equivalencia.value),
        );
      });
    }
  });

  group('ParserAcorde - conteúdo não interpretável', () {
    const textos = [
      'Cmaj9(#11)',
      'C6/9',
      'Calt',
      'Cno3',
      'texto evidentemente não reconhecível',
      'C7(b9)desconhecido',
      'C7(#11)',
      'C7(9)(desconhecido)',
    ];

    for (final texto in textos) {
      test('preserva $texto sem parsing parcial', () {
        final resultado = parser.interpretar(texto);

        expect(resultado, isA<AcordeNaoInterpretavel>());
        expect((resultado as AcordeNaoInterpretavel).textoOriginal, texto);
      });
    }
  });
}

Acorde _acordeInterpretado(ParserAcorde parser, String texto) {
  final resultado = parser.interpretar(texto);

  expect(resultado, isA<AcordeInterpretado>());
  return (resultado as AcordeInterpretado).acorde;
}
