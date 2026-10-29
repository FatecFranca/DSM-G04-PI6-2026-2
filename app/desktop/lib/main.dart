import 'package:flutter/material.dart';
import 'package:meu_app/borala.dart';

Future<void> main() async {
  await inicializarBoraLa();
  runApp(const MyApp());
}
