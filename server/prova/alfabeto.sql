-- O alfabeto de que o `pedir_codigo` escolhe, provado e nao suposto.
--
-- Isto existe por causa de um acordo entre dois ficheiros que nao se
-- conhecem:
--
--   `cesto_selado.sql`     emite codigos de 34 letras, sem I e sem O
--   `_shared/cascata.ts`   le um I escrito como sendo um 1, e um O como 0
--
-- O segundo so esta certo enquanto o primeiro for verdade. Se alguem
-- puser o `I` de volta no `v_letras`, os dois passam a discordar em
-- silencio: um codigo emitido com `I` chega pelo Ko-fi, a cascata
-- troca-lhe o `I` por `1`, a procura falha, e o pagamento cai na fila
-- manual sem que ninguem perceba porque. Dinheiro entrado, acto por
-- entregar, e nenhuma mensagem de erro em lado nenhum.
--
-- Um comentario nao trava isso. Esta prova trava.
\set ON_ERROR_STOP on

\set QUEM '00000000-0000-0000-0000-0000000000a1'

insert into auth.users (id) values (:'QUEM') on conflict do nothing;
select set_config('request.jwt.claims', '{"sub":"' || :'QUEM' || '"}', false);
set role authenticated;

\echo ''
\echo '== o alfabeto do codigo =='

do $$
declare
    v_codigo text;
    v_vistas text := '';
    v_maus   text := '';
begin
    -- 400 codigos: com 34 letras e quatro casas chega de sobra para ver
    -- cada letra aparecer e para apanhar uma intrusa.
    for _ in 1..400 loop
        v_codigo := public.pedir_codigo(
            '[{"ato_slug": "pimenta", "quantidade": 1}]'::jsonb);
        if v_codigo !~ '^BAR-[0-9A-Z]{4}$' then
            raise exception 'FALHOU: feitio inesperado: %', v_codigo;
        end if;
        v_vistas := v_vistas || substr(v_codigo, 5);
    end loop;

    if v_vistas ~ 'I' then v_maus := v_maus || 'I '; end if;
    if v_vistas ~ 'O' then v_maus := v_maus || 'O '; end if;
    if v_maus <> '' then
        raise exception
            'FALHOU: o gerador emitiu %— a cascata.ts troca-a(s) e deixa '
            'de encontrar o codigo. Ver _shared/cascata.ts, CONFUSOES.',
            v_maus;
    end if;

    raise notice 'ok: 400 codigos, % letras distintas, nenhum I nem O',
        (select count(distinct c) from regexp_split_to_table(v_vistas, '') c);
end $$;

\echo ''
\echo '== a porta, sem sessao =='

select set_config('request.jwt.claims', '{}', false);

do $$
declare
    v_codigo text;
begin
    v_codigo := public.pedir_codigo(
        '[{"ato_slug": "pimenta", "quantidade": 1}]'::jsonb);
    raise exception 'FALHOU: emitiu % sem sessao', v_codigo;
exception
    when sqlstate 'P0001' then
        if sqlerrm <> 'sem sessao' then
            raise;
        end if;
        raise notice 'ok: sem sessao nao se emite codigo';
end $$;

reset role;
