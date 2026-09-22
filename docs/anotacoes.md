# VERIFICAR:

## (Nova ideia) 01 - Questão da facilidade em adicionar músicas/cifras: (Nova ideia)

Era muito dificil (no app que usava) ficar adicionando novas músicas, eu
tinha que pesquisar a cifra da música na internet, copiar e colar o
texto em um .doc, editar e salvar na pasta do drive. Depois sincronizar,
converter em chorpro dentro do app (que tinha essa funcionalidade).

## [(Dúvida)]{.mark} 02 - Verificar a questão dos custos e grau iniciante em programação.

## [(Dúvida)]{.mark} 03 - Verificar se é interessante fazer toda a documentação, considerando que sou iniciante e não vou saber conceitos e o que é necessário ou não, ou já partir para a programação e ir sanando as dúvidas na prática?

## [(Dúvida)]{.mark} 04 - O que é domínio? O que é cardinalidade? A Biblioteca Musical constitui o principal Aggregate Root do domínio. O que é isso?

## (Nova ideia) 05 - Possibilidade de add e remover blocos da música (refrão, verso 1, etc). Arrastar, duplicar e excluir.

## (Nova ideia) 06 - Possibilidade de guitarristas salvarem patchs de pedaleiras, com timbres.

## (Problema / oportunidade) 07 - Facilitar a seleção de repertório pelo ministrante

### Problema percebido

Ministrantes podem ter dificuldade para escolher as músicas do louvor pelo qual estão responsáveis. O aplicativo poderá futuramente oferecer recursos que facilitem a descoberta de opções e a tomada de decisão durante a montagem do repertório.

### Possíveis soluções a avaliar

- Histórico de execução das músicas, permitindo consultar quais músicas foram tocadas, em quais cultos, datas ou outros contextos relevantes.
- Histórico de tons utilizados, permitindo identificar o último tom em que determinada música foi executada e, se fizer sentido, o histórico por ministrante.
- Categorização das músicas para facilitar a descoberta de opções, com classificações como animadas, lentas, adoração e outras categorias ainda a definir.
- Filtros adicionais, como tema e outros metadados que possam ser úteis na preparação do repertório.

### Pontos a analisar antes de implementar

Este registro representa um problema e hipóteses de solução, e não uma decisão de implementação. Antes de desenvolver esses recursos, avaliar:

- se a necessidade é relevante no uso real;
- quais informações realmente ajudam o ministrante a escolher o repertório;
- quais categorias e filtros são adequados;
- quais dados vale a pena registrar e manter;
- como oferecer esses recursos sem aumentar desnecessariamente a complexidade da interface;
- outras soluções possíveis para o mesmo problema.

## 

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

# ANÁLISE - MODELO DE DOMÍNIO

-   Item 1.3 cita documentos para o projeto, ainda não temos alguns
    (Arquitetura do Sistema, Modelo de Dados e Backlog) - **VERIFICAR**.

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

# PONTOS DE ALTERAÇÃO NOS DOCS., PENDENTES:

## 01 - Observação importante (proposta de melhoria)

Durante a elaboração deste capítulo, identifiquei um ponto que merece
discussão antes de avançarmos para o Capítulo 5.

Hoje modelamos **Seção → Linha → Segmento Musical** como Objetos de
Valor distintos. Essa é uma solução muito boa e bastante limpa.

No entanto, acredito que ainda podemos elevar o nível da modelagem ao
introduzir um conceito intermediário chamado **Estrutura Musical** (ou
**Partitura Lógica**), que serviria como raiz dos Objetos de Valor da
composição. Essa abordagem é comum em editores musicais profissionais e
deixaria o modelo ainda mais preparado para funcionalidades futuras,
como edição visual avançada, sincronização em tempo real e IA.

Eu manteria o documento como está por enquanto e voltaria a esse
refinamento apenas após concluirmos toda a primeira versão do Modelo de
Domínio. Assim evitamos redesenhar conceitos antes de termos a visão
completa do sistema.

\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_
