import 'package:cloud_firestore/cloud_firestore.dart';

DateTime toDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  } else if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  } else {
    return DateTime.now();
  }
}

T? tryGet<T>(List<T> list, int index) {
  if (index < 0 || index >= list.length) return null;
  return list[index];
}
