import { Router } from "express";
import { authMiddleware } from "../middlewares/autentication";
import {
  createClassificacaoEstabelecimentoController,
  listClassificacoesEstabelecimentosController,
  getClassificacaoEstabelecimentoByIdsController,
  deleteClassificacaoEstabelecimentoController
} from "../controllers/classificacoesEstabelecimentos";

const router = Router();

router.use(authMiddleware);

router.post("/", createClassificacaoEstabelecimentoController);
router.get("/", listClassificacoesEstabelecimentosController);
router.get("/:id_classificacao/:id_estabelecimento", getClassificacaoEstabelecimentoByIdsController);
router.delete("/:id_classificacao/:id_estabelecimento", deleteClassificacaoEstabelecimentoController);

export default router;
