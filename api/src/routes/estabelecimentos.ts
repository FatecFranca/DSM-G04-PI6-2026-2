import { Router } from "express";
import { authMiddleware } from "../middlewares/autentication";
import {
  createEstabelecimentoController,
  listEstabelecimentosController,
  getEstabelecimentoByIdController,
  updateEstabelecimentoController,
  deleteEstabelecimentoController
} from "../controllers/estabelecimentos";

const router = Router();

router.use(authMiddleware);

router.post("/", createEstabelecimentoController);
router.get("/", listEstabelecimentosController);
router.get("/:id", getEstabelecimentoByIdController);
router.put("/:id", updateEstabelecimentoController);
router.delete("/:id", deleteEstabelecimentoController);

export default router;
