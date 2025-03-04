import 'package:flutter/material.dart';

import '../engine.dart';
import 'common.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key, required this.historyData});

  final Iterable<dynamic> historyData;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

    for (final index in historyData) {
      final incident =
          engine.hetu.invoke('getIncidentByIndex', positionalArgs: [index]);
      widgets.add(Text(incident['message']));
    }

    return Container(
      padding: const EdgeInsets.all(10),
      height: MediaQuery.of(context).size.height - kTabBarHeight,
      child: SingleChildScrollView(
        child: ListView(
          shrinkWrap: true,
          children: widgets,
        ),
      ),
    );
  }
}
