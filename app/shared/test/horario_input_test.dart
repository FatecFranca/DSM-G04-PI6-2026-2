import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meu_app/components/cadastro_estabelecimento_dialog.dart';

void main() {
  final mascara = HorarioInputFormatter();
  TextEditingValue editar(String texto, {int? cursor}) => mascara.formatEditUpdate(
    TextEditingValue.empty,
    TextEditingValue(text: texto, selection: TextSelection.collapsed(offset: cursor ?? texto.length)),
  );

  test('horario insere separador e aceita colagem com ou sem mascara', () {
    expect(editar('1900').text, '19:00');
    expect(editar('09:30').text, '09:30');
    expect(editar('123456').text, '12:34');
    expect(editar('').text, '');
  });

  test('horario permite apagar e conserva cursor na edicao', () {
    expect(editar('19:0').text, '19:0');
    expect(editar('19:').text, '19');
    expect(editar('19:30', cursor: 4).selection.extentOffset, 4);
  });
}
