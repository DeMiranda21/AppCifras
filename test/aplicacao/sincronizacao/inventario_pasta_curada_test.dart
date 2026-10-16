import 'dart:convert';

import 'package:appcifras/aplicacao/sincronizacao/modelos_sincronizacao.dart';
import 'package:appcifras/aplicacao/sincronizacao/montar_inventario_pasta_curada.dart';
import 'package:appcifras/aplicacao/sincronizacao/validar_arquivo_pasta_curada.dart';
import 'package:appcifras/dominio/chordpro/validador_schema_appcifras.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final validar = ValidarArquivoPastaCurada();
  final montar = MontarInventarioPastaCurada(validador: validar);

  ArquivoSincronizacaoCandidato candidato({
    String localizador = 'musicas/musica.cho',
    String nome = 'musica.cho',
    String idMusica = 'musica-1',
    String idVersao = 'versao-1',
    String nomeVersao = 'Principal',
    String titulo = 'Título',
    String artista = 'Artista',
    bool? principal = true,
    int schema = 2,
    bool incluirIdVersao = true,
    String? conteudo,
  }) {
    final linhas = <String>[
      '{appcifras_schema:$schema}',
      '{appcifras_id:$idMusica}',
      if (incluirIdVersao) '{appcifras_version_id:$idVersao}',
      '{appcifras_version_name:$nomeVersao}',
      if (principal != null) '{appcifras_primary:$principal}',
      '{title:$titulo}',
      '{artist:$artista}',
      '{key:C}',
      '[C]Conteúdo',
    ];
    return ArquivoSincronizacaoCandidato(
      localizador: localizador,
      nomeLegivel: nome,
      bytes: utf8.encode(conteudo ?? linhas.join('\n')),
    );
  }

  Set<CodigoErroArquivoSincronizacao> errosArquivo(
    ResultadoValidacaoArquivoSincronizacao resultado,
  ) => (resultado as ArquivoSincronizacaoInvalido).erros
      .map((erro) => erro.codigo)
      .toSet();

  Set<CodigoErroGrupoSincronizacao> errosGrupo(
    GrupoMusicaSincronizacaoRejeitado grupo,
  ) => grupo.erros.map((erro) => erro.codigo).toSet();

  group('validação individual de arquivo sincronizável', () {
    test('aceita arquivo schema 2 válido e extrai os metadados', () {
      final resultado =
          validar.executar(candidato()) as ArquivoSincronizacaoValidado;

      expect(resultado.idMusica.valor, 'musica-1');
      expect(resultado.idVersaoMusica.valor, 'versao-1');
      expect(resultado.nomeVersao, 'Principal');
      expect(resultado.principalDeclarada, isTrue);
      expect(resultado.titulo, 'Título');
      expect(resultado.artista, 'Artista');
      expect(resultado.hashSha256, hasLength(64));
      expect(resultado.documento.conteudoOriginal, contains('[C]Conteúdo'));
    });

    test('ausência de appcifras_primary equivale a false', () {
      final resultado = validar.executar(
        candidato(principal: null),
      ) as ArquivoSincronizacaoValidado;

      expect(resultado.principalDeclarada, isFalse);
    });

    test('rejeita falta de appcifras_version_id', () {
      final resultado = validar.executar(candidato(incluirIdVersao: false));

      expect(
        errosArquivo(resultado),
        contains(CodigoErroArquivoSincronizacao.idVersaoAusenteOuInvalido),
      );
    });

    test('rejeita schema 1 para sincronização sem quebrar leitura local', () {
      final candidatoSchema1 = candidato(schema: 1);
      final resultado = validar.executar(candidatoSchema1);
      final documento = ParserDocumentoChordPro().interpretar(
        utf8.decode(candidatoSchema1.bytes),
      );

      expect(
        errosArquivo(resultado),
        contains(CodigoErroArquivoSincronizacao.schemaAusenteOuInvalido),
      );
      expect(
        () =>
            const ValidadorSchemaAppCifras().validarParaIncorporacao(documento),
        returnsNormally,
      );
    });

    test('rejeita nome de versão vazio depois de trim', () {
      final resultado = validar.executar(candidato(nomeVersao: '   '));

      expect(
        errosArquivo(resultado),
        contains(CodigoErroArquivoSincronizacao.nomeVersaoInvalido),
      );
    });

    test('rejeita appcifras_primary que não seja booleano', () {
      final original = candidato();
      final texto = utf8
          .decode(original.bytes)
          .replaceFirst('{appcifras_primary:true}', '{appcifras_primary:sim}');

      final resultado = validar.executar(
        ArquivoSincronizacaoCandidato(
          localizador: original.localizador,
          nomeLegivel: original.nomeLegivel,
          bytes: utf8.encode(texto),
        ),
      );

      expect(
        errosArquivo(resultado),
        contains(CodigoErroArquivoSincronizacao.principalInvalida),
      );
    });

    test('rejeita diretiva de identidade duplicada', () {
      final original = candidato();
      final texto = utf8
          .decode(original.bytes)
          .replaceFirst(
            '{appcifras_version_id:versao-1}',
            '{appcifras_version_id:versao-1}\n'
                '{appcifras_version_id:versao-2}',
          );

      final resultado = validar.executar(
        ArquivoSincronizacaoCandidato(
          localizador: original.localizador,
          nomeLegivel: original.nomeLegivel,
          bytes: utf8.encode(texto),
        ),
      );

      expect(
        errosArquivo(resultado),
        contains(CodigoErroArquivoSincronizacao.idVersaoAusenteOuInvalido),
      );
    });

    test('calcula o mesmo SHA-256 para os mesmos bytes', () {
      final primeiro =
          validar.executar(candidato()) as ArquivoSincronizacaoValidado;
      final segundo = validar.executar(
        candidato(localizador: 'outro/local.cho', nome: 'outro.cho'),
      ) as ArquivoSincronizacaoValidado;

      expect(segundo.hashSha256, primeiro.hashSha256);
    });

    test('detecta alteração de bytes pelo SHA-256', () {
      final primeiro =
          validar.executar(candidato()) as ArquivoSincronizacaoValidado;
      final alterado = candidato();
      final segundo = validar.executar(
        ArquivoSincronizacaoCandidato(
          localizador: alterado.localizador,
          nomeLegivel: alterado.nomeLegivel,
          bytes: [...alterado.bytes, 10],
        ),
      ) as ArquivoSincronizacaoValidado;

      expect(segundo.hashSha256, isNot(primeiro.hashSha256));
    });

    test('caminho e nome não alteram as identidades internas', () {
      final primeiro =
          validar.executar(candidato()) as ArquivoSincronizacaoValidado;
      final segundo = validar.executar(
        candidato(localizador: 'renomeada/cifra.cho', nome: 'cifra.cho'),
      ) as ArquivoSincronizacaoValidado;

      expect(segundo.idMusica, primeiro.idMusica);
      expect(segundo.idVersaoMusica, primeiro.idVersaoMusica);
    });

    test(
      'mantém IdMusica e IdVersaoMusica como tipos conceitualmente distintos',
      () {
        final resultado = validar.executar(
          candidato(idMusica: 'mesmo-valor', idVersao: 'mesmo-valor'),
        ) as ArquivoSincronizacaoValidado;

        expect(resultado.idMusica.valor, resultado.idVersaoMusica.valor);
        expect(
          resultado.idMusica.runtimeType,
          isNot(resultado.idVersaoMusica.runtimeType),
        );
      },
    );

    test(
      'rejeita UTF-8 inválido, extensão e diretivas gerenciadas ambíguas',
      () {
        final utf8Invalido = validar.executar(
          ArquivoSincronizacaoCandidato(
            localizador: 'invalido.txt',
            nomeLegivel: 'invalido.txt',
            bytes: const [0xC3, 0x28],
          ),
        );
        final duplicado = candidato();
        final texto = utf8
            .decode(duplicado.bytes)
            .replaceFirst(
              '{appcifras_primary:true}',
              '{appcifras_primary:true}\n{appcifras_primary:false}',
            );
        final principalDuplicada = validar.executar(
          ArquivoSincronizacaoCandidato(
            localizador: duplicado.localizador,
            nomeLegivel: duplicado.nomeLegivel,
            bytes: utf8.encode(texto),
          ),
        );

        expect(
          errosArquivo(utf8Invalido),
          containsAll({
            CodigoErroArquivoSincronizacao.extensaoInvalida,
            CodigoErroArquivoSincronizacao.utf8Invalido,
          }),
        );
        expect(
          errosArquivo(principalDuplicada),
          contains(CodigoErroArquivoSincronizacao.principalInvalida),
        );
      },
    );
  });

  group('inventário da pasta curada', () {
    test('aceita duas versões da mesma Música com IDs diferentes', () {
      final inventario = montar.executar([
        candidato(idVersao: 'v-1', principal: true),
        candidato(
          localizador: 'musicas/alternativa.cho',
          nome: 'alternativa.cho',
          idVersao: 'v-2',
          nomeVersao: 'Alternativa',
          principal: null,
        ),
      ]);

      expect(inventario.arquivosValidos, hasLength(2));
      expect(inventario.gruposValidos, hasLength(1));
      expect(
        inventario.gruposValidos.single.arquivos.map(
          (arquivo) => arquivo.idVersaoMusica.valor,
        ),
        ['v-1', 'v-2'],
      );
      expect(inventario.gruposRejeitados, isEmpty);
    });

    test('rejeita mesmo IdVersaoMusica em dois arquivos da mesma Música', () {
      final inventario = montar.executar([
        candidato(localizador: 'a.cho', nome: 'a.cho'),
        candidato(localizador: 'b.cho', nome: 'b.cho'),
      ]);

      expect(inventario.gruposValidos, isEmpty);
      expect(
        errosGrupo(inventario.gruposRejeitados.single),
        contains(CodigoErroGrupoSincronizacao.idVersaoDuplicado),
      );
    });

    test('rejeita IdVersaoMusica associado a Músicas diferentes', () {
      final inventario = montar.executar([
        candidato(localizador: 'a.cho', nome: 'a.cho', idMusica: 'musica-a'),
        candidato(localizador: 'b.cho', nome: 'b.cho', idMusica: 'musica-b'),
      ]);

      expect(inventario.gruposValidos, isEmpty);
      expect(inventario.gruposRejeitados, hasLength(2));
      expect(
        inventario.gruposRejeitados.every(
          (grupo) => errosGrupo(grupo).contains(
            CodigoErroGrupoSincronizacao.idVersaoAssociadoAMusicasDiferentes,
          ),
        ),
        isTrue,
      );
    });

    test('rejeita grupo com título divergente', () {
      final inventario = montar.executar([
        candidato(localizador: 'a.cho', nome: 'a.cho', idVersao: 'v-a'),
        candidato(
          localizador: 'b.cho',
          nome: 'b.cho',
          idVersao: 'v-b',
          titulo: 'Outro título',
          principal: null,
        ),
      ]);

      expect(
        errosGrupo(inventario.gruposRejeitados.single),
        contains(CodigoErroGrupoSincronizacao.tituloMusicaDivergente),
      );
    });

    test('rejeita grupo com artista divergente', () {
      final inventario = montar.executar([
        candidato(localizador: 'a.cho', nome: 'a.cho', idVersao: 'v-a'),
        candidato(
          localizador: 'b.cho',
          nome: 'b.cho',
          idVersao: 'v-b',
          artista: 'Outro artista',
          principal: null,
        ),
      ]);

      expect(
        errosGrupo(inventario.gruposRejeitados.single),
        contains(CodigoErroGrupoSincronizacao.artistaMusicaDivergente),
      );
    });

    test('normaliza somente trim ao comparar título e artista', () {
      final inventario = montar.executar([
        candidato(localizador: 'a.cho', nome: 'a.cho', idVersao: 'v-a'),
        candidato(
          localizador: 'b.cho',
          nome: 'b.cho',
          idVersao: 'v-b',
          titulo: '  Título  ',
          artista: '  Artista  ',
          principal: null,
        ),
      ]);

      expect(inventario.gruposValidos, hasLength(1));
      expect(inventario.gruposRejeitados, isEmpty);
    });

    test('distingue grupo externo válido e apto para criação nova', () {
      final inventario = montar.executar([candidato()]);
      final grupo = inventario.gruposValidos.single;

      expect(grupo.avaliacaoCriacao.apta, isTrue);
      expect(grupo.avaliacaoCriacao.principalInicial?.valor, 'versao-1');
    });

    test(
      'grupo sem principal continua externo válido, mas inapto para criar',
      () {
        final inventario = montar.executar([candidato(principal: null)]);
        final grupo = inventario.gruposValidos.single;

        expect(grupo.avaliacaoCriacao.apta, isFalse);
        expect(grupo.avaliacaoCriacao.quantidadePrincipais, 0);
        expect(
          grupo.avaliacaoCriacao.inaptidao,
          CodigoInaptidaoCriacaoMusicaNova.quantidadePrincipalInvalida,
        );
      },
    );

    test('grupo com mais de uma principal fica inapto para criar', () {
      final inventario = montar.executar([
        candidato(localizador: 'a.cho', nome: 'a.cho', idVersao: 'v-a'),
        candidato(localizador: 'b.cho', nome: 'b.cho', idVersao: 'v-b'),
      ]);
      final grupo = inventario.gruposValidos.single;

      expect(grupo.avaliacaoCriacao.apta, isFalse);
      expect(grupo.avaliacaoCriacao.quantidadePrincipais, 2);
    });

    test('arquivo inválido não impede grupo independente válido', () {
      final inventario = montar.executar([
        candidato(incluirIdVersao: false),
        candidato(
          localizador: 'outra/valida.cho',
          nome: 'valida.cho',
          idMusica: 'musica-2',
          idVersao: 'versao-2',
        ),
      ]);

      expect(inventario.arquivosInvalidos, hasLength(1));
      expect(inventario.gruposValidos, hasLength(1));
      expect(inventario.gruposValidos.single.idMusica.valor, 'musica-2');
    });

    test('ordem de entrada não altera o resultado lógico', () {
      final a = candidato(
        localizador: 'z.cho',
        nome: 'z.cho',
        idMusica: 'musica-z',
        idVersao: 'versao-z',
      );
      final b = candidato(
        localizador: 'a.cho',
        nome: 'a.cho',
        idMusica: 'musica-a',
        idVersao: 'versao-a',
      );

      final direto = montar.executar([a, b]);
      final inverso = montar.executar([b, a]);

      expect(
        direto.gruposValidos.map((grupo) => grupo.idMusica.valor),
        inverso.gruposValidos.map((grupo) => grupo.idMusica.valor),
      );
      expect(
        direto.arquivosValidos.map((arquivo) => arquivo.candidato.localizador),
        inverso.arquivosValidos.map((arquivo) => arquivo.candidato.localizador),
      );
    });
  });
}
