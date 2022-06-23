import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';

import '../global.dart';

class WorldMapScene extends Scene {
  late final TileMap map;

  Map<String, dynamic> jsonData;

  WorldMapScene({required this.jsonData, required super.controller})
      : super(key: 'worldmap');

  bool isMapReady = false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    map = await TileMap.fromJson(data: jsonData, engine: engine);
    add(map);
    isMapReady = true;
    engine.broadcast(MapLoadedEvent(isNewGame: jsonData['isNewGame'] ?? false));
  }
}
