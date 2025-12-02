
import 'package:enum_to_string/enum_to_string.dart';
import 'package:neom_core/utils/enums/subscription_level.dart';

class CaseteSession {

  String id; ///createdTime in milisecondsSinceEpoch as id
  String itemId;
  String itemName;
  String ownerEmail; ///EMAIL OF OWNER
  String listenerEmail; ///EMAIL OF READER

  int casete; ///REAL Number of seconds listened
  int totalDuration; ///TOTAL DURATION OF THE ITEM IN SECONDS
  int createdTime; ///CREATED SESSION TIME IN MILISECONDSSINCEEPOCH


  SubscriptionLevel? subscriptionLevel;
  bool isTest;

  @override
  String toString() {
    return 'CaseteSession{id: $id, itemId: $itemId, itemName: $itemName, ownerEmail: $ownerEmail, listenerEmail: $listenerEmail, casete: $casete, createdTime: $createdTime, subscriptionLevel: $subscriptionLevel, isTest: $isTest}';
  }

  CaseteSession({
    this.id = '',
    this.itemId = '',
    this.itemName = '',
    this.ownerEmail = '',
    this.listenerEmail = '',
    this.casete = 0,
    this.totalDuration = 0,
    this.createdTime = 0,
    this.subscriptionLevel,
    this.isTest = false,
  });

  /// Convert the CaseteSession object to a JSON map.
  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'ownerEmail': ownerEmail,
      'listenerEmail': listenerEmail,
      'casete': casete,
      'totalDuration': totalDuration,
      'createdTime': createdTime,
      'subscriptionLevel': subscriptionLevel?.name,
      'isTest': isTest,
    };
  }

  /// Create a CaseteSession object from a JSON map.
  factory CaseteSession.fromJSON(json) {
    return CaseteSession(
      id: json['id'] ?? '',
      itemId: json['itemId'] ?? '',
      itemName: json['itemName'] ?? '',
      ownerEmail: json['ownerEmail'] ?? json['ownerId'] ?? '',
      listenerEmail: json['listenerEmail'] ?? json['readerId'] ?? '',
      casete: json['casete'] ?? 0,
      totalDuration: json['totalDuration'] ?? 0,
      createdTime: json['createdTime'] ?? 0,
      subscriptionLevel: EnumToString.fromString(SubscriptionLevel.values, json["subscriptionLevel"].toString()),
      isTest: json['isTest'] ?? false,
    );
  }

}
