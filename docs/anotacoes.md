# Anotações abertas

Este arquivo guarda apenas dúvidas ou hipóteses ainda não consolidadas.

## Qualidade das cifras

Permanecem abertas, para decisão ou medição antes da implementação:

- como impedir futuramente a entrada de novas tablaturas no catálogo sem
  remover trechos instrumentais legítimos.

A retirada atual de tablaturas é decisão de curadoria do conteúdo publicado.
Não está aprovada uma validação automática de tablatura.

## Reavaliação do editor após uso real

Observar em ensaios, cultos e manutenção cotidiana quais operações ainda tornam
o editor atual lento ou inseguro. Reavaliar então o recorte do editor comum e
do diagnóstico contextual da transposição, em vez de assumir antecipadamente
que o rework completo é o próximo bloqueio.

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

## Importação em lote

Continuam abertas:

- política para identificar duplicata, Música existente ou nova VersaoMusica;
- ação diante de possível duplicata: pular, revisar, atualizar ou outra;
- destino de um `.txt` cuja conversão conservadora não seja confiável:
  revisão obrigatória, rascunho, ignorar com relatório ou outra alternativa;
- necessidade de preservar permanentemente o texto original `.txt` depois da
  conversão para ChordPro.

## Múltiplas bibliotecas e compartilhamento

Bibliotecas públicas ou assináveis, bibliotecas de igrejas/equipes,
distribuição remota e conflitos entre origens são possibilidade distante. Não
orientam o domínio, a persistência ou o roadmap de curto prazo, que mantêm uma
única Biblioteca principal e oficial. Antes de qualquer implementação futura,
avaliar necessidade real, autoria, direitos, versionamento, conflitos,
privacidade e alternativas técnicas.
