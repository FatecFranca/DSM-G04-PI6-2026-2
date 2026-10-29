export function pontuarPreferencia(tipo: string, valor: unknown): number {
  if (tipo === "like") return 3;
  if (tipo === "dislike") return -3;
  if (tipo !== "rating") return 0;
  const nota = Number(valor);
  return nota >= 4 && nota <= 5 ? 3 : nota >= 1 && nota <= 2 ? -3 : 0;
}
