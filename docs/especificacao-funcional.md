# **Especificação Funcional -- Aplicativo de Cifras para Músicos**

## **1. Objetivo**

Desenvolver um aplicativo para Android (com futura compatibilidade para
iOS) destinado a músicos de igrejas, permitindo gerenciar uma biblioteca
musical, organizar repertórios para cultos e consultar cifras de forma
rápida, intuitiva e totalmente funcional mesmo sem acesso à internet.

O aplicativo deverá ser uma ferramenta de apoio ao ministério de louvor,
priorizando simplicidade, desempenho e facilidade de uso durante ensaios
e apresentações.

# **2. Objetivos do Projeto**

-   Centralizar todo o repertório em uma única biblioteca musical.

-   Eliminar a dependência de diversos arquivos PDF ou imagens.

-   Facilitar a organização das músicas para cada culto.

-   Permitir alteração instantânea da tonalidade.

-   Permitir visualização em cifras ou graus harmônicos.

-   Manter funcionamento offline.

-   Sincronizar automaticamente a biblioteca com serviços de
    armazenamento em nuvem.

-   Possibilitar futura expansão para novos recursos musicais sem
    alteração da estrutura principal.

# **3. Público-Alvo**

-   Músicos de igreja.

-   Ministros de louvor.

-   Instrumentistas.

-   Vocalistas.

-   Equipes de adoração.

# **4. Princípios do Aplicativo**

-   Interface limpa.

-   Poucos toques para qualquer ação.

-   Funcionamento rápido.

-   Funcionamento offline como prioridade.

-   Arquivos pertencem ao usuário.

-   A sincronização é apenas um meio de atualização da biblioteca.

-   O aplicativo gerencia conhecimento musical, e não apenas arquivos de
    cifras.

# **5. Funcionalidades**

## **5.1 Biblioteca Musical**

A Biblioteca Musical será o elemento central do aplicativo.

Ela representará todo o repertório disponível para o usuário,
independentemente da origem das músicas.

As músicas poderão ser provenientes de diferentes fontes de
sincronização, mas serão apresentadas ao usuário como uma única
biblioteca organizada.

Cada música deverá possuir, no mínimo:

### **Informações obrigatórias**

-   Título.

-   Artista.

-   Tom original.

-   Letra com cifras.

### **Informações opcionais**

-   Compositor.

-   Ministério.

-   Álbum.

-   Categoria.

-   Coleção.

-   Idioma.

-   BPM.

-   Compasso.

-   Duração aproximada.

-   Nível de dificuldade.

-   Instrumentação predominante.

-   Tags.

-   Observações.

-   Nível de Energia: Muito Calma, Calma, Moderada, Animada, Muito
    Animada

-   Histórico de Tons Utilizados: Ministrante - Tom Utilizado

-   Observação.

A biblioteca deverá permitir:

-   pesquisa por título;

-   pesquisa por artista;

-   pesquisa por trecho da letra;

-   pesquisa por tags;

-   pesquisa por categoria;

-   ordenação por nome;

-   ordenação por artista;

-   ordenação por data de inclusão;

-   visualização das músicas recentes;

-   favoritos.

## **5.2 Visualização da Música**

Ao abrir uma música deverão ser exibidos:

-   título;

-   artista;

-   tom original;

-   tom atual;

-   letra com cifras;

-   botão de alteração de tom;

-   botão para alternar entre cifras e graus;

-   ajuste de tamanho da fonte;

-   botão de favorito;

-   compartilhamento (futuro).

## **5.3 Alteração de Tom**

O aplicativo deverá permitir:

-   aumentar meio tom;

-   diminuir meio tom;

-   selecionar qualquer tonalidade;

-   retornar ao tom original.

Todos os acordes deverão ser atualizados automaticamente.

## **5.4 Exibição por Graus**

O aplicativo deverá possuir três modos de visualização:

-   Cifras.

-   Graus.

-   Cifras + Graus.

A conversão será realizada automaticamente considerando o tom atual da
música.

As características dos acordes deverão ser preservadas integralmente.

Exemplos:

-   G → I

-   Em7 → vim7

-   Cadd9 → IVadd9

-   Dsus4 → Vsus4

-   G/B → I/III

O usuário poderá escolher:

-   Algarismos romanos.

-   Graus numéricos.

-   Sistema simplificado.

## **5.5 Listas de Culto**

O usuário poderá criar listas de músicas.

Cada lista possuirá:

-   nome;

-   descrição;

-   data;

-   observações.

Será possível:

-   adicionar músicas;

-   remover músicas;

-   alterar a ordem por arrastar;

-   definir um tom específico para cada música;

-   navegar rapidamente entre as músicas durante o culto.

## **5.6 Favoritos**

Permitir marcar músicas favoritas.

## **5.7 Histórico**

Registrar automaticamente:

-   últimas músicas abertas;

-   últimos repertórios utilizados.

## **5.8 Pesquisa**

Pesquisar por:

-   título;

-   artista;

-   letra;

-   categoria;

-   coleção;

-   tags.

A pesquisa deverá ocorrer em tempo real.

## **5.9 Modo Palco**

Características:

-   tela sempre ligada;

-   interface simplificada;

-   fonte ampliada;

-   poucos botões;

-   navegação rápida;

-   ocultação dos menus.

## **5.10 Rolagem Automática**

Permitir:

-   iniciar;

-   pausar;

-   reiniciar;

-   alterar velocidade.

## **5.11 Ajuste da Fonte**

Permitir alterar o tamanho da letra sem modificar o restante da
interface.

## **5.12 Temas**

Disponibilizar:

-   claro;

-   escuro;

-   AMOLED.

## **5.13 Organização do Repertório**

Permitir organizar músicas por:

-   artista;

-   ministério;

-   categoria;

-   coleção;

-   favoritos;

-   tags.

O usuário poderá criar coleções personalizadas.

## **5.14 Sincronização da Biblioteca**

A biblioteca poderá ser sincronizada com diferentes fontes.

Na primeira versão:

-   Google Drive.

Arquitetura preparada para futuras integrações:

-   OneDrive;

-   Dropbox;

-   GitHub;

-   servidor próprio;

-   armazenamento local.

A sincronização deverá:

-   identificar novas músicas;

-   atualizar músicas alteradas;

-   detectar exclusões;

-   manter cópia local.

## **5.15 Funcionamento Offline**

Após sincronizadas, todas as músicas deverão permanecer disponíveis sem
internet.

## **5.16 Informações Musicais**

Cada música poderá armazenar:

-   Tom original.

-   Tom preferencial do ministério.

-   BPM.

-   Compasso.

-   Duração aproximada.

-   Grau de dificuldade.

-   Instrumentação predominante.

-   Tags.

-   Observações do líder.

-   Data da última execução.

-   Quantidade de execuções.

-   Data da última alteração.

## **5.17 Organização Inteligente do Repertório**

O aplicativo deverá permitir:

-   Filtrar por tonalidade.

-   Filtrar por BPM.

-   Filtrar por compasso.

-   Filtrar por dificuldade.

-   Filtrar por duração.

-   Filtrar por artista.

-   Filtrar por ministério.

-   Filtrar por tags.

-   Exibir músicas mais executadas.

-   Exibir músicas menos executadas.

-   Exibir músicas recentemente adicionadas.

-   Exibir músicas recentemente utilizadas.

# **6. Biblioteca Musical**

O conceito central do aplicativo será a Biblioteca Musical.

A biblioteca será independente da origem das músicas.

O usuário enxergará apenas uma biblioteca única.

As músicas poderão ser sincronizadas de diversas fontes, permanecendo
organizadas de forma transparente.

Os arquivos de origem não constituem a biblioteca, mas apenas um
mecanismo de sincronização.

# **7. Funcionalidades Futuras**

-   Importação automática de PDFs.

-   Conversão automática de cifras.

-   Compartilhamento de músicas.

-   Compartilhamento de repertórios.

-   Login em múltiplos dispositivos.

-   Backup automático.

-   Estatísticas de utilização.

-   Sugestão automática de repertórios.

-   Sugestão de tonalidades.

-   Sugestão de transições entre músicas.

-   Organização automática por ocasião.

-   Controle por pedal Bluetooth.

-   Integração MIDI.

-   Modo tablet.

-   Modo paisagem.

-   Espelhamento para monitor externo.

-   Integração com Inteligência Artificial para organização e análise do
    repertório.

## **7.1 PR-001 — Centralização da versão utilizada pela equipe**

**Status:** necessidade futura registrada; solução e conceitos candidatos,
ainda não aprovados para implementação ou incorporação ao Modelo de Domínio.

**Problema observado**

Músicos de uma mesma equipe de louvor frequentemente chegam aos ensaios
utilizando cifras ou versões diferentes da mesma música. Isso gera
divergências de letra, acordes, tom e, eventualmente, estrutura ou ordem
das partes da música, dificultando o uso de uma referência comum.

**Possível solução futura**

Permitir a criação de Grupos ou Equipes de Louvor com membros e um papel
responsável pela definição do repertório oficial da equipe,
provisoriamente chamado de "Diretor". Esse responsável poderia selecionar
as músicas/versões a serem utilizadas e disponibilizá-las aos demais
membros, para que todos utilizem a mesma referência.

Essa referência compartilhada poderia contemplar o tom utilizado pela
equipe, a cifra, a letra, a estrutura/ordem das partes e outras adaptações
específicas daquela equipe. A necessidade detalha o contexto de uso do
compartilhamento de músicas e repertórios já citado nesta seção; não
define ainda seu mecanismo de disponibilização.

**Hipótese conceitual a validar**

A necessidade sugere uma possível distinção futura entre:

- Música: identidade/conteúdo musical de referência;
- Arranjo ou Versão: configuração utilizada em determinado contexto ou
  por determinada equipe.

Essa distinção é apenas uma hipótese, não uma redefinição da Música atual.
Arranjo/Versão, Grupo/Equipe e os respectivos papéis (Diretor e Membro)
são conceitos candidatos, não elementos aprovados do Modelo de Domínio.
Nomes, responsabilidades e relações permanecem sujeitos a validação futura.

**Decisão para o desenvolvimento atual**

Não implementar esta funcionalidade agora. Conforme o escopo de recursos
adiados em [Decisões do MVP, seção 6](decisoes-mvp.md#6-sincronização-e-recursos-adiados),
ela permanece fora do MVP, sem alterar seu escopo ou cronograma.
Não criar Usuário, Grupo/Equipe, Diretor, Membro, Arranjo/Versão,
permissões, autenticação, sincronização colaborativa ou infraestrutura
de nuvem nesta etapa. Não alterar a arquitetura ou o Modelo de Domínio
para antecipar essa funcionalidade.

A única orientação para o desenvolvimento atual é evitar decisões
desnecessárias que pressuponham que uma Música sempre possuirá uma única
versão global e definitiva. Isso não exige suporte a múltiplas versões
no MVP nem modifica as regras atuais de preservação do conteúdo original.

# **8. MVP**

A primeira versão deverá conter:

-   Biblioteca Musical.

-   Pesquisa.

-   Visualização de músicas.

-   Alteração de tom.

-   Visualização em cifras.

-   Visualização em graus.

-   Visualização mista.

-   Favoritos.

-   Listas de culto.

-   Funcionamento offline.

-   Persistência local e funcionamento offline.

A sincronização com Google Drive será avaliada após a estabilização da versão local funcional, conforme `docs/decisoes-mvp.md`.

Toda a arquitetura deverá ser preparada para permitir evolução contínua,
preservando compatibilidade e evitando reestruturações significativas.
