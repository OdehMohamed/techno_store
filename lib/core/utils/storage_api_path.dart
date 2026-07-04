class StorageApiPath {
  static String profilesPhotos(String userID) => 'profiles_photos/$userID/';

  // Maintenance Device Images
  static String maintenanceImages(String deviceId, String folderName) =>
      'maintenance_devices/$deviceId/$folderName/';

  // The device's whole image folder (covers before_receiving/ and
  // after_delivery/ together) — used for cascade deletion.
  static String maintenanceDevicesFolder(String deviceId) =>
      'maintenance_devices/$deviceId';
}
