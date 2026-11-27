import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/widgets/views/item_image_view.dart';

/// A reusable section for managing item media: main image, gallery of sub-images,
/// and video demonstration URL.
class ItemMediaSection extends StatefulWidget {
  final TextEditingController mainImageController;
  final List<String> subImages;
  final ValueChanged<List<String>> onSubImagesChanged;
  final TextEditingController videoController;

  const ItemMediaSection({
    super.key,
    required this.mainImageController,
    required this.subImages,
    required this.onSubImagesChanged,
    required this.videoController,
  });

  @override
  State<ItemMediaSection> createState() => _ItemMediaSectionState();
}

class _ItemMediaSectionState extends State<ItemMediaSection> {
  static const _allowedImageExtensions = ['png', 'jpg', 'jpeg', 'webp', 'bmp'];
  static const _allowedVideoExtensions = [
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
    'wmv',
  ];

  Future<List<String>> _pickImageSources({required bool allowMultiple}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedImageExtensions,
        allowMultiple: allowMultiple,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return const [];

      final sources = <String>[];
      for (final file in result.files) {
        final path = file.path?.trim();
        if (path != null && path.isNotEmpty && File(path).existsSync()) {
          sources.add(path);
          continue;
        }
        final bytes = file.bytes;
        if (bytes != null && bytes.isNotEmpty) {
          final ext = (file.extension ?? 'png').toLowerCase();
          final mime = ext == 'jpg' ? 'jpeg' : ext;
          sources.add('data:image/$mime;base64,${base64Encode(bytes)}');
        }
      }
      return sources;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر اختيار الصورة: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
      return const [];
    }
  }

  Future<void> _pickMainImageFromDesktop() async {
    final picked = await _pickImageSources(allowMultiple: false);
    if (picked.isNotEmpty && mounted) {
      setState(() {
        widget.mainImageController.text = picked.first;
      });
    }
  }

  Future<void> _pickSubImagesFromDesktop() async {
    final picked = await _pickImageSources(allowMultiple: true);
    if (picked.isNotEmpty && mounted) {
      final updated = List<String>.from(widget.subImages);
      for (final src in picked) {
        if (!updated.contains(src)) {
          updated.add(src);
        }
      }
      widget.onSubImagesChanged(updated);
    }
  }

  Future<void> _pickVideoFromDesktop() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedVideoExtensions,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path?.trim();
      if (path != null && path.isNotEmpty && mounted) {
        setState(() {
          widget.videoController.text = path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر اختيار الفيديو: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showAddSubImageDialog() {
    final urlCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة صورة فرعية'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رابط الصورة (URL)',
                    hintText: 'https://example.com/image.jpg',
                    prefixIcon: Icon(Icons.link),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                if (urlCtrl.text.trim().isNotEmpty) ...[
                  const Text(
                    'معاينة:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ItemImageView(
                        source: urlCtrl.text.trim(),
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                        fallback: Container(
                          height: 120,
                          width: 120,
                          color: Colors.grey[200],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.grey),
                              SizedBox(height: 4),
                              Text(
                                'الرابط غير صالح',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  final url = urlCtrl.text.trim();
                  if (url.isNotEmpty) {
                    final updated = List<String>.from(widget.subImages);
                    if (!updated.contains(url)) {
                      updated.add(url);
                      widget.onSubImagesChanged(updated);
                    }
                    Navigator.pop(dialogCtx);
                  }
                },
                child: const Text('إضافة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.actionBlue),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.actionBlue, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Image Input & Preview
        _buildMainImageInput(),
        const SizedBox(height: 16),

        // Sub-images List
        _buildSubImagesList(),
        const SizedBox(height: 16),

        // Video URL Input & Preview
        _buildVideoInput(),
      ],
    );
  }

  Widget _buildMainImageInput() {
    final hasImage = widget.mainImageController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.mainImageController,
                decoration:
                    _buildDecoration(
                      'الصورة الرئيسية (رابط أو ملف من الجهاز)',
                      Icons.image_outlined,
                    ).copyWith(
                      hintText: 'https://example.com/main_image.jpg',
                      suffixIcon: hasImage
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                setState(
                                  () => widget.mainImageController.clear(),
                                );
                              },
                            )
                          : null,
                    ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 52,
              child: FilledButton.tonalIcon(
                onPressed: _pickMainImageFromDesktop,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('رفع من الجهاز'),
              ),
            ),
          ],
        ),
        if (hasImage) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ItemImageView(
                    source: widget.mainImageController.text.trim(),
                    height: 80,
                    width: 80,
                    fit: BoxFit.cover,
                    fallback: Container(
                      height: 80,
                      width: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معاينة الصورة الرئيسية',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'هذه هي الصورة التي ستظهر بشكل بارز في بطاقة العنصر',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubImagesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                'الصور الإضافية والفرعية (Sub-images) (${widget.subImages.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: _pickSubImagesFromDesktop,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('رفع من الجهاز'),
                ),
                TextButton.icon(
                  onPressed: _showAddSubImageDialog,
                  icon: const Icon(Icons.add_link, size: 18),
                  label: const Text('إضافة رابط'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.subImages.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 36,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 6),
                Text(
                  'لا توجد صور إضافية بعد',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.subImages.length,
              itemBuilder: (context, index) {
                final imgUrl = widget.subImages[index];
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ItemImageView(
                          source: imgUrl,
                          fit: BoxFit.cover,
                          fallback: Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Delete Button
                    Positioned(
                      top: 4,
                      right: 12,
                      child: InkWell(
                        onTap: () {
                          final updated = List<String>.from(widget.subImages)
                            ..removeAt(index);
                          widget.onSubImagesChanged(updated);
                        },
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: AppTheme.error,
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    // Set as Main Image Button
                    Positioned(
                      bottom: 4,
                      left: 12,
                      right: 4,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            widget.mainImageController.text = imgUrl;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم تعيين الصورة كصورة رئيسية'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'تعيين رئيسية',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildVideoInput() {
    final hasVideo = widget.videoController.text.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.videoController,
                decoration:
                    _buildDecoration(
                      'الفيديو (رابط أو ملف من الجهاز)',
                      Icons.videocam_outlined,
                    ).copyWith(
                      hintText:
                          'https://youtube.com/watch?v=... أو مسار ملف فيديو',
                      suffixIcon: hasVideo
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.open_in_new, size: 18),
                                  tooltip: 'معاينة / فتح الفيديو',
                                  onPressed: () async {
                                    try {
                                      final raw = widget.videoController.text
                                          .trim();
                                      final uri = File(raw).existsSync()
                                          ? Uri.file(raw)
                                          : Uri.tryParse(raw);
                                      if (uri != null &&
                                          await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      } else {
                                        if (mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('تعذر فتح الفيديو'),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (_) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('تعذر فتح الفيديو'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(
                                      () => widget.videoController.clear(),
                                    );
                                  },
                                ),
                              ],
                            )
                          : null,
                    ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 52,
              child: FilledButton.tonalIcon(
                onPressed: _pickVideoFromDesktop,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('رفع من الجهاز'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
