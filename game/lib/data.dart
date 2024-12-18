import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:samsara/cardgame/cardgame.dart';
import 'package:json5/json5.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/utils/json.dart';
import 'package:hetu_script/utils/uid.dart';

import 'ui.dart';
import 'common.dart';
import 'config.dart';

/// 游戏数据，大部分以JSON或者Hetu Struct形式保存
/// 这个类是纯静态类，方法都是有关读取和保存的
/// 游戏逻辑等操作这些数据的代码另外写在logic目录下的文件中
abstract class GameData {
  static Map<String, dynamic> editorToolItemsData = {};
  static Map<String, dynamic> cardsData = {};
  static Map<String, dynamic> cardsMainAffixData = {};
  static Map<String, dynamic> cardsSupportAffixData = {};
  static Map<String, dynamic> animationsData = {};
  static Map<String, dynamic> statusEffectsData = {};
  static Map<String, dynamic> itemsData = {};

  static Map<String, String> organizationCategoryNames = {};
  static Map<String, String> cultivationGenreNames = {};
  static Map<String, String> constructableSiteCategoryNames = {};

  static dynamic data;

  static BuildContext? ctx;

  static bool _isInitted = false;
  static bool get isInitted => _isInitted;

  static Future<void> init(BuildContext context) async {
    final editorToolItemsString =
        await rootBundle.loadString('assets/data/editor_tools.json5');
    editorToolItemsData = JSON5.parse(editorToolItemsString);

    final cardsDataString =
        await rootBundle.loadString('assets/data/cards.json5');
    cardsData = JSON5.parse(cardsDataString);

    final cardsMainAffixDataString =
        await rootBundle.loadString('assets/data/card_main_affixes.json5');
    cardsMainAffixData = JSON5.parse(cardsMainAffixDataString);

    final animationDataString =
        await rootBundle.loadString('assets/data/animation.json5');
    animationsData = JSON5.parse(animationDataString);

    final statusEffectDataString =
        await rootBundle.loadString('assets/data/status_effect.json5');
    statusEffectsData = JSON5.parse(statusEffectDataString);

    final itemsDataString =
        await rootBundle.loadString('assets/data/items.json5');
    itemsData = JSON5.parse(itemsDataString);

    for (final key in kOrganizationCategories) {
      organizationCategoryNames[key] = engine.locale(key);
    }
    for (final key in kMainCultivationGenres) {
      cultivationGenreNames[key] = engine.locale(key);
    }
    for (final key in kConstructableSiteCategories) {
      constructableSiteCategoryNames[key] = engine.locale(key);
    }

    ctx = context;
    engine.hetu.invoke('build', positionalArgs: [context]);

    _isInitted = true;
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

  /// wether started a new game or load from a save.
  static bool isGameCreated = false;

  static Future<void> newGame(String worldId, [String? saveName]) async {
    worldIds.clear();
    currentWorldId = worldId;
    worldIds.add(worldId);

    data = engine.hetu.invoke('newGame', positionalArgs: [saveName]);

    await registerModuleEventHandlers();

    isGameCreated = true;
  }

  static String? currentWorldId;
  static Set<String> worldIds = {};

  static Future<void> _loadGame({
    required dynamic gameData,
    required dynamic universeData,
    required dynamic historyData,
    bool isEditorMode = false,
  }) async {
    data = engine.hetu.invoke('loadGameFromJsonData', namedArgs: {
      'gameData': gameData,
      'universeData': universeData,
      'historyData': historyData,
      'isEditorMode': isEditorMode,
    });

    currentWorldId = engine.hetu.invoke('getCurrentWorldId');

    final ids = engine.hetu.invoke('getWorldIds');

    for (final id in ids) {
      worldIds.add(id);
    }

    await registerModuleEventHandlers();

    isGameCreated = true;
  }

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

    await _loadGame(
      gameData: gameData,
      universeData: universeData,
      historyData: historyData,
      isEditorMode: isEditorMode,
    );
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

    await _loadGame(
      gameData: gameData,
      universeData: universeData,
      historyData: historyData,
      isEditorMode: false,
    );
  }

  static CustomGameCard getSiteCard(dynamic siteData) {
    final id = siteData['id'];
    final card = CustomGameCard(
      id: id,
      deckId: id,
      data: siteData,
      anchor: Anchor.center,
      borderRadius: 15.0,
      illustrationSpriteId: siteData['image'],
      spriteId: 'location/site/site_frame.png',
      title: siteData['name'],
      titleConfig: const ScreenTextConfig(textStyle: TextStyle(fontSize: 20.0)),
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

  static dynamic generateBattleCardData({
    String? genre,
    int level = 1, // 卡牌等级最小是1，最大是40
  }) {
    assert(_isInitted, 'Game data is not loaded yet!');

    if (genre != null) {
      assert(
          kMainCultivationGenres.contains(genre) ||
              kSupportCultivationGenres.contains(genre) ||
              genre == 'general',
          'Unknown cultivation genre: $genre');
    }

    final mainAffixes = cardsMainAffixData.values.where((affix) {
      final List genres = affix['genre'];

      if (genre != null) {
        return genres.contains(genre);
      } else {
        return true;
      }
    });

    assert(mainAffixes.isNotEmpty);

    final mainAffix = jsonCopy(mainAffixes.random);

    return {
      'id': '${DateTime.now().toYMDHHMMSS2()}_${randomUID()}',
      'level': level,
      'main': mainAffix,
      'support': [],
    };
  }

  static CustomGameCard createBattleCardByData(dynamic data) {
    assert(data != null, 'Invalid battle card data!');
    assert(_isInitted, 'Game data is not loaded yet!');
    assert(GameUI.isInitted, 'Game UI is not initted yet!');

    // final data = generateBattleCardAffixes(genre: genre);
    // assert(data != null, 'Failed to generate card data! (genre: $genre)');

    final String image = data['main']['image'];

    final String id = data['id'];
    final String title = engine.locale('battleCard.${data['main']['id']}.name');
    final int level = data['level'];

    final description = StringBuffer();
    final genreString =
        '${engine.locale('genre')}: ${engine.locale(data['main']['genre'])}';
    description.writeln(genreString);
    final typeString =
        '${engine.locale('type')}: ${engine.locale('battleCardType.${data['main']['type']}')}';
    description.writeln(typeString);
    final levelString = '${engine.locale('level')}: $level';
    description.writeln(levelString);

    final extraDescription = StringBuffer();
    extraDescription.writeln('<bold>$title</>');
    extraDescription.writeln('<grey>$genreString</>');
    extraDescription.writeln('<grey>$typeString</>');
    extraDescription.writeln('<grey>$levelString</>');
    extraDescription.writeln('——————————————');

    final String affixId = data['main']['id'];
    final mainAffixDescriptionRaw =
        engine.locale('battleCard.$affixId.description');
    final List<String> values = [];
    final mainAffixValues = data['main']['value'];
    final r = math.Random();
    for (final value in mainAffixValues) {
      final random = value['random'] = r.nextDouble();
      final int min = value['min'];
      final int max = value['max'];
      final int increment = value['increment'];
      final double finalValue =
          min + (max - min) * random + r.nextInt(level) * increment;
      values.add(finalValue.round().toString());
    }
    final mainAffixLine =
        '<lightBlue>${mainAffixDescriptionRaw.interpolate(values)}</>';
    extraDescription.writeln(mainAffixLine);

    return CustomGameCard(
      id: id,
      // deckId: id,
      data: data,
      preferredSize: GameUI.libraryCardSize,
      spriteId: 'cultivation/battlecard/border3.png',
      illustrationRelativePaddings:
          const EdgeInsets.fromLTRB(0.06, 0.04, 0.06, 0.388),
      illustrationSpriteId: 'cultivation/battlecard/illustration/$image',
      title: title,
      titleRelativePaddings:
          const EdgeInsets.fromLTRB(0.08, 0.625, 0.08, 0.469),
      titleConfig: const ScreenTextConfig(
        anchor: Anchor.topCenter,
        outlined: true,
        textStyle: TextStyle(
          fontFamily: 'RuiZiYunZiKuLiBianTiGBK',
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
        ),
      ),
      descriptionRelativePaddings:
          const EdgeInsets.fromLTRB(0.08, 0.735, 0.08, 0.08),
      descriptionConfig: const ScreenTextConfig(
        anchor: Anchor.center,
        textStyle: TextStyle(
          fontFamily: 'NotoSansMono',
          fontSize: 11.0,
          color: Colors.black,
        ),
        overflow: ScreenTextOverflow.wordwrap,
      ),
      description: mainAffixLine,
      extraDescription: extraDescription.toString(),
    );
  }

  static GameCard getBattleCardById(String cardId) {
    assert(_isInitted, 'Game data is not loaded yet!');
    assert(GameUI.isInitted, 'Game UI is not initted yet!');

    final data = cardsData[cardId];
    assert(data != null, 'Failed to load card data: [$cardId]');
    final String id = data['id'];

    return GameCard(
      id: id,
      deckId: id,
      script: id,
      data: data,
      // title: data['title'][engine.locale.languageId],
      // description: data['rules'][engine.locale.languageId],
      size: GameUI.libraryCardSize,
      spriteId: 'cultivation/library/$id.png',
      // focusedPriority: 1000,
      // illustrationSpriteId: 'cards/illustration/$id.png',
      // illustrationHeightRatio: kCardIllustrationHeightRatio,
      // showTitle: true,
      // titleStyle: const ScreenTextConfig(
      //   colorTheme: ScreenTextColorTheme.light,
      //   anchor: Anchor.topCenter,
      //   padding: EdgeInsets.only(
      //       top: kLibraryCardHeight * kCardIllustrationHeightRatio),
      //   textStyle: TextStyle(fontSize: 16),
      // ),
      // showDescription: true,
      // descriptionStyle: const ScreenTextConfig(
      //   colorTheme: ScreenTextColorTheme.dark,
      // ),
    );
  }
}

abstract class PrebuildDecks {
  // static List<GameCard> _getCards(List<String> cardIds) {
  //   return cardIds.map((e) => GameData.getBattleCard(e)).toList();
  // }

  // static const List<String> _basic = [
  //   'defend_normal',
  //   'attack_normal',
  //   'attack_normal',
  //   'attack_normal',
  // ];

  // static const List<String> _blade_1 = [
  //   'defend_normal',
  //   'blade_4',
  //   'blade_3',
  //   'blade_1',
  // ];

  // static const List<String> _blade_2 = [
  //   'blade_4',
  //   'blade_6',
  //   'blade_7',
  //   'blade_8',
  // ];

  // static const List<String> _blade_3 = [
  //   'blade_9',
  //   'blade_10',
  //   'blade_7',
  //   'blade_8',
  // ];

  // static const _allDecks = [
  //   _basic,
  //   ..._bladeDecks,
  // ];

  // static const _bladeDecks = [
  //   _blade_1,
  //   _blade_2,
  //   _blade_3,
  // ];

  // static List<GameCard> get random => _getCards(_allDecks.random());
  // static List<GameCard> get randomBlade => _getCards(_bladeDecks.random());

  // static List<GameCard> get basic => _getCards(_basic);
  // static List<GameCard> get blade1 => _getCards(_blade_1);
  // static List<GameCard> get blade2 => _getCards(_blade_2);
  // static List<GameCard> get blade3 => _getCards(_blade_3);
}
