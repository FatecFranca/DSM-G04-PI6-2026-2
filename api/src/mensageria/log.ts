type ErroComCampos = { message?: unknown; code?: unknown; stack?: unknown; cause?: unknown };

export function ocultarCredenciais(texto: string, ambiente: NodeJS.ProcessEnv = process.env): string {
  const segredos: string[] = [];
  for (const [chave, valor] of Object.entries(ambiente)) {
    if (!valor || !/(SENHA|PASSWORD|SECRET|TOKEN|CREDENTIAL|PRIVATE_KEY|DATABASE_URL|DIRECT_URL)/i.test(chave)) continue;
    segredos.push(valor);
    try {
      const url = new URL(valor);
      if (url.password) {
        segredos.push(url.password);
        segredos.push(decodeURIComponent(url.password));
      }
    } catch { /* Nem todo segredo e uma URL. */ }
  }
  let seguro = texto;
  for (const segredo of [...new Set(segredos)].sort((a, b) => b.length - a.length)) {
    seguro = seguro.split(segredo).join("[OCULTO]");
  }
  return seguro
    .replace(/([a-z][a-z0-9+.-]*:\/\/)[^\s/@]+:[^\s/@]*@/gi, "$1[OCULTO]@")
    .replace(/(Bearer\s+)[a-z0-9._~+\/-]+=*/gi, "$1[OCULTO]")
    .replace(/((?:password|senha|secret|access_token|refresh_token|token|private_key)["']?\s*[=:]\s*)(?:"[^"]*"|'[^']*'|[^\s,;}]+)/gi, "$1[OCULTO]");
}

export function serializarErro(erro: unknown, ambiente: NodeJS.ProcessEnv = process.env, nivel = 0): {
  mensagem: string; codigo: string | number | null; stack: string | null; causa?: unknown;
} {
  const campos: ErroComCampos = erro !== null && typeof erro === "object" ? erro : {};
  const limpar = (valor: string) => ocultarCredenciais(valor, ambiente);
  return {
    mensagem: limpar(typeof campos.message === "string" ? campos.message : typeof erro === "string" ? erro : "Erro sem mensagem").slice(0, 8000),
    codigo: typeof campos.code === "number" ? campos.code : typeof campos.code === "string" ? limpar(campos.code) : null,
    stack: typeof campos.stack === "string" ? limpar(campos.stack).slice(0, 16000) : null,
    ...(campos.cause && nivel < 2 ? { causa: serializarErro(campos.cause, ambiente, nivel + 1) } : {}),
  };
}

export function registrarMensageria(estado: string, id: string, erro?: unknown) {
  const registro = { componente: "mensageria", estado, id, ...(erro !== undefined ? { erro: serializarErro(erro) } : {}) };
  if (erro !== undefined) console.error(JSON.stringify(registro));
  else console.log(JSON.stringify(registro));
}
