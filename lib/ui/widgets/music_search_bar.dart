import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:hive/hive.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';
import 'package:neom_core/data/implementations/app_hive_controller.dart';
import 'package:neom_core/utils/enums/app_hive_box.dart';
import '../../data/implementations/player_hive_controller.dart';

class MusicSearchBar extends StatefulWidget {

  final Widget body;
  final bool autofocus;
  final bool liveSearch;
  final bool showClose;
  final Widget? leading;
  final String? hintText;
  final TextEditingController controller;
  final Function(String)? onQueryChanged;
  final Function()? onQueryCleared;
  final Function(String) onSubmitted;

  const MusicSearchBar({
    super.key,
    this.leading,
    this.hintText,
    this.showClose = true,
    this.autofocus = false,
    this.onQueryChanged,
    this.onQueryCleared,
    required this.body,
    required this.controller,
    required this.liveSearch,
    required this.onSubmitted,
  });

  @override
  State<MusicSearchBar> createState() => _MusicSearchBarState();
}

class _MusicSearchBarState extends State<MusicSearchBar> {
  String tempQuery = '';
  String query = '';
  final ValueNotifier<bool> hide = ValueNotifier<bool>(true);
  final ValueNotifier<List> suggestionsList = ValueNotifier<List>([]);

  @override
  void dispose() {
    super.dispose();
    hide.dispose();
    suggestionsList.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.body,
        ValueListenableBuilder(
          valueListenable: hide,
          builder: (
            BuildContext context,
            bool hidden,
            Widget? child,
          ) {
            return Visibility(
              visible: !hidden,
              child: GestureDetector(
                onTap: () {
                  hide.value = true;
                },
              ),
            );
          },
        ),
        Column(
          children: [
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0,),
              ),
              elevation: 8.0,
              child: Container(
                decoration: AppTheme.appBoxDecoration,
                height: 52.0,
                child: Center(
                  child: TextField(
                    controller: widget.controller,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(
                          width: 1.5,
                          color: Colors.transparent,
                        ),
                      ),
                      fillColor: Theme.of(context).colorScheme.secondary,
                      prefixIcon: widget.leading,
                      suffixIcon: widget.showClose
                          ? ValueListenableBuilder(
                              valueListenable: hide,
                              builder: (
                                BuildContext context,
                                bool hidden,
                                Widget? child,
                              ) {
                                return Visibility(
                                  visible: !hidden,
                                  child: IconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () {
                                      widget.controller.text = '';
                                      hide.value = true;
                                      suggestionsList.value = [];
                                      if (widget.onQueryCleared != null) {
                                        widget.onQueryCleared!.call();
                                      }
                                    },
                                  ),
                                );
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      hintText: widget.hintText,
                    ),
                    autofocus: widget.autofocus,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.search,
                    onChanged: (val) {
                      tempQuery = val;
                      if (val.trim() == '') {
                        hide.value = true;
                        suggestionsList.value = [];
                        if (widget.onQueryCleared != null) {
                          widget.onQueryCleared!.call();
                        }
                      }
                      if (widget.liveSearch && val.trim() != '') {
                        hide.value = false;
                        Future.delayed(const Duration(milliseconds: 600,),
                              () async {
                            if (tempQuery == val && tempQuery.trim() != ''
                                && tempQuery != query) {
                              query = tempQuery;
                              if (widget.onQueryChanged == null) {
                                widget.onSubmitted(tempQuery);
                              } else {
                                await widget.onQueryChanged!(tempQuery);
                              }
                            }
                          },
                        );
                      }
                    },
                    onSubmitted: (submittedQuery) async {
                      if (!hide.value) hide.value = true;
                      if (submittedQuery.trim() != '') {
                        query = submittedQuery.trim();
                        widget.onSubmitted(submittedQuery);
                        List searchQueries = AppHiveController().searchQueries;
                        if (searchQueries.contains(query)) {
                          searchQueries.remove(query);
                        }
                        searchQueries.insert(0, query);
                        if (searchQueries.length > 10) {
                          searchQueries = searchQueries.sublist(0, 10);
                        }
                        await PlayerHiveController().setSearchQueries(searchQueries);
                      }
                    },
                  ),
                ),
              ),
            ),
            ValueListenableBuilder(
              valueListenable: hide,
              builder: (
                BuildContext context,
                bool hidden,
                Widget? child,
              ) {
                return Visibility(
                  visible: !hidden,
                  child: ValueListenableBuilder(
                    valueListenable: suggestionsList,
                    builder: (
                      BuildContext context,
                      List suggestedList,
                      Widget? child,
                    ) {
                      return suggestedList.isEmpty
                          ? const SizedBox.shrink()
                          : Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 18.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  10.0,
                                ),
                              ),
                              elevation: 8.0,
                              child: Container(
                                decoration: AppTheme.appBoxDecoration,
                                height: min(
                                  MediaQuery.of(context).size.height / 1.75,
                                  70.0 * suggestedList.length,
                                ),
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.only(
                                    top: 10,
                                    bottom: 10,
                                  ),
                                  shrinkWrap: true,
                                  itemExtent: 70.0,
                                  itemCount: suggestedList.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      leading: const Icon(CupertinoIcons.search),
                                      title: Text(
                                        suggestedList[index].toString(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () {
                                        widget.onSubmitted(
                                          suggestedList[index].toString(),
                                        );
                                        hide.value = true;
                                        List searchQueries = Hive.box(AppHiveBox.settings.name).get('searchQueries', defaultValue: [],) as List;
                                        if (searchQueries.contains(
                                          suggestedList[index].toString().trim(),
                                        )) {
                                          searchQueries.remove(suggestedList[index].toString().trim(),);
                                        }
                                        searchQueries.insert(0, suggestedList[index].toString().trim(),
                                        );
                                        if (searchQueries.length > 10) {
                                          searchQueries = searchQueries.sublist(0, 10);
                                        }
                                        PlayerHiveController().setSearchQueries(searchQueries);
                                      },
                                    );
                                  },
                                ),
                              ),
                            );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}
