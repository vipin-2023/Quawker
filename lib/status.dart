import 'package:flutter/material.dart';
import 'package:squawker/client.dart';
import 'package:squawker/constants.dart';
import 'package:squawker/generated/l10n.dart';
import 'package:squawker/profile/profile.dart';
import 'package:squawker/tweet/conversation.dart';
import 'package:squawker/ui/errors.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:pref/pref.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

class StatusScreenArguments {
  final String id;
  final String? username;

  StatusScreenArguments({required this.id, required this.username});

  @override
  String toString() {
    return 'StatusScreenArguments{id: $id, username: $username}';
  }
}

class StatusScreen extends StatelessWidget {
  const StatusScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as StatusScreenArguments;

    return _StatusScreen(username: args.username, id: args.id);
  }
}

class _StatusScreen extends StatefulWidget {
  final String? username;
  final String id;

  const _StatusScreen({Key? key, required this.username, required this.id}) : super(key: key);

  @override
  _StatusScreenState createState() => _StatusScreenState();
}

class _StatusScreenState extends State<_StatusScreen> {
  final _pagingController = PagingController<String?, TweetChain>(firstPageKey: null);
  final _scrollController = AutoScrollController();

  final _seenAlready = <String>{};

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener((cursor) {
      _loadTweet(cursor);
    });
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future _loadTweet(String? cursor) async {
    try {
      var isFirstPage = _pagingController.nextPageKey == null;

      var result = await Twitter.getTweet(widget.id, cursor: cursor);
      if (!mounted) {
        return;
      }

      if (result.cursorBottom != null && result.cursorBottom == _pagingController.nextPageKey) {
        _pagingController.appendLastPage([]);
      } else {
        // Twitter sometimes sends the original replies with all pages, so we need to manually exclude ones that we've already seen
        var chains = result.chains.skipWhile((element) => _seenAlready.contains(element.id)).toList();

        for (var chain in chains) {
          _seenAlready.add(chain.id);
        }

        _pagingController.appendPage(chains, result.cursorBottom);

        // If we're on the first page, we want to scroll to the selected status
        if (isFirstPage) {
          var statusIndex = chains.indexWhere((e) => e.id == widget.id);

          await _scrollController.scrollToIndex(statusIndex, preferPosition: AutoScrollPosition.begin);
          await _scrollController.highlight(statusIndex);
        }
      }
    } catch (e, stackTrace) {
      if (mounted) {
        _pagingController.error = [e, stackTrace];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ChangeNotifierProvider<TweetContextState>(
        create: (context) => TweetContextState(PrefService.of(context, listen: false).get(optionTweetsHideSensitive)),
        child: PagedListView<String?, TweetChain>(
          padding: EdgeInsets.zero,
          pagingController: _pagingController,
          scrollController: _scrollController,
          addAutomaticKeepAlives: false,
          shrinkWrap: true,
          builderDelegate: PagedChildBuilderDelegate(
            itemBuilder: (context, chain, index) {
              return AutoScrollTag(
                key: ValueKey(chain.id),
                controller: _scrollController,
                index: index,
                highlightColor: Colors.white.withOpacity(1),
                child: TweetConversation(id: chain.id, tweets: chain.tweets, username: null, isPinned: chain.isPinned),
              );
            },
            firstPageErrorIndicatorBuilder: (context) => FullPageErrorWidget(
              error: _pagingController.error[0],
              stackTrace: _pagingController.error[1],
              prefix: L10n.of(context).unable_to_load_the_tweet,
              onRetry: () => _loadTweet(_pagingController.firstPageKey),
            ),
            newPageErrorIndicatorBuilder: (context) => FullPageErrorWidget(
              error: _pagingController.error[0],
              stackTrace: _pagingController.error[1],
              prefix: L10n.of(context).unable_to_load_the_next_page_of_replies,
              onRetry: () => _loadTweet(_pagingController.nextPageKey),
            ),
            noItemsFoundIndicatorBuilder: (context) {
              return Center(
                child: Text(
                  L10n.of(context).could_not_find_any_tweets_by_this_user,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
