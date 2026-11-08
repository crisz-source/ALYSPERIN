# ALYSPERIN — Classes, Disciplinas, Progressão, Gear Score e Masmorras

> **Atualização (2026-11-07, decisão do proprietário): o jogo NÃO terá disciplinas.**
> Cada personagem escolhe apenas uma classe. Implementadas até agora: **Guardião** (tanque,
> espada + escudo; habilidades do antigo "Bastião") e **Devoto** (cura, cajado; habilidades do
> antigo "Sacerdote" + Oração de cura no botão direito). As listas por disciplina abaixo ficam
> como **banco de ideias** para as habilidades das classes; GS, masmorras e sincronização seguem valendo.

- **Status:** v2 (2026-11-07) — decisões do proprietário aplicadas (ver §10). Nomes das
  habilidades aprovados ("quero o nome habilidades mesmo").
- **Origem:** especificação do proprietário "Sistema de Classes, Disciplinas, Progressão
  e Masmorras" (6 classes × 3 disciplinas, GS, Dungeon Sync).
- **O que é decisão do proprietário:** classes e disciplinas (definidas por ele), e os
  números de exemplo das masmorras.
- **O que é proposta minha (marcado com ⚑):** curva de níveis, fórmulas, nomes e efeitos
  das habilidades, regras de sincronização em detalhe. Tudo ajustável.

---

## 1. Regras fundamentais

1. Cada personagem escolhe **1 classe e 1 disciplina**, sem misturar. A escolha é feita na
   criação do personagem e é **definitiva** para aquele personagem ⚑ (trocar = outro personagem).
2. **Base igual para todos:** mesmos HP, MP e dano-base por nível. Classe e disciplina
   **não dão bônus de atributo**. As diferenças vêm das **habilidades, mecânicas e funções**.
3. **Duas progressões separadas:**
   - **Nível de Disciplina** (experiência) → libera **habilidades** e aumenta a base de HP/MP/dano.
   - **Gear Score (GS)** (equipamentos) → aumenta a força dos equipamentos e dá acesso a masmorras.
   - GS **nunca** libera habilidades; nível **nunca** substitui equipamento.
4. **Dungeon Sync:** ao entrar numa masmorra mais fraca que o personagem, nível, GS e
   habilidades são limitados ao teto dela; tudo volta ao sair.

## 2. Nível de Disciplina e habilidades ⚑

- Nível máximo: **60** (decisão do proprietário; expansões podem aumentar).
- Experiência para o nível N+1 = 30 × N (curva atual do protótipo; ajustável).
- **6 habilidades por disciplina**, nas teclas 1–6, liberadas por nível:

| Etapa | Nível | Tecla | Papel |
|---|---|---|---|
| Inicial | 1 | 1 | habilidade principal da identidade |
| Inicial | 1 | 2 | segunda ferramenta básica (mobilidade, defesa ou utilidade) |
| Nova | 10 | 3 | amplia o estilo |
| Intermediária | 20 | 4 | abre combinações (sinergia com 1–3) |
| Avançada | 35 | 5 | poder forte, recarga longa |
| Domínio | 50 | 6 | especial: o domínio máximo da disciplina |

*(Na §7 os números entre parênteses seguem a versão anterior — 1, 1, 8, 18, 30, 45 —
e devem ser lidos como 1, 1, 10, 20, 35, 50.)*

- Além das 6 ativas, cada disciplina tem **1 traço passivo** desde o nível 1 que define
  sua mecânica central (ex.: Hemomante paga habilidades com vida).
- **Sem sistema de pontos** (decisão do proprietário): HP/MP/dano crescem
  **automaticamente e igual** por nível. **Já implementado** (commit a331599).
- **Mana não recupera sozinha** (decisão do proprietário): volta com itens de mana.
  **Já implementado.**

### Base por nível (igual para todas as classes) ⚑
| | Nível 1 | Por nível | Nível 60 |
|---|---|---|---|
| HP | 100 | +8 | 572 |
| MP | 30 | +2 | 148 |
| Dano-base | ×1,0 | +10% | ×6,9 |

O dano final de um golpe = dano-base × multiplicador da arma (GS) × multiplicador da habilidade.

## 3. Gear Score (GS) ⚑

- Cada equipamento tem um **GS** (nível do item). Faixa inicial: **100 a 2500**.
- **GS do personagem** = média do GS dos equipamentos nos espaços: arma, mão secundária
  (escudo/foco/aljava), cabeça, peito, pernas, acessório. Espaço vazio conta como 0.
  *(O protótipo tem só arma e escudo; os outros espaços entram numa etapa futura.)*
- O GS escala os **números dos equipamentos**:
  - multiplicador de dano da arma = 1 + GS ÷ 1000 (GS 700 → ×1,7; GS 2000 → ×3,0);
  - defesa/proteção das peças de armadura seguem a mesma curva.
- A durabilidade continua valendo: equipamento quebrado perde força (já implementado).

## 4. Masmorras ⚑ (nomes e GS: exemplos do proprietário)

| Masmorra | GS de entrada | Teto de sync (GS) | Nível mínimo | Teto de nível | Jogadores |
|---|---|---|---|---|---|
| Ruínas Esquecidas | 300 | 300 | 20 | 24 | 1–4 |
| Catacumbas Sombrias | 500 | 500 | 26 | 30 | 1–4 |
| Fortaleza Abandonada | 700 | 700 | 32 | 36 | 1–4 |
| Templo dos Condenados | 1000 | 1000 | 40 | 44 | 1–4 |
| Abismo Ancestral | 1500 | 1500 | 48 | 52 | 1–4 |
| Cidadela do Caos | 2000 | 2000 | 56 | 60 | 1–4 |

- **Masmorras começam no nível 20** (decisão do proprietário). Antes disso, o jogador
  progride em áreas abertas, missões e chefes de área.
- **Requisito de entrada:** GS ≥ GS de entrada **e** nível ≥ nível mínimo da masmorra ⚑.
- Cada masmorra é um arquivo de dados (`DungeonData`): nome, requisitos, tetos, cena,
  inimigos, chefe e recompensas. Criar uma nova = criar um arquivo + a cena do mapa.

## 5. Dungeon Sync ⚑

Ao **entrar** numa masmorra, para **cada jogador individualmente**:

1. **Nível efetivo** = mín(nível real, teto de nível) → HP/MP/dano-base recalculados pela tabela da §2.
2. **GS efetivo** = mín(GS real, teto de sync). Cada equipamento acima do teto tem seus
   números calculados como se tivesse GS = teto (o item em si não muda).
3. **Habilidades** com nível de liberação > nível efetivo ficam **bloqueadas** (cadeado
   "Sincronizado" na barra), mesmo que o jogador já as tenha.
4. Fora da masmorra o personagem **continua** com GS e nível reais (interface mostra
   "GS 2000 (sincronizado: 700)").

Ao **sair**, tudo é restaurado automaticamente. Implementação: o personagem nunca tem seus
dados alterados — todas as contas passam por valores "efetivos", que leem o teto ativo.
Sair = remover o teto. Não há risco de perder itens ou nível.

**Recompensas em sync:** itens dropados respeitam o GS da masmorra (não o do jogador).
Incentivo para revisitar: experiência ajustada ao nível efetivo + recompensa diária ⚑
(etapa futura).

## 6. Funções no grupo (equilíbrio)

| Função | Disciplinas principais |
|---|---|
| Proteção (tanque) | Bastião, Vanguarda (iniciador), Oráculo (mitigação) |
| Dano corpo a corpo | Carrasco, Assassino, Duelista, Hemomante |
| Dano à distância | Piromante, Tempestário, Rastreador, Atirador, Inquisidor |
| Controle | Criomante, Armadilheiro, Domador, Pactário |
| Suporte / cura | Sacerdote, Oráculo, Necromante (invocações que protegem) |

Regra de equilíbrio: nenhuma disciplina tem só uma função; cada uma tem **uma função
principal forte** e **uma secundária fraca**, e nenhuma tem cura forte + dano forte ao mesmo tempo.

## 7. As 18 disciplinas — habilidades propostas ⚑

Formato: **Nome** (nível) — efeito. Recargas e números exatos ficam para a etapa de equilíbrio.

**Armas por classe (decisão do proprietário: cada classe usa só as suas):**

| Classe | Armas permitidas | Mão secundária |
|---|---|---|
| Guardião | espada, maça, machado | escudo |
| Arcanista | cajado | foco arcano |
| Errante | adagas, espada leve, facas de arremesso | — (adaga secundária) |
| Devoto | maça, cetro | relíquia |
| Caçador | arco, besta | aljava |
| Profano | foice, grimório | talismã |

### 1. Guardião (espada/maça + escudo)
**Bastião** — *passivo Muralha: bloquear gera Firmeza (reduz dano por alguns segundos).*
1. **Golpe de escudo** (1) — empurra e atordoa o alvo à frente.
2. **Provocar** (1) — inimigos próximos atacam o Bastião por 4 s.
3. **Postura inabalável** (8) — enquanto defende, não é empurrado e bloqueia por todos os lados.
4. **Muralha compartilhada** (18) — aliados próximos recebem 30% menos dano por 6 s.
5. **Bastião eterno** (30) — por 5 s não cai abaixo de 1 de vida.
6. **Fortaleza viva** (45) — cria uma cúpula que bloqueia projéteis inimigos por 8 s.

**Carrasco** — *passivo Sentença: dano extra contra inimigos com menos de 30% de vida.*
1. **Golpe esmagador** (1) — golpe lento e muito forte.
2. **Corte em arco** (1) — giro que acerta tudo em volta.
3. **Fratura** (8) — o alvo recebe mais dano por 5 s.
4. **Fúria do carrasco** (18) — golpes mais rápidos, recebe mais dano (risco/recompensa).
5. **Execução** (30) — mata na hora inimigo comum abaixo de 20% de vida; dano enorme em chefes.
6. **Veredito final** (45) — salto que golpeia o chão, dano em área proporcional à vida perdida dos alvos.

**Vanguarda** — *passivo Ímpeto: cada investida reduz a recarga das outras habilidades.*
1. **Investida** (1) — avança e empurra o primeiro inimigo.
2. **Quebra-linha** (1) — golpe que atravessa e derruba inimigos em linha.
3. **Salto de assalto** (8) — salta até um ponto e atordoa ao cair.
4. **Grito de guerra** (18) — aliados próximos ficam mais rápidos e com mais dano.
5. **Carga devastadora** (30) — investida longa, invencível durante o avanço.
6. **Ponta de lança** (45) — 3 investidas seguidas em direções escolhidas.

### 2. Arcanista (cajado; ataque básico = projétil mágico)
**Piromante** — *passivo Combustão: acertos aplicam Queimadura (dano contínuo, acumula).*
1. **Bola de fogo** (1) — projétil que explode em área.
2. **Rastro de chamas** (1) — deixa fogo no chão ao se esquivar.
3. **Muro de fogo** (8) — barreira de chamas que queima quem atravessa.
4. **Ignição** (18) — detona as Queimaduras dos alvos de uma vez.
5. **Chuva de meteoros** (30) — meteoros caem numa área por 3 s.
6. **Coração do inferno** (45) — vira um núcleo de fogo: todo ataque explode, por 8 s.

**Criomante** — *passivo Frio cortante: acertos aplicam Lentidão; 3 acúmulos congelam.*
1. **Lança de gelo** (1) — projétil que atravessa e deixa lento.
2. **Armadura de geada** (1) — escudo que deixa lento quem ataca o Criomante.
3. **Campo congelado** (8) — chão de gelo que deixa inimigos lentos.
4. **Prisão de gelo** (18) — congela um alvo por 3 s (chefes: só lentidão).
5. **Nevasca** (30) — área grande de lentidão e dano contínuo.
6. **Zero absoluto** (45) — congela todos os inimigos na tela por 2 s.

**Tempestário** — *passivo Carga: ataques rápidos acumulam Carga; com 5, o próximo raio salta para mais alvos.*
1. **Faísca** (1) — disparos rápidos e fracos.
2. **Passo relâmpago** (1) — teleporte curto na direção do mouse.
3. **Corrente elétrica** (8) — raio que salta entre até 4 inimigos.
4. **Sobrecarga** (18) — por 6 s, ataques muito mais rápidos.
5. **Tempestade** (30) — raios caem aleatoriamente em volta por 5 s.
6. **Avatar do trovão** (45) — por 8 s todo ataque vira Corrente elétrica.

### 3. Errante (adagas/espada leve/arremessos)
**Assassino** — *passivo Ponto fraco: ataques pelas costas são críticos garantidos.*
1. **Apunhalar** (1) — golpe rápido com dano alto pelas costas.
2. **Véu de sombras** (1) — fica invisível por 3 s (atacar revela).
3. **Lâmina envenenada** (8) — próximos golpes aplicam veneno.
4. **Passo sombrio** (18) — teleporta para as costas do alvo.
5. **Marca da morte** (30) — o alvo recebe todo dano acumulado de novo ao fim de 5 s.
6. **Mil cortes** (45) — some e golpeia todos os inimigos próximos várias vezes.

**Duelista** — *passivo Ritmo: esquiva perfeita dá Ritmo (mais velocidade de ataque, acumula até 5).*
1. **Estocada** (1) — avanço curto com golpe preciso.
2. **Aparar** (1) — janela curta que anula um golpe e contra-ataca.
3. **Dança de lâminas** (8) — combo de 5 golpes rápidos.
4. **Passo fantasma** (18) — esquiva que deixa uma imagem que distrai inimigos.
5. **Duelo** (30) — liga-se a um alvo: mais dano contra ele, menos contra outros.
6. **Tempestade de aço** (45) — por 6 s esquivas não têm recarga e cada esquiva golpeia.

**Rastreador** — *passivo Presa marcada: inimigo marcado recebe mais dano e aparece através de paredes.*
1. **Arremesso de faca** (1) — projétil rápido de longa distância.
2. **Marcar presa** (1) — marca um alvo por 15 s.
3. **Rede** (8) — prende um inimigo no lugar por 2 s.
4. **Tiro perfurante** (18) — atravessa todos em linha, dano extra no marcado.
5. **Instinto de caça** (30) — revela todos os inimigos e armadilhas da sala; mais dano por 8 s.
6. **Golpe de misericórdia** (45) — teleporta até o marcado e causa dano enorme.

### 4. Devoto (maça/cetro + relíquia)
**Sacerdote** — *passivo Graça: curar um aliado cheio dá um escudo de vida a ele.*
1. **Luz curativa** (1) — cura um aliado (ou a si mesmo) à distância.
2. **Raio sagrado** (1) — projétil fraco que cura aliados que atravessa.
3. **Bênção de proteção** (8) — escudo que absorve dano num aliado.
4. **Círculo de cura** (18) — área que cura aliados dentro por 6 s.
5. **Ressurreição** (30) — levanta um aliado caído (co-op) / revive a si com metade da vida uma vez por masmorra (solo).
6. **Milagre** (45) — cura total do grupo e remove efeitos negativos.

**Inquisidor** — *passivo Julgamento: dano extra contra mortos-vivos, demônios e criaturas profanas.*
1. **Martelo da fé** (1) — golpe que libera uma onda sagrada curta.
2. **Selo sagrado** (1) — marca o chão; inimigos profanos que entram são atordoados.
3. **Lança de luz** (8) — projétil sagrado de longa distância.
4. **Purgar** (18) — remove escudos/fortalecimentos dos inimigos próximos.
5. **Consagração** (30) — área sagrada: inimigos dentro recebem dano contínuo e ficam lentos.
6. **Ira divina** (45) — coluna de luz enorme no alvo; mata profanos comuns na hora.

**Oráculo** — *passivo Presságio: um ícone avisa, 1 s antes, o próximo ataque forte que vai atingir um aliado.*
1. **Visão** (1) — por 3 s, mostra para onde os inimigos próximos vão atacar.
2. **Bênção da sorte** (1) — aliado ganha chance de esquivar golpes automaticamente.
3. **Elo do destino** (8) — divide o dano entre aliados ligados.
4. **Reverter o tempo** (18) — volta um aliado para a posição e vida de 3 s atrás.
5. **Profecia** (30) — o próximo golpe fatal num aliado é anulado.
6. **Destino selado** (45) — por 6 s, todos os aliados acertam críticos e os inimigos ficam lentos.

### 5. Caçador (arco/besta)
**Atirador** — *passivo Mira firme: parado, cada tiro causa mais dano (acumula).*
1. **Tiro carregado** (1) — segurar para mais alcance e dano.
2. **Rolamento tático** (1) — esquiva que recarrega o próximo tiro como crítico.
3. **Chuva de flechas** (8) — flechas caem numa área.
4. **Tiro triplo** (18) — 3 flechas em leque.
5. **Flecha explosiva** (30) — explode ao acertar, dano em área.
6. **Olho de águia** (45) — por 8 s, todos os tiros perfuram e são críticos.

**Domador** — *passivo Vínculo: um companheiro animal acompanha e ataca o alvo do Domador.*
1. **Chamar companheiro** (1) — invoca/reposiciona o companheiro (lobo no início ⚑).
2. **Ordem: atacar** (1) — o companheiro investe contra o alvo e o derruba.
3. **Ordem: proteger** (8) — o companheiro provoca inimigos e protege o Domador.
4. **Fúria selvagem** (18) — Domador e companheiro ficam mais rápidos e fortes.
5. **Matilha** (30) — dois companheiros extras por 10 s.
6. **Espírito ancestral** (45) — o companheiro vira uma fera gigante por 10 s.

**Armadilheiro** — *passivo Preparação: armadilhas montadas fora de combate ficam mais fortes.*
1. **Armadilha de urso** (1) — prende o primeiro inimigo que pisar.
2. **Granada de fumaça** (1) — área que confunde inimigos (atacam qualquer um).
3. **Mina explosiva** (8) — explode quando um inimigo passa.
4. **Cerca de espinhos** (18) — barreira que causa dano e bloqueia passagem.
5. **Campo minado** (30) — espalha 5 minas numa área.
6. **Arapuca mestra** (45) — prende todos os inimigos numa grande área por 3 s.

### 6. Profano (foice/grimório)
**Necromante** — *passivo Colheita: inimigos derrotados perto deixam almas (recurso para invocar).*
1. **Erguer servo** (1) — invoca um esqueleto (até 3).
2. **Toque mortal** (1) — projétil sombrio que drena vida.
3. **Explosão de cadáver** (8) — um servo explode em área.
4. **Exército dos mortos** (18) — todos os servos ficam mais fortes por 8 s.
5. **Lorde ossudo** (30) — invoca um guerreiro morto-vivo grande por 15 s.
6. **Dança macabra** (45) — inimigos derrotados por 10 s levantam como servos temporários.

**Hemomante** — *passivo Preço de sangue: habilidades gastam VIDA em vez de mana; quanto menos vida, mais dano.*
1. **Lâmina de sangue** (1) — golpe que custa vida e causa muito dano.
2. **Sifão** (1) — drena vida de um inimigo próximo.
3. **Pacto rubro** (8) — sacrifica 20% da vida: mais dano por 8 s.
4. **Tempestade carmesim** (18) — área que drena vida de todos os inimigos dentro.
5. **Transfusão** (30) — troca porcentagem de vida com um inimigo (não funciona em chefes).
6. **Avatar sanguíneo** (45) — por 8 s, todo dano causado cura o Hemomante.

**Pactário** — *passivo Dívida: usar habilidades acumula Dívida; Dívida cheia = a entidade cobra (dano no Pactário) ou recompensa (efeito forte), escolhido por ritmo de uso.*
1. **Chamado da entidade** (1) — um tentáculo agarra e puxa o inimigo.
2. **Selo proibido** (1) — maldição: o alvo causa menos dano.
3. **Olhos do abismo** (8) — inimigos próximos ficam com medo e fogem por 2 s.
4. **Troca de almas** (18) — troca de lugar com um inimigo.
5. **Portal profano** (30) — abre um portal que atrai e prende inimigos.
6. **Manifestação** (45) — a entidade aparece e ataca tudo por 8 s (paga com Dívida máxima).

## 8. Como isso vira código (arquitetura) ⚑

- `ClassData` (6 arquivos) e `DisciplineData` (18 arquivos, cada um aponta para a classe,
  passivo e 6 habilidades com nível de liberação). Já existe a base: `AbilityData` + `DisciplineData`.
- `CharacterProfile` (autoload/recurso): classe, disciplina, nível, exp., inventário,
  equipamento, missões — **sobrevive à troca de mapas** (necessário para entrar em masmorras)
  e vira a base do salvamento.
- `SyncState` no jogador: `{level_cap, gs_cap}` ou nada. Todas as contas usam
  `effective_level()` e `effective_gs()`. Entrar na masmorra define; sair remove.
- `DungeonData` + `DungeonEntrance` (portal "[E] Entrar" que verifica requisitos e mostra
  o motivo da recusa) + `DungeonExit`.
- Habilidades: um executor por tipo de mecânica (projétil, área, investida, invocação,
  armadilha, efeito de status, escudo...), reaproveitado entre disciplinas. Sistema de
  **efeitos de status** (queimadura, lentidão, congelamento, veneno, atordoamento, medo,
  escudo) necessário para quase todas as disciplinas.

## 9. Etapas de implementação propostas

| Etapa | Entrega | Testável pelo proprietário |
|---|---|---|
| A | Dados: 6 classes, 18 disciplinas; tela de criação (classe → disciplina); base igual por nível; remoção dos bônus provisórios | escolher qualquer uma das 18 |
| B | Efeitos de status (lentidão, congelar, queimar, veneno, atordoar, escudo) | — (base técnica) |
| C | Habilidades **iniciais** (teclas 1–2) das 18 disciplinas + passivos | jogar cada disciplina no começo |
| D | GS: GS nos itens, GS do personagem, escala de dano; armadura (4 espaços novos) | ver GS subir com equipamento |
| E | Perfil persistente entre mapas; masmorra 1 (Ruínas Esquecidas) com entrada/saída e requisitos | entrar e sair |
| F | Dungeon Sync completo + interface "sincronizado" | entrar com personagem forte numa masmorra fraca |
| G | Habilidades de nível 8 e 18 | — |
| H | Habilidades de nível 30 e 45 | — |
| I | Chefe da masmorra 1; enigmas | — |

Cada etapa com testes automáticos, worklog e commit.

## 10. Decisões do proprietário (2026-11-07)

1. Nomes das habilidades da §7: **aprovados**.
2. Sistema de pontos: **não** — crescimento automático por nível (implementado).
3. Nível máximo: **60**.
4. Masmorras: **a partir do nível 20**.
5. Armas: **cada classe usa só os seus tipos**.
6. Mana: **não recupera sozinha**; só com itens.
7. Ponto de descanso: **removido**; continuar após a morte volta ao início da área.
8. Ordem das etapas (§9): mantida.

Os 3 primeiros chefes estão em `documentation/design/chefes-iniciais.md`.
