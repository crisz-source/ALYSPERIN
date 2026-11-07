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
| 2026-11-07 | Inimigo mostra no chão o caminho do ataque; mira trava nos últimos 0,2 s |
| 2026-11-07 | "Esquiva perfeita!" quando um golpe passa pela invencibilidade do rolamento |
| 2026-11-07 | Inventário de 8 vagas fixas; equipamento (arma + escudo) separado da bolsa |
| 2026-11-07 | Durabilidade: arma/escudo quebrados ficam bem mais fracos, não somem |
| 2026-11-07 | Progressão por nível com pontos escolhidos (Vigor, Força); sem escudo não há defesa |
| 2026-11-07 | Inventário não pausa o jogo (pensado para o co-op) |
| 2026-11-07 | Mana NÃO recupera sozinha: só com itens (Poção de mana) e cheia ao continuar após a morte |
| 2026-11-07 | Sem sistema de pontos (Vigor/Força removidos): vida, mana e dano crescem por nível, igual para todos |
| 2026-11-07 | Nível máximo 60; masmorras a partir do nível 20; cada classe usa só os seus tipos de arma |
| 2026-11-07 | Ponto de descanso removido: continuar após a morte volta ao início da área |
| 2026-11-07 | Interagir na tecla F (antes E); barra de habilidades no centro embaixo com 21 espaços: 1-9 e F1-F12 |
| 2026-11-07 | Inventário na tecla I (antes Tab); consumíveis podem ser arrastados para a barra de habilidades |
| 2026-11-07 | Barra de vida dos monstros sempre visível; números de dano na tela |
| 2026-11-07 | Marcadores de missão: ! nova, ? em andamento, * pronta para entregar |
| 2026-11-07 | Chefes aprovados; Fúria aos 70%, 50% e 20% de vida; óleos de arma aprovados |
| 2026-11-07 | ~~Morrer recomeça a área do zero~~ → substituído: morrer mostra "Você morreu!" / "Deseja continuar?"; Sim volta ao último ponto de descanso mantendo itens e experiência |

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
  (teste manual ok — "ficou tudo ótimo")
- [x] Aviso do ataque no chão (mira trava no fim) e "Esquiva perfeita!"
- [ ] Feedback sonoro (sem áudio no projeto)

### Fase 4 — Primeira área jogável — ✅ protótipo completo (teste manual do último bloco pendente)
- [x] Tiles provisórios (chão, parede com colisão), mapa com salas, corredores e pilares
- [x] Câmera presa às bordas do mapa (inclusive durante a tremida)
- [x] Inimigos espalhados, sem renascimento; linha de visão (não veem através de parede)
- [x] HUD como cena reutilizável; morte reinicia a área
- [x] Objetos interativos (E): placa, porta (trancada por mecanismo), alavanca; caixa de mensagem no HUD
- [ ] Pathfinding dos inimigos (hoje perseguem em linha reta)

### Fase 5 — Sistemas de gameplay — 🔄 protótipo pronto (teste manual pendente)
- [x] Itens (dados .tres), inventário de 8 vagas, equipamento arma + escudo
- [x] 3 armas com estilos diferentes, 2 escudos, erva de cura; durabilidade
- [x] Itens no chão, baús, descartar; tela de inventário (Tab)
- [x] Experiência, níveis, pontos (Vigor/Força); HUD com nível e exp.
- [x] Habilidades (teclas 1–6): Golpe giratório (nível 2)
- [ ] Reparo de equipamento; ícones reais; salvamento

### Fase 6 — Mundo e conteúdo — 🔄 em andamento
- [x] Morte com "continuar" (volta ao início da área; botão "Não" a definir pelo proprietário)
- [x] Mana; magias (Dardo arcano, Cura); NPC com diálogo; missões (derrotar / coletar)
- [x] Disciplinas PROVISÓRIAS (Vanguarda/Guardião/Arcanista) — a substituir pelo sistema
  de 6 classes × 3 disciplinas definido pelo proprietário
- [ ] Classes/disciplinas definitivas, Gear Score, masmorras com sincronização
- [ ] Enigmas, chefes

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
- `hud.tscn`: barra, textos e caixa de mensagem simples, sem arte.
- `door.tscn`, `lever.tscn`, `sign_post.tscn`: formas coloridas no lugar de arte; textos
  da placa/porta/alavanca são provisórios.
- Itens e habilidade (`game/items/data/`, `game/abilities/data/`): nomes, números e
  cores provisórios; quadrados coloridos no lugar de ícones.
- `inventory_screen`: tela montada por código, sem arte.
- `item_pickup.tscn`, `chest.tscn`: formas coloridas; distribuição dos itens na área provisória.
- `LungeTelegraph` (faixa vermelha) e "Esquiva perfeita!" com fonte padrão: efeitos sem arte.
- `test_arena.gd`: reaparecimento de inimigos e reinício automático são ferramentas
  de teste, não sistemas finais de spawn/morte.
