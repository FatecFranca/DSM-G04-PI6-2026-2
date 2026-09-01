import { extendZodWithOpenApi } from "@asteasolutions/zod-to-openapi";
import { z } from "zod";

extendZodWithOpenApi(z);

export const loginSchema = z.object({
  email: z.string().email("Email invalido"),
  senha: z.string().min(1, "Senha e obrigatoria"),
});

export type LoginDTO = z.infer<typeof loginSchema>;
