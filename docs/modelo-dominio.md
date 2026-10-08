# Modelo de Domínio — AppCifras

Este documento define apenas conceitos aprovados ou necessários ao software
atual. Escopo e simplificações do MVP estão em decisoes-mvp.md.

## Modelo atual — Música e conteúdo

Musica é entidade identificada por IdMusica. A identidade distingue músicas
mesmo quando seus dados são iguais. Ela é a identidade de catálogo: título e
artista lhe pertencem. Cada VersaoMusica tem DocumentoChordPro e tom original
próprios; a versão principal é a cifra apresentada enquanto não houver seleção
de versão.

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

## Evolução aprovada — Música e versões

Musica é a identidade da música no catálogo: título e artista lhe pertencem.
VersaoMusica é o arranjo concreto, com identidade própria, DocumentoChordPro e
tom original próprios. Uma Música poderá ter várias versões, das quais uma é
marcada como principal.

A cifra única preexistente é migrada automaticamente para sua versão principal.
Não se duplica a entrada de catálogo para representar arranjos como Principal,
Simplificada, Igreja A ou Acústica. Na migração inicial, o valor textual do
IdVersaoMusica principal coincide com o IdMusica e o arquivo ChordPro não é
renomeado.

Cada Música tem exatamente uma versão principal ativa. Uma versão principal não
pode ser arquivada diretamente; trocar a principal apenas move essa marca para
outra versão ativa, sem copiar conteúdo, apagar a versão anterior ou trocar
identidades.

O nome ou rótulo de VersaoMusica é editável e não determina sua identidade. Já
o conteúdo musical — DocumentoChordPro, acordes, estrutura, arranjo e tom
original — poderá ser alterado somente enquanto a versão não for referenciada
por ItemListaCulto. Após o primeiro uso em Lista, esse conteúdo será imutável;
uma mudança musical criará nova versão a partir da existente. A proteção vale
mesmo que a versão deixe de ser principal.

Versão usada por Lista não poderá ser excluída fisicamente: será arquivada,
permanecendo disponível para referências antigas, sem ser oferecida normalmente
em novas seleções. Versão nunca usada poderá ser excluída. O ItemListaCulto
manterá referência à versão concreta, sem snapshot completo de ChordPro; a
imutabilidade após o uso preserva o significado das Listas antigas.

As diretivas `{title}` e `{artist}` presentes em cada ChordPro espelham os
metadados atuais do catálogo e podem ser atualizadas sem alterar o conteúdo
musical de uma versão. `{key}` pertence exclusivamente à versão. A diretiva
`{appcifras_id}` continua identificando IdMusica; não há diretiva de ID de
versão nesta etapa.

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

## Modelo atual — Lista de Culto

ListaCulto é entidade identificada por IdListaCulto e nome. ItemListaCulto é
identificado por IdItemListaCulto, referencia Música por IdMusica e sua versão
concreta por IdVersaoMusica, além de posição persistente. A Lista não contém
ChordPro nem duplica conteúdo da Música.

Itens são independentes: o domínio suporta ocorrências repetidas da mesma
música. A interface pode aplicar restrições de conveniência sem alterar essa
capacidade. Remover item ou Lista não remove Música.

## Evolução aprovada — contexto de ministração nas Listas

Uma Lista de Culto será normalmente criada para uma ministração e funcionará
como memória operacional desse repertório; não haverá, por enquanto, entidade
separada de execução nem estados planejada, executada ou cancelada. A Lista
terá futuramente data e ministrante opcional, aplicável à Lista inteira, sem
ministrante por música, múltiplos ministrantes ou override por item.

Cada ItemListaCulto registra a Música, a versão escolhida e a posição. Em
evolução posterior, também registrará o tom daquela ocasião. Esse tom será snapshot
operacional: mudanças posteriores no último tom, na versão principal ou em
outras Listas não alterarão uma Lista anterior. Pesquisa histórica e
estatísticas futuras serão consultas derivadas das próprias Listas, não dados
persistidos separadamente.

## Preferência de tom de execução

O último tom é preferência local associada a IdVersaoMusica, separada de Música
e ChordPro. Não é histórico, tom original nem tom da Lista. A regra exata para
usá-lo como sugestão inicial de um novo ItemListaCulto permanece aberta; depois
da inclusão, o tom snapshot do item será independente.

## Limites atuais

Biblioteca Musical é escopo organizacional, não Aggregate Root formal no MVP.
Não existem ainda entidades implementadas de Coleção, Fonte de Sincronização,
Usuário, Equipe ou Ministrante. A Biblioteca atual é única,
principal e oficial; múltiplas bibliotecas públicas, assináveis ou comunitárias
são possibilidade distante e não orientam a arquitetura atual.
