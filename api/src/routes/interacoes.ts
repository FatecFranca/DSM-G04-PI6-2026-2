import { Router } from "express";
import { authMiddleware } from "../middlewares/autentication";
import { createInteracaoController, listMyInteracoesController } from "../controllers/interacoes";

const router = Router();

router.use(authMiddleware);

router.post("/", createInteracaoController);
router.get("/me", listMyInteracoesController);

export default router;
