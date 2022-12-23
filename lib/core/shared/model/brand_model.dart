class BrandModel {
  String? _name;
  String? _logo;

  BrandModel({String? name, String? logo}) {
    if (name != null) {
      this._name = name;
    }
    if (logo != null) {
      this._logo = logo;
    }
  }

  String? get name => _name;
  set name(String? name) => _name = name;
  String? get logo => _logo;
  set logo(String? logo) => _logo = logo;

  BrandModel.fromJson(Map<String, dynamic> json) {
    _name = json['name'];
    _logo = json['logo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this._name;
    data['logo'] = this._logo;
    return data;
  }
}