# Anotações abertas

Este arquivo guarda apenas dúvidas ou hipóteses ainda não consolidadas.

## Confirmação de execução de uma Lista de Culto

Antes de registrar histórico automaticamente, definir como o usuário confirma
quais músicas foram realmente executadas. Não assumir que todas as músicas
planejadas foram tocadas.

## Taxonomia de classificação

Antes de implementar tags e filtros, definir se temas e momentos/tipos serão
predefinidos, configuráveis ou combinados, e quais categorias têm valor real.

## Interação móvel da edição assistida

Prioridade alta: toque em palavra ou acorde deve selecionar automaticamente o
token completo, delimitado por espaço ou quebra de linha; acordes como `D/F#`
e `Am7` continuam um único token. Definir também uma apresentação alternativa
para `Tratar como texto`, que não dependa da posição variável do menu nativo,
sem transformar a edição em um editor de texto complexo.

## Bibliotecas compartilháveis/assináveis

Avaliar futuramente a possibilidade de um usuário ou grupo publicar uma
biblioteca musical para que outras pessoas possam adicioná-la ou assiná-la no
AppCifras. O conceito pode abranger bibliotecas pessoais, de uma igreja, de um
ministério ou de uma equipe de louvor, inclusive permitindo que um usuário
acompanhe mais de uma biblioteca.

Após a sincronização, as músicas recebidas devem permanecer disponíveis
localmente, preservando o funcionamento offline-first. Novas músicas e
alterações publicadas pela origem poderão ser identificadas e recebidas pelo
aplicativo quando houver conexão.

A solução deverá considerar origem e versionamento das músicas e tratar
explicitamente divergências entre uma atualização publicada e alterações feitas
localmente pelo usuário. Uma atualização remota não deve sobrescrever
silenciosamente uma versão local modificada.

Possíveis formas de resolução, ainda em aberto, incluem avisar que existe uma
nova versão, permitir atualizar, manter a versão local e, futuramente, comparar
alterações ou distinguir de forma mais explícita a música publicada da cópia ou
versão local.

Este registro representa uma oportunidade futura, não uma decisão de
implementação nem requisito da versão atual. Antes de desenvolver, avaliar a
necessidade real, a experiência de uso, o modelo de versionamento e conflitos e
as alternativas técnicas. Não estão definidos neste momento servidor próprio,
Google Drive, Firebase, Supabase, protocolo/API, arquitetura de sincronização ou
modelo definitivo de resolução de conflitos.

### Descoberta e comunidade

Avaliar também uma possível evolução das bibliotecas compartilháveis para uma
experiência de descoberta comunitária. Uma futura tela de bibliotecas poderia
distinguir uma biblioteca oficial do AppCifras de bibliotecas publicadas por
usuários, igrejas, ministérios ou equipes de louvor.

Os usuários poderiam cadastrar e compartilhar suas próprias bibliotecas e
pesquisar músicas dentro de uma biblioteca específica ou, eventualmente, entre
múltiplas bibliotecas. Uma mesma música poderá existir em diferentes versões e
fontes, devendo sua origem ficar clara para que o usuário possa escolher qual
conteúdo deseja utilizar.

Como hipóteses de descoberta e sinais de qualidade, avaliar futuramente recursos
como seguir, adicionar ou utilizar bibliotecas, curtir músicas/cifras ou
bibliotecas e apresentar indicadores simples de utilização. Esses sinais
poderiam permitir que autores e bibliotecas reconhecidos pela comunidade por
cifras completas, corretas ou bem estruturadas ganhassem reputação de forma
orgânica.

Não estão decididos sistema de ranking, pontuação, estrelas, algoritmo de
reputação ou qualquer outro mecanismo específico. Antes de implementar, avaliar
a necessidade real desses recursos e questões como identidade e autoria,
moderação, duplicidade de conteúdo, pesquisa remota, privacidade, infraestrutura
e direitos autorais relacionados ao compartilhamento público de letras e cifras.

O objetivo a investigar é facilitar que o usuário encontre rapidamente versões
confiáveis de músicas e descubra bibliotecas úteis, e não criar uma rede social
como fim em si mesma.
