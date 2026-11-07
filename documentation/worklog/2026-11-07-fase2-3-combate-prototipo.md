# Fase 2 (etapas 2–3) + Fase 3 — Protótipo de combate

- **Data:** 2026-11-07
- **Status:** concluído — testes automáticos 49/49 e teste manual do proprietário ok
- **Pedido:** proprietário pediu "5 etapas de uma vez, no final eu testo". Os detalhes
  de sensação foram decididos por mim com valores ajustáveis no Inspetor (lista abaixo).
- **Arquivos tocados:**
  - novos: `game/combat/damage_info.gd`, `game/components/health_component.gd`,
    `hurtbox.gd`, `hitbox.gd`, `game/actors/player/player_camera.gd`,
    `game/actors/enemies/basic_enemy/basic_enemy.gd` + `.tscn`,
    `game/world/arenas/test_arena/test_arena.gd`
  - modificados: `player.gd` (máquina de estados), `player_input.gd` (buffer + mira),
    `player.tscn`, `test_arena.tscn` (recriados por script; versões anteriores no
    commit `23af053`)

## Etapas
1. **Vida e dano** — `HealthComponent` (único lugar que decide dano/morte, emite
   `health_changed`, `damaged`, `died`), `Hurtbox` (área que recebe golpe),
   `Hitbox` (área que causa golpe; 1 acerto por alvo por ativação, ou repetição
   com `rehit_interval`), `DamageInfo` (pacote do golpe).
2. **Ataque com espada** — mira no mouse; preparação 0,06 s → lâmina ativa 0,10 s →
   recuperação 0,14 s; arco de 130° com 24 px de alcance; pode andar a 30% da
   velocidade durante o golpe; **input buffer** de 0,2 s.
3. **Esquiva** — rolamento 230 px/s por 0,24 s (~55 px), invencível nos primeiros
   0,18 s, recarga de 0,45 s; direção = movimento (ou para onde está virado);
   cancela a recuperação do ataque (não a preparação nem a lâmina).
4. **Inimigo básico** — parado → percebe a 130 px → persegue a 45 px/s → a 40 px
   avisa (laranja pulsando, 0,45 s) → investida 190 px/s por 0,22 s → 0,6 s
   vulnerável. Escolhe o jogador vivo **mais próximo do grupo `players`** (já
   pensado para o co-op). 30 de vida (3 golpes).
5. **Reações e feedback** — empurrão nos dois lados, clarão branco ao levar dano,
   atordoamento curto, piscar durante invulnerabilidade pós-dano (0,7 s), tremida de
   câmera arredondada em pixel inteiro, barra de vida do jogador (HUD) e do inimigo,
   morte do inimigo com desvanecimento e reaparecimento após 4 s, morte do jogador
   com mensagem e reinício da arena após 2 s.

## Problemas encontrados

### Golpe guardado no buffer era perdido no fim do ataque
- **Sintoma:** teste "clique durante o golpe sai em seguida" falhava: clique dado no
  meio da lâmina ativa não gerava o segundo golpe.
- **Causa raiz:** ao fim do ataque o estado mudava para MOVE e só no **quadro
  seguinte** o MOVE checava o buffer; nesse quadro extra o `poll()` descontava mais
  1/60 s e o comando (0,2 s) já tinha expirado. Conta: clique em t≈0,117 s, ataque
  termina em 0,30 s → faltam 0,183 s + 1 quadro (0,017) = 0,2 s.
- **Solução:** no quadro em que o ataque termina, se houver ataque guardado, o próximo
  começa ali mesmo (`player.gd`, fim de `_process_attack`).
- **Prevenção:** teste 2c. Antes da correção: FAIL; depois: PASS, sem outra mudança
  nessa parte do código.

### Corpo de inimigo morto bloqueava outros inimigos
- **Sintoma:** teste "investida machuca o jogador" falhava (hp 100 → 100).
- **Como cheguei nela:** rastreio quadro a quadro da investida isolada mostrou que ela
  **acerta** (`f=107 ... php=85`). A diferença na suíte: um inimigo morto num teste
  anterior ficou parado em (530, 300) — o teste tinha desligado a física dele e o
  desvanecer roda na física — e os inimigos colidem entre si (máscara world|enemy):
  a investida batia no corpo morto.
- **Causa raiz (do teste):** estado deixado pelo próprio teste.
- **Causa raiz (do jogo, revelada):** mesmo no jogo normal, durante os 0,4 s de
  desvanecimento o corpo morto continuava colidindo.
- **Solução:** ao morrer, o inimigo desliga a própria `CollisionShape`
  (`set_deferred("disabled", true)`); o teste religa a física do inimigo antes de
  esperar o desvanecimento.
- **Prevenção:** teste "corpo morto para de colidir".

### Teste de fim da invulnerabilidade media cedo demais
- **Sintoma:** FAIL com `t=0.17` (janela é 0,18).
- **Causa raiz:** erro de contagem de quadros no teste, não no jogo.
- **Solução:** o teste espera até `_state_time >= dodge_invulnerability`.

### Captura de tela confusa (não era bug)
Na primeira captura o inimigo 1 "sumiu": o inimigo 2, posicionado perto demais na
preparação da cena, deu uma investida e empurrou o jogador para cima do inimigo 1.
Refeita com inimigos separados e posições impressas: tudo no lugar.

## Testes feitos
Suíte `test_combat.gd` (scratchpad) com `fake_input.gd` — um `PlayerInput` falso,
com a mesma interface que a entrada de rede usará no co-op.

| Bloco | Verificações | Resultado |
|---|---|---|
| 1. HealthComponent | dano, zero, invulnerável, cura limitada, morte sem negativo, nada após morte, `died` 1× | ✅ 9/9 |
| 2. Ataque | clique real inicia; acerta na mira (30→20); inimigo reage; empurrão; vira para a mira; 1 acerto por golpe; mira oposta não acerta; buffer; sem golpe extra; morre em 3; corpo não colide; some; reaparece | ✅ 15/15 |
| 3. Esquiva | estado, velocidade 230, invulnerável, dano bloqueado, vulnerável após 0,18 s, distância, recarga, não corta preparação, guardada sai na recuperação | ✅ 10/10 |
| 4. IA | parado longe; percebe e persegue; aproxima; avisa; investida −15; jogador reage; HUD; câmera treme; invulnerável; acaba; golpe interrompe investida | ✅ 11/11 |
| 5. Morte | morre; mensagem; morto não ataca; arena reinicia; vida cheia | ✅ 5/5 |
| Regressão | `test_movement.gd` da etapa 1 | ✅ todos |
| Visual | janela real: arco da espada, empurrão (536→554), barra do inimigo, aviso laranja | ✅ capturas conferidas |

```
RESULTADO: 49 passaram, 0 falharam
```

**Não coberto:** sensação ao jogar (peso do golpe, tempos, dificuldade do inimigo),
mira com mouse real (testada com mira injetada + clique real), som (não há áudio no
projeto ainda).

## Decisões de sensação tomadas por mim (ajustáveis no Inspetor)
| Valor | Escolha | Onde |
|---|---|---|
| Andar durante o ataque | sim, a 30% | Player → Ataque |
| Arco/alcance da espada | 130° / 24 px | gerado na cena (SwordHitbox) |
| Dano espada / investida | 10 / 15 | SwordHitbox, LungeHitbox |
| Vida jogador / inimigo | 100 / 30 | HealthComponent |
| Esquiva | 55 px, 0,18 s invencível, recarga 0,45 s | Player → Esquiva |
| Hitstop (congelar 1–2 quadros no impacto) | **não feito** | mexeria no tempo global; no co-op isso afeta todos os jogadores — avaliar depois |

## Abordagens consideradas
| Abordagem | Decisão | Motivo |
|---|---|---|
| Componentes Hitbox/Hurtbox/Health | ✅ | Reutilizáveis por qualquer ator; uma única porta de dano (preparação para autoridade do host) |
| Dano direto via `body_entered` no inimigo | ❌ | Lógica espalhada por cada ator, difícil de replicar em rede |
| Hitbox varrendo sobreposições a cada quadro | ✅ | Pega alvos que já estavam encostados na ativação |
| Só sinal `area_entered` | ❌ | Perde o alvo que já estava dentro quando a lâmina liga |
| Máquina de estados com `enum` | ✅ | 5 estados cabem num arquivo; nós-estado separados só se crescer |
| Timers com `await` na arena | ❌ | Podem retomar sobre nó já liberado após reinício; trocado por conexão de sinal |
| Jogador colidir com corpo do inimigo | ❌ | Em ação top-down trava o jogador; inimigos atravessam o jogador e machucam só na investida |

## Pendências
- [x] Teste manual do proprietário: atacar, esquivar, barra de vida — "tudo funcionando perfeitamente"
- [x] Commit
- [ ] Combo de 3 golpes, defesa (botão direito), som, hitstop — próximas iterações
- [ ] F5 no editor (modo embutido) continua sem teclado — contorno: janela própria
