// Serve a vista apenas em localhost e abre-a no browser.
const fs = require('node:fs');
const http = require('node:http');
const path = require('node:path');
const { spawn } = require('node:child_process');

const raiz = path.resolve(__dirname, '../..');
const paginaSource = fs.readFileSync(path.join(raiz,
  'server/functions/reconciliacao_admin/pagina.ts'), 'utf8');
const recurso = fs.readFileSync(path.join(raiz,
  'client/resources/servidor/supabase.tres'), 'utf8');
const pagina = paginaSource.match(/String\.raw`([\s\S]*)`;\s*$/);
const endpoint = recurso.match(/^url = "([^"]+)"$/m);
const publica = recurso.match(/^chave_publica = "([^"]+)"$/m);
if (!pagina || !endpoint || !publica) {
  throw new Error('nao foi possivel ler a pagina ou a configuracao publica');
}

const origem = 'http://127.0.0.1:4173';
const admin = endpoint[1] + '/functions/v1/reconciliacao_admin';
const html = pagina[1]
  .replace('__SUPABASE_URL__', JSON.stringify(endpoint[1]))
  .replace('__SUPABASE_ANON_KEY__', JSON.stringify(publica[1]))
  .replace('__ADMIN_URL__', JSON.stringify(admin));

const server = http.createServer((req, res) => {
  if (req.method !== 'GET' || (req.url !== '/' && req.url !== '/favicon.ico')) {
    res.writeHead(404).end();
    return;
  }
  if (req.url === '/favicon.ico') {
    res.writeHead(204).end();
    return;
  }
  res.writeHead(200, {
    'content-type': 'text/html; charset=utf-8',
    'cache-control': 'no-store',
    'content-security-policy': "default-src 'none'; style-src 'unsafe-inline'; script-src 'unsafe-inline'; connect-src " + endpoint[1] + "; img-src 'none'; frame-ancestors 'none'; base-uri 'none'; form-action 'none'",
    'x-content-type-options': 'nosniff',
    'x-frame-options': 'DENY',
    'referrer-policy': 'no-referrer',
  }).end(html);
});

server.listen(4173, '127.0.0.1', () => {
  console.log('Vista de reconciliacao: ' + origem);
  console.log('Fecha com Ctrl+C.');
  if (!process.env.BARCO_ADMIN_NO_OPEN) {
    const filho = spawn('xdg-open', [origem], { detached: true, stdio: 'ignore' });
    filho.unref();
  }
});
