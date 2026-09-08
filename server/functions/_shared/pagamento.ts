// O dinheiro, sem saber de onde veio. SPEC.md §10.5.
//
// Nada aqui menciona Ko-fi, e e de proposito: os processadores de
// pagamento fecham contas a servicos espirituais, e quem fecha a conta e
// o processador, nao a plataforma. Quando isso acontecer, entra outro no
// lugar dele — Stripe, Gumroad, Swish — e o que se escreve e um tradutor
// novo para este mesmo tipo. O resto do sistema nao da por nada.

/// Um pagamento que entrou, ja traduzido do que quer que o tenha trazido.
export interface Pagamento {
    /// Quem o trouxe: "kofi". So serve para o registo e para depurar.
    readonly origem: string;
    /// O identificador unico DO LADO DE LA. E nele que assenta a
    /// idempotencia — no Ko-fi e o `message_id`.
    readonly id_externo: string;
    /// Registam-se, nunca decidem nada — o acto vem do codigo ou do SKU,
    /// nunca do valor (ver `cascata.ts`). Por isso podem faltar sem que
    /// isso impeca creditar.
    readonly valor: number | null;
    readonly moeda: string | null;
    /// O email de quem pagou, se vier. Diz QUEM, nunca O QUE.
    readonly email: string | null;
    /// O que a pessoa escreveu. E aqui que o codigo BAR-XXXX aparece.
    readonly mensagem: string | null;
    /// O SKU do artigo comprado, se foi compra de loja. Diz O QUE, nunca
    /// QUEM.
    readonly sku: string | null;
    /// O payload inteiro como chegou, para o registo e para a fila manual.
    readonly cru: unknown;
}

/// O que se conseguiu concluir sobre um pagamento.
///
/// Note-se que sao DUAS perguntas independentes, e nao uma: de quem e, e
/// o que paga. Um SKU diz o acto e nao diz a pessoa; um email diz a
/// pessoa e nao diz o acto. So se creditam pagamentos em que as duas
/// respostas existem.
export interface Casamento {
    readonly user_id: string | null;
    /// O acto, quando se soube por SKU. Com codigo fica nulo: quem
    /// resolve o que o codigo compra e o cesto, no servidor.
    readonly ato_slug: string | null;
    /// Por onde se soube. `null` quando nao se soube de nada.
    readonly por: "codigo" | "sku" | "email" | "sku+email" | null;
    /// O codigo usado, para o marcar como gasto.
    readonly codigo: string | null;
}

/// O que a cascata precisa de perguntar ao registo.
///
/// E uma interface e nao o cliente do Supabase para isto se poder provar
/// sem base de dados nenhuma.
export interface Registo {
    /// Que acto e que este SKU da loja paga.
    atoPorSku(sku: string): Promise<string | null>;
    /// Um codigo por gastar. Devolve `null` se nao existe ou ja foi usado.
    ///
    /// So devolve DE QUEM e. O que o codigo compra esta no cesto
    /// (`codigo_itens`) e quem o le e a transacao, no servidor: um cesto
    /// lido aqui e conferido la seria a mesma conta feita duas vezes, e
    /// duas contas iguais acabam sempre por deixar de ser iguais.
    codigoPorGastar(codigo: string): Promise<{ user_id: string } | null>;
    /// Que pessoa tem este email.
    pessoaPorEmail(email: string): Promise<string | null>;
}
