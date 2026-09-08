-- Quem ve o que. SPEC.md §3.3, AGENTS.md.
--
-- O principio: as tabelas de dinheiro nao se leem do cliente. O que a
-- pessoa precisa de ver e o que comprou e o que ainda tem por gastar;
-- tudo o resto — o que o Ko-fi mandou, a fila manual, os pagamentos de
-- outra gente — nao lhe diz respeito e nao lhe chega.
--
-- RLS ligado SEM politica nenhuma nao e um esquecimento: e negar tudo. As
-- Edge Functions passam por cima disto com a chave de admin
-- (`SUPABASE_SECRET_KEYS['default']`), que e a unica que credita.

alter table public.atos           enable row level security;
alter table public.codigos        enable row level security;
alter table public.pagamentos     enable row level security;
alter table public.creditos       enable row level security;
alter table public.reconciliacao  enable row level security;

-- Os precos sao publicos: sao os numeros que estao nos botoes.
create policy "os precos leem-se" on public.atos
    for select to authenticated, anon
    using (true);

-- O codigo e de quem o pediu. Ve o seu, cria o seu, e mais nada — nao o
-- altera nem o apaga, que quem o marca como usado e o webhook.
create policy "o codigo e de quem o pediu" on public.codigos
    for select to authenticated
    using (auth.uid() = user_id);

create policy "pedir um codigo" on public.codigos
    for insert to authenticated
    with check (auth.uid() = user_id);

-- O que comprei, vejo. Escrever creditos e so do webhook.
create policy "os creditos sao de quem os comprou" on public.creditos
    for select to authenticated
    using (auth.uid() = user_id);

-- `pagamentos` e `reconciliacao` ficam SEM politica de proposito.
--
-- O `raw` guarda o payload do Ko-fi inteiro, que traz o email do pagador
-- e o que ele escreveu na mensagem. Isso nao se serve ao cliente, nem
-- sequer ao dono do pagamento: quem precisa dele e o webhook e quem
-- resolve a fila a mao, os dois com a chave de admin.
