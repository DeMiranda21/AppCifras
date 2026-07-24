# **Roadmap de Desenvolvimento -- Aplicativo de Cifras**

## **Objetivo**

Este documento estabelece o planejamento das próximas etapas do
desenvolvimento do aplicativo de cifras.

O propósito é manter um fluxo de trabalho organizado, sem tornar o
projeto excessivamente complexo. A prioridade passa a ser a
implementação do software, utilizando apenas as práticas de engenharia
que realmente agreguem valor ao projeto.

# **Fase 1 -- Preparação do Ambiente de Desenvolvimento (Prioridade Máxima)**

## **Objetivo**

Preparar um ambiente único de desenvolvimento que permita trabalhar no
projeto a partir de diferentes computadores de forma segura e
organizada.

Esta etapa será realizada apenas uma vez e servirá como base para todo o
restante do desenvolvimento.

## **Atividades**

-   Instalar e configurar o Git.

-   Criar (ou configurar) a conta no GitHub.

-   Criar o repositório do projeto.

-   Definir a estrutura inicial de diretórios.

-   Configurar o VS Code para documentação e desenvolvimento.

-   Publicar a documentação existente no repositório.

-   Aprender o fluxo básico de versionamento:

    -   Clone;

    -   Pull;

    -   Commit;

    -   Push.

## **Resultado esperado**

Ao final desta etapa o projeto deverá possuir:

-   repositório no GitHub;

-   sincronização entre computadores;

-   histórico de alterações;

-   ambiente preparado para desenvolvimento.

A partir desse momento, o versionamento passa a fazer parte da rotina do
projeto.

# **Fase 2 -- Consolidação do Modelo de Domínio**

## **Objetivo**

Realizar apenas as alterações estruturais consideradas essenciais antes
do início da implementação.

Não será buscada uma modelagem perfeita, mas sim uma modelagem
suficientemente sólida para permitir o desenvolvimento.

## **Revisões previstas**

-   Revisar Biblioteca Musical como Aggregate Root.

-   Revisar Registro de Tom (Entity × Value Object).

-   Revisar Tag.

-   Revisar Fonte de Sincronização.

-   Avaliar a necessidade da entidade Execução.

## **Critério de encerramento**

Concluídas essas revisões, o documento será considerado:

**Modelo de Domínio v1.0**

Após essa versão, novas alterações somente serão realizadas quando
surgirem necessidades reais durante a implementação.

# **Fase 3 -- Arquitetura da Aplicação**

## **Objetivo**

Transformar o Modelo de Domínio em uma estrutura de software.

Serão definidos:

-   organização das camadas;

-   casos de uso;

-   repositórios;

-   persistência;

-   sincronização;

-   comunicação entre módulos.

## **Diretriz**

A arquitetura deverá permanecer simples.

Serão evitados padrões arquiteturais que aumentem a complexidade do
projeto sem oferecer benefícios concretos nesta fase.

# **Fase 4 -- Implementação do MVP**

## **Objetivo**

Desenvolver uma primeira versão funcional do aplicativo.

A ordem inicial sugerida é:

1.  Cadastro de músicas.

2.  Visualização de cifras.

3.  Transposição.

4.  Listas de culto.

5.  Persistência local.

6.  Configurações.

O foco desta etapa será colocar o aplicativo em funcionamento, ainda que
algumas funcionalidades permaneçam ausentes.

# **Fase 5 -- Evolução Contínua**

Após a estabilização do MVP, serão avaliadas funcionalidades mais
avançadas, como:

-   sincronização em nuvem;

-   compartilhamento;

-   múltiplos usuários;

-   estatísticas;

-   recursos colaborativos;

-   outras melhorias identificadas durante o uso.

# **Princípios do Projeto**

Durante todo o desenvolvimento serão observados os seguintes princípios.

## **1. Implementação acima de documentação**

A documentação existe para apoiar o desenvolvimento do software.

Ela não deve impedir que o desenvolvimento avance.

## **2. Complexidade somente quando necessária**

Toda decisão arquitetural deverá resolver um problema real.

Tecnologias, padrões ou metodologias não serão adotados apenas por serem
considerados boas práticas em projetos maiores.

## **3. Evolução incremental**

O projeto não precisa nascer perfeito.

Ele deverá evoluir continuamente, com pequenas melhorias e revisões
sempre que houver justificativa prática.

## **4. Funcionalidade acima de teoria**

Uma funcionalidade concluída possui mais valor do que diversas
funcionalidades apenas planejadas.

A prioridade será produzir software executável.

## **5. Aprendizado contínuo**

Este projeto também faz parte do processo de aprendizado em
desenvolvimento de software.

É esperado que novas experiências levem à revisão de algumas decisões
arquiteturais ao longo do tempo.

Essas revisões serão tratadas como evolução natural do projeto.

# **Fluxo de Trabalho**

A partir deste momento, o desenvolvimento seguirá o seguinte ciclo:

1.  Configurar e manter o ambiente de desenvolvimento.

2.  Concluir o Modelo de Domínio v1.0.

3.  Definir uma arquitetura simples e adequada ao projeto.

4.  Iniciar imediatamente a implementação do MVP.

5.  Evoluir o aplicativo conforme novas necessidades surgirem.

# **Considerações Finais**

Este projeto não tem como objetivo servir apenas como exercício de
programação.

O propósito é desenvolver um aplicativo que possa ser utilizado de forma
prática e evoluir ao longo do tempo.

Ao mesmo tempo, por se tratar do primeiro projeto do desenvolvedor,
serão priorizadas soluções simples, compreensíveis e sustentáveis.

A organização será suficiente para facilitar a evolução do sistema, mas
nunca a ponto de retardar desnecessariamente o início da implementação.

O desenvolvimento passará a ser orientado pelo princípio de que **o
software é o principal resultado do projeto**, utilizando documentação,
modelagem e versionamento como instrumentos de apoio, e não como fins em
si mesmos.
