import { Router } from "express";
import { authMiddleware } from "../middlewares/autentication";
import {
  createClassificacaoController,
  listClassificacoesController,
  getClassificacaoByIdController,
  updateClassificacaoController,
  deleteClassificacaoController
} from "../controllers/classificacoes";

const router = Router();

router.use(authMiddleware);

router.post("/", createClassificacaoController);
router.get("/", listClassificacoesController);
router.get("/:id", getClassificacaoByIdController);
router.put("/:id", updateClassificacaoController);
router.delete("/:id", deleteClassificacaoController);

export default router;
