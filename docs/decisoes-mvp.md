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

O formato de intercâmbio e armazenamento da música será **ChordPro**. A aplicação preservará o conteúdo do usuário e poderá gerar uma representação interpretada em memória para renderização, transposição e exibição de graus.

O MVP aceitará somente notações básicas de acordes. A lista exata das notações reconhecidas será definida antes da implementação do parser.

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

A versão mínima do Android será definida durante a configuração do Flutter, considerando a compatibilidade das ferramentas.

## 9. Pendências antes da implementação

- definir a versão mínima de Android;
- especificar a lista de notações básicas aceitas pelo parser ChordPro;
- definir o esquema versionado dos metadados associados ao arquivo ChordPro.
