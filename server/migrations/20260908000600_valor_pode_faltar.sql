-- O valor e a moeda passam a poder faltar.
--
-- Nenhum dos dois decide nada: o acto vem do codigo ou do SKU, e ja esta
-- escrito no §10.4 que o valor NAO desempata entre actos do mesmo preco.
-- Sao registo.
--
-- Estavam `not null`, e o parser rebentava quando nao os percebia. Isso
-- fazia um campo sem poder nenhum bloquear um pagamento inteiro: resposta
-- 500, o Ko-fi a reenviar para sempre, e um pagamento perfeitamente
-- creditavel — por codigo, que nem sequer olha para o valor — a nunca ser
-- creditado, sem nada no ecra a dizer porque.
--
-- O payload inteiro fica em `raw`, portanto o valor nunca se perde de
-- facto: perde-se a coluna, nao o dado.
alter table public.pagamentos alter column amount   drop not null;
alter table public.pagamentos alter column currency drop not null;
