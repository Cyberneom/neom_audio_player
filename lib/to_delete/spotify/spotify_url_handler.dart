// class SpotifyUrlHandler extends StatelessWidget {
//   final String id;
//   final String type;
//   const SpotifyUrlHandler({super.key, required this.id, required this.type});
//
//   @override
//   Widget build(BuildContext context) {
//     if (type == 'track') {
//       callSpotifyFunction(
//         function: (String accessToken) {
//           SpotifyApiCalls().getTrackDetails(accessToken, id).then((value) {
//             Navigator.pushReplacement(
//               context,
//               PageRouteBuilder(
//                 opaque: false,
//                 pageBuilder: (_, __, ___) => SearchPage(
//                   query: (value['artists'] != null &&
//                       (value['artists'] as List).isNotEmpty)
//                       ? '${value["name"]} by ${value["artists"][0]["name"]}'
//                       : value['name'].toString(),
//                 ),
//               ),
//             );
//           });
//         },
//       );
//     }
//     return Container();
//   }
// }
