import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/config/theme.dart';

/// A reusable gallery viewer that displays an item's main image and sub-images horizontally.
class ItemGalleryViewer extends StatelessWidget {
  final String? mainImage;
  final List<String> subImages;

  const ItemGalleryViewer({
    super.key,
    this.mainImage,
    this.subImages = const [],
  });

  @override
  Widget build(BuildContext context) {
    final allImages = <String>[];
    if (mainImage != null && mainImage!.trim().isNotEmpty) {
      allImages.add(mainImage!.trim());
    }
    for (final img in subImages) {
      if (img.trim().isNotEmpty && !allImages.contains(img.trim())) {
        allImages.add(img.trim());
      }
    }

    if (allImages.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 40,
                color: Colors.grey,
              ),
              SizedBox(height: 6),
              Text(
                'لم يتم رفع صور لهذا العنصر',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allImages.length,
        itemBuilder: (context, index) {
          final isMain = index == 0 && mainImage != null;
          return Container(
            width: 150,
            margin: const EdgeInsets.only(left: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isMain ? AppTheme.actionBlue : AppTheme.border,
                width: isMain ? 2 : 1,
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    allImages[index],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                if (isMain)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.actionBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'رئيسية',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

