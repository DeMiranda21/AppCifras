# **Requisitos Não Funcionais -- Aplicativo de Cifras**

## **1. Objetivo**

Este documento estabelece os requisitos técnicos e de qualidade do
aplicativo, definindo como o sistema deverá funcionar independentemente
das funcionalidades oferecidas ao usuário.

# **2. Plataforma**

A primeira versão será desenvolvida para Android.

A arquitetura deverá permitir futura publicação para iOS sem necessidade
de reescrita da aplicação.

# **3. Tecnologia**

O aplicativo deverá ser desenvolvido em Flutter.

Todo o código deverá ser compatível com as versões estáveis do Flutter.

# **4. Desempenho**

O aplicativo deverá iniciar rapidamente.

Objetivos:

-   abertura inferior a 2 segundos;

-   troca instantânea entre músicas;

-   pesquisa em tempo real;

-   alteração de tom sem atraso perceptível;

-   mudança entre cifras e graus instantânea.

# **5. Funcionamento Offline**

Após sincronizadas, todas as músicas deverão permanecer disponíveis
localmente.

Sem internet deverá ser possível:

-   pesquisar músicas;

-   abrir músicas;

-   alterar tom;

-   visualizar graus;

-   utilizar listas de culto;

-   utilizar favoritos.

A internet será necessária apenas para sincronização.

# **6. Armazenamento**

Cada música será armazenada como um arquivo individual.

O aplicativo utilizará um banco de dados local apenas para:

-   índice de pesquisa;

-   favoritos;

-   histórico;

-   listas de culto;

-   configurações.

As cifras não deverão ser armazenadas no banco de dados.

# **7. Estrutura das Músicas**

Cada música deverá possuir um identificador único.

Informações mínimas:

-   título;

-   artista;

-   tom original;

-   letra;

-   acordes;

-   metadados.

A estrutura deverá permitir inclusão futura de novos campos sem
incompatibilidade.

# **8. Sincronização**

A sincronização deverá ocorrer com uma pasta definida pelo usuário.

Características:

-   sincronização manual;

-   sincronização automática (configurável);

-   detecção de novos arquivos;

-   detecção de alterações;

-   detecção de exclusões;

-   resolução de conflitos.

A sincronização nunca deverá apagar arquivos locais sem confirmação do
usuário.

# **9. Arquitetura**

A lógica de negócio deverá ser independente da interface gráfica.

Todo o sistema de:

-   transposição;

-   graus;

-   pesquisa;

-   leitura das músicas;

deverá funcionar independentemente das telas.

Isso permitirá reutilização futura em outras plataformas.

# **10. Sistema Harmônico**

O aplicativo não deverá tratar acordes apenas como texto.

Internamente cada acorde deverá possuir:

-   nota fundamental;

-   qualidade;

-   alterações;

-   baixo;

-   função harmônica.

Isso permitirá:

-   transposição precisa;

-   exibição em graus;

-   futuras análises harmônicas;

-   geração automática de campos harmônicos.

# **11. Pesquisa**

A pesquisa deverá localizar músicas por:

-   título;

-   artista;

-   trecho da letra;

-   categoria;

-   coleção.

Os resultados deverão aparecer enquanto o usuário digita.

# **12. Escalabilidade**

A arquitetura deverá suportar:

-   milhares de músicas;

-   centenas de listas;

-   diversos dispositivos sincronizados.

Sem degradação perceptível de desempenho.

# **13. Interface**

A interface deverá priorizar:

-   simplicidade;

-   poucos botões;

-   facilidade de leitura;

-   acessibilidade.

Durante a execução das músicas, nenhuma ação comum deverá exigir mais de
dois toques.

# **14. Configurações**

As preferências do usuário deverão ser persistidas.

Exemplos:

-   tamanho da fonte;

-   tema;

-   velocidade da rolagem;

-   modo de visualização (cifras, graus ou ambos);

-   tipo de representação dos graus.

# **15. Segurança**

Nenhuma informação pessoal deverá ser compartilhada sem autorização.

As configurações do usuário deverão permanecer locais, salvo quando
futuramente houver sincronização em nuvem.

# **16. Compatibilidade**

O aplicativo deverá adaptar-se automaticamente a:

-   celulares;

-   tablets;

-   diferentes resoluções;

-   orientação retrato;

-   orientação paisagem (implementação futura).

# **17. Manutenibilidade**

O código deverá seguir princípios de desenvolvimento que facilitem
manutenção e evolução.

Objetivos:

-   baixo acoplamento;

-   alta coesão;

-   modularização;

-   separação entre interface e regras de negócio.

# **18. Extensibilidade**

Novas funcionalidades deverão poder ser adicionadas sem necessidade de
alterar significativamente a arquitetura existente.

Exemplos de futuras expansões:

-   cifras sincronizadas em tempo real;

-   importação de novos formatos;

-   pedal Bluetooth;

-   integração MIDI;

-   monitor externo;

-   compartilhamento entre equipes;

-   recursos colaborativos.

# **19. Experiência do Usuário**

O aplicativo deverá transmitir a sensação de rapidez e simplicidade.

O usuário deverá conseguir:

-   localizar uma música em poucos segundos;

-   alterar seu tom imediatamente;

-   navegar durante o culto sem distrações.

A interface deverá privilegiar o uso em apresentações ao vivo.

# **20. Princípios do Projeto**

Durante todo o desenvolvimento deverão ser respeitados os seguintes
princípios:

-   simplicidade acima da complexidade;

-   desempenho acima de animações desnecessárias;

-   funcionamento offline como prioridade;

-   arquivos pertencem ao usuário, não ao aplicativo;

-   nenhuma funcionalidade deverá depender exclusivamente de conexão com
    a internet;

-   toda funcionalidade deverá ser pensada para uso real durante ensaios
    e cultos.
