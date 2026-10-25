# Princípios do Projeto

Estes princípios são estáveis e orientam decisões de produto, arquitetura e
implementação.

- **Offline primeiro.** Depois de disponíveis localmente, músicas e fluxos
  essenciais funcionam sem internet.
- **Biblioteca antes de arquivos isolados.** O usuário trabalha com repertório;
  arquivos externos entram por importação ou pela Biblioteca Oficial pública,
  sem substituir a Biblioteca local como centro da experiência. A atualização
  oficial não exige login nem escolha de pasta remota e, depois do download,
  todo o uso essencial continua local e offline.
- **ChordPro canônico, invisível no uso comum.** O conteúdo musical tem fonte
  preservada; leitura, transposição e graus são representações derivadas. O
  usuário edita uma música; o AppCifras mantém o ChordPro por trás. Colagem,
  revisão e operações musicais comuns usam letra, acordes, seções, problemas e
  ações musicais, sem exigir que o usuário compreenda ou edite a sintaxe.
  ChordPro textual permanece disponível como modo avançado e fallback.
- **Poucos toques e uso real.** Em ensaios e cultos, rapidez, legibilidade,
  estabilidade e baixa distração superam efeitos visuais. A menor jornada
  completa e confiável de uso pessoal vem antes de refinamentos amplos; o uso
  real orienta quais melhorias recebem prioridade depois dela.
- **Domínio independente.** Regras musicais não dependem de Flutter, banco,
  arquivos ou APIs.
- **Simplicidade responsável.** Complexidade, abstrações e entidades só entram
  quando resolvem necessidade concreta.
- **Evolução incremental.** Entregar, observar e ampliar sem reescrever o
  núcleo desnecessariamente.
- **Fonte de verdade clara.** Cada informação e documento tem responsabilidade
  definida, sem duplicação concorrente.
