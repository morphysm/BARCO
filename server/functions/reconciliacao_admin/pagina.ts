export const PAGINA = String.raw`<!doctype html>
<html lang="pt">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="robots" content="noindex,nofollow">
  <title>Barco — reconciliacao</title>
  <style>
    :root { color-scheme: dark; font-family: ui-monospace, monospace; }
    * { box-sizing: border-box; }
    body { margin: 0; background: #080808; color: #eee9de; }
    main { width: min(940px, calc(100% - 32px)); margin: 36px auto 80px; }
    h1 { font-size: 24px; font-weight: 500; letter-spacing: .08em; }
    h2 { font-size: 18px; font-weight: 500; margin: 0 0 18px; }
    section, article { border: 1px solid #57534b; padding: 20px; margin: 18px 0; }
    .linha { display: flex; gap: 10px; align-items: end; flex-wrap: wrap; }
    label { display: grid; gap: 6px; flex: 1 1 220px; }
    input, select, button { font: inherit; color: inherit; background: #111; border: 1px solid #777066; padding: 10px; }
    button { cursor: pointer; }
    button:disabled { cursor: default; opacity: .35; }
    .estado { min-height: 22px; color: #c7bfae; }
    .erro { color: #e27676; }
    .certo { color: #91bd91; }
    .miudo { color: #aaa397; font-size: 13px; overflow-wrap: anywhere; }
    pre { white-space: pre-wrap; overflow-wrap: anywhere; padding: 12px; background: #10100f; border-left: 2px solid #57534b; }
    .itens { margin: 12px 0; padding: 0; list-style: none; }
    .itens li { display: flex; justify-content: space-between; gap: 12px; border-bottom: 1px solid #302e2a; padding: 7px 0; }
    .confirmar { display: flex; align-items: center; gap: 10px; margin: 16px 0; }
    .confirmar input { width: auto; }
    [hidden] { display: none !important; }
  </style>
</head>
<body>
<main>
  <h1>BARCO / RECONCILIACAO</h1>
  <section id="entrada">
    <h2>entrada de administracao</h2>
    <div class="linha">
      <label>email <input id="email" type="email" autocomplete="email"></label>
      <button id="enviar">enviar codigo</button>
    </div>
    <div class="linha" id="linha-codigo" hidden>
      <label>codigo recebido <input id="codigo" inputmode="numeric" autocomplete="one-time-code"></label>
      <button id="confirmar-codigo">entrar</button>
    </div>
    <p class="estado" id="estado-entrada"></p>
  </section>
  <section id="painel" hidden>
    <div class="linha">
      <h2>pagamentos por reconciliar</h2>
      <button id="recarregar">recarregar</button>
      <button id="sair">sair</button>
    </div>
    <p class="estado" id="estado-painel"></p>
    <div id="fila"></div>
  </section>
</main>
<script>
(function () {
  'use strict';
  var SUPABASE_URL = __SUPABASE_URL__;
  var CHAVE_PUBLICA = __SUPABASE_ANON_KEY__;
  var ADMIN_URL = __ADMIN_URL__;
  var token = sessionStorage.getItem('barco_admin_token') || '';
  var atos = [];
  var porSlug = new Map();
  var email = document.getElementById('email');
  var codigo = document.getElementById('codigo');
  var estadoEntrada = document.getElementById('estado-entrada');
  var estadoPainel = document.getElementById('estado-painel');
  var entrada = document.getElementById('entrada');
  var painel = document.getElementById('painel');
  var fila = document.getElementById('fila');

  function estado(no, mensagem, classe) {
    no.textContent = mensagem || '';
    no.className = 'estado' + (classe ? ' ' + classe : '');
  }

  async function auth(caminho, corpo) {
    var resposta = await fetch(SUPABASE_URL + caminho, {
      method: 'POST',
      headers: { 'apikey': CHAVE_PUBLICA, 'content-type': 'application/json' },
      body: JSON.stringify(corpo)
    });
    var dados = await resposta.json().catch(function () { return {}; });
    if (!resposta.ok) throw new Error(dados.msg || dados.error_description || 'nao foi possivel confirmar');
    return dados;
  }

  async function api(corpo) {
    var resposta = await fetch(ADMIN_URL, {
      method: 'POST',
      headers: { 'authorization': 'Bearer ' + token, 'content-type': 'application/json' },
      body: JSON.stringify(corpo)
    });
    var dados = await resposta.json().catch(function () { return {}; });
    if (!resposta.ok) {
      if (resposta.status === 401) sair();
      throw new Error(dados.erro || 'pedido recusado');
    }
    return dados;
  }

  document.getElementById('enviar').onclick = async function () {
    estado(estadoEntrada, 'a enviar...');
    try {
      await auth('/auth/v1/otp', { email: email.value.trim().toLowerCase(), create_user: false });
      document.getElementById('linha-codigo').hidden = false;
      estado(estadoEntrada, 'codigo enviado');
      codigo.focus();
    } catch (e) { estado(estadoEntrada, e.message, 'erro'); }
  };

  document.getElementById('confirmar-codigo').onclick = async function () {
    estado(estadoEntrada, 'a confirmar...');
    try {
      var sessao = await auth('/auth/v1/verify', {
        email: email.value.trim().toLowerCase(), token: codigo.value.trim(), type: 'email'
      });
      token = sessao.access_token || '';
      if (!token) throw new Error('a resposta nao trouxe uma sessao');
      sessionStorage.setItem('barco_admin_token', token);
      await carregar();
    } catch (e) { estado(estadoEntrada, e.message, 'erro'); }
  };

  document.getElementById('recarregar').onclick = carregar;
  document.getElementById('sair').onclick = sair;

  function sair() {
    token = '';
    sessionStorage.removeItem('barco_admin_token');
    painel.hidden = true;
    entrada.hidden = false;
  }

  function texto(tag, conteudo, classe) {
    var no = document.createElement(tag);
    no.textContent = conteudo == null ? '' : String(conteudo);
    if (classe) no.className = classe;
    return no;
  }

  function botao(nome, accao) {
    var no = document.createElement('button');
    no.type = 'button';
    no.textContent = nome;
    no.onclick = accao;
    return no;
  }

  async function carregar() {
    estado(estadoPainel, 'a ler...');
    try {
      var dados = await api({ acao: 'listar' });
      atos = dados.atos || [];
      porSlug = new Map(atos.map(function (a) { return [a.slug, a]; }));
      fila.replaceChildren();
      (dados.fila || []).forEach(montarPagamento);
      entrada.hidden = true;
      painel.hidden = false;
      estado(estadoPainel, dados.fila.length ? '' : 'a fila esta vazia', 'certo');
    } catch (e) { estado(estadoPainel, e.message, 'erro'); }
  }

  function montarPagamento(pagamento) {
    var artigo = document.createElement('article');
    artigo.appendChild(texto('h2', String(pagamento.amount) + ' ' + String(pagamento.currency || '—') + ' / ' + String(pagamento.raw.type || 'tipo desconhecido')));
    artigo.appendChild(texto('p', pagamento.created_at || '', 'miudo'));
    artigo.appendChild(texto('p', 'message_id: ' + pagamento.kofi_message_id, 'miudo'));
    var bruto = document.createElement('pre');
    bruto.textContent = JSON.stringify(pagamento.raw, null, 2);
    artigo.appendChild(bruto);

    var pessoa = '';
    var itens = new Map();
    var linhaPessoa = document.createElement('div');
    linhaPessoa.className = 'linha';
    var labelEmail = document.createElement('label');
    labelEmail.append('email exacto da conta');
    var emailPessoa = document.createElement('input');
    emailPessoa.type = 'email';
    emailPessoa.value = pagamento.raw.email || '';
    labelEmail.appendChild(emailPessoa);
    var resultadoPessoa = texto('span', '', 'miudo');
    linhaPessoa.append(labelEmail, botao('procurar conta', async function () {
      pessoa = '';
      resultadoPessoa.textContent = 'a procurar...';
      try {
        var r = await api({ acao: 'procurar_pessoa', email: emailPessoa.value });
        pessoa = r.user_id || '';
        resultadoPessoa.textContent = pessoa ? pessoa : 'nenhuma conta com este email';
        actualizar();
      } catch (e) { resultadoPessoa.textContent = e.message; }
    }), resultadoPessoa);
    artigo.appendChild(linhaPessoa);

    var linhaActo = document.createElement('div');
    linhaActo.className = 'linha';
    var selector = document.createElement('select');
    atos.forEach(function (a) {
      var opcao = document.createElement('option');
      opcao.value = a.slug;
      opcao.textContent = a.slug + ' — ' + String(Number(a.cafes) * 2) + ' USD';
      selector.appendChild(opcao);
    });
    var quantidade = document.createElement('input');
    quantidade.type = 'number'; quantidade.min = '1'; quantidade.max = '99'; quantidade.value = '1';
    linhaActo.append(selector, quantidade, botao('juntar acto', function () {
      var n = Math.max(1, Math.min(99, Number(quantidade.value) || 1));
      itens.set(selector.value, (itens.get(selector.value) || 0) + n);
      actualizar();
    }));
    artigo.appendChild(linhaActo);

    var lista = document.createElement('ul');
    lista.className = 'itens';
    artigo.appendChild(lista);
    var total = texto('p', 'total escolhido: 0 USD');
    artigo.appendChild(total);
    var confirma = document.createElement('label');
    confirma.className = 'confirmar';
    var caixa = document.createElement('input');
    caixa.type = 'checkbox';
    confirma.append(caixa, 'confirmei a pessoa e cada acto; esta escrita nao tem undo');
    artigo.appendChild(confirma);
    var resolver = botao('creditar e resolver', resolverPagamento);
    resolver.disabled = true;
    artigo.appendChild(resolver);
    var resposta = texto('p', '', 'estado');
    artigo.appendChild(resposta);

    caixa.onchange = actualizar;
    function actualizar() {
      lista.replaceChildren();
      var soma = 0;
      itens.forEach(function (n, slug) {
        var a = porSlug.get(slug);
        soma += Number(a.cafes) * n * 2;
        var li = document.createElement('li');
        li.append(texto('span', slug + ' x' + n), botao('tirar', function () { itens.delete(slug); actualizar(); }));
        lista.appendChild(li);
      });
      total.textContent = 'total escolhido: ' + soma + ' USD';
      var bate = pagamento.currency === 'USD' && Number(pagamento.amount) === soma;
      total.className = bate ? 'certo' : 'erro';
      resolver.disabled = !(pessoa && itens.size && bate && caixa.checked);
    }

    async function resolverPagamento() {
      if (!confirm('Creditar estes actos a esta pessoa e fechar a linha? Esta escrita nao tem undo.')) return;
      resolver.disabled = true;
      resposta.textContent = 'a escrever...';
      try {
        var escolhidos = Array.from(itens, function (x) { return { ato_slug: x[0], quantidade: x[1] }; });
        var r = await api({ acao: 'resolver', reconciliacao_id: pagamento.id, user_id: pessoa, itens: escolhidos });
        resposta.textContent = r.estado;
        resposta.className = 'estado certo';
        await carregar();
      } catch (e) {
        resposta.textContent = e.message;
        resposta.className = 'estado erro';
        actualizar();
      }
    }
    actualizar();
    fila.appendChild(artigo);
  }

  if (token) carregar();
}());
</script>
</body>
</html>`;
