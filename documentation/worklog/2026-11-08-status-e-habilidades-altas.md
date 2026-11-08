# Efeitos de status (Etapa B) e habilidades de nível alto (Etapa G/H)

- **Data:** 2026-11-08
- **Status:** concluído
- **Arquivos tocados:** `game/components/status_effects.gd` (novo), `game/abilities/support_spell_data.gd` (novo),
  `game/abilities/effects/support_zone.gd` (novo), `game/components/health_component.gd`, `game/combat/damage_info.gd`,
  `game/combat/projectile.gd`, `game/actors/player/player.gd`, `game/actors/player/player_animator.gd`,
  `game/actors/enemies/basic_enemy/basic_enemy.gd`, `game/actors/allies/ally_dummy.gd`,
  `game/ui/admin_console/admin_console.gd`, `game/abilities/data/*.tres`, `game/classes/data/*.tres`

## Objetivo
Pedido do proprietário: "implemente todo o restante". Escopo combinado: B (status), G/H (habilidades
altas), D (Gear Score/elementos), E/F (masmorra + sync), I (chefe). Fora: co-op online, botão "Não",
novas classes. Esta entrada cobre B e G/H.

## Etapa B — efeitos de status
- `StatusEffects`: componente comum (jogador, inimigo, aliado de teste), criado por `attach()`.
  Guarda id → tempo/força/fonte; aplica dano contínuo a cada 0,5 s; texto acima da cabeça; tinta.
- Efeitos: lento, congelar, queimar, veneno, atordoar, medo, provocar; positivos: Postura,
  Protegido, Inabalável.
- `DamageInfo.over_time`: dano contínuo não é bloqueado, ignora invulnerabilidade, não empurra
  e não interrompe. `DamageInfo.element` preparado para os chefes.
- Jogador: congelado/atordoado não age; medo foge da fonte; lentidão em `_apply_movement`.
- Inimigo: congelar = atordoamento azul; medo foge e não ataca; lentidão na perseguição e investida.
- Console: `/efeito NOME [eu]`.

## Etapa G/H — 8 habilidades (SupportSpellData, uma mecânica por habilidade)
Guardião: Postura inabalável (10), Muralha compartilhada (20), Bastião eterno (35), Fortaleza viva (50).
Devoto: Bênção de proteção (10), Círculo de cura (20), Ressurreição (35, + revive solo 1x), Milagre (50).

## Problemas encontrados

### Força de um efeito "grudava" na duração de outro (bug do jogo)
- **Sintoma:** aliado continuava Protegido depois de sair da cúpula (teste "fora da cúpula: proteção acaba").
- **Causa raiz:** a renovação fazia `tempo = max(tempos)` e `força = max(forças)` separadamente;
  cúpula (50%, pulsos de 0,6 s) + Muralha (30%, 6 s) = 50% por 6 s.
- **Como cheguei nela:** instrumentação: `protect restante=3.27 força=0.5` 3 s após a Muralha.
- **Solução:** mais forte substitui (força + duração dele), igual estende, mais fraco é ignorado.
- **Prevenção:** 3 verificações novas em `test3d_status.gd`.

### Erros dos testes (não do jogo)
- Suíte de sistemas esperava a Postura "em desenvolvimento" — atualizada para o comportamento novo.
- Comando de edição falhou no terminal por aspas no texto — edições passaram a ir por arquivo .py.

## Testes feitos
| # | Suíte | Resultado |
|---|---|---|
| 1 | `test3d_status.gd` (nova): cada efeito no inimigo e no jogador, renovação, morte limpa, /efeito | ✅ 24 |
| 2 | `test3d_support.gd` (nova): as 8 habilidades, revive solo e recarga | ✅ 21 |
| 3 | Todas as 14 suítes | ✅ 344, 0 falhas |

## Abordagens consideradas
| Abordagem | Decisão | Motivo |
|---|---|---|
| Um componente de status lido pelo dono | ✅ | regras de corpo ficam no dono; o componente só guarda e conta tempo |
| Um tipo de dado por habilidade de suporte | ❌ | 8 arquivos quase iguais; um enum de mecânica basta |
| Várias instâncias do mesmo efeito em paralelo | ❌ (por ora) | mais complexo; a regra "mais forte vence" cobre os casos atuais |

## Pendências
- [ ] Ícones dos efeitos (hoje texto).
- [ ] Projéteis inimigos ainda não existem (a cúpula já os apaga quando existirem).
