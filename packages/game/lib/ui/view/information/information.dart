import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/ui/view/character/character.dart';
import 'package:hetu_script/values.dart' show HTStruct;

import '../../../global.dart';
import 'game_entity_listview.dart';
import '../../shared/constants.dart';
import '../../shared/responsive_route.dart';
import '../../shared/close_button.dart';

const kInformationViewCharacterColumns = [
  'name',
  'currentLocation',
  'organization',
  'fame',
  // 'infamy',
];

const kInformationViewNationColumns = [
  'name',
  'capital',
  'gridSize',
  'locationNumber',
  'organizationNumber',
];

const kInformationViewLocationColumns = [
  'name',
  'nation',
  'organization',
  'category',
  'development',
];

const kInformationViewOrganizationColumns = [
  'name',
  'leader',
  'headquartersLocation',
  'locationNumber',
  'memberNumber',
  'development',
];

class InformationPanel extends StatefulWidget {
  const InformationPanel({Key? key}) : super(key: key);

  @override
  State<InformationPanel> createState() => _InformationPanelState();
}

class _InformationPanelState extends State<InformationPanel>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final HTStruct _nationsData,
      _locationsData,
      _organizationsData,
      _charactersData;

  final List<List<String>> _nationsFieldRow = [],
      _locationsFieldRow = [],
      _organizationsFieldRow = [],
      _charactersFieldRow = [];

  @override
  void initState() {
    super.initState();

    updateData();
  }

  void updateData() {
    _nationsFieldRow.clear();
    _locationsFieldRow.clear();
    _organizationsFieldRow.clear();
    _charactersFieldRow.clear();

    _nationsData = engine.invoke('getNations');
    for (final nation in _nationsData.values) {
      final rowData = <String>[];
      // 国家名字
      rowData.add(nation['name']);
      // 首都名字
      final location = engine.hetu.interpreter
          .invoke('getLocationById', positionalArgs: [nation['capitalId']]);
      rowData.add(location['name']);
      // 地块大小
      rowData.add(nation['territoryIndexes'].length.toString());
      // 据点数量
      rowData.add(nation['locationIds'].length.toString());
      rowData.add(nation['organizationIds'].length.toString());
      // 多存一个隐藏的 id 信息，用于点击事件
      rowData.add(nation['id']);
      _nationsFieldRow.add(rowData);
    }

    _locationsData = engine.invoke('getLocations');
    for (final loc in _locationsData.values) {
      final rowData = <String>[];
      rowData.add(loc['name']);
      final nationId = loc['nationId'];
      if (nationId != null) {
        // 国家名字
        final nation = engine.hetu.interpreter
            .invoke('getNationById', positionalArgs: [nationId]);
        rowData.add(nation['name']);
      } else {
        rowData.add(engine.locale['none']);
      }
      // 门派名字
      final orgId = loc['organizationId'];
      if (orgId != null) {
        final organization = engine.hetu.interpreter
            .invoke('getOrganizationById', positionalArgs: [orgId]);
        rowData.add(organization['name']);
      } else {
        rowData.add(engine.locale['none']);
      }
      // 类型
      final category = loc['category'];
      switch (category) {
        case 'city':
          rowData.add(engine.locale['city']);
          break;
        case 'arcana':
          rowData.add(engine.locale['arcana']);
          break;
        case 'mirage':
          rowData.add(engine.locale['mirage']);
          break;
        default:
          rowData.add(engine.locale['unknown']);
      }
      // 发展度
      rowData.add(loc['development'].toString());
      // 多存一个隐藏的 id 信息，用于点击事件
      rowData.add(loc['id']);
      _locationsFieldRow.add(rowData);
    }

    _organizationsData = engine.invoke('getOrganizations');
    for (final org in _organizationsData.values) {
      final rowData = <String>[];
      rowData.add(org['name']);
      // 掌门
      final leader = engine.hetu.interpreter
          .invoke('getCharacterById', positionalArgs: [org['leaderId']]);
      rowData.add(leader['name']);
      // 总堂
      final headquarters = engine.hetu.interpreter
          .invoke('getLocationById', positionalArgs: [org['headquartersId']]);
      rowData.add(headquarters['name']);
      // 据点数量
      rowData.add(org['locationIds'].length.toString());
      // 成员数量
      rowData.add(org['characterIds'].length.toString());
      // 发展度
      rowData.add(org['development'].toString());
      // 多存一个隐藏的 id 信息，用于点击事件
      rowData.add(org['id']);
      _organizationsFieldRow.add(rowData);
    }

    _charactersData = engine.invoke('getCharacters');
    for (final char in _charactersData.values) {
      final rowData = <String>[];
      rowData.add(char['name']);
      // 当前所在地点
      final currentLocation = engine
          .invoke('getLocationById', positionalArgs: [char['locationId']]);
      rowData.add(currentLocation['name']);
      // 门派名字
      final orgId = char['organizationId'];
      if (orgId != null) {
        final organization = engine.hetu.interpreter
            .invoke('getOrganizationById', positionalArgs: [orgId]);
        rowData.add(organization['name']);
      } else {
        rowData.add(engine.locale['none']);
      }
      // 名声
      final int fame = char['fame'];
      rowData.add(fame.toString());
      // 多存一个隐藏的 id 信息，用于点击事件
      rowData.add(char['id']);
      _charactersFieldRow.add(rowData);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final layout = DefaultTabController(
      length: kInformationViewTabLengths,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale['info']),
          actions: const [ButtonClose()],
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.person),
                text:
                    '${engine.locale['character']}(${_charactersFieldRow.length})',
              ),
              Tab(
                icon: const Icon(Icons.groups),
                text:
                    '${engine.locale['organization']}(${_organizationsFieldRow.length})',
              ),
              Tab(
                icon: const Icon(Icons.location_city),
                text:
                    '${engine.locale['location']}(${_locationsFieldRow.length})',
              ),
              Tab(
                icon: const Icon(Icons.public),
                text: '${engine.locale['nation']}(${_nationsFieldRow.length})',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            GameEntityListView(
              columns: kInformationViewCharacterColumns,
              data: _charactersFieldRow,
              onTap: (dataId) => showDialog(
                context: context,
                builder: (context) => CharacterView(characterId: dataId),
              ),
            ),
            GameEntityListView(
              columns: kInformationViewOrganizationColumns,
              data: _organizationsFieldRow,
            ),
            GameEntityListView(
              columns: kInformationViewLocationColumns,
              data: _locationsFieldRow,
            ),
            GameEntityListView(
              columns: kInformationViewNationColumns,
              data: _nationsFieldRow,
            ),
          ],
        ),
      ),
    );

    return ResponsiveRoute(
      alignment: AlignmentDirectional.center,
      child: layout,
    );
  }
}
