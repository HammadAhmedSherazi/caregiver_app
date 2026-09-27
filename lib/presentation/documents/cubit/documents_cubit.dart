import 'package:equatable/equatable.dart';

import '../../../core/base/base_cubit.dart';
import '../../../data/models/api/document_model.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../core/i18n/tr.dart';

enum DocumentsStatus { initial, loading, success, failure }

class DocumentsState extends Equatable {
  const DocumentsState({
    this.status = DocumentsStatus.initial,
    this.documents = const [],
    this.errorMessage,
  });

  final DocumentsStatus status;
  final List<DocumentModel> documents;
  final String? errorMessage;

  bool get isLoading => status == DocumentsStatus.loading;
  bool get hasError => status == DocumentsStatus.failure;

  DocumentsState copyWith({
    DocumentsStatus? status,
    List<DocumentModel>? documents,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DocumentsState(
      status: status ?? this.status,
      documents: documents ?? this.documents,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, documents, errorMessage];
}

/// Documents on file for the Docs tab (`GET /documents`).
class DocumentsCubit extends BaseCubit<DocumentsState> {
  DocumentsCubit({required this.repository}) : super(const DocumentsState());

  final TaskRepository repository;

  /// Clears cached data (called on sign-out).
  void reset() {
    _generation++;
    emit(const DocumentsState());
  }

  int _generation = 0;

  Future<void> load() async {
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
