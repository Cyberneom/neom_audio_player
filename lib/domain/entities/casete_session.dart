
class CaseteSession {

  String id; ///createdTime in milisecondsSinceEpoch as id
  String itemId; /// ID del libro
  String itemName; /// Título del libro
  String ownerId; ///USERID OR EMAIL OF OWNER
  String readerId; ///PROFILEID OF READER

  int totalPages; ///TOTAL NUMBER OF READ PAGES
  int totalDuration; ///TOTAL DURATION OF SESSION IN MS
  int casete; ///REAL Number of Pages Read
  int createdTime; ///CREATED SESSION TIME IN MILISECONDSSINCEEPOCH

  @override
  String toString() {
    return 'CaseteSession{id: $id, itemId: $itemId, itemName: $itemName, ownerId: $ownerId, readerId: $readerId, totalPages: $totalPages, totalDuration: $totalDuration, createdTime: $createdTime}';
  }

  CaseteSession({
    this.id = '',
    this.itemId = '',
    this.itemName = '',
    this.ownerId = '',
    this.readerId = '',
    this.totalPages = 0,
    this.totalDuration = 0,
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
      'readerId': readerId,
      'totalPages': totalPages,
      'totalDuration': totalDuration,
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
      readerId: json['readerId'] ?? '',
      totalPages: json['totalPages'] ?? 0,
      totalDuration: json['totalDuration'] ?? 0,
      casete: json['casete'] ?? 0,
      createdTime: json['createdTime'] ?? 0,
    );
  }

}
