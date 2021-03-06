import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intro_views_flutter/Models/page_view_model.dart';
import 'package:intro_views_flutter/intro_views_flutter.dart';
import 'package:islamtime/custom_widgets_and_styles/custom_styles_formats.dart';
import 'package:islamtime/custom_widgets_and_styles/custom_text.dart';
import 'package:islamtime/services/size_config.dart';
import 'location_page.dart';
import 'package:islamtime/i18n/onboarding_i18n.dart';

class OnBoardingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IntroViewsFlutter(
      [page1, page2],
      showSkipButton: false,
      onTapDoneButton: () => Get.off(LocationPage()),
      doneText: CustomText(
        'done'.i18n,
        size: 6.0,
        color: Colors.white,
        fontWeight: FontWeight.normal,
      ),
    );
  }

  final page1 = PageViewModel(
    title: Padding(
      padding: EdgeInsets.only(top: SizeConfig.safeBlockVertical * 1.0),
      child: CustomText(
        '''There are differences in perspective of the day's beginning(by day we mean the full 24 hour cycle not the morning time). Jews tend to begin at Magrib, Christians at sharp midnight.'''
            .i18n,
        size: 6.4,
        color: Colors.white,
        fontWeight: FontWeight.normal,
      ),
    ),
    mainImage: Image.asset('assets/images/jew_and_christian.png'),
    body: Text(''),
    pageColor: Colors.blueGrey[800],
    textStyle: GoogleFonts.heebo(fontSize: 26.0),
  );

  final page2 = PageViewModel(
    title: Padding(
      padding: EdgeInsets.only(top: SizeConfig.safeBlockVertical * 1.0),
      child: CustomText(
        '''For muslims the day starts at maghrib, also keep in mind that in islam the the night precedes the morning. and that's why on the last day of Ramadan, we don't pray Taraweeh, and that’s because the day (new day) has started at maghrib, so Ramadan is over and Eid has begun. this also mean that you may recite Surah Kahf any time after sunset of Thursday.'''
            .i18n,
        size: 5.6,
        color: Colors.white,
        fontWeight: FontWeight.normal,
      ),
    ),
    mainImage: Image.asset('assets/images/muslim.png'),
    body: Text(''),
    pageColor: Colors.blueGrey[800],
    textStyle: customRobotoStyle(3.0, Colors.white, FontWeight.normal),
  );
}
