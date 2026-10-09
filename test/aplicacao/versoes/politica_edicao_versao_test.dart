import 'package:appcifras/aplicacao/versoes/politica_edicao_versao.dart';
import 'package:appcifras/dominio/entidades/versao_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserDocumentoChordPro();

  VersaoMusica versao({required bool principal}) => VersaoMusica(
    id: IdVersaoMusica(principal ? 'principal' : 'alternativa'),
    idMusica: IdMusica('musica'),
    nome: 'Nome',
    documento: parser.interpretar(
      '{title: T}\n{artist: A}\n{key: C}\n[C]Letra',
    ),
    principal: principal,
    arquivada: false,
  );

  group('PoliticaEdicaoVersao', () {
    const politica = PoliticaEdicaoVersao();

    test('principal exige nova versão para alterar conteúdo', () {
      final decisao = politica.decidir(
        versao: versao(principal: true),
        usadaEmLista: false,
      );
      expect(decisao.podeSobrescreverConteudo, isFalse);
      expect(decisao.deveCriarNovaVersao, isTrue);
      expect(decisao.podeRenomear, isTrue);
    });

    test('alternativa não usada pode sobrescrever conteúdo', () {
      final decisao = politica.decidir(
        versao: versao(principal: false),
        usadaEmLista: false,
      );
      expect(decisao.podeSobrescreverConteudo, isTrue);
      expect(decisao.deveCriarNovaVersao, isFalse);
      expect(decisao.podeRenomear, isTrue);
    });

    test('alternativa usada exige nova versão para alterar conteúdo', () {
      final decisao = politica.decidir(
        versao: versao(principal: false),
        usadaEmLista: true,
      );
      expect(decisao.podeSobrescreverConteudo, isFalse);
      expect(decisao.deveCriarNovaVersao, isTrue);
      expect(decisao.podeRenomear, isTrue);
    });
  });
}
