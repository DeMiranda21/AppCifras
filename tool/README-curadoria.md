# Curadoria local da biblioteca

Ferramenta de linha de comando separada do aplicativo Flutter. Ela reutiliza o
conversor textual, o parser de acordes e o validador schema 2 do AppCifras, sem
alterar o comportamento do aplicativo.

Simulação, sem escrita:

```powershell
dart run tool/curadoria.dart --biblioteca "E:\Projetos\AppCifras - Biblioteca" --lote "Lote 02" --simular
```

Processamento:

```powershell
dart run tool/curadoria.dart --biblioteca "E:\Projetos\AppCifras - Biblioteca" --lote "Lote 02"
```

Para reaplicar regras atualizadas a origens cujo hash não mudou, preservando os
UUIDs registrados:

```powershell
dart run tool/curadoria.dart --biblioteca "E:\Projetos\AppCifras - Biblioteca" --lote "Lote 02" --reavaliar
```

Inventário global somente leitura (não cria UUID, CHO ou relatório):

```powershell
dart run tool/curadoria.dart --biblioteca "E:\Projetos\AppCifras - Biblioteca" --inventario-global
```

Acrescente `--detalhes` para imprimir a decisão e os motivos editoriais de cada
arquivo, inclusive durante uma simulação.

O comando de conversão lê somente arquivos `.txt` filhos diretos do lote
informado. As
saídas ficam em `prontos`, `revisar` e `bloqueados`. O `manifest.json` guarda o
hash SHA-256 da origem e do CHO gerado, além das identidades estáveis. Uma nova
execução ignora origens inalteradas. O checkpoint registra a identidade antes
da gravação do CHO e permite retomar uma execução interrompida. Manifesto,
checkpoint e relatório são gravados atomicamente e mantêm backup `.bak`.

Os TXT de origem nunca são escritos, movidos, renomeados ou excluídos. Um CHO
existente sem vínculo com a mesma origem é tratado como conflito e não é
sobrescrito.

Se um CHO vinculado foi editado depois da geração, a execução mantém o arquivo
intacto e registra conflito. Use `--adotar-cho-editado` para aceitar o conteúdo
atual como base protegida ou `--substituir-cho-editado` para gerar novamente; a
substituição cria antes uma cópia em `.curadoria-backups`.

O arquivo opcional `curadoria_overrides.json`, na raiz da biblioteca, usa o
caminho exato da origem e nunca aproxima títulos:

```json
{
  "schema": 1,
  "overrides": {
    "Lote 02/Exemplo.txt": {
      "artista": "Artista confirmado",
      "nomeVersao": "Acústica",
      "aprovado": true,
      "observacao": "Conferido na fonte original"
    }
  }
}
```

Também são aceitos `titulo`, `tom`, `decisaoDuplicidade`,
`idMusicaCompartilhado` (UUID v4 deliberadamente compartilhado) e `principal`.
