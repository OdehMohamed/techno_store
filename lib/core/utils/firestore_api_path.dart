class FirestoreApiPath {
  static String users() => 'users/';
  static String user(String userId) => 'users/$userId';
  static String userMeta(String userId) => 'users/$userId/meta/isActivated';

  // Maintenance Devices Paths
  static String maintenanceDevices() => 'maintenanceDevices/';
  static String maintenanceDevice(String deviceId) =>
      'maintenanceDevices/$deviceId';

  // User Devices (subcollection under user)
  static String userDevices(String userId) => 'users/$userId/devices/';
  static String userDevice(String userId, String deviceId) =>
      'users/$userId/devices/$deviceId';

  // Query helpers
  static String userMaintenanceDevices(String userId) =>
      maintenanceDevices(); // سنستخدم query للفلترة حسب userId

  // static String products() => 'products/';
  // static String product(String productId) => 'products/$productId';

  // static String shippingAddresses(String userId) => 'users/$userId/shippingAddresses/';
  // static String shippingAddress(String userId, String shippingId) => 'users/$userId/shippingAddresses/$shippingId';

  // static String paymentMethods(String userId) => 'users/$userId/paymentMethods/';
  // static String paymentMethod(String userId, String paymentId) => 'users/$userId/paymentMethods/$paymentId';

  // static String favorites(String userId) => 'users/$userId/favorites/';
  // static String favoriteItem(String userId, String favoriteId) => 'users/$userId/favorites/$favoriteId';

  // static String cart(String userId) => 'users/$userId/cart/';
  // static String cartItem(String userId, String itemId) => 'users/$userId/cart/$itemId';
}
