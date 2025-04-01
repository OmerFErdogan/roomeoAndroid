// lib/ui/screens/home/home_screen.dart
// İlk satırlarda import kısmını şu şekilde güncellemelisiniz:

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/room_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/models/room.dart';
import '../../shared/widgets/modern_card.dart';
import '../../shared/widgets/modern_button.dart';
import '../../shared/styles/modern_theme.dart';

// Modern bileşenleri manuel olarak implemente edelim
// ModernRoomItem widget'ı için basit bir uygulama

class ModernRoomItem extends StatelessWidget {
  final Room room;
  final bool isActive;
  final VoidCallback onTap;
  final bool showActions;

  const ModernRoomItem({
    Key? key,
    required this.room,
    required this.onTap,
    this.isActive = false,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
        boxShadow:
            isActive ? ModernTheme.defaultShadow : ModernTheme.lightShadow,
        border: isActive
            ? Border.all(
                color: ModernTheme.primary.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(ModernTheme.borderRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildContent(context),
              if (showActions) _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? ModernTheme.primary.withOpacity(0.05) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: ModernTheme.borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: room.isPremium
                  ? ModernTheme.warning.withOpacity(0.1)
                  : ModernTheme.primary.withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(ModernTheme.smallBorderRadius),
            ),
            child: Icon(
              room.isPremium ? Icons.star : Icons.meeting_room,
              color: room.isPremium ? ModernTheme.warning : ModernTheme.primary,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: ModernTheme.titleStyle.copyWith(
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 14,
                      color: ModernTheme.textSecondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "${room.currentParticipants}/${room.maxParticipants}",
                      style: ModernTheme.captionStyle,
                    ),
                    if (room.isPrivate) ...[
                      SizedBox(width: 12),
                      Icon(
                        Icons.lock,
                        size: 14,
                        color: ModernTheme.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Özel",
                        style: ModernTheme.captionStyle,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _buildRoomTypeChip(),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            room.description,
            style: ModernTheme.bodyStyle.copyWith(
              color: ModernTheme.textSecondary,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildInfoItem(Icons.calendar_today, _formatDate(room.createdAt),
                  'Oluşturuldu'),
              SizedBox(width: 16),
              _buildInfoItem(Icons.access_time,
                  isActive ? 'Aktif' : 'Aktif Değil', 'Durum'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ModernTheme.backgroundLight,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(ModernTheme.borderRadius),
          bottomRight: Radius.circular(ModernTheme.borderRadius),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Oda Tipi: ${room.roomType.toUpperCase()}',
            style: ModernTheme.captionStyle.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.arrow_forward,
                size: 18,
                color: ModernTheme.primary,
              ),
              SizedBox(width: 4),
              Text(
                'Odaya Gir',
                style: ModernTheme.captionStyle.copyWith(
                  color: ModernTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypeChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: room.isPremium
            ? ModernTheme.warning.withOpacity(0.1)
            : ModernTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        room.roomType.toUpperCase(),
        style: ModernTheme.chipTextStyle.copyWith(
          color: room.isPremium ? ModernTheme.warning : ModernTheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: ModernTheme.textSecondary,
        ),
        SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: ModernTheme.captionStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: ModernTheme.textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: ModernTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
