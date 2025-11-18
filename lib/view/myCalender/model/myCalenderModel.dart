class MyEventCalenderModel {
  bool? status;
  int? code;
  String? message;
  List<Body>? body;

  MyEventCalenderModel({
    this.status,
    this.code,
    this.message,
    this.body,
  });

  factory MyEventCalenderModel.fromJson(Map<String, dynamic> json) => MyEventCalenderModel(
    status: json["status"],
    code: json["code"],
    message: json["message"],
    body: json["body"] == null ? [] : List<Body>.from(json["body"]!.map((x) => Body.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "code": code,
    "message": message,
    "body": body == null ? [] : List<dynamic>.from(body!.map((x) => x.toJson())),
  };
}

class Body {
  String? title;
  String? description;
  DateTime? startDatetime;
  DateTime? endDatetime;
  dynamic color;
  dynamic textColor;
  dynamic opacity;
  dynamic borderColor;
  String? id;
  String? type;

  Body({
    this.title,
    this.description,
    this.startDatetime,
    this.endDatetime,
    this.color,
    this.textColor,
    this.opacity,
    this.borderColor,
    this.id,
    this.type,
  });

  factory Body.fromJson(Map<String, dynamic> json) => Body(
    title: json["title"],
    description: json["description"],
    startDatetime: json["start_datetime"] == null ? null : DateTime.parse(json["start_datetime"]),
    endDatetime: json["end_datetime"] == null ? null : DateTime.parse(json["end_datetime"]),
    color: json["color"],
    textColor: json["textColor"],
    opacity: json["opacity"]?.toDouble(),
    borderColor: json["borderColor"]!,
    id: json["id"],
    type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    "title": title,
    "description": description,
    "start_datetime": startDatetime?.toIso8601String(),
    "end_datetime": endDatetime?.toIso8601String(),
    "color": color,
    "textColor": textColor,
    "opacity": opacity,
    "borderColor": borderColor,
    "id": id,
    "type": type,
  };
}