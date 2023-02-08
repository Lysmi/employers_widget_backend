// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class ManagerEntity {
  String name;
  List<DateTime> timeStart;
  List<DateTime> timeEnd;

  Map<String, List<bool>> data;

  ManagerEntity({
    required this.name,
    required this.timeStart,
    required this.timeEnd,
    required this.data,
  });

  ManagerEntity copyWith({
    String? name,
    int? innerNumber,
    List<DateTime>? timeStart,
    List<DateTime>? timeEnd,
    Map<String, List<bool>>? data,
  }) {
    return ManagerEntity(
      name: name ?? this.name,
      timeStart: timeStart ?? this.timeStart,
      timeEnd: timeEnd ?? this.timeEnd,
      data: data ?? this.data,
    );
  }

  factory ManagerEntity.fromMap(Map<String, dynamic> map) {
    var timeStartString =
        (map['timeStart'] as List<dynamic>).map((e) => e.split(' '));
    var timeEndString =
        (map['timeEnd'] as List<dynamic>).map((e) => e.split(' '));
    var timeStart = timeStartString.map((e) {
      var res = e[0].split(':');
      res.add(e[1]);
      return res;
    });
    var timeEnd = timeEndString.map((e) {
      var res = e[0].split(':');
      res.add(e[1]);
      return res;
    });
    var now = DateTime.now();

    return ManagerEntity(
        name: map['name'] as String,
        timeStart: timeStart
            .map((e) => DateTime(
                    now.year,
                    now.month,
                    now.day,
                    int.parse((e as List)[0]) + (((e)[2] == 'PM') ? 12 : 0),
                    int.parse((e)[1]))
                .toLocal())
            .toList(),
        timeEnd: timeEnd
            .map((e) => DateTime(
                    now.year,
                    now.month,
                    now.day,
                    int.parse((e as List)[0]) + (((e)[2] == 'PM') ? 12 : 0),
                    int.parse((e)[1]))
                .toLocal())
            .toList(),
        data: Map<String, List<dynamic>>.from(
          (map['data'] as Map<String, dynamic>),
        ).map((key, value) =>
            MapEntry(key, value.map((e) => e as bool).toList())));
  }

  factory ManagerEntity.fromJson(String source) =>
      ManagerEntity.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'ManagerEntity(name: $name,timeStart: $timeStart, timeEnd: $timeEnd, data: $data)';
  }

  @override
  bool operator ==(covariant ManagerEntity other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.timeStart == timeStart &&
        other.timeEnd == timeEnd;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        timeStart.hashCode ^
        timeEnd.hashCode ^
        data.hashCode;
  }
}
