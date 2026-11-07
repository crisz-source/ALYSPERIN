# Fase 1 — Análise do ambiente e fundação do projeto

- **Data:** 2026-11-07
- **Status:** concluído
- **Arquivos tocados:** `project.godot`, `.gitignore`, `.gitattributes`,
  `game/world/arenas/test_arena/test_arena.tscn`, `documentation/CONVENCOES.md`,
  `documentation/DEVLOG.md`, pastas com `.gitkeep`

## Objetivo
Executar a "Primeira tarefa importante" do briefing: analisar o diretório, verificar
a Godot, identificar limitações, propor a arquitetura e, com aprovação, criar a base
limpa do projeto com uma cena que abre sem erros.

## Plano executado
1. Análise do diretório e do ambiente (tabela abaixo).
2. Proposta de arquitetura → aprovada pelo proprietário: pastas por funcionalidade,
   640×360 com tiles de 16 px, instalar Godot via winget, iniciar git.
3. `winget install --id GodotEngine.GodotEngine --exact --version 4.7.2`.
4. `git init -b main`, `.gitignore` (ignora `.godot/`), `.gitattributes` (LF, binários).
5. Configuração via script GDScript headless (`ProjectSettings.save()` e
   `ResourceSaver.save()`), em vez de escrever `project.godot`/`.tscn` à mão, para que
   o formato saia exatamente como a 4.7.2 espera.
6. Testes (abaixo), documentação.

**Desvio do plano:** o worklog foi movido de `.claude/worklog/` para
`documentation/worklog/` depois que a pasta virou repositório git, seguindo a pasta de
documentação já definida no briefing.

## Análise do ambiente
| Verificação | Resultado |
|---|---|
| Conteúdo inicial da pasta | Vazio |
| Godot (PATH, winget, Scoop, Steam, `%APPDATA%\Godot`, Desktop, Downloads) | Não instalada |
| Git | 2.55.0.windows.3 |
| GPU / RAM | Intel Iris Xe (integrada) / 31,7 GB |

Godot instalada em:
`%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\`
(`Godot_v4.7.2-stable_win64.exe` = editor; `..._console.exe` = mesma coisa com terminal).
O winget avisou que, sem privilégio de administrador, **não cria o atalho `godot` no
PATH** — usar o caminho completo.

## Problemas encontrados

### Ações de input gravadas presas a um único dispositivo
- **Sintoma:** `project.godot` saiu com `"device":16` (teclas) e `"device":32` (mouse),
  enquanto o editor da Godot grava `-1`.
- **Causa raiz:** na 4.7, `InputEventKey.new()` já nasce com
  `device = DEVICE_ID_KEYBOARD (16)` e `InputEventMouseButton` com
  `DEVICE_ID_MOUSE (32)`. Uma ação guardada com um device específico só casa com
  eventos daquele device exato.
- **Como cheguei nela:** script de sondagem:
  ```
  DEVICE_ID_EMULATION = -1 / DEVICE_ID_KEYBOARD = 16 / DEVICE_ID_MOUSE = 32
  new InputEventKey.device = 16
  evento device=0 casa com move_up? false
  ```
  e, com a ação gravada em `-1`, eventos de device 0, 16, 32 e -1 casam todos (`true`).
- **Solução:** o script de setup define `ev.device = -1` (todos os dispositivos) antes
  de gravar cada ação — mesmo comportamento do editor. Corrige na origem (a criação do
  evento), não no arquivo gerado.
- **Prevenção:** teste T1 confere as 17 ações. Ao criar ações por código no futuro
  (ex.: remapeamento de controles no menu), definir `device = -1` explicitamente.

## Testes feitos
| # | O que testa | Comando | Resultado |
|---|---|---|---|
| 1 | Versão da engine | `Godot_..._console.exe --version` | ✅ `4.7.2.stable.official.ed1daf0bf` |
| 2 | Importação do projeto | `--headless --path . --import` | ✅ exit 0 |
| 3 | 17 ações existem e casam com as teclas certas (e não com as erradas) | `--headless --script check_input.gd` | ✅ exit 0 |
| 4 | Cena principal roda sem erro | `--headless --path . --quit-after 120` | ✅ exit 0, sem erros |
| 5 | Janela real com GPU e renderer Compatibility | `--path . --write-movie f.png --quit-after 5` | ✅ quadro capturado |

**Saída relevante:**
```
acoes esperadas=17 faltando=[]
W->move_up: true | LMB->attack: true | Space->dodge: true
W->attack (deve ser false): false

OpenGL API 3.3.0 - Build 32.0.101.7092 - Compatibility - Using Device: Intel - Intel(R) Iris(R) Xe Graphics
Movie Maker mode enabled, recording movie in 640×360 @ 60 FPS...
```
O quadro capturado mostra o fundo escuro 640×360 e o texto
"ALYSPERIN - Arena de teste (provisorio)".

**Verificação manual pelo proprietário (2026-11-07):** projeto importado pela
interface do editor, F5 abriu a janela com fundo cinza-escuro e o texto de teste.
Log `%APPDATA%\Godot\app_userdata\ALYSPERIN\logs\godot.log` sem erros nem avisos;
o editor não alterou nenhum arquivo versionado.

**Não coberto:** o pressionar de teclas físicas reais — o mapeamento foi testado com eventos
simulados. Ambos serão exercitados na Fase 2, quando houver personagem para mover.

## Abordagens consideradas
| Abordagem | Decisão | Motivo |
|---|---|---|
| Configurar via script GDScript + `ProjectSettings.save()` | ✅ adotada | Formato garantido pela própria engine instalada |
| Escrever `project.godot`/`.tscn` à mão | ❌ descartada | Serialização de InputEvent é verbosa e muda entre versões; risco de erro silencioso |
| Renderer Compatibility | ✅ adotada | Leve, roda em GPU integrada, suficiente para 2D |
| Renderer Forward+ | ❌ descartada | Custo desnecessário para 2D pixel art |
| Stretch `viewport` + escala inteira | ✅ adotada | Pixel perfeito; nada de pixels de tamanhos diferentes |
| Stretch `canvas_items` | ❌ descartada por ora | Movimento mais suave, mas permite sub-pixel e quebra a grade da pixel art. Rever se a câmera tremer na Fase 2 |
| Pastas por tipo (briefing) | ❌ descartada (aprovado) | Espalha cada elemento por 3 pastas |
| `snap_2d_transforms_to_pixel` | ⏳ não ativado | Avaliar na Fase 2 junto com a câmera |

## Estado final
Projeto Godot 4.7.2 em `C:\Users\crist\Documents\ALYSPERIN`, repositório git em `main`
(sem commits ainda). Abrir: executar o editor, "Importar" → selecionar `project.godot`,
F5 roda a arena de teste.

## Pendências
- [ ] Primeiro commit (aguardando autorização do proprietário)
- [ ] Fase 2: personagem jogável
