import '../../aplicacao/portas/consulta_detalhe_lista_culto.dart';
import '../../dominio/chordpro/validador_schema_appcifras.dart';
import '../../dominio/entidades/versao_musica.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';
import '../../dominio/repositorios/repositorio_listas_culto.dart';
import '../../dominio/servicos/parser_documento_chordpro.dart';
import '../arquivos/armazenamento_arquivos_chordpro.dart';
import 'banco_biblioteca.dart';

class ConsultaDetalheListaCultoLocal implements ConsultaDetalheListaCulto {
  ConsultaDetalheListaCultoLocal({
    required RepositorioListasCulto repositorioListas,
    required BancoBiblioteca banco,
    required ArmazenamentoArquivosChordPro armazenamentoArquivos,
    required ParserDocumentoChordPro parserDocumento,
    ValidadorSchemaAppCifras validadorSchema = const ValidadorSchemaAppCifras(),
  }) : this._(
         repositorioListas,
         banco,
         armazenamentoArquivos,
         parserDocumento,
         validadorSchema,
       );

  ConsultaDetalheListaCultoLocal._(
    this._repositorioListas,
    this._banco,
    this._armazenamentoArquivos,
    this._parserDocumento,
    this._validadorSchema,
  );

  final RepositorioListasCulto _repositorioListas;
  final BancoBiblioteca _banco;
  final ArmazenamentoArquivosChordPro _armazenamentoArquivos;
  final ParserDocumentoChordPro _parserDocumento;
  final ValidadorSchemaAppCifras _validadorSchema;

  @override
  Future<List<ItemDetalheListaCulto>> carregar(idLista) async {
    final itens = await _repositorioListas.listarItens(idLista);
    if (itens.isEmpty) return const [];

    final idsMusicas = {for (final item in itens) item.idMusica.valor};
    final idsVersoes = {for (final item in itens) item.idVersaoMusica.valor};
    final consultaMusicas = _banco.listarMusicasPorIds(idsMusicas);
    final consultaVersoes = _banco.listarVersoesPorIds(idsVersoes);
    final consultaOrigens = _banco.listarOrigensSincronizadasVersoesPorIds(
      idsVersoes,
    );
    final musicas = await consultaMusicas;
    final indicesVersoes = await consultaVersoes;
    final origens = await consultaOrigens;
    final musicasPorId = {for (final musica in musicas) musica.id: musica};
    final idsVersoesSincronizadas = {
      for (final origem in origens) origem.idVersaoMusica,
    };
    final versoes = await Future.wait<VersaoMusica?>(
      indicesVersoes.map(
        (indice) => _tentarReconstruirVersao(
          indice,
          sincronizada: idsVersoesSincronizadas.contains(indice.id),
        ),
      ),
    );
    final versoesPorId = {
      for (final versao in versoes.whereType<VersaoMusica>())
        versao.id: versao,
    };

    return [
      for (final item in itens)
        if (musicasPorId[item.idMusica.valor] case final musica?)
          ItemDetalheListaCulto(
            item: item,
            titulo: musica.titulo,
            artista: musica.artista,
            versao: versoesPorId[item.idVersaoMusica],
          ),
    ];
  }

  Future<VersaoMusica?> _tentarReconstruirVersao(
    VersoesMusica indice, {
    required bool sincronizada,
  }) async {
    try {
      return await _reconstruirVersao(indice, sincronizada: sincronizada);
    } on ArquivoChordProInexistente {
      return null;
    } on SchemaAppCifrasNaoSuportado {
      return null;
    } on FormatException {
      return null;
    } on StateError {
      return null;
    }
  }

  Future<VersaoMusica> _reconstruirVersao(
    VersoesMusica indice, {
    required bool sincronizada,
  }) async {
    final id = IdVersaoMusica(indice.id);
    final idMusica = IdMusica(indice.idMusica);
    if (indice.arquivo != _armazenamentoArquivos.nomeArquivo(id)) {
      throw StateError('Índice de versão inconsistente para ${id.valor}.');
    }
    final conteudo = await _armazenamentoArquivos.obter(id);
    final documento = _parserDocumento.interpretar(conteudo);
    if (sincronizada) {
      _validadorSchema.validarParaVersaoSincronizada(documento);
    } else {
      _validadorSchema.validarParaIncorporacao(documento);
    }
    return VersaoMusica(
      id: id,
      idMusica: idMusica,
      nome: indice.nome,
      documento: documento,
      principal: indice.principal,
      arquivada: indice.arquivada,
    );
  }
}
