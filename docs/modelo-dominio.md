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

## Evolução aprovada — entrada e revisão contextual

No fluxo comum, o rascunho que o usuário vê representa uma música em termos de
letra, acordes e seções. DocumentoChordPro continua sendo a única fonte
canônica persistida; a revisão assistida é uma projeção transitória usada para
produzir ou transformar esse documento, não um segundo modelo musical salvo.

A análise do rascunho classifica cada trecho relevante em um destes estados:

- reconhecido com segurança, quando pode ser convertido automaticamente;
- ambíguo, quando exige uma decisão localizada do usuário;
- inválido ou problemático, quando uma interpretação pretendida precisa ser
  corrigida;
- desconhecido porém preservável, quando o texto deve permanecer intacto,
  embora algum recurso possa ficar indisponível.

ProblemaDeCifra é o valor transitório que descreve uma ocorrência concreta a
ser revisada. Ele contém tipo, faixa no rascunho, texto encontrado, contexto,
motivo, ações permitidas e revisão do rascunho em que foi produzido. A faixa e
o texto esperado identificam a ocorrência, inclusive quando o mesmo texto se
repete. Antes de transformar, a aplicação confirma que a revisão ainda é a
mesma e que a faixa ainda contém o valor esperado.

Depois de qualquer decisão, o rascunho inteiro é analisado novamente e os
ProblemasDeCifra anteriores deixam de valer. As posições são dados laterais do
rascunho para esta etapa; não passam a integrar todos os nós da representação
interpretada. Diagnósticos não são persistidos.

As ações iniciais são `É acorde`, `É texto` e `Corrigir acorde`. A correção só
é aceita quando ParserAcorde reconhece o valor informado. A decisão afeta a
ocorrência exibida, sem procurar outra ocorrência pelo texto e sem depender de
seleção do editor. Dúvida sem decisão permanece texto. Conteúdo desconhecido
preservável pode gerar limitação explícita, mas continua pertencendo ao
DocumentoChordPro produzido.

Título e artista continuam pertencendo à Musica, e tom original pertence à
VersaoMusica. Esses metadados são editados em campos próprios e não são
ProblemasDeCifra.

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

A Biblioteca continua apresentando uma única entrada por Música e abre sua
versão principal. Fora de uma Lista de Culto, a leitura pode alternar entre
versões ativas sem mudar qual delas é principal. Ao abrir uma Lista, a leitura
usa estritamente a versão registrada pelo ItemListaCulto.

Uma nova versão nasce como cópia do DocumentoChordPro da versão de origem, com
novo IdVersaoMusica, mesmo IdMusica, nome não vazio, principal=false e
arquivada=false. A preferência de último tom não é copiada: por ser local à
versão, a nova versão começa no seu tom original.

O nome ou rótulo de VersaoMusica é editável e não determina sua identidade. O
conteúdo musical de uma alternativa poderá ser sobrescrito enquanto ela não for
referenciada por ItemListaCulto; depois do primeiro uso, uma mudança musical
criará nova versão a partir dela. Para a versão principal, o usuário escolhe
explicitamente entre sobrescrever o mesmo IdVersaoMusica ou criar uma nova
versão. A sobrescrita é permitida mesmo quando a principal aparece em Listas.

Versão usada por Lista não poderá ser excluída fisicamente: será arquivada,
permanecendo disponível para referências antigas, sem ser oferecida normalmente
em novas seleções. Versão nunca usada poderá ser excluída. O ItemListaCulto
mantém referência à versão concreta, sem snapshot completo de ChordPro. Listas
antigas que apontam para a principal acompanham sua evolução; sua memória
operacional preserva repertório, versão escolhida e, futuramente, tom da ocasião.

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

Cada ItemListaCulto registra a Música, a versão escolhida e a posição. O detalhe
da Lista permite trocar a versão desse item por outra versão ativa da mesma
Música, sem alterar a principal nem outros itens. Uma referência existente a uma
versão arquivada continua válida e abrível, embora arquivadas não sejam oferecidas
para nova escolha. Em evolução posterior, o item também registrará o tom daquela
ocasião. Esse tom será snapshot operacional: mudanças posteriores no último tom,
na versão principal ou em outras Listas não alterarão uma Lista anterior.
Pesquisa histórica e estatísticas futuras serão consultas derivadas das próprias
Listas, não dados persistidos separadamente.

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
