class MaintenanceDeviceModel {
  String? _customerName;
  String? _phoneNumber;
  String? _address;
  String? _brandID;
  String? _deviceModel;
  String? _color;
  String? _imeiNumber;
  String? _problem;
  String? _status;
  String? _problemNotes;
  String? _accessories;
  String? _price;
  String? _estimatedTime;
  String? _notes;
  List<int>? _pattern;

  MaintenanceDeviceModel(
      {String? customerName,
        String? phoneNumber,
        String? address,
        String? brandID,
        String? deviceModel,
        String? color,
        String? imeiNumber,
        String? problem,
        String? status,
        String? problemNotes,
        String? accessories,
        String? price,
        String? estimatedTime,
        String? notes,
        List<int>? pattern}) {
    if (customerName != null) {
      this._customerName = customerName;
    }
    if (phoneNumber != null) {
      this._phoneNumber = phoneNumber;
    }
    if (address != null) {
      this._address = address;
    }
    if (brandID != null) {
      this._brandID = brandID;
    }
    if (deviceModel != null) {
      this._deviceModel = deviceModel;
    }
    if (color != null) {
      this._color = color;
    }
    if (imeiNumber != null) {
      this._imeiNumber = imeiNumber;
    }
    if (problem != null) {
      this._problem = problem;
    }
    if (status != null) {
      this._status = status;
    }
    if (problemNotes != null) {
      this._problemNotes = problemNotes;
    }
    if (accessories != null) {
      this._accessories = accessories;
    }
    if (price != null) {
      this._price = price;
    }
    if (estimatedTime != null) {
      this._estimatedTime = estimatedTime;
    }
    if (notes != null) {
      this._notes = notes;
    }
    if (pattern != null) {
      this._pattern = pattern;
    }
  }

  String? get customerName => _customerName;
  set customerName(String? customerName) => _customerName = customerName;
  String? get phoneNumber => _phoneNumber;
  set phoneNumber(String? phoneNumber) => _phoneNumber = phoneNumber;
  String? get address => _address;
  set address(String? address) => _address = address;
  String? get brandID => _brandID;
  set brandID(String? brandID) => _brandID = brandID;
  String? get deviceModel => _deviceModel;
  set deviceModel(String? deviceModel) => _deviceModel = deviceModel;
  String? get color => _color;
  set color(String? color) => _color = color;
  String? get imeiNumber => _imeiNumber;
  set imeiNumber(String? imeiNumber) => _imeiNumber = imeiNumber;
  String? get problem => _problem;
  set problem(String? problem) => _problem = problem;
  String? get status => _status;
  set status(String? status) => _status = status;
  String? get problemNotes => _problemNotes;
  set problemNotes(String? problemNotes) => _problemNotes = problemNotes;
  String? get accessories => _accessories;
  set accessories(String? accessories) => _accessories = accessories;
  String? get price => _price;
  set price(String? price) => _price = price;
  String? get estimatedTime => _estimatedTime;
  set estimatedTime(String? estimatedTime) => _estimatedTime = estimatedTime;
  String? get notes => _notes;
  set notes(String? notes) => _notes = notes;
  List<int>? get pattern => _pattern;
  set pattern(List<int>? pattern) => _pattern = pattern;

  MaintenanceDeviceModel.fromJson(Map<String, dynamic> json) {
    _customerName = json['customerName'];
    _phoneNumber = json['phoneNumber'];
    _address = json['address'];
    _brandID = json['brandID'];
    _deviceModel = json['deviceModel'];
    _color = json['color'];
    _imeiNumber = json['imeiNumber'];
    _problem = json['problem'];
    _status = json['status'];
    _problemNotes = json['problemNotes'];
    _accessories = json['accessories'];
    _price = json['price'];
    _estimatedTime = json['estimatedTime'];
    _notes = json['notes'];
    _pattern = json['pattern'].cast<int>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['customerName'] = this._customerName;
    data['phoneNumber'] = this._phoneNumber;
    data['address'] = this._address;
    data['brandID'] = this._brandID;
    data['deviceModel'] = this._deviceModel;
    data['color'] = this._color;
    data['imeiNumber'] = this._imeiNumber;
    data['problem'] = this._problem;
    data['status'] = this._status;
    data['problemNotes'] = this._problemNotes;
    data['accessories'] = this._accessories;
    data['price'] = this._price;
    data['estimatedTime'] = this._estimatedTime;
    data['notes'] = this._notes;
    data['pattern'] = this._pattern;
    return data;
  }
}