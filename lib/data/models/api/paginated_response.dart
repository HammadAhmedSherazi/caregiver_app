import 'package:equatable/equatable.dart';

class PaginatedResponse<T> extends Equatable {
  const PaginatedResponse({
    required this.data,
    this.links = const {},
    this.meta = const {},
  });

  final List<T> data;
  final Map<String, dynamic> links;
  final Map<String, dynamic> meta;

  @override
  List<Object?> get props => [data, links, meta];
}
