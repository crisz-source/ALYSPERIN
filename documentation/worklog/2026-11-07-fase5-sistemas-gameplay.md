# Fase 5 — Sistemas de gameplay (inventário, equipamento, itens, armas, habilidades, progressão)

- **Data:** 2026-11-07
- **Status:** concluído nos testes automáticos; teste manual do proprietário pendente
- **Pedido:** "pode fazer tudo isso ai! que testamos depois" — em resposta às opções
  apresentadas. Adotei as recomendações: inventário de vagas fixas (8), durabilidade
  que enfraquece sem sumir, progressão por nível com pontos escolhidos (Vigor/Força).
- **Arquivos novos:**
  - itens: `game/items/item_data.gd`, `weapon_data.gd`, `shield_data.gd`,
    `consumable_data.gd`, `item_stack.gd`, `game/items/data/*.tres` (6 itens provisórios)
  - inventário: `game/inventory/inventory.gd`, `equipment.gd`
  - progressão: `game/actors/player/character_stats.gd`
  - habilidades: `game/abilities/ability_data.gd`, `spin_slash_data.gd`,
    `game/abilities/data/spin_slash.tres`
  - mundo: `game/world/objects/item_pickup/` e `game/world/objects/chest/` (script + cena)
  - interface: `game/ui/inventory/inventory_screen.gd` + `.tscn`
- **Modificados:** `player.gd` (+ `.tscn`), `player_input.gd`, `basic_enemy.gd`,
  `health_component.gd` (`set_max_health`), `hud.gd` (+ `.tscn`), `prototype_area.gd`
  (+ `.tscn`), `test_arena.gd` (+ `.tscn`)

## Como ficou
| Sistema | Regra |
|---|---|
| Inventário | 8 vagas fixas (`expand()` para crescer no futuro). Ervas empilham até 5; armas/escudos não. |
| Equipamento | 1 arma + 1 escudo, fora das vagas. Equipar troca: o antigo volta para a mesma vaga. Desequipar exige vaga livre. |
| Armas | Espada curta (10, normal, 80 dur.), Machado pesado (18, lento ×1,35, 45 dur.), Lâmina leve (7, rápida ×0,75, 60 dur.). Sem arma: soco de 4, alcance ×0,7. Combo usa multiplicadores ×1, ×1, ×2. |
| Escudos | Madeira (150°, 40 dur.), Reforçado (170°, 80 dur.). **Sem escudo não há defesa.** |
| Durabilidade | Arma −1 por inimigo acertado (golpe ou habilidade); escudo −1 por bloqueio. Quebrada: arma causa 40%; escudo deixa passar 50% do dano. Aviso "Arma quebrou!"/"Escudo quebrou!". Reparo: ainda não existe. |
| Consumível | Erva medicinal: +30 de vida; com vida cheia não gasta. |
| Progressão | 10 exp. por inimigo (para quem deu o último golpe). Nível N→N+1 custa 30×N. 1 ponto por nível: Vigor (+10 vida máx., enche os 10) ou Força (+8% dano). Aviso "Nível N!". |
| Habilidades | 6 espaços (teclas 1–6). Golpe giratório na tecla 1: nível 2, recarga 4 s, círculo de 30 px, 1,5× o dano da arma. Tecla bloqueada avisa o nível. |
| Mundo | Itens no chão ("[E] Pegar ..."), baús ("[E] Abrir", o que não cabe fica). Descartar da bolsa cria item no chão com a mesma durabilidade. Na área: lâmina + 2 ervas soltas; baú NE (machado + 2 ervas); baú SE atrás da porta (escudo reforçado + erva). |
| Tela (Tab) | Bolsa, equipamento com barra de durabilidade, detalhes ao passar o mouse, nível/exp./vida, [+] para pontos. Clique = usar/equipar/tirar; botão direito = descartar. **Não pausa o jogo** (co-op); o personagem fica parado com a tela aberta. |
| HUD | "Nv N", barra de experiência, barra de habilidades com recarga e cadeado. |

**Decisão registrada:** morrer recomeça a área do zero, inclusive itens e experiência
ganhos nela (equivale a carregar o início da área). Sistema de salvamento fica para depois.

## Problemas encontrados

### Comando de edição quebrado pelo terminal (não chegou a rodar)
- **Sintoma:** `bash: unexpected EOF while looking for matching ''` ao mandar um script
  Python longo direto no terminal.
- **Causa:** o texto embutido confundiu as aspas do terminal antes de chegar ao Python.
- **Solução:** scripts de edição longos gravados em arquivo (scratchpad) e executados de lá.
  Conferido com `git status` que nada tinha sido alterado pela tentativa.

### HUD procurava o jogador por grupo global (pego na revisão, antes de rodar)
- `get_first_node_in_group("players")` daria o jogador errado no co-op. Trocado por
  guardar o jogador recebido em `bind_player`.

Nenhum outro problema: os 5 blocos passaram nos testes de primeira.

## Testes feitos
Comando: `godot --headless --path . --script <scratchpad>/run_test.gd -- <scratchpad>/<teste>.gd`

| Suíte | O que cobre | Resultado |
|---|---|---|
| `test_inventory.gd` | ItemStack (durabilidade, quebra, cópia), Inventory (empilhar, limite, cheio, parcial, remover, expandir), Equipment (troca, tipo errado), CharacterStats (níveis múltiplos, pontos) | ✅ 35/35 |
| `test_items_combat.gd` | equipamento inicial; dano por arma (10/18/7/4) e velocidade; desgaste por acerto, não no vazio, quebra com aviso, 40%; escudo obrigatório, desgaste, quebrado 15→8, ângulo do item; exp. por abate, nível, Vigor 110 e HUD, Força 11; erva (cheia/cura), equipar da bolsa preservando durabilidade, desequipar com bolsa cheia, descartar | ✅ 35/35 |
| `test_world_items.gd` | pegar item, bolsa cheia, pegar parcial; baú cheio/resto/tudo/mensagem/vazio; descartar → chão → pegar de volta com durabilidade | ✅ 17/17 |
| `test_inventory_ui.gd` | Tab abre/fecha, Esc fecha, bloqueia o jogador; vagas e cores; barra de durabilidade 25% vermelha; **clique de mouse real** na erva; equipar/descartar/tirar; detalhes; [+]; HUD "Nv 2" e barra de exp.; morto não abre | ✅ 26/26 |
| `test_abilities.gd` | bloqueada no nível 1 com aviso e cadeado; giro acerta os dois lados (15), não acerta a 60 px; desgaste; recarga 4 s e sombra no HUD; usa o dano da arma (27 com machado); dano interrompe | ✅ 17/17 |
| Regressão | movimento, combate (49), combate 2 (41), área (24), aviso/esquiva/interação (39) | ✅ todas |
| Visual (janela real) | baú/itens/alavanca, tela de inventário, golpe giratório, HUD | ✅ capturas conferidas |

```
test_inventory: 35/35  test_items_combat: 35/35  test_world_items: 17/17
test_inventory_ui: 26/26  test_abilities: 17/17
test_movement: TODOS  test_combat: 49/49  test_combat2: 41/41  test_area: 24/24  test_feedback_interact: 39/39
(0 SCRIPT ERROR, 0 WARNING em todas)
```

**Não coberto:** teclas reais Tab/1 (simuladas pelo mesmo caminho de ações; Tab também
testado via `InputEventAction`), equilíbrio (durabilidade, preço dos níveis, força do giro),
legibilidade da fonte padrão em tamanho 8 na tela de inventário.

## Abordagens consideradas
| Abordagem | Decisão | Motivo |
|---|---|---|
| Vagas fixas (8) | ✅ | Recomendada e aprovada; simples, tensão de escolha, boa no co-op |
| Grade com tamanhos / peso | ❌ | Interface mais complexa / menos tensão |
| Quebrado = mais fraco | ✅ | Pune sem frustrar |
| Quebrado = some | ❌ | Frustrante sem sistema de reparo |
| Itens como Resource (.tres) + ItemStack | ✅ | Editável no Inspetor; molde separado de "item com durabilidade" |
| Equipamento dentro das vagas | ❌ | Ocuparia a bolsa limitada com o que já está na mão |
| Escudo obrigatório para defender | ✅ | Dá sentido ao item e à durabilidade |
| Pausar com o inventário aberto | ❌ | No co-op não dá; o personagem só fica parado |
| Tela montada por código | ✅ (provisório) | Sem arte ainda; quando houver, vira cena desenhada no editor |
| Morte mantém itens/exp. | ❌ | Baús renascem com a área → daria para repetir e acumular |
| Exp. para quem deu o último golpe | ✅ por ora | Divisão no co-op fica para a Fase 7 (host decide) |
| Habilidade como Resource + execução no Player | ✅ | Estrutura pronta para 6 espaços; Disciplinas (Fase 6) vão definir quais |

## Pendências
- [ ] Teste manual do proprietário
- [ ] Reparo de armas/escudos (decidir como: item, NPC, bancada)
- [ ] Ícones reais dos itens/habilidades; fonte de pixel art
- [ ] Salvamento (hoje a morte recomeça a área)
- [ ] Fase 6: Disciplinas, NPCs, missões, dungeons, chefes, magia, enigmas
