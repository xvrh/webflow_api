import 'package:json_annotation/json_annotation.dart';

part 'webflow_api_models.g.dart';

/// A class representing a Webflow CMS Collection.
/// Gets populated by the retreived JSON from API.
class Collection {
  String id, lastUpdated, createdOn, name, slug, singularName;
  List<Field> fields;
  Map<String, dynamic> json;

  Collection.fromJson(this.json)
      : id = json['id'],
        lastUpdated = json["lastUpdated"],
        createdOn = json["createdOn"],
        name = json['displayName'],
        slug = json['slug'],
        singularName = json['singularName'],
        fields = ((json["fields"] ?? []) as List)
            .map((e) => Field.fromJson(e))
            .toList();
}

/// A class representing a Webflow CMS Item Fields.
/// Gets populated by the retreived JSON from API.
@JsonSerializable()
class Field {
  final String id, type, slug, displayName;
  final bool isEditable, isRequired;
  final FieldValidation? validations;
  final String? innerType;

  factory Field.fromJson(Map<String, dynamic> json) => _$FieldFromJson(json);

  Field(this.id, this.type, this.innerType, this.slug, this.displayName, this.isEditable,
      this.isRequired, this.validations);

  Map<String, dynamic> toJson() => _$FieldToJson(this);
}

@JsonSerializable()
class FieldValidation {
  final List<FieldOption>? options;

  FieldValidation({required this.options});

  factory FieldValidation.fromJson(Map<String, dynamic> json) =>
      _$FieldValidationFromJson(json);

  Map<String, dynamic> toJson() => _$FieldValidationToJson(this);
}

@JsonSerializable()
class FieldOption {
  final String name;
  final String id;

  FieldOption({required this.name, required this.id});

  factory FieldOption.fromJson(Map<String, dynamic> json) =>
      _$FieldOptionFromJson(json);

  Map<String, dynamic> toJson() => _$FieldOptionToJson(this);
}

/// A class representing a Webflow CMS Item.
/// Gets populated by the retreived JSON from API.
class Item {
  String id;
  bool archived, draft;
  Map<String, dynamic> json;
  final ItemFieldData fieldData;

  Item.fromJson(this.json)
      : archived = json['isArchived'],
        draft = json['isDraft'],
        id = json['id'],
      fieldData = ItemFieldData.fromJson(json['fieldData'] as Map<String, dynamic>);
}

class ItemFieldData {
  String name, slug;

  ItemFieldData.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        slug = json['slug'];
}

/// A class representing a Webflow CMS Item Response.
/// Gets populated by the retreived JSON from API.
/// The item response contains meta information about the response, besides the Item details.
class ItemsResponse {
  PaginationResponse pagination;
  List<Item> items;

  ItemsResponse.fromJson(Map<String, dynamic> json)
      : pagination = PaginationResponse.fromJson(json['pagination'] as Map<String, dynamic>),
        items = ((json["items"] ?? []) as List)
            .map((e) => Item.fromJson(e))
            .toList();
}

class PaginationResponse {
  final int limit, offset, total;

  PaginationResponse.fromJson(Map<String, dynamic> json)
      : limit = json['limit'],
        offset = json['offset'],
        total = json['total'];
}
