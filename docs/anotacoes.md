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
