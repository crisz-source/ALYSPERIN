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

## Marcos
### Fase 1 — Fundação — ✅ concluída (2026-11-07)
- Godot instalada e verificada; projeto criado; pastas; configurações de pixel art;
  mapa de controles; camadas de física; convenções (`CONVENCOES.md`).
- Cena `game/world/arenas/test_arena/test_arena.tscn` abre sem erros
  (**provisória**: só fundo e texto, sem jogabilidade).

### Fase 2 — Primeiro personagem jogável — 🔄 em andamento
- [x] Cena do jogador, movimentação top-down (8 dir.), direção em 4, câmera
  (testes automáticos ok; teste manual ok — "bem fluido")
- [ ] Ataque básico com espada, esquiva
- [ ] Inimigo simples e arena de teste com obstáculos (protótipo)

## Problemas conhecidos
- F5 no editor (jogo embutido na aba "Jogo") não recebe o teclado; clicar dentro não
  resolve. Contorno: rodar o jogo em janela própria. Causa ainda em aberto.
- Câmera sem limites: perto das bordas mostra o vazio cinza fora da arena (resolver na Fase 4).

## Itens provisórios no projeto
- `test_arena.tscn`: chão quadriculado desenhado por código, paredes e pilares em
  `ColorRect`, texto de ajuda — no lugar de tilemap/arte reais.
- `player.tscn`: corpo azul (`BodyPlaceholder`) e seta amarela (`FacingIndicator`)
  no lugar de sprites.
