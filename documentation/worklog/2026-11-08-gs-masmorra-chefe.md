# Gear Score (D), masmorra + Dungeon Sync (E/F) e Khar'Vesh (I)

- **Data:** 2026-11-08
- **Status:** concluído (números provisórios ⚑)
- **Arquivos novos:** `game/dungeons/{dungeon_data,dungeon_map,dungeon_entrance}.gd`, `game/dungeons/data/forgotten_ruins.tres`,
  `game/actors/bosses/{khar_vesh,boss_part}.gd`, `game/items/data/{veteran_*,*_oil,crimson_sap,living_branch,ancestral_bark,altar_thorn,sprouted_heart}.tres`
- **Arquivos alterados:** `player.gd`, `character_stats.gd`, `weapon_data.gd`, `shield_data.gd`, `consumable_data.gd`, `hitbox.gd`,
  `basic_enemy.gd`, `game_area.gd`, `hud.gd`, `test_menu.gd`, `admin_console.gd`, `prototype_area.tscn` (gerada)

## Etapa D — Gear Score
- `gear_score` em armas e escudos (iniciais 100, malho/escudo sentinela 120, veterano 320).
- GS do personagem = média dos espaços da classe (Guardião: arma + escudo; Devoto: arma). Vazio = 0.
- Dano da arma x(1 + (GS − 100) / 1000). **Desvio do design** (1 + GS/1000): mantém o dano atual dos itens iniciais.
- Óleos de fogo/gelo/raio: elemento nos golpes da arma por 60 s (`Hitbox.element` → `DamageInfo.element`).
- HUD: "Nv N · GS N", "(sinc.: …)" na masmorra e "[Fogo]" com óleo.

## Etapa E/F — Ruínas Esquecidas + Dungeon Sync
- Portal na sala inicial ([F] Entrar): exige nível 20 e GS 300 (real) e diz o que falta.
- **Decisão:** a masmorra é montada na mesma cena, longe da área (DUNGEON_ORIGIN), em vez de trocar
  de cena. O jogador, inventário, missões e equipamento continuam os mesmos sem precisar de um perfil
  salvo entre mapas (fica para o salvamento/co-op).
- Sync: `effective_level()` (teto 24) e `effective_gs_of()` (teto 300) em vida, mana, dano e habilidades.
  O personagem nunca é alterado; sair = tirar o teto.
- Mapa provisório: entrada → corredor → salão (4 monstros vida 160 / dano 30) → corredor → arena com 4 poças.
- Morrer lá dentro: continua no início da masmorra, ainda sincronizado. Saída pelo portal: volta ao ponto de entrada.

## Etapa I — Khar'Vesh, a Mãe-Raiz
- Corpo provisório por código. Partes (`BossPart`): casca 900, cerne (x1,5, só sem casca), boca 250,
  chicotes 250, bulbos 150 x3. Um golpe que encosta em várias partes tira da vida total uma vez só.
- Resistências do design; Molhada (perto de poça, fase 2+): Fogo neutro, Raio vulnerável por 10 s; sem casca: Terra neutra.
- Fases 70% / 35% com rugido de 1,5 s invulnerável; Fúria 70/50/20% (x1,15/1,25/1,40 em velocidade e dano, aviso ≥ 0,35 s, aura).
- Ataques com aviso no chão: chicotada, varredura, lança (3 seguidas na fase 3 + 3 s ofegante), esporos (lento + veneno),
  Sugar seiva (interrompida com 60 de dano nos bulbos ou atordoamento), brotos.
- Materiais garantidos por parte + Coração Germinado (25%); 3000 de experiência.
- Aparece ao passar pela entrada da arena da masmorra, ou com `/boss`.

## Problemas encontrados

### DungeonData não compilava no gerador
- **Sintoma:** `Compile Error: Identifier not found: Hitstop` ao gerar `forgotten_ruins.tres`.
- **Causa raiz:** `entry_refusal(player: Player)` fazia o recurso depender do Player (que depende do autoload).
- **Solução:** `entry_refusal(level, gear_score)` — os dados não conhecem quem os usa.

### Texto do nível no HUD tinha dois donos
- **Sintoma:** HUD mostrava só "Nv 60" logo após ganhar experiência.
- **Causa raiz:** `_on_xp_changed` escrevia "Nv N" e o `_process` escrevia o texto completo.
- **Solução:** `_on_xp_changed` chama `_update_level_label()` (um só lugar escreve).

### Chefe não sumia depois de morrer
- **Sintoma:** corpo ficava parado depois do golpe final.
- **Causa raiz:** o golpe final na casca quebrava a casca → "entrar na fase 3" → estado ROAR por cima de DEAD;
  o aviso de vida também chega antes de "morto" ser marcado.
- **Solução:** sem vida, `_enter_phase` e `_on_health_changed` não fazem nada; ao morrer o chefe sai do grupo "bosses".

### Erros dos testes (não do jogo)
- Lambda tipada recebendo monstros já liberados; posição de volta comparada com regra errada; vida do chefe
  alterada sem passar pelo dano (disparava fase na primeira cura); processamento do chefe desligado durante a morte;
  verificações antigas de texto ("Nv 2", "/boss ainda sem chefe").

## Testes feitos
| Suíte | O que cobre | Resultado |
|---|---|---|
| `test3d_gs.gd` | GS, escala de dano, tetos, óleos, menu | ✅ 18 |
| `test3d_dungeon.gd` | portal e recusas, sync, monstros, morrer/continuar, sair, entrar de novo | ✅ 18 |
| `test3d_boss.gd` | /boss, resistências, golpe em várias partes, cada parte, fases, Fúria, ataques, cura, Provocar, morte, arena | ✅ 44 |
| Todas (18 suítes) | | ✅ 424, 0 falhas |

Capturas (só a janela do jogo): portal na sala inicial, corredor da masmorra com HUD sincronizado, chefe com barra e aura.

## Pendências
- [ ] Arte de verdade do chefe e da masmorra (tudo provisório).
- [ ] Janela de 2 s dos bulbos expostos após a varredura (hoje os bulbos podem ser atingidos sempre).
- [ ] Recompensa de entrada diária / drops pelo GS da masmorra.
- [ ] Usar os materiais (criação de itens).
