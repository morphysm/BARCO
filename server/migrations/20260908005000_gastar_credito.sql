-- Gastar um credito.
--
-- Tem de ser o servidor: o cliente nao tem — e nao pode ter — politica de
-- escrita sobre `creditos`. Se pudesse marcar um credito como gasto,
-- podia marca-lo como POR gastar, e um credito que se desgasta sozinho
-- deixa de ser um credito.
--
-- Gasta UM, o mais antigo primeiro, e devolve se conseguiu. O
-- `spent_at is null` dentro do proprio `update` faz o teste e a marca
-- numa operacao so — o mesmo padrao do `codigos.usado_em` e do
-- `pagamentos.creditado_em`, que ja estao provados. Dois cliques ao mesmo
-- tempo nao gastam o mesmo credito duas vezes.
--
-- `for update skip locked` para o caso de dois pedidos simultaneos: o
-- segundo passa ao credito seguinte em vez de esperar pelo primeiro.
create function public.gastar_credito(p_ato_slug text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
    v_id   uuid;
    v_user uuid := auth.uid();
begin
    if v_user is null then
        return false;
    end if;

    select id into v_id
      from public.creditos
     where user_id = v_user
       and ato_slug = p_ato_slug
       and spent_at is null
     order by created_at
     limit 1
       for update skip locked;

    if v_id is null then
        return false;
    end if;

    update public.creditos
       set spent_at = now()
     where id = v_id
       and spent_at is null;

    return found;
end;
$$;

revoke execute on function public.gastar_credito(text) from public;
grant execute on function public.gastar_credito(text) to authenticated;
