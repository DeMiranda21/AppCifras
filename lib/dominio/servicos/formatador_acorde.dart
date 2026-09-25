import '../objetos_de_valor/acorde.dart';
import '../objetos_de_valor/nota.dart';

/// Produz uma cifra canônica para uma estrutura de acorde interpretável.
///
/// O formatador recebe somente [Acorde]. Cifras não interpretáveis permanecem
/// fora deste contrato e devem conservar seu texto original.
class FormatadorAcorde {
  /// Formata [acorde] sem alterar sua grafia enarmônica.
  ///
  /// Estados estruturais que o parser não produz não recebem uma
  /// sintaxe inventada e resultam em [UnsupportedError].
  String formatar(Acorde acorde) {
    final sufixo = _formatarSufixo(acorde);
    final alteracoes = _formatarAlteracoes(acorde.alteracoes);
    final baixo = acorde.baixo == null
        ? ''
        : '/${_formatarNota(acorde.baixo!)}';

    return '${_formatarNota(acorde.notaFundamental)}$sufixo$alteracoes$baixo';
  }

  String _formatarSufixo(Acorde acorde) {
    if (acorde.adicoes.contains(AdicaoAcorde.segunda)) {
      return _formatarSegundaAdicionada(acorde);
    }

    if (acorde.adicoes.isNotEmpty) {
      if (acorde.qualidade != QualidadeAcorde.maior ||
          acorde.suspensoes.isNotEmpty ||
          acorde.adicoes.length != 1) {
        throw UnsupportedError('Estrutura de adições não suportada.');
      }

      final adicao = acorde.adicoes.single;
      final base = switch (adicao) {
        AdicaoAcorde.nona => 'add9',
        AdicaoAcorde.decimaPrimeira => 'add11',
        AdicaoAcorde.segunda => throw StateError('Segunda já foi tratada.'),
      };
      return _comExtensoesEntreParenteses(base, acorde.extensoes);
    }

    if (acorde.suspensoes.isNotEmpty) {
      if (acorde.qualidade != QualidadeAcorde.maior ||
          acorde.suspensoes.length != 1) {
        throw UnsupportedError('Estrutura de suspensão não suportada.');
      }

      final base = acorde.suspensoes.single == SuspensaoAcorde.segunda
          ? 'sus2'
          : '4';
      return _comExtensoesEntreParenteses(base, acorde.extensoes);
    }

    return switch (acorde.qualidade) {
      QualidadeAcorde.maior => _formatarMaior(acorde.extensoes),
      QualidadeAcorde.menor => _formatarMenor(acorde.extensoes),
      QualidadeAcorde.quinta => _comExtensoesEntreParenteses(
        '5',
        acorde.extensoes,
      ),
      QualidadeAcorde.diminuto => _comExtensoesEntreParenteses(
        'dim',
        acorde.extensoes,
      ),
      QualidadeAcorde.aumentado => _comExtensoesEntreParenteses(
        'aug',
        acorde.extensoes,
      ),
    };
  }

  String _formatarSegundaAdicionada(Acorde acorde) {
    if (acorde.qualidade != QualidadeAcorde.maior ||
        acorde.adicoes.length != 1 ||
        acorde.suspensoes.isNotEmpty ||
        acorde.alteracoes.isNotEmpty) {
      throw UnsupportedError('Estrutura de segunda adicionada não suportada.');
    }

    if (acorde.extensoes.isEmpty) {
      return '2';
    }
    if (_conjuntosIguais(acorde.extensoes, {ExtensaoAcorde.sexta})) {
      return '2(6)';
    }
    throw UnsupportedError('Extensões com segunda adicionada não suportadas.');
  }

  String _formatarMaior(Set<ExtensaoAcorde> extensoes) {
    if (_conjuntosIguais(extensoes, {
      ExtensaoAcorde.setima,
      ExtensaoAcorde.nona,
      ExtensaoAcorde.decimaPrimeira,
      ExtensaoAcorde.decimaTerceira,
    })) {
      return '13';
    }
    if (_conjuntosIguais(extensoes, {
      ExtensaoAcorde.setima,
      ExtensaoAcorde.nona,
      ExtensaoAcorde.decimaPrimeira,
    })) {
      return '11';
    }
    if (_conjuntosIguais(extensoes, {
      ExtensaoAcorde.setima,
      ExtensaoAcorde.nona,
    })) {
      return '9';
    }
    if (extensoes.contains(ExtensaoAcorde.setimaMaior)) {
      return _comExtensoesEntreParenteses(
        '7M',
        extensoes.difference({ExtensaoAcorde.setimaMaior}),
      );
    }
    if (extensoes.contains(ExtensaoAcorde.setima)) {
      return _comExtensoesEntreParenteses(
        '7',
        extensoes.difference({ExtensaoAcorde.setima}),
      );
    }
    if (extensoes.contains(ExtensaoAcorde.sexta)) {
      return _comExtensoesEntreParenteses(
        '6',
        extensoes.difference({ExtensaoAcorde.sexta}),
      );
    }
    return _comExtensoesEntreParenteses('', extensoes);
  }

  String _formatarMenor(Set<ExtensaoAcorde> extensoes) {
    if (_conjuntosIguais(extensoes, {
      ExtensaoAcorde.setima,
      ExtensaoAcorde.nona,
    })) {
      return 'm9';
    }
    if (extensoes.contains(ExtensaoAcorde.setima)) {
      return _comExtensoesEntreParenteses(
        'm7',
        extensoes.difference({ExtensaoAcorde.setima}),
      );
    }
    if (extensoes.contains(ExtensaoAcorde.sexta)) {
      return _comExtensoesEntreParenteses(
        'm6',
        extensoes.difference({ExtensaoAcorde.sexta}),
      );
    }
    return _comExtensoesEntreParenteses('m', extensoes);
  }

  String _comExtensoesEntreParenteses(
    String base,
    Set<ExtensaoAcorde> extensoes,
  ) {
    const permitidas = {ExtensaoAcorde.nona, ExtensaoAcorde.decimaTerceira};
    if (!permitidas.containsAll(extensoes)) {
      throw UnsupportedError('Combinação de extensões não suportada.');
    }

    final componentes = <String>[];
    if (extensoes.contains(ExtensaoAcorde.nona)) {
      componentes.add('(9)');
    }
    if (extensoes.contains(ExtensaoAcorde.decimaTerceira)) {
      componentes.add('(13)');
    }
    return '$base${componentes.join()}';
  }

  String _formatarAlteracoes(Set<AlteracaoAcorde> alteracoes) {
    final ordenadas = alteracoes.toList()
      ..sort((primeira, segunda) {
        final porGrau = primeira.grau.compareTo(segunda.grau);
        if (porGrau != 0) {
          return porGrau;
        }
        return primeira.alteracao.deslocamentoCromatico.compareTo(
          segunda.alteracao.deslocamentoCromatico,
        );
      });

    return ordenadas
        .map((alteracao) => '(${alteracao.alteracao.simbolo}${alteracao.grau})')
        .join();
  }

  String _formatarNota(Nota nota) =>
      '${nota.nome.simbolo}${nota.alteracao.simbolo}';

  bool _conjuntosIguais<T>(Set<T> primeiro, Set<T> segundo) =>
      primeiro.length == segundo.length && primeiro.containsAll(segundo);
}
