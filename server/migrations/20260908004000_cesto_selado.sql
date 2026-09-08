-- O cesto sela-se quando o codigo nasce.
--
-- FALHA ENCONTRADA. A `codigo_itens` foi criada sem RLS. O ficheiro de
-- politicas so cobre as cinco tabelas originais, e uma tabela nova nao
-- herda nada: sem RLS as permissoes vem dos GRANTs que o Supabase da a
-- `anon` e a `authenticated`, e a chave publica — que vai dentro do app —
-- escrevia nela.
--
-- O que isso abria: a janela entre emitir o codigo e o pagamento chegar.
-- Nessa janela o cesto podia mudar. Apagar os itens do codigo de outra
-- pessoa punha o custo a zero e fazia o pagamento dela cair na fila; e o
-- cesto que o webhook lia deixava de ser o cesto que foi comprado.
--
-- (A conferencia de valor limitava o estrago — um cesto inchado passava a
-- custar mais do que o que foi pago e era recusado — mas limitar nao e
-- fechar.)
--
-- O FECHO nao e so ligar o RLS. E tirar ao cliente qualquer escrita nestas
-- duas tabelas e dar-lhe UMA porta: `pedir_codigo`, que cria o codigo, os
-- itens e o total numa transacao so. Depois disso nao ha por onde
-- alterar o cesto — nem o proprio, nem o de outrem. Um cesto que se pode
-- editar depois de emitido nao e uma encomenda, e uma intencao.

-- O total, congelado no momento da emissao.
--
-- Nao se recalcula a partir da `atos` quando o pagamento chega: entre
-- emitir e pagar, um preco pode mudar, e a conta a pagar tem de ser a que
-- foi mostrada a pessoa. Uma encomenda guarda o seu preco.
alter table public.codigos add column cafes_total integer;

alter table public.codigo_itens enable row level security;

-- Ve-se o proprio cesto. Escrever, ninguem: nem o dono.
create policy "o cesto e de quem o pediu" on public.codigo_itens
    for select to authenticated
    using (exists (
        select 1 from public.codigos c
         where c.codigo = codigo_itens.codigo and c.user_id = auth.uid()));

-- O cliente deixa de poder criar codigos a mao. A unica porta e a funcao.
drop policy if exists "pedir um codigo" on public.codigos;

-- Emite um codigo com o seu cesto, tudo de uma vez.
--
-- `security definer` para poder escrever em tabelas que o cliente nao
-- alcanca. O que ela aceita e uma lista de itens; o resto — o codigo, o
-- dono, o total — decide-o ela. O cliente nao escolhe o codigo (seria
-- escolher o de outra pessoa) nem diz quanto custa (seria dizer o preco
-- a quem cobra).
create function public.pedir_codigo(p_itens jsonb)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
    v_user   uuid := auth.uid();
    v_codigo text;
    v_total  integer;
    v_itens  integer;
    v_letras text := '0123456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    v_i      integer;
begin
    if v_user is null then
        raise exception 'sem sessao';
    end if;
    if p_itens is null or jsonb_array_length(p_itens) = 0 then
        raise exception 'cesto vazio';
    end if;
    if jsonb_array_length(p_itens) > 20 then
        raise exception 'cesto grande de mais';
    end if;

    -- Um codigo por tentativa, ate um livre. O feitio e BAR-XXXX, sem
    -- I nem O nem 1: sao os que se leem mal quando alguem os copia a mao
    -- do ecra para o Ko-fi.
    for _ in 1..12 loop
        v_codigo := 'BAR-';
        for v_i in 1..4 loop
            v_codigo := v_codigo || substr(v_letras, 1 + floor(random() * 34)::int, 1);
        end loop;
        exit when not exists (select 1 from public.codigos where codigo = v_codigo);
        v_codigo := null;
    end loop;
    if v_codigo is null then
        raise exception 'nao se arranjou codigo livre';
    end if;

    insert into public.codigos (codigo, user_id) values (v_codigo, v_user);

    insert into public.codigo_itens (codigo, ato_slug, quantidade)
    select v_codigo,
           i->>'ato_slug',
           greatest(1, least(99, coalesce((i->>'quantidade')::int, 1)))
      from jsonb_array_elements(p_itens) i
     where exists (select 1 from public.atos a where a.slug = i->>'ato_slug')
    on conflict (codigo, ato_slug) do update
       set quantidade = public.codigo_itens.quantidade + excluded.quantidade;

    select count(*), coalesce(sum(a.cafes * ci.quantidade), 0)
      into v_itens, v_total
      from public.codigo_itens ci
      join public.atos a on a.slug = ci.ato_slug
     where ci.codigo = v_codigo;

    if v_itens = 0 then
        raise exception 'nenhum item do cesto existe';
    end if;

    update public.codigos set cafes_total = v_total where codigo = v_codigo;
    return v_codigo;
end;
$$;

revoke execute on function public.pedir_codigo(jsonb) from public;
grant execute on function public.pedir_codigo(jsonb) to authenticated;
