import { Router } from "express";
import { authMiddleware } from "../middlewares/autentication";
import { listAiSuggestionsController, listRecomendacoesController } from "../controllers/recomendacoes";

const router = Router();

router.use(authMiddleware);
router.get("/", listRecomendacoesController);
router.get("/ia-sugestoes", listAiSuggestionsController);

export default router;
