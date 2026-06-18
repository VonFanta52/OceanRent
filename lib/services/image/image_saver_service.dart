import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String?> uploadToCloudinary(File image) async {
  final url = Uri.parse(
    "https://api.cloudinary.com/v1_1/ddkl78gti/image/upload",
  );

  final request = http.MultipartRequest("POST", url)
    ..fields['upload_preset'] = "basico"
    ..files.add(await http.MultipartFile.fromPath('file', image.path));

  final response = await request.send();

  final responseData = await response.stream.bytesToString();

  if (response.statusCode == 200) {
    final json = jsonDecode(responseData);
    return json['secure_url'];
  } else {
    return null;
  }
}

Future<List<String>> uploadImages(List<File> images) async {
  final results = await Future.wait(
    images.map((img) => uploadToCloudinary(img)),
  );

  return results.whereType<String>().toList();
}
