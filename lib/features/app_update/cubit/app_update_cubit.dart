import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core/model/app_config_model.dart';
import 'package:techno_store/features/app_update/services/app_update_service.dart';

part 'app_update_state.dart';

/// Fetches appConfig/global and determines whether the installed app must
/// be blocked until updated. See
/// docs/ai-workflow/FORCED_UPDATE_IMPLEMENTATION_PLAN.md. Every path through
/// [checkForUpdate] that isn't a confirmed force-required result falls
/// through to AppUpdateUpToDate — fails open, consistent with
/// AppUpdateService's own fail-open contract.
class AppUpdateCubit extends Cubit<AppUpdateState> {
  AppUpdateCubit() : super(AppUpdateInitial()) {
    checkForUpdate();
  }

  final _appUpdateService = AppUpdateService.instance;

  Future<void> checkForUpdate() async {
    emit(AppUpdateLoading());
    try {
      final config = await _appUpdateService.fetchAppConfig();
      if (config != null) {
        final platformInfo = _appUpdateService.currentPlatformInfo(config);
        final forceRequired =
            await _appUpdateService.isForceUpdateRequired(config);
        if (forceRequired && platformInfo != null) {
          emit(AppUpdateForceRequired(platformInfo: platformInfo));
          return;
        }
      }
      emit(AppUpdateUpToDate());
    } catch (e) {
      // Should not normally happen — AppUpdateService itself fails open —
      // but as a last line of defense, an unexpected error here must never
      // block the app either.
      debugPrint('❌ Unexpected error in AppUpdateCubit — failing open: $e');
      emit(AppUpdateUpToDate());
    }
  }
}
