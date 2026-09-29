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
