# Anotações abertas

Este arquivo guarda apenas dúvidas ou hipóteses ainda não consolidadas.

## Acesso ao ChordPro avançado

Definir, depois de validar o fluxo comum, onde e como oferecer o editor textual
ChordPro como opção secundária e fallback. O acesso deve ser encontrável para o
usuário avançado sem apresentar sintaxe como caminho normal de entrada ou
edição.

## Critérios concretos de ambiguidade

Calibrar com exemplos reais quais candidatos de acorde devem gerar
ProblemaDeCifra na entrada manual. A decisão já fixada é conservadora: A–G
continua sendo a notação aceita nesta etapa, rótulos conhecidos permanecem
texto e a dúvida não vira acorde automaticamente. Permanecem abertos apenas os
limites heurísticos necessários para manter baixa a taxa de falsos positivos.

## Último tom e novo Item de Lista

Definir a regra exata para sugerir o tom inicial quando uma música for incluída
em uma Lista de Culto: usar o último tom salvo para a versão, o tom original da
versão escolhida ou outra regra explícita. Depois de criado, o tom snapshot do
ItemListaCulto será independente da preferência de último tom.

## Importação em lote

Continuam abertas:

- política para identificar duplicata, Música existente ou nova VersaoMusica;
- ação diante de possível duplicata: pular, revisar, atualizar ou outra;
- destino de um `.txt` cuja conversão conservadora não seja confiável:
  revisão obrigatória, rascunho, ignorar com relatório ou outra alternativa;
- necessidade de preservar permanentemente o texto original `.txt` depois da
  conversão para ChordPro.

## Consultas e estatísticas derivadas das Listas

Definir futuramente se consultas e estatísticas usarão todas as Listas ou algum
filtro explícito. A Lista é memória operacional do repertório; caso o uso real
revele necessidade de distinguir planejamento de repertório efetivamente
tocado, reavaliar essa simplificação antes de introduzir estados ou registros
de execução.

## Múltiplas bibliotecas e compartilhamento

Bibliotecas públicas ou assináveis, bibliotecas de igrejas/equipes,
distribuição remota e conflitos entre origens são possibilidade distante. Não
orientam o domínio, a persistência ou o roadmap de curto prazo, que mantêm uma
única Biblioteca principal e oficial. Antes de qualquer implementação futura,
avaliar necessidade real, autoria, direitos, versionamento, conflitos,
privacidade e alternativas técnicas.
