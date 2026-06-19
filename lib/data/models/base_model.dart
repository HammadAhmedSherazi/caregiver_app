import 'package:equatable/equatable.dart';

abstract class BaseModel extends Equatable {
  const BaseModel();

  Map<String, dynamic> toJson();
}
