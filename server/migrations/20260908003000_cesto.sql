-- Um pagamento pode comprar varios actos.
--
-- Comprar uma oferenda de 2 USD de cada vez pelo Ko-fi — colar o codigo,
-- pagar, esperar pelo webhook, voltar — quatro vezes numa sessao nao se
-- pede a ninguem. Entao um codigo passa a nomear um CESTO.
--
-- O que isto NAO e: uma moeda intermedia. O `AGENTS.md` proibe-a pelo
-- nome, e com razao. A diferenca esta na ordem: escolhe-se ANTES de
-- pagar, e paga-se exactamente o que se escolheu, portanto nao ha troco.
-- Um saldo residual seria moeda; um cesto fechado nao e. E os creditos
-- que saem daqui sao NOMEADOS — tres pimentas e um marafo — e nao um
-- numero que serve para tudo.
--
-- A tira do `assentamento` continua a nao ser um carrinho (GDD §2, pilar
-- 3): compra-se aqui, depoe-se la, um gesto de cada vez.

create table public.codigo_itens (
    codigo      text not null references public.codigos (codigo) on delete cascade,
    ato_slug    text not null references public.atos (slug),
    quantidade  integer not null check (quantidade > 0),
    primary key (codigo, ato_slug)
);

comment on table public.codigo_itens is
    'O cesto de um codigo. Um pagamento, varios actos nomeados.';

-- O acto sai do cabecalho e passa para os itens. A `codigos` esta vazia,
-- portanto nao ha nada a migrar.
alter table public.codigos drop column ato_slug;

-- A GARANTIA MUDA DE SITIO, e isto e o cerne desta migracao.
--
-- Havia `creditos_um_por_pagamento`: UNIQUE em `source_payment_id`, um
-- credito por pagamento. Com um cesto isso deixa de poder ser — quatro
-- oferendas num pagamento sao quatro creditos.
--
-- Mas o que essa restricao protegia continua a ter de ser protegido: que
-- um pagamento nao seja creditado DUAS vezes, sobretudo pela vista da
-- fila manual, que ainda nao existe e que alguem vai escrever a fazer o
-- obvio. Entao a garantia passa a ser sobre o PAGAMENTO e nao sobre a
-- contagem de creditos: um pagamento credita-se uma vez.
--
-- E o mesmo teste-e-marca atomico do `codigos.usado_em`, que ja esta
-- provado: o `where ... and creditado_em is null` faz as duas coisas numa
-- operacao so, e a segunda tentativa nao encontra linha.
alter table public.creditos drop constraint creditos_um_por_pagamento;
alter table public.pagamentos add column creditado_em timestamptz;

comment on column public.pagamentos.creditado_em is
    'Marcado quando os creditos deste pagamento foram escritos. Escrito uma vez; e ele que impede creditar duas.';
