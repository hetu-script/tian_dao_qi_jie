import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:samsara/cardgame/card.dart';
import 'package:json5/json5.dart';
import 'package:samsara/samsara.dart';

import 'ui.dart';
import 'common.dart';
import 'config.dart';

abstract class GameData {
  static Map<String, dynamic> cardData = {};
  static Map<String, dynamic> animationData = {};
  static Map<String, dynamic> statusEffectData = {};

  static Map<String, String> organizationCategoryNames = {};
  static Map<String, String> cultivationGenreNames = {};
  static Map<String, String> constructableSiteCategoryNames = {};

  static bool _isLoaded = false;
  static bool get isLoaded => _isLoaded;

  static Future<void> load() async {
    final cardsDataString =
        await rootBundle.loadString('assets/data/cards.json5');
    cardData = JSON5.parse(cardsDataString);

    final animationDataString =
        await rootBundle.loadString('assets/data/animation.json5');
    animationData = JSON5.parse(animationDataString);

    final statusEffectDataString =
        await rootBundle.loadString('assets/data/status_effect.json5');
    statusEffectData = JSON5.parse(statusEffectDataString);

    for (final key in kOrganizationCategories) {
      organizationCategoryNames[key] = engine.locale(key);
    }
    for (final key in kCultivationGenres) {
      cultivationGenreNames[key] = engine.locale(key);
    }
    for (final key in kConstructableSiteCategories) {
      constructableSiteCategoryNames[key] = engine.locale(key);
    }

    _isLoaded = true;
  }

  static Card getSiteCard(dynamic siteData) {
    final id = siteData['id'];
    final card = Card(
      id: id,
      deckId: id,
      data: siteData,
      anchor: Anchor.center,
      borderRadius: 15.0,
      illustrationSpriteId: siteData['image'],
      spriteId: 'location/site/site_frame.png',
      title: siteData['name'],
      titleStyle: ScreenTextStyle(textStyle: const TextStyle(fontSize: 20.0)),
      showTitle: true,
      enablePreview: true,
      focusOnPreviewing: true,
      focusedPriority: 500,
      focusedSize: GameUI.siteCardFocusedSize,
      focusedOffset: Vector2(
          (GameUI.siteCardFocusedSize.x - GameUI.siteCardSize.x) / 2,
          (GameUI.siteCardSize.y - GameUI.siteCardFocusedSize.y) / 2),
    );
    return card;
  }

  static Card getBattleCard(String cardId) {
    assert(_isLoaded, 'GameData is not loaded yet!');
    assert(GameUI.isInitted, 'Game UI is not initted yet!');

    final data = cardData[cardId];
    assert(data != null, 'Failed to load card data: [$cardId]');
    final String id = data['id'];

    return Card(
      id: id,
      deckId: id,
      script: id,
      data: data,
      // title: data['title'][engine.locale.languageId],
      // description: data['rules'][engine.locale.languageId],
      size: GameUI.libraryCardSize,
      spriteId: 'card/library/$id.png',
      // focusedPriority: 1000,
      // illustrationSpriteId: 'cards/illustration/$id.png',
      // illustrationHeightRatio: kCardIllustrationHeightRatio,
      // showTitle: true,
      // titleStyle: const ScreenTextStyle(
      //   colorTheme: ScreenTextColorTheme.light,
      //   anchor: Anchor.topCenter,
      //   padding: EdgeInsets.only(
      //       top: kLibraryCardHeight * kCardIllustrationHeightRatio),
      //   textStyle: TextStyle(fontSize: 16),
      // ),
      // showDescription: true,
      // descriptionStyle: const ScreenTextStyle(
      //   colorTheme: ScreenTextColorTheme.dark,
      // ),
    );
  }

  static Future<void> registerModuleEventHandlers() async {
    if (kDebugMode) {
      for (final key in GameConfig.modules.keys) {
        if (GameConfig.modules[key]?['enabled'] == true) {
          if (GameConfig.modules[key]?['preinclude'] == true) {
            engine.loadModFromAssetsString(
              '$key/main.ht',
              module: key,
            );
          }
        }
      }
    } else {
      for (final key in GameConfig.modules.keys) {
        if (GameConfig.modules[key]?['enabled'] == true) {
          if (GameConfig.modules[key]?['preinclude'] == true) {
            final mod = await rootBundle.load('assets/mods/$key.mod');
            final modBytes = mod.buffer.asUint8List();
            engine.loadModFromBytes(
              modBytes,
              moduleName: key,
            );
          }
        }
      }
    }
  }

  static bool isGameCreated = false;

  static Future<void> newGame(String worldId, [String? saveName]) async {
    worldIds.clear();
    currentWorldId = worldId;
    worldIds.add(worldId);

    engine.hetu.invoke('resetGame');
    if (saveName != null) {
      engine.hetu.invoke('setSaveName', positionalArgs: [saveName]);
    }

    await registerModuleEventHandlers();

    isGameCreated = true;
  }

  static String? currentWorldId;
  static Set<String> worldIds = {};

  static Future<void> loadGame(String savePath,
      {bool isEditorMode = false}) async {
    worldIds.clear();
    currentWorldId = null;
    engine.info('从 [$savePath] 载入游戏存档。');
    final gameSave = await File(savePath).open();
    final gameDataString = utf8.decoder
        .convert((await gameSave.read(await gameSave.length())).toList());
    await gameSave.close();
    final gameData = jsonDecode(gameDataString);
    final universeSave = await File(savePath + kUniverseSaveFilePostfix).open();
    final universeDataString = utf8.decoder.convert(
        (await universeSave.read(await universeSave.length())).toList());
    await universeSave.close();
    final universeData = jsonDecode(universeDataString);
    final historySave = await File(savePath + kHistorySaveFilePostfix).open();
    final historyDataString = utf8.decoder
        .convert((await historySave.read(await historySave.length())).toList());
    await historySave.close();
    final historyData = jsonDecode(historyDataString);

    final ids = engine.hetu.invoke('loadGameFromJsonData', namedArgs: {
      'gameData': gameData,
      'universeData': universeData,
      'historyData': historyData,
      'isEditorMode': isEditorMode,
    });

    currentWorldId = engine.hetu.invoke('getCurrentWorldId');

    for (final id in ids) {
      worldIds.add(id);
    }

    await registerModuleEventHandlers();

    isGameCreated = true;
  }

  static Future<void> loadPreset(String filename) async {
    final gameSave = 'assets/save/$filename$kGameSaveFileExtension';
    final gameDataString = await rootBundle.loadString(gameSave);
    final gameData = jsonDecode(gameDataString);

    final universeSave = '$gameSave$kUniverseSaveFilePostfix';
    final universeDataString = await rootBundle.loadString(universeSave);
    final universeData = jsonDecode(universeDataString);

    final historySave = '$gameSave$kHistorySaveFilePostfix';
    final historyDataString = await rootBundle.loadString(historySave);
    final historyData = jsonDecode(historyDataString);

    final ids = engine.hetu.invoke('loadGameFromJsonData', namedArgs: {
      'gameData': gameData,
      'universeData': universeData,
      'historyData': historyData,
    });

    currentWorldId = engine.hetu.invoke('getCurrentWorldId');

    for (final id in ids) {
      worldIds.add(id);
    }

    await registerModuleEventHandlers();

    isGameCreated = true;
  }
}

abstract class PresetDecks {
  static List<Card> _getCards(List<String> cardIds) {
    return cardIds.map((e) => GameData.getBattleCard(e)).toList();
  }

  static const List<String> _basic = [
    'defend_normal',
    'attack_normal',
    'attack_normal',
    'attack_normal',
  ];

  static const List<String> _blade_1 = [
    'defend_normal',
    'blade_4',
    'blade_3',
    'blade_1',
  ];

  static const List<String> _blade_2 = [
    'blade_4',
    'blade_6',
    'blade_7',
    'blade_8',
  ];

  static const List<String> _blade_3 = [
    'blade_9',
    'blade_10',
    'blade_7',
    'blade_8',
  ];

  static const _allDecks = [
    _basic,
    ..._bladeDecks,
  ];

  static const _bladeDecks = [
    _blade_1,
    _blade_2,
    _blade_3,
  ];

  static List<Card> get random => _getCards(_allDecks.random());
  static List<Card> get randomBlade => _getCards(_bladeDecks.random());

  static List<Card> get basic => _getCards(_basic);
  static List<Card> get blade1 => _getCards(_blade_1);
  static List<Card> get blade2 => _getCards(_blade_2);
  static List<Card> get blade3 => _getCards(_blade_3);
}
