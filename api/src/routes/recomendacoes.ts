import { Router } from "express";
import { authMiddleware } from "../middlewares/autentication";
import { getModeloRecomendacaoController, recomendarController } from "../controllers/recomendacoes";

const router = Router();
router.get("/modelo", getModeloRecomendacaoController);
router.use(authMiddleware);
router.post("/", recomendarController);
export default router;
