import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownViewer extends StatelessWidget {
  final String markdownData;

  const MarkdownViewer({super.key, required this.markdownData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Pre-process HTML badges to standard Markdown format
    var processedData = markdownData.replaceAllMapped(
      RegExp(r'<img[^>]+>', caseSensitive: false),
      (match) {
        final imgTag = match.group(0)!;
        final srcMatch = RegExp('src=["\']([^"\']+)["\']').firstMatch(imgTag);
        final altMatch = RegExp('alt=["\']([^"\']+)["\']').firstMatch(imgTag);
        final src = srcMatch?.group(1) ?? '';
        final alt = altMatch?.group(1) ?? '';
        return '![$alt]($src)';
      },
    );
    // Strip common wrapper tags used for badges on GitHub
    processedData = processedData.replaceAll(RegExp(r'<\/?(?:p|div)[^>]*>', caseSensitive: false), '');

    return MarkdownBody(
      data: processedData,
      selectable: true,
      onTapLink: (text, href, title) async {
        if (href != null) {
          final uri = Uri.parse(href);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      imageBuilder: (uri, title, alt) {
        var urlString = uri.toString();
        final isBadge = urlString.contains('shields.io');
        
        // Convert shields.io SVG badges to PNG on the fly to avoid flutter_svg text rendering bugs on Android
        if (isBadge && !urlString.contains('.png')) {
           if (urlString.contains('?')) {
             urlString = urlString.replaceFirst('?', '.png?');
           } else {
             urlString += '.png';
           }
        }

        // Detect actual SVGs (not shields.io)
        if (urlString.split('?').first.endsWith('.svg')) {
          return Padding(
            padding: const EdgeInsets.only(right: 6.0, bottom: 4.0),
            child: SvgPicture.network(
              urlString,
              height: 24, // Standard badge height constraint
              placeholderBuilder: (context) => const SizedBox(
                width: 24,
                height: 24,
                child: Padding(
                  padding: EdgeInsets.all(4.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }
        
        // Handle raster inline badges (including our converted shields.io PNGs)
        if (isBadge) {
          return Padding(
            padding: const EdgeInsets.only(right: 6.0, bottom: 4.0),
            child: Image.network(
              urlString,
              height: 24,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const SizedBox(
                  width: 24, height: 24,
                  child: Padding(
                    padding: EdgeInsets.all(4.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 24),
            ),
          );
        }

        // Handle standard large raster images
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              urlString,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 100,
                  width: double.infinity,
                  color: colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image, size: 40),
                );
              },
            ),
          ),
        );
      },
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
        h1: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
          height: 1.5,
        ),
        h2: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
          height: 1.5,
        ),
        h3: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        listBullet: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.primary,
        ),
        code: theme.textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          backgroundColor: colorScheme.surfaceContainerHighest,
          color: colorScheme.onSurfaceVariant,
        ),
        codeblockPadding: const EdgeInsets.all(12),
        codeblockDecoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        blockquote: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: colorScheme.primary,
              width: 4,
            ),
          ),
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        ),
        blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        tableBody: theme.textTheme.bodyMedium,
        tableHead: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        tableBorder: TableBorder.all(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
    );
  }
}
