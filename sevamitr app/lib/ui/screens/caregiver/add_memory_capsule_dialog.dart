import 'package:flutter/material.dart';
import 'package:dementia_ner_care/core/theme/dementia_theme.dart';
import 'package:dementia_ner_care/data/models/memory_capsule_model.dart';
import 'package:dementia_ner_care/data/database/offline_database.dart';
import 'package:dementia_ner_care/core/localization/app_localizations.dart';

/// Caregiver Dialog to Record Voice Stories and Add Family Photo Prompts
class AddMemoryCapsuleDialog extends StatefulWidget {
  final VoidCallback onCapsuleAdded;

  const AddMemoryCapsuleDialog({
    super.key,
    required this.onCapsuleAdded,
  });

  @override
  State<AddMemoryCapsuleDialog> createState() => _AddMemoryCapsuleDialogState();
}

class _AddMemoryCapsuleDialogState extends State<AddMemoryCapsuleDialog> {
  final _titleController = TextEditingController();
  final _relationController = TextEditingController();
  final _storyController = TextEditingController();
  final _regionalStoryController = TextEditingController();
  final _quizQuestionController = TextEditingController();
  final _correctOptionController = TextEditingController();
  final _distractor1Controller = TextEditingController();
  final _distractor2Controller = TextEditingController();

  bool _isSaving = false;

  Future<void> _saveCapsule() async {
    if (_titleController.text.isEmpty || _storyController.text.isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    final capsule = MemoryCapsule(
      title: _titleController.text.trim(),
      relationTag: _relationController.text.trim().isEmpty
          ? "Family Memory"
          : _relationController.text.trim(),
      photoAssetPath: "assets/images/custom_memory.png",
      audioStoryText: _storyController.text.trim(),
      audioStoryTextRegional: _regionalStoryController.text.trim(),
      recordedDateFormatted: "Today",
      quizQuestion: _quizQuestionController.text.trim().isEmpty
          ? "Who is in this memory with you?"
          : _quizQuestionController.text.trim(),
      quizQuestionRegional: "এইখন ছবিত কোন আছে?",
      quizOptions: [
        _correctOptionController.text.trim().isEmpty
            ? "Family Member"
            : _correctOptionController.text.trim(),
        _distractor1Controller.text.trim().isEmpty
            ? "Doctor"
            : _distractor1Controller.text.trim(),
        _distractor2Controller.text.trim().isEmpty
            ? "Friend"
            : _distractor2Controller.text.trim(),
      ],
      correctOptionIndex: 0,
    );

    await OfflineDatabase.instance.insertMemoryCapsule(capsule);
    widget.onCapsuleAdded();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: DementiaColors.canvasWarmCream,
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 650, maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_photo_alternate,
                          color: DementiaColors.actionForestGreen, size: 28),
                      SizedBox(width: 8),
                      Text(
                        context.tr('add_memory_capsule'),
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: DementiaColors.textPrimaryDark),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Upload a family photo and record a gentle story that the patient can listen to during reminiscence sessions.",
                style: TextStyle(
                    fontSize: 14, color: DementiaColors.textSecondaryDark),
              ),
              const SizedBox(height: 16),

              // Title
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: context.tr('memory_title_input'),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Relation
              TextField(
                controller: _relationController,
                decoration: InputDecoration(
                  labelText: context.tr('relation_tag_input'),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Story in English
              TextField(
                controller: _storyController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.tr('story_input'),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Story in Regional Language
              TextField(
                controller: _regionalStoryController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: context.tr('regional_story_input'),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Quiz Options
              TextField(
                controller: _correctOptionController,
                decoration: InputDecoration(
                  labelText: context.tr('correct_answer_input'),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: _distractor1Controller,
                decoration: InputDecoration(
                  labelText: context.tr('distractor_input'),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveCapsule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DementiaColors.actionForestGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.check),
                label: Text(
                    _isSaving
                        ? context.tr('saving')
                        : context.tr('save_memory_capsule'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
