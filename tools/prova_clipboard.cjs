// Run with NODE_PATH pointing to an installed Playwright package.
// Exercises the exported helper in a real, clipboard-restricted iframe.
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');

const source = fs.readFileSync(path.join(__dirname,
  '../client/scripts/ui/codigo_clipboard.gd'), 'utf8');
const script = source.match(/const SCRIPT_WEB := """\n([\s\S]*?)\n"""/)[1];
const server = http.createServer((req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Permissions-Policy', 'clipboard-write=(), clipboard-read=()');
  if (req.url === '/game') {
    res.end(`<button id="copiar">copiar</button><textarea id="colar"></textarea>
      <script>${script}</script><script>
      window.resultados = [];
      document.querySelector('#copiar').onclick = () => BarcoClipboard.copiar(
        'BAR-7X2K', window.destino || '', (...args) => resultados.push(args));
      </script>`);
  } else if (req.url === '/checkout') {
    res.end('Checkout de prova — nenhum pagamento');
  } else {
    res.end(`<iframe title="Barco" style="width:100%;height:650px;border:0"
      sandbox="allow-scripts allow-same-origin allow-popups allow-popups-to-escape-sandbox allow-modals"
      src="http://127.0.0.1:${server.address().port}/game"></iframe>`);
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
    const context = await browser.newContext({ viewport: { width: 390, height: 844 } });
    const page = await context.newPage();
    const errors = [];
    page.on('pageerror', e => errors.push(e.message));
    async function fresh() {
      await page.goto(`http://localhost:${server.address().port}/`);
      const iframe = page.frameLocator('iframe');
      await iframe.locator('#copiar').waitFor();
      return page.frames().find(f => f.url().endsWith('/game'));
    }
    let frame = await fresh();
    await frame.click('#copiar');
    assert.deepEqual(await frame.evaluate(() => resultados), [['BAR-7X2K', 'copiado']]);
    await frame.click('#colar');
    await page.keyboard.press('Control+V');
    assert.equal(await frame.inputValue('#colar'), 'BAR-7X2K');
    console.log('PASS: actual copy/paste works inside a clipboard-restricted iframe');

    frame = await fresh();
    await frame.evaluate(() => {
      document.execCommand = () => false;
      Object.defineProperty(navigator, 'clipboard', { configurable: true,
        value: { writeText: () => Promise.reject(new Error('Denied')) } });
      window.destino = location.origin + '/checkout';
    });
    await frame.click('#copiar');
    await frame.locator('dialog[open]').waitFor();
    assert.deepEqual(await frame.evaluate(() => resultados), [['BAR-7X2K', 'manual']]);
    assert.equal(await frame.locator('dialog input').inputValue(), 'BAR-7X2K');
    await frame.locator('dialog button').first().click();
    await frame.getByRole('status').filter({ hasText: 'Ctrl+C' }).waitFor();
    assert.equal(context.pages().length, 1, 'failed copy must not open checkout');
    const bounds = await frame.locator('dialog').boundingBox();
    assert.ok(bounds.width <= 390, 'fallback fits a mobile viewport');
    const popupPromise = context.waitForEvent('page');
    await frame.getByRole('link').click();
    const popup = await popupPromise;
    await popup.waitForLoadState();
    assert.ok(popup.url().endsWith('/checkout'));
    assert.equal(await popup.evaluate(() => window.opener), null);
    await popup.close();
    await frame.getByRole('button', { name: 'voltar', exact: true }).click();
    assert.equal(await frame.locator('dialog').count(), 0);
    console.log('PASS: denied copy offers selectable text, no false success, and a working manual link');

    frame = await fresh();
    await frame.evaluate(() => {
      window.destino = location.origin + '/checkout';
      window.open = () => null;
    });
    await frame.click('#copiar');
    await frame.locator('dialog[open]').waitFor();
    assert.deepEqual(await frame.evaluate(() => resultados),
      [['BAR-7X2K', 'copiado'], ['BAR-7X2K', 'abertura_bloqueada']]);
    assert.equal(await frame.getByRole('link').count(), 1);
    console.log('PASS: popup rejection leaves a direct link after confirmed copy');

    frame = await fresh();
    await frame.evaluate(() => {
      document.execCommand = () => false;
      Object.defineProperty(navigator, 'clipboard', { configurable: true,
        value: { writeText: () => new Promise(resolve => { window.concluir = resolve; }) } });
      window.destino = location.origin + '/checkout';
    });
    await frame.click('#copiar');
    await frame.evaluate(async () => {
      BarcoClipboard.cancelar();
      concluir();
      await Promise.resolve();
    });
    assert.deepEqual(await frame.evaluate(() => resultados), []);
    assert.equal(context.pages().length, 1);
    assert.equal(await frame.locator('dialog').count(), 0);
    assert.deepEqual(errors, []);
    console.log('PASS: leaving checkout cancels pending callbacks and popup creation');
  } finally {
    if (browser) await browser.close();
    server.close();
  }
})().catch(e => { console.error(e); process.exitCode = 1; });
