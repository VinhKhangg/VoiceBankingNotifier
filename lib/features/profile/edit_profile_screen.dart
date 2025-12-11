import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:permission_handler/permission_handler.dart';
import 'change_password_screen.dart';
import '../../../models/user_model.dart';
import '../../../repositories/profile_repository.dart';

class EditProfileScreen extends StatefulWidget {
  // ✅ Nhận model từ màn hình trước
  final UserProfileModel initialProfile;
  const EditProfileScreen({super.key, required this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  final ProfileRepository _profileRepo = ProfileRepository(); // ✅ Khởi tạo repository
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isPhoneNumberEditable = true;

  final cloudinary = CloudinaryPublic('dp1wds7mo', 'tlbz1m6v', cache: false);

  @override
  void initState() {
    super.initState();
    // ✅ Điền dữ liệu vào controller từ model được truyền vào
    _nameController.text = widget.initialProfile.name ?? "";
    _photoUrlController.text = widget.initialProfile.photoURL ?? "";
    _phoneNumberController.text = widget.initialProfile.phoneNumber ?? "";
    if (widget.initialProfile.phoneNumber != null && widget.initialProfile.phoneNumber!.isNotEmpty) {
      _isPhoneNumberEditable = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _photoUrlController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  // Hàm _pickAndUploadImage giữ nguyên, không cần thay đổi
  Future<void> _pickAndUploadImage() async {
    final status = await Permission.photos.request();
    if (status.isGranted) {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile == null) return;
      setState(() => _isUploading = true);
      try {
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(
            pickedFile.path,
            resourceType: CloudinaryResourceType.Image,
          ),
        );
        setState(() {
          _photoUrlController.text = response.secureUrl;
          _isUploading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Tải ảnh lên thành công!"), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi tải ảnh: ${e.toString()}")));
        }
        setState(() => _isUploading = false);
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Yêu cầu cấp quyền"),
            content: const Text("Ứng dụng cần quyền truy cập thư viện ảnh để bạn có thể chọn ảnh đại diện. Vui lòng cấp quyền trong cài đặt."),
            actions: [
              TextButton(child: const Text("Để sau"), onPressed: () => Navigator.of(context).pop()),
              ElevatedButton(
                child: const Text("Mở Cài đặt"),
                onPressed: () {
                  openAppSettings();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    }
  }

  // ✅ Cập nhật hàm _updateProfile để dùng Repository
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Tạo một đối tượng UserProfileModel mới từ dữ liệu trên form
      final updatedProfile = widget.initialProfile.copyWith(
        name: _nameController.text.trim(),
        photoURL: _photoUrlController.text.trim(),
        phoneNumber: _isPhoneNumberEditable ? _phoneNumberController.text.trim() : widget.initialProfile.phoneNumber,
      );

      // Gọi repository để cập nhật
      await _profileRepo.updateUserProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Cập nhật thông tin thành công!"), backgroundColor: Colors.green),
        );
        // Trả về true để màn hình AccountScreen biết và tải lại dữ liệu
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(BuildContext context, {required String labelText, required IconData icon, Widget? suffixIcon}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: labelText,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Cập nhật UI để dùng widget.initialProfile cho các thông tin ban đầu
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chỉnh sửa thông tin"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isUploading ? null : _pickAndUploadImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                            backgroundImage: _photoUrlController.text.isNotEmpty ? NetworkImage(_photoUrlController.text) : null,
                            child: _photoUrlController.text.isEmpty
                                ? Text(
                              widget.initialProfile.name?.substring(0, 1).toUpperCase() ?? 'A',
                              style: TextStyle(fontSize: 45, color: theme.colorScheme.primary),
                            )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                            ),
                            child: _isUploading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.initialProfile.email ?? "Không có email",
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration(context, labelText: "Tên hiển thị", icon: Icons.person_outline),
                validator: (value) => (value == null || value.trim().isEmpty) ? "Tên hiển thị không được để trống" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneNumberController,
                decoration: _inputDecoration(
                  context,
                  labelText: "Số điện thoại",
                  icon: Icons.phone_outlined,
                  suffixIcon: !_isPhoneNumberEditable ? Icon(Icons.lock, color: Colors.grey.shade400) : null,
                ).copyWith(
                    helperText: !_isPhoneNumberEditable ? "Số điện thoại đã liên kết, không thể thay đổi." : "Dùng để xác thực khi liên kết ngân hàng."
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                readOnly: !_isPhoneNumberEditable,
                validator: (value) {
                  if (_isPhoneNumberEditable) {
                    if (value == null || value.trim().isEmpty) return "Vui lòng nhập số điện thoại";
                    if (value.length < 10 || value.length > 11) return "Số điện thoại không hợp lệ";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Offstage(offstage: true, child: TextFormField(controller: _photoUrlController, readOnly: true)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.save_outlined),
                label: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Lưu thay đổi"),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                icon: const Icon(Icons.password_outlined),
                label: const Text("Đổi mật khẩu"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
