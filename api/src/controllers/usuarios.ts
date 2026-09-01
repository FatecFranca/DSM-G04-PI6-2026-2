import { Request, Response } from "express";
import * as usuariosModel from "../models/usuarios";
import { UsuarioSchema, UsuarioUpdateSchema } from "../types/usuario";

export async function createUsuarioController(req: Request, res: Response) {
  try {
    const parsed = UsuarioSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        errors: parsed.error.flatten()
      });
    }

    const usuario = await usuariosModel.createUsuario(parsed.data);
    if (!usuario) {
      return res.status(400).json({
        error: "Erro ao criar usuario"
      });
    }

    return res.status(201).json({ success: true, data: usuario });
  } catch (error) {
    const statusCode = (error as { statusCode?: unknown })?.statusCode;
    if (typeof statusCode === "number") {
      return res.status(statusCode).json({
        success: false,
        message: error instanceof Error ? error.message : "Erro ao criar usuario"
      });
    }

    return res.status(500).json({
      success: false,
      message: "Erro ao criar usuario",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}

export async function listUsuariosController(_req: Request, res: Response) {
  try {
    const usuarios = await usuariosModel.listUsuarios();
    return res.json({ success: true, data: usuarios });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao listar usuarios",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}

export async function getUsuarioByIdController(req: Request, res: Response) {
  const id: number = Number(req.params.id);
  if (!id) return res.status(400).json({ success: false, message: "ID invalido" });

  try {
    const usuario = await usuariosModel.getUsuarioById(id);
    if (!usuario) return res.status(404).json({ success: false, message: "Registro nao encontrado" });
    return res.json({ success: true, data: usuario });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao buscar usuario",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}

export async function updateUsuarioController(req: Request, res: Response) {
  const id: number = Number(req.params.id);
  if (!id) return res.status(400).json({ success: false, message: "ID invalido" });

  try {
    const parsed = UsuarioUpdateSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        errors: parsed.error.flatten()
      });
    }

    const existing = await usuariosModel.getUsuarioById(id);
    if (!existing) return res.status(404).json({ success: false, message: "Registro nao encontrado" });

    const usuario = await usuariosModel.updateUsuario(id, parsed.data);
    return res.json({ success: true, data: usuario });
  } catch (error) {
    return res.status(500).json({
      message: "Erro ao atualizar usuario",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}

export async function deleteUsuarioController(req: Request, res: Response) {
  const id: number = Number(req.params.id);
  if (!id) return res.status(400).json({ success: false, message: "ID invalido" });

  try {
    const existing = await usuariosModel.getUsuarioById(id);
    if (!existing) return res.status(404).json({ success: false, message: "Registro nao encontrado" });

    await usuariosModel.deleteUsuario(id);
    return res.json({ success: true, message: "Registro removido com sucesso" });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Erro ao remover usuario",
      error: error instanceof Error ? error.message : "Erro desconhecido"
    });
  }
}
