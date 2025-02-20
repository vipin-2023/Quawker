import 'package:flutter/material.dart';
import 'package:squawker/trends/_list.dart';
import 'package:squawker/trends/_settings.dart';
import 'package:squawker/trends/_tabs.dart';

class TrendsScreen extends StatefulWidget {
  final ScrollController scrollController;

  const TrendsScreen({Key? key, required this.scrollController}) : super(key: key);

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> with AutomaticKeepAliveClientMixin<TrendsScreen> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: const TrendsTabBar(),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add_rounded),
          onPressed: () async => showDialog(
                context: context,
                builder: (context) => const TrendsSettings(),
              )),
      body: TrendsList(scrollController: widget.scrollController),
    );
  }
}
