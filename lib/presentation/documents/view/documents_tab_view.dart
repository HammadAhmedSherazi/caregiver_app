import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/velora_format.dart';
import '../../../data/models/api/document_model.dart';
import '../../../data/models/task_page_model.dart';
import '../../main/app_navigator.dart';
import '../../task/cubit/task_cubit.dart';
import '../../task/cubit/task_state.dart';
import '../../widgets/velora/velora.dart';
import '../cubit/documents_cubit.dart';

/// Docs tab: upload entry point, office requests and documents on file.
///
/// Data: `GET /documents` (DocumentsCubit) and document-request
/// notifications from the task page (TaskCubit).
class DocumentsTabView extends StatelessWidget {
  const DocumentsTabView({super.key});

  Future<void> _upload(BuildContext context) async {
    final uploaded = await AppNavigator.openUpload(context);
    if (uploaded == true && context.mounted) {
      context.read<DocumentsCubit>().load();
      context.read<TaskCubit>().loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DocumentsCubit, DocumentsState>(
      builder: (context, state) {
        return VeloraPage(
          underTabBar: true,
          onRefresh: () async {
            await Future.wait([
              context.read<DocumentsCubit>().load(),
              context.read<TaskCubit>().loadTasks(),
            ]);
          },
          header: VeloraHeader(
            title: 'Documents',
            subtitle: 'Your file with the office',
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            bottom: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _UploadBanner(onTap: () => _upload(context)),
            ),
          ),
          children: [
            _RequestsCard(onUpload: () => _upload(context)),
            if (state.hasError)
              VeloraErrorState(
                message: state.errorMessage ?? 'We couldn\'t load your documents.',
                onRetry: () => context.read<DocumentsCubit>().load(),
              )
            else if (state.isLoading || state.status == DocumentsStatus.initial)
              const VeloraLoadingState(message: 'Loading your documents…')
            else if (state.documents.isEmpty)
              VeloraEmptyState(
                title: 'No documents yet',
                message: 'Documents you send, and papers from the office, will show here.',
                action: VeloraButton(
                  label: 'Upload a document',
                  icon: VeloraIcons.camera,
                  onPressed: () => _upload(context),
                ),
              )
            else
              _FileCard(documents: state.documents),
          ],
        );
      },
    );
  }
}

class _UploadBanner extends StatelessWidget {
  const _UploadBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VeloraColors.amber,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: VeloraColors.amberInk.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: const VeloraIcon(VeloraIcons.camera, size: 20, color: VeloraColors.amberInk, strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Upload a document',
                        style: VeloraText.body(15, weight: FontWeight.w700, color: VeloraColors.amberInk)),
                    Text(
                      'Snap a photo or pick a file · goes straight to the office',
                      style: VeloraText.body(12,
                          weight: FontWeight.w600, color: VeloraColors.amberInk.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestsCard extends StatelessWidget {
  const _RequestsCard({required this.onUpload});

  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        final requests = (state.data?.allTasks ?? const <TaskItem>[])
            .where((t) => t.type == TaskItemType.documentUpload)
            .toList();
        if (requests.isEmpty) return const SizedBox.shrink();

        return VeloraCard(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCaption(
                'Requested by the office',
                trailing: StatusPill(
                  '${requests.length} needs attention',
                  tone: PillTone.warn,
                ),
              ),
              const SizedBox(height: 6),
              for (final task in requests)
                VeloraListRow(
                  leading: const IconTile(
                    VeloraIcons.alertCircle,
                    tone: IconTileTone.amber,
                    size: 36,
                    iconSize: 16,
                    radius: 10,
                  ),
                  title: task.title,
                  subtitle: task.subtitle,
                  subtitleColor: VeloraColors.warnText,
                  trailing: const StatusPill('Upload', tone: PillTone.warn),
                  showChevron: false,
                  onTap: onUpload,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.documents});

  final List<DocumentModel> documents;

  static (String, PillTone) _status(DocumentModel d) {
    final s = d.verificationStatus.toLowerCase();
    if (s.contains('reject') || s.contains('declin')) return ('Needs a new copy', PillTone.danger);
    if (s.contains('pend') || s.contains('review')) return ('In review', PillTone.warn);
    if (s.contains('verif') || s.contains('approv') || s.contains('accept')) {
      return ('On file', PillTone.good);
    }
    return (d.verificationStatus.isEmpty ? 'Received' : d.verificationStatus, PillTone.mute);
  }

  Future<void> _open(BuildContext context, DocumentModel doc) async {
    final url = doc.url;
    if (url == null || url.isEmpty) return;
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      showVeloraToast(context, 'Couldn\'t open this document.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final onFile = documents.where((d) => _status(d).$2 == PillTone.good).length;

    return VeloraCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCaption(
            'Your file',
            trailing: Text('$onFile of ${documents.length} on file',
                style: VeloraText.body(12, color: VeloraColors.muted)),
          ),
          const SizedBox(height: 12),
          VeloraProgressBar(value: documents.isEmpty ? 0 : onFile / documents.length),
          const SizedBox(height: 6),
          for (final doc in documents)
            Builder(
              builder: (context) {
                final (label, tone) = _status(doc);
                final uploaded = doc.uploadedAt;
                final canOpen = doc.url != null && doc.url!.isNotEmpty;
                return VeloraListRow(
                  leading: IconTile(
                    tone == PillTone.good ? VeloraIcons.check : VeloraIcons.documentPlain,
                    tone: switch (tone) {
                      PillTone.good => IconTileTone.good,
                      PillTone.warn => IconTileTone.amber,
                      PillTone.danger => IconTileTone.danger,
                      _ => IconTileTone.mute,
                    },
                    size: 36,
                    iconSize: 16,
                    radius: 10,
                  ),
                  title: doc.name,
                  subtitle: [
                    if (doc.type.isNotEmpty) doc.type,
                    if (uploaded != null) VeloraFormat.monthDay(uploaded.toLocal()),
                  ].join(' · '),
                  trailing: StatusPill(label, tone: tone),
                  showChevron: false,
                  onTap: canOpen ? () => _open(context, doc) : null,
                );
              },
            ),
        ],
      ),
    );
  }
}
