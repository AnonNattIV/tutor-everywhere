// lib/pages/tutor/profile_tab.dart
import 'package:flutter/material.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    required this.dateOfBirth,
    required this.preferredPlace,
    required this.bio,
    required this.isEditingBio,
    required this.isEditingPreferredPlace,
    required this.bioController,
    required this.preferredPlaceController,
    required this.onStartEditBio,
    required this.onCancelEditBio,
    required this.onSaveBio,
    required this.onStartEditPreferredPlace,
    required this.onCancelEditPreferredPlace,
    required this.onSavePreferredPlace,
    this.canEdit = false,
  });

  final String dateOfBirth;
  final String preferredPlace;
  final String bio;
  final bool isEditingBio;
  final bool isEditingPreferredPlace;
  final TextEditingController bioController;
  final TextEditingController preferredPlaceController;
  final VoidCallback onStartEditBio;
  final VoidCallback onCancelEditBio;
  final VoidCallback onSaveBio;
  final VoidCallback onStartEditPreferredPlace;
  final VoidCallback onCancelEditPreferredPlace;
  final VoidCallback onSavePreferredPlace;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date of Birth (read-only)
          _buildInfoRow('Date of birth', dateOfBirth),
          const SizedBox(height: 12),
          
          // Preferred Place (editable)
          _buildEditableRow(
            label: 'Preferred place',
            value: preferredPlace,
            isEditing: isEditingPreferredPlace,
            controller: preferredPlaceController,
            onStartEdit: onStartEditPreferredPlace,
            onCancelEdit: onCancelEditPreferredPlace,
            onSave: onSavePreferredPlace,
            canEdit: canEdit,
            hintText: 'e.g., Chatuchak / Home / Cafe',
          ),
          const SizedBox(height: 16),
          
          // Bio (editable)
          _buildEditableRow(
            label: 'Bio',
            value: bio,
            isEditing: isEditingBio,
            controller: bioController,
            onStartEdit: onStartEditBio,
            onCancelEdit: onCancelEditBio,
            onSave: onSaveBio,
            canEdit: canEdit,
            hintText: 'Tell students about yourself...',
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        children: [
          TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.w600)),
          TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEditableRow({
    required String label,
    required String value,
    required bool isEditing,
    required TextEditingController controller,
    required VoidCallback onStartEdit,
    required VoidCallback onCancelEdit,
    required VoidCallback onSave,
    required bool canEdit,
    required String hintText,
    int maxLines = 2,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            if (canEdit)
              IconButton(
                onPressed: isEditing ? null : onStartEdit,
                icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Edit $label',
              ),
          ],
        ),
        const SizedBox(height: 4),
        if (isEditing && canEdit) ...[
          TextField(
            controller: controller,
            maxLines: maxLines,
            minLines: 1,
            autofocus: true,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onCancelEdit, child: const Text('Cancel')),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: onSave, child: const Text('Save')),
            ],
          ),
        ] else
          Text(
            value,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: maxLines > 1 ? 1.5 : 1,
            ),
          ),
      ],
    );
  }
}