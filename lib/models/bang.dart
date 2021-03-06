import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:islamtime/custom_widgets_and_styles/custom_styles_formats.dart';
import 'package:json_annotation/json_annotation.dart';

part 'bang.g.dart';

@JsonSerializable()
class Bang extends Equatable {
  final String speda;
  final String rojHalat;
  final String nevro;
  final String evar;
  final String maghrab;
  final String aesha;
  final DateTime theThird;
  final DateTime lastThird;
  final DateTime dayTime;
  final DateTime maghrabDateTime;
  final DateTime spedaDateTime;
  final String date;
  final String formattedHijriDate;
  final DateTime midNightStart;
  final DateTime midNightEnd;

  Bang({
    @required this.speda,
    @required this.rojHalat,
    @required this.nevro,
    @required this.evar,
    @required this.maghrab,
    @required this.aesha,
    @required this.theThird,
    @required this.lastThird,
    @required this.dayTime,
    @required this.maghrabDateTime,
    @required this.spedaDateTime,
    @required this.date,
    @required this.formattedHijriDate,
    @required this.midNightStart,
    @required this.midNightEnd,
  });

  @override
  List<Object> get props => [
        speda,
        rojHalat,
        nevro,
        evar,
        maghrab,
        aesha,
        theThird,
        lastThird,
        dayTime,
        maghrabDateTime,
      ];

  factory Bang.fromJson(Map<String, dynamic> json) => _$BangFromJson(json);

  Map<String, dynamic> toJson() => _$BangToJson(this);

  static Bang fromJsonRequest(dynamic json, int day) {
    final speda = _toAmPm(json['data'][day]['timings']['Fajr']);
    final rojHalat = _toAmPm(json['data'][day]['timings']['Sunrise']);
    final nevro = _toAmPm(json['data'][day]['timings']['Dhuhr']);
    final evar = _toAmPm(json['data'][day]['timings']['Asr']);
    final maghrab = _toAmPm(json['data'][day]['timings']['Maghrib']);
    final aesha = _toAmPm(json['data'][day]['timings']['Isha']);

    String date = json['data'][day]['date']['readable'];
    String hijriDate = json['data'][day]['date']['hijri']['date'];

    List<String> hijriDateSplit = hijriDate.split('-');
    final hijriDateTime = DateTime(int.parse(hijriDateSplit[2]),
        int.parse(hijriDateSplit[1]), int.parse(hijriDateSplit[0]));

    final spedaDateTime =
        _customStringToDate(json['data'][day]['timings']['Fajr']);
    final maghrabDateTime =
        _customStringToDate(json['data'][day]['timings']['Maghrib']);

    var dates = getTheDifference(spedaDateTime, maghrabDateTime);
    print('dates $dates');

    return Bang(
      speda: speda,
      rojHalat: rojHalat,
      nevro: nevro,
      evar: evar,
      maghrab: maghrab,
      aesha: aesha,
      theThird: dates[0],
      lastThird: dates[1],
      midNightStart: dates[1],
      midNightEnd: dates[2],
      dayTime: dates[3],
      maghrabDateTime: dates[4],
      spedaDateTime: dates[5],
      date: date,
      formattedHijriDate: todayHijri,
    );
  }

  static DateTime _customStringToDate(String time, [bool isSpeda = false]) {
    final now = DateTime.now();
    final splitedTime = time.split(':');

    final hour = int.parse(splitedTime[0].trim());

    // to remove the extra stuff at the end
    final formattedStringPartTwo = splitedTime[1]
        .replaceAll(RegExp(r'(?<=\().*?(?=\))'), '')
        .replaceAll('()', '');

    final minute = int.parse(formattedStringPartTwo);

    final dateTime = DateTime(now.year, now.month, now.day, hour, minute);

    return dateTime;
  }

  static String _toAmPm(String time) {
    final formattedString =
        time.replaceAll(RegExp(r'(?<=\().*?(?=\))'), '').replaceAll('()', '');
    final splitString = formattedString.split(':');
    final hour = int.parse(splitString[0]);
    final minute = int.parse(splitString[1]);

    final tod = TimeOfDay(hour: hour, minute: minute);
    if (tod.hourOfPeriod == 0) {
      return '12:${tod.minute.toString().padLeft(2, '0')}';
    }

    return '${tod.hourOfPeriod.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
  }

  static List<DateTime> getTheDifference(
    DateTime spedaBang,
    DateTime maghrabBang,
  ) {
    // get the full differnce between speda and maghrab bang
    final spedaAndMaghrabDiff = spedaBang.subtract(
      Duration(
        days: maghrabBang.day,
        hours: maghrabBang.hour,
        minutes: maghrabBang.minute,
      ),
    );

    // ** get a third of the time
    final thirdOfDifferenceSeconds =
        (Duration(hours: spedaAndMaghrabDiff.hour).inSeconds ~/ 3);
    final thirdDuration = Duration(
        seconds: thirdOfDifferenceSeconds,
        minutes: (spedaAndMaghrabDiff.minute ~/ 3));
    final thirdHours = thirdDuration.inHours;
    final thirdMin = thirdDuration.inMinutes % (thirdHours * 60);
    // int midSecond = thirdDuration.inSeconds;

    final midNightStart = maghrabBang.add(
      Duration(
        hours: thirdHours,
        minutes: thirdMin,
      ),
    );

    final midNightEnd = midNightStart.add(
      Duration(
        hours: thirdHours,
        minutes: thirdMin,
      ),
    );

    // DateTime lastThird = midNightEnd.add(
    //   Duration(
    //     hours: thirdHours,
    //     minutes: thirdMin,
    //   ),
    // );

    final dayTime = maghrabBang.subtract(
      Duration(hours: spedaBang.hour, minutes: spedaBang.minute),
    );

    return [
      DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        thirdHours,
        thirdMin,
      ),
      midNightStart,
      midNightEnd,
      dayTime,
      maghrabBang,
      spedaBang,
    ];
  }
}
