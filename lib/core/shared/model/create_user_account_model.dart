class CreateUserAccountModel {
  String? _name;
  String? _photo;
  int? _type = 1;

  CreateUserAccountModel({String? name, String? photo, int? type}) {
    if (name != null) {
      this._name = name;
    }
    if (photo != null) {
      this._photo = photo;
    }
    if (type != null) {
      this._type = type;
    }
  }

  String? get name => _name;
  set name(String? name) => _name = name;
  String? get photo => _photo;
  set photo(String? photo) => _photo = photo;
  int? get type => _type;
  set type(int? type) => _type = type;

  CreateUserAccountModel.fromJson(Map<String, dynamic> json) {
    _name = json['name'];
    _photo = json['photo'];
    _type = json.containsKey('type') ? json['type'] : _type;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this._name;
    data['photo'] = this._photo;
    data['type'] = this._type;
    return data;
  }
}
