# **MODELO DE DOMÍNIO - v2.0**

# **Capítulo 1 --- Estrutura e Fundamentos**

## 1.1 Objetivo

O Modelo de Domínio define a representação conceitual do Aplicativo de
Cifras Musicais.

Seu propósito é estabelecer uma linguagem única para o projeto,
descrevendo os conceitos fundamentais do domínio, seus relacionamentos,
responsabilidades e regras permanentes, independentemente da tecnologia
utilizada ou da forma de implementação.

Este documento constitui a principal referência para o desenvolvimento
do núcleo do sistema e deverá ser utilizado como base para a
Especificação Funcional, Arquitetura do Sistema e Modelo de Dados.

## 1.2 Escopo

Este documento descreve exclusivamente os elementos pertencentes ao
domínio do problema.

São abordados:

-   Entidades;

-   Objetos de Valor;

-   Serviços de Domínio;

-   Enumerações;

-   Agregados;

-   Relacionamentos;

-   Regras do Domínio;

-   Decisões conceituais.

Não fazem parte deste documento:

-   

-   fluxo de telas;

-   experiência do usuário;

-   arquitetura técnica;

-   persistência de dados;

-   APIs;

-   tecnologias utilizadas;

-   detalhes de implementação.Esses assuntos serão tratados em
    documentos específicos.

## 1.3 Papel na Documentação do Projeto

O Modelo de Domínio ocupa posição central na documentação do sistema.

Sua responsabilidade é definir **o que existe no domínio**, enquanto os
demais documentos descrevem **como o sistema se comporta** ou **como
será implementado**.

A relação entre os documentos é a seguinte:

  -----------------------------------------------------------------------
  **Documento**              **Responsabilidade**
  -------------------------- --------------------------------------------
  Princípios do Projeto      Define a filosofia e os princípios
                             permanentes do projeto.

  Modelo de Domínio          Define os conceitos do negócio e seus
                             relacionamentos.

  Especificação Funcional    Define o comportamento esperado pelo
                             usuário.

  Arquitetura do Sistema     Define como os conceitos do domínio serão
                             implementados.

  Modelo de Dados            Define a persistência das informações.

  Backlog do Produto         Organiza a evolução funcional do sistema.
  -----------------------------------------------------------------------

Sempre que houver conflito entre documentos, a definição dos conceitos
do domínio prevalecerá sobre as demais.

Para decisões de escopo e simplificações temporárias do MVP, prevalece
`docs/decisoes-mvp.md`. Esse documento não altera os conceitos
musicais permanentes: define somente o recorte aprovado para a primeira
versão funcional.

## 1.4 Filosofia do Domínio

O sistema não gerencia arquivos de cifras.

[O sistema gerencia **conhecimento musical**.]{.mark}

Essa distinção orienta todas as decisões de modelagem.

Uma música não é representada como um documento textual contendo
acordes, mas como uma estrutura organizada composta por conceitos
musicais.

[Consequentemente:]{.mark}

-   [acordes não são tratados como texto;]{.mark}

-   [tonalidades não são tratadas como texto;]{.mark}

-   [graus harmônicos não são tratados como texto;]{.mark}

-   [a renderização é apenas uma forma de apresentação da estrutura
    musical.]{.mark}

Todo processamento realizado pelo sistema deverá preservar essa
separação entre representação e apresentação.

## 1.5 (Ref) Linguagem Ubíqua (Glossário)

Todos os participantes do projeto deverão utilizar a mesma terminologia
ao se referirem aos conceitos do domínio.

Essa padronização reduz ambiguidades e facilita a comunicação entre
analistas, desenvolvedores, testadores e futuros mantenedores do
sistema.

Os principais termos utilizados neste documento são:

  -----------------------------------------------------------------------
  **Termo**           **Definição**
  ------------------- ---------------------------------------------------
  Biblioteca Musical  Repositório que reúne todas as músicas pertencentes
                      ao usuário.

  Música              Representação de uma composição musical cadastrada
                      na biblioteca.

  Lista de Culto      Sequência organizada de músicas destinada a uma
                      ocasião específica.

  Item da Lista       Referência de uma Música dentro de uma Lista de
                      Culto.

  Registro de Tom     Histórico de tonalidades utilizadas para
                      determinada música.

  Letra               Estrutura textual organizada da música.

  Seção               Unidade estrutural da música, como verso, refrão ou
                      ponte.

  Linha               Organização espacial de uma seção da letra.

  Segmento Musical    Menor unidade semântica da composição, associando
                      texto e acorde.

  Acorde              Representação estruturada de um acorde musical.

  Tom                 Representação da tonalidade da música.

  Grau Harmônico      Representação funcional de um acorde em determinado
                      tom.
  -----------------------------------------------------------------------

Este glossário será expandido sempre que novos conceitos forem
incorporados ao domínio.

## 1.6 Princípios de Modelagem

O Modelo de Domínio deverá observar permanentemente os seguintes
princípios.

### 1. Conhecimento Musical acima da Representação

O domínio representa conceitos musicais, e não apenas caracteres
armazenados em um arquivo.

### 2. Fonte Única da Verdade

Cada informação possui um único local oficial de definição.

Nenhum conceito deverá ser duplicado em diferentes partes do sistema.

### 3. Separação entre Domínio e Interface

O domínio não possui qualquer dependência da interface gráfica.

Mudanças na apresentação jamais poderão alterar a estrutura do domínio.

### 4. Separação entre Dados e Comportamentos

Entidades e Objetos de Valor representam informações.

Processamentos complexos pertencem aos Serviços de Domínio.

### 5. Objetos de Valor Preferencialmente Imutáveis

Sempre que possível, Objetos de Valor deverão ser tratados como
estruturas imutáveis.

Alterações deverão resultar na criação de novas instâncias.

### 6. Evolução sem Ruptura

Novas funcionalidades deverão ampliar o domínio existente sem
comprometer sua consistência.

Mudanças incompatíveis somente poderão ocorrer mediante revisão formal
da documentação.

## 1.7 Convenções de Modelagem

Para manter uniformidade, todos os elementos do domínio seguirão um
padrão de documentação.

### Entidades

Cada Entidade será descrita por:

-   Finalidade;

-   Responsabilidades;

-   Identidade;

-   Atributos obrigatórios;

-   Atributos opcionais;

-   Relacionamentos;

-   Cardinalidades;

-   Regras específicas;

-   Observações arquiteturais.

### Objetos de Valor

Cada Objeto de Valor será descrito por:

-   Finalidade;

-   Estrutura;

-   Responsabilidades;

-   Regras;

-   Exemplos;

-   Observações.

### Serviços de Domínio

Cada Serviço de Domínio será descrito por:

-   Finalidade;

-   Responsabilidades;

-   Operações realizadas;

-   Regras de negócio envolvidas;

-   Dependências do domínio.

## 1.8 Organização do Documento

Este documento está estruturado da seguinte forma:

1.  Estrutura e Fundamentos e Linguagem Ubíqua

2.  Entidades

3.  Objetos de Valor

4.  Serviços de Domínio

5.  Enumerações

6.  Agregados

7.  Regras do Domínio

8.  Diagramas UML

9.  Decisões Arquiteturais

Cada capítulo possui responsabilidade própria e não deve duplicar
informações pertencentes a outro capítulo.

# **Capítulo 2 -- Entidades**

## 2.1 Conceito

Entidades são objetos do domínio que possuem identidade própria e
persistente.

Sua existência não depende exclusivamente dos valores de seus atributos.
Mesmo que suas propriedades sejam alteradas ao longo do tempo, continuam
representando o mesmo conceito dentro do domínio.

No Aplicativo de Cifras Musicais, as entidades representam os principais
elementos gerenciados pelo usuário, como músicas, listas e histórico de
execuções.

As entidades definidas neste domínio são:

-   Biblioteca Musical;

-   Música;

-   Lista de Culto;

-   Item da Lista;

-   Registro de Tom;

-   Coleção;

-   Tag;

-   Fonte de Sincronização.

## 2.2 Biblioteca Musical

Finalidade

A Biblioteca Musical representa o repertório completo do usuário.

Ela constitui o principal ponto de acesso às músicas cadastradas e
organiza todos os elementos permanentes do domínio musical.

[A Biblioteca Musical não representa uma pasta do sistema operacional
nem um diretório físico de arquivos.]{.underline} Seu papel é reunir
conhecimento musical de forma independente da origem dos dados.

Responsabilidades

Compete à Biblioteca Musical:

-   manter o conjunto de músicas do usuário;

-   disponibilizar músicas para Listas de Culto;

-   organizar Coleções;

-   disponibilizar mecanismos de pesquisa;

-   manter vínculo com Fontes de Sincronização;

-   fornecer informações estatísticas do repertório.

Não compete à Biblioteca Musical:

-   renderizar cifras;

-   realizar transposição;

-   interpretar acordes;

-   calcular graus harmônicos.

Essas responsabilidades pertencem aos Serviços de Domínio.

Identidade

**Identificador único**

-   Id

Embora normalmente exista apenas uma Biblioteca Musical por usuário, o
modelo admite múltiplas bibliotecas caso essa funcionalidade seja
incorporada futuramente.

Atributos obrigatórios

-   Id

-   Nome

Atributos opcionais

-   Descrição

-   Data de criação

-   Data da última sincronização

Os seguintes atributos são derivados e não precisam ser armazenados:

-   Quantidade de músicas

-   Quantidade de listas

-   Quantidade de coleções

Relacionamentos

Uma Biblioteca Musical:

-   contém diversas Músicas;

-   contém diversas Listas de Culto;

-   contém diversas Coleções;

-   utiliza uma ou mais Fontes de Sincronização.

Cardinalidades

Biblioteca Musical

1 ───── N Música

1 ───── N Lista de Culto

1 ───── N Coleção

1 ───── N Fonte de Sincronização

Regras do Domínio

Toda Música pertence exatamente a uma Biblioteca Musical.

Não existem músicas desvinculadas de uma Biblioteca.

A exclusão da Biblioteca implica a remoção lógica dos elementos que lhe
pertencem.

Observações

A Biblioteca Musical constitui o principal **Aggregate Root** do
domínio.

## 2.3 Música

Finalidade

A Música representa uma composição musical cadastrada na Biblioteca
Musical.

É a entidade central do domínio e concentra todas as informações
permanentes relacionadas a uma composição.

[Uma Música não representa um arquivo de cifra.]{.underline}

Ela representa uma composição musical estruturada, composta por
metadados e Objetos de Valor que descrevem seu conteúdo musical.

Responsabilidades

Compete à Música:

-   armazenar seus metadados;

-   manter sua Letra;

-   preservar o Tom Original;

-   disponibilizar informações para pesquisa;

-   participar de Listas de Culto;

-   manter o Histórico de Tons utilizados.

Não compete à Música:

-   realizar transposição;

-   calcular graus;

-   interpretar campo harmônico;

-   renderizar a cifra.

Essas operações pertencem aos Serviços de Domínio.

Identidade

**Identificador único**

-   Id

A identidade da Música permanece a mesma independentemente da origem do
arquivo utilizado para sua importação.

Atributos obrigatórios

-   Id

-   Título

-   Tom Original

-   Letra

Atributos opcionais

Identificação

-   Subtítulo

-   Artista

-   Compositor

-   Álbum

-   Ministério

-   Idioma

Informações Musicais

-   BPM

-   Compasso

-   Duração

-   Nível de Energia

Organização

-   Tags

-   Coleções

Histórico

-   Data da criação

-   Data da última alteração

-   Data da última execução

-   Quantidade de execuções

Observações

-   Comentários

-   Notas do usuário

Objetos de Valor relacionados

A Música é composta por:

-   Letra;

-   Tom;

-   Grau Harmônico (quando calculado para determinado contexto).

Relacionamentos

Uma Música:

-   pertence a uma Biblioteca Musical;

-   participa de diversas Listas de Culto;

-   possui diversos Registros de Tom;

-   pertence a diversas Coleções;

-   possui diversas Tags.

Cardinalidades

Biblioteca Musical

1 ───── N Música

Música

1 ───── N Registro de Tom

N ───── N Lista de Culto

N ───── N Coleção

N ───── N Tag

Regras do Domínio

O Tom Original nunca poderá ser alterado por operações de transposição.

A Letra representa a composição oficial da Música e permanece inalterada
durante mudanças de tonalidade.

Todo histórico de utilização deve ser registrado por meio de Registros
de Tom, sem modificar os atributos permanentes da Música.

Observações

[A Música constitui um **Aggregate Root**.]{.underline}

Os Objetos de Valor que compõem sua estrutura não existem
independentemente dela.

## 2.4 Lista de Culto

Finalidade

A Lista de Culto representa um conjunto ordenado de músicas preparado
para uma ocasião específica.

Sua finalidade é organizar o repertório de execução sem alterar as
informações permanentes das músicas.

Uma Lista de Culto representa um **contexto de utilização**, e não uma
classificação permanente da Biblioteca Musical.

Responsabilidades

Compete à Lista de Culto:

-   organizar a sequência de execução das músicas;

-   armazenar informações específicas do evento;

-   permitir configurações próprias para cada apresentação;

-   preservar a ordem definida pelo usuário;

-   disponibilizar o repertório para navegação durante a execução.

Não compete à Lista de Culto alterar qualquer informação permanente da
Música.

Identidade

**Identificador único**

-   Id

Atributos obrigatórios

-   Id

-   Nome

Atributos opcionais

-   Descrição

-   Data

-   Local

-   Responsável

-   Tema

-   Observações

-   Data de criação

-   Data da última alteração

Relacionamentos

Uma Lista de Culto:

-   pertence a uma Biblioteca Musical;

-   contém diversos Itens da Lista.

Cardinalidades

Biblioteca Musical

1 ───── N Lista de Culto

Lista de Culto

1 ───── N Item da Lista

Regras do Domínio

A ordem dos Itens possui significado e deve ser preservada.

Uma mesma Música poderá aparecer mais de uma vez na mesma Lista.

Cada ocorrência constitui um Item independente.

Observações

A Lista de Culto constitui um **Aggregate Root**.

Todas as alterações em seus Itens devem ocorrer através dela.

## 2.5 Item da Lista

Finalidade

Representar a participação de uma Música em determinada Lista de Culto.

Essa separação evita duplicação de informações e permite que uma mesma
Música seja utilizada inúmeras vezes em diferentes contextos.

Responsabilidades

Compete ao Item:

-   referenciar uma Música;

-   definir sua posição na Lista;

-   armazenar configurações específicas daquela execução;

-   registrar observações particulares.

Identidade

**Identificador único**

-   Id

Atributos obrigatórios

-   Id

-   Música

-   Ordem

Atributos opcionais

-   Tom utilizado na execução

-   Observações

-   Tempo estimado

-   Notas do ministro

-   Indicação de início automático (futuro)

Objetos de Valor relacionados

-   Tom

Relacionamentos

Cada Item:

-   pertence a uma Lista de Culto;

-   referencia exatamente uma Música.

Cardinalidades

Lista de Culto

1 ───── N Item

Item

N ───── 1 Música

Regras do Domínio

Alterar o Tom utilizado pelo Item jamais altera o Tom Original da
Música.

Excluir um Item nunca remove a Música da Biblioteca.

## 2.6 Registro de Tom

Finalidade

Representar um registro histórico de tonalidade utilizada durante a
execução de uma Música.

Essa entidade preserva o histórico musical do ministério, permitindo
reutilização futura das tonalidades mais adequadas.

Responsabilidades

Compete ao Registro de Tom:

-   armazenar o Tom utilizado;

-   registrar o contexto da execução;

-   preservar histórico de apresentações;

-   fornecer informações para futuras recomendações.

Identidade

**Identificador único**

-   Id

Atributos obrigatórios

-   Id

-   Tom

-   Data da execução

Atributos opcionais

-   Ministrante

-   Evento

-   Observações

-   Lista de Culto relacionada

Objetos de Valor relacionados

-   Tom

Relacionamentos

Cada Registro:

-   pertence exatamente a uma Música.

Cardinalidades

Música

1 ───── N Registro de Tom

Regras do Domínio

O Registro nunca modifica o Tom Original da Música.

Seu objetivo é exclusivamente histórico.

Observações

No futuro poderá servir de base para funcionalidades inteligentes, como
sugestões automáticas de tonalidade.

## 2.7 Coleção

Finalidade

Representar agrupamentos permanentes definidos pelo usuário.

Enquanto as Listas representam eventos específicos, as Coleções
representam classificações permanentes.

Exemplos

-   Natal

-   Páscoa

-   Ceia

-   Jovens

-   Conferência

-   Acústico

Responsabilidades

-   organizar repertórios permanentes;

-   facilitar pesquisas;

-   evitar duplicação de músicas.

Identidade

**Identificador único**

-   Id

Atributos

-   Id

-   Nome

-   Descrição (opcional)

Relacionamentos

Uma Coleção pode conter diversas Músicas.

Uma Música pode pertencer a diversas Coleções.

Cardinalidades

Coleção

N ───── N Música

Regras do Domínio

A exclusão de uma Coleção não altera as Músicas pertencentes a ela.

## 2.8 Tag

Finalidade

Representar classificações livres atribuídas pelo usuário.

As Tags complementam as Coleções, oferecendo uma organização mais
flexível.

Exemplos

-   Adoração

-   Oferta

-   Missões

-   Comunhão

-   Ceia

-   Gratidão

Responsabilidades

-   classificar músicas;

-   facilitar pesquisas;

-   permitir filtros personalizados.

Identidade

**Identificador único**

-   Id

Relacionamentos

Uma Tag pode estar associada a diversas Músicas.

Uma Música pode possuir diversas Tags.

Cardinalidades

Tag

N ───── N Música

Regras do Domínio

Tags não possuem hierarquia.

O sistema não diferencia Tags criadas pelo usuário e Tags importadas.

## 2.9 Fonte de Sincronização

Finalidade

Representar uma origem externa responsável por importar ou atualizar
músicas na Biblioteca Musical.

Embora esteja relacionada à infraestrutura da aplicação, essa entidade
faz parte do domínio por influenciar diretamente o gerenciamento do
repertório.

Responsabilidades

Compete à Fonte de Sincronização:

-   identificar a origem dos dados;

-   armazenar suas configurações;

-   registrar o estado da sincronização;

-   disponibilizar informações para importação e atualização.

Identidade

**Identificador único**

-   Id

Atributos

-   Id

-   Nome

-   Tipo

-   Caminho ou Identificador

-   Status

-   Data da última sincronização

Exemplos

-   Pasta Local

-   Google Drive

-   Dropbox

-   OneDrive

-   GitHub

-   Servidor Próprio

Regras do Domínio

A remoção de uma Fonte de Sincronização não implica a exclusão das
Músicas já importadas.

## 2.10 Considerações sobre as Entidades

As entidades definidas nos Capítulos 2 e 3 representam todos os objetos
do domínio que possuem identidade própria e ciclo de vida independente.

Cada uma possui uma responsabilidade clara e bem delimitada:

-   **Biblioteca Musical** organiza o repertório.

-   **Música** representa a composição musical.

-   **Lista de Culto** organiza músicas para eventos específicos.

-   **Item da Lista** representa a participação de uma Música em uma
    Lista.

-   **Registro de Tom** preserva o histórico de execuções.

-   **Coleção** organiza repertórios permanentes.

-   **Tag** oferece classificação flexível.

-   **Fonte de Sincronização** integra o domínio com repositórios
    externos.

Nenhuma dessas entidades contém regras de processamento musical, como
transposição ou cálculo de graus. Essas responsabilidades serão tratadas
exclusivamente pelos **Serviços de Domínio**, preservando a separação
entre **estado** e **comportamento**, conforme os princípios do
Domain-Driven Design.

# **[Capítulo 3 -- Objetos de Valor]{.mark}** 

## 3.1 Conceito

Objetos de Valor (Value Objects) representam conceitos do domínio que
não possuem identidade própria.

Sua existência é definida exclusivamente pelos valores que carregam e
pelo significado que representam dentro do domínio.

Diferentemente das Entidades, Objetos de Valor:

-   não possuem ciclo de vida independente;

-   não são identificados por um ID;

-   podem ser substituídos integralmente quando seu conteúdo muda;

-   existem apenas como parte de uma Entidade ou de outro Objeto de
    Valor.

No Aplicativo de Cifras Musicais, os Objetos de Valor representam
conceitos musicais fundamentais, como a estrutura da letra, acordes,
tonalidades e graus harmônicos.

Os Objetos de Valor definidos neste domínio são:

-   Letra;

-   Seção;

-   Linha;

-   Segmento Musical;

-   Acorde;

-   Tom;

-   Nota Musical;

-   Grau Harmônico.

## 3.2 Letra

**Finalidade**

A Letra representa a estrutura textual completa de uma Música.

Ela organiza o conteúdo da composição em unidades estruturadas,
preservando seu significado musical independentemente da forma de
apresentação.

A Letra existe exclusivamente como parte de uma Música.

**Por que é um Objeto de Valor?**

A Letra não possui identidade própria.

Se todo o seu conteúdo for substituído por outro equivalente, continua
representando a mesma composição pertencente à Música.

Sua existência depende integralmente da Entidade Música.

**Estrutura**

Uma Letra é composta por:

-   Seções.

**Responsabilidades**

Compete à Letra:

-   organizar a composição;

-   preservar sua estrutura;

-   servir como base para renderização;

-   permitir diferentes formas de apresentação.

**Regras**

A estrutura da Letra nunca é modificada por operações de transposição.

Mudanças de tonalidade alteram apenas os acordes dos Segmentos Musicais.

## 3.3 Seção

**Finalidade**

Representar uma unidade estrutural da composição.

Cada Seção agrupa linhas que desempenham uma mesma função musical.

**Exemplos**

-   Introdução

-   Verso

-   Pré-Refrão

-   Refrão

-   Ponte

-   Solo

-   Instrumental

-   Final

**Por que é um Objeto de Valor?**

Uma Seção não possui existência própria.

Seu significado depende exclusivamente da Letra à qual pertence.

**Estrutura**

Cada Seção possui:

-   Tipo;

-   Ordem;

-   Linhas.

**Responsabilidades**

-   organizar partes da composição;

-   preservar a sequência estrutural;

-   facilitar navegação e renderização.

**Regras**

A ordem das Seções deve ser preservada.

Uma Música pode conter várias Seções do mesmo tipo.

## 3.4 Linha

**Finalidade**

Representar uma linha da composição.

A Linha organiza Segmentos Musicais em sequência.

**Por que é um Objeto de Valor?**

Uma Linha não possui identidade nem significado independente.

Ela existe apenas dentro de uma Seção.

**Estrutura**

Cada Linha contém:

-   ordem;

-   Segmentos Musicais.

**Responsabilidades**

-   organizar a disposição dos segmentos;

-   preservar a sequência textual.

**Regras**

A Linha não representa uma unidade musical.

Ela representa apenas organização estrutural.

## 3.5 Segmento Musical

**Finalidade**

Representar a menor unidade semântica da música.

Cada Segmento associa um trecho da letra às informações musicais
correspondentes.

**Por que é um Objeto de Valor?**

O Segmento Musical existe apenas como parte de uma Linha.

Não possui identidade própria e pode ser reconstruído integralmente sem
alterar a identidade da Música.

**Estrutura**

Cada Segmento possui:

-   Texto;

-   Acorde (opcional).

No futuro poderá armazenar:

-   marcações de dinâmica;

-   indicação vocal;

-   comentários técnicos;

-   marcações para IA.

**Responsabilidades**

Compete ao Segmento:

-   associar texto e acorde;

-   preservar a posição relativa na Linha;

-   servir como unidade básica de renderização.

**Exemplo**

\[G\]Grandes \[Em\]são Tuas obras

Representação lógica:

Segmento 1

Texto: \"Grandes\"

Acorde: G

Segmento 2

Texto: \"são\"

Acorde: Em

Segmento 3

Texto: \"Tuas obras\"

Acorde: ---

**Regras**

O texto e o acorde pertencem ao mesmo Segmento.

Nenhum acorde pode existir desacoplado de um Segmento Musical.

## 3.6 Acorde

**Finalidade**

Representar um acorde musical de forma estruturada.

O Acorde descreve sua composição musical e não apenas sua representação
textual.

**Por que é um Objeto de Valor?**

Dois acordes estruturalmente iguais representam exatamente o mesmo
conceito musical, independentemente de onde são utilizados.

Não existe identidade individual para um acorde.

**Estrutura**

Um Acorde é composto por:

-   Nota Fundamental;

-   Qualidade;

-   Extensões;

-   Alterações;

-   Suspensões;

-   Baixo (opcional).

**Exemplos**

-   C

-   Am

-   G/B

-   Cadd9

-   Dsus4

-   F#m7(b5)

**Responsabilidades**

-   representar harmonicamente um acorde;

-   permitir transposição;

-   permitir cálculo de graus;

-   servir como base para renderização.

**Regras**

O Acorde deve permanecer independente de sua representação textual.

Sua estrutura é a fonte oficial da informação.

## 3.7 Tom

**Finalidade**

Representar a tonalidade de referência utilizada em uma Música ou em uma
execução específica.

**Por que é um Objeto de Valor?**

Dois Tons iguais representam exatamente a mesma tonalidade.

Não existe identidade individual para um Tom.

**Estrutura**

Cada Tom possui:

-   Nota Fundamental;

-   Modo.

**Modos suportados**

-   Maior;

-   Menor.

O modelo admite expansão futura para modos gregos e outros sistemas
tonais.

**Responsabilidades**

-   servir de referência para transposição;

-   permitir cálculo dos graus harmônicos.

**Regras**

O Tom representa apenas uma tonalidade.

As relações entre acordes pertencem aos Serviços de Domínio.

## 3.8 Nota Musical

**Finalidade**

Representar uma nota da escala cromática.

**Por que é um Objeto de Valor?**

Uma Nota é completamente definida por seus atributos.

Não possui identidade independente.

**Estrutura**

Cada Nota possui:

-   Nome;

-   Alteração.

**Exemplos**

-   C

-   C#

-   Db

-   Eb

-   F#

-   Bb

**Responsabilidades**

-   representar notas musicais;

-   servir de base para construção dos acordes;

-   permitir cálculos de transposição.

**Regras**

Notas enarmônicas representam o mesmo som, mas podem possuir grafias
distintas.

A escolha da grafia adequada é responsabilidade dos Serviços de Domínio.

**4.9 Grau Harmônico**

**Finalidade**

Representar a função harmônica exercida por um acorde em relação a um
Tom específico.

**Por que é um Objeto de Valor?**

O Grau é definido exclusivamente pela combinação entre um acorde e um
contexto tonal.

Não possui identidade própria nem existência independente.

**Estrutura**

Cada Grau possui:

-   Número;

-   Representação romana;

-   Qualidade harmônica.

**Exemplos**

-   I

-   ii

-   iii

-   IV

-   V

-   vi

-   vii°

**Responsabilidades**

-   representar a função harmônica de um acorde;

-   permitir diferentes formas de exibição da música.

**Regras**

O mesmo acorde pode representar graus diferentes conforme o Tom
utilizado.

Exemplo:

  -----------------------------------------------------------------------
  **Tom**               **Acorde**                **Grau**
  --------------------- ------------------------- -----------------------
  G                     G                         I

  C                     G                         V

  D                     G                         IV
  -----------------------------------------------------------------------

## 3.10 Considerações sobre os Objetos de Valor

Os Objetos de Valor representam a essência do conhecimento musical
tratado pelo sistema. Eles não possuem identidade própria, mas carregam
significado e regras que permanecem consistentes independentemente da
tecnologia utilizada ou da forma de apresentação.

Essa modelagem permite que funcionalidades como transposição, exibição
por graus harmônicos, sincronização, exportação e futuras análises
inteligentes sejam implementadas sobre uma estrutura musical sólida,
preservando a separação entre [**dados** (Objetos de Valor) e
**comportamentos** (Serviços de Domínio).]{.mark}

# **Capítulo 4 -- Serviços de Domínio**

## 4.1 Conceito

Serviços de Domínio encapsulam regras de negócio e operações que não
pertencem naturalmente a uma Entidade ou a um Objeto de Valor
específico.

Um Serviço de Domínio representa um comportamento do sistema que depende
da interação entre múltiplos conceitos do domínio ou da aplicação de
regras musicais complexas.

Os Serviços de Domínio:

-   não possuem identidade;

-   não armazenam estado permanente;

-   são preferencialmente **stateless**;

-   operam sobre Entidades e Objetos de Valor;

-   preservam a consistência das regras do domínio.

No Aplicativo de Cifras Musicais, os Serviços de Domínio concentram todo
o processamento musical, mantendo as Entidades e Objetos de Valor
focados apenas na representação dos conceitos do negócio.

Os serviços atualmente definidos são:

-   Serviço de Transposição;

-   Serviço de Campo Harmônico;

-   Serviço de Graus Harmônicos;

-   Serviço de Normalização de Acordes.

## 4.2 Serviço de Transposição

**Finalidade**

Realizar a transposição de acordes e tonalidades entre diferentes tons,
preservando a estrutura musical da composição.

**Responsabilidades**

Compete ao Serviço de Transposição:

-   transpor acordes;

-   transpor tonalidades;

-   preservar a qualidade dos acordes;

-   respeitar inversões;

-   manter extensões e alterações;

-   preservar a estrutura da Letra.

**Entradas**

-   Música (ou Letra);

-   Tom de origem;

-   Tom de destino.

**Saída**

Uma nova representação musical contendo os acordes transpostos.

A Música original nunca deve ser modificada.

**Regras do Domínio**

A transposição altera exclusivamente os acordes.

Nenhum trecho textual poderá ser modificado.

O Tom Original da Música permanece inalterado.

As relações entre os acordes devem ser preservadas.

**Exemplo**

Antes:

Tom: G

\[G\]Grandes são Tuas obras

\[Em\]Senhor

Após transposição para A:

Tom: A

\[A\]Grandes são Tuas obras

\[F#m\]Senhor

## 4.3 Serviço de Campo Harmônico

**Finalidade**

Determinar os acordes pertencentes ao campo harmônico de uma determinada
tonalidade.

**Responsabilidades**

Compete ao Serviço de Campo Harmônico:

-   construir campos harmônicos maiores;

-   construir campos harmônicos menores;

-   identificar acordes diatônicos;

-   disponibilizar acordes por grau.

**Entradas**

-   Tom.

**Saída**

Lista ordenada de acordes pertencentes ao campo harmônico.

**Exemplo**

Tom de C Maior:

  -----------------------------------------------------------------------
  **Grau**                              **Acorde**
  ------------------------------------- ---------------------------------
  I                                     C

  ii                                    Dm

  iii                                   Em

  IV                                    F

  V                                     G

  vi                                    Am

  vii°                                  Bdim
  -----------------------------------------------------------------------

**Regras do Domínio**

O cálculo deve respeitar a teoria musical adotada pelo sistema.

O Serviço não altera qualquer Entidade.

## 4.4 Serviço de Graus Harmônicos

**Finalidade**

Converter acordes em graus harmônicos e realizar a operação inversa.

**Responsabilidades**

Compete ao Serviço:

-   identificar o grau de um acorde;

-   converter graus em acordes;

-   permitir visualização da música em números romanos;

-   fornecer suporte ao Nashville Number System.

**Entradas**

-   Tom;

-   Acorde (ou Grau).

**Saída**

Grau correspondente ou acorde correspondente.

**Exemplo**

Tom: G

  -----------------------------------------------------------------------
  **Acorde**                             **Grau**
  -------------------------------------- --------------------------------
  G                                      I

  Am                                     ii

  Bm                                     iii

  C                                      IV

  D                                      V

  Em                                     vi
  -----------------------------------------------------------------------

**Regras do Domínio**

O Grau depende sempre do Tom informado.

O mesmo acorde pode produzir resultados diferentes em tonalidades
distintas.

## 4.5 Serviço de Normalização de Acordes

**Finalidade**

Padronizar a representação dos acordes, garantindo consistência entre
importação, armazenamento e exibição.

**Responsabilidades**

Compete ao Serviço:

-   reconhecer grafias equivalentes;

-   padronizar nomenclaturas;

-   remover ambiguidades;

-   validar acordes;

-   converter representações externas para o formato interno.

**Exemplos**

  -----------------------------------------------------------------------
  **Entrada**                 **Representação Normalizada**
  --------------------------- -------------------------------------------
  Cmaj7                       Cmaj7

  CM7                         Cmaj7

  CΔ7                         Cmaj7

  C7M                         Cmaj7

  C+                          Caug

  C°                          Cdim
  -----------------------------------------------------------------------

**Regras do Domínio**

A normalização nunca altera o significado harmônico do acorde.

Ela modifica apenas sua representação.

## 4.6 Relacionamento entre os Serviços

Os Serviços de Domínio atuam de forma complementar.

Em diversas funcionalidades eles poderão ser utilizados em conjunto.

Exemplo:

Importação de Música

│

▼

Normalização de Acordes

│

▼

Transposição

│

▼

Campo Harmônico

│

▼

Graus Harmônicos

│

▼

Renderização

Essa sequência representa um fluxo lógico de processamento. A
implementação poderá utilizar apenas os serviços necessários para cada
caso de uso.

## 4.7 Evolução dos Serviços

O conjunto de Serviços de Domínio poderá ser ampliado sem necessidade de
alterar as Entidades ou os Objetos de Valor.

Exemplos de serviços previstos para versões futuras:

-   Serviço de Detecção Automática de Tom;

-   Serviço de Análise Harmônica;

-   Serviço de Sugestão de Modulação;

-   Serviço de Simplificação de Acordes;

-   Serviço de Validação Musical;

-   Serviço de Geração de Campo Harmônico Modal;

-   Serviço de Recomendação de Tonalidade com base no histórico de
    execuções;

-   Serviço de Identificação de Progressões Harmônicas.

A inclusão de novos serviços deverá respeitar os princípios
estabelecidos neste Modelo de Domínio.

## 4.8 Considerações Finais

Os Serviços de Domínio concentram todo o comportamento musical do
sistema, mantendo as Entidades e Objetos de Valor livres de regras
complexas e focados apenas na representação do conhecimento musical.

Essa separação favorece a reutilização das regras de negócio, simplifica
os testes, reduz o acoplamento entre componentes e permite a evolução
independente das estruturas de dados e dos algoritmos de processamento.

# **Capítulo 5 -- Agregados**

## (DÚVIDA) 5.1 Conceito

Um Agregado (Aggregate) é um conjunto de objetos do domínio que deve ser
tratado como uma única unidade de consistência.

Cada agregado possui uma Entidade Raiz (**Aggregate Root**), responsável
por controlar o acesso aos demais objetos que o compõem e garantir o
cumprimento das regras de negócio.

Objetos internos ao agregado não devem ser manipulados diretamente por
outros agregados.

Toda alteração em um agregado deve ocorrer por meio de sua Raiz.

Essa abordagem reduz o acoplamento entre componentes do domínio e
preserva a consistência das regras de negócio.

## 5.2 Agregado Biblioteca Musical

**Aggregate Root**

**Biblioteca Musical**

**Objetivo**

Representar o repositório lógico que organiza todo o repertório
pertencente ao usuário.

A Biblioteca é responsável apenas pela organização geral dos elementos
do domínio.

**Elementos pertencentes**

-   Música

-   Lista de Culto

-   Coleção

-   Fonte de Sincronização

**Limite do Agregado**

Biblioteca Musical

│

├── Música

├── Lista de Culto

├── Coleção

└── Fonte de Sincronização

**Regras de Consistência**

Toda Música pertence exatamente a uma Biblioteca.

Toda Lista pertence exatamente a uma Biblioteca.

Toda Coleção pertence exatamente a uma Biblioteca.

Uma Fonte de Sincronização somente pode existir vinculada a uma
Biblioteca.

**Observação**

A Biblioteca **não controla o conteúdo interno** das Músicas.

Ela apenas mantém o conjunto de músicas pertencentes ao repertório.

## 5.3 Agregado Música

**Aggregate Root**

**Música**

**Objetivo**

Representar uma composição musical completa.

Toda modificação estrutural da composição ocorre através da entidade
Música.

**Elementos pertencentes**

-   Letra

-   Seções

-   Linhas

-   Segmentos Musicais

-   Acordes

-   Tom Original

-   Registro de Tom

**Limite do Agregado**

Música

│

├── Tom Original

├── Letra

│ ├── Seção

│ │ ├── Linha

│ │ │ ├── Segmento Musical

│ │ │ │ └── Acorde

│

└── Registro de Tom

**Regras de Consistência**

Toda alteração da estrutura da música ocorre pela entidade Música.

Nenhum Objeto de Valor pode existir desacoplado da Música.

A substituição de uma Letra substitui toda sua estrutura interna.

O Tom Original pertence exclusivamente à Música.

**Observação**

A Música é o principal agregado funcional do domínio.

Grande parte dos Serviços de Domínio atua diretamente sobre ela.

## 5.4 Agregado Lista de Culto

**Aggregate Root**

**Lista de Culto**

**Objetivo**

Representar uma sequência organizada de músicas para uma determinada
ocasião.

**Elementos pertencentes**

-   Item da Lista

**Limite do Agregado**

Lista de Culto

│

└── Item da Lista

**Regras de Consistência**

Itens somente podem existir dentro de uma Lista.

A ordem dos Itens deve permanecer consistente.

A exclusão da Lista remove todos os seus Itens.

**Observação**

O Item da Lista não pertence ao agregado Música.

Ele apenas referencia uma Música.

## 5.5 Agregado Coleção

**Aggregate Root**

**Coleção**

**Objetivo**

Organizar grupos permanentes de músicas.

**Elementos pertencentes**

Nenhum.

A Coleção apenas referencia Músicas.

**Observação**

Coleção é um agregado extremamente simples.

Seu relacionamento com Música ocorre apenas por referência.

## 5.6 Agregado Tag

**Aggregate Root**

**Tag**

**Objetivo**

Permitir classificação flexível das músicas.

**Elementos pertencentes**

Nenhum.

A Tag apenas referencia Músicas.

## (DÚVIDA) 5.7 Relacionamentos entre Agregados

Os agregados comunicam-se exclusivamente por meio de suas Entidades
Raiz.

Nenhum agregado acessa diretamente objetos internos pertencentes a outro
agregado.

Biblioteca Musical

│

├────────────► Música

│

├────────────► Lista de Culto

│ │

│ ▼

│ Item da Lista

│ │

│ ▼

│ Música

│

├────────────► Coleção

│ │

│ ▼

│ Música

│

└────────────► Fonte de Sincronização

Essa organização reduz dependências e facilita a evolução independente
dos agregados.

## 5.8 Regras Gerais dos Agregados

O domínio observa as seguintes regras:

-   Toda modificação estrutural deve ocorrer por meio do Aggregate Root.

-   Objetos internos nunca são compartilhados entre agregados.

-   Agregados comunicam-se por referência às suas Entidades Raiz.

-   Objetos de Valor nunca existem fora de um agregado.

-   Serviços de Domínio operam sobre agregados, mas não alteram seus
    limites.

## 5.9 Considerações Arquiteturais

A definição dos agregados estabelece os limites de consistência do
domínio e orienta a implementação da aplicação. Cada agregado representa
uma unidade lógica de alteração, persistência e validação das regras de
negócio.

Ao concentrar o acesso aos objetos internos por meio de suas Entidades
Raiz, o modelo reduz o acoplamento entre componentes, favorece a
manutenção da integridade dos dados e facilita a evolução do sistema.

# **Capítulo 6 -- Regras do Domínio**

## 6.1 Objetivo

As Regras do Domínio definem restrições, invariantes e comportamentos
permanentes que devem ser respeitados por qualquer implementação do
sistema.

Essas regras são independentes da interface, da tecnologia utilizada e
da forma de persistência dos dados.

Toda funcionalidade implementada deverá preservar as regras descritas
neste capítulo.

## 6.2 Regras Gerais

**RG-01 --- Identidade das Entidades**

Toda Entidade deve possuir identidade única e persistente.

A alteração de seus atributos não modifica sua identidade.

**RG-02 --- Objetos de Valor**

Objetos de Valor não possuem identidade própria.

Sua substituição não representa alteração da identidade da Entidade que
os contém.

**RG-03 --- Serviços de Domínio**

Serviços de Domínio não armazenam estado permanente.

Toda informação persistente pertence às Entidades.

**RG-04 --- Imutabilidade dos Objetos de Valor**

Sempre que possível, Objetos de Valor deverão ser tratados como
estruturas imutáveis.

Quando necessário, alterações deverão resultar na criação de uma nova
instância.

## 6.3 Regras da Biblioteca Musical

**RB-01**

Toda Música pertence exatamente a uma Biblioteca Musical.

**RB-02**

Não podem existir músicas órfãs.

**RB-03**

Uma Biblioteca pode conter qualquer quantidade de Músicas.

**RB-04**

A exclusão de uma Biblioteca implica a remoção lógica de seus elementos,
conforme a política de persistência adotada pela aplicação.

## 6.4 Regras da Música

**RM-01**

Toda Música possui exatamente um Tom Original.

**RM-02**

Toda Música possui exatamente uma Letra.

**RM-03**

A Letra representa a versão oficial da composição.

**RM-04**

O Tom Original nunca é alterado por operações de transposição.

**RM-05**

Toda alteração estrutural da composição ocorre através da entidade
Música.

**RM-06**

A estrutura da composição permanece inalterada durante operações de
processamento musical.

## 6.5 Regras da Lista de Culto

**RL-01**

Todo Item pertence exatamente a uma Lista.

**RL-02**

Um Item referencia exatamente uma Música.

**RL-03**

Uma mesma Música poderá aparecer diversas vezes na mesma Lista.

Cada ocorrência representa um Item distinto.

**RL-04**

A ordem dos Itens possui significado e deve ser preservada.

## 6.6 Regras do Registro de Tom

**RT-01**

Todo Registro pertence exatamente a uma Música.

**RT-02**

O Registro nunca altera o Tom Original da Música.

**RT-03**

Cada Registro representa apenas uma execução histórica.

## 6.7 Regras dos Objetos de Valor

**RV-01**

Uma Letra sempre pertence exatamente a uma Música.

**RV-02**

Uma Seção sempre pertence exatamente a uma Letra.

**RV-03**

Uma Linha sempre pertence exatamente a uma Seção.

**RV-04**

Um Segmento Musical sempre pertence exatamente a uma Linha.

**RV-05**

Um Acorde somente pode existir associado a um Segmento Musical.

**RV-06**

Todo Tom deve possuir exatamente:

-   Nota Fundamental;

-   Modo.

**RV-07**

Um Grau Harmônico depende obrigatoriamente de um contexto tonal.

## 6.8 Regras de Processamento Musical

**RP-01 --- Transposição**

A transposição modifica exclusivamente os acordes.

**RP-02 --- Estrutura**

A estrutura da música jamais poderá ser alterada por operações de
transposição.

**RP-03 --- Texto**

O conteúdo textual da letra nunca sofre alterações durante processamento
musical.

**RP-04 --- Graus Harmônicos**

O Grau de um acorde depende exclusivamente do Tom utilizado como
referência.

**RP-05 --- Normalização**

A normalização nunca altera o significado harmônico de um acorde.

Ela modifica apenas sua representação.

**RP-06 --- Campo Harmônico**

Todo Campo Harmônico calculado deverá respeitar a teoria musical adotada
pelo sistema.

## 6.9 Regras de Integridade

**RI-01**

Nenhuma referência pode apontar para uma Entidade inexistente.

**RI-02**

Objetos internos de um Agregado não podem ser acessados diretamente por
outro Agregado.

**RI-03**

Toda comunicação entre Agregados ocorre por meio de suas Entidades Raiz.

**RI-04**

Objetos de Valor não podem existir desacoplados de uma Entidade.

**RI-05**

Toda operação deve preservar a consistência do domínio.

## 6.10 Regras de Evolução

O modelo foi concebido para permitir expansão sem ruptura da estrutura
existente.

Novos conceitos deverão observar as seguintes diretrizes:

-   preservar a Linguagem Ubíqua;

-   respeitar os limites dos Agregados;

-   manter a separação entre dados e comportamento;

-   evitar duplicação de responsabilidades;

-   priorizar Objetos de Valor para conceitos sem identidade própria.

Mudanças incompatíveis deverão ser formalmente documentadas antes de sua
incorporação ao domínio.

## 6.11 Considerações Finais

As regras descritas neste capítulo representam os invariantes do domínio
e constituem a principal referência para validação da implementação.

Elas devem orientar a construção de casos de uso, testes automatizados,
validações de negócio e futuras evoluções do sistema, garantindo que o
comportamento da aplicação permaneça consistente independentemente da
tecnologia empregada.

# **Capítulo 7 -- Decisões Arquiteturais**

## 7.1 Objetivo

Este capítulo documenta as principais decisões de modelagem adotadas
durante a construção do Modelo de Domínio.

Seu propósito é registrar o racional por trás dessas escolhas,
facilitando a evolução do sistema e reduzindo o risco de alterações que
comprometam a consistência do domínio.

As decisões aqui descritas não representam regras de negócio, mas
diretrizes de projeto que orientam a implementação e a manutenção da
aplicação.

## 7.2 A Música representa conhecimento musical, não um arquivo

**Decisão**

A entidade **Música** representa uma composição musical estruturada e
não um arquivo de cifra.

**Justificativa**

Arquivos de cifras são apenas uma forma de armazenamento ou intercâmbio
de informações.

O domínio da aplicação trata da composição musical em si,
independentemente de sua origem.

Essa decisão permite:

-   importar diferentes formatos;

-   exportar para novos formatos;

-   alterar a renderização sem alterar o domínio;

-   desacoplar a lógica musical da persistência.

## 7.3 A renderização é separada da representação

**Decisão**

A forma como uma música é exibida não faz parte do Modelo de Domínio.

**Justificativa**

O mesmo conteúdo pode ser apresentado de diversas maneiras:

-   cifra tradicional;

-   somente letra;

-   somente acordes;

-   graus harmônicos;

-   Nashville Number System;

-   projeção para culto;

-   impressão;

-   exportação para PDF.

Todas essas representações utilizam exatamente os mesmos dados do
domínio.

## 7.4 Acorde é um Objeto de Valor

**Decisão**

Acordes não possuem identidade própria.

**Justificativa**

Dois acordes estruturalmente iguais representam exatamente o mesmo
conceito musical.

Criar uma entidade para acordes aumentaria desnecessariamente a
complexidade do domínio.

## 7.5 Tom é um Objeto de Valor

**Decisão**

O Tom representa apenas uma tonalidade.

**Justificativa**

Não existe identidade individual para um Tom.

Sua existência depende exclusivamente do contexto em que é utilizado.

## 7.6 Campo Harmônico é um Serviço de Domínio

**Decisão**

Campo Harmônico não é um objeto armazenado.

É um serviço responsável por realizar cálculos.

**Justificativa**

O Campo Harmônico depende da aplicação de regras da teoria musical sobre
um determinado Tom.

Ele representa comportamento, e não estado.

## 7.7 Graus Harmônicos dependem do contexto tonal

**Decisão**

O Grau Harmônico nunca pertence ao acorde.

**Justificativa**

Um mesmo acorde pode exercer funções diferentes conforme a tonalidade.

Exemplo:

  ------------------------------------------------------------------------
  **Tom**            **Acorde G**                     **Grau**
  ------------------ -------------------------------- --------------------
  G                  G                                I

  C                  G                                V

  D                  G                                IV
  ------------------------------------------------------------------------

Portanto, o Grau é sempre contextual.

## 7.8 A Letra possui estrutura hierárquica

**Decisão**

A Letra não é armazenada como um bloco único de texto.

Ela é organizada em:

-   Seções;

-   Linhas;

-   Segmentos Musicais.

**Justificativa**

Essa estrutura permite:

-   renderização flexível;

-   edição localizada;

-   sincronização;

-   exportação;

-   futuras análises por inteligência artificial.

## 7.9 Segmento Musical é a menor unidade semântica

**Decisão**

O Segmento Musical constitui a menor unidade estrutural do domínio.

**Justificativa**

Ele associa diretamente:

-   texto;

-   acorde.

Essa modelagem evita dependência entre renderização e processamento
musical.

## 7.10 Serviços de Domínio concentram o processamento

**Decisão**

Operações musicais pertencem aos Serviços de Domínio.

**Justificativa**

Entidades e Objetos de Valor permanecem responsáveis apenas pela
representação do estado do domínio.

Essa separação reduz acoplamento e facilita testes.

## 7.11 A transposição não modifica a Música

**Decisão**

Transpor uma música não altera sua estrutura permanente.

**Justificativa**

A transposição representa apenas uma forma alternativa de execução.

A composição permanece exatamente a mesma.

O Tom Original é preservado.

## 7.12 Histórico separado da composição

**Decisão**

Execuções anteriores são registradas por meio da entidade Registro de
Tom.

**Justificativa**

Informações históricas não pertencem à composição musical.

Essa separação mantém a Música estável e preserva o histórico das
apresentações.

## (DÚVIDA) 7.13 Separação entre domínio e infraestrutura

**Decisão**

O Modelo de Domínio não possui dependência de banco de dados, APIs,
interface gráfica ou frameworks.

**Justificativa**

A tecnologia utilizada poderá ser alterada sem necessidade de modificar
os conceitos do domínio.

## 7.14 Preparação para evolução

**Decisão**

O modelo foi projetado para permitir evolução incremental.

**Justificativa**

Novas funcionalidades deverão ser implementadas preferencialmente por
meio da [inclusão de novos Objetos de Valor ou Serviços de
Domínio]{.underline}, preservando as Entidades existentes.

Essa estratégia reduz o impacto das mudanças e favorece a
compatibilidade entre versões.

## 7.15 Considerações Finais

As decisões arquiteturais registradas neste capítulo representam o
entendimento consolidado do domínio no momento da elaboração desta
documentação.

Elas devem servir como referência para futuras evoluções do sistema,
evitando que simplificações de implementação comprometam a integridade
do modelo ou descaracterizem os conceitos definidos neste documento.

# **Capítulo 8 -- Diagramas do Domínio**

## 8.1 Objetivo

Este capítulo apresenta a representação gráfica do Modelo de Domínio.

Os diagramas têm como finalidade complementar a descrição textual dos
capítulos anteriores, oferecendo uma visão integrada das Entidades,
Objetos de Valor, Agregados, Serviços de Domínio e seus relacionamentos.

Os diagramas possuem caráter conceitual e não representam detalhes de
implementação, persistência ou tecnologia.

## 8.2 Mapa Geral do Domínio

Este diagrama apresenta uma visão de alto nível dos principais conceitos
do domínio e da forma como se relacionam.

BIBLIOTECA MUSICAL

│

┌───────────────────────────────────┼──────────────────────────────────────┐

│ │ │

▼ ▼ ▼

MÚSICAS LISTAS DE CULTO COLEÇÕES

│ │

│ │

│ contém vários

│ │

▼ ▼

REGISTROS DE TOM ITENS DA LISTA

▲ │

│ │ referencia

└───────────────────────────────────┘

MÚSICA

▲

│

TAGS

▲

│

FONTES DE SINCRONIZAÇÃO

## 8**.3 Diagrama das Entidades**

Biblioteca Musical

│

├── Música

├── Lista de Culto

├── Coleção

├── Tag

└── Fonte de Sincronização

Lista de Culto

└── Item da Lista

Música

└── Registro de Tom

## 8.4 Diagrama dos Objetos de Valor

Música

│

├── Tom Original

│

└── Letra

│

├── Seção

│ │

│ ├── Linha

│ │ │

│ │ ├── Segmento Musical

│ │ │ │

│ │ │ ├── Texto

│ │ │ └── Acorde

│

└── Estrutura da composição

Acorde

│

├── Nota Fundamental

├── Qualidade

├── Extensões

├── Alterações

└── Baixo

Tom

│

├── Nota

└── Modo

Grau Harmônico

│

├── Grau

├── Representação

└── Qualidade

## 8.5 Diagrama dos Agregados

┌────────────────────────────┐

│ Aggregate │

│ Biblioteca Musical │

└────────────┬───────────────┘

│

├────────► Música

├────────► Lista de Culto

├────────► Coleção

└────────► Fonte de Sincronização

┌────────────────────────────┐

│ Aggregate │

│ Música │

└────────────┬───────────────┘

│

├── Letra

├── Tom

└── Registro de Tom

┌────────────────────────────┐

│ Aggregate │

│ Lista de Culto │

└────────────┬───────────────┘

│

└── Item da Lista

> **Observação:** caso, na revisão arquitetural, a decisão seja remover
> a **Biblioteca Musical** como *Aggregate Root*, este diagrama será
> ajustado para refletir essa alteração.

## 8.6 Diagrama dos Serviços de Domínio

┌──────────────────────────────┐

│ Serviços de Domínio │

├──────────────────────────────┤

│ │

│ Transposição │

│ Campo Harmônico │

│ Graus Harmônicos │

│ Normalização de Acordes │

└──────────────┬───────────────┘

│

┌─────────────────────┼─────────────────────┐

▼ ▼ ▼

Música Objetos de Valor Renderização

## 8.7 Fluxo de Processamento Musical

O processamento musical ocorre de forma lógica, preservando a separação
entre representação e comportamento.

Importação

│

▼

Normalização

│

▼

Modelo de Domínio

│

▼

Transposição

│

▼

Campo Harmônico

│

▼

Graus Harmônicos

│

▼

Renderização

## 8.8 Diagrama UML Simplificado

Biblioteca Musical

──────────────────────────

\+ id

\+ nome

──────────────────────────

1

│

│

├───────────────\*

│

▼

Música

──────────────────────────

\+ id

\+ título

\+ tomOriginal

\+ letra

──────────────────────────

│

├───────────────\*

│

▼

Registro de Tom

Música

\*

│

│

\*──────────────

Lista de Culto

Lista de Culto

1

│

│

\*──────────────

Item da Lista

Música

\*

│

│

\*──────────────

Coleção

Música

\*

│

│

\*──────────────

Tag

## 8.9 Diagrama UML Completo (conceitual)

Biblioteca Musical

├── Música

│ ├── Letra

│ │ ├── Seção

│ │ │ ├── Linha

│ │ │ │ └── Segmento Musical

│ │ │ │ └── Acorde

│ ├── Tom

│ └── Registro de Tom

│

├── Lista de Culto

│ └── Item da Lista

│ └── Música

│

├── Coleção

│ └── Música

│

├── Tag

│ └── Música

│

└── Fonte de Sincronização

## 8.10 Considerações Finais

Os diagramas apresentados neste capítulo sintetizam a estrutura
conceitual do Modelo de Domínio e servem como referência visual para sua
implementação.

Eles não substituem as descrições detalhadas dos capítulos anteriores,
mas as complementam, permitindo compreender rapidamente os principais
elementos do sistema e suas interações.

Todos os diagramas deverão ser mantidos sincronizados com o Modelo de
Domínio sempre que houver evolução dos conceitos ou das regras de
negócio.
