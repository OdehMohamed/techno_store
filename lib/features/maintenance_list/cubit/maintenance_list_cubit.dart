import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core/model/device_tab_page.dart';
import 'package:techno_store/core/model/grouped_maintenance_devices.dart';
import 'package:techno_store/core/model/maintenance_device_model.dart';
import 'package:techno_store/features/maintenance_list/services/maintenance_list_services.dart';

part 'maintenance_list_state.dart';

class MaintenanceListCubit extends Cubit<MaintenanceListState> {
  MaintenanceListCubit() : super(MaintenanceListInitial());
  final MaintenanceListServices maintenanceListServices =
      MaintenanceListServices();

  StreamSubscription<GroupedMaintenanceDevices>? _devicesSubscription;

  // --- New per-tab search/filter flow (see
  // docs/ai-workflow/SEARCH_FILTER_IMPLEMENTATION_PLAN.md). Coexists with
  // the fields/methods above during the transition; listenToMaintenanceDevices
  // and MaintenanceListLoaded/groupedDevices are removed once
  // InnerMaintenanceList is rewired onto this flow in a later commit. ---

  static const int _pageLimit = 50;

  StreamSubscription<DeviceTabPage>? _tabSubscription;
  final Map<String, DeviceTabPage> _tabCache = {};
  String? _activeTabKey;
  String? _activeUid;
  String _searchText = '';

  String _tabKey({
    required String status,
    String? brand,
    String? maintenanceEmployee,
    DateTime? receivedFrom,
    DateTime? receivedTo,
  }) {
    return [
      status,
      brand ?? '',
      maintenanceEmployee ?? '',
      receivedFrom?.toIso8601String() ?? '',
      receivedTo?.toIso8601String() ?? '',
    ].join('|');
  }

  List<MaintenanceDeviceModel> _applySearch(
    List<MaintenanceDeviceModel> devices,
  ) {
    final query = _searchText.trim().toLowerCase();
    if (query.isEmpty) return devices;
    return devices.where((d) {
      return d.name.toLowerCase().contains(query) ||
          d.phoneNumber.toLowerCase().contains(query) ||
          d.model.toLowerCase().contains(query) ||
          (d.imeiNumber?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _emitTabState(DeviceTabPage page, {bool isLoadingMore = false}) {
    emit(MaintenanceListTabLoaded(
      devices: page.devices,
      visibleDevices: _applySearch(page.devices),
      hasMore: page.lastDocument != null && page.devices.length >= _pageLimit,
      isLoadingMore: isLoadingMore,
    ));
  }

  /// Switches the active status tab, optionally narrowed by at most one
  /// structured filter. Reuses the session cache when this exact
  /// combination was already loaded (instant revisit); otherwise shows
  /// MaintenanceListLoading while the new bounded query resolves. See
  /// docs/ai-workflow/SEARCH_FILTER_IMPLEMENTATION_PLAN.md §4.
  void listenToTab({
    required String status,
    String? uid,
    String? brand,
    String? maintenanceEmployee,
    DateTime? receivedFrom,
    DateTime? receivedTo,
  }) {
    final key = _tabKey(
      status: status,
      brand: brand,
      maintenanceEmployee: maintenanceEmployee,
      receivedFrom: receivedFrom,
      receivedTo: receivedTo,
    );
    _activeTabKey = key;
    _activeUid = uid;

    final cached = _tabCache[key];
    if (cached != null) {
      _emitTabState(cached);
    } else {
      emit(MaintenanceListLoading());
    }

    _tabSubscription?.cancel();
    _tabSubscription = maintenanceListServices
        .streamDevicesForTab(
      status: status,
      uid: uid,
      brand: brand,
      maintenanceEmployee: maintenanceEmployee,
      receivedFrom: receivedFrom,
      receivedTo: receivedTo,
      limit: _pageLimit,
    )
        .listen(
      (page) {
        _tabCache[key] = page;
        if (_activeTabKey == key) {
          _emitTabState(page);
        }
      },
      onError: (error) {
        debugPrint('❌ Tab stream error: $error');
        if (_activeTabKey == key) {
          emit(MaintenanceListError(error: error.toString()));
        }
      },
    );
  }

  /// Re-filters the currently loaded tab's devices by [text] — no new
  /// Firestore query. Client-side substring search only ever looks at
  /// what's already loaded for the active tab, per the approved plan.
  void updateSearchText(String text) {
    _searchText = text;
    final cached = _activeTabKey != null ? _tabCache[_activeTabKey] : null;
    if (cached != null) {
      _emitTabState(cached);
    }
  }

  /// One-time paginated continuation for the active tab, beyond its live
  /// top-[_pageLimit] window.
  Future<void> loadMoreForCurrentTab({
    required String status,
    String? brand,
    String? maintenanceEmployee,
    DateTime? receivedFrom,
    DateTime? receivedTo,
  }) async {
    final key = _activeTabKey;
    if (key == null) return;
    final cached = _tabCache[key];
    if (cached == null || cached.lastDocument == null) return;

    _emitTabState(cached, isLoadingMore: true);

    try {
      final morePage = await maintenanceListServices.fetchMoreDevicesForTab(
        status: status,
        uid: _activeUid,
        brand: brand,
        maintenanceEmployee: maintenanceEmployee,
        receivedFrom: receivedFrom,
        receivedTo: receivedTo,
        startAfter: cached.lastDocument!,
        limit: _pageLimit,
      );
      final combined = DeviceTabPage(
        devices: [...cached.devices, ...morePage.devices],
        lastDocument: morePage.lastDocument ?? cached.lastDocument,
      );
      _tabCache[key] = combined;
      if (_activeTabKey == key) {
        _emitTabState(combined);
      }
    } catch (e) {
      debugPrint('❌ Error loading more devices: $e');
      if (_activeTabKey == key) {
        _emitTabState(cached);
      }
    }
  }

  /// Listen to realtime updates (للتحديثات الفورية)
  void listenToMaintenanceDevices(String? uid) {
    // Cancel any existing subscription
    _devicesSubscription?.cancel();

    // Emit loading state
    emit(MaintenanceListLoading());

    debugPrint('🎧 Starting to listen for uid: $uid');

    // Start listening to realtime updates
    _devicesSubscription =
        maintenanceListServices.streamMaintenanceDevices(uid).listen(
      (groupedDevices) {
        debugPrint('📦 Received stream data: '
            '${groupedDevices.inMaintenance.length} in maintenance, '
            '${groupedDevices.fixed.length} fixed, '
            '${groupedDevices.delivered.length} delivered');
        emit(MaintenanceListLoaded(groupedDevices: groupedDevices));
      },
      onError: (error) {
        debugPrint('❌ Stream error: $error');
        emit(MaintenanceListError(error: error.toString()));
      },
      onDone: () {
        debugPrint('✅ Stream completed');
      },
    );
  }

  /// Stops the active device stream and returns to the initial (no data)
  /// state. Call this when the signed-in user changes (e.g. on sign-out) —
  /// otherwise the stream keeps running with an auth context that no longer
  /// applies (surfacing as a permission-denied stream error once the
  /// session ends) and the next user to sign in on this device could
  /// briefly see the previous user's device list before their own stream
  /// delivers data.
  void stopListening() {
    _devicesSubscription?.cancel();
    _devicesSubscription = null;
    _tabSubscription?.cancel();
    _tabSubscription = null;
    _tabCache.clear();
    _activeTabKey = null;
    _activeUid = null;
    _searchText = '';
    emit(MaintenanceListInitial());
  }

  /// Fetch devices once (للاستخدام مع RefreshIndicator)
  Future<void> fetchGroupedMaintenanceDevices(String? uid) async {
    emit(MaintenanceListLoading());

    try {
      final groupedDevices =
          await maintenanceListServices.fetchMaintenanceDevices(uid);
      emit(MaintenanceListLoaded(groupedDevices: groupedDevices));
    } catch (e) {
      emit(MaintenanceListError(error: e.toString()));
    }
  }

  /// Delete a device
  Future<void> deleteDevice(String deviceId) async {
    try {
      await maintenanceListServices.deleteDevice(deviceId);
      debugPrint('✅ Device deleted successfully: $deviceId');
    } catch (e) {
      debugPrint('❌ Error deleting device: $e');
      emit(MaintenanceListError(error: e.toString()));
    }
  }

  /// Update device status
  Future<void> updateDeviceStatus(String deviceId, String newStatus) async {
    try {
      await maintenanceListServices.updateDeviceStatus(deviceId, newStatus);
      debugPrint(
          '✅ Device status updated successfully: $deviceId to $newStatus');
    } catch (e) {
      debugPrint('❌ Error updating device status: $e');
      emit(MaintenanceListError(error: e.toString()));
    }
  }

  Future<void> updateDeviceAsFixed({
    required String deviceId,
    required String maintenanceEmployee,
    required double? price,
    required List<String> installedPartCodes,
  }) async {
    try {
      await maintenanceListServices.updateDeviceAsFixed(
        deviceId: deviceId,
        maintenanceEmployee: maintenanceEmployee,
        price: price,
        installedPartCodes: installedPartCodes,
      );
      debugPrint('✅ Device fixed update saved successfully: $deviceId');
    } catch (e) {
      debugPrint('❌ Error saving fixed update: $e');
      emit(MaintenanceListError(error: e.toString()));
    }
  }

  Future<void> updateFixedDeviceDetails({
    required String deviceId,
    required String maintenanceEmployee,
    required double? price,
    required List<String> installedPartCodes,
  }) async {
    try {
      await maintenanceListServices.updateFixedDeviceDetails(
        deviceId: deviceId,
        maintenanceEmployee: maintenanceEmployee,
        price: price,
        installedPartCodes: installedPartCodes,
      );
      debugPrint('✅ Fixed device details edited successfully: $deviceId');
    } catch (e) {
      debugPrint('❌ Error editing fixed details: $e');
      emit(MaintenanceListError(error: e.toString()));
    }
  }

  Future<void> deliverDevice({
    required String deviceId,
    required String deliveredByEmployee,
    required double price,
    required List<String> imagesAfterDelivery,
  }) async {
    try {
      await maintenanceListServices.deliverDevice(
        deviceId: deviceId,
        deliveredByEmployee: deliveredByEmployee,
        price: price,
        imagesAfterDelivery: imagesAfterDelivery,
      );
      debugPrint('✅ Device delivered successfully: $deviceId');
    } catch (e) {
      debugPrint('❌ Error delivering device: $e');
      emit(MaintenanceListError(error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _devicesSubscription?.cancel();
    _tabSubscription?.cancel();
    debugPrint('🛑 Stopped listening to maintenance devices stream');
    return super.close();
  }
}
