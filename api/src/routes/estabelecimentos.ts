import { Router } from "express";
import { authMiddleware } from "../middlewares/autentication";
import {
  listEstabelecimentosController,
  listAvaliacoesEstabelecimentoController,
  getEstabelecimentoByIdController,
} from "../controllers/estabelecimentos";

const router = Router();

router.use(authMiddleware);

router.get("/", listEstabelecimentosController);
router.get("/:id/avaliacoes", listAvaliacoesEstabelecimentoController);
router.get("/:id", getEstabelecimentoByIdController);

export default router;


