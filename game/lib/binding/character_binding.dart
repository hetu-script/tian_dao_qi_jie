import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';
import 'package:flutter/material.dart' show Colors;

import '../scene/battle/character.dart';

class BattleCharacterClassBinding extends HTExternalClass {
  BattleCharacterClassBinding() : super(r'BattleCharacter');

  @override
  dynamic instanceMemberGet(dynamic instance, String varName,
      {bool ignoreUndefined = false}) {
    var character = instance as BattleCharacter;
    switch (varName) {
      case 'data':
        return character.data;
      case 'life':
        return character.life;
      case 'lifeMax':
        return character.lifeMax;
      case 'addHintText':
        return ({positionalArgs, namedArgs}) {
          final color = switch (namedArgs['color']) {
            _ => Colors.white,
          };
          character.addHintText(positionalArgs.first, color: color);
        };
      case 'changeLife':
        return ({positionalArgs, namedArgs}) => character
            .changeLife(positionalArgs[0], playSound: namedArgs['playSound']);
      case 'takeDamage':
        return ({positionalArgs, namedArgs}) {
          return character.takeDamage(positionalArgs.first);
        };
      case 'setState':
        return ({positionalArgs, namedArgs}) => character.setState(
              positionalArgs.first,
              overlay: namedArgs['overlay'],
              recovery: namedArgs['recovery'],
              complete: namedArgs['complete'],
              sound: namedArgs['sound'],
            );
      case 'hasStatusEffect':
        return ({positionalArgs, namedArgs}) =>
            character.hasStatusEffect(positionalArgs.first);
      case 'removeStatusEffect':
        return ({positionalArgs, namedArgs}) => character.removeStatusEffect(
              positionalArgs[0],
              amount: namedArgs['amount'],
              percentage: namedArgs['percentage'],
              hintLacking: namedArgs['hintLacking'],
            );
      case 'addStatusEffect':
        return ({positionalArgs, namedArgs}) => character
            .addStatusEffect(positionalArgs[0], amount: namedArgs['amount']);
      case 'setTurnFlag':
        return ({positionalArgs, namedArgs}) =>
            character.setTurnFlag(positionalArgs[0], positionalArgs[1]);
      case 'getTurnFlag':
        return ({positionalArgs, namedArgs}) =>
            character.getTurnFlag(positionalArgs[0]);
      case 'removeTurnFlag':
        return ({positionalArgs, namedArgs}) =>
            character.removeTurnFlag(positionalArgs[0]);
      case 'getGameFlag':
        return ({positionalArgs, namedArgs}) =>
            character.getGameFlag(positionalArgs[0]);

      default:
        if (!ignoreUndefined) throw HTError.undefined(varName);
    }
  }
}
