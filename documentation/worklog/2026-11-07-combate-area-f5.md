# Combate parte 2 (combo, defesa, hitstop) + Fase 4 (área jogável) + F5 do editor

- **Data:** 2026-11-07
- **Status:** concluído nos testes automáticos (114 verificações + movimento); teste
  manual do proprietário pendente; F5 do editor aguardando o editor ser fechado
- **Pedido:** "pode fazer todos esses, vc que manda e eu testo" — os 3 caminhos
  propostos: melhorar o combate, primeira área jogável, investigar o F5 do editor.
- **Arquivos tocados:**
  - novos: `game/systems/hitstop.gd` (autoload `Hitstop`), `game/ui/hud/hud.gd` + `hud.tscn`,
    `game/world/areas/prototype_area/prototype_area.gd` + `.tscn`,
    `game/world/tilesets/dungeon_tileset_placeholder.tres`,
    `assets/environments/tiles/dungeon_tiles_placeholder.png`
  - modificados: `player.gd` (combo, BLOCK, hitstop, limites de câmera),
    `player_input.gd` (`defend_held`), `player_camera.gd` (limites + tremida limitada),
    `basic_enemy.gd` (STAGGER, linha de visão), `health_component.gd` (`block_filter`,
    sinal `blocked`), `hitbox.gd` (sinal `hit_blocked`), `hurtbox.gd` (doc),
    `damage_info.gd` (`blocked`), `test_arena.gd` (usa Hud e limites),
    `player.tscn`, `basic_enemy.tscn`, `test_arena.tscn` (regerados),
    `project.godot` (autoload, cena principal, cor de fundo)

## Objetivo
1. Combate mais rico: combo de 3 golpes, defesa no botão direito, hitstop.
2. Primeiro mapa de verdade com tiles, salas e corredores, câmera presa às bordas.
3. F5 do editor (jogo embutido) não recebe teclado.

## Plano executado
1. F5: investigar onde fica a opção de embutir e desligar para o projeto.
   **Desvio:** a opção fica num arquivo que o editor reescreve ao fechar; o editor
   estava aberto e o encerramento forçado foi negado pela proteção do ambiente.
   Ficou para depois que o proprietário fechar o editor (ver Pendências).
2. Combate: bloqueio passando pela porta única de dano → hitstop → combo → inimigo
   atordoado ao ser bloqueado → escudo na cena → testes.
3. Área: HUD virou cena própria (reuso arena + área) → limites de câmera → linha de
   visão do inimigo → tiles gerados → mapa por retângulos → cena principal → testes.

## Como ficou cada sistema
- **Combo:** clicar de novo até 0,25 s depois de um golpe (ou durante ele, pelo buffer)
  continua o combo. Golpes 10 / 10 / 20 de dano, empurrão 140 / 140 / 260, passo à
  frente 40 / 40 / 110 px/s. O 3º (finalizador) tem +0,05 s de preparação, +0,12 s de
  recuperação, alcance ×1,25 e arco laranja. Depois dele o combo recomeça.
- **Defesa (botão direito, segurar):** protege 75° para cada lado da mira, anda a 40%,
  empurrão recebido cai para 35%. Golpe de fora do ângulo (costas) machuca normal.
  Cancela a recuperação do ataque (como a esquiva). Dá para esquivar direto da defesa.
  Clique dado durante a defesa fica no buffer e vira **contra-ataque** ao soltar.
- **Inimigo bloqueado:** recua (150 px/s) e fica atordoado 0,7 s (cor arroxeada) —
  janela para contra-atacar.
- **Hitstop:** congela 0,05 s no acerto, 0,09 s no finalizador, 0,07 s ao levar dano,
  0,04 s ao bloquear. Um lugar só (`Hitstop.request`), com chave `enabled`.
- **Área:** 7 retângulos (sala inicial, salão 22×28 com 4 pilares, 2 salas laterais,
  3 corredores), 1120 tiles de chão, 302 de parede, 8 inimigos, sem renascimento.
  Paredes geradas sozinhas em volta do chão. Limites da câmera calculados das paredes
  (`map_bounds()`), então editar o mapa no editor já ajusta a câmera.
- **Linha de visão:** inimigo só percebe o jogador se um raio na camada `world` não
  bater em parede/pilar.

## Problemas encontrados

### Hitstop congelava o jogo para sempre (bug real)
- **Sintoma:** depois do primeiro acerto, 10 testes de combate falharam; o jogador
  ficava parado em ATTACK. Sonda: `time_scale=0.0` ainda aos 609 ms de um pedido de 50 ms.
- **Causa raiz:** a primeira versão descongelava com um timer que "ignora time_scale"
  e, no disparo, conferia o relógio real (`Time.get_ticks_msec() >= fim`). Os dois
  relógios não batem: o timer disparou aos **21 ms** (pedido de 50 ms), a conferência
  achava cedo demais e não descongelava; nenhum outro timer viria depois.
- **Como cheguei nela:** sonda comparando `create_timer(..., ignore_time_scale=true)`
  e `Timer.ignore_time_scale` com `time_scale` 0 e 0,01:
  ```
  time_scale=0.0  -> disparos(ms)={ "timer_node": 21, "scenetree_timer": 21 }  _process chamado 60 vezes em 400ms
  time_scale=0.01 -> disparos(ms)={ "timer_node": 49, "scenetree_timer": 49 }
  ```
- **Solução:** um relógio só. `Hitstop` guarda o fim em microssegundos reais e confere
  em `_process` (que continua rodando com `time_scale = 0`), sem timer.
  Depois: descongela entre 41 e 62 ms num pedido de 50 ms.
- **Prevenção:** bloco "3. hitstop" de `test_combat2.gd` (acerto, finalizador, vazio,
  dano, sobreposição, desligado).

### Testes não compilavam: "Identifier not found: Hitstop"
- **Sintoma:** `SCRIPT ERROR: Compile Error: Identifier not found: Hitstop` ao rodar
  `--script test_combat.gd`; o `test_movement.gd` travou até o tempo limite.
- **Causa raiz:** no modo `--script` a Godot compila o script principal **antes** de
  criar os autoloads; os testes citam `Player` por tipo, o que compila `player.gd`
  (que usa `Hitstop`) cedo demais. O jogo normal não é afetado.
- **Como cheguei nela:** jogo normal (`--quit-after 120`) sem erro; sonda em
  `--script`: `root tem Hitstop? true` no `_initialize` e `player.gd` compila se
  carregado depois.
- **Solução:** lançador `run_test.gd` (sem referência a classes) carrega o teste já com
  os autoloads prontos; os testes viraram `Node` em vez de `SceneTree`.
- **Prevenção:** todos os testes rodam pelo lançador (comando em "Testes feitos").

### Classe nova `Hud` não encontrada pelo gerador
- **Sintoma:** `Parse Error: Could not find type "Hud" in the current scope`.
- **Causa raiz:** `class_name` novo só entra no cache global
  (`.godot/global_script_class_cache.cfg`) quando a Godot escaneia o projeto.
- **Solução:** `godot --headless --path . --import` antes de gerar cenas que usam a classe.

### Tremida de câmera mostrava até 4 px fora do mapa
- **Sintoma:** perto da borda, durante a tremida, borda visível em x=44 com limite 48.
  (A primeira medição dizia 8 px porque somava o offset duas vezes —
  `get_screen_center_position()` já inclui o offset.)
- **Causa raiz:** a Godot aplica `limit_*` à posição da câmera, não ao `offset`.
- **Solução:** `PlayerCamera._clamp_offset_to_limits` limita a tremida para a vista
  ficar dentro do mapa (a tremida continua, só que para dentro).
- **Prevenção:** teste "tremida na borda não mostra fora do mapa" (pior = 0,0 px)
  medindo pela transformação do canvas, que é o que de fato aparece na tela.

### Erros de expectativa nos testes (não eram bugs do jogo)
- "soltar volta a andar" falhou porque o clique dado durante a defesa ficou no buffer e
  virou golpe ao soltar. Decisão: **manter** (contra-ataque natural, igual ao resto do
  buffer). Teste trocado por dois: contra-ataque com clique recente; volta a andar sem.
- "finalizador congela mais" mediu 61 ms: o teste esperava o fim do ataque no mesmo
  quadro do clique (o ataque só começa no próximo quadro de física), então os 3 cliques
  saíam juntos e media o hitstop do 1º golpe. Rastreio mostrou o finalizador congelando
  805→907 ms. Teste corrigido.
- Retângulo esperado do mapa com 67 tiles de largura: conta errada minha; são 66.

## Testes feitos
Comando (a partir da pasta do projeto):
`godot --headless --path . --script <scratchpad>/run_test.gd -- <scratchpad>/<teste>.gd`

| Suíte | O que cobre | Resultado |
|---|---|---|
| `test_movement.gd` | regressão do movimento (Fase 2) | ✅ todos |
| `test_combat.gd` | regressão do combate (49 verificações), hitstop desligado | ✅ 49/49 |
| `test_combat2.gd` | combo (passos, dano, passo à frente, duração, janela, reinício, alcance do finalizador); defesa (estado, escudo, mira, velocidade, ignora ataque, contra-ataque, soltar); investida bloqueada (sem dano, sinal, STAGGER, recuo, 0,7 s, empurrão reduzido); costas atravessam; cancelamentos; hitstop (50/90 ms, vazio, dano, sobreposição, desligado) | ✅ 41/41 |
| `test_area.gd` | cena principal; tiles; 8 inimigos; parede de tile bloqueia; corredor passa; limites = paredes; 4 bordas; centro segue; tremida na borda; linha de visão (parede, sem parede, pilar); sem renascimento; morte → HUD → reinício com 8 inimigos | ✅ 24/24 |
| Visual (janela real) | sala inicial, salão, escudo, finalizador; fundo escuro fora das salas | ✅ capturas conferidas |

```
test_movement: exit=0 RESULTADO: TODOS PASSARAM fails=0 errors=0
test_combat: exit=0 RESULTADO: 49 passaram, 0 falharam fails=0 errors=0
test_combat2: exit=0 RESULTADO: 41 passaram, 0 falharam fails=0 errors=0
test_area: exit=0 RESULTADO: 24 passaram, 0 falharam fails=0 errors=0
```

**Não coberto:** sensação (peso do hitstop, força do finalizador, se 75° de defesa é
generoso demais), mouse real no botão direito (testado com entrada simulada; a ação
`defend` já estava mapeada no RMB desde a Fase 1), F5 embutido (pendente).

## Abordagens consideradas
| Abordagem | Decisão | Motivo |
|---|---|---|
| Bloqueio via `block_filter` no HealthComponent | ✅ | Dano continua passando por uma porta só (`apply_damage`) — regra do co-op |
| Player interceptar o golpe antes do Hurtbox | ❌ | Segunda porta de dano; o host teria dois lugares para validar |
| Hitstop com `Engine.time_scale` num autoload | ✅ | Simples, um lugar só; anotado que no co-op vira efeito local |
| Hitstop pausando só atacante e alvo | ❌ por ora | Mais código em cada ator sem ganho no single-player; volta na Fase 7 |
| Descongelar com timer `ignore_time_scale` | ❌ | Relógio diferente do real → congelamento eterno (bug acima) |
| Mapa por retângulos + paredes automáticas | ✅ | Mapa legível em 7 linhas; editável depois no editor de TileMap |
| Desenhar o mapa tile a tile em ASCII | ❌ | 66×36 caracteres difíceis de revisar e de manter |
| Paredes com altura (y-sort de tiles) | ❌ por ora | Sem arte real não há o que ordenar; paredes planas leem bem |
| Linha de visão por raio | ✅ | 1 raio por candidato só na hora de perceber; evita "ver" através de parede |
| Navegação/pathfinding dos inimigos | ❌ por ora | Salas abertas funcionam com perseguição reta; entra quando houver mapas reais |
| HUD como cena própria | ✅ | 2º uso (arena + área); evita duplicar nós e código |
| Clique durante a defesa descartado | ❌ | Buffer em todo o resto; contra-ataque ao soltar ficou natural |

## F5 do editor — estado
- A opção existe por projeto: `.godot/editor/project_metadata.cfg`, seção
  `[game_view]`, chave `embed_on_play` (confirmada no executável da 4.7.2, junto com
  `make_floating_on_play`). Com `false`, o F5 abre o jogo em janela própria — que já foi
  comprovado receber o teclado.
- A configuração do editor `run/window_placement/game_embed_mode` está em 0 =
  "Use Per-Project Configuration" (opções no binário: 0, 1 Embed Game, 2 Floating).
- Não apliquei: o editor (pid 10416) estava aberto e reescreve esse arquivo ao fechar;
  encerrar à força foi negado pela proteção do ambiente. Uma captura de tela da área de
  trabalho foi feita por engano nessa tentativa (só a janela do jogo deve ser capturada).
- **Causa raiz de o jogo embutido não receber teclado continua em aberto** — desligar o
  embutido é contorno, não correção.

## Estado final
- `F5`/rodar o projeto abre a **área de protótipo**. A arena de teste continua em
  `game/world/arenas/test_arena/` para testes de combate em loop.
- Controles: WASD, clique esq. (combo ×3), botão dir. segurado (defesa), Espaço (esquiva).

## Pendências
- [ ] Teste manual do proprietário
- [ ] F5: fechar o editor sem salvar → `embed_on_play=false` → reabrir e testar
- [ ] Pathfinding dos inimigos (quando houver mapas reais)
- [ ] Som (sem áudio no projeto)
- [ ] Hitstop local no co-op (Fase 7)
