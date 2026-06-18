import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<File?> compressImage(XFile image) async {
  final tempDir = await getTemporaryDirectory();
  final targetPath = path.join(
    tempDir.path,
    "${DateTime.now().microsecondsSinceEpoch}.jpg",
  );

  final XFile? finalImage = await FlutterImageCompress.compressAndGetFile(
    image.path,
    targetPath,
    minWidth: 800,
    quality: 80,
  );

  if (finalImage == null) return null;

  return File(finalImage.path);
}

Future<List<File>> compressListImage(List<XFile> images) async {
  final results = await Future.wait(images.map((img) => compressImage(img)));

  return results.whereType<File>().toList();
}
