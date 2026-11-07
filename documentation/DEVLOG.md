# DEVLOG — ALYSPERIN

Registro do desenvolvimento: o que está pronto, o que está pendente e problemas
conhecidos. Detalhes técnicos de cada etapa ficam em `documentation/worklog/`.

## Decisões aprovadas
| Data | Decisão |
|---|---|
| 2026-11-07 | Godot 4.7.2 (GDScript), renderer Compatibility |
| 2026-11-07 | Pastas organizadas por funcionalidade (`game/`), não por tipo de arquivo |
| 2026-11-07 | Pixel art: resolução interna 640×360, escala inteira, tiles 16×16 |
| 2026-11-07 | Controle de versão com git local (branch `main`) |
| 2026-11-07 | Ataque básico mira na direção do mouse |
| 2026-11-07 | Movimento em 8 direções; sprites desenhados em 4 direções |
| 2026-11-07 | Esquiva = rolamento com invencibilidade curta + tempo de recarga (sem stamina por ora) |
| 2026-11-07 | Combo de 3 golpes (3º = finalizador mais forte e mais lento); defesa segurando botão direito, protege a frente da mira |
| 2026-11-07 | Hitstop global (`Engine.time_scale`) no autoload `Hitstop`; vira efeito local no co-op (Fase 7) |
| 2026-11-07 | Cena principal passa a ser a área de protótipo; arena fica só para testes |

## Marcos
### Fase 1 — Fundação — ✅ concluída (2026-11-07)
- Godot instalada e verificada; projeto criado; pastas; configurações de pixel art;
  mapa de controles; camadas de física; convenções (`CONVENCOES.md`).
- Cena `game/world/arenas/test_arena/test_arena.tscn` abre sem erros
  (**provisória**: só fundo e texto, sem jogabilidade).

### Fase 2 — Primeiro personagem jogável — 🔄 em andamento
- [x] Cena do jogador, movimentação top-down (8 dir.), direção em 4, câmera
  (testes automáticos ok; teste manual ok — "bem fluido")
- [x] Ataque básico com espada mirando no mouse, input buffer
- [x] Esquiva (rolamento, invencibilidade, recarga, cancela recuperação do ataque)
  (teste manual ok — "tudo funcionando perfeitamente")

### Fase 3 — Fundamentos do combate — 🔄 protótipo pronto (teste manual ok em 2026-11-07)
- [x] Sistema de vida e dano (HealthComponent, Hitbox, Hurtbox, DamageInfo)
- [x] Inimigo básico com IA (perseguir, avisar, investir)
- [x] Reações: empurrão, clarão, atordoamento, invulnerabilidade pós-dano
- [x] Feedback visual: tremida de câmera, barras de vida, morte e reinício
- [x] Combo de 3 golpes, defesa (botão direito), inimigo atordoado ao ser bloqueado, hitstop
  (testes automáticos ok; teste manual pendente)
- [ ] Feedback sonoro (sem áudio no projeto)

### Fase 4 — Primeira área jogável — 🔄 protótipo pronto (teste manual pendente)
- [x] Tiles provisórios (chão, parede com colisão), mapa com salas, corredores e pilares
- [x] Câmera presa às bordas do mapa (inclusive durante a tremida)
- [x] Inimigos espalhados, sem renascimento; linha de visão (não veem através de parede)
- [x] HUD como cena reutilizável; morte reinicia a área
- [ ] Pathfinding dos inimigos (hoje perseguem em linha reta)

## Problemas conhecidos
- F5 no editor (jogo embutido na aba "Jogo") não recebe o teclado; clicar dentro não
  resolve. Contorno: desligar o jogo embutido para o projeto (`embed_on_play=false`) —
  aplicar com o editor fechado. Causa ainda em aberto.
- Hitstop congela o jogo inteiro (global): ok no single-player, precisa mudar no co-op.

## Itens provisórios no projeto
- `test_arena.tscn`: chão quadriculado desenhado por código, paredes e pilares em
  `ColorRect`, texto de ajuda — no lugar de tilemap/arte reais.
- `player.tscn`: corpo azul (`BodyPlaceholder`), seta amarela (`FacingIndicator`) e
  arco claro do golpe (`SwingPlaceholder`) no lugar de sprites/efeitos.
- `basic_enemy.tscn`: inimigo inteiro é provisório (quadrado vermelho, sem nome nem
  conceito definido) — serve só para testar combate.
- `player.tscn`: escudo (`ShieldPlaceholder`, arco azul-claro).
- `assets/environments/tiles/dungeon_tiles_placeholder.png` e
  `game/world/tilesets/dungeon_tileset_placeholder.tres`: tiles gerados por código.
- `prototype_area.tscn`: mapa, nome e distribuição de inimigos provisórios.
- `hud.tscn`: barra e textos simples, sem arte.
- `test_arena.gd`: reaparecimento de inimigos e reinício automático são ferramentas
  de teste, não sistemas finais de spawn/morte.
