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
Timers que podem sobreviver ao nó: usar `create_timer().timeout.connect(...)`, não `await`.

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
`dodge` (Espaço), `special` (Q), `interact` (E), `ability_1..6` (1–6),
`inventory` (Tab), `pause` (Esc). Teclas físicas: valem para teclado ABNT ou US.

## Git
- Branch principal `main`. Commit ao fim de cada etapa testada.
- `.godot/` é cache e não vai para o git.
