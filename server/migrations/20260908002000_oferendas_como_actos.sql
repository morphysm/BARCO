-- Cada oferenda e o seu proprio acto.
--
-- A `atos` tinha so os actos genericos do §10.1 — `oferenda_simples`,
-- `sacrificio`. Mas o codigo que a pessoa cola no Ko-fi nomeia UM acto, e
-- com um acto generico quem pagasse uma pimenta ficava com credito para
-- depor umas rosas negras. Nao e o mesmo acto: sao oferendas diferentes,
-- com significados diferentes, e o app nao tem porque as trocar.
--
-- Os precos sao os mesmos dos `.tres` do cliente, e continuam a ser ESTES
-- que mandam: o cliente mostra-os na tela, o servidor decide com eles.
-- `tools/verificar_precos.py` confere que os dois lados nao derivaram.
--
-- Os actos genericos ficam. Nao ha nada a apontar para eles ainda, mas o
-- §10.1 e o contrato e nao se apaga metade dele por conveniencia.
insert into public.atos (slug, cafes) values
    ('charuto',       1),
    ('cigarro',       1),
    ('marafo',        1),
    ('navalha',       1),
    ('pimenta',       1),
    ('rosas_negras',  1),
    ('vela_branca',   1),
    ('vela_preta',    1),
    ('vela_vermelha', 1),
    -- Sete cafes, o escalao do `sacrificio` (§10.1). E a mais cara da
    -- lista e e a unica que nao se pousa: atira-se.
    ('sangue',        7)
on conflict (slug) do nothing;
