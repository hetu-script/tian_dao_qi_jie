import 'package:flutter/foundation.dart';
import 'package:samsara/samsara.dart';

import '../config.dart';

class HistoryState with ChangeNotifier {
  List<dynamic> incidents = [];

  void update({
    int count = 20,
    bool onlyHero = true,
  }) {
    final String? heroId = engine.hetu.invoke('getHeroId');
    if (heroId == null && onlyHero) return;

    final Iterable history =
        engine.hetu.fetch('timeline')['incidents'].reversed;
    incidents.clear();
    final iter = history.iterator;
    var i = 0;
    while (iter.moveNext() && i < count) {
      final incident = iter.current;
      if (incident['subjectId'] == heroId ||
          incident['objectId'] == heroId ||
          incident['isGlobal']) {
        incidents.add(incident);
        ++i;
      }
    }
    incidents.reverse();
    notifyListeners();
  }
}
