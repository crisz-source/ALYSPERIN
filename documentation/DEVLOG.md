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

### Fase 2 — Primeiro personagem jogável — ⏳ próxima
- [ ] Cena do jogador, movimentação top-down, câmera
- [ ] Ataque básico com espada, esquiva
- [ ] Inimigo simples e arena de teste com obstáculos (protótipo)

## Problemas conhecidos
- Nenhum no momento.

## Itens provisórios no projeto
- `test_arena.tscn`: fundo `ColorRect` e `Label` no lugar de tilemap/arte reais.
