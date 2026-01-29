part of 'new_device_cubit.dart';

sealed class NewDeviceState {}

// Initial State
final class NewDeviceInitial extends NewDeviceState {}

// Loading States
final class NewDeviceLoading extends NewDeviceState {}

// Success States
final class NewDeviceSuccess extends NewDeviceState {
  final String deviceId;

  NewDeviceSuccess({required this.deviceId});
}

final class NewDeviceUpdated extends NewDeviceState {
  final String message;

  NewDeviceUpdated({required this.message});
}

// Error State
final class NewDeviceError extends NewDeviceState {
  final String error;

  NewDeviceError({required this.error});
}

// Image Upload States
final class ImagesUploading extends NewDeviceState {
  final int current;
  final int total;

  ImagesUploading({required this.current, required this.total});
}

final class ImagesUploaded extends NewDeviceState {
  final List<String> imageUrls;

  ImagesUploaded({required this.imageUrls});
}
