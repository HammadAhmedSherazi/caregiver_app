import 'dart:typed_data';

import 'package:caregiver_app/core/network/api_exception.dart';
import 'package:caregiver_app/data/models/api/velora/velora_models.dart';
import 'package:caregiver_app/data/repositories/task_repository.dart';
import 'package:caregiver_app/presentation/documents/cubit/documents_cubit.dart';
import 'package:caregiver_app/presentation/documents/view/document_viewer_view.dart';
import 'package:caregiver_app/presentation/task/cubit/task_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Only the PDF / office-document calls are exercised here.
class _FakeRepository implements TaskRepository {
  Object? payStubError;
  Object? officeError;
  Object? receiptError;
  List<OfficeDocumentModel> officeDocuments = const [];

  @override
  Future<List<int>> downloadPayStub(String id) async {
    if (payStubError != null) throw payStubError!;
    return [1, 2, 3];
  }

  @override
  Future<List<int>> downloadOfficeDocument(String id) async {
    if (officeError != null) throw officeError!;
    return [4, 5];
  }

  @override
  Future<List<int>> downloadCheckInReceipt(int formId) async {
    if (receiptError != null) throw receiptError!;
    return [6];
  }

  @override
  Future<List<OfficeDocumentModel>> getOfficeDocuments() async {
    if (officeError != null) throw officeError!;
    return officeDocuments;
  }

  @override
  Future<List<Never>> getDocuments() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TaskCubit PDF loaders', () {
    late _FakeRepository repo;
    late TaskCubit cubit;

    setUp(() {
      repo = _FakeRepository();
      cubit = TaskCubit(repository: repo);
    });

    tearDown(() => cubit.close());

    test('return the downloaded bytes', () async {
      expect(await cubit.loadPayStubPdf('31'), Uint8List.fromList([1, 2, 3]));
      expect(await cubit.loadOfficeDocumentPdf('w2-2025'), Uint8List.fromList([4, 5]));
      expect(await cubit.loadCheckInReceiptPdf(7), Uint8List.fromList([6]));
    });

    test('planned endpoints report "not live" without inventing a file', () async {
      repo.officeError = ApiNotLiveException('GET /documents/office/{id}/download');
      repo.receiptError = ApiNotLiveException('GET /compliance-forms/{id}/receipt');
      await expectLater(
        cubit.loadOfficeDocumentPdf('w2-2025'),
        throwsA(isA<DocumentDownloadException>().having((e) => e.notLive, 'notLive', isTrue)),
      );
      await expectLater(
        cubit.loadCheckInReceiptPdf(7),
        throwsA(isA<DocumentDownloadException>().having((e) => e.notLive, 'notLive', isTrue)),
      );
    });

    test('404 / 403 map to friendly messages', () async {
      repo.payStubError = NotFoundException('nope');
      await expectLater(
        cubit.loadPayStubPdf('31'),
        throwsA(isA<DocumentDownloadException>()
            .having((e) => e.message, 'message', 'Pay stub is not available.')
            .having((e) => e.notLive, 'notLive', isFalse)),
      );
      repo.receiptError = NotFoundException('nope');
      await expectLater(
        cubit.loadCheckInReceiptPdf(7),
        throwsA(isA<DocumentDownloadException>()
            .having((e) => e.message, 'message', 'The receipt is ready once your check-in is sent.')),
      );
    });
  });

  group('DocumentsCubit "From the office"', () {
    test('not live while VELORA_API is off', () async {
      final repo = _FakeRepository()..officeError = ApiNotLiveException('GET /documents/office');
      final cubit = DocumentsCubit(repository: repo);
      await cubit.loadOfficeDocuments();
      expect(cubit.state.officeStatus, OfficeDocumentsStatus.notLive);
      expect(cubit.state.officeDocuments, isEmpty);
      await cubit.close();
    });

    test('lists what the server returns', () async {
      final repo = _FakeRepository()
        ..officeDocuments = [
          OfficeDocumentModel.fromJson(const {
            'id': 'w2-2025',
            'kind': 'w2',
            'title': '2025 W-2',
            'subtitle': 'PDF · Jan 2026',
          }),
        ];
      final cubit = DocumentsCubit(repository: repo);
      await cubit.loadOfficeDocuments();
      expect(cubit.state.officeStatus, OfficeDocumentsStatus.success);
      expect(cubit.state.officeDocuments.single.title, '2025 W-2');
      await cubit.close();
    });
  });

  group('DocumentViewerView', () {
    Future<void> pump(WidgetTester tester, Future<Uint8List> Function() load) {
      return tester.pumpWidget(
        MaterialApp(
          home: DocumentViewerView(title: '2025 W-2', fileName: '2025-W-2.pdf', load: load),
        ),
      );
    }

    testWidgets('shows the file name and "not connected yet" for planned APIs', (tester) async {
      await pump(
        tester,
        () async => throw DocumentDownloadException('Not available yet.', notLive: true),
      );
      await tester.pump();

      expect(find.text('2025 W-2'), findsOneWidget);
      expect(find.text('2025-W-2.pdf'), findsOneWidget);
      expect(find.text('Not connected yet'), findsOneWidget);
      expect(find.text('Message the office'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('offers retry on a real download error', (tester) async {
      var calls = 0;
      await pump(tester, () async {
        calls++;
        throw DocumentDownloadException('Unable to download this document.');
      });
      await tester.pump();

      expect(find.text('Try again'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(calls, 2);
    });

    testWidgets('Save and Share stay disabled until the PDF is loaded', (tester) async {
      await pump(tester, () async => throw DocumentDownloadException('x'));
      await tester.pump();

      for (final label in ['Save to Files', 'Share or print']) {
        final button = tester.widget<InkWell>(
          find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first,
        );
        expect(button.onTap, isNull, reason: label);
      }
    });
  });
}
