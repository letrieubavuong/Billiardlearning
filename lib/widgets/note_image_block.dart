import 'dart:io';

import 'package:flutter/material.dart';

import '../models/image_block_data.dart';

class NoteImageBlock extends StatelessWidget {
  const NoteImageBlock({
    super.key,
    required this.data,
    this.previewHeight,
    this.enableFullscreen = true,
  });

  final ImageBlockData data;
  final double? previewHeight;
  final bool enableFullscreen;

  @override
  Widget build(BuildContext context) {
    final image = _buildImage(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: SizedBox(
              height: previewHeight,
              child: data.source.isEmpty
                  ? _errorPlaceholder(context, 'Chưa có hình ảnh')
                  : image,
            ),
          ),
        ),
        if (data.caption.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            data.caption.trim(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: enableFullscreen && data.source.isNotEmpty
          ? Semantics(
              button: true,
              label: data.altText.isEmpty
                  ? 'Mở hình ảnh toàn màn hình'
                  : '${data.altText}. Mở toàn màn hình',
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openFullscreen(context),
                child: content,
              ),
            )
          : content,
    );
  }

  Widget _buildImage(BuildContext context, {BoxFit? fit}) {
    final resolvedFit =
        fit ?? (data.fit == 'cover' ? BoxFit.cover : BoxFit.contain);
    if (data.isNetwork) {
      return Image.network(
        data.source,
        fit: resolvedFit,
        semanticLabel: data.altText.isEmpty ? null : data.altText,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          final total = progress.expectedTotalBytes;
          return Center(
            child: CircularProgressIndicator(
              value: total == null
                  ? null
                  : progress.cumulativeBytesLoaded / total,
            ),
          );
        },
        errorBuilder: (context, error, stack) =>
            _errorPlaceholder(context, 'Không tải được hình ảnh'),
      );
    }
    return Image.file(
      File(data.source),
      fit: resolvedFit,
      semanticLabel: data.altText.isEmpty ? null : data.altText,
      errorBuilder: (context, error, stack) =>
          _errorPlaceholder(context, 'Không tìm thấy hình ảnh'),
    );
  }

  Widget _errorPlaceholder(BuildContext context, String message) {
    return SizedBox(
      height: previewHeight ?? 160,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(data.caption.isEmpty ? 'Hình ảnh' : data.caption),
          ),
          body: SafeArea(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 5,
              child: Center(child: _buildImage(context, fit: BoxFit.contain)),
            ),
          ),
        ),
      ),
    );
  }
}
