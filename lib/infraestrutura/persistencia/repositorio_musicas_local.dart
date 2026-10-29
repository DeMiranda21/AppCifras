import '../../dominio/chordpro/documento_chordpro.dart';
import '../../dominio/chordpro/validador_schema_appcifras.dart';
import '../../dominio/entidades/musica.dart';
import '../../dominio/entidades/versao_musica.dart';
import '../../dominio/erros/id_musica_ja_existente.dart';
import '../../dominio/erros/musica_em_uso_em_lista.dart';
import '../../dominio/erros/musica_nao_encontrada.dart';
import '../../dominio/erros/operacao_versao_musica_nao_permitida.dart';
import '../../dominio/erros/versao_musica_nao_encontrada.dart';
import '../../dominio/objetos_de_valor/id_musica.dart';
import '../../dominio/objetos_de_valor/id_versao_musica.dart';
import '../../dominio/repositorios/repositorio_musicas.dart';
import '../../dominio/repositorios/repositorio_versoes_musicas.dart';
import '../../dominio/servicos/parser_documento_chordpro.dart';
import '../../aplicacao/entrada/rascunho_documento_chordpro.dart';
import '../../aplicacao/biblioteca/item_biblioteca.dart';
import '../../aplicacao/portas/aplicador_grupo_sincronizacao.dart';
import '../../aplicacao/diagnostico/medicao_desempenho_biblioteca.dart';
import '../../aplicacao/diagnostico/medicao_desempenho_visualizacao.dart';
import '../../aplicacao/pesquisa/normalizacao_pesquisa.dart';
import '../arquivos/armazenamento_arquivos_chordpro.dart';
import '../arquivos/codificador_chordpro_gerenciado.dart';
import 'banco_biblioteca.dart';

class EstadoPersistenciaMusicaInconsistente implements Exception {
  const EstadoPersistenciaMusicaInconsistente(this.id);

  final IdMusica id;
}

class RepositorioMusicasLocal
    implements
        RepositorioMusicas,
        RepositorioVersoesMusicas,
        RepositorioConsultaBiblioteca,
        AplicadorGrupoSincronizacao {
  RepositorioMusicasLocal({
    required this._banco,
    required this._armazenamentoArquivos,
    ParserDocumentoChordPro? parserDocumento,
    this._codificador = const CodificadorChordProGerenciado(),
    this._validadorSchema = const ValidadorSchemaAppCifras(),
  }) : _parserDocumento = parserDocumento ?? ParserDocumentoChordPro();

  final BancoBiblioteca _banco;
  final ArmazenamentoArquivosChordPro _armazenamentoArquivos;
  final ParserDocumentoChordPro _parserDocumento;
  final CodificadorChordProGerenciado _codificador;
  final ValidadorSchemaAppCifras _validadorSchema;

  @override
  Future<void> aplicar(PlanoAplicacaoGrupoSincronizacao plano) async {
    final indice = await _banco.obterPorId(plano.idMusica.valor);
    if ((indice == null) != plano.criarMusica) {
      throw StateError('O estado local mudou durante a sincronização.');
    }

    final registrosExistentes = plano.criarMusica
        ? const <VersoesMusica>[]
        : await _banco.listarVersoesMusica(plano.idMusica.valor);
    final porIdExistente = {
      for (final registro in registrosExistentes) registro.id: registro,
    };
    for (final versao in plano.versoesNovas) {
      if (await _banco.obterVersaoPorId(versao.id.valor) != null ||
          await _armazenamentoArquivos.existe(versao.id)) {
        throw StateError('A versão ${versao.id.valor} já existe.');
      }
    }
    for (final versao in plano.versoesExistentes) {
      final registro = porIdExistente[versao.id.valor];
      if (registro == null) {
        throw StateError('A versão ${versao.id.valor} deixou de existir.');
      }
      _validarNomeArquivo(versao.id, registro.arquivo, plano.idMusica);
    }

    final catalogoMudou =
        indice != null &&
        (indice.titulo != plano.titulo || indice.artista != plano.artista);
    final atualizacoesSolicitadas = {
      for (final versao in plano.versoesExistentes)
        versao.id: versao.conteudoChordProAtualizado,
    };
    final anteriores = <IdVersaoMusica, String>{};
    final desejados = <IdVersaoMusica, String>{};
    for (final registro in registrosExistentes) {
      final id = IdVersaoMusica(registro.id);
      final atualizacao = atualizacoesSolicitadas[id];
      if (!catalogoMudou && atualizacao == null) continue;
      final anterior = await _armazenamentoArquivos.obter(id);
      anteriores[id] = anterior;
      desejados[id] =
          atualizacao ??
          _revisarMetadadosCatalogo(
            anterior,
            titulo: plano.titulo,
            artista: plano.artista,
          );
    }
    final conteudoPrincipalParaIndice = plano.criarMusica
        ? plano.versoesNovas
              .singleWhere((versao) => versao.principal)
              .conteudoChordPro
        : desejados[IdVersaoMusica(
            registrosExistentes.singleWhere((versao) => versao.principal).id,
          )];
    final idVersaoPrincipal = plano.criarMusica
        ? plano.versoesNovas.singleWhere((versao) => versao.principal).id.valor
        : registrosExistentes.singleWhere((versao) => versao.principal).id;
    final indicePesquisaAtualizado = conteudoPrincipalParaIndice == null
        ? null
        : _criarRegistroIndicePesquisa(
            idMusica: plano.idMusica.valor,
            idVersaoMusica: idVersaoPrincipal,
            titulo: plano.titulo,
            artista: plano.artista,
            conteudoVisivel: ExtratorConteudoVisivelChordPro.extrair(
              _parserDocumento.interpretar(conteudoPrincipalParaIndice),
            ),
          );

    final criadas = <IdVersaoMusica>[];
    final substituidas = <IdVersaoMusica>[];
    try {
      for (final versao in plano.versoesNovas) {
        await _armazenamentoArquivos.salvar(versao.id, versao.conteudoChordPro);
        criadas.add(versao.id);
      }
      for (final entrada in desejados.entries) {
        if (entrada.value == anteriores[entrada.key]) continue;
        await _armazenamentoArquivos.substituir(entrada.key, entrada.value);
        substituidas.add(entrada.key);
      }

      await _banco.executarEmTransacao(() async {
        if (plano.criarMusica) {
          final principal = plano.versoesNovas.singleWhere(
            (versao) => versao.principal,
          );
          await _banco.inserir(
            id: plano.idMusica.valor,
            titulo: plano.titulo,
            artista: plano.artista,
            arquivo: _armazenamentoArquivos.nomeArquivo(principal.id),
          );
        } else if (catalogoMudou) {
          final alteradas = await _banco.atualizar(
            id: plano.idMusica.valor,
            titulo: plano.titulo,
            artista: plano.artista,
          );
          if (alteradas != 1) throw MusicaNaoEncontrada(plano.idMusica);
        }

        for (final versao in plano.versoesNovas) {
          await _banco.inserirVersaoMusica(
            id: versao.id.valor,
            idMusica: plano.idMusica.valor,
            nome: versao.nome,
            arquivo: _armazenamentoArquivos.nomeArquivo(versao.id),
            principal: versao.principal,
            arquivada: false,
          );
          await _banco.salvarOrigemSincronizadaVersao(
            idVersaoMusica: versao.id.valor,
            localizadorExterno: versao.localizadorExterno,
            hashSha256: versao.hashSha256,
            presente: true,
          );
        }
        for (final versao in plano.versoesExistentes) {
          await _banco.renomearVersaoMusica(versao.id.valor, versao.nome);
          await _banco.salvarOrigemSincronizadaVersao(
            idVersaoMusica: versao.id.valor,
            localizadorExterno: versao.localizadorExterno,
            hashSha256: versao.hashSha256,
            presente: true,
          );
        }
        if (indicePesquisaAtualizado != null) {
          await _banco.salvarIndicePesquisaMusica(
            idMusica: indicePesquisaAtualizado.idMusica,
            idVersaoMusica: indicePesquisaAtualizado.idVersaoMusica,
            conteudoVisivel: indicePesquisaAtualizado.conteudoVisivel,
            tituloNormalizado: indicePesquisaAtualizado.tituloNormalizado,
            textoNormalizado: indicePesquisaAtualizado.textoNormalizado,
          );
        }
      });
    } catch (erro, pilha) {
      try {
        for (final id in substituidas.reversed) {
          await _armazenamentoArquivos.substituir(id, anteriores[id]!);
        }
        for (final id in criadas.reversed) {
          if (await _armazenamentoArquivos.existe(id)) {
            await _armazenamentoArquivos.excluir(id);
          }
        }
      } catch (_) {
        throw EstadoPersistenciaMusicaInconsistente(plano.idMusica);
      }
      Error.throwWithStackTrace(erro, pilha);
    }
  }

  @override
  Future<void> salvar(Musica musica) async {
    final versao = musica.versaoPrincipal;
    if (await _banco.obterPorId(musica.id.valor) != null ||
        await _armazenamentoArquivos.existe(versao.id)) {
      throw IdMusicaJaExistente(musica.id);
    }

    final conteudo = _codificador.codificar(musica);
    await _armazenamentoArquivos.salvar(versao.id, conteudo);
    try {
      await _banco.inserir(
        id: musica.id.valor,
        titulo: musica.titulo,
        artista: musica.artista,
        arquivo: _armazenamentoArquivos.nomeArquivo(versao.id),
      );
      await _banco.inserirVersaoMusica(
        id: versao.id.valor,
        idMusica: musica.id.valor,
        nome: versao.nome,
        arquivo: _armazenamentoArquivos.nomeArquivo(versao.id),
        principal: true,
        arquivada: false,
      );
      await _salvarIndicePesquisa(
        musica.versaoPrincipal,
        titulo: musica.titulo,
        artista: musica.artista,
      );
    } catch (erro, pilha) {
      try {
        await _banco.excluirPorId(musica.id.valor);
        await _armazenamentoArquivos.excluir(versao.id);
      } catch (_) {
        throw EstadoPersistenciaMusicaInconsistente(musica.id);
      }
      Error.throwWithStackTrace(erro, pilha);
    }
  }

  @override
  Future<void> atualizar(Musica musica) async {
    final indice = await _banco.obterPorId(musica.id.valor);
    if (indice == null) {
      throw MusicaNaoEncontrada(musica.id);
    }
    final versaoPersistida = await _banco.obterVersaoPrincipalPorMusica(
      musica.id.valor,
    );
    if (versaoPersistida == null) {
      throw EstadoPersistenciaMusicaInconsistente(musica.id);
    }
    final versao = musica.versaoPrincipal;
    if (versao.id.valor != versaoPersistida.id) {
      throw ArgumentError(
        'A atualização atual opera somente a versão principal.',
      );
    }
    _validarNomeArquivo(versao.id, versaoPersistida.arquivo, musica.id);
    final conteudosAnteriores = <IdVersaoMusica, String>{};
    final conteudosAtualizados = <IdVersaoMusica, String>{};
    final versoes = await _banco.listarVersoesMusica(musica.id.valor);
    for (final registroVersao in versoes) {
      final idVersao = IdVersaoMusica(registroVersao.id);
      _validarNomeArquivo(idVersao, registroVersao.arquivo, musica.id);
      final conteudoAnterior = await _armazenamentoArquivos.obter(idVersao);
      conteudosAnteriores[idVersao] = conteudoAnterior;
      final sincronizada =
          await _banco.obterOrigemSincronizadaVersao(idVersao.valor) != null;
      conteudosAtualizados[idVersao] = idVersao == versao.id && !sincronizada
          ? _codificador.codificar(musica)
          : _revisarMetadadosCatalogo(
              idVersao == versao.id
                  ? versao.documento.conteudoOriginal
                  : conteudoAnterior,
              titulo: musica.titulo,
              artista: musica.artista,
            );
    }
    try {
      for (final entrada in conteudosAtualizados.entries) {
        await _armazenamentoArquivos.substituir(entrada.key, entrada.value);
      }
    } catch (erro, pilha) {
      await _restaurarArquivos(musica.id, conteudosAnteriores);
      Error.throwWithStackTrace(erro, pilha);
    }
    try {
      await _banco.executarEmTransacao(() async {
        final linhasAtualizadas = await _banco.atualizar(
          id: musica.id.valor,
          titulo: musica.titulo,
          artista: musica.artista,
        );
        if (linhasAtualizadas != 1) {
          throw MusicaNaoEncontrada(musica.id);
        }
        await _salvarIndicePesquisa(
          musica.versaoPrincipal,
          titulo: musica.titulo,
          artista: musica.artista,
        );
      });
    } catch (erro, pilha) {
      await _restaurarArquivos(musica.id, conteudosAnteriores);
      Error.throwWithStackTrace(erro, pilha);
    }
  }

  @override
  Future<Musica?> obterPorId(IdMusica id) async {
    final indice = await _medirSqliteVisualizacao(
      () => _banco.obterPorId(id.valor),
    );
    if (indice == null) {
      return null;
    }
    return _reconstruir(id, indice);
  }

  @override
  Future<List<Musica>> listar() async {
    final medicao = MedicaoDesempenhoBiblioteca.atual;
    final indices = medicao == null
        ? await _banco.listar()
        : await medicao.medirSqlite(_banco.listar);
    medicao?.registrarQuantidadeMusicas(indices.length);
    return Future.wait(
      indices.map(
        (indice) => _reconstruir(IdMusica(indice.id), indice, medicao: medicao),
      ),
    );
  }

  @override
  Future<List<ItemBiblioteca>> listarItensBiblioteca() async {
    final medicao = MedicaoDesempenhoBiblioteca.atual;
    final registros = medicao == null
        ? await _banco.listarItensBiblioteca()
        : await medicao.medirSqlite(_banco.listarItensBiblioteca);
    medicao?.registrarQuantidadeMusicas(registros.length);
    final idsEncontrados = <String>{};
    for (final registro in registros) {
      if (registro.idVersaoPrincipal == null ||
          !idsEncontrados.add(registro.idMusica)) {
        throw EstadoPersistenciaMusicaInconsistente(
          IdMusica(registro.idMusica),
        );
      }
    }
    final conteudosGerados = <String, String>{};
    final registrosSemConteudo = registros
        .where((registro) => registro.conteudoVisivel == null)
        .toList();
    final versoesSemIndice = registrosSemConteudo.isEmpty
        ? const <VersoesMusica>[]
        : medicao == null
        ? await _banco.listarVersoesPorIds(
            registrosSemConteudo.map((registro) => registro.idVersaoPrincipal!),
          )
        : await medicao.medirSqlite(
            () => _banco.listarVersoesPorIds(
              registrosSemConteudo.map(
                (registro) => registro.idVersaoPrincipal!,
              ),
            ),
          );
    final versoesPorId = {
      for (final versao in versoesSemIndice) versao.id: versao,
    };
    await Future.wait(
      registrosSemConteudo.map((registro) async {
        final versao = versoesPorId[registro.idVersaoPrincipal];
        if (versao == null) {
          throw EstadoPersistenciaMusicaInconsistente(
            IdMusica(registro.idMusica),
          );
        }
        final reconstruida = await _reconstruirVersao(versao, medicao: medicao);
        final conteudo = ExtratorConteudoVisivelChordPro.extrair(
          reconstruida.documento,
        );
        conteudosGerados[registro.idMusica] = conteudo;
      }),
    );
    final indicesGerados = [
      for (final registro in registros)
        if (registro.conteudoVisivel == null ||
            registro.tituloNormalizado == null ||
            registro.textoNormalizado == null)
          _criarRegistroIndicePesquisa(
            idMusica: registro.idMusica,
            idVersaoMusica: registro.idVersaoPrincipal!,
            titulo: registro.titulo,
            artista: registro.artista,
            conteudoVisivel:
                registro.conteudoVisivel ??
                conteudosGerados[registro.idMusica]!,
          ),
    ];
    if (indicesGerados.isNotEmpty) {
      if (medicao == null) {
        await _banco.salvarIndicesPesquisaMusicas(indicesGerados);
      } else {
        await medicao.medirSqlite(
          () => _banco.salvarIndicesPesquisaMusicas(indicesGerados),
        );
      }
    }
    return [
      for (final registro in registros)
        ItemBiblioteca(
          idMusica: IdMusica(registro.idMusica),
          idVersaoPrincipal: IdVersaoMusica(registro.idVersaoPrincipal!),
          titulo: registro.titulo,
          artista: registro.artista,
          conteudoVisivel:
              registro.conteudoVisivel ?? conteudosGerados[registro.idMusica]!,
          tituloNormalizado:
              registro.tituloNormalizado ?? normalizarPesquisa(registro.titulo),
          textoNormalizado:
              registro.textoNormalizado ??
              normalizarPesquisa(
                '${registro.titulo}\n${registro.artista}\n'
                '${registro.conteudoVisivel ?? conteudosGerados[registro.idMusica]!}',
              ),
        ),
    ];
  }

  @override
  Future<void> excluir(IdMusica id) async {
    final indice = await _banco.obterPorId(id.valor);
    if (indice == null) {
      throw MusicaNaoEncontrada(id);
    }
    if (await _banco.possuiItemListaParaMusica(id.valor)) {
      throw MusicaEmUsoEmLista(id);
    }
    final versoes = await _banco.listarVersoesMusica(id.valor);
    if (versoes.isEmpty) {
      throw EstadoPersistenciaMusicaInconsistente(id);
    }
    final conteudos = <IdVersaoMusica, String>{};
    for (final versao in versoes) {
      final idVersao = IdVersaoMusica(versao.id);
      _validarNomeArquivo(idVersao, versao.arquivo, id);
      conteudos[idVersao] = await _armazenamentoArquivos.obter(idVersao);
      await _armazenamentoArquivos.excluir(idVersao);
    }
    try {
      await _banco.excluirPorId(id.valor);
    } catch (erro, pilha) {
      try {
        for (final entrada in conteudos.entries) {
          await _armazenamentoArquivos.salvar(entrada.key, entrada.value);
        }
      } catch (_) {
        throw EstadoPersistenciaMusicaInconsistente(id);
      }
      Error.throwWithStackTrace(erro, pilha);
    }
  }

  @override
  Future<VersaoMusica?> obterPrincipalPorMusica(IdMusica idMusica) async {
    final indice = await _medirSqliteVisualizacao(
      () => _banco.obterVersaoPrincipalPorMusica(idMusica.valor),
    );
    return indice == null ? null : _reconstruirVersao(indice);
  }

  @override
  Future<VersaoMusica?> obterVersaoPorId(IdVersaoMusica id) async {
    final indice = await _medirSqliteVisualizacao(
      () => _banco.obterVersaoPorId(id.valor),
    );
    return indice == null ? null : _reconstruirVersao(indice);
  }

  @override
  Future<List<VersaoMusica>> listarPorMusica(IdMusica idMusica) async {
    final indices = await _banco.listarVersoesMusica(idMusica.valor);
    return Future.wait(indices.map(_reconstruirVersao));
  }

  @override
  Future<void> atualizarConteudoVersao(VersaoMusica versao) async {
    final atual = await obterVersaoPorId(versao.id);
    if (atual == null) throw VersaoMusicaNaoEncontrada(versao.id);
    if (atual.idMusica != versao.idMusica) {
      throw ArgumentError('Música da versão inválida.');
    }
    if (!atual.principal && await estaUsadaEmLista(atual.id)) {
      throw StateError('Esta versão exige salvar como nova versão.');
    }
    await _validarSchemaVersao(versao.id, versao.documento);
    final musica = await obterPorId(atual.idMusica);
    final rascunho = RascunhoDocumentoChordPro.criar(
      conteudoChordPro: versao.documento.conteudoOriginal,
      parserDocumento: _parserDocumento,
    );
    final conteudo = rascunho
        .comRevisao(
          RevisaoMetadadosChordPro(
            titulo: rascunho.tituloDetectado == musica!.titulo
                ? null
                : musica.titulo,
            artista: rascunho.artistaDetectado == musica.artista
                ? null
                : musica.artista,
          ),
        )
        .produzirConteudoFinal();
    final conteudoAnterior = atual.documento.conteudoOriginal;
    await _armazenamentoArquivos.substituir(atual.id, conteudo);
    if (atual.principal) {
      try {
        await _salvarIndicePesquisa(
          VersaoMusica(
            id: versao.id,
            idMusica: versao.idMusica,
            nome: versao.nome,
            documento: _parserDocumento.interpretar(conteudo),
            principal: true,
            arquivada: false,
          ),
          titulo: musica.titulo,
          artista: musica.artista,
        );
      } catch (erro, pilha) {
        await _armazenamentoArquivos.substituir(atual.id, conteudoAnterior);
        Error.throwWithStackTrace(erro, pilha);
      }
    }
  }

  @override
  Future<void> salvarVersao(VersaoMusica versao) async {
    if (await _banco.obterVersaoPorId(versao.id.valor) != null ||
        await _armazenamentoArquivos.existe(versao.id)) {
      throw ArgumentError.value(versao.id, 'versao', 'A versão já existe.');
    }
    if (await _banco.obterPorId(versao.idMusica.valor) == null) {
      throw MusicaNaoEncontrada(versao.idMusica);
    }

    final conteudo = versao.documento.conteudoOriginal;
    await _armazenamentoArquivos.salvar(versao.id, conteudo);
    try {
      await _banco.inserirVersaoMusica(
        id: versao.id.valor,
        idMusica: versao.idMusica.valor,
        nome: versao.nome,
        arquivo: _armazenamentoArquivos.nomeArquivo(versao.id),
        principal: versao.principal,
        arquivada: versao.arquivada,
      );
    } catch (erro, pilha) {
      try {
        await _armazenamentoArquivos.excluir(versao.id);
      } catch (_) {
        throw EstadoPersistenciaMusicaInconsistente(versao.idMusica);
      }
      Error.throwWithStackTrace(erro, pilha);
    }
  }

  @override
  Future<bool> estaUsadaEmLista(IdVersaoMusica id) =>
      _banco.possuiItemListaParaVersao(id.valor);

  @override
  Future<void> renomear(IdVersaoMusica id, String nome) async {
    final versao = await obterVersaoPorId(id);
    if (versao == null) throw VersaoMusicaNaoEncontrada(id);
    final nomeValidado = VersaoMusica(
      id: versao.id,
      idMusica: versao.idMusica,
      nome: nome,
      documento: versao.documento,
      principal: versao.principal,
      arquivada: versao.arquivada,
    ).nome;
    await _banco.renomearVersaoMusica(id.valor, nomeValidado);
  }

  @override
  Future<void> definirComoPrincipal(IdVersaoMusica id) async {
    final versao = await obterVersaoPorId(id);
    if (versao == null) {
      throw VersaoMusicaNaoEncontrada(id);
    }
    if (versao.arquivada) {
      throw ArgumentError('A versão arquivada não pode ser principal.');
    }
    if (!versao.principal) {
      final musica = await _banco.obterPorId(versao.idMusica.valor);
      if (musica == null) {
        throw MusicaNaoEncontrada(versao.idMusica);
      }
      await _banco.executarEmTransacao(() async {
        await _banco.definirVersaoPrincipal(versao.idMusica.valor, id.valor);
        await _salvarIndicePesquisa(
          versao,
          titulo: musica.titulo,
          artista: musica.artista,
        );
      });
    }
  }

  @override
  Future<void> arquivar(IdVersaoMusica id) async {
    final versao = await obterVersaoPorId(id);
    if (versao == null) throw VersaoMusicaNaoEncontrada(id);
    if (versao.principal) throw VersaoPrincipalNaoPodeSerArquivada(versao);
    if (!versao.arquivada) await _banco.definirArquivadaVersao(id.valor, true);
  }

  @override
  Future<void> restaurar(IdVersaoMusica id) async {
    final versao = await obterVersaoPorId(id);
    if (versao == null) throw VersaoMusicaNaoEncontrada(id);
    if (versao.arquivada) await _banco.definirArquivadaVersao(id.valor, false);
  }

  @override
  Future<void> excluirVersao(IdVersaoMusica id) async {
    final versao = await obterVersaoPorId(id);
    if (versao == null) throw VersaoMusicaNaoEncontrada(id);
    if (versao.principal) throw VersaoPrincipalNaoPodeSerExcluida(versao);
    if (await estaUsadaEmLista(id)) throw VersaoMusicaEmUsoEmLista(versao);
    final conteudo = await _armazenamentoArquivos.obter(id);
    await _armazenamentoArquivos.excluir(id);
    try {
      await _banco.excluirVersaoMusica(id.valor);
    } catch (erro, pilha) {
      try {
        await _armazenamentoArquivos.salvar(id, conteudo);
      } catch (_) {
        throw EstadoPersistenciaMusicaInconsistente(versao.idMusica);
      }
      Error.throwWithStackTrace(erro, pilha);
    }
  }

  Future<Musica> _reconstruir(
    IdMusica id,
    IndiceMusica indice, {
    MedicaoDesempenhoBiblioteca? medicao,
  }) async {
    final registroVersao = await _medirSqlite(
      () => _banco.obterVersaoPrincipalPorMusica(id.valor),
      medicaoBiblioteca: medicao,
    );
    if (registroVersao == null) {
      throw EstadoPersistenciaMusicaInconsistente(id);
    }
    final versao = await _reconstruirVersao(registroVersao, medicao: medicao);
    return Musica(
      id: id,
      titulo: indice.titulo,
      artista: indice.artista,
      versaoPrincipal: versao,
    );
  }

  Future<VersaoMusica> _reconstruirVersao(
    VersoesMusica indice, {
    MedicaoDesempenhoBiblioteca? medicao,
  }) async {
    final id = IdVersaoMusica(indice.id);
    _validarNomeArquivo(id, indice.arquivo, IdMusica(indice.idMusica));
    try {
      final conteudo = await _medirLeituraArquivo(
        () => _armazenamentoArquivos.obter(id),
        medicaoBiblioteca: medicao,
      );
      final documento = _medirInterpretacaoChordPro(
        () => _parserDocumento.interpretar(conteudo),
        medicaoBiblioteca: medicao,
      );
      await _validarSchemaVersao(id, documento, medicao: medicao);
      return VersaoMusica(
        id: id,
        idMusica: IdMusica(indice.idMusica),
        nome: indice.nome,
        documento: documento,
        principal: indice.principal,
        arquivada: indice.arquivada,
      );
    } catch (_) {
      throw EstadoPersistenciaMusicaInconsistente(IdMusica(indice.idMusica));
    }
  }

  Future<void> _validarSchemaVersao(
    IdVersaoMusica id,
    DocumentoChordPro documento, {
    MedicaoDesempenhoBiblioteca? medicao,
  }) async {
    final schemas = documento.elementos.whereType<DiretivaSchemaAppCifras>();
    final schema2 = schemas.length == 1 && schemas.single.versao == 2;
    if (schema2) {
      final origem = await _medirSqlite(
        () => _banco.obterOrigemSincronizadaVersao(id.valor),
        medicaoBiblioteca: medicao,
      );
      if (origem == null) throw const SchemaAppCifrasNaoSuportado();
      _validadorSchema.validarParaVersaoSincronizada(documento);
    } else {
      _validadorSchema.validarParaIncorporacao(documento);
    }
  }

  void _validarNomeArquivo(
    IdVersaoMusica id,
    String nomeArquivo,
    IdMusica idMusica,
  ) {
    if (nomeArquivo != _armazenamentoArquivos.nomeArquivo(id)) {
      throw EstadoPersistenciaMusicaInconsistente(idMusica);
    }
  }

  Future<T> _medirSqliteVisualizacao<T>(Future<T> Function() operacao) {
    final medicao = MedicaoDesempenhoVisualizacao.atual;
    return medicao == null ? operacao() : medicao.medirSqlite(operacao);
  }

  Future<T> _medirSqlite<T>(
    Future<T> Function() operacao, {
    MedicaoDesempenhoBiblioteca? medicaoBiblioteca,
  }) {
    final medicaoVisualizacao = MedicaoDesempenhoVisualizacao.atual;
    if (medicaoVisualizacao != null) {
      return medicaoVisualizacao.medirSqlite(operacao);
    }
    return medicaoBiblioteca == null
        ? operacao()
        : medicaoBiblioteca.medirSqlite(operacao);
  }

  Future<T> _medirLeituraArquivo<T>(
    Future<T> Function() operacao, {
    MedicaoDesempenhoBiblioteca? medicaoBiblioteca,
  }) {
    final medicaoVisualizacao = MedicaoDesempenhoVisualizacao.atual;
    if (medicaoVisualizacao != null) {
      return medicaoVisualizacao.medirLeituraArquivo(operacao);
    }
    return medicaoBiblioteca == null
        ? operacao()
        : medicaoBiblioteca.medirLeituraArquivo(operacao);
  }

  T _medirInterpretacaoChordPro<T>(
    T Function() operacao, {
    MedicaoDesempenhoBiblioteca? medicaoBiblioteca,
  }) {
    final medicaoVisualizacao = MedicaoDesempenhoVisualizacao.atual;
    if (medicaoVisualizacao != null) {
      return medicaoVisualizacao.medirInterpretacaoChordPro(operacao);
    }
    return medicaoBiblioteca == null
        ? operacao()
        : medicaoBiblioteca.medirInterpretacaoChordPro(operacao);
  }

  String _revisarMetadadosCatalogo(
    String conteudo, {
    required String titulo,
    required String artista,
  }) =>
      RascunhoDocumentoChordPro.criar(
            conteudoChordPro: conteudo,
            parserDocumento: _parserDocumento,
          )
          .comRevisao(
            RevisaoMetadadosChordPro(titulo: titulo, artista: artista),
          )
          .produzirConteudoFinal();

  Future<void> _restaurarArquivos(
    IdMusica idMusica,
    Map<IdVersaoMusica, String> conteudos,
  ) async {
    try {
      for (final entrada in conteudos.entries) {
        await _armazenamentoArquivos.substituir(entrada.key, entrada.value);
      }
    } catch (_) {
      throw EstadoPersistenciaMusicaInconsistente(idMusica);
    }
  }

  Future<void> _salvarIndicePesquisa(
    VersaoMusica versao, {
    required String titulo,
    required String artista,
  }) {
    final registro = _criarRegistroIndicePesquisa(
      idMusica: versao.idMusica.valor,
      idVersaoMusica: versao.id.valor,
      titulo: titulo,
      artista: artista,
      conteudoVisivel: ExtratorConteudoVisivelChordPro.extrair(
        versao.documento,
      ),
    );
    return _banco.salvarIndicePesquisaMusica(
      idMusica: registro.idMusica,
      idVersaoMusica: registro.idVersaoMusica,
      conteudoVisivel: registro.conteudoVisivel,
      tituloNormalizado: registro.tituloNormalizado,
      textoNormalizado: registro.textoNormalizado,
    );
  }

  RegistroIndicePesquisaMusica _criarRegistroIndicePesquisa({
    required String idMusica,
    required String idVersaoMusica,
    required String titulo,
    required String artista,
    required String conteudoVisivel,
  }) => RegistroIndicePesquisaMusica(
    idMusica: idMusica,
    idVersaoMusica: idVersaoMusica,
    conteudoVisivel: conteudoVisivel,
    tituloNormalizado: normalizarPesquisa(titulo),
    textoNormalizado: normalizarPesquisa('$titulo\n$artista\n$conteudoVisivel'),
  );
}
