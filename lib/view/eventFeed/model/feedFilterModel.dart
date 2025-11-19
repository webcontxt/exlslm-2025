class FeedFilterModel {
  bool? status;
  int? code;
  String? message;
  Body? body;

  FeedFilterModel({this.status, this.code, this.message, this.body});

  FeedFilterModel.fromJson(Map<String, dynamic> json) {
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
  FilterType? type;

  Body({this.type});

  Body.fromJson(Map<String, dynamic> json) {
    type = json['type'] != null ? new FilterType.fromJson(json['type']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.type != null) {
      data['type'] = this.type!.toJson();
    }
    return data;
  }
}

class FilterType {
  String? label;
  String? name;
  String? placeholder;
  String? type;
  String? value;
  List<Options>? options;

  FilterType(
      {this.label,
        this.name,
        this.placeholder,
        this.type,
        this.value,
        this.options});

  FilterType.fromJson(Map<String, dynamic> json) {
    label = json['label'];
    name = json['name'];
    placeholder = json['placeholder'];
    type = json['type'];
    value = json['value'];
    if (json['options'] != null) {
      options = <Options>[];
      json['options'].forEach((v) {
        options!.add(new Options.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['label'] = this.label;
    data['name'] = this.name;
    data['placeholder'] = this.placeholder;
    data['type'] = this.type;
    data['value'] = this.value;
    if (this.options != null) {
      data['options'] = this.options!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Options {
  String? text;
  String? value;

  Options({this.text, this.value});

  Options.fromJson(Map<String, dynamic> json) {
    text = json['text'];
    value = json['value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['text'] = this.text;
    data['value'] = this.value;
    return data;
  }
}
