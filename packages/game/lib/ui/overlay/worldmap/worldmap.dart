import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:heavenly_tribulation/ui/view/character/character.dart';
import 'package:path_provider/path_provider.dart' as path;
import 'package:path/path.dart' as path;
import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';

import '../../shared/avatar.dart';
import 'popup.dart';
import '../../shared/popup_submenu_item.dart';
import '../../../shared/json.dart';
import '../../../shared/constants.dart';
import '../../../shared/util.dart';
import 'history_panel.dart';
import '../../shared/loading_screen.dart';
import '../../../global.dart';
import '../../../scene/worldmap.dart';

// This is the type used by the popup menu.
enum TopRightMenuItems { info, viewNone, viewZones, viewNations, exit }

class WorldMapOverlay extends StatefulWidget {
  final WorldMapScene scene;

  const WorldMapOverlay({required Key key, required this.scene})
      : super(key: key);

  @override
  _WorldMapOverlayState createState() => _WorldMapOverlayState();
}

class _WorldMapOverlayState extends State<WorldMapOverlay>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  WorldMapScene get scene => widget.scene;
  TileMap get map => widget.scene.map!;

  Vector2? menuPosition;

  void showCharacter(String characterId) => showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return CharacterView(characterId: characterId);
      });

  @override
  void initState() {
    super.initState();

    engine.registerListener(
      Events.loadedMap,
      EventHandler(widget.key!, (event) {
        setState(() {});
      }),
    );

    engine.registerListener(
      Events.tappedMap,
      EventHandler(widget.key!, (event) {
        if (map.hero!.isMoving) {
          return;
        }
        setState(() {
          final terrain = (event as MapInteractionEvent).terrain;
          if (terrain != null) {
            final tilePos = terrain.tilePosition;
            menuPosition = scene.map!
                .tilePosition2TileCenterInScreen(tilePos.left, tilePos.top);
          }
        });
      }),
    );
  }

  @override
  void dispose() {
    super.dispose();
    engine.disposeListenders(widget.key!);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // pass the build context to script
    engine.invoke('build', positionalArgs: [context]);

    final heroData = engine.invoke('getHero');
    final screenSize = MediaQuery.of(context).size;

    final heroInfoRow = <Widget>[];
    if (heroData != null) {
      heroInfoRow.add(
        Avatar(
          avatarAssetKey: 'assets/images/${heroData['avatar']}',
          size: 100,
          onPressed: () {
            showCharacter(heroData['id']);
            // Navigator.of(context).pushNamed(
            //   'character',
            //   arguments: heroData['id'],
            // );
          },
        ),
      );
    }

    final screenWidgets = <Widget>[
      SizedBox(
        height: screenSize.height,
        width: screenSize.width,
        child: SceneWidget(scene: scene),
      ),
      Positioned(
        left: 0,
        top: 0,
        child: Container(
          width: 180,
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).backgroundColor.withOpacity(0.5),
            borderRadius:
                const BorderRadius.only(bottomRight: Radius.circular(5.0)),
            border: Border.all(
              width: 2,
              color: Colors.lightBlue,
            ),
          ),
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: heroInfoRow,
          ),
        ),
      ),
      Positioned(
        right: 0,
        top: 0,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).backgroundColor,
            borderRadius:
                const BorderRadius.only(bottomLeft: Radius.circular(5.0)),
            border: Border.all(
              width: 2,
              color: Colors.lightBlue,
            ),
          ),
          child: PopupMenuButton<TopRightMenuItems>(
            offset: const Offset(0, 45),
            icon: const Icon(Icons.menu_open),
            tooltip: engine.locale['menu'],
            onSelected: (TopRightMenuItems item) {
              switch (item) {
                case TopRightMenuItems.info:
                  Navigator.of(context).pushNamed('information');
                  break;
                case TopRightMenuItems.viewNone:
                  map.gridMode = GridMode.none;
                  break;
                case TopRightMenuItems.viewZones:
                  map.gridMode = GridMode.zone;
                  break;
                case TopRightMenuItems.viewNations:
                  map.gridMode = GridMode.nation;
                  break;
                case TopRightMenuItems.exit:
                  engine.leaveScene('WorldMap');
                  _saveGame();
                  engine.broadcast(const GameEvent.back2Menu());
                  break;
                default:
              }
            },
            itemBuilder: (BuildContext context) =>
                <PopupMenuEntry<TopRightMenuItems>>[
              PopupMenuItem<TopRightMenuItems>(
                value: TopRightMenuItems.info,
                child: Container(
                  alignment: Alignment.centerLeft,
                  width: 100,
                  child: Text(engine.locale['info']),
                ),
              ),
              PopupSubMenuItem<TopRightMenuItems>(
                title: engine.locale['view'],
                offset: const Offset(-160, 0),
                items: {
                  engine.locale['none']: TopRightMenuItems.viewNone,
                  engine.locale['zone']: TopRightMenuItems.viewZones,
                  engine.locale['nation']: TopRightMenuItems.viewNations,
                },
              ),
              const PopupMenuDivider(),
              PopupMenuItem<TopRightMenuItems>(
                value: TopRightMenuItems.exit,
                child: Container(
                  alignment: Alignment.centerLeft,
                  width: 100,
                  child: Text(engine.locale['exitGame']),
                ),
              ),
            ],
          ),
        ),
      ),
      Positioned(
        left: 0,
        bottom: 0,
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            color: Theme.of(context).backgroundColor.withOpacity(0.5),
            borderRadius:
                const BorderRadius.only(topRight: Radius.circular(5.0)),
            border: Border.all(
              width: 2,
              color: Colors.lightBlue,
            ),
          ),
          padding: const EdgeInsets.all(10.0),
          child: SingleChildScrollView(
            child: HistoryPanel(key: UniqueKey()),
          ),
        ),
      ),
    ];

    if (menuPosition != null) {
      if (map.selectedTerrain != null) {
        final terrain = map.selectedTerrain!;
        final terrainZone = map.zones[terrain.zoneIndex];
        final characters = map.selectedActors;
        final hero = map.hero;
        List<int>? route;
        var isHeroPosition = false;
        if (terrain.tilePosition != hero!.tilePosition) {
          final start = engine.hetu.interpreter
              .invoke('getTerrain', positionalArgs: [hero.left, hero.top]);
          final end = engine.invoke('getTerrain',
              positionalArgs: [terrain.left, terrain.top]);
          List? calculatedRoute = engine.hetu.interpreter
              .invoke('calculateRoute', positionalArgs: [start, end]);
          if (calculatedRoute != null) {
            route = List<int>.from(calculatedRoute);
            // for (var i = 1; i < route.length; ++i) {
            //   final index = route[i];
            //   final tilePosition = map.index2TilePos(index);
            //   engine.info(tilePosition);
            // }
          }
        } else {
          isHeroPosition = true;
        }

        void closePopup() {
          setState(() {
            menuPosition = null;
            scene.map!.selectedTerrain = null;
          });
        }

        final stringBuffer = StringBuffer();

        stringBuffer.writeln('坐标: ${terrain.left}, ${terrain.top}');

        final zoneData = engine.hetu.interpreter
            .invoke('getZoneByIndex', positionalArgs: [terrain.zoneIndex]);
        stringBuffer.writeln('${zoneData['name']}');

        if (terrain.nationId != null) {
          final nationData = engine.hetu.interpreter
              .invoke('getNationById', positionalArgs: [terrain.nationId]);
          stringBuffer.writeln('${nationData['name']}');
        }

        if (terrain.locationId != null) {
          final locationData = engine.hetu.interpreter
              .invoke('getLocationById', positionalArgs: [terrain.locationId]);
          stringBuffer.writeln('${locationData['name']}');
        }

        screenWidgets.add(
          WorldMapPopup(
            left: menuPosition!.x - WorldMapPopup.defaultSize / 2,
            top: menuPosition!.y - WorldMapPopup.defaultSize / 2,
            onPanelTapped: closePopup,
            moveToIcon: route != null,
            onMoveToIconTapped: () {
              map.moveHeroToTilePositionByRoute(route!);
              closePopup();
            },
            checkIcon: terrainZone.index != 0,
            onCheckIconTapped: () {
              if (route != null) {
                map.moveHeroToTilePositionByRoute(route,
                    action: DestinationAction.check);
              } else {
                engine.broadcast(
                    MapInteractionEvent.checkTerrain(terrain: terrain));
              }
              closePopup();
            },
            enterIcon: ((route != null && terrain.locationId != null) ||
                    (isHeroPosition && terrain.locationId != null))
                ? true
                : false,
            onEnterIconTapped: () {
              if (route != null) {
                map.moveHeroToTilePositionByRoute(route,
                    action: DestinationAction.enter);
              } else {
                engine.broadcast(
                    LocationEvent.entered(locationId: terrain.locationId!));
              }
              closePopup();
            },
            talkIcon: characters != null ? true : false,
            onTalkIconTapped: closePopup,
            restIcon: isHeroPosition,
            onRestIconTapped: closePopup,
            title: stringBuffer.toString(),
          ),
        );
      }
    }

    if (!widget.scene.isMapReady) {
      screenWidgets.add(LoadingScreen(text: engine.locale['loading']));
    }

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: screenSize.height,
        width: screenSize.width,
        child: Stack(
          children: screenWidgets,
        ),
      ),
    );
  }

  Future<void> _saveGame() async {
    var savePath = engine.invoke('getSavePath');
    if (savePath == null) {
      final stampName = timestampCrc();
      final directory = await path.getApplicationDocumentsDirectory();
      savePath = path.join(directory.path, 'Heavenly Tribulation', 'save',
          stampName + kSaveFileExtension);
      engine.invoke('setSavePath', positionalArgs: [savePath]);
    }
    final saveFile = File(savePath);
    if (!saveFile.existsSync()) {
      saveFile.createSync(recursive: true);
    }
    final gameJsonData = engine.invoke('getGameJsonData');
    final gameStringData = jsonEncodeWithIndent(gameJsonData);
    saveFile.writeAsStringSync(gameStringData);
  }
}
