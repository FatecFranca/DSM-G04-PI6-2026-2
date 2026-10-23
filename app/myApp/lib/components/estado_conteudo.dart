import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EstadoConteudo extends StatelessWidget {
  const EstadoConteudo({
    required this.titulo,
    required this.descricao,
    this.icone = Icons.search_off,
    this.acao,
    this.textoAcao = 'Tentar novamente',
    super.key,
  });
  final String titulo;
  final String descricao;
  final IconData icone;
  final VoidCallback? acao;
  final String textoAcao;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 52, color: AppTheme.accent),
            const SizedBox(height: 18),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(descricao, textAlign: TextAlign.center),
            if (acao != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: acao, child: Text(textoAcao)),
            ],
          ],
        ),
      ),
    ),
  );
}
