import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/learning_models.dart';
import '../../models/profile.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';

/// Certificates, Liquid Glass mockup "5b": a glass card framing a
/// certificate preview (seal, course, date + serial), pending/rejected
/// request rows and a gradient download CTA. Request/download logic is
/// unchanged.
class CertificatesScreen extends ConsumerStatefulWidget {
  const CertificatesScreen({super.key});

  @override
  ConsumerState<CertificatesScreen> createState() =>
      _CertificatesScreenState();
}

class _CertificatesScreenState extends ConsumerState<CertificatesScreen> {
  final _scrollOffset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (!ref.watch(authControllerProvider).isLoggedIn) {
      return const LoginGuard(child: SizedBox.shrink());
    }
    final certsAsync = ref.watch(certificatesProvider);
    final reqsAsync = ref.watch(certificateRequestsProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          RefreshIndicator(
            color: AppColors.wine,
            onRefresh: () async {
              ref.invalidate(certificatesProvider);
              ref.invalidate(certificateRequestsProvider);
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.axis == Axis.vertical) {
                  _scrollOffset.value = n.metrics.pixels;
                }
                return false;
              },
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 60),
                children: [
                  GlassEntrance(
                    child: Row(
                      children: [
                        _GlassBackButton(onTap: () => context.pop()),
                        Expanded(
                          child: Text(
                            l.certificates,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Pending / rejected requests ──
                  reqsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (reqs) {
                      final active = reqs
                          .where((r) => r.isPending || r.isRejected)
                          .toList();
                      if (active.isEmpty) return const SizedBox.shrink();
                      return Column(
                        children: [
                          for (var i = 0; i < active.length; i++) ...[
                            GlassEntrance(
                              delay: GlassMotion.entranceStep * (1 + i),
                              child: _RequestCard(req: active[i]),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    },
                  ),

                  // ── Issued certificates ──
                  certsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: AppLoader(),
                    ),
                    error: (e, _) => ErrorView(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(certificatesProvider),
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return GlassEntrance(
                          delay: GlassMotion.entranceStep,
                          child: _EmptyBanner(l: l),
                        );
                      }
                      return Column(
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            GlassEntrance(
                              delay: GlassMotion.entranceStep * (1 + i),
                              child: _CertificateCard(cert: items[i]),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      );
                    },
                  ),

                  // ── Request new certificate ──
                  const SizedBox(height: 6),
                  GlassEntrance(
                    delay: GlassMotion.entranceStep * 2,
                    child: _RequestButton(),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child:
                GlassTopChrome(offset: _scrollOffset, title: l.certificates),
          ),
        ],
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassPressable(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dark ? AppColors.glassFillDark : AppColors.glassFillLight,
          border: Border.all(
            color:
                dark ? AppColors.glassStrokeDark : AppColors.glassStrokeLight,
            width: 0.5,
          ),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: 20,
          color: dark ? AppColors.inkDarkPrimary : AppColors.ink,
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return GlassContainer(
      borderRadius: AppColors.radiusTariffCard,
      withShadow: false,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.workspace_premium_outlined, color: accent, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l.noCertificates,
              style: TextStyle(color: mutedColor, fontSize: 13),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final isPending = req.isPending;
    final color = isPending ? AppColors.warning : AppColors.danger;
    final icon =
        isPending ? Icons.hourglass_top_rounded : Icons.cancel_outlined;
    final label = isPending ? l.certRequestPending : l.certRequestRejected;

    return GlassContainer(
      borderRadius: AppColors.radiusTariffCard,
      withShadow: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  req.courseTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    fontSize: 13.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${l.certFullName}: ${req.fullName}',
            style: TextStyle(fontSize: 12, color: mutedColor),
          ),
          if (req.isRejected && req.rejectionReason != null) ...[
            const SizedBox(height: 4),
            Text(
              '${l.certRejectionReason}: ${req.rejectionReason}',
              style: const TextStyle(fontSize: 12, color: AppColors.danger),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return coursesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (courses) {
        final enrolled = courses.where((c) => !c.isFree).toList();
        if (enrolled.isEmpty) return const SizedBox.shrink();
        return OutlinedButton.icon(
          onPressed: () => _showRequestDialog(context, ref, l, courses),
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: BorderSide(color: accent),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: const StadiumBorder(),
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
      barrierColor: AppColors.sheetScrim,
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: GlassSheet(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 32),
        child: Form(
          key: widget.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 14),
              Text(
                l.certRequestNew,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Course>(
                initialValue: _selected,
                hint: Text(l.certSelectCourse),
                items: widget.courses
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c.title)))
                    .toList(),
                onChanged: (v) => setState(() => _selected = v),
                validator: (v) =>
                    v == null ? l.certSelectCourseRequired : null,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppColors.radiusSegment),
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
                    borderRadius:
                        BorderRadius.circular(AppColors.radiusSegment),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 3) {
                    return l.fullNameTooShort;
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style:
                      const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              _PrimaryCta(
                label: l.certRequestSend,
                loading: _loading,
                onTap: _loading
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.onTap,
    this.loading = false,
    this.icon,
  });
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GlassPressable(
      onTap: loading ? null : onTap,
      child: Opacity(
        opacity: onTap == null && !loading ? 0.5 : 1,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.wineGradient,
            borderRadius: BorderRadius.circular(AppColors.radiusButton),
            boxShadow: [
              BoxShadow(
                color: AppColors.wine.withValues(alpha: 0.30),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ───── Issued certificate card (mockup 5b) ─────
class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.cert});
  final Certificate cert;

  String _date(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  Future<void> _download(BuildContext context, AppLocalizations l) async {
    final rawUrl = cert.pdfUrl!.startsWith('http')
        ? cert.pdfUrl!
        : '${AppConstants.apiUrl.replaceAll('/api/v1', '')}${cert.pdfUrl}';
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.pdfUrl(rawUrl))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Framed certificate preview (mockup 5b).
          Container(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 26),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.wine.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                // Seal
                Container(
                  width: 54,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.wine, AppColors.wineDeep],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.wine.withValues(alpha: 0.30),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.workspace_premium_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(height: 14),
                Text(
                  l.certificates.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  cert.courseTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                if (cert.grade != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${l.grade}: ${cert.grade}',
                    style: TextStyle(fontSize: 11.5, color: mutedColor),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _date(cert.issuedAt),
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Flexible(
                      child: Text(
                        'ID: ${cert.serialNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: mutedColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (cert.pdfUrl != null) ...[
            const SizedBox(height: 12),
            _PrimaryCta(
              label: l.pdfDownload,
              icon: Icons.download_rounded,
              onTap: () => _download(context, l),
            ),
          ],
        ],
      ),
    );
  }
}
