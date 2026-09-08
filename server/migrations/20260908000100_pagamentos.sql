-- O dinheiro. SPEC.md §3.3 e §10.
--
-- Quatro tabelas e uma regra: o servidor nunca acredita no cliente sobre
-- precos nem sobre o que foi pago. O cliente pede um codigo, mostra-o, e
-- espera; quem credita e o webhook, com a chave de admin.
--
-- Nenhuma destas tabelas tem `delete`. Um pagamento aconteceu ou nao
-- aconteceu, e um credito gasto fica gasto (AGENTS.md, Irreversibilidade).

-- Os actos que se podem comprar, com o preco em cafes.
--
-- Vive no servidor e nao no cliente porque e o servidor que tem de
-- decidir se o que entrou paga o que se pediu. Os `.tres` do cliente
-- dizem o mesmo, mas sao para mostrar na tela — nao sao autoridade.
create table public.atos (
    slug        text primary key,
    cafes       integer not null check (cafes > 0),
    -- O SKU do artigo na loja do Ko-fi, quando existir. E o degrau mais
    -- robusto da cascata do §10.4: nao depende de ninguem escrever nada.
    kofi_sku    text unique
);

comment on table public.atos is
    'Precos em cafes. 1 cafe = 2 USD (SPEC.md §10.1). O cliente mostra, o servidor decide.';

insert into public.atos (slug, cafes) values
    ('vela_20min',            1),
    ('oferenda_simples',      1),
    ('trabalho_completo',     3),
    ('vela_sete_dias',        3),
    ('assentamento_firmeza',  7),
    ('sacrificio',            7);

-- O codigo que a pessoa cola na mensagem do Ko-fi: BAR-7X2K.
--
-- E o que liga um pagamento anonimo a uma pessoa e a um acto. Sem ele so
-- resta o email do pagador, e a seguir a fila manual.
create table public.codigos (
    codigo      text primary key,
    user_id     uuid not null references auth.users (id) on delete cascade,
    ato_slug    text not null references public.atos (slug),
    created_at  timestamptz not null default now(),
    -- Um codigo serve uma vez. Depois de casado com um pagamento fica
    -- gasto, senao o mesmo codigo colado em duas doacoes creditava duas.
    usado_em    timestamptz
);

create index codigos_por_pessoa on public.codigos (user_id, created_at desc);

-- O que o Ko-fi mandou, tal e qual, mais o que se conseguiu concluir.
--
-- `kofi_message_id` e UNIQUE, e e ESSA a garantia de idempotencia — nao
-- uma verificacao no codigo (SPEC.md §3.3). O Ko-fi reenvia com o mesmo
-- id ate receber 200; sem esta restricao, um reenvio creditava outra vez.
create table public.pagamentos (
    id                uuid primary key default gen_random_uuid(),
    -- Nulo enquanto nao se souber de quem e. Um pagamento sem dono e um
    -- pagamento por reconciliar, nao um pagamento invalido.
    user_id           uuid references auth.users (id) on delete set null,
    kofi_message_id   text not null unique,
    amount            numeric(12, 2) not null,
    currency          text not null,
    raw               jsonb not null,
    -- Por onde e que se soube: 'sku', 'codigo', 'email', 'manual'.
    matched_by        text check (matched_by in ('sku', 'codigo', 'email', 'manual')),
    created_at        timestamptz not null default now()
);

create index pagamentos_por_pessoa on public.pagamentos (user_id, created_at desc);

-- O que a pessoa comprou e ainda nao gastou.
create table public.creditos (
    id                 uuid primary key default gen_random_uuid(),
    user_id            uuid not null references auth.users (id) on delete cascade,
    ato_slug           text not null references public.atos (slug),
    source_payment_id  uuid not null references public.pagamentos (id),
    created_at         timestamptz not null default now(),
    -- Nulo = por gastar. Escrito uma vez, nunca limpo.
    spent_at           timestamptz
);

create index creditos_por_gastar on public.creditos (user_id, ato_slug)
    where spent_at is null;

-- A fila manual do §10.4. E funcionalidade, nao um TODO: um pagamento que
-- nao se conseguiu casar fica aqui a espera de uma pessoa, e NUNCA e
-- creditado por adivinhacao.
create table public.reconciliacao (
    id               uuid primary key default gen_random_uuid(),
    kofi_message_id  text not null unique references public.pagamentos (kofi_message_id),
    raw              jsonb not null,
    resolved_by      uuid references auth.users (id),
    resolved_at      timestamptz
);

create index reconciliacao_por_resolver on public.reconciliacao (id)
    where resolved_at is null;
