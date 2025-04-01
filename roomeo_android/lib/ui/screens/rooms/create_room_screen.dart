// lib/ui/screens/rooms/create_room_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/room_provider.dart';
import '../../shared/styles/modern_theme.dart';
import '../../shared/widgets/modern_button.dart';
import '../../shared/widgets/modern_text_field.dart';

class CreateRoomScreen extends StatefulWidget {
  @override
  _CreateRoomScreenState createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _roomType = 'normal';
  bool _isPrivate = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Oda Oluştur',
          style: ModernTheme.titleStyle,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: ModernTheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(),
                SizedBox(height: 32),
                ModernTextField(
                  controller: _nameController,
                  label: 'Oda Adı',
                  hintText: 'Odanıza bir isim verin',
                  prefixIcon: Icons.meeting_room,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Lütfen bir oda adı girin';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                ModernTextField(
                  controller: _descriptionController,
                  label: 'Açıklama',
                  hintText: 'Odanızı kısaca açıklayın',
                  prefixIcon: Icons.description,
                  maxLines: 3,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Lütfen bir açıklama girin';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32),
                Text(
                  'Oda Türü',
                  style: ModernTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                _buildRoomTypeSelection(),
                SizedBox(height: 32),
                _buildPrivacySection(),
                SizedBox(height: 48),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yeni Oda Oluştur',
          style: ModernTheme.headingStyle,
        ),
        SizedBox(height: 8),
        Text(
          'Diğer kullanıcıların katılabileceği bir çalışma odası oluşturun.',
          style: ModernTheme.captionStyle.copyWith(
            color: ModernTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomTypeSelection() {
    return Row(
      children: [
        Expanded(
          child: _buildRoomTypeOption(
            title: 'Normal',
            description: '6 katılımcı',
            icon: Icons.people,
            isSelected: _roomType == 'normal',
            onTap: () {
              setState(() {
                _roomType = 'normal';
              });
            },
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildRoomTypeOption(
            title: 'Premium',
            description: '18 katılımcı',
            icon: Icons.star,
            isSelected: _roomType == 'premium',
            onTap: () {
              setState(() {
                _roomType = 'premium';
              });
            },
            isPremium: true,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomTypeOption({
    required String title,
    required String description,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isPremium = false,
  }) {
    final Color primaryColor =
        isPremium ? ModernTheme.warning : ModernTheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
          border: Border.all(
            color: isSelected ? primaryColor : ModernTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    offset: Offset(0, 4),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 24,
              ),
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: ModernTheme.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              description,
              style: ModernTheme.captionStyle,
            ),
            SizedBox(height: 12),
            if (isSelected)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Seçildi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _isPrivate ? Icons.lock : Icons.public,
                color: _isPrivate ? ModernTheme.warning : ModernTheme.primary,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Gizlilik Ayarı',
                  style: ModernTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: _isPrivate,
                onChanged: (value) {
                  setState(() {
                    _isPrivate = value;
                  });
                },
                activeColor: ModernTheme.warning,
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _isPrivate
                ? 'Özel odalar için sistem otomatik olarak erişim kodu oluşturur. Bu kodu istediğiniz kişilere göndererek odanıza davet edebilirsiniz.'
                : 'Genel odalar herkese açıktır ve arama sonuçlarında görünür.',
            style: ModernTheme.captionStyle,
          ),
          if (_isPrivate) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ModernTheme.warning.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(ModernTheme.smallBorderRadius),
                border: Border.all(
                  color: ModernTheme.warning.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: ModernTheme.warning,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Oda oluşturulduğunda size bir erişim kodu gösterilecek.',
                      style: ModernTheme.captionStyle.copyWith(
                        color: ModernTheme.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ModernButton(
      text: 'Oda Oluştur',
      icon: Icons.add_circle,
      type: ModernButtonType.primary,
      isLoading: _isSubmitting,
      onPressed: _isSubmitting ? null : _createRoom,
    );
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final room = await context.read<RoomProvider>().createRoom(
            name: _nameController.text,
            description: _descriptionController.text,
            roomType: _roomType,
            isPrivate: _isPrivate,
          );

      if (room.isPrivate) {
        // Erişim kodunu göster
        _showAccessCodeDialog(room.accessCode ?? '');
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: ModernTheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showAccessCodeDialog(String accessCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: ModernTheme.success),
            SizedBox(width: 8),
            Text('Oda Oluşturuldu', style: ModernTheme.titleStyle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Odanız başarıyla oluşturuldu. Bu erişim kodunu odanıza katılmasını istediğiniz kişilerle paylaşın:',
              style: ModernTheme.bodyStyle,
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: ModernTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
                border: Border.all(
                  color: ModernTheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    accessCode,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: ModernTheme.primary,
                      letterSpacing: 2.0,
                    ),
                  ),
                  SizedBox(width: 12),
                  IconButton(
                    icon: Icon(Icons.copy, color: ModernTheme.primary),
                    onPressed: () {
                      // Access code'u kopyalama işlemi
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('Kapat'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
        ),
      ),
    );
  }
}
