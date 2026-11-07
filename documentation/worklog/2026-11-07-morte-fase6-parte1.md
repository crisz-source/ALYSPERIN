# Morte com "continuar", Disciplinas provisórias, magia, NPC e missões (Fase 6, parte 1)

- **Data:** 2026-11-07
- **Status:** concluído nos testes automáticos; teste manual pendente. As Disciplinas
  desta etapa são PROVISÓRIAS e serão substituídas pelo sistema de 6 classes × 3
  disciplinas enviado pelo proprietário logo depois (ver `documentation/design/`).
- **Pedidos:** (1) "quando morrer, aparecer 'Você morreu!' e 'Deseja continuar? Sim ou
  Não' — a funcionalidade do Não eu ainda vou elaborar"; (2) "pode começar a parte 6,
  sobre as disciplinas pode decidir você mesmo por enquanto".

## O que foi feito
- **Morte:** tela "Você morreu!" / "Deseja continuar?" com Sim e Não (`DeathScreen`).
  Sim = volta no último **ponto de descanso** com vida e mana cheias, mantendo itens,
  equipamento e experiência; inimigos vivos voltam à origem com vida cheia; derrotados e
  baús abertos continuam como estavam. Não = só mostra "ainda será definida" (provisório).
- **Ponto de descanso** (`Checkpoint`, "[E] Descansar"): marca onde voltar e restaura
  vida e mana. Dois na área (sala inicial e salão).
- **`GameArea`**: base comum das áreas (HUD, inventário, morte, diálogo, Disciplina,
  itens descartados). Arena e área de protótipo herdam dela.
- **Mana** (`ManaComponent`): 30 base, recupera 3/s; barra azul no HUD.
- **Disciplinas provisórias** (Vanguarda, Guardião, Arcanista) com tela de escolha ao
  começar; estrutura `DisciplineData`.
- **Magias:** Dardo arcano (projétil, 8 de mana), Cura (20 de mana, +30 de vida, nível 2).
- **NPC + diálogo + missão:** `DialogueBox` (E avança), `QuestData`, `QuestLog` no
  jogador, marcador "!"/"?" no NPC, rastreador no HUD. Missão "Ameaça no salão"
  (derrotar 3 → 40 exp. + 2 ervas). Missões de coleta também suportadas.

## Problemas encontrados

### Projétil atravessava paredes e portas (bug real)
- **Sintoma:** Dardo arcano passava por paredes de tiles e pela porta (x 416 → 384 sem colisão).
- **Causa raiz:** na física da Godot, uma `Area2D` com `monitorable = false` não é
  comparada com corpos estáticos. O `Hitbox` desliga `monitorable` (correto para a
  espada) e o projétil herdou isso.
- **Como cheguei nela:** consulta direta ao espaço físico via `intersect_point` encontrou
  a parede; sonda mínima com `Area2D` simples: `monitorable=true → body_entered=[Wall]`,
  `monitorable=FALSE → []`.
- **Solução:** `Projectile._ready` religa `monitorable`. Regra registrada em CONVENCOES.
- **Prevenção:** testes "projétil some ao bater na parede" e sonda contra a porta
  (liberado no quadro 8) e parede (quadro 4).

### Missão de coleta nunca concluía (bug real)
- **Causa raiz:** `turn_in_quest` tirava os itens da bolsa ANTES de `complete()`, que
  confere o objetivo contando a bolsa → já não havia itens → não concluía e os itens sumiam.
- **Solução:** concluir primeiro, retirar depois. **Prevenção:** teste "entregar tira 3 (sobra 1)".

### Diálogo: proteção contra "pular a 1ª fala" contava quadros (bug frágil)
- **Sintoma:** E real não avançava o diálogo no teste.
- **Causa raiz:** a caixa ignorava teclas "até 1 quadro depois de abrir"; a contagem de
  quadros varia (a Godot roda vários quadros de física seguidos depois de uma carga lenta).
- **Solução:** olhar a tecla: se o E ainda está segurado ao abrir, espera ser solto.
- **Prevenção:** teste "E segurado ao abrir não pula a 1ª fala".

### Testes, não jogo
- Marcador "!" lido antes do 1º quadro de desenho (física em sequência após carregar);
  conta de mana da Cura sem a recuperação de 0,5 s; testes antigos de "reinicia tudo"
  reescritos para "continuar".

## Testes feitos
| Suíte | Resultado |
|---|---|
| `test_disciplines.gd` (escolha, bônus, mana, Dardo, parede, sem mana, Cura, descanso, Vanguarda, Guardião 85°/desgaste) | ✅ 24/24 |
| `test_quests.gd` (NPC, diálogo com E real, aceitar, progresso, HUD, marcador, entregar, recompensas, coleta) | ✅ 25/25 |
| `test_area.gd` (agora com morrer/continuar e ponto de descanso) | ✅ 32/32 |
| `test_combat.gd` (bloco 5: morte → tela → continuar) | ✅ 48/48 |
| Demais: movimento, combate 2 (41), aviso/interação (39), inventário (35), itens/combate (35), itens no mundo (17), tela de inventário (26), habilidades (17) | ✅ todas |

```
12 suítes, 264 verificações, 0 SCRIPT ERROR, 0 WARNING
```

**Não coberto:** mouse real nos botões Sim/Não e nos cartões de Disciplina (testados
pelas mesmas funções que os botões chamam); sensação da magia.

## Pendências
- [ ] Teste manual do proprietário
- [ ] Substituir as Disciplinas provisórias pelo sistema de 6 classes × 3 disciplinas
- [ ] Definir o botão "Não" da tela de morte (proprietário)
