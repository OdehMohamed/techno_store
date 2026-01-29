class StorageApiPath {
  static String profilesPhotos(String userID) => 'profiles_photos/$userID/';

  // Maintenance Device Images
  static String maintenanceImages(String deviceId, String folderName) =>
      'maintenance_devices/$deviceId/$folderName/';
}
