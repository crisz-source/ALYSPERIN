# Aviso da investida, esquiva perfeita e objetos interativos (fim da Fase 4)

- **Data:** 2026-11-07
- **Status:** concluído nos testes automáticos; teste manual do proprietário pendente
- **Pedido:** "antes do inimigo atacar, mostrar onde ele vai atacar para que o personagem
  consiga usar a esquiva, e aparecer uma mensagem no momento da esquiva 'dodge success'
  algo assim. Feito isso, pode prosseguir para os próximos passos". Próximo passo do
  cronograma: "Objetos interativos" (único item da Fase 4 que faltava).
- **Arquivos tocados:**
  - novos: `game/ui/floating_text/floating_text.gd`, `game/components/interactable.gd`,
    `game/world/objects/door/` (`door.gd`, `door.tscn`), `game/world/objects/lever/`
    (`lever.gd`, `lever.tscn`), `game/world/objects/sign_post/` (`sign_post.gd`, `sign_post.tscn`)
  - modificados: `basic_enemy.gd` (+ `.tscn`, nó `LungeTelegraph`), `health_component.gd`
    (sinal `hit_ignored`), `player.gd` (esquiva perfeita, interação), `player_input.gd`
    (tecla E com buffer), `player.tscn` (`InteractionDetector`, `InteractPrompt`),
    `hud.gd` + `hud.tscn` (caixa de mensagem), `prototype_area.tscn` (porta, alavanca,
    placa), `test_arena.tscn` (texto de ajuda)

## O que foi feito
- **Aviso da investida:** durante a preparação aparece no chão uma faixa vermelha do
  tamanho exato da área atingida (largura da LungeHitbox, comprimento =
  velocidade × duração + meia hitbox). A mira acompanha o jogador e **trava nos últimos
  0,2 s** (faixa mais forte). A investida sai na direção travada, e não mais na posição
  atual do jogador: o aviso nunca mente, e tanto esquivar quanto sair da faixa funcionam.
- **Esquiva perfeita:** golpe que encosta durante a invencibilidade do rolamento mostra
  "Esquiva perfeita!" (texto azul que sobe e some, preso no mundo). Uma mensagem por
  esquiva; não conta se a invulnerabilidade for a pós-dano. Texto escolhido em português
  para combinar com o resto da interface (constante `DODGE_SUCCESS_TEXT`).
- **Interação (E):**
  - `Interactable`: área na camada `interactable`; o dono registra `handler`
    (mesmo padrão do `block_filter`), que devolve a mensagem para o HUD.
  - Jogador: `InteractionDetector` (raio 14 px) escolhe o objeto usável mais próximo e
    mostra "[E] <verbo>" acima dele; E com buffer de 0,2 s, só sai quando o jogador está
    livre (não interrompe golpe).
  - HUD: caixa de mensagem embaixo; o tempo na tela cresce com o tamanho do texto (2,5–7 s).
  - Objetos provisórios: **placa** (texto), **porta** (fechada bloqueia passagem e visão;
    pode exigir mecanismo), **alavanca** (abre as portas escolhidas no Inspetor; uso único).
  - Na área: placa na sala inicial; porta fechando o corredor para a sala sudeste;
    alavanca na sala nordeste.

## Problemas encontrados

### Velocidade da investida só aplicada no 2º quadro (comportamento, não bug)
- **Sintoma:** teste "investida sai na direção do aviso" falhou com `vel=0.00` no primeiro
  quadro em que o estado já era LUNGE.
- **Causa:** a troca WINDUP → LUNGE acontece no fim do processamento da preparação; o
  `velocity` daquele quadro ainda é o da preparação (≈0). A velocidade da investida é
  aplicada a partir do quadro seguinte — e o quadro em que a investida termina também se
  move. Total: 14 quadros × 190/60 ≈ 44 px (a faixa desenha 41,8 px + meia hitbox).
- **Decisão:** manter. A diferença de ~2 px na ponta não muda a leitura do aviso.
  Teste corrigido para medir no quadro seguinte.

### Teste do E durante o ataque esperava algo errado
- Um E apertado no começo do golpe (0,3 s) expira no buffer (0,2 s) antes do fim — correto
  pelo desenho. O teste passou a apertar E na recuperação, que cabe no buffer.

## Testes feitos
Comando: `godot --headless --path . --script <scratchpad>/run_test.gd -- <scratchpad>/<teste>.gd`

| Suíte | O que cobre | Resultado |
|---|---|---|
| `test_feedback_interact.gd` | aviso: escondido ao perseguir, aparece na preparação, aponta para o jogador, comprimento 48,8, acompanha, trava (cor), não acompanha travado, investida na direção do aviso, some na investida, sair da faixa evita; esquiva perfeita: sem dano, sinal 1×, texto certo, sobe, preso no mundo, some; não conta pós-dano nem fora da invencibilidade; interação: vazio, placa (foco, aviso, mensagem, some), porta trancada (bloqueia, aviso, mensagem, bloqueia visão), alavanca (aviso, abre, mensagem, uso único, não fecha), porta aberta (sem aviso, passa, inimigo enxerga), E não interrompe golpe e sai do buffer | ✅ 39/39 |
| Regressão | `test_movement`, `test_combat` (49), `test_combat2` (41), `test_area` (24) | ✅ todas |
| Visual (janela real) | placa + mensagem, aviso travado, "Esquiva perfeita!", porta com "[E] Abrir" | ✅ capturas conferidas |

```
RESULTADO: 39 passaram, 0 falharam
test_movement: RESULTADO: TODOS PASSARAM errors=0
test_combat: RESULTADO: 49 passaram, 0 falharam errors=0
test_combat2: RESULTADO: 41 passaram, 0 falharam errors=0
test_area: RESULTADO: 24 passaram, 0 falharam errors=0
```

**Não coberto:** tecla E real (simulada pela mesma interface do teclado; a ação
`interact` está mapeada no E desde a Fase 1); sensação do tempo de reação com a mira
travada em 0,2 s.

## Abordagens consideradas
| Abordagem | Decisão | Motivo |
|---|---|---|
| Mira acompanha e trava nos últimos 0,2 s | ✅ | Aviso sempre verdadeiro; ainda exige atenção (não dá para sair cedo demais) |
| Mira travada desde o início da preparação | ❌ | Fácil demais: basta dar um passo para o lado no começo |
| Mirar no jogador no instante da investida (como antes) | ❌ | O aviso mentiria: a investida sairia para outro lugar |
| Sinal `hit_ignored` no HealthComponent + Player decide | ✅ | Não cria nova porta de dano; quem sabe se é esquiva é o Player |
| Hitbox avisar "errei por invencibilidade" | ❌ | Lógica de esquiva espalhada nos atacantes |
| Texto flutuante como filho com `top_level` | ✅ | Some junto com o jogador ao trocar de cena; não precisa procurar o pai |
| Mensagem de objeto sobe pelo Player → HUD | ✅ | HUD por jogador (pensando no co-op); objetos não procuram o HUD |
| Objetos procurarem o HUD por grupo | ❌ | Acoplamento global; no co-op cada jogador tem o seu |
| Porta montada por script a partir de `size_tiles` | ✅ | Cada porta com tamanho próprio sem compartilhar a mesma forma de colisão |
| Baú com itens | ❌ por ora | Depende do inventário (Fase 5), que exige decisões do proprietário |

## Pendências
- [ ] Teste manual do proprietário
- [ ] Fase 5 (inventário, itens, equipamento, armas, habilidades, progressão): apresentar opções
- [ ] F5 do editor: fechar o editor sem salvar → `embed_on_play=false` (ver worklog anterior)
- [ ] Som (sem áudio no projeto)
