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
`{appcifras_id}` continua identificando IdMusica. Em arquivos sincronizáveis do
schema 2, `{appcifras_version_id}` identifica a VersaoMusica concreta;
documentos locais anteriores continuam podendo obter essa identidade somente da
persistência.

## Modelo atual — origem sincronizada

OrigemSincronizada é o vínculo leve entre uma VersaoMusica e o arquivo que a
representa na única Biblioteca Oficial pública. Sua presença distingue uma
versão gerenciada pelo catálogo oficial de uma versão exclusivamente local.
Não é uma abstração de múltiplas fontes nem transforma a publicação externa em
outra Biblioteca local.

Cada arquivo da fonte corresponde a uma VersaoMusica. Vários arquivos podem
declarar o mesmo IdMusica, desde que tenham IdVersaoMusica distintos. Título,
nome da versão, nome do arquivo e caminho podem mudar sem trocar identidade. O
vínculo registra o IdVersaoMusica, o localizador atual na árvore, o hash SHA-256
dos bytes externos e se a origem está presente ou ausente; IdMusica deriva da
própria versão.

Uma versão com origem presente é somente leitura no fluxo comum. Alteração do
usuário cria outra VersaoMusica local com novo ID e sem origem sincronizada. A
versão local pode ser editada e definida como principal, mas não é enviada à
publicação oficial. A marca de principal vinda da fonte inicializa uma Música
nova; depois da incorporação, qual versão é principal permanece estado local.

Ausência do arquivo não encerra a identidade nem apaga conteúdo. A versão, a
preferência de último tom e as referências de ItemListaCulto permanecem; apenas
o vínculo passa a ausente. O reaparecimento dos mesmos IdMusica e
IdVersaoMusica reativa o vínculo existente.

A publicação oficial usa manifesto versionado e arquivos `.cho` por HTTPS. O
manifesto transporta somente identidade, hash, tamanho e localizador relativo;
metadados musicais continuam no ChordPro schema 2. Nome de arquivo, path e
geração não substituem IdMusica ou IdVersaoMusica como identidade. O conteúdo
oficial é incorporado ao armazenamento local e permanece disponível offline.

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

## Evolução aprovada — contexto de ministração e histórico

Uma Lista de Culto é criada para uma ministração e funciona como memória
operacional desse repertório. Ao ser salva, passa a compor o histórico; não há
distinção inicial entre Lista planejada e efetivamente executada, nem entidade
separada de Execução ou Histórico. Consultas históricas são projeções derivadas
das próprias Listas.

ListaCulto possuirá DataCulto e um Ministrante associado, ambos opcionais e
aplicáveis à Lista inteira. A data ordena o histórico, identifica utilizações
anteriores e permite consultas por período. `criadaEm` é metadado técnico
imutável, preenchido automaticamente nas novas Listas com o instante de sua
criação no aplicativo. Não substitui DataCulto nem representa a data do culto;
serve somente para desempatar Listas com a mesma DataCulto e para ordenação
técnica ou de apresentação entre Listas sem data. Ministrante é entidade local
simples, identificada por IdMinistrante e com nome para seleção consistente.
Seu cadastro não representa Usuário, conta, autenticação, permissão ou
sincronização. Nesta evolução não há ministrante por música, múltiplos
ministrantes ou override por item.

Listas legadas, anteriores a essa evolução, mantêm DataCulto, IdMinistrante e
`criadaEm` nulos. Permanecem válidas e utilizáveis; a migração não inventa
nenhum desses valores. Seus itens mantêm tom histórico nulo, sem inferi-lo da
preferência atual da VersaoMusica nem do tom original. Essas nulabilidades são
compatibilidade histórica, não uma segunda origem para os dados.

IdMinistrante é identidade estável e independente do nome. O nome pode ser
alterado sem trocar a identidade ou romper referências de Listas. Ministrante
associado a Lista histórica não é excluído fisicamente: pode ser arquivado ou
inativado, deixando de aparecer normalmente em novas seleções, enquanto as
referências existentes continuam válidas. Não há snapshot do nome na Lista;
Listas antigas exibem o nome atual do Ministrante referenciado. Um Ministrante
arquivado pode ser restaurado. Nomes iguais não tornam dois Ministrantes a
mesma entidade: o cadastro admite duplicidade porque a identidade é o ID.

Cada ItemListaCulto registra a Música, a versão escolhida e a posição. O detalhe
da Lista permite trocar a versão desse item por outra versão ativa da mesma
Música, sem alterar a principal nem outros itens. Uma referência existente a uma
versão arquivada continua válida e abrível, embora arquivadas não sejam oferecidas
para nova escolha. O item também registrará o tom daquela ocasião. Esse tom é
snapshot operacional e fonte de verdade ao abrir a música pela Lista: mudanças
posteriores no último tom da VersaoMusica, na versão principal ou em outras
Listas não alteram uma Lista anterior. Alterar o tom dentro do contexto da Lista
atualiza somente o ItemListaCulto correspondente e não altera a preferência
global da VersaoMusica. Trocar a versão concreta do item preserva seu tom; se o
tom era nulo, permanece nulo e nenhum histórico é consultado para preenchê-lo.
Trocar o Ministrante da Lista também preserva todos os tons já registrados;
somente novas inclusões passam a usar o novo Ministrante no fallback.

## Preferência de tom de execução

O último tom é preferência local associada a IdVersaoMusica, separada de Música
e ChordPro. Não é histórico, tom original nem tom da Lista. Fora de uma Lista,
a leitura usa essa preferência. Ao adicionar uma música a uma Lista com
Ministrante definido, o tom inicial segue esta precedência: último tom usado
por esse Ministrante na mesma Música e VersaoMusica; na ausência, último tom
geral da VersaoMusica; na ausência, tom original. Depois da inclusão, o tom do
ItemListaCulto é independente dessas preferências.

O último tom histórico considera somente itens com tom não nulo em Listas cuja
DataCulto seja conhecida. A ordem é DataCulto decrescente e, apenas quando ela
for igual, `criadaEm` decrescente. Nenhum ID, UUID, `rowid`, posição ou outro
identificador funciona como critério temporal. Listas sem DataCulto continuam
historicamente válidas e podem ser ordenadas entre si por `criadaEm` para
apresentação, mas não participam da determinação da última utilização.

## Limites atuais

Biblioteca Musical é escopo organizacional, não Aggregate Root formal no MVP.
Não existem ainda entidades implementadas de Coleção, Usuário ou Equipe.
Ministrante é uma evolução aprovada como cadastro exclusivamente local.
OrigemSincronizada é somente o vínculo mínimo descrito acima, sem
hierarquia genérica de fontes. A Biblioteca atual é única, principal e oficial;
múltiplas bibliotecas públicas, assináveis ou comunitárias são possibilidade
distante e não orientam a arquitetura atual.
