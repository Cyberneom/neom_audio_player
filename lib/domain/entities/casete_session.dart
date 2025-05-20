
class CaseteSession {

  String id; ///createdTime in milisecondsSinceEpoch as id
  String itemId; /// Id of audio
  String itemName; /// Título del libro
  String ownerId; ///EMAIL OF OWNER
  String listenerId; ///email OF Listener
  int casete; ///REAL Number of seconds listened
  int createdTime; ///CREATED SESSION TIME IN MILISECONDSSINCEEPOCH

  @override
  String toString() {
    return 'CaseteSession{id: $id, itemId: $itemId, itemName: $itemName, ownerId: $ownerId, listenerId: $listenerId, casete: $casete, createdTime: $createdTime}';
  }

  CaseteSession({
    this.id = '',
    this.itemId = '',
    this.itemName = '',
    this.ownerId = '',
    this.listenerId = '',
    this.casete = 0,
    this.createdTime = 0,
  });

  /// Convert the CaseteSession object to a JSON map.
  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'ownerId': ownerId,
      'listenerId': listenerId,
      'casete': casete,
      'createdTime': createdTime,
    };
  }

  /// Create a CaseteSession object from a JSON map.
  factory CaseteSession.fromJSON(json) {
    return CaseteSession(
      id: json['id'] ?? '',
      itemId: json['itemId'] ?? '',
      itemName: json['itemName'] ?? '',
      ownerId: json['ownerId'] ?? '',
      listenerId: json['listenerId'] ?? '',
      casete: json['casete'] ?? 0,
      createdTime: json['createdTime'] ?? 0,
    );
  }

}
