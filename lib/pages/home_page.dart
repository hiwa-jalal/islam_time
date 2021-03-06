import 'dart:ui';
import 'package:jiffy/jiffy.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:i18n_extension/i18n_widget.dart';
import 'package:islamtime/bloc/bang_bloc.dart';
import 'package:islamtime/bloc/time_cycle/time_cycle_bloc.dart';
import 'package:islamtime/cubit/after_spotlight_cubit.dart';
import 'package:islamtime/cubit/body_status_cubit.dart';
import 'package:islamtime/cubit/is_rtl_cubit.dart';
import 'package:islamtime/cubit/theme_cubit/theme_cubit.dart';
import 'package:islamtime/i18n/prayer_and_time_names_i18n.dart';

import 'package:islamtime/custom_widgets_and_styles/countdown.dart';
import 'package:islamtime/custom_widgets_and_styles/custom_styles_formats.dart';
import 'package:islamtime/custom_widgets_and_styles/custom_text.dart';
import 'package:islamtime/custom_widgets_and_styles/home_page_widgets/bottom_sheet_widget.dart';
import 'package:islamtime/models/bang.dart';
import 'package:islamtime/models/time_cycle.dart';
import 'package:islamtime/pages/athkar_page.dart';
import 'package:islamtime/services/connection_service.dart';
import 'package:islamtime/services/size_config.dart';
import 'package:islamtime/ui/global/theme/app_themes.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_tooltip/simple_tooltip.dart';
import 'package:solid_bottom_sheet/solid_bottom_sheet.dart';
import 'package:tutorial_coach_mark/animated_focus_light.dart';
import 'package:tutorial_coach_mark/content_target.dart';
import 'package:tutorial_coach_mark/target_focus.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    Key key,
    @required this.userLocation,
    this.showDialog = false,
  }) : super(key: key);

  final bool showDialog;
  final String userLocation;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String locationPrefs;
  double prefsLat;
  double prefsLng;
  int prefsMethodNumber;
  List<int> prefsTuning;

  int _animation;
  String _arrowAnimation = 'upArrowAnimation';
  var _isLoading = false;
  final _refreshController = RefreshController(initialRefresh: false);

  final _scaffold = GlobalKey();
  final _solidController = SolidController();
  final _swipeSheetKey = GlobalKey();
  final List<TargetFocus> _targets = [];

  @override
  void initState() {
    _animation = 0;
    if (widget.showDialog) {
      SchedulerBinding.instance
          .addPostFrameCallback((_) => _showLocationDialog());
    }
    _initTargets();
    super.initState();
  }

  Future<bool> _getIsLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(IS_LOCAL_KEY);
  }

  void _showTutorial() {
    TutorialCoachMark(
      context,
      targets: _targets,
      colorShadow: Colors.grey[400],
      textSkip: 'Ok'.i18n,
      clickSkip: () {},
      textStyleSkip: customRobotoStyle(4.4),
      paddingFocus: -100,
    )..show();
  }

  void _initTargets() {
    _targets.add(
      TargetFocus(
        identify: 'Target 1',
        keyTarget: _swipeSheetKey,
        shape: ShapeLightFocus.Circle,
        contents: [
          ContentTarget(
            align: AlignContent.top,
            child: Container(
              child: Column(
                children: <Widget>[
                  Text(
                    'Swipe to get more details'.i18n,
                    style: GoogleFonts.roboto(
                      fontSize: 64.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _getSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefsLat = prefs.getDouble(LAT_KEY);
    prefsLng = prefs.getDouble(LNG_KEY);
    prefsMethodNumber = prefs.getInt(METHOD_NUMBER_KEY);
    locationPrefs = prefs.getString(LOCATION_KEY);

    final tuningString = prefs.getStringList(TUNING_KEY);
    final tuningInt = tuningString.map((e) => int.parse(e)).toList();

    prefsTuning = tuningInt;
  }

  void _showLocationDialog() {
    AwesomeDialog(
      context: _scaffold.currentContext,
      dialogType: DialogType.INFO,
      animType: AnimType.SCALE,
      body: Center(
        child: Text(
          'Your Location is'.i18n + '\n' + widget.userLocation,
          style: customFarroDynamicStyle(size: 5.4, context: context),
          textAlign: TextAlign.center,
        ),
      ),
      btnOkOnPress: () => _showTutorial(),
    )..show();
  }

  Future<void> _onRefresh(
    BangBloc bangBloc,
    BuildContext context,
    bool isNotConnected,
    bool isLocal,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    if (isLocal) {
      final locationPrefsLocal = prefs.getString(LOCATION_KEY);
      final splitedPrefs = locationPrefsLocal.split(',');
      bangBloc.add(
        GetBang(countryName: splitedPrefs[0], cityName: splitedPrefs[1].trim()),
      );
    } else {
      await _getSharedPrefs();
      if (isNotConnected) {
        _refreshController.refreshCompleted();
        showOfflineDialog(context, OfflineMessage.basic, true);
      } else {
        bangBloc.add(
          FetchBangWithSettings(
            methodNumber: prefsMethodNumber,
            tuning: prefsTuning,
          ),
        );
      }
    }
  }

  // TODO: merge both these methods
  Future<void> _persisetTutorialDisplay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(IS_FIRST_TIME_KEY, true);
  }

  Future<bool> _getTutorialDisplay() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(IS_FIRST_TIME_KEY);
  }

  Widget _buildFlareActor() {
    return FlareActor(
      'assets/flare/DayAndNight.flr',
      animation: (_animation == 0)
          ? 'day_idle'
          : (_animation == 1)
              ? 'switch_to_night'
              : (_animation == 2) ? 'switch_to_day' : 'night_idle',
      callback: (value) {
        if (value == 'switch_to_night') {
          setState(() => _animation = 3);
        } else {
          setState(() => _animation = 0);
        }
      },
      fit: BoxFit.fill,
    );
  }

  Widget _buildBottomSheet(
    BuildContext context,
    BodyStatusCubit bodyStatusCubit,
    TimeCycle timeCycle,
  ) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SolidBottomSheet(
        controller: _solidController,
        maxHeight: SizeConfig.screenHeight / 2,
        headerBar: StatefulBuilder(
          builder: (context, sheetSetState) {
            _solidController.isOpenStream.listen((event) {
              if (event) {
                bodyStatusCubit.changeStatus(true);
                sheetSetState(() => _arrowAnimation = 'downArrowAnimation');
              } else {
                bodyStatusCubit.changeStatus(false);
                sheetSetState(() => _arrowAnimation = 'upArrowAnimation');
              }
            });
            return SizedBox(
              key: _swipeSheetKey,
              height: SizeConfig.safeBlockHorizontal * 20.0,
              child: FlareActor(
                'assets/flare/arrow_up_down.flr',
                animation: _arrowAnimation,
              ),
            );
          },
        ),
        body: BlocBuilder<BodyStatusCubit, bool>(
          builder: (context, state) => state ? BottomSheetTime() : Container(),
        ),
      ),
    );
  }

  Widget _buildSimpleTooltip(
    AsyncSnapshot<bool> isLocalSnapshot,
    TimeCycle timeCycle,
  ) {
    return FutureBuilder(
      future: _getTutorialDisplay(),
      builder: (context, isFirstTimeSnapshot) =>
          BlocBuilder<AfterSpotLightCubit, bool>(
        builder: (context, afterSpotLightState) => SimpleTooltip(
          content: Material(
            child: AutoSizeText(
              'Swipe from here to get latest prayer times'.i18n,
              style: GoogleFonts.roboto(
                fontSize: 76.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          show: () {
            if (isFirstTimeSnapshot.data == null && afterSpotLightState) {
              return true;
            }
            return false;
          }(),
          hideOnTooltipTap: true,
          tooltipTap: _persisetTutorialDisplay,
          tooltipDirection: TooltipDirection.down,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.safeBlockHorizontal * 2.4),
            child: AutoSizeText(
              'Time Remaining Until'.i18n +
                  ' ${timeCycle.untilDayOrNight.i18n}',
              style: customFarroDynamicStyle(
                fontWeight: FontWeight.bold,
                context: context,
                size: 6.8,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  void _checkTheme(TimeCycle timeCycle, BuildContext context) {
    final cubitTheme = BlocProvider.of<ThemeCubit>(context);
    timeCycle.timeIs == TimeIs.day
        ? cubitTheme.changeTheme(AppTheme.light)
        : cubitTheme.changeTheme(AppTheme.dark);
  }

  Widget _buildAthkarAvatar() {
    return Positioned.fill(
      top: SizeConfig.safeBlockVertical * 20.0,
      right: SizeConfig.safeBlockHorizontal * 1.6,
      child: Align(
        alignment: Alignment.topRight,
        child: CircleAvatar(
          radius: SizeConfig.blockSizeVertical * 5.6,
          backgroundColor: Colors.black,
          child: InkWell(
            onTap: () => Get.to(AthkarPage()),
            child: CircleAvatar(
              radius: SizeConfig.blockSizeVertical * 5.2,
              backgroundColor: Colors.blueGrey[700],
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.blockSizeVertical * 0.6),
                child: CustomText(
                  'Last third deeds'.i18n,
                  size: 4.2,
                  color: Colors.white,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _isDateOudated(
    BangBloc bangBloc,
    Bang bang,
    bool isNotConnected,
    bool isLocal,
  ) {
    final jif = Jiffy(bang.date, 'dd MMM yyyy');

    if (jif.date < DateTime.now().day ||
        jif.month < DateTime.now().month ||
        jif.year < DateTime.now().year) {
      if (isLocal) {
        final splitedPrefs = widget.userLocation.split(',');
        bangBloc.add(
          GetBang(
              countryName: splitedPrefs[0], cityName: splitedPrefs[1].trim()),
        );
        _isLoading = true;
      } else {
        if (!isNotConnected) {
          bangBloc.add(
            FetchBangWithSettings(
              methodNumber: prefsMethodNumber ?? 0,
              tuning: prefsTuning ?? [0, 0, 0, 0, 0, 0],
            ),
          );
        }
      }
      _isLoading = true;
    } else {
      _isLoading = false;
    }
  }

  Widget _buildLoadingOverlay(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 4,
              sigmaY: 4,
            ),
            child: SizedBox(
              height: 260.w,
              width: 260.w,
              child: SpinKitDoubleBounce(
                color: Colors.white,
                size: 300.w,
              ),
            ),
          ),
          Positioned(
            top: 700.h,
            right: 50.w,
            left: 50.w,
            child: AutoSizeText(
              'Getting prayer times for today'.i18n,
              style: customFarroDynamicStyle(context: context, size: 6.0),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bangBloc = BlocProvider.of<BangBloc>(context);
    final bodyStatusCubit = context.bloc<BodyStatusCubit>();
    final afterSpotLightCubit = BlocProvider.of<AfterSpotLightCubit>(context);
    final connectionStatus = Provider.of<ConnectivityStatus>(context);
    final isNotConnected = connectionStatus == ConnectivityStatus.Offline;
    final isRtlCubit = BlocProvider.of<IsRtlCubit>(context);
    if (I18n.locale.languageCode == 'ar') {
      isRtlCubit.isRtl(true);
    }
    SizeConfig().init(context);

    return SafeArea(
      child: AbsorbPointer(
        absorbing: _isLoading,
        child: Scaffold(
          key: _scaffold,
          body: Stack(
            children: <Widget>[
              FutureBuilder<bool>(
                future: _getIsLocal(),
                builder: (context, isLocalSnapshot) {
                  if (isLocalSnapshot.hasData) {
                    print('ISLOCAL => ${isLocalSnapshot.data}');
                    return SmartRefresher(
                      onRefresh: () => _onRefresh(
                        bangBloc,
                        context,
                        isNotConnected,
                        isLocalSnapshot.data,
                      ),
                      controller: _refreshController,
                      header: WaterDropHeader(waterDropColor: Colors.blue),
                      child: BlocConsumer<TimeCycleBloc, TimeCycleState>(
                        listener: (context, state) {
                          if (state is TimeCycleLoaded) {
                            if (state.timeCycle.timeIs == TimeIs.day) {
                              _animation = 2;
                            } else {
                              _animation = 1;
                            }
                          }
                        },
                        builder: (context, state) {
                          if (state is TimeCycleLoaded) {
                            final timeCycle = state.timeCycle;
                            _checkTheme(state.timeCycle, context);
                            return Stack(
                              children: <Widget>[
                                _buildFlareActor(),
                                // Center(
                                //   child: IconButton(
                                //     icon: FlutterLogo(
                                //       size: 4000.0,
                                //     ),
                                //     onPressed: () async {
                                //       final prefs =
                                //           await SharedPreferences.getInstance();
                                //       await prefs.clear();
                                //     },
                                //   ),
                                // ),
                                // Align(
                                //   alignment: Alignment.centerRight,
                                //   child: Padding(
                                //     padding: const EdgeInsets.all(40.0),
                                //     child: FlatButton(
                                //       child: FlutterLogo(
                                //         size: 100.0,
                                //         colors: Colors.red,
                                //       ),
                                //       onPressed: () async =>
                                //           cubitTheme.changeTheme(AppTheme.dark),
                                //       onLongPress: () => cubitTheme
                                //           .changeTheme(AppTheme.light),
                                //     ),
                                //   ),
                                // ),
                                _buildBottomSheet(
                                  context,
                                  bodyStatusCubit,
                                  timeCycle,
                                ),
                                BlocConsumer<BangBloc, BangState>(
                                  listener: (context, state) {
                                    if (state is BangLoaded) {
                                      afterSpotLightCubit.changeStatus();
                                      _persisetTutorialDisplay();
                                      _refreshController.refreshCompleted();
                                    }
                                  },
                                  builder: (context, state) {
                                    if (state is BangLoaded) {
                                      _isDateOudated(
                                        bangBloc,
                                        state.bang,
                                        isNotConnected,
                                        isLocalSnapshot.data,
                                      );
                                      return SingleChildScrollView(
                                        child: Column(
                                          children: <Widget>[
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 14.0,
                                                bottom: 18.0,
                                              ),
                                              child: _buildSimpleTooltip(
                                                isLocalSnapshot,
                                                timeCycle,
                                              ),
                                            ),
                                            Align(
                                              alignment: Alignment.topCenter,
                                              child: Countdown(
                                                bang: state.bang,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return SizedBox();
                                  },
                                ),
                                timeCycle.isLastThird
                                    ? _buildAthkarAvatar()
                                    : Container(),
                                _isLoading
                                    ? _buildLoadingOverlay(context)
                                    : Container(),
                              ],
                            );
                          } else {
                            return BlocBuilder<BangBloc, BangState>(
                              builder: (context, state) {
                                if (state is BangLoaded) {
                                  return Countdown(bang: state.bang);
                                }
                                return SizedBox();
                              },
                            );
                          }
                        },
                      ),
                    );
                  }
                  return CircularProgressIndicator();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
