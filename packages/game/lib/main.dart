import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:heavenly_tribulation/ui/view/information/information.dart';

import 'ui/view/location.dart';
import 'ui/game_app.dart';
import 'ui/editor/editor.dart';
import 'ui/view/character.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Flame.device.setPortraitDownOnly();
  await Flame.device.fullScreen();

  runApp(
    MaterialApp(
      title: 'Tian Dao Qi Jie',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
          scrollbarTheme: const ScrollbarThemeData().copyWith(
        thumbColor: MaterialStateProperty.all(Colors.grey),
      )),
      home: GameApp(key: UniqueKey()),
      routes: {
        'location': (context) => LocationView(key: UniqueKey()),
        'information': (context) => const InformationPanel(),
        'character': (context) => const CharacterView(),
        'editor': (context) => const GameEditor(),
      },
    ),
  );
}
