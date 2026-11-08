# Arte CC0 (KayKit): personagens animados, esqueletos, cenário e clima

- **Data:** 2026-11-08
- **Status:** concluído (primeira passada de arte)
- **Arquivos novos:** `assets/characters/kaykit/` (Knight, Mage, Skeleton_Warrior, Skeleton_Minion + licenças),
  `assets/environment/kaykit_dungeon/`, `assets/environment/kaykit_halloween/` (+ LICENSE.txt), `game/world/decor/decor.gd`
- **Alterados:** `player.gd`, `player_animator.gd`, `class_data.gd`, `basic_enemy.gd`, `dungeon_map.gd`, cenas geradas

## Objetivo
Proprietário: "faça o que você recomenda" — pacotes CC0 com personagens animados, mais clima e cenário.

## Origem e licença
Kay Lousberg (kaylousberg.com), repositórios github.com/KayKit-Game-Assets: Character Pack Adventurers 1.0,
Character Pack Skeletons 1.0, Dungeon Remastered 1.0, Halloween Bits 1.0. Todos **CC0** (LICENSE.txt lido
antes de usar; copiado junto dos arquivos). Baixados com `git clone --depth 1` numa pasta separada, só como dados.

## O que mudou
- **Guardião = cavaleiro, Devoto = mago** (escala 0,7 ≈ 1,7 m). Armas próprias dos modelos escondidas; o item
  equipado vai preso ao osso da mão (`handslot_r/l`), desfazendo a escala do modelo.
- **Animações reais por estado** (PlayerAnimator): Idle/Running, combo 1H (escudo) ou 2H (cajado) com 3 golpes
  encaixados no tempo real do golpe, Blocking, Dodge_Forward, Hit_A, Death_A, giro, golpe de escudo, Cheer
  (Provocar), Spellcast_Shoot/Raise. Sem modelo de classe, segue a animação por código.
- **Monstros = esqueleto lacaio** animado (corrida, estocada ajustada ao aviso, dano, atordoado, morte que desmonta
  o esqueleto). Avisos de cor (piscar, preparação, congelado, efeitos) por camada sobre o modelo.
- **Cenário:** pedra com textura de ruído (triplanar) nos blocos; 26 peças KayKit encostadas nas paredes da área
  inicial (escolha fixa por tile, longe de portas/NPC/portal/monstros, corredores livres); masmorra com lanternas,
  ossos, escombros, pilares, caixões, lápides, santuário e árvore morta.
- **Clima:** tons de filme, brilho nas chamas, contraste maior, saturação menor; luz geral da masmorra mais baixa.

## Problemas encontrados
- **Cópia dos pacotes falhou:** o pacote de masmorra usa `nome.gltf.glb` (não `.gltf` + `.bin`). Corrigido no copiador.
- **Folha de poses vazia:** o script de captura recortava uma imagem 640x360, mas desde o texto nítido a imagem
  tem 1920x1080 (era do teste, não do jogo).
- **Golpes pareciam "parados" na captura:** hipótese confirmada — a animação (1 s) toca 3x mais rápido para caber
  no golpe (0,3 s); o script avançava além do fim. Com avanço menor aparecem os golpes.
- **Testes antigos** supunham o boneco provisório nas classes (cajado erguido por código, corpo caído, espada de caixa) —
  passaram a conferir a animação que está tocando.

## Testes
| Suíte | Novas verificações |
|---|---|
| `test3d_anim.gd` | mago animado; Spellcast_Raise/Shoot; Death_A; cavaleiro Idle/Running_A; 3 golpes do combo; Blocking; malho no osso da mão |
| `test3d_status.gd` | esqueleto no lugar do cubo; corrida; estocada no aviso; morte desmonta |
| Todas (19) | ✅ 447, 0 falhas |
Capturas: folha de poses (cavaleiro e mago), sala inicial, salão com esqueletos, arena decorada com o chefe.

## Pendências
- [ ] Paredes/chão com as peças KayKit (grade de 4 m vs. grade de 1 m do jogo) — hoje: blocos com pedra texturizada.
- [ ] Modelo de arte do Khar'Vesh (ainda formas simples).
- [ ] Esqueleto guerreiro para inimigos mais fortes (já copiado).
