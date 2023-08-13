/*
 *  This file is part of BlackHole (https://github.com/Sangwan5688/BlackHole).
 * 
 * BlackHole is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * BlackHole is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with BlackHole.  If not, see <http://www.gnu.org/licenses/>.
 * 
 * Copyright (c) 2021-2023, Ankit Sangwan
 */

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:hive/hive.dart';
import 'package:neom_commons/core/utils/app_theme.dart';
import 'package:neom_music_player/ui/YouTube/youtube_search.dart';
import 'package:neom_music_player/utils/constants/app_hive_constants.dart';
import 'package:neom_music_player/utils/constants/player_translation_constants.dart';
import 'package:get/get.dart';

class SearchBar extends StatefulWidget {
  final bool isYt;
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
  const SearchBar({
    super.key,
    this.leading,
    this.hintText,
    this.showClose = true,
    this.autofocus = false,
    this.onQueryChanged,
    this.onQueryCleared,
    required this.body,
    required this.isYt,
    required this.controller,
    required this.liveSearch,
    required this.onSubmitted,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
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
              margin: const EdgeInsets.fromLTRB(
                18.0,
                10.0,
                18.0,
                15.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  10.0,
                ),
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
                        if (widget.isYt) {
                          Future.delayed(
                            const Duration(
                              milliseconds: 600,
                            ),
                            () async {
                              if (tempQuery == val &&
                                  tempQuery.trim() != '' &&
                                  tempQuery != query) {
                                query = tempQuery;
                                suggestionsList.value =
                                    await widget.onQueryChanged!(tempQuery)
                                        as List;
                              }
                            },
                          );
                        } else {
                          Future.delayed(
                            const Duration(
                              milliseconds: 600,
                            ),
                            () async {
                              if (tempQuery == val &&
                                  tempQuery.trim() != '' &&
                                  tempQuery != query) {
                                query = tempQuery;
                                if (widget.onQueryChanged == null) {
                                  widget.onSubmitted(tempQuery);
                                } else {
                                  widget.onQueryChanged!(tempQuery);
                                }
                              }
                            },
                          );
                        }
                      }
                    },
                    onSubmitted: (submittedQuery) {
                      if (!hide.value) hide.value = true;
                      if (submittedQuery.trim() != '') {
                        query = submittedQuery.trim();
                        widget.onSubmitted(submittedQuery);
                        List searchQueries = Hive.box(AppHiveConstants.settings)
                            .get('search', defaultValue: []) as List;
                        if (searchQueries.contains(query)) {
                          searchQueries.remove(query);
                        }
                        searchQueries.insert(0, query);
                        if (searchQueries.length > 10) {
                          searchQueries = searchQueries.sublist(0, 10);
                        }
                        Hive.box(AppHiveConstants.settings).put('search', searchQueries);
                      }
                    },
                  ),
                ),
              ),
            ),
            if (!widget.isYt)
              Padding(
                padding: const EdgeInsets.only(left: 25.0, right: 25.0),
                child: RichText(
                  text: TextSpan(
                    children: <TextSpan>[
                      TextSpan(
                        style: const TextStyle(color: Colors.grey),
                        text: PlayerTranslationConstants.cantFind.tr,
                      ),
                      TextSpan(
                        text: PlayerTranslationConstants.searchYt.tr,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                opaque: false,
                                pageBuilder: (_, __, ___) => YouTubeSearchPage(
                                  query: query.isNotEmpty
                                      ? query
                                      : widget.controller.text,
                                ),
                              ),
                            );
                          },
                      ),
                    ],
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
                          ? const SizedBox()
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
                              child: SizedBox(
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
                                      leading:
                                          const Icon(CupertinoIcons.search),
                                      title: Text(
                                        suggestedList[index].toString(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      onTap: () {
                                        widget.onSubmitted(
                                          suggestedList[index].toString(),
                                        );
                                        hide.value = true;
                                        List searchQueries =
                                            Hive.box(AppHiveConstants.settings).get(
                                          'search',
                                          defaultValue: [],
                                        ) as List;
                                        if (searchQueries.contains(
                                          suggestedList[index]
                                              .toString()
                                              .trim(),
                                        )) {
                                          searchQueries.remove(
                                            suggestedList[index]
                                                .toString()
                                                .trim(),
                                          );
                                        }
                                        searchQueries.insert(
                                          0,
                                          suggestedList[index]
                                              .toString()
                                              .trim(),
                                        );
                                        if (searchQueries.length > 10) {
                                          searchQueries =
                                              searchQueries.sublist(0, 10);
                                        }
                                        Hive.box(AppHiveConstants.settings)
                                            .put('search', searchQueries);
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
