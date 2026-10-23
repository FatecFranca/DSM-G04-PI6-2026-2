import { Request, Response, NextFunction } from "express";
import jwt, { JwtPayload, SignOptions } from "jsonwebtoken";
import { prisma } from "../../lib/prisma";

const signOptions: SignOptions = { expiresIn: "30m" };

/** Le e valida o segredo usado para assinar tokens; falha cedo se estiver inseguro. */
function getJwtSecret() {
  const secret = process.env.JWT_SECRET?.trim();
  if (!secret || secret === "your-secret-key" || secret.length < 32) {
    throw new Error("JWT_SECRET deve ser configurada com pelo menos 32 caracteres");
  }
  return secret;
}

/** Cria um JWT com o payload recebido e validade de 30 minutos. */
export const generateToken = (payload: object): string =>
  jwt.sign(payload, getJwtSecret(), signOptions);

/** Confere assinatura e expiracao do token e devolve os dados que estavam dentro dele. */
export const verifyToken = (token: string): JwtPayload =>
  jwt.verify(token, getJwtSecret()) as JwtPayload;

/** Valida o Bearer token, confirma que a conta esta ativa e libera a rota protegida. */
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
// Middleware de autenticacao: confere o token antes de liberar uma rota protegida.
// Quando o token e valido, o identificador do usuario fica disponivel em req.user.
