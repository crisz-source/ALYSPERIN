# Etapa A (reduzida): Guardião (tanque) e Devoto (cura)

- **Data:** 2026-11-07
- **Status:** concluído nos testes automáticos; teste manual pendente
- **Pedido:** "não faça ainda as 6 classes de uma vez, faça apenas duas, tank e healer".
  Interpretação (seguindo o design aprovado): **Guardião** com a disciplina **Bastião**
  (proteção) e **Devoto** com a disciplina **Sacerdote** (cura). As outras disciplinas
  dessas classes aparecem como "Em breve"; as outras 4 classes ficam para depois.

## O que foi feito
- **Dados:** `ClassData` (nova: função, armas permitidas, usa escudo, equipamento inicial,
  disciplinas) e `DisciplineData` reescrita **sem bônus de atributo** (regra: base igual),
  com passivo e `available` ("Em breve").
- **Classes** (`game/disciplines/classes/`): Guardião (espada/maça/machado + escudo; começa
  com espada curta e escudo de madeira) e Devoto (maça/cetro, sem escudo; começa com a nova
  **Maça de peregrino**).
- **Disciplinas** (`game/disciplines/data/`): Bastião e Sacerdote jogáveis; Carrasco,
  Vanguarda, Inquisidor, Oráculo "Em breve". As provisórias antigas (Guardião-disciplina e
  Arcanista) foram removidas; `vanguard.tres` foi reaproveitado para a Vanguarda real.
- **Habilidades (nomes do design aprovado):**
  - Bastião: **Golpe de escudo** (atordoa 1,5 s, precisa de escudo), **Provocar** (inimigos
    em 8 m seguem você por 4 s). Passivo **Muralha**: bloquear dá **Firmeza** (−30% de dano por 3 s).
  - Sacerdote: **Luz curativa** (+25), **Raio sagrado** (projétil, 8). Passivo **Graça**:
    curar com a vida cheia vira **escudo de vida**.
  - Níveis 10/20/35/50 das duas disciplinas: na barra com cadeado; ao liberar, a tecla avisa
    "ainda em desenvolvimento" sem gastar mana/recarga (`AbilityData.is_implemented()`).
- **Regras novas:** cada classe equipa só as suas armas ("Sua classe não usa …"); Devoto não
  usa escudo; base de vida/mana/dano igual para todos.
- **Base para a Etapa B:** inimigo ganhou `apply_stun()` e `apply_taunt()`; vida ganhou
  escudo de vida (`shield_points`).
- **Tela de criação** em 2 etapas (classe → disciplina), "Em breve" desativado, botão Voltar.
- **Co-op (anotado):** Luz curativa curará o aliado na mira e o Raio sagrado curará aliados
  que atravessar quando houver aliados (Fase 7). Hoje a Luz cura a si mesmo.

## Problemas encontrados

### Texto do cartão invadia o cartão vizinho (bug real)
- **Sintoma:** descrição do Bastião passava por cima do cartão do Carrasco.
- **Hipóteses descartadas (com medida):** (1) falta de largura mínima → continuou 491 px;
  (2) tamanho definido antes da quebra de linha → continuou 491 px. Sonda isolada mostrou que
  um Label igual NÃO crescia; a medição do cartão real mostrou 491 px **já ao criar**.
- **Causa raiz:** o texto era atribuído antes de ligar a quebra de linha e a fonte menor; o
  Label fixava a largura de uma linha só na fonte padrão (491 px) e o tamanho definido depois
  não reduzia.
- **Solução:** configurar quebra, fonte e tamanho antes de atribuir o texto. Medido depois:
  164 px de largura, 5 linhas. Captura conferida.

### Testes (não jogo)
- Atordoamento medido com o inimigo congelado (o relógio do atordoamento roda na física dele).
- 200 de exp. não chegava ao nível 10 (são 1350 no total).
- Suítes antigas usavam `choose()` e as disciplinas provisórias; a barra agora tem as teclas
  3–6 ocupadas pelas habilidades de nível alto → arrastes de teste usam a tecla 7.
- Um processo de teste ficou travado esperando a tela antiga: encerrado (era um teste meu).

## Testes feitos
| Suíte | Resultado |
|---|---|
| `test3d_creation.gd` (2 classes, 3 disciplinas, "Em breve" bloqueado, Voltar, aplicação, barra com cadeados) | ✅ 9/9 |
| `test3d_systems.gd` (agora com: base igual 108, loadout do Guardião, 6 habilidades, Golpe de escudo atordoa 1,5 s, Provocar, Firmeza −30%, nível alto avisa sem gastar, Devoto maça/sem escudo, recusa espada e escudo, Luz +25/−15, Graça escudo 12 absorve, Raio 8/−6) | ✅ 38/38 |
| `test3d_combat` (31), `test3d_world` (29), `test3d_ui` (18), `test_inventory` (37), `test_inventory_ui` (24), `test_round7` (21), `test_drag_real` (2) | ✅ todas |

```
9 suítes, 209 verificações, 0 SCRIPT ERROR, 0 WARNING
```

**Não coberto:** sensação/equilíbrio das habilidades; visual do atordoamento e da
provocação (só cor do inimigo e texto flutuante, sem efeitos próprios).

## Pendências
- [ ] Teste manual do proprietário
- [ ] Etapa B: efeitos de status completos (lentidão, congelar, queimar, veneno, medo, escudo em aliados)
- [ ] Habilidades de nível 10+ do Bastião e do Sacerdote; disciplinas "Em breve"; outras 4 classes

## Ajustes pedidos depois (mira, defesa, nível)
- **Mira parecia estar na ponta da arma.** Medido: a ponta da espada aparecia a 14 px do
  centro da tela e a cabeça a 26 px (a câmera por cima do ombro colocava o personagem no
  centro). Causa: posição do pivô da câmera. Correção: pivô mais alto e mais ao lado
  (`Pitch` em (1,0; 0,9; 0)). Depois: espada a 40 px, cabeça a 49 px; personagem embaixo à
  esquerda, mira livre. Teste novo garante distância mínima.
- **"Defesa bem-sucedida!"** a cada bloqueio (texto flutuante azul-claro); "Firmeza" do
  Bastião sobe um pouco para não sobrepor.
- **Animação de nível ~5 s**: asas e coroa ficam ~3,8 s e somem em 1,2 s (subindo).
- Testes: `test3d_ui.gd` 22/22 (+4: efeito visível aos 3,5 s, some até ~5,5 s, espada e
  cabeça longe do centro, mensagem de defesa); demais 8 suítes passando.
