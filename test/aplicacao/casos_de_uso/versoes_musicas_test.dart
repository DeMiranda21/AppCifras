import 'package:appcifras/aplicacao/casos_de_uso/versoes_musicas.dart';
import 'package:appcifras/aplicacao/portas/gerador_id_versao_musica.dart';
import 'package:appcifras/dominio/entidades/versao_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_musica.dart';
import 'package:appcifras/dominio/objetos_de_valor/id_versao_musica.dart';
import 'package:appcifras/dominio/repositorios/repositorio_versoes_musicas.dart';
import 'package:appcifras/dominio/servicos/parser_documento_chordpro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = ParserDocumentoChordPro();
  final idMusica = IdMusica('santo-pra-sempre');

  VersaoMusica versao({
    required String id,
    required String nome,
    required String tom,
    bool principal = false,
    bool arquivada = false,
  }) => VersaoMusica(
    id: IdVersaoMusica(id),
    idMusica: idMusica,
    nome: nome,
    documento: parser.interpretar(
      '{appcifras_schema: 1}\n'
      '{appcifras_id: santo-pra-sempre}\n'
      '{title: Santo Pra Sempre}\n'
      '{artist: Bethel Music}\n'
      '{key: $tom}\n'
      '{comment: manter}\n'
      '[$tom]Santo Pra Sempre',
    ),
    principal: principal,
    arquivada: arquivada,
  );

  test('lista somente versões ativas da música', () async {
    final principal = versao(
      id: 'principal',
      nome: 'Principal',
      tom: 'C',
      principal: true,
    );
    final ativa = versao(id: 'igreja-a', nome: 'Igreja A', tom: 'D');
    final arquivada = versao(
      id: 'antiga',
      nome: 'Antiga',
      tom: 'E',
      arquivada: true,
    );
    final repositorio = _RepositorioVersoesFake([principal, ativa, arquivada]);

    final resultado = await ListarVersoesMusica(repositorio).executar(idMusica);

    expect(resultado, [principal, ativa]);
    expect(resultado.singleWhere((versao) => versao.principal), principal);
  });

  test('cria versão independente preservando o documento da origem', () async {
    final origem = versao(
      id: 'principal',
      nome: 'Principal',
      tom: 'C',
      principal: true,
    );
    final repositorio = _RepositorioVersoesFake([origem]);
    final criar = CriarVersaoMusica(
      repositorio: repositorio,
      geradorId: _GeradorIdVersaoFake(IdVersaoMusica('simplificada')),
    );

    final criada = await criar.executar(origem: origem, nome: ' Simplificada ');

    expect(criada.id, IdVersaoMusica('simplificada'));
    expect(criada.id, isNot(origem.id));
    expect(criada.idMusica, origem.idMusica);
    expect(criada.nome, 'Simplificada');
    expect(
      criada.documento.conteudoOriginal,
      origem.documento.conteudoOriginal,
    );
    expect(criada.tomOriginal, origem.tomOriginal);
    expect(criada.principal, isFalse);
    expect(criada.arquivada, isFalse);
    expect(repositorio.versoes, [origem, criada]);
  });

  test('rejeita nome de versão vazio depois do trim', () async {
    final origem = versao(
      id: 'principal',
      nome: 'Principal',
      tom: 'C',
      principal: true,
    );
    final repositorio = _RepositorioVersoesFake([origem]);
    final criar = CriarVersaoMusica(
      repositorio: repositorio,
      geradorId: _GeradorIdVersaoFake(IdVersaoMusica('nova')),
    );

    await expectLater(
      criar.executar(origem: origem, nome: '   '),
      throwsA(isA<ArgumentError>()),
    );
    expect(repositorio.versoes, [origem]);
  });
}

class _RepositorioVersoesFake implements RepositorioVersoesMusicas {
  _RepositorioVersoesFake(Iterable<VersaoMusica> versoes)
    : versoes = [...versoes];

  final List<VersaoMusica> versoes;

  @override
  Future<List<VersaoMusica>> listarPorMusica(IdMusica idMusica) async =>
      versoes.where((versao) => versao.idMusica == idMusica).toList();

  @override
  Future<VersaoMusica?> obterPrincipalPorMusica(IdMusica idMusica) async =>
      (await listarPorMusica(idMusica))
          .cast<VersaoMusica?>()
          .firstWhere((versao) => versao!.principal, orElse: () => null);

  @override
  Future<VersaoMusica?> obterVersaoPorId(IdVersaoMusica id) async => versoes
      .cast<VersaoMusica?>()
      .firstWhere((versao) => versao!.id == id, orElse: () => null);

  @override
  Future<void> salvarVersao(VersaoMusica versao) async {
    versoes.add(versao);
  }
}

class _GeradorIdVersaoFake implements GeradorIdVersaoMusica {
  const _GeradorIdVersaoFake(this._id);

  final IdVersaoMusica _id;

  @override
  IdVersaoMusica gerar() => _id;
}
