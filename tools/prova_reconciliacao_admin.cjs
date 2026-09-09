// Exercita a vista num browser real, com auth e servidor simulados.
//
// NODE_PATH=/caminho/para/node_modules node tools/prova_reconciliacao_admin.cjs
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');

const source = fs.readFileSync(path.join(__dirname,
  '../server/functions/reconciliacao_admin/pagina.ts'), 'utf8');
const pagina = source.match(/String\.raw`([\s\S]*)`;\s*$/)[1];
let resolucao = null;

const server = http.createServer(async (req, res) => {
  const partes = [];
  for await (const parte of req) partes.push(parte);
  const corpo = partes.length ? JSON.parse(Buffer.concat(partes).toString()) : {};
  res.setHeader('content-type', req.url === '/' && req.method === 'GET'
    ? 'text/html; charset=utf-8' : 'application/json');

  if (req.url === '/' && req.method === 'GET') {
    const origem = 'http://127.0.0.1:' + server.address().port;
    res.end(pagina
      .replace('__SUPABASE_URL__', JSON.stringify(origem))
      .replace('__SUPABASE_ANON_KEY__', JSON.stringify('publica'))
      .replace('__ADMIN_URL__', JSON.stringify(origem)));
  } else if (req.url === '/auth/v1/otp') {
    assert.equal(corpo.create_user, false);
    res.end('{}');
  } else if (req.url === '/auth/v1/verify') {
    res.end(JSON.stringify({ access_token: 'sessao-de-prova' }));
  } else if (corpo.acao === 'listar') {
    assert.equal(req.headers.authorization, 'Bearer sessao-de-prova');
    res.end(JSON.stringify({
      atos: [{ slug: 'marafo', cafes: 1 }, { slug: 'pimenta', cafes: 1 }],
      fila: resolucao ? [] : [{
        id: 'fila-1', kofi_message_id: 'mensagem-1', amount: 6,
        currency: 'USD', created_at: '2026-09-09T12:00:00Z',
        raw: { type: 'Donation', email: 'pessoa@exemplo.pt',
          message: '<img data-injeccao="sim">', shop_items: [] }
      }]
    }));
  } else if (corpo.acao === 'procurar_pessoa') {
    res.end(JSON.stringify({ user_id: 'pessoa-1' }));
  } else if (corpo.acao === 'resolver') {
    resolucao = corpo;
    res.end(JSON.stringify({ estado: 'creditado' }));
  } else {
    res.statusCode = 404;
    res.end('{}');
  }
});

(async () => {
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  let browser;
  try {
    browser = await chromium.launch({
      executablePath: process.env.BARCO_CHROME || '/usr/bin/google-chrome',
      headless: true,
    });
    const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
    await page.goto('http://127.0.0.1:' + server.address().port + '/');
    await page.locator('#email').fill('admin@exemplo.pt');
    await page.getByRole('button', { name: 'enviar codigo' }).click();
    await page.locator('#codigo').fill('123456');
    await page.getByRole('button', { name: 'entrar' }).click();
    await page.getByText('6 USD / Donation').waitFor();
    assert.equal(await page.locator('[data-injeccao]').count(), 0,
      'o texto do pagamento nao pode criar HTML');
    assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth),
      'a vista cabe num ecra estreito');

    await page.getByRole('button', { name: 'procurar conta' }).click();
    await page.getByText('pessoa-1').waitFor();
    const quantidade = page.locator('input[type=number]');
    await page.locator('select').selectOption('pimenta');
    await quantidade.fill('2');
    await page.getByRole('button', { name: 'juntar acto' }).click();
    await page.locator('select').selectOption('marafo');
    await quantidade.fill('1');
    await page.getByRole('button', { name: 'juntar acto' }).click();
    await page.getByText('total escolhido: 6 USD').waitFor();
    await page.locator('input[type=checkbox]').check();
    const resolver = page.getByRole('button', { name: 'creditar e resolver' });
    assert.equal(await resolver.isEnabled(), true);
    page.once('dialog', dialog => dialog.accept());
    await resolver.click();
    await page.waitForFunction(() => document.body.textContent.includes('a fila esta vazia'));

    assert.deepEqual(resolucao, {
      acao: 'resolver', reconciliacao_id: 'fila-1', user_id: 'pessoa-1',
      itens: [
        { ato_slug: 'pimenta', quantidade: 2 },
        { ato_slug: 'marafo', quantidade: 1 },
      ],
    });
    console.log('PASS: login, fila, total exacto, confirmacao e resolucao');
    console.log('PASS: payload tratado como texto e vista estreita sem overflow');
  } finally {
    if (browser) await browser.close();
    server.close();
  }
})().catch(e => { console.error(e); process.exitCode = 1; });
