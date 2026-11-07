# ALYSPERIN — Os 3 primeiros Chefes

- **Status:** APROVADO v2 (2026-11-07). Proprietário aprovou os 3 chefes, os números de dano
  na tela e os óleos de arma, e acrescentou a regra de Fúria (§0).
- **Origem:** especificação do proprietário "Criação dos 3 primeiros Bosses"
  (inspiração Monster Hunter: fraquezas elementais, partes destrutíveis, descoberta em combate).
- **Escopo:** exatamente 3 chefes, um para cada uma das 3 primeiras masmorras.
- **Filosofia (do proprietário):** o jogador não recebe manual. Nada de bestiário, dicas,
  revelação de fraquezas ou interface indicando elemento. Tudo se descobre observando.
- **Atenção:** as seções "Estratégias possíveis" existem **só neste documento**, para a equipe.
  Nada delas aparece no jogo.

---

## 0. Regras comuns (padrão para todos os chefes futuros)

### Elementos e tabela de resistência
Elementos: **Fogo, Gelo, Raio, Terra, Luz, Trevas**. Ataques físicos sem elemento são **neutros**.

| Classificação | Multiplicador de dano ⚑ | Reação visível do chefe |
|---|---|---|
| Muito vulnerável | ×1,75 | recua, faísca grande da cor do elemento, som grave, às vezes interrompe o ataque |
| Vulnerável | ×1,35 | estremece, faísca média |
| Neutro | ×1,0 | faísca normal |
| Resistente | ×0,6 | faísca pequena e apagada, sem reação |
| Muito resistente | ×0,3 | o elemento "escorre" pelo corpo (efeito de dissipação), o chefe nem se vira |

- **De onde vem cada elemento hoje:** Fogo (Piromante), Gelo (Criomante), Raio
  (Tempestário), Luz (Inquisidor, Sacerdote), Trevas (Profano: Necromante, Hemomante,
  Pactário). **Terra:** nenhuma disciplina tem como elemento principal. Proposta ⚑: golpes
  pesados de maça e machado (Guardião: Bastião/Carrasco), flechas e armadilhas de pedra
  (Caçador) e **óleos/encantamentos de arma** (itens consumíveis que dão um elemento à
  arma por um tempo, para qualquer classe). Os óleos também garantem que **nenhuma
  disciplina fique sem resposta** a uma fraqueza.
- **Números de dano na tela** (aprovado): números flutuantes com **tamanho e cor**
  proporcionais ao dano, sem nome de elemento. **Já implementado** para todos os inimigos.

### Partes destrutíveis
Cada parte tem **vida própria** (Hurtbox separada). O dano na parte também conta para a
vida total do chefe. Ao quebrar: animação de quebra, mudança visual permanente na luta,
consequência mecânica real e **material garantido** daquela parte.

### Fases
Mudam por **vida do chefe** (≈ 70% e 35%) e por **eventos** (partes quebradas, ambiente).
Toda transição tem uma animação de 1–2 s em que o chefe fica **invulnerável e parado**
(respiro para o grupo) ⚑. Mudanças de resistência são sempre acompanhadas de mudança de
aparência — nunca de texto.

### Fúria (regra do proprietário, vale para TODOS os chefes)
Aos **70%, 50% e 20%** de vida o chefe entra em **Fúria**. Em Fúria os ataques ficam
**mais rápidos e mais fortes**. Cada limiar ativa a Fúria de novo e mais intensa ⚑:

| Limiar | Velocidade dos ataques ⚑ | Dano ⚑ | Sinal visual (sem texto) |
|---|---|---|---|
| 70% | +15% | +15% | rugido + aura vermelha fraca |
| 50% | +25% | +25% | aura mais forte, olhos/brilho mudam de cor |
| 20% | +40% | +40% | aura intensa, respiração ofegante visível |

- Os avisos dos ataques (chão/postura) **encurtam junto**, mas nunca abaixo de 0,35 s ⚑
  — continua justo.
- A Fúria **se soma** às fases (70%/35%): no limiar de 70% o chefe muda de fase e entra em
  Fúria ao mesmo tempo.
- A entrada em Fúria tem uma animação curta (rugido) em que o chefe não ataca ⚑.

### Ataques justos
Todo ataque forte tem **aviso no chão** (como a faixa vermelha do protótipo) ou uma
**postura de preparação** reconhecível de 0,5–1,2 s. Ataques sem aviso só os fracos.

### Equilíbrio entre funções
Cada chefe tem: um momento para **tanques** (algo que precisa ser segurado/provocado), um
para **controle** (algo que precisa ser interrompido/desacelerado), um para **suporte**
(dano em área previsível que exige cura/escudo), e partes que recompensam **dano focado**.

---

## 1. Khar'Vesh, a Mãe-Raiz

**Masmorra:** Ruínas Esquecidas — **GS 300**, nível 20–24. Dificuldade: introdutória (ensina
a ler fraquezas e quebrar partes).

### 1.1 Conceito
Uma árvore-fera colossal que cresceu dentro de um templo afundado, enraizada no próprio
altar. É um chefe **de território**: começa presa ao chão e controla a arena com raízes.

### 1.2 História e origem
Antes das ruínas serem esquecidas, os sacerdotes do templo plantaram uma semente no altar
como oferenda a um deus da colheita que nunca respondeu. A semente bebeu o sangue dos
sacrifícios por séculos. Quando o templo afundou, a planta continuou crescendo no escuro,
até ganhar fome, vontade e uma única ideia: **proteger o altar**, que ela entende como
seu ventre. Os aldeões chamam de Mãe-Raiz porque, ao seu redor, nada mais cresce.

### 1.3 Aparência
Tronco do tamanho de uma torre caída, curvado como um corpo ajoelhado. Casca negra
rachada com veios avermelhados (a seiva de sangue). No lugar do rosto, uma fenda vertical
cheia de espinhos que se abre como boca. Dois **galhos-chicote** longos como braços. Nas
costas, três **bulbos de seiva** pulsantes, translúcidos e vermelhos. Raízes grossas se
espalham pelo chão da arena, quebrando os ladrilhos antigos.

### 1.4 Localização e ambiente
Câmara principal do templo afundado: chão de pedra rachada, **poças de água** em
cantos (infiltração), pilares tombados, luz fraca vinda de rachaduras no teto. O altar
fica sob o tronco.

### 1.5 Personalidade e comportamento
Paciente e defensiva. Não persegue: ocupa espaço. Fica mais agressiva quanto mais perto o
jogador chega do altar. Quando ferida, "sangra" seiva e tenta se curar.

### 1.6 Resistências
| Elemento | Classificação |
|---|---|
| Fogo | **Muito vulnerável** |
| Gelo | Vulnerável |
| Raio | Neutro |
| Terra | **Muito resistente** |
| Luz | Neutro |
| Trevas | Resistente |

**Mudanças durante a luta (sem aviso em texto):**
- **Molhada:** quando ela mergulha raízes nas poças (fase 2), a casca fica **escura e
  brilhante, pingando**. Nesse estado, Fogo cai para **Neutro** e Raio sobe para
  **Vulnerável**, por ~10 s, até secar (a casca volta a ficar fosca).
- **Sem casca** (fase 3): Terra cai para **Neutro**.

### 1.7 Partes destrutíveis
| Parte | Vida da parte ⚑ | Consequência ao quebrar | Material |
|---|---|---|---|
| Bulbos de seiva (×3, costas) | baixa | cada bulbo destruído **reduz a cura** dela em 1/3; os 3 = sem cura | Seiva Rubra |
| Galho-chicote esquerdo / direito | média | aquele lado perde o **alcance longo** (o chicote vira golpe curto) | Galho Vivo |
| Casca do tronco | alta | expõe o **cerne** (ponto fraco: dano crítico) e libera a fase 3 | Casca Ancestral |
| Fenda-boca | média | ela **atordoa** por 4 s e perde o ataque de esporos | Espinho de Altar |

### 1.8 Ataques
- **Chicotada** (aviso: galho recua e treme) — faixa longa à frente.
- **Varredura de raízes** (aviso: chão racha em arco) — arco de 180° em volta.
- **Lança de raiz** (aviso: círculo de terra levantando sob o jogador, 0,8 s) — raiz brota do chão.
- **Nuvem de esporos** (aviso: fenda incha e brilha) — área que deixa **lento** e tira vida aos poucos.
- **Sugar seiva** (aviso: bulbos pulsam forte) — cura por 3 s; interrompida se levar dano alto
  num bulbo ou atordoamento.
- **Brotos** — invoca 2–3 pequenas plantas que mordem (fase 2+).

### 1.9 Fases
1. **Enraizada (100–70%)** — imóvel. Chicotadas, varreduras, lanças de raiz. Ensina a ler
   avisos. Bulbos ficam expostos quando ela se inclina após a varredura (janela de 2 s).
2. **Desperta (70–35%)** — arranca metade das raízes e passa a **se arrastar** lentamente
   pela arena. Começa a mergulhar raízes nas poças (estado Molhada). Invoca brotos. Esporos.
3. **Ferida aberta (35–0%)** — a casca se parte sozinha se ainda não foi quebrada; o cerne
   vermelho fica à mostra e pulsa. Ataques mais rápidos, raízes saem em sequência
   (3 lanças seguidas). **Momento de vulnerabilidade:** após cada sequência de lanças ela
   fica 3 s ofegante, com o cerne aberto.

### 1.10 Estratégias possíveis (só para a equipe)
- Descobrir que fogo funciona muito bem — mas notar que molhada ele perde força e raio passa
  a funcionar. Afastá-la das poças (provocar o tanque longe da água) mantém a fraqueza.
- Quebrar os bulbos cedo transforma a luta: sem cura, ela fica muito mais curta.
- Quebrar os chicotes reduz o perigo para quem ataca de longe.

### 1.11 Recompensas
- **Seiva Rubra** (bulbos) — poções melhores e óleos de Fogo.
- **Galho Vivo** (chicotes) — cajados (Arcanista) e arcos (Caçador).
- **Casca Ancestral** — escudos e armaduras de nível inicial com resistência a Terra.
- **Espinho de Altar** (boca) — adagas/facas (Errante).
- **Coração Germinado** (raro, chance ao derrotar) — necessário para criar o primeiro
  equipamento de raridade superior.

### 1.12 Contribuição das classes
- **Guardião (Bastião)**: segura a atenção longe das poças; bloqueia chicotadas.
- **Arcanista**: Piromante brilha; Tempestário aproveita o estado Molhada; Criomante desacelera os brotos.
- **Errante**: Assassino quebra os bulbos nas costas (ataques pelas costas).
- **Devoto**: Sacerdote limpa/cura a lentidão dos esporos.
- **Caçador**: Atirador quebra bulbos de longe; Armadilheiro segura os brotos.
- **Profano**: servos do Necromante distraem os brotos; Pactário interrompe a cura (medo/puxão).

---

## 2. Velkhor, o Coro dos Mil Ossos

**Masmorra:** Catacumbas Sombrias — **GS 500**, nível 26–30. Dificuldade: média (exige
**prioridade de alvos** e leitura de padrões de magia).

### 2.1 Conceito
Uma montanha de ossos fundidos em forma de gigante, com **três crânios** que cantam — cada um
lança um tipo diferente de magia. É um chefe **de padrões e prioridades**: o grupo decide
qual crânio calar primeiro.

### 2.2 História e origem
As catacumbas guardavam os mortos de uma cidade inteira durante uma praga. Um coral de
monges ficou trancado lá dentro, cantando para acalmar os moribundos, até morrer também.
O canto nunca parou: ele se prendeu aos ossos e foi juntando todos os mortos num só corpo.
Velkhor não é um morto-vivo comum — é **uma canção que ganhou carne de osso**, e cada
crânio é um dos últimos monges, ainda cantando a mesma oração distorcida.

### 2.3 Aparência
Um gigante corcunda feito de milhares de ossos encaixados, costelas formando uma **gaiola
torácica em forma de sino** com um brilho azul-pálido dentro (o "coração do coro"). Três
crânios grandes nos ombros e no topo, cada um com um capuz de pano podre e uma vela
derretida grudada. Braços longos que arrastam no chão, terminando em mãos feitas de
fêmures. Ao se mover, ossos soltos caem e voltam a se encaixar.

### 2.4 Localização e ambiente
Uma cripta circular com **nichos de ossos** nas paredes e **quatro lanternas de almas**
(chamas azuis) nos cantos. Teto alto com um sino quebrado pendurado. Chão de lápides.

### 2.5 Personalidade e comportamento
Ritualístico. Repete padrões como uma liturgia (o grupo pode aprender o "ritmo"). Os
crânios reagem entre si: se um é calado, os outros cantam mais alto.

### 2.6 Resistências
| Elemento | Classificação |
|---|---|
| Fogo | Neutro |
| Gelo | Resistente |
| Raio | Neutro |
| Terra | Vulnerável |
| Luz | **Muito vulnerável** |
| Trevas | **Muito resistente** |

**Mudanças durante a luta:**
- **Lanternas absorvidas** (fase 2): quando ele suga uma lanterna de almas, os ossos ganham
  um **brilho dourado-esverdeado** e Luz cai de Muito vulnerável para **Neutro** por ~15 s.
  Apagar as lanternas antes (golpeá-las) impede isso.
- **Sino exposto** (fase 3): com a gaiola quebrada, o coração azul fica **Muito vulnerável a
  Raio** (o canto vibra e o raio "ressoa" — faíscas extras).

### 2.7 Partes destrutíveis
| Parte | Consequência ao quebrar | Material |
|---|---|---|
| Crânio do Lamento (esquerdo) | para as **ondas de medo** (inimigos próximos fogem/jogadores ficam lentos) | Crânio Cantor |
| Crânio da Vigília (direito) | para de **invocar esqueletos** | Crânio Cantor |
| Crânio da Penitência (topo) | para a **chuva de velas** (área de fogo) | Cera Funerária |
| Gaiola torácica | expõe o coração (crítico + fraqueza a Raio) e libera a fase 3 | Costela-Sino |
| Mãos de fêmur | perde o **agarrão** daquele lado | Osso Fundido |

### 2.8 Ataques
- **Esmagar** (aviso: braço sobe e cai em linha) — linha de dano.
- **Agarrão** (aviso: mão se abre rente ao chão) — agarra e prende um jogador por 2 s
  (aliados libertam causando dano na mão).
- **Onda de lamento** (Crânio do Lamento; aviso: crânio abre a boca e escurece) — anel de medo.
- **Vigília** (Crânio da Vigília; aviso: o crânio brilha azul) — invoca 3 esqueletos dos nichos.
- **Chuva de velas** (Crânio da Penitência; aviso: velas acendem) — gotas de cera em chamas
  caem em círculos marcados.
- **Coro** (fase 3; aviso: os crânios restantes cantam juntos por 2 s) — explosão em toda a
  sala, exceto atrás de lápides grandes (o grupo precisa se esconder).

### 2.9 Fases
1. **Liturgia (100–70%)** — ataques físicos lentos e um crânio por vez canta, em ordem fixa
   (Lamento → Vigília → Penitência). O ritmo é aprendível.
2. **Coro crescente (70–35%)** — dois crânios cantam ao mesmo tempo. Ele vai até as
   lanternas para absorvê-las (estado dourado). Mais esqueletos.
3. **Réquiem (35–0%)** — a gaiola racha (se não foi quebrada); o coração azul fica à mostra.
   Usa o **Coro** a cada ~25 s. **Vulnerabilidade:** depois de cada Coro, ele desaba de joelhos
   por 4 s com o coração exposto.

### 2.10 Estratégias possíveis (só para a equipe)
- Perceber que Luz destrói, mas que ele "fica dourado" e a Luz perde força — e ligar isso às
  lanternas. Apagar as lanternas cedo mantém a fraqueza.
- Escolher qual crânio calar primeiro muda a luta (grupos sem cura calam a Penitência; grupos
  com pouco controle calam a Vigília).
- Trevas quase não funcionam — Profanos contribuem com controle, servos e quebra de partes.

### 2.11 Recompensas
- **Crânio Cantor** — relíquias (Devoto) e grimórios (Profano).
- **Cera Funerária** — óleos de Fogo e Luz; velas de proteção (consumível).
- **Costela-Sino** — armaduras pesadas e escudos com resistência a Trevas.
- **Osso Fundido** — foices (Profano) e maças (Guardião/Devoto).
- **Nota do Último Monge** (raro) — item de progressão para conteúdos sagrados posteriores.

### 2.12 Contribuição das classes
- **Guardião**: Bastião provoca para afastar o Agarrão dos frágeis; Carrasco quebra mãos e gaiola.
- **Arcanista**: Tempestário domina a fase 3 (coração + Raio); Piromante é neutro, mas forte em área contra esqueletos.
- **Errante**: Rastreador quebra crânios de longe; Duelista sobrevive às ondas com esquivas.
- **Devoto**: Inquisidor é a resposta natural (Luz e bônus contra profanos); Oráculo prevê o Coro.
- **Caçador**: Atirador quebra crânios; Armadilheiro prende esqueletos.
- **Profano**: Trevas fracas, mas Necromante segura esqueletos com servos; Pactário puxa/medo nos invocados.

---

## 3. Nhalgrim, a Serpe de Cinzas

**Masmorra:** Fortaleza Abandonada — **GS 700**, nível 32–36. Dificuldade: alta para o ponto
(exige **posicionamento e mobilidade**; luta mais "Monster Hunter" das três).

### 3.1 Conceito
Uma serpe (dragão de duas patas e asas) que fez ninho nas torres queimadas de uma fortaleza.
Chefe **móvel e aéreo**, que voa sobre a arena e muda de temperatura durante a luta.

### 3.2 História e origem
A fortaleza caiu numa guerra antiga quando seus próprios defensores a incendiaram para não
entregá-la. O fogo nunca se apagou por completo nas fundações. Uma serpe jovem encontrou ali
um ninho quente e passou décadas comendo **cinzas e brasas**. O corpo dela virou parte do
incêndio: as escamas são carvão vivo, e o fogo das fundações responde ao rugido dela.

### 3.3 Aparência
Corpo longo e magro, cinza-carvão com rachaduras alaranjadas que brilham ao respirar. Asas
membranosas rasgadas, com bordas que soltam fagulhas. Cabeça estreita com chifres curvos
para trás e um **saco de chamas** na garganta que incha e brilha antes de cuspir fogo. Cauda
longa terminando numa lâmina óssea. Ao se aquecer, as rachaduras ficam brancas e o corpo
inteiro passa a soltar fumaça.

### 3.4 Localização e ambiente
O pátio central da fortaleza: muralhas caídas, **grades de ferro no chão** sobre as fundações
em brasa (quando ela ruge, jatos de fogo saem das grades), escombros que servem de cobertura,
e uma torre parcialmente desabada onde ela pousa.

### 3.5 Personalidade e comportamento
Territorial e orgulhosa. Testa o grupo de longe antes de descer. Foge para o ar quando
ferida, e volta mais furiosa. Odeia ser cercada: se três jogadores ficam perto, ela levanta voo.

### 3.6 Resistências
| Elemento | Classificação |
|---|---|
| Fogo | **Muito resistente** |
| Gelo | **Muito vulnerável** |
| Raio | Vulnerável (Muito vulnerável nas **asas** quando voando) |
| Terra | Neutro |
| Luz | Neutro |
| Trevas | Resistente |

**Mudança de temperatura (sem aviso em texto):**
- **Superaquecida** (fase 3, rachaduras **brancas**, fumaça): Fogo vira **imunidade total**
  (cura levemente se atingida), mas Gelo causa **choque térmico** — dano ×2 e um atordoamento
  curto na primeira vez a cada 20 s.
- **Resfriada** (após receber muito Gelo, rachaduras ficam **apagadas e cinzentas** por ~8 s):
  escamas endurecem → dano físico **reduzido**, mas ela fica lenta e não consegue voar.

### 3.7 Partes destrutíveis
| Parte | Consequência ao quebrar | Material |
|---|---|---|
| Asas (esquerda/direita) | uma quebrada = voos curtos; as duas = **não voa mais** (fase 2 vira terrestre) | Membrana Fumegante |
| Cauda (cortável) | a varredura perde metade do alcance; a ponta cai e pode ser coletada | Lâmina Caudal |
| Cabeça | atordoamento a cada X de dano acumulado; quebrada = chifres partidos, ataques de chifrada mais curtos | Chifre de Brasa |
| Saco de chamas (garganta) | só pode ser atingido **enquanto incha** (antes do sopro); quebrado = explode na boca dela (dano alto) e ela **não cospe fogo** por 30 s | Glândula Ígnea |

### 3.8 Ataques
- **Mordida e chifrada** (aviso: cabeça recua) — frente curta.
- **Varredura de cauda** (aviso: corpo gira devagar) — círculo atrás e dos lados.
- **Sopro de brasas** (aviso: saco incha e brilha 1 s) — cone de fogo; deixa chão em chamas.
- **Rasante** (no ar; aviso: sombra no chão e grito) — atravessa a arena em linha.
- **Chuva de cinzas** (no ar; aviso: círculos escuros no chão) — bolas de fogo caem.
- **Rugido das fundações** (aviso: ela ruge com o pescoço erguido) — as grades soltam jatos
  de fogo; o grupo precisa sair de cima das grades.

### 3.9 Fases
1. **Caçada (100–70%)** — luta no chão. Mordidas, cauda, sopro. Levanta voo por curtos
   períodos quando cercada.
2. **Céu em chamas (70–35%)** — passa a maior parte do tempo **voando**: rasantes, chuva de
   cinzas. Pousa na torre para respirar (janela de 4 s). Asas quebradas encurtam ou cancelam
   esta fase.
3. **Fornalha (35–0%)** — pousa e fica **superaquecida**: rachaduras brancas, rugido das
   fundações a cada ~20 s, sopro mais longo. **Vulnerabilidade:** depois de cada rugido ela
   fica 3 s ofegante com o saco de chamas exposto.

### 3.10 Estratégias possíveis (só para a equipe)
- Fogo não funciona (nem na fase 3, onde até cura) — Piromantes precisam de óleo de outro
  elemento ou focar em controle/partes.
- Gelo é muito forte, e na fase 3 vira choque térmico. Resfriá-la demais endurece as escamas
  (físico rende menos) — saber dosar.
- Raio nas asas durante o voo derruba a fase 2.
- Acertar o saco de chamas no momento certo cancela o sopro.

### 3.11 Recompensas
- **Membrana Fumegante** — capas e armaduras leves (Errante/Caçador).
- **Lâmina Caudal** (só cortando a cauda) — espadas e machados temáticos.
- **Chifre de Brasa** — cajados de fogo e maças.
- **Glândula Ígnea** (só quebrando o saco) — óleos de Fogo fortes e flechas incendiárias.
- **Escama de Carvão Vivo** (rara) — material de aprimoramento de equipamentos acima de GS 700.

### 3.12 Contribuição das classes
- **Guardião**: Bastião segura a frente e bloqueia sopros; Vanguarda alcança rápido quando ela pousa.
- **Arcanista**: Criomante é a resposta natural (com cuidado para não "resfriar demais");
  Tempestário derruba no ar; Piromante contribui com óleos/controle e dano nos invocados de fogo ⚑.
- **Errante**: Duelista vive nas costas dela desviando da cauda; Rastreador acerta as asas.
- **Devoto**: Sacerdote sustenta o grupo nas chuvas de cinzas; Oráculo prevê rasantes.
- **Caçador**: Atirador é chave na fase aérea; Armadilheiro prende quando ela pousa.
- **Profano**: Hemomante aproveita a luta longa (cura com dano); Pactário puxa/prende quando no chão.

---

## 4. Como isso vira código (proposta) ⚑

- `ElementalProfile` (Resource): tabela elemento → classificação; o `DamageInfo` ganha o
  campo `element`; o `HealthComponent` do chefe aplica o multiplicador.
- `BossPart` (componente): Hurtbox própria com vida da parte, limite de quebra, sinal `broken`,
  material garantido; repassa o dano para a vida total.
- `Boss` base: máquina de estados por fase + "estados de corpo" (Molhada, Dourado,
  Superaquecida, Resfriada) que trocam o `ElementalProfile` ativo e a aparência.
- Reações visuais por classificação (faísca, recuo, som) num lugar só.
- Sem bestiário, sem dicas, sem interface de fraqueza — por design.

**Pré-requisitos no código antes dos chefes:** elementos nas habilidades (Etapa C do
documento de classes), efeitos de status (Etapa B), masmorras com entrada/saída (Etapa E).
Proposta: chefe 1 junto com a masmorra 1 (Etapa I).

## 5. Decisões do proprietário (2026-11-07)
1. Os 3 chefes: **aprovados**.
2. Números de dano na tela: **sim** (implementado).
3. Óleos/encantamentos de arma: **sim** (entram com os elementos, Etapa C).
4. **Fúria aos 70%, 50% e 20%** de vida, para todos os chefes (§0).
