import 'package:equatable/equatable.dart';

import '../../../core/base/base_cubit.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/api/document_model.dart';
import '../../../data/models/api/velora/velora_models.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../core/i18n/tr.dart';

enum DocumentsStatus { initial, loading, success, failure }

/// "From the office" (`GET /documents/office`, 🚧 planned). [notLive] while
/// `VELORA_API` is off — the section says so instead of guessing.
enum OfficeDocumentsStatus { initial, loading, success, failure, notLive }

class DocumentsState extends Equatable {
  const DocumentsState({
    this.status = DocumentsStatus.initial,
    this.documents = const [],
    this.errorMessage,
    this.officeStatus = OfficeDocumentsStatus.initial,
    this.officeDocuments = const [],
  });

  final DocumentsStatus status;
  final List<DocumentModel> documents;
  final String? errorMessage;
  final OfficeDocumentsStatus officeStatus;
  final List<OfficeDocumentModel> officeDocuments;

  bool get isLoading => status == DocumentsStatus.loading;
  bool get hasError => status == DocumentsStatus.failure;

  DocumentsState copyWith({
    DocumentsStatus? status,
    List<DocumentModel>? documents,
    String? errorMessage,
    bool clearError = false,
    OfficeDocumentsStatus? officeStatus,
    List<OfficeDocumentModel>? officeDocuments,
  }) {
    return DocumentsState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      officeStatus: officeStatus ?? this.officeStatus,
      officeDocuments: officeDocuments ?? this.officeDocuments,
    );
  }

  @override
  List<Object?> get props => [status, documents, errorMessage, officeStatus, officeDocuments];
}

/// Docs tab data: documents on file (`GET /documents`) and papers from the
/// office (`GET /documents/office`).
class DocumentsCubit extends BaseCubit<DocumentsState> {
  DocumentsCubit({required this.repository}) : super(const DocumentsState());

  final TaskRepository repository;

  /// Clears cached data (called on sign-out).
  void reset() {
    _generation++;
    emit(const DocumentsState());
  }

  int _generation = 0;

  Future<void> load() => Future.wait([_loadFiles(), loadOfficeDocuments()]);

  Future<void> loadOfficeDocuments() async {
    final generation = _generation;
    if (state.officeStatus != OfficeDocumentsStatus.success) {
      emit(state.copyWith(officeStatus: OfficeDocumentsStatus.loading));
    }
    try {
      final documents = await repository.getOfficeDocuments();
      if (generation != _generation) return;
      emit(state.copyWith(officeStatus: OfficeDocumentsStatus.success, officeDocuments: documents));
    } on ApiNotLiveException {
      if (generation != _generation) return;
      emit(state.copyWith(officeStatus: OfficeDocumentsStatus.notLive, officeDocuments: const []));
    } catch (error, stackTrace) {
      logError('Failed to load office documents', error: error, stackTrace: stackTrace);
      if (generation != _generation) return;
      if (state.officeStatus != OfficeDocumentsStatus.success) {
        emit(state.copyWith(officeStatus: OfficeDocumentsStatus.failure));
      }
    }
  }

  Future<void> _loadFiles() async {
    final generation = _generation;
    final hasData = state.status == DocumentsStatus.success;
    if (!hasData) {
      emit(state.copyWith(status: DocumentsStatus.loading, clearError: true));
    }

    try {
      final documents = await repository.getDocuments();
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: DocumentsStatus.success,
          documents: documents,
          clearError: true,
        ),
      );
    } catch (error, stackTrace) {
      logError('Failed to load documents', error: error, stackTrace: stackTrace);
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: hasData ? DocumentsStatus.success : DocumentsStatus.failure,
          errorMessage: tr('Failed to load your documents. Please try again.'),
        ),
      );
    }
  }
}
