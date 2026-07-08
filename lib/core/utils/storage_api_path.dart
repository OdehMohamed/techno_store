class StorageApiPath {
  // No trailing slash: these are folder paths passed to
  // FirebaseStorageServices.uploadFile, which appends "/$fileName" itself. A
  // trailing slash here produces a double slash (an empty path segment) in the
  // final object path.
  static String profilesPhotos(String userID) => 'profiles_photos/$userID';

  // Maintenance Device Images
  static String maintenanceImages(String deviceId, String folderName) =>
      'maintenance_devices/$deviceId/$folderName';
}
