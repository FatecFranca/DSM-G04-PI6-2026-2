import { Request, Response, NextFunction } from "express";

export function adminRestaurantes(req: Request & { user?: { id_usuario: number } }, res: Response, next: NextFunction) {
  const permitidos = (process.env.RESTAURANTES_ADMIN_IDS ?? "").split(",").map(id => id.trim());
  if (!req.user || !permitidos.includes(String(req.user.id_usuario))) {
    return res.status(403).json({ success: false, message: "Somente administradores podem editar restaurantes" });
  }
  next();
}
