## O browser confirma a copia; se a recusar, oferece seleccao nativa.
class_name CodigoClipboard
extends RefCounted

const SCRIPT_WEB := """
window.BarcoClipboard = (() => {
  let actual = null;
  function cancelar() {
    if (!actual) return;
    actual.activa = false;
    if (actual.painel) actual.painel.remove();
    actual = null;
  }
  function copiar(codigo, destino, avisar) {
    cancelar();
    const tarefa = { activa: true, painel: null };
    actual = tarefa;
    function dizer(estado) {
      if (tarefa.activa) avisar(codigo, estado);
    }
    function campo() {
      const input = document.createElement('input');
      input.value = codigo;
      input.readOnly = true;
      input.setAttribute('aria-label', 'Código do pagamento');
      input.style.cssText = 'font:28px monospace;width:100%;box-sizing:border-box;padding:12px;color:#eee;background:#111;border:1px solid #aaa;user-select:text';
      input.addEventListener('click', () => input.select());
      return input;
    }
    function copiaAntiga(input) {
      input.focus();
      input.select();
      input.setSelectionRange(0, codigo.length);
      try { return document.execCommand('copy'); } catch (_) { return false; }
    }
    function terminar() {
      if (!tarefa.activa) return;
      dizer('copiado');
      if (!destino) {
        if (tarefa.painel) tarefa.painel.remove();
        return;
      }
      const janela = window.open(destino, '_blank');
      if (janela) {
        janela.opener = null;
        if (tarefa.painel) tarefa.painel.remove();
      } else {
        manual(true);
        dizer('abertura_bloqueada');
      }
    }
    function manual(copiado = false) {
      if (!tarefa.activa) return;
      if (tarefa.painel) tarefa.painel.remove();
      const painel = document.createElement('dialog');
      tarefa.painel = painel;
      painel.setAttribute('aria-label', 'Código do pagamento');
      painel.style.cssText = 'box-sizing:border-box;max-width:calc(100% - 24px);width:420px;padding:24px;background:#080808;color:#eee;border:1px solid #aaa;font:18px serif';
      const texto = document.createElement('p');
      texto.textContent = copiado ? 'Código copiado. Abre o Ko-fi e cola-o na mensagem.' : 'Selecciona e copia este código. No Ko-fi, cola-o na mensagem.';
      painel.append(texto);
      const input = campo();
      painel.append(input);
      const estado = document.createElement('p');
      estado.setAttribute('role', 'status');
      painel.append(estado);
      const botao = document.createElement('button');
      botao.textContent = destino ? 'copiar e abrir o Ko-fi' : 'copiar código';
      botao.style.cssText = 'font:inherit;padding:12px;margin:12px 8px 12px 0';
      botao.onclick = () => tentar(input, () => {
        estado.textContent = 'Copia a selecção com Ctrl+C, Cmd+C ou o menu do telemóvel.';
        input.focus(); input.select();
      });
      painel.append(botao);
      if (destino) {
        const link = document.createElement('a');
        link.textContent = 'já copiei — abrir o Ko-fi';
        link.href = destino;
        link.target = '_blank';
        link.rel = 'noopener noreferrer';
        link.style.cssText = 'display:block;color:#eee;padding:12px 0';
        painel.append(link);
      }
      const fechar = document.createElement('button');
      fechar.textContent = 'voltar';
      fechar.style.cssText = 'font:inherit;padding:12px';
      fechar.onclick = () => { painel.close(); cancelar(); };
      painel.append(fechar);
      painel.addEventListener('cancel', cancelar);
      document.body.append(painel);
      painel.showModal();
      input.focus(); input.select();
    }
    function tentar(input, falhou) {
      if (copiaAntiga(input)) { terminar(); return; }
      if (!navigator.clipboard || !navigator.clipboard.writeText) { falhou(); return; }
      try {
        navigator.clipboard.writeText(codigo).then(terminar, () => {
          if (tarefa.activa) falhou();
        });
      } catch (_) { falhou(); }
    }
    const input = campo();
    input.style.position = 'fixed';
    input.style.left = '-10000px';
    document.body.append(input);
    const foco = document.activeElement;
    tentar(input, () => { dizer('manual'); manual(); });
    input.remove();
    if (!tarefa.painel && foco && foco.isConnected) foco.focus();
  }
  return { copiar, cancelar };
})();
"""
