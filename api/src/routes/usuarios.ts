import { Router } from "express";
import { authMiddleware } from "../middlewares/autentication";
import {
  createUsuarioController,
  listUsuariosController,
  getUsuarioByIdController,
  updateUsuarioController,
  deleteUsuarioController
} from "../controllers/usuarios";

const router = Router();


// Rota pública para criação de usuário
router.post("/", createUsuarioController);

// Todas as rotas abaixo exigem autenticação
router.use(authMiddleware);
router.get("/", listUsuariosController);
router.get("/:id", getUsuarioByIdController);
router.put("/:id", updateUsuarioController);
router.delete("/:id", deleteUsuarioController);

export default router;
