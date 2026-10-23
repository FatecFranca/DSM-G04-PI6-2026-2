import { Router } from "express";
import { authMiddleware } from "../middlewares/autentication";
import {
  createUsuarioController,
  getUsuarioByIdController,
  updateUsuarioController,
  deleteUsuarioController
} from "../controllers/usuarios";
import { getMyPreferenciasController, saveMyPreferenciasController } from "../controllers/usuarios";

const router = Router();



router.post("/", createUsuarioController);


router.use(authMiddleware);
router.get("/me/preferencias", getMyPreferenciasController);
router.put("/me/preferencias", saveMyPreferenciasController);
router.get("/:id", getUsuarioByIdController);
router.put("/:id", updateUsuarioController);
router.delete("/:id", deleteUsuarioController);

export default router;
