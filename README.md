# ALYSPERIN

RPG de ação em 3D, terceira pessoa, com fantasia sombria e horror de sobrevivência, em visual de anime
(cel shading) com mundo levemente pixelado. Feito em **Godot 4.7.2** (GDScript), para PC.
Meta futura: co-op de até 4 jogadores. Inspirações: Kingdom Hearts, Resident Evil, Tera (mira e barra de
habilidades), Monster Hunter (chefes). Nada é copiado desses jogos.

> **Estado:** projeto pausado em 2026-11-08. Tudo que existe está neste repositório (código, cenas,
> modelos, testes, geradores e documentação). Para retomar, siga "Como voltar a trabalhar" abaixo.

---

## Como voltar a trabalhar

1. Instale o **Godot 4.7.2** (versão padrão, não a .NET). No Windows: `winget install GodotEngine.GodotEngine`
   ou baixe em https://godotengine.org/download.
2. Clone o repositório: `git clone https://github.com/crisz-source/ALYSPERIN.git`
3. Abra a pasta no Godot (Importar → `project.godot`). Na primeira abertura ele importa os modelos (leva um tempo).
4. **F5** roda o jogo (cena principal: a área inicial).
   - Problema conhecido: com o jogo "embutido" no editor, o teclado pode não funcionar. Desligue em
     Editor → Configurações do editor → Run → "Embed Game" (ou rode pelo executável).
5. Para conferir que nada quebrou, rode os testes (seção "Testes").

### Para continuar com o Claude Code
Peça para ler este README, `documentation/DEVLOG.md`, `documentation/CONVENCOES.md` e os registros em
`documentation/worklog/` (um por etapa, com problemas, causa raiz e testes).

---

## Controles

| Tecla | Ação |
|---|---|
| WASD | andar |
| Mouse | câmera (roda = zoom); a mira fica no centro |
| Clique esquerdo | atacar (combo de 3 golpes) |
| Clique direito | defender (Guardião) / Oração de cura (Devoto) |
| Espaço | esquivar (esquiva perfeita no tempo certo) / confirmar cura em grupo |
| 1–9, F1–F12 | habilidades e itens da barra |
| F | interagir (portas, baús, NPCs, portais) |
| I | inventário (arraste consumíveis para a barra) |
| Esc | solta o mouse |
| **P** | **menu de testes** (trocar classe, aliados, nível 20, equipamento GS 320 + óleos, encher vida) |
| **Enter** | **console de admin**: `/add players N`, `/add mob N`, `/boss`, `/efeito NOME [eu]`, `/help` |

---

## O que já existe

- **Classes:** Guardião (tanque: arma + escudo, cavaleiro animado) e Devoto (cura: cajado, mago animado).
  Habilidades nos níveis 1, 1, 10, 20, 35, 50; passivos Muralha e Graça; nível máximo 60; mana não regenera.
- **Combate:** combo, defesa, esquiva perfeita, golpe pelas costas (x1,5), números de dano, hitstop,
  aviso no chão antes dos ataques inimigos, mira sem trava.
- **Cura em grupo:** passar a mira nos aliados seleciona; Espaço cura todos (15 de mana por uso).
- **Efeitos de status:** lento, congelar, queimar, veneno, atordoar, medo, provocar, + Postura, Protegido, Inabalável.
- **Itens:** inventário de 8 espaços, durabilidade, consumíveis na barra, armas/escudos com modelo 3D na mão,
  **Gear Score** (dano escala com o GS), **óleos de arma** (fogo, gelo, raio).
- **Missões** com marcadores (! nova, ? etapa concluída, * pronta para entregar).
- **Masmorra Ruínas Esquecidas** (portal laranja; exige nível 20 e GS 300) com **Dungeon Sync** (nível 24, GS 300).
- **Chefe Khar'Vesh, a Mãe-Raiz:** partes destrutíveis (bulbos, chicotes, casca, boca, cerne), fases 70/35%,
  Fúria 70/50/20%, fraquezas elementais descobertas em combate, estado Molhada, materiais.
- **Vila de Brisaclara** (portal verde): refúgio de dia, colorido, com aldeões e diálogo.
- **Visual:** cel shading com contorno (autoload `ToonStyle`), mundo 3D a 1/3 da resolução (pixelado),
  textos nítidos (autoload `WorldText`), animações reais dos personagens KayKit.
- **Morte:** "Você morreu!" → continuar (mantém o progresso).

## O que falta (próximos passos)

1. **Co-op online (até 4 jogadores)** — maior etapa pendente; o código já separa entrada/regras pensando nisso
   (`PlayerInput`, `DamageInfo`, `HealthComponent` como único lugar que aplica dano).
2. **Botão "Não" da tela de morte** — comportamento a definir pelo proprietário.
3. **Loja** (a mercadora da vila ainda não vende) e **criação de itens** com os materiais do chefe.
4. **Arte:** modelo do Khar'Vesh (hoje formas simples); paredes/chão com peças KayKit (grade de 4 m vs. 1 m do mapa);
   ícones de itens e efeitos.
5. **Outros chefes aprovados:** Velkhor e Nhalgrim (`documentation/design/chefes-iniciais.md`) e as masmorras 2–6.
6. **Mais classes** (o design tem 6; hoje existem 2 por decisão do proprietário).
7. **Salvamento** (perfil persistente entre sessões).
8. Região que escurece aos poucos; janela de bulbos expostos do chefe; recompensas diárias.

---

## Estrutura

```
game/
  actors/      jogador (player.gd, player_animator.gd), inimigos, chefes (khar_vesh.gd), aliados de teste, NPC
  abilities/   dados das habilidades (.tres) e tipos (projétil, cura, suporte...)
  classes/     ClassData + guardian.tres / devotee.tres
  combat/      DamageInfo, projétil
  components/  vida, mana, hitbox/hurtbox, efeitos de status, interação
  dungeons/    DungeonData, mapa e portal da masmorra
  items/       armas, escudos, consumíveis, materiais (.tres)
  quests/      missões
  systems/     autoloads: Hitstop, WorldText (texto nítido), ToonStyle (anime)
  ui/          HUD, inventário, telas, menu de testes (P), console de admin (Enter)
  world/       áreas, arena de teste, vila, decoração, portais
assets/        modelos 3D (cada pasta com LICENSE.txt)
documentation/ DEVLOG, convenções, design (classes, chefes), worklog por etapa
tools/
  tests/       suítes de teste automáticas (21 arquivos, 467 verificações)
  generators/  scripts que geram as cenas e os dados (player, inimigos, áreas, classes, itens, masmorra)
  dequantize_glb.py   converte .glb com KHR_mesh_quantization (Godot não lê)
```

## Testes

Todas as suítes (headless), no Git Bash, na pasta do projeto:

```sh
GODOT="/caminho/para/Godot_v4.7.2-stable_win64_console.exe" sh tools/run_all_tests.sh
```

Uma suíte só:

```sh
"$GODOT" --headless --path . --script tools/tests/run_test.gd -- res://tools/tests/test3d_boss.gd
```

Último resultado (2026-11-08): **467 verificações, 0 falhas**.

## Geradores de cena

Várias cenas (`player.tscn`, inimigo, áreas, arena) e dados (`classes`, itens, masmorra) são **gerados por script**.
Mudou um gerador? Rode-o e depois os testes:

```sh
"$GODOT" --headless --path . --import          # depois de criar uma class_name nova
"$GODOT" --headless --path . --script res://tools/generators/build_3d_core.gd
"$GODOT" --headless --path . --script res://tools/generators/build_classes.gd
"$GODOT" --headless --path . --script res://tools/generators/build_dungeons.gd
"$GODOT" --headless --path . --script res://tools/generators/build_3d_world.gd   # por último (usa os anteriores)
```

## Créditos e licenças de arte

- **KayKit** (Kay Lousberg, kaylousberg.com) — Adventurers, Skeletons, Dungeon Remastered, Halloween Bits,
  Medieval Hexagon. **CC0**. https://github.com/KayKit-Game-Assets
- **Moonsteel Convergence** (3dassets.dev) — Malho de brasa, Escudo sentinela, Cajado crescente. **CC0**.
- Licença de cada pacote no `LICENSE.txt` da pasta em `assets/`.
