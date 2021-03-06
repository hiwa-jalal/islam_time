import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart' as get_package;
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:i18n_extension/i18n_widget.dart';
import 'package:islamtime/bloc/bang_bloc.dart';
import 'package:islamtime/bloc/time_cycle/time_cycle_bloc.dart';
import 'package:islamtime/cubit/after_spotlight_cubit.dart';
import 'package:islamtime/cubit/is_outdated_cubit.dart';
import 'package:islamtime/pages/home_page.dart';
import 'package:islamtime/pages/language_selection_page.dart';
import 'package:islamtime/repository/bang_api_client.dart';
import 'package:islamtime/repository/bang_repository.dart';
import 'package:islamtime/services/connection_service.dart';
import 'package:islamtime/services/size_config.dart';
import 'package:provider/provider.dart';
import 'cubit/body_status_cubit.dart';
import 'cubit/is_rtl_cubit.dart';
import 'cubit/theme_cubit/theme_cubit.dart';
import 'package:http/http.dart' as http;
import 'package:islamtime/repository/location_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:islamtime/custom_widgets_and_styles/custom_styles_formats.dart';

class SimpleBlocDelegate extends BlocObserver {
  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    print('transition $transition');
  }

  @override
  void onEvent(Bloc bloc, Object event) {
    super.onEvent(bloc, event);
    print('event $event');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Bloc.observer = SimpleBlocDelegate();
  HydratedBloc.storage = await HydratedStorage.build();

  final prefs = await SharedPreferences.getInstance();
  final locationPrefs = prefs.getString('location');
  final langaugePrefs = prefs.getString(LANGUAGE_KEY);

  print('lang prefs in main ====> $langaugePrefs ==============<');

  final repository = LocalBangRepository(
    bangApiClient: BangApiClient(
      httpClient: http.Client(),
    ),
  );

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<BangBloc>(
          create: (_) => BangBloc(
            bangRepository: repository,
            locationRepository: LocationRepository(),
          ),
        ),
        BlocProvider<TimeCycleBloc>(create: (_) => TimeCycleBloc()),
        BlocProvider<BodyStatusCubit>(create: (_) => BodyStatusCubit()),
        BlocProvider<AfterSpotLightCubit>(create: (_) => AfterSpotLightCubit()),
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit()),
        BlocProvider<IsRtlCubit>(create: (_) => IsRtlCubit()),
        BlocProvider<IsOutdatedCubit>(create: (_) => IsOutdatedCubit()),
      ],
      child: StreamProvider<ConnectivityStatus>(
        create: (context) =>
            ConnectivityService().connectionStatusController.stream,
        child: BlocBuilder<ThemeCubit, ThemeChanged>(
          builder: (context, state) {
            return I18n(
              initialLocale:
                  langaugePrefs != null ? Locale(langaugePrefs) : Locale('en'),
              child: get_package.GetMaterialApp(
                theme: state.themeData,
                debugShowCheckedModeBanner: false,
                home: locationPrefs != null
                    ? Builder(
                        builder: (context) {
                          ScreenUtil.init(context);
                          return HomePage(
                            showDialog: false,
                            userLocation: locationPrefs,
                          );
                        },
                      )
                    : Builder(
                        builder: (context) {
                          SizeConfig().init(context);
                          ScreenUtil.init(context);
                          return LanguageSelectionPage();
                        },
                      ),
                // home: SplashScreenPage(locationPrefs: locationPrefs),
              ),
            );
          },
        ),
      ),
    ),
  );
}
