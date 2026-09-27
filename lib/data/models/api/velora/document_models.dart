import 'package:equatable/equatable.dart';

import '../../../../core/network/api_exception.dart';
import 'common_models.dart';
import 'json.dart';

/// `GET /documents/required` item.
class RequiredDocumentModel extends Equatable {
  const RequiredDocumentModel({
    required this.key,
    required this.label,
    required this.status,
    required this.statusLabel,
    this.expiresOn,
    this.documentId,
    this.action,
  });

  /// `photo_id` `social_security_card` `i9` `w4_mi_w4` `direct_deposit_form`
  /// `background_check_consent` `handbook_signed`.
  final String key;
  final String label;

  /// `on_file` · `expiring` · `expired` · `missing`.
  final String status;
  final String statusLabel;
  final DateTime? expiresOn;
  final int? documentId;
  final AppActionModel? action;

  bool get needsAttention => status != 'on_file';

  factory RequiredDocumentModel.fromJson(Json j) => RequiredDocumentModel(
        key: strOr(j['key']),
        label: strOr(j['label']),
        status: strOr(j['status']),
        statusLabel: strOr(j['status_label']),
        expiresOn: dateOrNull(j['expires_on']),
        documentId: intOrNull(j['document_id']),
        action: AppActionModel.maybeFromJson(j['action']),
      );

  @override
  List<Object?> get props => [key, label, status, statusLabel, expiresOn, documentId, action];
}

/// `GET /documents/required` 🚧 PLANNED — NOT LIVE.
class RequiredDocumentsModel extends Equatable {
  const RequiredDocumentsModel({
    required this.upToDate,
    required this.total,
    required this.needsAttention,
    required this.items,
  });

  final int upToDate;
  final int total;
  final int needsAttention;
  final List<RequiredDocumentModel> items;

  factory RequiredDocumentsModel.fromJson(Json json) {
    final d = jsonMap(json['data']) ?? json;
    final s = jsonMap(d['summary']) ?? const {};
    return RequiredDocumentsModel(
      upToDate: intOrNull(s['up_to_date']) ?? 0,
      total: intOrNull(s['total']) ?? 0,
      needsAttention: intOrNull(s['needs_attention']) ?? 0,
      items: jsonList(d['items']).map(RequiredDocumentModel.fromJson).toList(),
    );
  }

  @override
  List<Object?> get props => [upToDate, total, needsAttention, items];
}

/// `GET /documents/office` item. `id` is a string key.
class OfficeDocumentModel extends Equatable {
  const OfficeDocumentModel({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle,
    this.issuedAt,
  });

  final String id;

  /// `pay_schedule` · `check_in_receipt` · `w2`.
  final String kind;
  final String title;
  final String? subtitle;
  final DateTime? issuedAt;

  factory OfficeDocumentModel.fromJson(Json j) => OfficeDocumentModel(
        id: strOr(j['id']),
        kind: strOr(j['kind']),
        title: strOr(j['title']),
        subtitle: str(j['subtitle']),
        issuedAt: dateOrNull(j['issued_at']),
      );

  @override
  List<Object?> get props => [id, kind, title, subtitle, issuedAt];
}

/// `type` values for `POST /documents`. The legacy values still work on
/// today's live API; the new ones are 🚧 PLANNED — NOT LIVE.
enum DocumentUploadType {
  // Live today.
  legacyId('ID', isLegacy: true),
  legacyMailLetter('Mail/Letter', isLegacy: true),
  legacySignedForm('Signed Form', isLegacy: true),
  legacyOther('Other', isLegacy: true),
  // Planned — exactly the five choices in the design.
  /// "Photo ID or driver's license" (front and back).
  photoId('photo_id'),

  /// "Tax or pay form": W-4, MI-W4, direct deposit.
  taxOrPayForm('tax_or_pay_form'),

  /// "For Robert or for you".
  doctorOrHospitalNote('doctor_or_hospital_note'),

  /// "Letter from DHS or the plan".
  stateLetter('state_letter'),
  other('other');

  const DocumentUploadType(this.value, {this.isLegacy = false});

  final String value;
  final bool isLegacy;
}

/// Optional `purpose` of `POST /documents`.
enum DocumentUploadPurpose {
  directDeposit('direct_deposit');

  const DocumentUploadPurpose(this.value);

  final String value;
}

/// Planned extra fields of `POST /documents` (multipart).
class DocumentUploadExtras extends Equatable {
  const DocumentUploadExtras({
    this.expiresOn,
    this.backFilePath,
    this.backFileName,
    this.replacesDocumentId,
    this.purpose,
  });

  /// Bank change from My info: `tax_or_pay_form` + `purpose: direct_deposit`.
  const DocumentUploadExtras.directDeposit()
      : expiresOn = null,
        backFilePath = null,
        backFileName = null,
        replacesDocumentId = null,
        purpose = DocumentUploadPurpose.directDeposit;

  /// Required for `photo_id`.
  final DateTime? expiresOn;
  final String? backFilePath;
  final String? backFileName;
  final int? replacesDocumentId;
  final DocumentUploadPurpose? purpose;

  bool get isEmpty =>
      expiresOn == null && backFilePath == null && replacesDocumentId == null && purpose == null;

  void validate(DocumentUploadType type) {
    if (purpose == DocumentUploadPurpose.directDeposit && type != DocumentUploadType.taxOrPayForm) {
      throw RequestValidationException({
        'purpose': ['A direct deposit change is sent as a tax or pay form.'],
      });
    }
    if (type == DocumentUploadType.photoId && expiresOn == null) {
      throw RequestValidationException({
        'expires_on': ['Enter the new expiration date.'],
      });
    }
  }

  @override
  List<Object?> get props => [expiresOn, backFilePath, backFileName, replacesDocumentId, purpose];
}
