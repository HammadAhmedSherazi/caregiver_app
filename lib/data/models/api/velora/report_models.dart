import 'package:equatable/equatable.dart';

import '../../../../core/network/api_exception.dart';
import 'json.dart';

/// `type` of `POST /change-reports` (§5).
enum ChangeReportType {
  hospitalStay('hospital_stay'),
  fallInjury('fall_injury'),
  needsChanged('needs_changed'),
  cannotWork('cannot_work'),
  contactChanged('contact_changed'),
  clientPassed('client_passed'),
  other('other');

  const ChangeReportType(this.value);

  final String value;
}

/// Body of `POST /change-reports`, validated per the contract table.
class ChangeReportRequest extends Equatable {
  const ChangeReportRequest({
    required this.type,
    this.from,
    this.until,
    this.note,
    this.sawDoctor,
    this.documentId,
  });

  final ChangeReportType type;
  final DateTime? from;
  final DateTime? until;
  final String? note;
  final bool? sawDoctor;

  /// A paperwork photo uploaded first via `POST /documents`.
  final int? documentId;

  String? get _note => (note == null || note!.trim().isEmpty) ? null : note!.trim();

  void validate() {
    final errors = <String, List<String>>{};
    void need(bool ok, String field, String message) {
      if (!ok) errors[field] = [message];
    }

    switch (type) {
      case ChangeReportType.hospitalStay:
      case ChangeReportType.cannotWork:
        need(from != null, 'from', 'Choose a start date.');
      case ChangeReportType.fallInjury:
        need(from != null, 'from', 'Choose the date it happened.');
        need(sawDoctor != null, 'saw_doctor', 'Tell us if they saw a doctor.');
      case ChangeReportType.clientPassed:
        need(from != null, 'from', 'Choose the date.');
      case ChangeReportType.needsChanged:
      case ChangeReportType.contactChanged:
      case ChangeReportType.other:
        need(_note != null, 'note', 'Tell us what happened.');
    }
    if (from != null && until != null && until!.isBefore(from!)) {
      errors['until'] = ['"Until" must be on or after the start date.'];
    }
    if (errors.isNotEmpty) throw RequestValidationException(errors);
  }

  /// Sends only the fields the contract allows for [type].
  Map<String, dynamic> toJson() {
    final allowsUntil = type == ChangeReportType.hospitalStay || type == ChangeReportType.cannotWork;
    final allowsDoc = type == ChangeReportType.hospitalStay ||
        type == ChangeReportType.fallInjury ||
        type == ChangeReportType.needsChanged ||
        type == ChangeReportType.other;
    return {
      'type': type.value,
      if (from != null) 'from': formatDate(from!),
      if (allowsUntil) 'until': until == null ? null : formatDate(until!),
      if (type == ChangeReportType.fallInjury) 'saw_doctor': ?sawDoctor,
      'note': ?_note,
      if (allowsDoc) 'document_id': ?documentId,
    };
  }

  @override
  List<Object?> get props => [type, from, until, note, sawDoctor, documentId];
}

/// Response of `POST /change-reports` (201) incl. the confirmation copy.
class ChangeReportResultModel extends Equatable {
  const ChangeReportResultModel({
    required this.message,
    required this.id,
    required this.type,
    required this.status,
    this.createdAt,
    this.doneTitle,
    this.doneMessage,
  });

  final String message;
  final int id;
  final String type;
  final String status;
  final DateTime? createdAt;
  final String? doneTitle;
  final String? doneMessage;

  factory ChangeReportResultModel.fromJson(Json json) {
    final d = jsonMap(json['data']) ?? const {};
    return ChangeReportResultModel(
      message: strOr(json['message']),
      id: intOrNull(d['id']) ?? 0,
      type: strOr(d['type']),
      status: strOr(d['status']),
      createdAt: dateOrNull(d['created_at']),
      doneTitle: str(d['done_title']),
      doneMessage: str(d['done_message']),
    );
  }

  @override
  List<Object?> get props => [message, id, type, status, createdAt, doneTitle, doneMessage];
}
