# Decisões do MVP — AppCifras

**Status:** aprovado pelo proprietário do projeto  
**Escopo:** decisões vinculantes para a primeira versão funcional local.  
**Precedência:** este documento resolve, para o MVP, divergências de escopo entre a Especificação Funcional, o Roadmap, o Modelo de Domínio e os Requisitos Não Funcionais. Decisões permanentes de conceito musical continuam sob responsabilidade do Modelo de Domínio.

## 1. Objetivo do MVP

Entregar uma versão Android local e offline que permita ao músico manter sua Biblioteca Musical, consultar cifras, alterar tonalidade, visualizar graus harmônicos simples, marcar favoritos e preparar Listas de Culto.

O fluxo principal é: cadastrar ou colar uma música, encontrá-la na biblioteca, visualizá-la, transpor quando necessário e organizá-la em uma lista.

## 2. Escopo aprovado

O MVP incluirá:

- cadastro, edição em texto simples e exclusão de músicas;
- título, artista, tom original e conteúdo com letra e acordes como dados obrigatórios;
- armazenamento local e uso offline;
- biblioteca, busca por título e favoritos;
- visualização de cifras;
- ajuste de tamanho de fonte;
- transposição;
- visualização por cifras, graus ou ambas;
- Listas de Culto com criação, inclusão de músicas, reordenação, tom por item e navegação;
- persistência de preferências locais.

## 3. Conteúdo e formato da música

O usuário cadastrará uma música digitando ou colando o conteúdo completo da letra com acordes em um editor de texto simples.

O formato de intercâmbio e armazenamento da música será **ChordPro**. Cada música será armazenada como um único arquivo UTF-8 nesse formato. O conteúdo ChordPro original fornecido pelo usuário será preservado sem reescrita; a aplicação poderá gerar uma representação interpretada em memória para renderização, transposição e exibição de graus.

O parser do MVP aceitará um subconjunto básico ampliado de acordes: fundamentais de A a G, com sustenidos ou bemóis; tríades; extensões; suspensões; adições; alterações entre parênteses; e inversões. Também aceitará os aliases de acordes já documentados no Modelo de Domínio. A definição detalhada dessa gramática pertence à implementação e aos testes do parser, sem ampliar o escopo musical aprovado para o MVP.

Cifras que o parser ainda não consiga interpretar serão preservadas no conteúdo original e sinalizadas como não interpretáveis. Elas não impedirão o cadastro ou a preservação da música e permanecerão como cifras absolutas, sem transposição ou conversão automática para graus.

Os metadados próprios do AppCifras associados ao arquivo ChordPro terão schema versionado. Esse schema incluirá apenas informações necessárias ao MVP e não incorporará recursos adiados.

Não haverá editor estruturado por seções, nem recursos de arrastar, duplicar, excluir ou reorganizar blocos. A evolução futura para seções estruturadas deve permanecer possível.

## 4. Graus harmônicos

A conversão será baseada no tom atual da música.

- Acordes pertencentes ao campo harmônico serão convertidos para graus romanos ou numéricos.
- Acordes fora do campo harmônico não receberão interpretação automática: permanecerão como acordes absolutos com sua grafia original.
- Inversões, como G/B, C/E e D/F#, serão preservadas integralmente no MVP.
- Acordes emprestados, dominantes secundários, alterações cromáticas e conversão avançada de inversões são evolução futura.

## 5. Modelagem do MVP

A Biblioteca Musical será inicialmente um escopo organizacional, e não um Aggregate Root formal.

Cada Música será uma entidade independente, identificada por ID e persistida localmente. Lista de Culto também terá identidade própria e seus itens referenciarão músicas por ID.

Registro de Tom, Tag e Fonte de Sincronização não serão entidades completas no MVP. Quando necessários, serão valores ou estruturas simples ligadas à música ou às configurações. Coleções não fazem parte do MVP.

## 6. Sincronização e recursos adiados

Sincronização com Google Drive ou qualquer outra nuvem fica para depois da versão local funcional. Também ficam fora do MVP importação de PDF, compartilhamento, histórico avançado, coleções, modo palco, rolagem automática, estatísticas, Bluetooth, MIDI, IA e colaboração.

## 7. Exclusão

A exclusão de uma música será definitiva no armazenamento local e exigirá confirmação explícita do usuário. Não haverá lixeira nem exclusão lógica no MVP.

## 8. Plataforma e validação

A plataforma inicial é Android. O aparelho principal de desenvolvimento e testes será um Samsung Galaxy A72.

O MVP deve priorizar nesse aparelho abertura rápida de músicas, operação offline, rolagem fluida, leitura confortável, transposição sem atraso perceptível e baixo consumo de memória e bateria.

O Android mínimo do MVP será a API 23 (Android 6.0).

## 9. Fonte dos dados locais

O arquivo da música é a fonte original de seu conteúdo e dos metadados próprios do AppCifras. O banco local armazenará apenas dados derivados e locais necessários para índice, favoritos, Listas de Culto e preferências.

## 10. Grafia enarmônica na transposição

Quando houver tom de destino conhecido, a transposição deve preferir a grafia enarmônica coerente com a tonalidade de destino. Por exemplo, ao transpor para Eb, devem ser preferidas grafias como Eb, Ab e Bb, em vez de D#, G# e A#, quando musicalmente correspondentes.

Quando não houver contexto tonal, a transposição deve preservar, quando possível, a família de acidente da grafia original. Por exemplo, C#7 transposto dois semitons deve tender a D#7, enquanto Db7 transposto dois semitons deve tender a Eb7.

Como fallback sem contexto tonal, se a nota resultante possuir representação natural, essa representação deve ser usada. Se a nota original possuir sustenido ou bemol e o resultado exigir acidente, deve ser preservada a preferência pela respectiva família. Se a nota original for natural e o resultado exigir acidente, deve ser preferido sustenido. Essa regra é apenas determinística para ausência de contexto tonal; quando houver tom de destino, prevalece a grafia coerente com a tonalidade.

A equivalência sonora e a grafia continuam sendo conceitos distintos: notas enarmônicas podem ter a mesma classe de altura sem serem estruturalmente iguais.

## 11. Acidentes suportados

O MVP suporta somente notas naturais, sustenidos simples (#) e bemóis simples (b). Acidentes duplos (##, bb e equivalentes) ficam fora do escopo.

Quando uma grafia teoricamente rigorosa exigir acidente duplo, o aplicativo deverá utilizar uma representação enarmônica equivalente suportada pelo MVP. Essa é uma simplificação deliberada e não deve provocar ampliação do modelo Nota nesta fase.

## 12. Conversão de graus harmônicos

Para o MVP, Tom.menor utiliza a escala menor natural como referência diatônica: i, ii°, III, iv, v, VI e VII. Escalas menor harmônica e melódica, incluindo o reconhecimento de V maior e vii° característicos, ficam para evolução futura.

Um acorde será convertido para grau somente se todas as notas que compõem sua estrutura forem diatônicas na escala do Tom informado. Em C maior, por exemplo, Em7, Cadd9 e Dsus4 são convertíveis, enquanto C7 permanece como cifra absoluta por conter Bb.

A conversão preserva estruturalmente qualidade, extensões, adições, suspensões e demais características suportadas do acorde. Inversões, acordes não diatônicos e estruturas que não correspondam ao grau esperado permanecem como cifras absolutas no MVP.

## 13. Subconjunto do parser de acordes

O parser do MVP trabalha com um subconjunto explícito e evolutivo de notações. O conteúdo ChordPro original é preservado sem reescrita; o parser produz somente uma representação estrutural derivada em memória. Uma cifra não reconhecida deve ser preservada exatamente como texto não interpretável, sem impedir o cadastro da música, mas não poderá ser transposta ou convertida para graus automaticamente.

São reconhecidas fundamentais de A a G, naturais, com sustenido simples (#) ou bemol simples (b), e as estruturas: maior (C), menor (Cm), quinta (C5), sexta (C6 e Cm6), sétimas C7, Cm7 e Cmaj7, extensões C9, Cm9, C11 e C13, adições Cadd9 e Cadd11, suspensões Csus2 e Csus4, diminuto (Cdim), aumentado (Caug), meio-diminuto (Cm7(b5)) e inversões com baixo após /.

As alterações inicialmente reconhecidas são b5, #5, b9 e #9, escritas entre parênteses e combináveis quando cada componente for suportado. Formas com extensões entre parênteses são aceitas quando equivalentes às estruturas suportadas, como C7(9), Cm7(9), C7M(9) e C7(13).

Os aliases C7M, CM7 e CΔ7 equivalem a Cmaj7; C° equivale a Cdim; C+ equivale a Caug; Cø equivale a Cm7(b5); e C4 equivale a Csus4. A normalização aplica-se somente à representação estrutural. Parênteses têm significado apenas para componentes previstos neste subconjunto, e / representa exclusivamente inversão; 6/9 não é suportado.

Ficam fora do subconjunto atual: alt, no3, #11, b13, 6/9, 69, 2 e outras notações que exijam ampliação do modelo. Não haverá parsing parcial nem correção silenciosa de texto desconhecido.

Para esse subconjunto, QualidadeAcorde.quinta representa acordes como C5 sem terça, e AdicaoAcorde.decimaPrimeira representa Cadd11. A transposição preserva essas estruturas; acordes de quinta permanecem como cifras absolutas na conversão de graus do MVP.

## 14. Processamento básico de ChordPro

O processamento ChordPro gera uma representação derivada e ordenada em memória, sem reescrever a fonte original. Espaços, linhas vazias, texto, acordes não interpretáveis e conteúdos malformados são preservados.

Nesta etapa são interpretadas somente as diretivas title, artist e key, além de start_of_chorus/end_of_chorus e seus aliases soc/eoc. Diretivas desconhecidas são preservadas, e refrões são reconhecidos exclusivamente por esses marcadores explícitos, sem inferência a partir do texto.

## 15. Metadados obrigatórios da Música

Para originar uma Música válida, o Documento ChordPro deve conter exatamente uma diretiva válida de cada metadado obrigatório: title, artist e key. Diretivas ausentes, repetidas ou sem valor válido impedem somente a criação da Música; o Documento ChordPro original continua preservado integralmente, sem escolha de precedência ou alteração automática.

## 16. Armazenamento local e importação

A Biblioteca Musical do MVP é local ao aparelho e funciona integralmente offline. Nuvem, backup e sincronização entre aparelhos são evoluções futuras; a arquitetura deve mantê-los fora do domínio musical e sem acoplamento impeditivo.

Arquivos externos são somente fontes de importação. A importação cria uma cópia pertencente ao AppCifras, que permanece utilizável offline e independente da disponibilidade, movimentação ou exclusão da origem. O aplicativo não modifica a origem: transformações futuras, incluindo TXT para ChordPro, ocorrem exclusivamente sobre a cópia interna.

O conteúdo musical (ChordPro, letra, acordes e metadados musicais), a identidade própria do AppCifras e o estado local derivado da Biblioteca permanecem conceitualmente separados. Favoritos, Listas de Culto, índices e preferências não pertencem à Música nem ao arquivo ChordPro nesta etapa.

Arquivos gerenciados pela Biblioteca poderão declarar `{appcifras_schema: 1}` e `{appcifras_id: <id>}`. `IdMusica` é a identidade canônica no domínio; quando a diretiva `appcifras_id` estiver presente, ela deve ocorrer uma única vez, ser válida e corresponder ao ID da Música. Documentos externos sem essas diretivas continuam válidos para importação, e cópias internas recebem identidade própria sem alterar a origem.

## 17. Persistência local da Biblioteca

Cada Música gerenciada é persistida em arquivo UTF-8 individual com extensão `.cho`, cujo nome interno é derivado de `IdMusica`, nunca de título ou artista. O arquivo ChordPro é a fonte oficial do conteúdo e dos metadados próprios da Música; SQLite mantém somente o índice e o estado local derivado, sem duplicar a cifra completa. Drift é a camada Dart sobre SQLite adotada pelo MVP.

Uma importação com `appcifras_id` já existente não sobrescreve silenciosamente a Música local. Conteúdo identificado com schema AppCifras inválido ou diferente de `1` não é incorporado como Música gerenciada, mas permanece preservado como conteúdo recebido. Nuvem e sincronização continuam fora do MVP local.

## 18. Entrada de cifras e revisão

A entrada principal evoluirá para receber texto bruto em uma única área, com análise e revisão antes do salvamento. ChordPro permanece o formato operacional e canônico da Música.

Para texto que não esteja em ChordPro, o conteúdo original recebido deve ser preservado como fonte de importação; a representação ChordPro convertida não cria uma segunda versão editável concorrente. A persistência adicional desse original será definida em etapa própria.

Quando a entrada for ChordPro completo, as diretivas existentes são a fonte dos metadados. Alterações confirmadas pelo usuário em título, artista ou tom devem alterar explicitamente o documento que será salvo, mantendo uma única fonte de verdade. Não haverá metadados paralelos, escolha de precedência ou deduplicação silenciosa.

Entradas ambíguas não devem receber conversões arriscadas: o conteúdo é preservado e a revisão informa o que foi ou não reconhecido. Rótulos inequívocos como Intro, Primeira Parte, Verso, Pré-Refrão, Refrão, Ponte e Final poderão ser identificados futuramente, preservando seu texto original, mas sua representação ChordPro ou estrutural não faz parte desta etapa. Comentários e tablaturas também são apenas preservados por enquanto.

Uma linha somente de acordes não implica, por si só, associação à próxima linha de letra, pois pode representar passagem instrumental ou introdução. Essa distinção pertence ao futuro conversor de cifra textual e não é uma regra de domínio.

## 19. Visualização responsiva da cifra e zoom

A visualização principal da cifra deve caber horizontalmente na largura útil disponível na tela. Nenhum acorde ou trecho de letra pode ficar cortado ou inacessível à direita; a navegação normal da música permanece vertical e não deve exigir rolagem horizontal.

Quando uma linha musical não couber, ela deverá ser reorganizada ou quebrada de forma controlada, preservando a associação entre cada acorde e o respectivo trecho de letra. A unidade semântica `acorde + trecho de letra associado` orientará essa quebra, evitando separação visual entre ambos. Não serão usadas como solução truncamento, ellipsis ou redução arbitrária da fonte.

A visualização deverá suportar futuramente zoom in e zoom out da cifra. A implementação atual não inclui zoom, mas a arquitetura de renderização deve permitir que o tamanho escolhido recalcule as dimensões dos grupos musicais e reorganize as linhas conforme a largura disponível, mantendo o conteúdo limitado à viewport e a navegação vertical. Não deve ser adotada solução estrutural baseada em canvas de largura fixa ou rolagem horizontal obrigatória.

## 20. Edição de música

A edição atualiza a mesma Música, preservando seu `IdMusica`; não cria outra entrada nem usa exclusão seguida de cadastro. O ChordPro canônico persistido é a origem da edição. Alterações de título, artista e tom substituem explicitamente somente as respectivas diretivas, sem deduplicação automática; o restante do documento é preservado. Quando `appcifras_id` estiver presente, deve continuar único, válido e coerente com a identidade da Música.

Diretivas internas do AppCifras, como `appcifras_schema` e `appcifras_id`, não são conteúdo editável pelo usuário. A interface apresenta apenas metadados funcionais e conteúdo musical; identidade e schema são preservados ou reaplicados pela aplicação e persistência. Diretivas reservadas coladas manualmente na área editável são ignoradas antes da reconstrução do documento canônico.

Na reanálise de música existente, ChordPro e rótulos já presentes são preservados exatamente. Somente pares inequívocos de linha textual de acordes e letra, sem marcação ChordPro, podem ser convertidos; em caso de dúvida, o conteúdo é preservado.

O usuário não deve precisar conhecer ChordPro para operações comuns de entrada e edição. ChordPro permanece canônico, mas sua sintaxe técnica não é requisito cotidiano. Futuramente, a edição permitirá reanálise e conversão segura de alterações textuais, preservando trechos ChordPro já válidos.
