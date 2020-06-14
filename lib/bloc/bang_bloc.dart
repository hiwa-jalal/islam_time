import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:islamtime/bang.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:jiffy/jiffy.dart';

part 'bang_event.dart';
part 'bang_state.dart';

class BangBloc extends Bloc<BangEvent, BangState> {
  @override
  BangState get initialState => BangInitial();

  @override
  Stream<BangState> mapEventToState(
    BangEvent event,
  ) async* {
    yield BangLoading();
    if (event is GetBang) {
      Bang bang = await getPrayerData(event.countryName, event.cityName);
      yield BangLoaded(bang);
    }
  }

  Future<Bang> getPrayerData(String countryName, String cityName) async {
    String fileString = await rootBundle
        .loadString('assets/fixed_prayer_time/$countryName/$cityName.txt');

    // split the files into individual lines
    List<String> fileLines = fileString.split('\n');

    // get the line that contains the matched date
    String matchedDate =
        fileLines.where((element) => element.contains(getDate())).toString();

    print('matched data => $matchedDate');

    // split the line that has the data by ','
    List<String> splitLine = matchedDate.split(',');

    String speda = toAmPm(splitLine[2]);
    String rojHalat = toAmPm(splitLine[3]);
    String nevro = toAmPm(splitLine[4]);
    String evar = toAmPm(splitLine[5]);
    String makhrab = toAmPm(splitLine[6]);
    String aesha = toAmPm(splitLine[7]);
    getTheDifference(splitLine[1], splitLine[2], splitLine[6]);
    // String midNight = 

    Bang bang = Bang(
      speda: speda,
      rojHalat: rojHalat,
      nevro: nevro,
      evar: evar,
      maghrab: makhrab,
      aesha: aesha,
    );

    return bang;
  }

  String getDate() {
    int month = Jiffy().month;
    int day = Jiffy().date;

    // used quotes on the last one to make it a String
    String formattedMonth = month < 10 ? '0$month' : '$month';
    String formattedDay = day < 10 ? '0$day' : '$day';

    return '$formattedMonth-$formattedDay';
  }

  String toAmPm(String time) {
    List<String> splitedTime = time.split(':');
    int hour = int.parse(splitedTime[0].trim());

    TimeOfDay timeOfDay = TimeOfDay(hour: hour, minute: 0);

    if (timeOfDay.hourOfPeriod < 10 && timeOfDay.hourOfPeriod != 00)
      return '0${timeOfDay.hourOfPeriod}:${splitedTime[1]}';
    if (timeOfDay.hourOfPeriod == 00) return '12:${splitedTime[1]}';

    return '${timeOfDay.hourOfPeriod}:${splitedTime[1]}';
  }

  dynamic getTheDifference(String date, String speda, String maghrab) {
    List<String> splitedDate = date.split('-');
    int month = int.parse(splitedDate[0]);
    int day = int.parse(splitedDate[1]);

    List<String> splitedSpedaTime = speda.split(':');
    int spedaH = int.parse(splitedSpedaTime[0]);
    int spedaM = int.parse(splitedSpedaTime[1]);

    List<String> splitedMaghrabTime = maghrab.split(':');
    int maghrabH = int.parse(splitedMaghrabTime[0]);
    int maghrabM = int.parse(splitedMaghrabTime[1]);

    var dateSpeda = Jiffy({
      'month': month,
      'day': day,
      'hour': spedaH,
      'minutes': spedaM,
    }).format('dd/MM/yyyy HH:mm:ss');

    var dateMaghrab = Jiffy({
      'month': month,
      'day': day,
      'hour': maghrabH,
      'minutes': maghrabM,
    }).format('dd/MM/yyyy HH:mm:ss');

    DateTime spedaBang = DateFormat('dd/MM/yyyy HH:mm').parse(dateSpeda);
    DateTime maghrabBang = DateFormat('dd/MM/yyyy HH:mm').parse(dateMaghrab);

    print('in new method TimeDate speda $spedaBang');
    print('in new method TimeDate maghrab $maghrabBang');

    DateTime spedaAndMaghrabDiff = spedaBang.subtract(
      Duration(days: maghrabBang.day, hours: maghrabBang.hour),
    );

    int midNight = (spedaAndMaghrabDiff.hour ~/ 2).toInt();
    print('midNight $midNight');
    
    DateTime addToMaghrab = maghrabBang.add(Duration(hours: midNight));
    print('newMidNight $addToMaghrab');

    String formattedMidNight = DateFormat('HH:mm').format(addToMaghrab);
    print('parsedMaghrab String => $formattedMidNight');

    return formattedMidNight;
  }
}
