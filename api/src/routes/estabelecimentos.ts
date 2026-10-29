import { Router } from "express";
import { curtirComentario } from "../models/curtidasComentarios";
import { authMiddleware } from "../middlewares/autentication";
import { adminRestaurantes } from "../middlewares/adminRestaurantes";
import {
  listEstabelecimentosController,
  createEstabelecimentoController,
  listAvaliacoesEstabelecimentoController,
  getEstabelecimentoByIdController,
  updateEstabelecimentoController,
} from "../controllers/estabelecimentos";

const router = Router();

router.use(authMiddleware);

router.get("/", listEstabelecimentosController);
router.post("/", createEstabelecimentoController);
router.get("/:id/avaliacoes", listAvaliacoesEstabelecimentoController);
router.put("/:id/comentarios/:classificacao/curtida", async (req, res) => {
  const id = Number(req.params.id);
  const classificacao = Number(req.params.classificacao);
  const usuario = (req as typeof req & { user?: { id_usuario: number } }).user?.id_usuario;
  if (!usuario) return res.status(401).json({ message: "Usuário não autenticado" });
  if (![id, classificacao].every(n => Number.isSafeInteger(n) && n > 0 && n <= 2147483647)) return res.status(400).json({ message: "Identificador inválido" });
  try {
    return res.json({ success: true, data: await curtirComentario(classificacao, id, usuario) });
  } catch (erro) {
    const status = (erro as { statusCode?: number }).statusCode ?? 500;
    return res.status(status).json({ message: status === 500 ? "Não foi possível curtir o comentário" : (erro as Error).message });
  }
});
router.get("/:id", getEstabelecimentoByIdController);
router.put("/:id", adminRestaurantes, updateEstabelecimentoController);

export default router;


