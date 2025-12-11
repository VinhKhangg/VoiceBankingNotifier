// D:/FileMonHoc/Khoa_Luan_Tot_Nghiep/Project/lib/services/api_service.dart

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

const String _backendUrl = 'http://10.0.2.2:3000'; // Đảm bảo URL này đúng

/// Helper function to call backend API with Firebase ID Token.
/// Supports different HTTP methods and can return dynamic JSON types (Map or List).
// ✅✅✅ SỬA LẠI KIỂU TRẢ VỀ THÀNH Future<dynamic> ✅✅✅
Future<dynamic> callBackendApi(
    String endpoint,
    Map<String, dynamic> body,
    { String method = 'POST' }
    ) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('Người dùng chưa đăng nhập.');
  }

  final idToken = await user.getIdToken();
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $idToken',
  };

  http.Response response;
  final uri = Uri.parse('$_backendUrl$endpoint');

  switch (method.toUpperCase()) {
    case 'GET':
      response = await http.get(uri, headers: headers);
      break;
    case 'DELETE':
      response = await http.delete(uri, headers: headers, body: jsonEncode(body));
      break;
    case 'POST':
    default:
      response = await http.post(uri, headers: headers, body: jsonEncode(body));
      break;
  }

  if (response.statusCode >= 200 && response.statusCode < 300) {
    if (response.body.isEmpty) {
      // Với các request thành công nhưng không có body (e.g., DELETE), trả về Map rỗng
      return {};
    }
    // Trả về kết quả đã được decode, có thể là Map hoặc List
    return jsonDecode(response.body);
  } else {
    final errorBody = jsonDecode(response.body);
    throw Exception(errorBody['message'] ?? 'Lỗi không xác định từ server (Mã: ${response.statusCode}).');
  }
}
