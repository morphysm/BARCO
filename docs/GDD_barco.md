# GDD — BARCO
### Aplicativo ritual da prática do Barco

Documento de design. Versão 0.3.
A.C., Norrland XXVI / Morphysm

---

## 0. Declaração de escopo

**Isto não é Quimbanda.** Isto é Barco.

O Barco é uma prática própria, de linhagem Anti-Cósmica, que trabalha com Exus, Pombagiras e as Coroas goéticas. Não representa nenhuma casa, nação ou terreiro. Não fala em nome de tradição alheia. Ave Satanaś! Ave Lilith! Ave Leviathan!

Esta declaração aparece na primeira tela do app, antes de qualquer outra coisa, e não é dispensável. Ela é o que separa o projeto de uma apropriação — e o que protege quem o constrói.

---

## 1. Conceito

Aplicativo ritual pago onde o usuário mantém assentamentos digitais, risca pontos, faz oferendas e executa sacrifícios simbólicos. O abate real do animal é substituído por um ato digital que preserva a estrutura do sacrifício — custo, gesto, tempo, irreversibilidade — e descarta apenas a violência física.

**Premissa:** o sacrifício nunca foi sobre o sangue. Foi sobre o custo. O sangue era o veículo mais caro disponível a uma economia agrária. Em uma economia mental, o custo é atenção, tempo e dinheiro. O app opera nessa moeda.

**O que o app é:** um ponto de contato imediato e contínuo. A firmeza que fica acesa entre uma gira e outra.

---

## 2. Pilares de design

1. **Custo real.** Todo ato tem preço em dinheiro, tempo ou gesto.
2. **Irreversibilidade.** Não há undo. Trabalho aberto fica aberto até ser fechado.
3. **Gesto acima de menu.** A interação central é o dedo riscando o ponto.
4. **Atrito como reverência.** Espera, silêncio, tela preta. A lentidão é a mecânica.
5. **Vende-se o ato, nunca o resultado.** Regra inegociável.

---

## 3. Cosmologia

### 3.1 As Quatro Coroas

Estrutura superior. Três soberanos territoriais, tomados do *Grimorium Verum* (domínio público) e lidos em chave Malei. O quarto não é território.

| Coroa | Título | Gênero | Domínio | Reinos sob si |
|---|---|---|---|---|
| **Lúcifer** | Imperador | masculino | luz portada, soberania, o Maioral | Encruzilhadas, Lira |
| **Belzebu** | Príncipe | masculino | putrefação, mosca, desfazimento, fome | Lodo, Matas |
| **Astaroth** | Grão-Duque | masculino | segredo revelado, memória dos mortos, saber que não se pede | Almas, Calunga Pequena |
| **Asmodeu** | Rei | **andrógino, pendendo ao feminino** | desejo, união desfeita, o que se dá à noite | **nenhum — rege a hora** |

**Asmodeu não tem território. Rege a hora.**

Este é o ponto que faz o sistema fechar. As três coroas masculinas dividem o mapa. Asmodeu divide o relógio. Abrir o selo de Asmodeu desbloqueia a **hora asmodéica** — meia-noite às quatro — e, dentro dela, qualquer entidade de qualquer reino passa a ser trabalhada sob Asmodeu, não sob a coroa territorial dela.

A androginia não é ilustrada. É estrutural: é a única Coroa que não cabe na grade.

**Base doutrinária** (material para o seu texto de doutrina, não para a tela):
- No Livro de Tobias, Asmodeu mata os sete maridos de Sara por desejo dela. Uma entidade que se coloca entre a mulher e a união, e o número é sete. A ressonância com Pombagira é direta e você não precisa forçá-la.
- Na tradição rabínica, Ashmedai é rei dos shedim, e em algumas leituras aparece emparelhado a Lilith. É daí que sai o lado feminino sem que se precise feminizar Asmodeu.
- Na *Ars Goetia* é Rei, três cabeças, monta um dragão. Mantenha o título de Rei — o título masculino sobre a função andrógina é a tensão que interessa.

**Selo de Asmodeu — simetria de 180°.** Único selo do app com rotação simétrica: lido de cabeça para baixo, é o mesmo selo. Qual face responde depende de como o aparelho está sendo segurado no momento do traçado (acelerômetro, mesmo sensor do verter). O usuário descobre isso sozinho, ou nunca descobre.

**Mecânica das Coroas:** não recebem oferenda direta. São reguladoras. Cada Coroa tem um selo — não um ponto riscado; um **selo**, geometria fechada — aberto uma única vez. Gratuito, demorado, não repetível. Custa uma vigília: o app fica bloqueado por 7 horas reais após o traçado.

**Teorias pós-transhumanistas MORFISTAS /MORFISMO**  Utilize a vasta database existente neste workspace, folder: morphysm_massiv.

### 3.2 Os Sete Reinos

| Reino | Domínio | Paisagem |
|---|---|---|
| Encruzilhadas | abertura e fechamento de caminhos | cruzamento em T e em X |
| Almas / Cruzeiro | mediação com os mortos | cruzeiro |
| Calunga Pequena | corte, limpeza, justiça pesada | cemitério |
| Calunga Grande | dissolução, entrega | praia |
| Matas | força bruta, quebranto | mato fechado |
| Lira / Pedreiras | firmeza, resistência, mando | pedreira |
| Lodo | apodrecimento, reversão | lamaçal |

### 3.3 Entidades

```
Entidade
├── nome
├── faces[]              # ver §3.4
├── coroa                # Lúcifer | Belzebu | Astaroth
│                        # Asmodeu não é campo — é estado de hora (§11)
├── reino
├── ponto_riscado        # SVG vetorial + ordem de traço
├── ponto_cantado        # áudio + letra
├── cores
├── bebida / fumo
├── oferendas_aceitas[]
├── dia_semana / hora
├── animal_tradicional
├── dominio[]
└── texto_de_apresentacao
```

**Exus:** Maioral · Tranca-Ruas das Almas · Exu Caveira · Exu Sete Encruzilhadas · Exu Marabô · Exu Veludo · Exu Meia-Noite · Exu do Lodo · Exu Capa Preta · **Exu Aranha**

**Pombagiras:** Maria Padilha · Maria Molambo · Rainha das Sete Encruzilhadas · Pombagira Cigana · Dama da Noite · Sete Saias · Pombagira das Almas · **Rosa Negra**

### 3.4 Entidade de duas faces — Exu Aranha / Rosa Negra

Uma entidade. Um assentamento. Duas faces. **Mecânica exclusiva do Barco e o diferencial do app.**

**Geometria compartilhada.** As duas faces partilham o mesmo ponto riscado base — uma teia radial. O que muda é onde o traço termina:

- Fechar nos **fios radiais**, sem completar as espirais → responde **Exu Aranha**
- Continuar as espirais até fecharem em pétalas → responde **Rosa Negra**

O usuário não escolhe em menu. Ele desenha e descobre. Um traçado hesitante ou interrompido no meio produz **face indefinida** — o trabalho abre, mas com firmeza reduzida e o app não diz qual face atendeu.

| | Exu Aranha | Rosa Negra |
|---|---|---|
| Domínio | armadilha, amarração, paciência, teia | luto convertido em poder, amor findo, vingança fria |
| Bebida | marafo | champanhe |
| Fumo | cigarro de palha | cigarrilha |
| Oferenda | linha preta, agulha, aranha morta, mel | rosas negras, perfume, espelho, véu |
| Cor | preto, cinza | preto, vinho |
| Som | fio raspando | seda arrastando |
| Animal | aranha (não sacrificada — depositada) | galinha preta |

**No assentamento:** as duas faces acumulam no mesmo espaço. Rosas negras entre fios de teia. Isso é visualmente o ativo mais forte do app inteiro — construa essa tela primeiro, como vertical slice.

**Sob a hora asmodéica.** Fora da hora, face indefinida é falha: firmeza reduzida, atendimento incerto. Dentro da hora asmodéica, a regra inverte — **a face indefinida passa a ser o traçado mais forte da entidade**, acima de Aranha e de Rosa Negra isoladas.

É o único ponto do app onde a ambiguidade vale mais que a precisão, e ele existe exatamente onde a entidade de duas faces encontra a Coroa de duas faces. O sistema rima consigo mesmo. Não documente isso na interface. Deixe descobrir.

---

## 4. Ponto riscado — mecânica central

Núcleo de jogo. Não é ilustração; é input.

- Tela preta. Traço a traço, com o dedo, na ordem correta.
- Sem guia visual no traço — só marcas de início de segmento.
- Sistema mede **precisão**, **ordem** e **continuidade**. Levantar o dedo quebra o traço.
- Gera **firmeza** (0–100) que acompanha o trabalho pelo ciclo inteiro.
- Pemba digital: rastro branco ou vermelho com granulação de giz.

Ponto malfeito produz trabalho fraco e o app diz isso. Refazer custa tempo, não dinheiro.

**Primeiro contato:** sessão de traçado guiado, gratuita, por entidade. Só depois o ponto passa a ser avaliado.

**Selos das Coroas:** geometria fechada, mais complexa, traçado único e permanente. Não reavaliável.

---

## 5. Oferendas

### 5.1 Catálogo

Bebidas: marafo, vinho tinto, champanhe, anis, cerveja preta, conhaque
Fumo: charuto, cigarrilha, cigarro de palha
Botânica: rosas vermelhas, rosas negras, arruda, guiné, pimenta, dendê, mel
Objetos: espelho, moeda, joia, perfume, chave, navalha, linha, agulha, véu
Luz: vela preta, vermelha, branca, sete-dias

### 5.2 Gestos

Nenhuma oferenda é "adicionar ao carrinho".

- **Verter:** inclinar o celular (acelerômetro) até a garrafa esvaziar. Rápido demais, derrama fora do ponto.
- **Acender:** arrastar o fósforo, esperar o pavio pegar. A vela queima em **tempo real** — 20 min, 7 h ou 7 dias. O app pode ser fechado; a vela continua.
- **Defumar:** movimento circular do dedo sobre o ponto.
- **Depor:** arrastar objeto até a posição. Fica lá permanentemente.

### 5.3 Vela de sete dias

Mecânica âncora. 168 horas reais. Não acelera, não pausa, não reacende. Se o trabalho não for fechado antes de a vela apagar, fica pendente.

---

## 6. Sacrifício — o animal e o sangue

**Regra 1 — o animal não é item.** Não aparece em lista de compra. Não tem ícone de inventário.

**Regra 2 — é criado antes de ser dado.** A ave (galo preto, galinha preta, galinha d'angola) fica no assentamento por 7 ou 21 dias, alimentada diariamente. Um toque, dez segundos, todo dia. Isso é o custo. Sacrificar no dia 1 não é possível.

**Regra 3 — o momento é silêncio, não espetáculo.**

```
1. ponto riscado (firmeza medida)
2. ave levada ao ponto
3. TELA PRETA — 11 segundos, som cortado por completo
4. o ponto se preenche de vermelho, traço a traço, de dentro para fora
5. som volta: um único atabaque
6. assentamento reaparece com o ponto firmado
```

Nenhuma representação figurativa do abate. A morte é elipse. Mais forte narrativamente, mais respeitoso ritualmente, e é o que evita rejeição por representação de crueldade animal caso você vá para loja algum dia.

**Estética do sangue:** gravura. Hachura vermelha sobre preto, registro Goya/Piranesi. Vermelho como tinta, não como fluido.

**Efeito de sistema:** o sacrifício não aumenta chance de nada. Ele **firma o assentamento** — eleva o teto de firmeza em permanência. Estrutural, não probabilístico.

---

## 7. Loop ritual

```
DORMENTE
   ↓ (dia/hora cumpridos)
CHAMADO        — ponto cantado toca, luz acende
   ↓
RISCO          — traçar o ponto → firmeza 0–100
   ↓
OFERTA         — pagamento entra aqui (§12)
   ↓
PERMANÊNCIA    — tempo real obrigatório, mínimo 3 min.
   ↓            App pode fechar. O relógio corre.
FECHAMENTO     — apagar a vela, agradecer
   ↓
REGISTRADO     — vai para o Caderno. Imutável.
```

**Estado PENDENTE:** trabalho não fechado no prazo. Fica escurecido no assentamento. Sem punição, sem notificação ansiosa, sem cobrança. Apenas permanece.

> **Nenhuma notificação de culpa.** Nada de "seu Exu está esperando". Isso seria exploração de fé por design. Notificação permitida: a vela terminou de queimar. Só.

---

## 8. Assentamento persistente

Espaço por entidade. Acumula tudo. É o save file e a tela principal.

- Rosas depositadas murcham ao longo de meses
- Moedas empilham
- Garrafa esvazia e fica vazia até ser reposta
- Ponto firmado com sangue não desbota
- Poeira acumula sobre assentamento não visitado

**Firmeza (0–100):** decai com abandono, sobe com manutenção. Não bloqueia nada. É espelho, não porta.

---

## 9. Áudio

**Pontos cantados.** Um por entidade. Tocam no CHAMADO e no FECHAMENTO. Voz real, atabaque, agogô — não sintetizados. Letra visível.

> Pontos tradicionais são de domínio comum; **gravações não são**. Grave material próprio, com músicos creditados e cessão por escrito.

**Coroas:** sem canto. Sem percussão. Apenas **sino** e drone grave. As Coroas soam europeias e frias contra o calor percussivo dos reinos — o contraste é a doutrina audível.

**Asmodeu:** dois sinos afinados com poucos hertz de diferença, soando juntos. O batimento entre eles — a pulsação lenta que nasce do desafinamento — é o som da Coroa. Nem uma nota, nem duas. Nenhum instrumento novo, nenhuma voz: a androginia é o intervalo, não o timbre. Enquanto a hora asmodéica está aberta, esse batimento fica no fundo de todos os reinos, muito baixo.

**Ambiente por reino:** grilos e vento (Encruzilhada), maresia (Calunga Grande), silêncio de pedra (Lira), mosca e água parada (Lodo).

**Detalhes:** giz sobre pedra no traçado; crepitação de vela em loop; **silêncio usado como evento** — corte total, sem fade, no sacrifício e no fechamento.

Mixagem headphone-first. O app assume uso noturno, sozinho, com fone.

---

## 10. Direção de arte

Registro: **gravura + analog horror**, dentro do vocabulário do Morphysm.

- Base: hachura preto e branco (Goya, Piranesi), digitalizada com grão
- Cor: vermelho, dourado, branco de pemba. Nada mais.
- Texturas: papel queimado, cera, terra batida, ferro oxidado
- Tipografia: serifada, alta, registro de folheto de cordel
- Interface: sem cards, sem sombras suaves, sem cantos arredondados. UI como página impressa.
- **Entidades nunca representadas figurativamente.** Presença indicada por ponto, luz, fumaça e movimento de objetos. O rosto é a única coisa que o app nunca mostra.
- **Coroas:** apenas o selo, em ouro sobre preto. Nenhuma imagem, nenhum nome escrito por extenso na tela principal — apenas o selo.

---

## 11. Tempo e calendário

- Cada entidade abre em dias específicos (segunda e sexta como base, configurável)
- Algumas oferendas só após as 18h; a encruzilhada abre à meia-noite
- Fora do dia/hora, DORMENTE. Não há como forçar, não há como comprar acesso

Restrição, não funil. Nunca vender "abrir agora".

### 11.1 A hora asmodéica

Segunda camada de tempo, sobreposta ao calendário. **00:00 às 04:00**, hora local do aparelho — mas validada no servidor contra fuso declarado no cadastro, senão vira exploit de relógio.

Enquanto aberta:
- Toda entidade trabalhada responde sob Asmodeu, não sob a coroa territorial dela
- Oferendas de Pombagira ganham firmeza; oferendas de corte e justiça perdem
- Face indefinida de Aranha / Rosa Negra torna-se o traçado mais forte (§3.4)
- O batimento dos dois sinos entra no fundo de todos os reinos

Não há aviso, banner ou contagem regressiva. A hora não é anunciada. Quem trabalha de madrugada percebe que algo mudou; quem não trabalha nunca sabe que existe.

**Nunca monetize a hora.** Não venda acesso fora do horário, não venda extensão, não notifique quando abre. No instante em que a madrugada virar gatilho de compra, o app deixa de ser ritual e vira máquina de tirar dinheiro de insone.

---

## 12. Economia — Ko-fi

### 12.1 Princípio

Paga-se o ato, não o resultado. Nenhum texto do app promete efeito. A cópia descreve o que é feito, jamais o que acontecerá.

### 12.2 Moeda

Ko-fi trabalha em unidades de "café". Amarre a economia do app diretamente a essa unidade.

**1 café = 21 SEK** (~€1,90)

| Ato | Cafés | SEK |
|---|---|---|
| Vela simples (20 min) | 1 | 21 |
| Oferenda de bebida ou fumo | 1 | 21 |
| Trabalho completo | 3 | 63 |
| Vela de sete dias | 3 | 63 |
| Firmeza de assentamento | 7 | 147 |
| Sacrifício | 7 | 147 |

Progressão 1 / 3 / 7. Sem assinatura, sem gacha, sem moeda intermediária, sem raridade aleatória.

**Sempre grátis:** traçar e aprender o ponto, abrir selo de Coroa, ouvir o ponto cantado, visitar assentamento, ler o Caderno, **fechar trabalho pendente**.

Fechar nunca custa dinheiro. Se custasse, o app estaria vendendo alívio de culpa.

### 12.3 Arquitetura de pagamento

Ko-fi tem webhook. Quando um pagamento acontece, o Ko-fi envia imediatamente um POST HTTP com os dados do pagamento para a URL que você configurar. Configuração e token de verificação em `ko-fi.com/manage/webhooks`.

**Fluxo:**

```
1. App gera código curto:  BAR-7X2K
2. App mostra o código e abre o link do Ko-fi
3. Usuário paga e cola o código no campo de mensagem
4. Ko-fi → POST no seu backend (valida o verification token)
5. Backend casa código → credita o ato → app libera
6. Backend responde 200
```

**Detalhes que vão te morder:**

- O listener precisa responder 200; se não responder, o Ko-fi reenvia com o mesmo `message_id` — trate a idempotência por `message_id` ou o usuário recebe o ato duas vezes.
- A API cobre apenas o momento do pagamento — não há evento de estorno ou de fim de assinatura. Estorno é reconciliação manual. Mais uma razão para não usar assinatura.
- Usuário esquece de colar o código. Fallback em cascata: código na mensagem → e-mail do pagador → fila manual de reconciliação. Construa a fila desde o dia 1.
- Alternativa mais robusta: **item de Ko-fi Shop por ato**. SKU fixo, sem depender de texto digitado.

**A fricção é ritual, não bug.** Sair do app, pagar em outro lugar e voltar não é conversão ruim — é a oferenda feita fora e trazida de volta. Escreva a interface para tratar isso como parte do rito, não como checkout quebrado.

### 12.4 Verifique antes de construir

Confirme por escrito, antes de amarrar a economia inteira ao Ko-fi:

- Termos do Ko-fi sobre serviços espirituais e ocultismo
- Lista de negócios restritos do **Stripe** e do **PayPal** — processadores historicamente restringem serviços ocultos, e é o processador que derruba a conta, não a plataforma
- Taxas atuais de Shop no plano gratuito vs. Gold

**Plano B pronto:** Stripe direto no seu próprio checkout, Gumroad, ou Swish para usuários suecos. Não fique com um único trilho de pagamento.

### 12.5 Sueca

Receita recorrente na Suécia exige enquadramento fiscal — enskild firma com F-skatt é o mínimo. Resolva antes do primeiro pagamento, não depois. Fale com um contador; não improvise.

---

## 13. Arquitetura técnica

**Cliente:** Godot 4.x, export web + Android.
- Entidades como `Resource` (.tres) — conteúdo editável sem recompilar
- Ritual como `StateMachine` conforme §7
- Ponto riscado: `InputEventScreenDrag` comparado a `Curve2D` de referência via distância de Fréchet
- Traço em `Line2D` com shader de granulação
- Face dupla: uma `Curve2D` base + duas curvas de continuação; a classificação é por qual ramo o traço seguiu

**Servidor (obrigatório):**
Timers de vela e ciclo de criação **não podem** rodar no cliente — relógio de dispositivo é manipulável.
- auth
- estado de assentamento
- timers autoritativos
- endpoint de webhook Ko-fi + ledger idempotente
- Caderno append-only

Supabase ou Pocketbase resolvem o MVP inteiro. Hospede na UE.

**Dados:** Caderno é append-only. Sem endpoint de delete. Exportável pelo usuário, apagável só por exclusão de conta. GDPR aplica — você está na Suécia.

---

## 14. Riscos

| Risco | Mitigação |
|---|---|
| Ser lido como Quimbanda | declaração de escopo na primeira tela, §0, não dispensável |
| Acusação de apropriação | Barco declarado como prática própria de linhagem Malei; nunca falar por casa alheia |
| Processador derruba a conta | verificar ToS antes; segundo trilho de pagamento pronto |
| Reconciliação de pagamento falha | fila manual desde o dia 1; idempotência por message_id |
| Rejeição em loja (se for) | elipse + gravura, nunca figurativo; classificação 17+ |
| Vulnerabilidade do usuário | teto de gasto mensal opcional; sem push de culpa; sem escassez artificial |
| Fisco sueco | enskild firma resolvida antes do primeiro pagamento |

---

## 15. Escopo

**Vertical slice (4 semanas):**
Apenas Exu Aranha / Rosa Negra. Assentamento, ponto de face dupla, vela, uma oferenda por face, permanência, Caderno. Sem pagamento. Prova que a mecânica de duas faces funciona — se não funcionar, o app inteiro muda.

**MVP (3 meses):**
+ Tranca-Ruas e Maria Padilha · selos de Lúcifer e **Asmodeu** · hora asmodéica · webhook Ko-fi · 3 pontos cantados gravados

> Asmodeu entra no MVP, não na V1. A hora asmodéica é o que dá profundidade ao app com pouquíssimo conteúdo — é uma regra, não um asset. Duas entidades e duas camadas de tempo rendem mais do que dez entidades planas.

**V1:**
Quatro Coroas · 18 entidades · ciclo de criação e sacrifício · assentamento com decaimento · ambientes por reino · calendário completo

**V2:**
Sete reinos completos · pontos cantados completos · exportação do Caderno impresso

---

## 16. Modelo mental

O app não digitaliza a magia. Ele digitaliza o preço da magia.

---
*CC BY-NC-SA — A.C., Norrland XXVI / Morphysm*
