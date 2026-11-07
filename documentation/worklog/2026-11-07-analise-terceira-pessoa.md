# Análise: viabilidade de converter o jogo para 3D em terceira pessoa

- **Data:** 2026-11-07
- **Status:** concluído (só análise, nenhum código alterado)
- **Arquivos tocados:** nenhum (apenas este worklog)

## Objetivo
O proprietário perguntou se é possível transformar o jogo (hoje 2D top-down em pixel
art) em terceira pessoa. Levantar o que é reaproveitável, o que precisa ser
reescrito e o custo.

## Método
- `project.godot`: renderer, resolução, camadas de física.
- Contagem de scripts com e sem referência a tipos 2D
  (`grep -L "Vector2|2D|Polygon|Rect2|canvas"`).
- Leitura de `player_input.gd`, `player_camera.gd`, `hitbox.gd`, `hurtbox.gd`,
  `projectile.gd`, `damage_info.gd`, `game_area.gd`; varredura de `player.gd` e
  `basic_enemy.gd`.

## Achados
- Godot 4.7, renderer **Compatibility**, viewport 640×360 em escala inteira, filtro
  Nearest — tudo configurado para pixel art 2D.
- 43 scripts / 3473 linhas. **17 scripts sem nenhuma referência 2D** (dados de
  itens/habilidades/disciplinas/missões, vida, mana, inventário, equipamento,
  stats, hitstop): migram sem mudança.
- Acoplados ao 2D (precisam ser portados para os equivalentes 3D):
  `player.gd` (780 linhas, CharacterBody2D, mira pelo mouse no plano, `to_cardinal`
  de 4 direções), `basic_enemy.gd` (RayCast/PhysicsRayQueryParameters2D,
  telegraph em Polygon2D), `hitbox/hurtbox/projectile` (Area2D),
  `player_camera.gd` (Camera2D com limites em pixels), `game_area.gd`,
  objetos do mundo (porta, baú, alavanca, pickup), `floating_text.gd`.
- UI (HUD, inventário, diálogo, morte, seleção de disciplina) é Control: continua
  igual em 3D, exceto o texto flutuante e barras de vida presas ao mundo.
- Toda a arte é placeholder (Polygon2D); `assets/` só tem um tileset placeholder.
  Não há arte final a perder.
- A arquitetura ajuda: `PlayerInput` separa intenção de leitura de teclado;
  `DamageInfo` desacopla golpe de dano; componentes reutilizáveis.

## Pontos de design que mudam (não só código)
- Mira: hoje é cursor do mouse no plano. Terceira pessoa exige câmera orbital com
  mouse + mira pela direção da câmera ou lock-on.
- Direção: 4 cardinais (sprite) vira rotação livre do modelo.
- Bloqueio por ângulo, esquiva, investida do inimigo: lógica vale, mas em X/Z.
- Mapas: TileMap 16×16 vira cenas 3D/GridMap; arte 3D (modelos, rig, animações)
  é o maior custo novo.
- Co-op previsto na Fase 7: câmera e mira 3D aumentam o que precisa ser replicado.

## Abordagens consideradas
| Abordagem | Avaliação |
|---|---|
| 3D terceira pessoa completo (câmera atrás do ombro) | Viável; reescrita da camada física/visual, maior custo de arte |
| 3D com câmera alta fixa/isométrica (tipo ARPG) | Viável; mantém mira por mouse e quase todo o design de combate |
| 2.5D: sprites (Sprite3D/billboard) em mundo 3D | Viável; reaproveita pixel art, custo de arte menor |
| Manter 2D | Sem custo de migração |

## Pendências
- [ ] Proprietário decidir o estilo de câmera/arte antes de qualquer migração.
- [ ] Se aprovado: protótipo isolado (player + 1 inimigo + câmera) em branch
      separada antes de portar o resto.
