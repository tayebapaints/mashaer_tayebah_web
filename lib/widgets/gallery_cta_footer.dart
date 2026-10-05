import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../content.dart';
import '../theme.dart';
import 'common.dart';

/// Finds the gallery images that REALLY exist by reading Flutter's asset
/// manifest, instead of guessing file names and extensions.
///
/// Requirement: `assets/images/work/` must be declared in pubspec.yaml:
///
/// flutter:
///   assets:
///     - assets/images/work/
class GalleryImages {
  GalleryImages._();

  static const String _folder = 'assets/images/work/';
  static const List<String> _extensions = ['.jpg', '.jpeg', '.png', '.webp'];

  static Future<List<String>> load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

    final paths = manifest.listAssets().where((path) {
      final lower = path.toLowerCase();
      return lower.startsWith(_folder) && _extensions.any(lower.endsWith);
    }).toList();

    // a, b, ... z, aa, ab, ac (shorter names first, then alphabetical).
    paths.sort((x, y) {
      final nameX = _baseName(x);
      final nameY = _baseName(y);
      final byLength = nameX.length.compareTo(nameY.length);
      return byLength != 0 ? byLength : nameX.compareTo(nameY);
    });

    return paths;
  }

  static String _baseName(String path) =>
      path.split('/').last.split('.').first;
}

class GallerySection extends StatefulWidget {
  final bool isArabic;
  const GallerySection({super.key, required this.isArabic});

  @override
  State<GallerySection> createState() => _GallerySectionState();
}

class _GallerySectionState extends State<GallerySection> {
  // Start with one page of photos and let the visitor ask for more.
  static const int _initialCount = 12;

  // Created once. Creating it inside build() would reload the manifest
  // on every rebuild (for example when "Show more" is tapped).
  late final Future<List<String>> _imagesFuture;

  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _imagesFuture = GalleryImages.load();
  }

  void _openViewer(String path) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.asset(path, fit: BoxFit.contain),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.isArabic;
    final width = MediaQuery.sizeOf(context).width;
    final cols = width > Breakpoints.tablet
        ? 4
        : (width > Breakpoints.mobile ? 3 : 2);

    return FutureBuilder<List<String>>(
      future: _imagesFuture,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState != ConnectionState.done;
        final all = snapshot.data ?? const <String>[];

        // Finished loading but there are no images: hide the whole section.
        if (!isLoading && all.isEmpty) return const SizedBox.shrink();

        final visible = _expanded ? all : all.take(_initialCount).toList();

        return Container(
          color: AppColors.cream2,
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: SiteContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  kicker: Content.galleryKicker.of(isArabic),
                  title: Content.galleryTitle.of(isArabic),
                ),
                const SizedBox(height: 32),
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: visible.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      // The photos are portrait, so portrait tiles crop less.
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (context, i) => _GalleryTile(
                      path: visible[i],
                      onTap: () => _openViewer(visible[i]),
                    ),
                  ),
                if (!isLoading && !_expanded && all.length > _initialCount) ...[
                  const SizedBox(height: 32),
                  Center(
                    child: OutlineButton(
                      label: Content.galleryMore.of(isArabic),
                      borderColor: AppColors.goldDark,
                      textColor: AppColors.ink,
                      onTap: () => setState(() => _expanded = true),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final String path;
  final VoidCallback onTap;

  const _GalleryTile({
    required this.path,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open photo',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              path,
              fit: BoxFit.cover,
              cacheWidth: 600,
              // Safety net only. Paths now come from the asset manifest,
              // so this should rarely run.
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0x11000000),
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(onTap: onTap),
            ),
          ],
        ),
      ),
    );
  }
}

class CtaSection extends StatelessWidget {
  final bool isArabic;
  const CtaSection({super.key, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.ink,
      padding: const EdgeInsets.symmetric(vertical: 90, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Text(
                Content.ctaKicker.of(isArabic),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFC9BFAE), fontSize: 15),
              ),
              const SizedBox(height: 10),
              Text(
                Content.ctaTitle.of(isArabic),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFF4EDE0),
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 36),
              InkWell(
                onTap: () => launchUrlSafely(Content.phoneTel),
                child: Text(
                  Content.phoneDisplay,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                Content.ctaAddress.of(isArabic),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFC9BFAE), fontSize: 15),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: Content.ctaButton.of(isArabic),
                onTap: () => launchUrlSafely(Content.whatsappUrl),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SiteFooter extends StatelessWidget {
  final bool isArabic;
  const SiteFooter({super.key, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            Content.footerName.of(isArabic),
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('•', style: TextStyle(color: AppColors.muted)),
          ),
          Text(
            Content.footerCity.of(isArabic),
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}