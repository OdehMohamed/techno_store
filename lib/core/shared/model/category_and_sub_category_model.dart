class CategoriesAndSubCategoryModel {
  String? _id;
  String? _parentId;
  String? _arName;
  String? _enName;

  CategoriesAndSubCategoryModel({String? arName, String? enName}) {
    if (arName != null) {
      this._arName = arName;
    }
    if (enName != null) {
      this._enName = enName;
    }
  }

  String? get id => _id;
  set id(String? id) => _id = id;
  String? get parentId => _parentId;
  set parentId(String? parentId) => _parentId = parentId;
  String? get arName => _arName;
  set arName(String? arName) => _arName = arName;
  String? get enName => _enName;
  set enName(String? enName) => _enName = enName;

  CategoriesAndSubCategoryModel.fromJson(Map<String, dynamic> json) {
    _arName = json['arName'];
    _enName = json['enName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['arName'] = this._arName;
    data['enName'] = this._enName;
    return data;
  }
}
