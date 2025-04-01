// lib/ui/shared/widgets/cartoon_room_item.dart
import 'package:flutter/material.dart';
import '../../../data/models/room.dart';
import '../styles/cartoon_theme.dart';
import 'cartoon_card.dart';

class CartoonRoomItem extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;

  const CartoonRoomItem({
    Key? key,
    required this.room,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CartoonCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Room header
          Container(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: room.isPremium
                  ? CartoonTheme.secondary.withOpacity(0.2)
                  : CartoonTheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(CartoonTheme.borderRadius - 2),
                topRight: Radius.circular(CartoonTheme.borderRadius - 2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.meeting_room,
                  color: room.isPremium
                      ? CartoonTheme.secondary
                      : CartoonTheme.primary,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    room.name,
                    style: CartoonTheme.bodyStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildRoomTypeChip(),
              ],
            ),
          ),

          // Room content
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.description,
                  style: CartoonTheme.captionStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(
                      Icons.people,
                      '${room.participantDisplay}',
                      'participants',
                    ),
                    if (room.isPrivate)
                      _buildInfoItem(
                        Icons.lock,
                        'Private',
                        'Room',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypeChip() {
    final isGold = room.isPremium;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isGold ? CartoonTheme.secondary : CartoonTheme.primary,
        borderRadius: BorderRadius.circular(CartoonTheme.smallBorderRadius),
        boxShadow: [
          BoxShadow(
            color: (isGold ? CartoonTheme.secondary : CartoonTheme.primary)
                .withOpacity(0.3),
            offset: Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: Text(
        room.roomType.toUpperCase(),
        style: CartoonTheme.captionStyle.copyWith(
          color: CartoonTheme.textLight,
          fontWeight: FontWeight.bold,
          fontSize: 10,
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
          color: CartoonTheme.textSecondary,
        ),
        SizedBox(width: 4),
        Text(
          '$value $label',
          style: CartoonTheme.captionStyle,
        ),
      ],
    );
  }
}
