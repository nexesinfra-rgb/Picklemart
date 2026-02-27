import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ionicons/ionicons.dart';
import '../../data/bill_model.dart';
import '../../application/bill_controller.dart';
import '../../../../media_upload_widget.dart';

class BillTemplateUploadWidget extends ConsumerStatefulWidget {
  final BillType billType;
  final VoidCallback? onTemplateUploaded;

  const BillTemplateUploadWidget({
    super.key,
    required this.billType,
    this.onTemplateUploaded,
  });

  @override
  ConsumerState<BillTemplateUploadWidget> createState() =>
      _BillTemplateUploadWidgetState();
}

class _BillTemplateUploadWidgetState
    extends ConsumerState<BillTemplateUploadWidget> {
  final _templateNameController = TextEditingController();
  MediaUploadResult? _selectedImage;
  bool _isUploading = false;

  @override
  void dispose() {
    _templateNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Template name input
        TextField(
          controller: _templateNameController,
          decoration: InputDecoration(
            labelText: 'Template Name',
            hintText: 'e.g., Standard Bill Format',
            prefixIcon: const Icon(Ionicons.document_text_outline),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Image upload
        MediaUploadWidget(
          label: 'Upload Bill Format Image',
          hint: 'Select bill format template image',
          allowImages: true,
          allowPdfs: false,
          maxImages: 1,
          onMediaSelected: (result) {
            setState(() {
              _selectedImage = result;
            });
          },
        ),

        // Preview
        if (_selectedImage != null) ...[
          const SizedBox(height: 16),
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _selectedImage!.path,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Ionicons.image_outline, size: 48),
                  );
                },
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Upload button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isUploading || _selectedImage == null
                ? null
                : _uploadTemplate,
            icon: _isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Ionicons.cloud_upload_outline),
            label: Text(_isUploading ? 'Uploading...' : 'Upload Template'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _uploadTemplate() async {
    if (_templateNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a template name')),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await ref.read(billControllerProvider.notifier).uploadBillTemplate(
            templateType: widget.billType,
            templateName: _templateNameController.text.trim(),
            image: _selectedImage!,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${widget.billType.displayName} template uploaded successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reset form
        _templateNameController.clear();
        setState(() {
          _selectedImage = null;
        });

        // Callback
        widget.onTemplateUploaded?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}

