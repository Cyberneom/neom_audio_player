

// class DataSearch extends SearchDelegate {
//   final List<SongModel> data;
//   final String tempPath;
//
//   DataSearch({required this.data, required this.tempPath}) : super();
//
//   @override
//   List<Widget> buildActions(BuildContext context) {
//     return [
//       if (query.isEmpty)
//         IconButton(
//           icon: const Icon(CupertinoIcons.search),
//           tooltip: PlayerTranslationConstants.search.tr,
//           onPressed: () {},
//         )
//       else
//         IconButton(
//           onPressed: () {
//             query = '';
//           },
//           tooltip: PlayerTranslationConstants.clear.tr,
//           icon: const Icon(
//             Icons.clear_rounded,
//           ),
//         ),
//     ];
//   }
//
//   @override
//   Widget buildLeading(BuildContext context) {
//     return IconButton(
//       icon: const Icon(Icons.arrow_back_rounded),
//       tooltip: PlayerTranslationConstants.back.tr,
//       onPressed: () {
//         close(context, null);
//       },
//     );
//   }
//
//   @override
//   Widget buildSuggestions(BuildContext context) {
//     final suggestionList = query.isEmpty
//         ? data
//         : [
//             ...{
//               ...data.where(
//                 (element) =>
//                     element.title.toLowerCase().contains(query.toLowerCase()),
//               ),
//               ...data.where(
//                 (element) =>
//                     element.artist!.toLowerCase().contains(query.toLowerCase()),
//               ),
//             },
//           ];
//     return ListView.builder(
//       physics: const BouncingScrollPhysics(),
//       padding: const EdgeInsets.only(top: 10, bottom: 10),
//       shrinkWrap: true,
//       itemExtent: 70.0,
//       itemCount: suggestionList.length,
//       itemBuilder: (context, index) => ListTile(
//         leading: OfflineAudioQuery.offlineArtworkWidget(
//           id: suggestionList[index].id,
//           type: ArtworkType.AUDIO,
//           tempPath: tempPath,
//           fileName: suggestionList[index].displayNameWOExt,
//         ),
//         title: Text(
//           suggestionList[index].title.trim() != ''
//               ? suggestionList[index].title
//               : suggestionList[index].displayNameWOExt,
//           overflow: TextOverflow.ellipsis,
//         ),
//         subtitle: Text(
//           suggestionList[index].artist! == '<unknown>'
//               ? PlayerTranslationConstants.unknown.tr
//               : suggestionList[index].artist!,
//           overflow: TextOverflow.ellipsis,
//         ),
//         onTap: () async {
//           List<AppMediaItem> suggestionItems = [];
//
//           for (var element in suggestionList) {
//             suggestionItems.add(AppMediaItem(
//               id: element.id.toString(),
//               album: element.album ?? '',
//               name: element.title,
//               duration: element.duration ?? 0,
//               artist: element.artist ?? '',
//               artistId: element.artistId.toString(),
//               genre: element.genre ?? '',
//               albumId: element.albumId.toString(),
//               url: element.uri ?? '',
//               permaUrl: element.uri ?? '',),
//             );
//           }
//           NeomPlayerInvoker.init(
//             appMediaItems: suggestionItems,
//             index: index,
//             isOffline: true,
//             recommend: false,
//           );
//         },
//       ),
//     );
//   }
//
//   @override
//   Widget buildResults(BuildContext context) {
//     final suggestionList = query.isEmpty
//         ? data
//         : [
//           ...{
//           ...data.where((element) =>
//               element.title.toLowerCase().contains(query.toLowerCase()),
//           ),
//           ...data.where((element) =>
//               element.artist!.toLowerCase().contains(query.toLowerCase()),
//           ),
//           },];
//     return ListView.builder(
//       physics: const BouncingScrollPhysics(),
//       padding: const EdgeInsets.only(top: 10, bottom: 10),
//       shrinkWrap: true,
//       itemExtent: 70.0,
//       itemCount: suggestionList.length,
//       itemBuilder: (context, index) => ListTile(
//         leading: OfflineAudioQuery.offlineArtworkWidget(
//           id: suggestionList[index].id,
//           type: ArtworkType.AUDIO,
//           tempPath: tempPath,
//           fileName: suggestionList[index].displayNameWOExt,
//         ),
//         title: Text(
//           suggestionList[index].title.trim() != ''
//               ? suggestionList[index].title
//               : suggestionList[index].displayNameWOExt,
//           overflow: TextOverflow.ellipsis,
//         ),
//         subtitle: Text(
//           suggestionList[index].artist! == '<unknown>'
//               ? PlayerTranslationConstants.unknown.tr
//               : suggestionList[index].artist!,
//           overflow: TextOverflow.ellipsis,
//         ),
//         onTap: () async {
//           NeomPlayerInvoker.init(
//             appMediaItems: AppMediaItem.listFromSongModel(suggestionList),
//             index: index,
//             isOffline: true,
//             recommend: false,
//           );
//         },
//       ),
//     );
//   }
//
//   @override
//   ThemeData appBarTheme(BuildContext context) {
//     final ThemeData theme = Theme.of(context);
//     return theme.copyWith(
//       primaryColor: Theme.of(context).colorScheme.secondary,
//       textSelectionTheme:
//           const TextSelectionThemeData(cursorColor: Colors.white),
//       hintColor: Colors.white70,
//       primaryIconTheme: theme.primaryIconTheme.copyWith(color: Colors.white),
//       textTheme: theme.textTheme.copyWith(
//         titleLarge:
//             const TextStyle(fontWeight: FontWeight.normal, color: Colors.white),
//       ),
//       inputDecorationTheme:
//           const InputDecorationTheme(focusedBorder: InputBorder.none),
//     );
//   }
// }
