# Convenções do projeto ALYSPERIN

Regras curtas para manter o código consistente. Quando houver dúvida, esta página
vence o padrão genérico da internet.

## Engine e ambiente
- **Godot 4.7.2** (edição padrão, GDScript). Atualizar só em versões de manutenção
  (4.7.x) sem combinar antes; versão nova (4.8+) é decisão registrada no DEVLOG.
- **Renderer:** Compatibility (OpenGL 3.3) — leve, suficiente para 2D, roda em GPU integrada.

## Pixel art
- Resolução interna **640×360**, ampliada em **escala inteira** (2× = 1280×720, 3× = 1920×1080).
- Tile base **16×16 px**. Personagens humanoides ≈ **16×32 px** (podem variar por design).
- Filtro de textura **Nearest** (pixels nítidos) — já é o padrão do projeto.
- Toda arte provisória fica com sufixo `_placeholder` no nome do arquivo.

## Pastas (organização por funcionalidade)
```
assets/      arte e áudio brutos (png, wav, fontes) — só material, sem lógica
game/
  actors/      player/, enemies/<nome>/ — cena + script + dados juntos
  components/  peças reutilizáveis (vida, hitbox, hurtbox...)
  combat/ abilities/ items/ inventory/ quests/ disciplines/
  world/       mapas, dungeons, arenas
  ui/          telas e HUD
  systems/     autoloads (singletons globais) — usar com moderação
  multiplayer/ reservado para a Fase 7
documentation/ convenções, DEVLOG, worklog/
```
Regra: o que muda junto fica junto. `player.tscn`, `player.gd` e `player_stats.tres`
ficam na mesma pasta.

## Nomes
| O quê | Estilo | Exemplo |
|---|---|---|
| Arquivos e pastas | `snake_case` | `test_arena.tscn`, `health_component.gd` |
| Nós na cena | `PascalCase` | `HealthComponent`, `Sprite` |
| `class_name` | `PascalCase` | `class_name HealthComponent` |
| Funções e variáveis | `snake_case` | `take_damage()`, `max_health` |
| Privado (uso interno) | prefixo `_` | `_current_state` |
| Constantes e enums | `UPPER_SNAKE_CASE` | `MAX_SPEED`, `State.IDLE` |
| Sinais | verbo no passado | `died`, `health_changed` |
| Ações de input | `snake_case` | `move_up`, `ability_1` |

## Estilo de GDScript
- **Tipagem estática sempre** (`var speed: float = 80.0`, `func f() -> void`).
  O projeto avisa quando uma declaração fica sem tipo.
- Ordem no arquivo: `class_name` → `extends` → sinais → enums → constantes →
  `@export` → variáveis → `@onready` → funções do motor (`_ready`, `_physics_process`)
  → funções públicas → funções privadas.
- Valores de balanceamento (vida, dano, velocidade) são `@export` ou ficam em
  `Resource` (`.tres`) — nunca número mágico no meio do código.
- Comentário explica **por quê**, não o quê.
- "Chamar para baixo, sinalizar para cima": um nó chama funções dos filhos e avisa o
  pai por sinais. Filho não procura o pai com `get_parent()`.

## Regras pensando no multiplayer (Fase 7)
1. **Entrada separada da lógica.** O personagem recebe uma intenção ("mover nesta
   direção", "atacar") e não lê o teclado direto. Assim, a entrada de um jogador
   remoto entra pelo mesmo caminho.
2. **Uma única autoridade para mudar estado importante** (vida, morte, drops). Hoje é
   o jogo local; no co-op passa a ser o host.
3. **Estado do jogo separado da apresentação.** Animação, partículas e som reagem a
   sinais; não decidem regras.

## Combate: como o dano viaja
`Hitbox` (quem bate, só machuca enquanto ativa) → detecta `Hurtbox` (quem apanha)
→ `HealthComponent.apply_damage(DamageInfo)` → sinais `damaged` / `died`.
Todo dano passa por `apply_damage`: nunca alterar `current_health` direto.
Controle de tela cheia numa camada de interface (raiz de tela) deve ter `mouse_filter = IGNORE`,
senão engole cliques e arrastes destinados a outras camadas (ex.: barra do HUD).
Área que precisa detectar paredes/portas (corpos estáticos) deve ter `monitorable = true`:
com `monitorable = false` a física da Godot não compara a área com corpos estáticos.
Timers que podem sobreviver ao nó: usar `create_timer().timeout.connect(...)`, não `await`.
Defesa/escudo: o dono registra `HealthComponent.block_filter`; golpe bloqueado não
causa dano, marca `DamageInfo.blocked` e emite `blocked` / `Hitbox.hit_blocked`.

Esquiva perfeita: golpe barrado por invulnerabilidade emite `HealthComponent.hit_ignored`;
o Player só conta se estiver no estado DODGE.

## Interação (tecla E)
`Interactable` (Area2D na camada `interactable`) fica no objeto; o dono registra
`handler: func(by: Player) -> String` (mensagem para o HUD, ou ""). O jogador procura
com o `InteractionDetector` e emite `message_requested`; o HUD escuta o jogador.
Objetos ficam em `game/world/objects/<nome>/`.

## Itens, inventário e progressão
- Tipo de item = `Resource` (`ItemData` e filhas: `WeaponData`, `ShieldData`,
  `ConsumableData`) em `game/items/data/*.tres`. Item carregado = `ItemStack`
  (item + quantidade + durabilidade); ao entrar num inventário/baú é sempre **copiado**.
- `Inventory` e `Equipment` só guardam e emitem `changed`; quem valida ações é o Player
  (`use_inventory_slot`, `unequip_*`, `discard_inventory_slot`, `pick_up`).
- Ações do Player devolvem a mensagem e emitem `message_requested`.
- Habilidade = `AbilityData` (e filhas, ex.: `SpinSlashData`) em `game/abilities/data/`;
  a posição em `Player.abilities` é a tecla (0 = tecla 1).
- Telas que tomam o controle (inventário) ligam `Player.input_blocked`.

## Autoloads (game/systems)
| Nome | Para quê |
|---|---|
| `Hitstop` | congela o jogo por centésimos de segundo no impacto (`Hitstop.request(s)`) |

Não misturar relógios: com `Engine.time_scale = 0`, timers "que ignoram a escala"
contam por um relógio diferente do real. Para medir tempo real, usar `Time.get_ticks_usec()`.

## Mapas
- Tiles em `TileMapLayer` com TileSet em `game/world/tilesets/`; textura em `assets/`.
- Camadas: `Ground` (sem colisão) e `Walls` (colisão na camada `world`).
- A área chama `player.set_camera_bounds(...)` com o retângulo do mapa.

## Camadas de física (2D)
| # | Nome | Uso |
|---|---|---|
| 1 | world | paredes e obstáculos |
| 2 | player | corpo e Hurtbox dos jogadores |
| 3 | enemy | corpo e Hurtbox dos inimigos |
| 4 | player_hitbox | golpes dos jogadores |
| 5 | enemy_hitbox | golpes dos inimigos |
| 6 | interactable | baús, portas, NPCs |

## Controles (ações já mapeadas)
`move_up/down/left/right` (WASD), `attack` (botão esq.), `defend` (botão dir.),
`dodge` (Espaço), `special` (Q), `interact` (F), `ability_1..9` (1–9), `ability_f1..f12` (F1–F12),
`inventory` (I), `pause` (Esc). Teclas físicas: valem para teclado ABNT ou US.

## Git
- Branch principal `main`. Commit ao fim de cada etapa testada.
- `.godot/` é cache e não vai para o git.
