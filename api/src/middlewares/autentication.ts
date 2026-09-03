import { Request, Response, NextFunction } from "express";
import jwt, { JwtPayload, SignOptions } from "jsonwebtoken";
import { prisma } from "../../lib/prisma";

const signOptions: SignOptions = { expiresIn: "30m" };

function getJwtSecret() {
  const secret = process.env.JWT_SECRET?.trim();
  if (!secret || secret === "your-secret-key" || secret.length < 32) {
    throw new Error("JWT_SECRET deve ser configurada com pelo menos 32 caracteres");
  }
  return secret;
}

export const generateToken = (payload: object): string =>
  jwt.sign(payload, getJwtSecret(), signOptions);

export const verifyToken = (token: string): JwtPayload =>
  jwt.verify(token, getJwtSecret()) as JwtPayload;

export const authMiddleware = async (
  req: Request & { user?: any },
  res: Response,
  next: NextFunction
) => {
  const authHeader = req.headers.authorization;
  const token = authHeader?.startsWith("Bearer ") ? authHeader.slice(7) : undefined;

  if (!token) {
    return res.status(401).json({ success: false, message: "Token nao fornecido" });
  }

  try {
    const { id_usuario } = verifyToken(token) as { id_usuario: number };

    const user = await prisma.tb_usuario.findUnique({ where: { id_usuario } });

    if (!user || !user.ativo) {
      return res.status(401).json({ success: false, message: "Usuario invalido ou inativo" });
    }

    req.user = { id_usuario: user.id_usuario, email: user.email };
    next();
  } catch {
    return res.status(401).json({ success: false, message: "Token invalido ou expirado" });
  }
};
