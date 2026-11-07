# Teclas F/I, barra de habilidades estilo hotbar, consumíveis na barra, dano na tela, mana só com itens

- **Data:** 2026-11-07
- **Status:** concluído nos testes automáticos; teste manual do proprietário pendente
- **Pedidos do proprietário (várias mensagens):** mana sem recuperação automática (só itens);
  sem sistema de pontos; nível máx. 60; remover ponto de descanso; interagir no F; barra de
  habilidades no centro embaixo com 1–9 e F1–F12; barra de vida dos monstros; números de
  dano; arrastar consumíveis para a barra; marcadores ! ? *; inventário no I.
- **Arquivos principais:** `character_stats.gd` (reescrito), `mana_component.gd`,
  `consumable_data.gd`, `player.gd`, `player_input.gd`, `hud.gd`, `inventory_screen.gd`,
  `floating_text.gd`, `basic_enemy.gd`, `npc.gd`, `dialogue_box.gd`, `interactable.gd`,
  `game_area.gd`, `project.godot` (teclas); removidos `game/world/objects/checkpoint/*`.

## O que foi feito
- **Mana:** `regen_per_second = 0`; `ConsumableData.mana_amount`; Poção de mana (+25):
  1 inicial, 2 no chão, 1 no baú NE. Item com efeito inútil (vida/mana cheia) não é gasto.
- **Progressão:** sem pontos; +8 vida, +2 mana, +10% dano por nível; máximo 60 (exp. para).
- **Descanso removido:** continuar após a morte volta ao início da área (vida e mana cheias).
- **Teclas:** `interact` = F, `inventory` = I, `ability_1..9` = 1–9, `ability_f1..f12` = F1–F12
  (todas com `device = -1`, tecla física). Avisos "[F] ...".
- **Barra de habilidades:** 21 espaços no centro embaixo (F1–F12 em cima, 1–9 embaixo);
  vazio mostra só a tecla.
- **Consumíveis na barra:** arrastar do inventário (I) para um espaço sem habilidade; a
  tecla usa a primeira pilha do item na bolsa; contador "xN" (fica x0 sem apagar o atalho);
  clique direito tira. Cliques do inventário passaram a valer ao **soltar** (apertar e
  arrastar não usa o item).
- **Monstros:** barra de vida sempre visível enquanto vivos; **números de dano** (inimigo:
  branco→amarelo e maior com o dano; jogador: vermelho). O número é filho de quem bateu, para
  não sumir junto com o inimigo morto.
- **Missões:** marcador ! (nova), ? (em andamento), * (pronta).
- **Documentos:** design v2 (decisões), chefes aprovados com regra de Fúria (70/50/20%).

## Problemas encontrados

### Arrastar para a barra não funcionava com o mouse de verdade (bug real)
- **Sintoma:** teste de arraste real (eventos de mouse pela interface) falhou: item não ia para a barra.
- **Causa raiz:** a raiz da tela de inventário (`Control` de tela cheia, camada 5) tinha
  `mouse_filter = STOP` e ficava por cima do HUD → engolia o "soltar" sobre a barra.
- **Como cheguei nela:** instrumentação: `gui_get_hovered_control()` no ponto de soltar =
  `InventoryScreen/Root`. Depois da correção: `Hud/AbilityBar/Ability4`. Contraprova: o mesmo
  teste com a raiz forçada de volta para STOP falha de novo.
- **Solução:** raiz com `MOUSE_FILTER_IGNORE` (só o painel captura). Regra em CONVENCOES.
- **Prevenção:** `test_drag_real.gd` (arraste real) — 2/2.
- **Observação:** o teste simulado também precisava informar `relative` no movimento do
  mouse (a Godot soma o deslocamento para iniciar o arraste) — limitação da simulação.

### Lista de habilidades vazia ao trocar o script num nó existente (pego na revisão)
- `_ability_buffers` era preenchida no `_ready`; trocar o script de um nó já na cena (entrada de
  rede/testes) não chama `_ready` → índice inválido. Agora é criada na declaração.

### Vazamento de memória nos testes (miniatura do arraste)
- Chamar a função de arraste fora de um arraste real criava a miniatura sem dono. Separado em
  `drag_payload()` (dados, testável) e `_drag_data()` (miniatura, só no arraste real).

## Testes feitos
| Suíte | Resultado |
|---|---|
| `test_round7.gd` (tecla I/F, arrastar só consumível, espaço com magia recusa, usar pela tecla, x0/x3, tirar, poção na F2, barra de vida, números e tamanhos, número do golpe final persiste, dano vermelho no jogador) | ✅ 21/21 |
| `test_drag_real.gd` (arraste com mouse real até o espaço 4; não gasta) | ✅ 2/2 |
| Regressão (12 suítes, ajustadas para crescimento automático, sem descanso, [F], 21 espaços, marcadores) | ✅ todas, 0 erros/avisos |

**Não coberto:** teclas físicas F1–F12 numa janela real (mapeamento conferido no InputMap;
dentro do editor, algumas F são atalhos do próprio editor).

## Pendências
- [ ] Teste manual do proprietário
- [ ] Decisão sobre o modo 3D em terceira pessoa (ver resposta no chat)
- [ ] Etapa A (6 classes × 3 disciplinas)
