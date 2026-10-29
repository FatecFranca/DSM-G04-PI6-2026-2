import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api.dart';

class CadastroEstabelecimentoDialog extends StatefulWidget {
  const CadastroEstabelecimentoDialog({required this.api, super.key});
  final ApiService api;

  @override
  State<CadastroEstabelecimentoDialog> createState() =>
      _CadastroEstabelecimentoDialogState();
}

class _CadastroEstabelecimentoDialogState
    extends State<CadastroEstabelecimentoDialog> {
  final _form = GlobalKey<FormState>();
  final _campos = {
    for (final chave in [
      'nome',
      'tipo',
      'faixa_preco',
      'ambiente',
      'publico',
      'abre',
      'fecha',
    ])
      chave: TextEditingController(),
  };
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    for (final campo in _campos.values) {
      campo.dispose();
    }
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando) return;
    if (!_form.currentState!.validate()) {
      setState(
        () => _erro =
            'Preencha todos os campos e informe os dois horários para cadastrar.',
      );
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await widget.api.cadastrarEstabelecimento({
        for (final campo in _campos.entries) campo.key: campo.value.text.trim(),
        'avaliacao': 0,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (erro) {
      if (mounted) {
        setState(() {
          _salvando = false;
          _erro = '$erro';
        });
      }
    }
  }

  Widget _campo(String chave, String rotulo, {String? dica}) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: _campos[chave],
      enabled: !_salvando,
      decoration: InputDecoration(labelText: rotulo, hintText: dica),
      maxLength: chave == 'nome' ? 200 : null,
      keyboardType: chave == 'nome'
          ? TextInputType.text
          : TextInputType.datetime,
      inputFormatters: chave == 'nome' ? null : [HorarioInputFormatter()],
      validator: (valor) {
        if (valor == null || valor.trim().isEmpty) {
          return chave == 'fecha'
              ? 'Informe o horário de fechamento.'
              : chave == 'abre'
              ? 'Informe o horário de abertura.'
              : 'Preencha este campo.';
        }
        if ((chave == 'abre' || chave == 'fecha') &&
            !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(valor.trim())) {
          return 'Use o formato HH:mm (ex.: 09:00).';
        }
        return null;
      },
    ),
  );

  Widget _lista(String chave, String rotulo, Map<String, String> opcoes) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: InputDecoration(labelText: rotulo),
          hint: const Text('Selecione uma opção'),
          items: opcoes.entries
              .map(
                (opcao) => DropdownMenuItem(
                  value: opcao.key,
                  child: Text(opcao.value),
                ),
              )
              .toList(),
          onChanged: _salvando
              ? null
              : (valor) => _campos[chave]!.text = valor ?? '',
          validator: (valor) => valor == null ? 'Selecione uma opção.' : null,
        ),
      );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_salvando,
    child: AlertDialog(
      title: const Text('Cadastrar estabelecimento'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Adicione um novo lugar ao catálogo. A nota será calculada pelas avaliações da comunidade.',
                ),
                const SizedBox(height: 24),
                _campo('nome', 'Nome do estabelecimento'),
                _lista('tipo', 'Categoria', const {
                  'bar': 'Bar',
                  'bar/hamburgueria': 'Bar/hamburgueria',
                  'cafeteria': 'Cafeteria',
                  'choperia': 'Choperia',
                  'churrascaria': 'Churrascaria',
                  'espetaria': 'Espetaria',
                  'hamburgueria': 'Hamburgueria',
                  'lanchonete': 'Lanchonete',
                  'pizzaria': 'Pizzaria',
                  'restaurante': 'Restaurante',
                  'sushi bar': 'Sushi bar',
                }),
                _lista('faixa_preco', 'Faixa de preço', const {
                  'barato': 'Barato',
                  'medio': 'Médio',
                  'caro': 'Caro',
                }),
                _lista('ambiente', 'Ambiente', const {
                  'formal': 'Formal',
                  'informal': 'Informal',
                }),
                _lista('publico', 'Público', const {
                  'familia': 'Família',
                  'adulto': 'Adulto',
                  'todos': 'Todos',
                }),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text('Horário de funcionamento · formato 24 horas'),
                ),
                Row(
                  children: [
                    Expanded(child: _campo('abre', 'Abre às', dica: '09:00')),
                    const SizedBox(width: 16),
                    Expanded(child: _campo('fecha', 'Fecha às', dica: '22:00')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (_erro != null)
          SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _erro!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: _salvando ? null : _salvar,
          icon: const Icon(Icons.add_business_outlined),
          label: Text(_salvando ? 'Salvando…' : 'Cadastrar'),
        ),
      ],
    ),
  );
}

/// Insere os dois-pontos ao digitar ou colar quatro dígitos e preserva o cursor.
class HorarioInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    final digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitados = digitos.substring(0, digitos.length.clamp(0, 4));
    final texto = limitados.length <= 2
        ? limitados
        : '${limitados.substring(0, 2)}:${limitados.substring(2)}';
    final posicao = newValue.selection.extentOffset.clamp(
      0,
      newValue.text.length,
    );
    final antes = newValue.text
        .substring(0, posicao)
        .replaceAll(RegExp(r'\D'), '')
        .length
        .clamp(0, limitados.length);
    final cursor = (antes + (antes > 2 ? 1 : 0)).clamp(0, texto.length);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }
}
