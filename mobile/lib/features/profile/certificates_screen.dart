import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/learning_models.dart';
import '../../models/profile.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';

class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    if (!ref.watch(authControllerProvider).isLoggedIn) {
      return const LoginGuard(child: SizedBox.shrink());
    }
    final certsAsync = ref.watch(certificatesProvider);
    final reqsAsync = ref.watch(certificateRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.certificates),
        titleSpacing: 20,
      ),
      body: RefreshIndicator(
        color: AppColors.wine,
        onRefresh: () async {
          ref.invalidate(certificatesProvider);
          ref.invalidate(certificateRequestsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Pending / rejected requests ──
            reqsAsync.when(
              loading: () => const SliverToBoxAdapter(child: AppLoader()),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (reqs) {
                final active = reqs
                    .where((r) => r.isPending || r.isRejected)
                    .toList();
                if (active.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RequestCard(req: active[i]),
                      ),
                      childCount: active.length,
                    ),
                  ),
                );
              },
            ),

            // ── Issued certificates ──
            certsAsync.when(
              loading: () =>
                  const SliverToBoxAdapter(child: AppLoader()),
              error: (e, _) => SliverToBoxAdapter(
                child: ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(certificatesProvider),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _EmptyBanner(l: l),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _CertificateCard(cert: items[i]),
                      ),
                      childCount: items.length,
                    ),
                  ),
                );
              },
            ),

            // ── Request new certificate button ──
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              sliver: SliverToBoxAdapter(
                child: _RequestButton(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBanner extends StatelessWidget {
  const _EmptyBanner({required this.l});
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.wine.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.wine.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_outlined, color: AppColors.wine, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l.noCertificates,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ───── Request card (pending / rejected) ─────
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.req});
  final CertificateRequest req;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isPending = req.isPending;
    final color = isPending ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);
    final bgColor = isPending
        ? const Color(0xFFFEF3C7)
        : const Color(0xFFFEE2E2);
    final icon = isPending ? Icons.hourglass_top_rounded : Icons.cancel_outlined;
    final label = isPending ? l.certRequestPending : l.certRequestRejected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  req.courseTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${l.certFullName}: ${req.fullName}',
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          if (req.isRejected && req.rejectionReason != null) ...[
            const SizedBox(height: 4),
            Text(
              '${l.certRejectionReason}: ${req.rejectionReason}',
              style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
            ),
          ],
        ],
      ),
    );
  }
}

// ───── "So'rov yuborish" button ─────
class _RequestButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final coursesAsync = ref.watch(coursesProvider);

    return coursesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (courses) {
        final enrolled = courses.where((c) => !c.isFree).toList();
        if (enrolled.isEmpty) return const SizedBox.shrink();
        return OutlinedButton.icon(
          onPressed: () => _showRequestDialog(context, ref, l, courses),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.wine,
            side: const BorderSide(color: AppColors.wine),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: Text(
            l.certRequestNew,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      },
    );
  }

  Future<void> _showRequestDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    List<Course> courses,
  ) async {
    final nameCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RequestSheet(
        courses: courses,
        nameCtrl: nameCtrl,
        formKey: formKey,
        onSubmit: (course, name) async {
          final repo = ref.read(profileRepositoryProvider);
          await repo.submitCertificateRequest(
            courseId: course.id,
            fullName: name,
          );
          ref.invalidate(certificateRequestsProvider);
          if (ctx.mounted) Navigator.pop(ctx);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l.certRequestSent)),
            );
          }
        },
      ),
    );
  }
}

class _RequestSheet extends StatefulWidget {
  const _RequestSheet({
    required this.courses,
    required this.nameCtrl,
    required this.formKey,
    required this.onSubmit,
  });
  final List<Course> courses;
  final TextEditingController nameCtrl;
  final GlobalKey<FormState> formKey;
  final Future<void> Function(Course course, String name) onSubmit;

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  Course? _selected;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: widget.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l.certRequestNew,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Course>(
                value: _selected,
                hint: Text(l.certSelectCourse),
                items: widget.courses
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.title)))
                    .toList(),
                onChanged: (v) => setState(() => _selected = v),
                validator: (v) => v == null ? l.certSelectCourseRequired : null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: widget.nameCtrl,
                decoration: InputDecoration(
                  labelText: l.certFullName,
                  hintText: l.certFullNameHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 3) return l.fullNameTooShort;
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () async {
                        if (!widget.formKey.currentState!.validate()) return;
                        setState(() {
                          _loading = true;
                          _error = null;
                        });
                        try {
                          await widget.onSubmit(
                            _selected!,
                            widget.nameCtrl.text.trim(),
                          );
                        } catch (e) {
                          setState(() => _error = e.toString());
                        } finally {
                          if (mounted) setState(() => _loading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.wine,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l.certRequestSend,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───── Issued certificate card ─────
class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.cert});
  final Certificate cert;

  String _date(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.wine, AppColors.wineDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  cert.courseTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(label: l.date, value: _date(cert.issuedAt)),
              const SizedBox(width: 16),
              _Stat(label: l.grade, value: cert.grade?.toString() ?? '—'),
              const SizedBox(width: 16),
              Expanded(
                child: _Stat(
                  label: l.serial,
                  value: cert.serialNumber,
                  small: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (cert.pdfUrl != null)
            OutlinedButton.icon(
              onPressed: () {
                final url = cert.pdfUrl!.startsWith('http')
                    ? cert.pdfUrl!
                    : '${AppConstants.apiUrl.replaceAll('/api/v1', '')}${cert.pdfUrl}';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.pdfUrl(url))),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(l.pdfDownload),
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.small = false});
  final String label;
  final String value;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: small ? 12 : 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
