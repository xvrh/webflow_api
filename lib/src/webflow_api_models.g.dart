// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webflow_api_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Field _$FieldFromJson(Map<String, dynamic> json) => Field(
      json['id'] as String,
      json['type'] as String,
      json['innerType'] as String?,
      json['slug'] as String,
      json['displayName'] as String,
      json['isEditable'] as bool,
      json['isRequired'] as bool,
      json['validations'] == null
          ? null
          : FieldValidation.fromJson(
              json['validations'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FieldToJson(Field instance) => <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'slug': instance.slug,
      'displayName': instance.displayName,
      'isEditable': instance.isEditable,
      'isRequired': instance.isRequired,
      'validations': instance.validations,
      'innerType': instance.innerType,
    };

FieldValidation _$FieldValidationFromJson(Map<String, dynamic> json) =>
    FieldValidation(
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => FieldOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FieldValidationToJson(FieldValidation instance) =>
    <String, dynamic>{
      'options': instance.options,
    };

FieldOption _$FieldOptionFromJson(Map<String, dynamic> json) => FieldOption(
      name: json['name'] as String,
      id: json['id'] as String,
    );

Map<String, dynamic> _$FieldOptionToJson(FieldOption instance) =>
    <String, dynamic>{
      'name': instance.name,
      'id': instance.id,
    };
