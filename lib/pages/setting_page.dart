import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:islamtime/bloc/bang_bloc.dart';
import 'package:islamtime/models/method_number.dart';
import 'package:islamtime/pages/home_page.dart';
import 'package:searchable_dropdown/searchable_dropdown.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool asTabs = false;
  MethodNumber selectedNumber = MethodNumber(3);
  List<int> methodNumbersList = [0, 0, 0, 0, 0, 0];
  final List<DropdownMenuItem> items = [];

  List<Widget> get appBarActions {
    return ([
      Center(child: Text("Tabs:")),
      Switch(
        activeColor: Colors.white,
        value: asTabs,
        onChanged: (value) {
          setState(() {
            asTabs = value;
          });
        },
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final bloc = BlocProvider.of<BangBloc>(context);
    return BlocConsumer<BangBloc, BangState>(
      listener: (context, state) {
        if (state is BangLoaded) {
          Get.to(HomePage(
            showDialog: false,
            bang: state.bang,
            userLocation: 'from setting',
          ));
        }
      },
      builder: (context, state) {
        if (state is BangLoaded) {
          return SafeArea(
            child: Scaffold(
              backgroundColor: Colors.grey,
              body: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                  child: Column(
                    children: <Widget>[
                      Material(
                        child: SearchableDropdown.single(
                          items: MethodNumber.list.map((exNum) {
                            return DropdownMenuItem(
                              child: Text(exNum.numberString),
                              value: exNum,
                            );
                          }).toList(),
                          onChanged: (value) {
                            selectedNumber = value;
                          },
                          value: selectedNumber,
                          hint: 'select a method',
                          isExpanded: true,
                        ),
                      ),
                      SizedBox(height: 20),
                      MethodNumberTile(
                        prayerName: 'Fajr',
                        onChange: (val) =>
                            methodNumbersList[0] = int.parse(val),
                      ),
                      MethodNumberTile(
                        prayerName: 'Sunrise',
                        onChange: (val) =>
                            methodNumbersList[1] = int.parse(val),
                      ),
                      MethodNumberTile(
                        prayerName: 'Zuhr',
                        onChange: (val) =>
                            methodNumbersList[2] = int.parse(val),
                      ),
                      MethodNumberTile(
                        prayerName: 'Asr',
                        onChange: (val) =>
                            methodNumbersList[3] = int.parse(val),
                      ),
                      MethodNumberTile(
                        prayerName: 'Maghrib',
                        onChange: (val) =>
                            methodNumbersList[4] = int.parse(val),
                      ),
                      MethodNumberTile(
                        prayerName: 'Isha',
                        isEnd: true,
                        onChange: (val) =>
                            methodNumbersList[5] = int.parse(val),
                      ),
                      Align(
                        alignment: FractionalOffset.centerRight,
                        child: RaisedButton(
                          child: Text('Ok'),
                          onPressed: () {
                            bloc.add(FetchBangWithSettings(
                              methodNumber: selectedNumber.number,
                              tuning: methodNumbersList,
                            ));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}