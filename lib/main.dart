import 'dart:async';

import 'package:flutter/material.dart';

import 'apresentacao/biblioteca/tela_biblioteca.dart';
import 'composicao/composicao_appcifras.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final composicao = await ComposicaoAppCifras.inicializar();
    runApp(MyApp(composicao: composicao));
  } catch (erro) {
    runApp(AppInicializacaoFalhou(erro: erro));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.composicao});

  final ComposicaoAppCifras composicao;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  var _encerrada = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(_encerrar());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_encerrar());
    super.dispose();
  }

  Future<void> _encerrar() async {
    if (_encerrada) {
      return;
    }
    _encerrada = true;
    await widget.composicao.encerrar();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AppCifras',
    theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
    home: TelaBiblioteca(
      listarMusicas: widget.composicao.listarMusicas,
      prepararEntradaMusica: widget.composicao.prepararEntradaMusica,
      salvarRascunhoChordPro: widget.composicao.salvarRascunhoChordPro,
      obterMusicaPorId: widget.composicao.obterMusicaPorId,
      atualizarMusica: widget.composicao.atualizarMusica,
      excluirMusica: widget.composicao.excluirMusica,
      obterUltimoTomExecucao: widget.composicao.obterUltimoTomExecucao,
      salvarUltimoTomExecucao: widget.composicao.salvarUltimoTomExecucao,
      removerUltimoTomExecucao: widget.composicao.removerUltimoTomExecucao,
      listarListasCulto: widget.composicao.listarListasCulto,
      criarListaCulto: widget.composicao.criarListaCulto,
      renomearListaCulto: widget.composicao.renomearListaCulto,
      excluirListaCulto: widget.composicao.excluirListaCulto,
      listarItensListaCulto: widget.composicao.listarItensListaCulto,
      adicionarMusicaAListaCulto: widget.composicao.adicionarMusicaAListaCulto,
      removerItemListaCulto: widget.composicao.removerItemListaCulto,
      reordenarItensListaCulto: widget.composicao.reordenarItensListaCulto,
    ),
  );
}

class AppInicializacaoFalhou extends StatelessWidget {
  const AppInicializacaoFalhou({super.key, required this.erro});

  final Object erro;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'AppCifras',
    home: Scaffold(
      body: Center(child: Text('Falha ao inicializar o AppCifras: $erro')),
    ),
  );
}
