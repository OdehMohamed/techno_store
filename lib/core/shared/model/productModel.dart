class ProductModel {
  String? _id;
  String? _arName;
  String? _enName;
  String? _brandID;
  double? _price;
  String? _description;
  List<String>? _photo;
  String? _subCategoryID;
  List<String>? _favoriteList;

  ProductModel(
      {
      String? arName,
      String? enName,
      String? brandID,
      double? price,
      String? description,
      List<String>? photo,
      String? subCategoryID,
      List<String>? favoriteList}) {

    if (arName != null) {
      this._arName = arName;
    }
    if (enName != null) {
      this._enName = enName;
    }
    if (brandID != null) {
      this._brandID = brandID;
    }
    if (price != null) {
      this._price = price;
    }
    if (description != null) {
      this._description = description;
    }
    if (photo != null) {
      this._photo = photo;
    }
    if (subCategoryID != null) {
      this._subCategoryID = subCategoryID;
    }
    if (favoriteList != null) {
      this._favoriteList = favoriteList;
    }
  }

  String? get id => _id;
  set id(String? id) => _id = id;
  String? get arName => _arName;
  set arName(String? arName) => _arName = arName;
  String? get enName => _enName;
  set enName(String? enName) => _enName = enName;
  String? get brandID => _brandID;
  set brandID(String? brandID) => _brandID = brandID;
  double? get price => _price;
  set price(double? price) => _price = price;
  String? get description => _description;
  set description(String? description) => _description = description;
  List<String>? get photo => _photo;
  set photo(List<String>? photo) => _photo = photo;
  String? get subCategoryID => _subCategoryID;
  set subCategoryID(String? subCategoryID) => _subCategoryID = subCategoryID;
  List<String>? get favoriteList => _favoriteList;
  set favoriteList(List<String>? favoriteList) => _favoriteList = favoriteList;

  ProductModel.fromJson(Map<String, dynamic> json) {
    _arName = json['arName'];
    _enName = json['enName'];
    _brandID = json['brandID'];
    _price = json['price'];
    _description = json['description'];
    _photo = json['photo'].cast<String>();
    _subCategoryID = json['subCategoryID'];
    _favoriteList = json['favoriteList'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['arName'] = this._arName;
    data['enName'] = this._enName;
    data['brandID'] = this._brandID;
    data['price'] = this._price;
    data['description'] = this._description;
    data['photo'] = this._photo;
    data['subCategoryID'] = this._subCategoryID;
    data['favoriteList'] = this._favoriteList;
    return data;
  }
}
