import { Router, Request } from "express";
import { prisma } from "../../lib/prisma";
import { authMiddleware } from "../middlewares/autentication";

type Requisicao = Request & { user?: { id_usuario: number } };
const router = Router();
router.use(authMiddleware);

router.get("/", async (req: Requisicao, res) => {
  if (!req.user) return res.status(401).json({ success: false });
  const cursor = req.query.antes === undefined ? undefined : Number(req.query.antes);
  if (cursor !== undefined && (!Number.isSafeInteger(cursor) || cursor <= 0)) {
    return res.status(400).json({ success: false, message: "Cursor invalido" });
  }
  try {
    const [lista, naoLidas] = await prisma.$transaction([
      prisma.tb_notificacao.findMany({
        where: { id_usuario: req.user.id_usuario, ...(cursor ? { id_notificacao: { lt: cursor } } : {}) },
        orderBy: { id_notificacao: "desc" }, take: 21,
      }),
      prisma.tb_notificacao.count({ where: { id_usuario: req.user.id_usuario, lida_em: null } }),
    ]);
    return res.json({ success: true, data: { notificacoes: lista.slice(0, 20), naoLidas, temMais: lista.length > 20 } });
  } catch {
    return res.status(500).json({ success: false, message: "Erro ao carregar notificacoes" });
  }
});

router.patch("/:id/lida", async (req: Requisicao, res) => {
  if (!req.user) return res.status(401).json({ success: false });
  const id = Number(req.params.id);
  if (!Number.isSafeInteger(id) || id <= 0) return res.status(400).json({ success: false, message: "ID invalido" });
  try {
    const where = { id_notificacao: id, id_usuario: req.user.id_usuario };
    const registro = await prisma.tb_notificacao.findFirst({ where });
    if (!registro) return res.status(404).json({ success: false, message: "Notificacao nao encontrada" });
    await prisma.tb_notificacao.updateMany({ where: { ...where, lida_em: null }, data: { lida_em: new Date() } });
    return res.json({ success: true });
  } catch {
    return res.status(500).json({ success: false, message: "Erro ao marcar notificacao" });
  }
});

export default router;
