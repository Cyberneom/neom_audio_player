/// Owner facts a casete session takes from the item being heard.
class CaseteSessionFields {
  CaseteSessionFields._();

  /// The owner's account email — what royalties are attributed and paid to.
  ///
  /// `ownerId` is a profile id for newer releases, so it is only the fallback
  /// for items that carry no email (external or legacy ones).
  static String ownerEmail(Map<String, dynamic>? extras) {
    final email = extras?['ownerEmail']?.toString() ?? '';
    if (email.isNotEmpty && email != 'null') return email;
    final ownerId = extras?['ownerId']?.toString() ?? '';
    return ownerId == 'null' ? '' : ownerId;
  }

  /// Whether the listener owns the item being heard. Owning any release at
  /// all is asked separately, of the catalog; this is the local fast path
  /// and what still works offline.
  static bool listenerOwnsItem({
    required Map<String, dynamic>? extras,
    required String itemId,
    required String listenerEmail,
    Iterable<String> listenerProfileIds = const [],
    List<String>? legacyReleaseItemIds,
  }) {
    if (listenerEmail.isEmpty) return false;
    if (ownerEmail(extras) == listenerEmail) return true;
    final ownerId = extras?['ownerId']?.toString() ?? '';
    if (ownerId.isNotEmpty && listenerProfileIds.contains(ownerId)) return true;
    // Older releases used the owner's email as the item id.
    if (itemId == listenerEmail) return true;
    return legacyReleaseItemIds?.contains(itemId) ?? false;
  }
}
