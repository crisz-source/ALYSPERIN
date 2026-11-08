# Animação de combate por código (PlayerAnimator)

- **Data:** 2026-11-08
- **Status:** concluído
- **Arquivos tocados:** `game/actors/player/player_animator.gd` (novo), `game/actors/player/player.gd`,
  `game/actors/player/player.tscn` e áreas (regeneradas pelo `build_3d_core.gd`)

## Objetivo
Passo 1 do plano: as armas ficavam paradas na mão. Animar ataque, defesa, esquiva, dano,
morte, habilidades e andar sem arte nova e sem mudar nenhuma regra de jogo.

## Plano executado
1. `PlayerAnimator` (filho do Player): lê estado e tempos e calcula uma pose (mãos + inclinação,
   giro e balanço do corpo), seguida suavemente (`FOLLOW_RATE` 30/s). No golpe a mão segue a pose
   exata, sem suavizar, porque a fase ativa dura só 0,1 s.
2. Player expõe leituras: `state_time()`, `combo_step()`, `attack_phase_times()`, `active_ability()`.
3. O animador passa a ser o único dono do transform do `Model` (o Player deixou de girar e achatar o
   Model): sem dois lugares escrevendo no mesmo nó.
4. Espada provisória passou para dentro de `RightHand` (anima junto quando a arma não tem modelo).
5. Poses: combo direita→esquerda, esquerda→direita, finalizador de cima para baixo (fases =
   tempos reais do golpe, então o malho anima 1,2x mais devagar); escudo à frente na defesa;
   empurrão no Golpe de escudo; corpo mergulha na esquiva; recua ao levar dano; cai de lado na
   morte; giro completo no Golpe giratório; cajado erguido na cura e apontado no Raio sagrado;
   braço levantado no Provocar; balanço ao andar; respiração parado.

## Problemas encontrados
Nenhum no jogo. Três erros na suíte nova (todos do teste):

### Suíte travava até o tempo limite
- **Sintoma:** processo não terminava; log: `Invalid assignment of property or key 'current_mana'`.
- **Causa raiz:** nome errado (ManaComponent usa `restore_full()`); o erro interrompe a rotina antes do `quit()`.
- **Solução:** `mana.restore_full()`.

### "golpe 2 começou" falhava
- **Causa raiz:** o golpe guardado sai no mesmo quadro em que o anterior acaba (comportamento do
  jogo, `_process_attack`), então o estado nunca sai de ATTACK; o teste esperava a troca de estado
  e atravessou o golpe 2 inteiro.
- **Solução:** esperar a troca de `combo_step()`.

### "giro começou" falhava
- **Hipótese descartada:** quadro de física não processado (com 2 quadros continuou falhando).
- **Causa raiz:** Golpe giratório libera no nível 2; o jogador do teste estava no nível 1. Achado
  ligando o sinal `message_requested`: `Golpe giratório: liberada no nível 2.`
- **Solução:** `gain_xp(30)` antes do teste.

## Testes feitos
| # | O que testa | Resultado |
|---|---|---|
| 1 | 11 suítes existentes (lógica não mudou) | ✅ 270, 0 falhas |
| 2 | `test3d_anim.gd` (nova): repouso, direção, 3 golpes do combo nas fases certas, volta ao repouso, malho mais lento, defesa, esquiva, giro, cura, projétil, morte e renascer | ✅ 29, 0 falhas |
| 3 | Folha de contato com 10 poses (cena de visualização) | ✅ conferida |

## Abordagens consideradas
| Abordagem | Decisão | Motivo |
|---|---|---|
| Animação por código lendo o estado | ✅ | sem arte nova; segue os tempos reais do golpe; some quando houver modelo animado |
| AnimationPlayer com trilhas feitas à mão | ❌ | tempos do golpe variam por arma/finalizador; teria que esticar cada trilha |
| Tweens disparados nos eventos | ❌ | cancelamentos (esquiva/defesa na recuperação) deixariam tweens pela metade |

## Pendências
- [ ] Trocar por animações de verdade quando houver modelo de personagem com esqueleto.
- [ ] Inimigo ainda sem animação de corpo.
