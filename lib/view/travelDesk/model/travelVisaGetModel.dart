class TravelVisaGetModel {
  bool? status;
  int? code;
  String? message;
  Body? body;

  TravelVisaGetModel({this.status, this.code, this.message, this.body});

  TravelVisaGetModel.fromJson(Map<String, dynamic> json) {
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
  VisaInfo? visaInfo;
  String? message;
  bool? isAdd;

  Body({this.visaInfo, this.message, this.isAdd});

  Body.fromJson(Map<String, dynamic> json) {
    visaInfo = json['visa_info'] != null
        ? new VisaInfo.fromJson(json['visa_info'])
        : null;
    message = json['message'];
    isAdd = json['is_add'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.visaInfo != null) {
      data['visa_info'] = this.visaInfo!.toJson();
    }
    data['message'] = this.message;
    data['is_add'] = this.isAdd;
    return data;
  }
}

class VisaInfo {
  String? visaFile;

  VisaInfo({this.visaFile});

  VisaInfo.fromJson(Map<String, dynamic> json) {
    visaFile = json['visa_file'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['visa_file'] = this.visaFile;
    return data;
  }
}
