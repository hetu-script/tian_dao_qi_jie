import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:heavenly_tribulation/ui/overlay/cardgame/deckbuilding.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:samsara/samsara.dart';
// import 'package:samsara/event.dart';
import 'package:window_manager/window_manager.dart';
import 'package:hetu_script/values.dart';
import 'package:samsara/flutter_ui/loading_screen.dart';
import 'package:samsara/flutter_ui/label.dart';
import 'package:samsara/utils/console.dart';
import 'package:json5/json5.dart';

import 'overlay/maze/maze.dart';
import '../global.dart';
import '../shared/constants.dart';
import '../../shared/datetime.dart';
import 'load_game_dialog.dart';
import '../binding/external_game_functions.dart';
import '../scene/worldmap.dart';
import '../scene/maze.dart';
import 'create_game_dialog.dart';
// import '../event/events.dart';
import 'overlay/worldmap/worldmap.dart';
import '../scene/cardgame/cardgame_autobattler.dart';
import '../scene/cardgame/deckbuilding.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  GameLocalization get locale => engine.locale;

  // 模组信息，key是模组名字，value代表是否启用
  final _modsInfo = <String, bool>{
    'story': true,
  };

  final _savedFiles = <SaveInfo>[];

  @override
  void initState() {
    super.initState();

    engine.registerSceneConstructor('worldmap', ([dynamic args]) async {
      engine.invoke('resetGame');

      var isFirstLoad = false;

      // 因为生成世界时会触发一些mod的回调函数，因此需要先载入 mod 数据
      for (final key in _modsInfo.keys) {
        if (_modsInfo[key] == true) {
          engine.invoke('load', moduleName: key);
        }
      }

      HTStruct worldData;
      final path = args!['path1'];
      if (path != null) {
        final gameSavePath = File(path);
        final gameDataString = gameSavePath.readAsStringSync();
        final gameData = jsonDecode(gameDataString);
        final mapSavePath = File(args!['path2']);
        final mapDataString = mapSavePath.readAsStringSync();
        final mapData = jsonDecode(mapDataString);
        engine.info('从 [$path] 载入游戏存档。');
        worldData = engine.invoke('loadGameFromJsonData',
            positionalArgs: [gameData, mapData]);
      } else {
        worldData = engine.invoke('createWorldMap', namedArgs: args);
        engine.invoke('enterWorld', positionalArgs: [worldData]);
        isFirstLoad = true;
      }

      return WorldMapScene(
        worldData: worldData,
        controller: engine,
        captionStyle: captionStyle,
        isFirstLoad: isFirstLoad,
      );
    });

    engine.registerSceneConstructor('maze', ([dynamic data]) async {
      return MazeScene(
        mapData: data!,
        controller: engine,
        captionStyle: captionStyle,
      );
    });

    engine.registerSceneConstructor('cardGame', ([dynamic data]) async {
      return CardGameAutoBattlerScene(
        controller: engine,
        arg: data,
      );
    });

    engine.registerSceneConstructor('deckBuilding', ([dynamic data]) async {
      return DeckBuildingScene(
        controller: engine,
        deckData: data,
      );
    });
  }

  Future<void> refreshSaves() async {
    _savedFiles.clear();
    _savedFiles.addAll(await _getSavedFiles());
  }

  // 因为 FutureBuilder根据返回值是否为null来判断，因此这里无论如何要返回一个值
  Future<bool?> _prepareData() async {
    await refreshSaves();

    if (engine.isLoaded) {
      engine.invoke('build', positionalArgs: [context]);
      return false;
    }

    await engine.init(externalFunctions: externalGameFunctions);
    if (kDebugMode) {
      engine.loadModFromAssetsString(
        'game/main.ht',
        moduleName: 'game',
        namedArgs: {'lang': 'zh', 'gameEngine': engine},
        isMainMod: true,
      );
      for (final key in _modsInfo.keys) {
        if (_modsInfo[key] == true) {
          engine.loadModFromAssetsString(
            '$key/main.ht',
            moduleName: key,
          );
        }
      }
    } else {
      final game = await rootBundle.load('assets/mods/game.mod');
      final gameBytes = game.buffer.asUint8List();
      engine.loadModFromBytes(
        gameBytes,
        moduleName: 'game',
        namedArgs: {'lang': 'zh', 'gameEngine': engine},
        isMainMod: true,
      );
      for (final key in _modsInfo.keys) {
        if (_modsInfo[key] == true) {
          final mod = await rootBundle.load('assets/mods/$key.mod');
          final modBytes = mod.buffer.asUint8List();
          engine.loadModFromBytes(
            modBytes,
            moduleName: key,
          );
        }
      }
    }

    final cardsDataString =
        await rootBundle.loadString('scripts/game/card/card.json5');
    final data = JSON5.parse(cardsDataString);
    for (final obj in data) {
      final id = obj['id'];
      assert(id != null);
      cardsData[id] = obj;
    }

    engine.invoke('build', positionalArgs: [context]);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _prepareData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return LoadingScreen(
              text: engine.isLoaded ? engine.locale['loading'] : 'Loading...');
        } else {
          final menus = <Widget>[
            // const Padding(
            //   padding: EdgeInsets.only(top: 150),
            //   child: Image(
            //     image: AssetImage('assets/images/title.png'),
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.only(top: 40.0),
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const CreateGameDialog(),
                  ).then((value) {
                    if (value != null) {
                      showDialog(
                        context: context,
                        builder: (context) => WorldMapOverlay(
                          key: UniqueKey(),
                          args: value,
                        ),
                      ).then((_) {
                        engine.invoke('build', positionalArgs: [context]);
                        setState(() {});
                      });
                    }
                  });
                },
                child: Label(
                  locale['sandboxMode'],
                  width: 100.0,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  LoadGameDialog.show(context, list: _savedFiles)
                      .then((SaveInfo? info) {
                    if (info != null) {
                      showDialog(
                        context: context,
                        builder: (context) => WorldMapOverlay(
                          key: UniqueKey(),
                          args: {
                            "id": info.worldId,
                            "path1": info.savepath1,
                            "path2": info.savepath2,
                          },
                        ),
                      ).then((_) {
                        engine.invoke('build', positionalArgs: [context]);
                        setState(() {});
                      });
                    } else {
                      if (_savedFiles.isEmpty) {
                        setState(() {});
                      }
                    }
                  });
                },
                child: Label(
                  locale['loadGame'],
                  width: 100.0,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: ElevatedButton(
                onPressed: () {
                  // Navigator.of(context).pushNamed('editor');
                },
                child: Label(
                  locale['gameEditor'],
                  width: 100.0,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (Global.isOnDesktop) ...[
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    windowManager.close();
                  },
                  child: Label(
                    locale['exit'],
                    width: 100.0,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ];

          final debugMenus = <Widget>[
            Positioned(
              right: 20.0,
              bottom: 20.0,
              width: 200.0,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const DeckBuildingOverlay(),
                        );
                      },
                      child: const Label(
                        'Test Deckbuilding',
                        width: 200.0,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return Material(
                              type: MaterialType.transparency,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final mazeData =
                                            engine.invoke('testMazeMountain');
                                        showDialog(
                                          context: context,
                                          builder: (context) => MazeOverlay(
                                            key: UniqueKey(),
                                            mazeData: mazeData,
                                          ),
                                        );
                                      },
                                      child: const Text('mountain'),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final mazeData = engine.invoke(
                                            'testMazeCultivationRecruit');
                                        showDialog(
                                          context: context,
                                          builder: (context) => MazeOverlay(
                                            key: UniqueKey(),
                                            mazeData: mazeData,
                                          ),
                                        );
                                      },
                                      child: const Text('cultivation recruit'),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('close'),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ).then(
                          (_) {
                            engine.invoke('build', positionalArgs: [context]);
                            setState(() {});
                          },
                        );
                      },
                      child: const Label(
                        'Test Maze',
                        width: 200.0,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) =>
                              Console(engine: engine),
                        ).then((_) => setState(() {
                              engine.invoke('build', positionalArgs: [context]);
                            }));
                      },
                      child: const Label(
                        'Console',
                        width: 200.0,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ];

          return Scaffold(
            body: Global.isPortraitMode
                ? Container(
                    color: Global.appTheme.colorScheme.background,
                    // decoration: const BoxDecoration(
                    //   image: DecorationImage(
                    //     fit: BoxFit.fill,
                    //     image: AssetImage('assets/images/bg/background_01.jpg'),
                    //   ),
                    // ),
                    alignment: Alignment.center,
                    child: Column(children: menus),
                  )
                : Stack(
                    children: [
                      Positioned(
                        left: 20.0,
                        bottom: 20.0,
                        height: 300.0,
                        width: 120.0,
                        child: Column(children: menus),
                      ),
                      if (engine.config.debugMode) ...debugMenus,
                    ],
                  ),
          );
        }
      },
    );
  }

  Future<List<SaveInfo>> _getSavedFiles() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final saveFolder =
        path.join(appDirectory.path, 'Heavenly Tribulation', 'save');

    final list = <SaveInfo>[];
    final saveDirectory = Directory(saveFolder);
    if (saveDirectory.existsSync()) {
      for (final entity in saveDirectory.listSync()) {
        if (entity is File &&
            path.extension(entity.path) == kGameSaveFileExtension) {
          final worldId = path.basenameWithoutExtension(entity.path);
          final d = entity.lastModifiedSync().toLocal();
          final saveInfo = SaveInfo(
            worldId: worldId,
            timestamp: d.toMeaningfulString(),
            savepath1: entity.path,
            savepath2: '${entity.path}$kUniverseSaveFilePostfix',
          );
          list.add(saveInfo);
        }
      }
    }
    return list;
  }
}
