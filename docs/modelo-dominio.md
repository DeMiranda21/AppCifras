# Modelo de Domínio — AppCifras

Este documento define apenas conceitos aprovados ou necessários ao software
atual. Escopo e simplificações do MVP estão em decisoes-mvp.md.

## Música e conteúdo

Musica é entidade identificada por IdMusica. A identidade distingue músicas
mesmo quando seus dados são iguais. Uma Música válida deriva título, artista e
tom original de exatamente uma diretiva válida de cada tipo no
DocumentoChordPro.

DocumentoChordPro preserva o conteúdo original e produz representação
interpretada ordenada para leitura e serviços musicais. Pode existir mesmo sem
originar Música válida. Texto, diretivas desconhecidas, linhas vazias e acordes
não interpretáveis são preservados.

O arquivo ChordPro é a fonte canônica do conteúdo musical. Metadados internos
do AppCifras e estado local derivado não criam segunda fonte de verdade.

EnergiaMusica é uma classificação local opcional, com Calma, Moderada ou
Animada. TagMusica é um valor livre, não vazio e identificado por texto sem
diferença de caixa dentro da mesma música; sua apresentação preserva o texto
legível informado. Ambas ficam fora do ChordPro e são associadas por IdMusica.

EstruturaMusica é uma representação derivada do DocumentoChordPro para leitura
e futuras operações assistidas. Suas SecoesMusica mantêm tipo semântico, rótulo
original e faixa de elementos no documento, inclusive seções vazias e conteúdo
anterior ao primeiro marcador. Ela não é persistida separadamente nem altera o
ChordPro. Rótulos inequívocos e marcadores estruturais conhecidos podem ser
reconhecidos; conteúdo ambíguo ou desconhecido permanece fora de uma seção
explícita, em faixa genérica derivada.

Para seções escritas futuramente pelo AppCifras, o tipo deriva do ambiente
ChordPro e o rótulo exibido deriva de seu atributo `label`; ambos permanecem
distintos. A leitura também aceita aliases e rótulos legados sem alterar sua
fonte.

## Conceitos musicais

Nota representa nome natural e alteração simples (natural, sustenido ou bemol),
mantendo grafia e classe de altura distintas. Tom combina nota fundamental e
modo maior ou menor. Acorde representa fundamental, qualidade, extensões,
adições, suspensões, alterações e baixo de inversão quando aplicáveis.

O parser produz acordes interpretados somente para o subconjunto aprovado.
AcordeNaoInterpretavel preserva texto original sem inventar semântica.
Transposição e graus trabalham sobre a representação interpretada, nunca sobre
texto reescrito.

ServicoTransposicao altera fundamental e baixo, preservando os demais
componentes. FormatadorAcorde produz a grafia canônica de acorde interpretado
sem redeterminar enarmonia. A conversão para graus depende do tom e mantém
como cifra absoluta estruturas não diatônicas, inversões ou formas fora do
contrato.

## Lista de Culto

ListaCulto é entidade identificada por IdListaCulto e nome. ItemListaCulto é
identificado por IdItemListaCulto, referencia Música por IdMusica e tem posição
persistente. A Lista não contém ChordPro nem duplica conteúdo da Música.

Itens são independentes: o domínio suporta ocorrências repetidas da mesma
música. A interface pode aplicar restrições de conveniência sem alterar essa
capacidade. Remover item ou Lista não remove Música.

## Preferência de tom de execução

O último tom é preferência local associada a IdMusica, separada de Música e
ChordPro. Não é histórico, tom original nem tom da Lista. Tom por item,
histórico de execução, ministrante, tags e classificações serão modelados
somente quando a etapa correspondente exigir.

## Limites atuais

Biblioteca Musical é escopo organizacional, não Aggregate Root formal no MVP.
Não existem entidades de Coleção, Tag, Fonte de Sincronização, Registro de
Tom, Arranjo/Versão, Usuário, Equipe ou Ministrante.
