class TravelPassportGetModel {
  bool? status;
  int? code;
  String? message;
  Body? body;

  TravelPassportGetModel({this.status, this.code, this.message, this.body});

  TravelPassportGetModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    code = json['code'];
    message = json['message'];
    body = json['body'] != null ? new Body.fromJson(json['body']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['code'] = this.code;
    data['message'] = this.message;
    if (this.body != null) {
      data['body'] = this.body!.toJson();
    }
    return data;
  }
}

class Body {
  PassportInfo? passportInfo;
  String? message;
  bool? isAdd;

  Body({this.passportInfo, this.message, this.isAdd});

  Body.fromJson(Map<String, dynamic> json) {
    passportInfo = json['passport_info'] != null
        ? new PassportInfo.fromJson(json['passport_info'])
        : null;
    message = json['message'];
    isAdd = json['is_add'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.passportInfo != null) {
      data['passport_info'] = this.passportInfo!.toJson();
    }
    data['message'] = this.message;
    data['is_add'] = this.isAdd;
    return data;
  }
}

class PassportInfo {
  dynamic frontFile;
  dynamic backFile;
  String? number;
  String? passportName;
  String? validFrom;
  String? validTill;

  PassportInfo(
      {this.frontFile,
      this.backFile,
      this.number,
      this.passportName,
      this.validFrom,
      this.validTill});

  PassportInfo.fromJson(Map<String, dynamic> json) {
    frontFile = json['front_file'];
    backFile = json['back_file'];
    number = json['number'];
    passportName = json['passport_name'];
    validFrom = json['valid_from'];
    validTill = json['valid_till'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['front_file'] = this.frontFile;
    data['back_file'] = this.backFile;
    data['number'] = this.number;
    data['passport_name'] = this.passportName;
    data['valid_from'] = this.validFrom;
    data['valid_till'] = this.validTill;
    return data;
  }
  /// ✅ Checks if all fields are null or empty (for strings)
  bool get isEmpty {
    return frontFile == null &&
        backFile == null &&
        (number == null || number!.isEmpty) &&
        (passportName == null || passportName!.isEmpty) &&
        (validFrom == null || validFrom!.isEmpty) &&
        (validTill == null || validTill!.isEmpty);
  }
}
