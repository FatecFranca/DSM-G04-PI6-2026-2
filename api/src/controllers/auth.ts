import { Request, Response } from "express";
import { generateToken } from "../middlewares/autentication";
import { findUserByEmail, updateUserPassword } from "../models/auth";
import { loginSchema } from "../types/authSchema";
import bcrypt from "bcrypt";

// Um hash bcrypt possui formato conhecido. Esta verificacao tambem permite que
// senhas antigas em texto puro sejam migradas no primeiro login bem-sucedido.
function isBcryptHash(value: string) {
  return /^\$2[aby]\$\d{2}\$[./A-Za-z0-9]{53}$/.test(value);
}

/** Valida as credenciais, protege senha antiga e devolve o JWT da nova sessao. */
export async function loginController(req: Request, res: Response) {
  // safeParse valida o corpo sem lancar excecao quando os dados estao incorretos.
  const parsed = loginSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json({
      success: false,
      error: "Dados inválidos"
    });
  }

  const { email, senha } = parsed.data;

  try {
    // Por seguranca, tanto usuario inexistente quanto senha errada retornam a mesma mensagem.
    const user = await findUserByEmail(email);

    if (!user) {
      return res.status(401).json({
        success: false,
        message: "Credenciais inválidas"
      });
    }

    if (!user.ativo) {
      return res.status(403).json({
        success: false,
        message: "Usuário inativo"
      });
    }

    let senhaValida = false;

    if (isBcryptHash(user.hash_senha)) {
      senhaValida = await bcrypt.compare(senha, user.hash_senha);
    } else {
      senhaValida = senha === user.hash_senha;

      if (senhaValida) {
        try {
          const novoHash = await bcrypt.hash(senha, 10);
          await updateUserPassword(user.id_usuario, novoHash);
        } catch {
          // nao bloqueia login se falhar ao migrar hash legado
        }
      }
    }

    if (!senhaValida) {
      return res.status(401).json({
        success: false,
        message: "Credenciais inválidas"
      });
    }
    // O token prova a identidade nas proximas chamadas feitas pelo aplicativo.
    const accessToken = generateToken({ id_usuario: user.id_usuario });

    return res.status(200).json({
      success: true,
      token: accessToken,
    });

  } catch (error) {
    console.error("Erro no login:", error);
    return res.status(500).json({
      success: false,
      message: "Erro ao fazer login"
    });
  }
};
