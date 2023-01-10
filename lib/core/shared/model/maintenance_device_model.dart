import 'package:uuid/uuid.dart';

import 'brand_model.dart';

class MaintenanceDeviceModel {
  String? _id = Uuid().v4();
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
  String? _replacedParts;
  List<bool>? _accessories;
  List<bool>? _preCheckList;
  List<String>? _preCheckListNotes;
  String? _price;
  String? _estimatedTime;
  String? _notes;
  String? _devicePassword;
  List<int>? _pattern;
  BrandModel? _brandModel;

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
        String? replacedParts,
        List<bool>? accessories,
        String? price,
        String? estimatedTime,
        String? notes,
        String? devicePassword,
        List<int>? pattern,
        List<bool>? preCheckList,
        List<String>? preCheckListNotes,
        BrandModel? brandModel}) {
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
    if (devicePassword != null) {
      this._devicePassword = devicePassword;
    }
    if (pattern != null) {
      this._pattern = pattern;
    }
    if (brandModel != null) {
      this._brandModel = brandModel;
    }
    if (preCheckListNotes != null) {
      this._preCheckListNotes = preCheckListNotes;
    }
    if (preCheckList != null) {
      this._preCheckList = preCheckList;
    }
    if (replacedParts != null) {
      this._replacedParts = replacedParts;
    }
  }

  String? get id => _id;
  set id(String? id) => _id = id;
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
  List<bool>? get accessories => _accessories;
  set accessories(List<bool>? accessories) => _accessories = accessories!;
  String? get price => _price;
  set price(String? price) => _price = price;
  String? get estimatedTime => _estimatedTime;
  set estimatedTime(String? estimatedTime) => _estimatedTime = estimatedTime;
  String? get notes => _notes;
  set notes(String? notes) => _notes = notes;
  String? get devicePassword => _devicePassword;
  set replacedParts(String? replacedParts) => _replacedParts = replacedParts;
  String? get replaceParts => _replacedParts;
  set devicePassword(String? devicePassword) => _devicePassword = devicePassword;
  List<int>? get pattern => _pattern;
  set pattern(List<int>? pattern) => _pattern = pattern;
  List<bool>? get preCheckList => _preCheckList;
  set preCheckList(List<bool>? preCheckList) => _preCheckList = preCheckList;
  List<String>? get preCheckListNotes => _preCheckListNotes;
  set preCheckListNotes(List<String>? preCheckListNotes) => _preCheckListNotes = preCheckListNotes;
  BrandModel? get brandModel => _brandModel;
  set brandModel(BrandModel? brandModel) => _brandModel = brandModel;

  MaintenanceDeviceModel.fromJson(Map<String, dynamic> json) {
    _id = json['id'];
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
    _accessories = json['accessories'].cast<bool>();
    _preCheckListNotes = json['preCheckListNotes'].cast<String>();
    _preCheckList = json['preCheckList'].cast<bool>();
    _price = json['price'];
    _estimatedTime = json['estimatedTime'];
    _notes = json['notes'];
    _devicePassword = json['devicePassword'];
    _pattern = json['pattern'].cast<int>();
    _replacedParts=json['replacedParts'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this._id;
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
    data['devicePassword'] = this._devicePassword;
    data['pattern'] = this._pattern;
    data['preCheckListNotes'] = this._preCheckListNotes;
    data['preCheckList'] = this._preCheckList;
    data['replacedParts'] = this._replacedParts;
    return data;
  }
}