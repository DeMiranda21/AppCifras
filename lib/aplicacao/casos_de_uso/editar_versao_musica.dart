import '../../dominio/chordpro/validador_schema_appcifras.dart';
import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/entidades/musica.dart';
import '../../dominio/entidades/versao_musica.dart';
import '../../dominio/erros/versao_musica_nao_encontrada.dart';
import '../../dominio/repositorios/repositorio_musicas.dart';
import '../../dominio/repositorios/repositorio_versoes_musicas.dart';
import '../../dominio/servicos/parser_documento_chordpro.dart';
import '../entrada/conteudo_chordpro_editavel.dart';
import '../entrada/rascunho_documento_chordpro.dart';
import '../portas/repositorio_tom_execucao.dart';
import '../portas/repositorio_sincronizacao.dart';
import '../versoes/politica_edicao_versao.dart';
import 'ciclo_vida_versoes_musicas.dart';
import 'versoes_musicas.dart';

class EstadoSalvamentoEdicaoVersao {
  VersaoMusica? _versaoPersistida;

  VersaoMusica? get versaoPersistida => _versaoPersistida;
}

class EditarVersaoMusica {
  const EditarVersaoMusica({
    required this.repositorio,
    required this.repositorioMusicas,
    required this.criarVersao,
    required this.avaliarPolitica,
    this.repositorioTom,
    this.repositorioOrigens,
  });
  final RepositorioVersoesMusicas repositorio;
  final RepositorioMusicas repositorioMusicas;
  final CriarVersaoMusica criarVersao;
  final AvaliarPoliticaEdicaoVersao avaliarPolitica;
  final RepositorioTomExecucao? repositorioTom;
  final RepositorioOrigensSincronizadas? repositorioOrigens;

  VersaoMusica preparar(
    VersaoMusica origem,
    String conteudo,
    RevisaoMetadadosChordPro revisao,
  ) {
    final parser = ParserDocumentoChordPro();
    final rascunho = RascunhoDocumentoChordPro.criar(
      conteudoChordPro: ConteudoChordProEditavel.recomporCanonico(
        conteudoCanonicoAnterior: origem.documento.conteudoOriginal,
        conteudoEditavel: conteudo,
      ),
      parserDocumento: parser,
    ).comRevisao(revisao);
    return VersaoMusica(
      id: origem.id,
      idMusica: origem.idMusica,
      nome: origem.nome,
      documento: parser.interpretar(rascunho.produzirConteudoFinal()),
      principal: origem.principal,
      arquivada: origem.arquivada,
    );
  }

  bool conteudoMusicalAlterado(VersaoMusica origem, VersaoMusica editada) {
    String musical(VersaoMusica v) => preparar(
      v,
      ConteudoChordProEditavel.extrair(v.documento.conteudoOriginal),
      const RevisaoMetadadosChordPro(titulo: '_', artista: '_'),
    ).documento.conteudoOriginal;
    return musical(origem) != musical(editada);
  }

  Future<VersaoMusica> executar({
    required VersaoMusica origem,
    required VersaoMusica editada,
    String? nomeNovaVersao,
    AcaoEdicaoConteudoVersao? acaoConteudo,
    EstadoSalvamentoEdicaoVersao? estadoSalvamento,
  }) async {
    final atual = await repositorio.obterVersaoPorId(origem.id);
    if (atual == null) throw VersaoMusicaNaoEncontrada(origem.id);
    if (editada.id != origem.id || editada.idMusica != origem.idMusica) {
      throw ArgumentError('A edição deve preservar a identidade da origem.');
    }
    const validadorSchema = ValidadorSchemaAppCifras();
    final schemas = editada.documento.elementos
        .whereType<DiretivaSchemaAppCifras>();
    if (schemas.length == 1 && schemas.single.versao == 2) {
      validadorSchema.validarParaVersaoSincronizada(editada.documento);
    } else {
      validadorSchema.validarParaIncorporacao(editada.documento);
    }
    final musica = await repositorioMusicas.obterPorId(origem.idMusica);
    if (musica == null) throw StateError('Música não encontrada.');
    final parser = ParserDocumentoChordPro();
    final catalogo = RascunhoDocumentoChordPro.criar(
      conteudoChordPro: editada.documento.conteudoOriginal,
      parserDocumento: parser,
    );

    catalogo.produzirConteudoFinal();
    final titulo = catalogo.tituloDetectado!;
    final artista = catalogo.artistaDetectado!;
    final versaoJaPersistida = estadoSalvamento?.versaoPersistida;
    var resultado = versaoJaPersistida ?? atual;
    if (versaoJaPersistida != null) {
      final revisada = VersaoMusica(
        id: versaoJaPersistida.id,
        idMusica: versaoJaPersistida.idMusica,
        nome: versaoJaPersistida.nome,
        documento: editada.documento,
        principal: versaoJaPersistida.principal,
        arquivada: versaoJaPersistida.arquivada,
      );
      if (conteudoMusicalAlterado(versaoJaPersistida, revisada)) {
        await AtualizarConteudoVersaoMusica(
          repositorio,
          repositorioTom: repositorioTom,
          repositorioOrigens: repositorioOrigens,
        ).executar(revisada);
      }
      resultado =
          await repositorio.obterVersaoPorId(versaoJaPersistida.id) ?? revisada;
      estadoSalvamento?._versaoPersistida = resultado;
    } else if (conteudoMusicalAlterado(origem, editada)) {
      final decisao = await avaliarPolitica.executar(atual);
      final acao =
          acaoConteudo ??
          (decisao.exigeEscolha ? null : decisao.acaoAutomatica!);
      if (acao == null) {
        throw ArgumentError(
          'Escolha sobrescrever a versão principal ou criar uma nova versão.',
        );
      }
      if (!decisao.permite(acao)) {
        throw StateError('A ação escolhida não é permitida para esta versão.');
      }
      if (acao == AcaoEdicaoConteudoVersao.criarNovaVersao) {
        if (nomeNovaVersao == null || nomeNovaVersao.trim().isEmpty) {
          throw ArgumentError('Informe o nome da nova versão.');
        }
        resultado = await criarVersao.executar(
          origem: editada,
          nome: nomeNovaVersao,
        );
      } else {
        await AtualizarConteudoVersaoMusica(
          repositorio,
          repositorioTom: repositorioTom,
          repositorioOrigens: repositorioOrigens,
        ).executar(editada);
        resultado = editada;
      }
      estadoSalvamento?._versaoPersistida = resultado;
    }
    // A revisão de catálogo conserva o conteúdo musical da principal.
    if (titulo != musica.titulo || artista != musica.artista) {
      final principal = preparar(
        musica.versaoPrincipal,
        ConteudoChordProEditavel.extrair(musica.documento.conteudoOriginal),
        RevisaoMetadadosChordPro(titulo: titulo, artista: artista),
      );
      await repositorioMusicas.atualizar(
        Musica(
          id: musica.id,
          titulo: titulo,
          artista: artista,
          versaoPrincipal: principal,
        ),
      );
    }
    return (await repositorio.obterVersaoPorId(resultado.id))!;
  }
}
