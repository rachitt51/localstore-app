import 'json.dart';

/// Cursor-paginated list: `{items, nextCursor}`.
class Paged<T> {
  const Paged({required this.items, this.nextCursor});

  factory Paged.fromJson(Json json, T Function(Json) fromItem) => Paged(
    items: asJsonList(json['items']).map(fromItem).toList(growable: false),
    nextCursor: asStringOrNull(json['nextCursor']),
  );

  final List<T> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  Paged<T> append(Paged<T> next) =>
      Paged(items: [...items, ...next.items], nextCursor: next.nextCursor);
}
