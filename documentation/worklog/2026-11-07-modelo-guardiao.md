# Primeiro modelo de arte: Guardião

- **Data:** 2026-11-07
- **Status:** substituído — modelo removido a pedido do proprietário no mesmo dia (ver `2026-11-07-armas-3d.md`)
- **Arquivos tocados:** `assets/characters/guardian/` (guardian.glb, source/model.glb, source/.gdignore),
  `tools/dequantize_glb.py`, `game/classes/class_data.gd`, `game/classes/data/guardian.tres`,
  `game/actors/player/player.gd`, `game/actors/player/player.tscn` e cenas de área (regeneradas)

## Objetivo
O proprietário gerou um modelo de tanque (`model.glb`) e pediu para usar no jogo no lugar
da cápsula azul.

## Plano executado
1. Importar e inspecionar o arquivo (falhou: ver problema abaixo).
2. Converter o arquivo, medir altura/orientação/animações.
3. `ClassData.model_scene` + troca de corpo em `Player.apply_class`.
4. Efeitos de cor (dano, morte, seleção de cura) por `material_overlay`, independente do modelo.
5. Peças provisórias agrupadas em `Model/Placeholder` (gerador `build_3d_core.gd`).
6. Testes, capturas só da janela do jogo, commit.

## Problemas encontrados

### Godot recusa o .glb
- **Sintoma:** `ERROR: glTF: Can't import file 'model', required extension 'KHR_mesh_quantization' is not supported.`
- **Causa raiz:** o exportador do site (gerador `3dassets.dev ingest`) grava posições/normais
  como inteiros de 16 bits normalizados (extensão obrigatória `KHR_mesh_quantization`);
  o importador do Godot 4.7.2 não implementa essa extensão.
- **Como cheguei nela:** leitura do cabeçalho JSON do glb: `extensionsRequired =
  ['EXT_texture_webp', 'KHR_mesh_quantization']`, accessors com `componentType 5122, normalized`.
- **Solução:** `tools/dequantize_glb.py` (só biblioteca padrão do Python) converte cada
  accessor de malha para float32 e remove a extensão. A escala de cada peça já está no nó
  (padrão da extensão), então só a divisão pelo máximo do inteiro é necessária. O
  `gltf-transform dequantize` (npm) foi bloqueado pela permissão do ambiente.
- **Prevenção:** o original fica em `source/` (com `.gdignore`, para o Godot não tentar
  importá-lo e acusar erro a cada abertura). Uso: `python tools/dequantize_glb.py source/model.glb guardian.glb`.

### Teste de orientação falhou (erro do teste)
- **Sintoma:** espada medida em +Z no espaço do jogador.
- **Causa raiz:** o teste media no espaço do jogador, que estava virado para +Z
  (`facing=(0,0,1)`, `Model.rotation.y = -π`); a frente fixa é a do nó `Model`.
- **Solução:** medir no espaço do `Model`: espada em (0,31; 1,07; -0,90) = à frente e à direita.

### Tinta de cura do Player era sobrescrita a cada frame (achado de passagem)
- `set_heal_selected` mudava a cor do corpo, mas `_update_visuals` a repunha no frame seguinte.
  Agora é um estado (`_heal_selected`) lido em `_update_visuals`. Só afetaria o co-op.

## Testes feitos
| # | O que testa | Resultado |
|---|---|---|
| 1 | 11 suítes (combate, sistemas, mundo, UI, criação, cura, admin, inventário x2, rodada 7, arrastar) | ✅ 269 verificações, 0 falhas |
| 2 | Novas: modelo carregado e boneco escondido; frente certa; idle em loop; camada de cor nas 23 peças; verde ao selecionar e volta; Devoto volta ao boneco | ✅ |
| 3 | Capturas (só a janela do jogo): costas, frente, lado | ✅ modelo no tamanho certo, espada à direita, escudo à esquerda |

## Abordagens consideradas
| Abordagem | Decisão | Motivo |
|---|---|---|
| Conversor próprio em Python | ✅ | sem dependência externa; reaproveitável para próximos modelos |
| `npx @gltf-transform/cli dequantize` | ❌ | bloqueado pela permissão do ambiente |
| Pedir para baixar sem compressão | ❌ (por ora) | o site pode não oferecer a opção; conversor resolve |
| Mudar cor dos materiais do modelo para piscar | ❌ | modelo tem 7 materiais compartilhados; a camada por cima não toca neles |
| Mesmo modelo para o Devoto | ❌ | modelo tem espada e escudo; Devoto usa cajado — fica no boneco até ter arte |

## Estado final
Escolher Guardião mostra o gladiador com espada e escudo; o Devoto continua com a cápsula.
Colisão, golpes, câmera e mira não mudaram.

## Pendências
- [ ] Origem/licença do modelo (site 3dassets.dev) — confirmar com o proprietário.
- [ ] Animações de andar, atacar, defender, esquivar (o modelo só tem bow/idle/wave).
- [ ] Modelo do Devoto.
