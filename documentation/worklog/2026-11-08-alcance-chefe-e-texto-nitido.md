# Partes do chefe fora do alcance e texto embaçado

- **Data:** 2026-11-08
- **Status:** concluído
- **Arquivos tocados:** `game/actors/bosses/khar_vesh.gd`, `game/systems/world_text.gd` (novo), `project.godot`,
  `documentation/CONVENCOES.md`

## Problema 1 — não dava para quebrar nada do Khar'Vesh
- **Sintoma (relato do proprietário):** "os bulbos estão muito em cima… o tanque não alcança nada".
- **Causa raiz:** as partes foram posicionadas pela aparência (bulbos a 3,0–4,3 m, boca 3,6 m, chicotes 2,5 m,
  cerne 3,0 m), mas a área de golpe da espada vai de 0,2 a 1,6 m (centro 0,9, meia altura 0,7).
- **Por que os testes não pegaram:** chamavam `apply_part_hit` direto, sem um golpe de verdade.
- **Solução:** todas as partes quebráveis dentro da faixa (constantes `MELEE_BAND_LOW/HIGH`).
- **Prevenção:** teste de geometria (toda parte dentro da faixa) + golpe real de espada pelas costas
  (acerta bulbos) e pela frente (acerta boca/chicote).

## Problema 2 — letras embaçadas
- **Sintoma:** textos borrados em tela cheia.
- **Causa raiz:** `stretch/mode = viewport` desenhava tudo (inclusive texto) em 640x360 e ampliava 3x.
- **Solução:** `canvas_items` (interface na resolução da tela) + 3D a 1/3 com `nearest` (mantém o visual
  pixelado escolhido) + autoload `WorldText` para os textos do mundo 3D (Label3D), que continuariam no 3D de baixa resolução.
- **Problemas no caminho:**
  - Esconder o Label3D com `transparency = 1` ainda desenhava o contorno → trocado por camada de desenho que a câmera não vê.
  - Cópia um quadro atrasada (o autoload atualizava antes da câmera e dos textos) → `process_priority = 1000`.
    Hipóteses descartadas antes: tamanho do Label atrasado; tamanho mínimo do Label (medições iguais nas duas).
  - Expectativa errada no teste (supunha câmera de 75°; a do jogo é 65°).

## Testes
| Suíte | Resultado |
|---|---|
| `test3d_boss.gd` (+3 de alcance) | ✅ 47 |
| `test3d_text.gd` (nova) | ✅ 10 |
| Todas (19 suítes) | ✅ 437, 0 falhas |
Capturas em 1920x1080: HUD, mensagens, barra de habilidades, nome do portal e número de dano nítidos; mundo pixelado.
