import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ionicons/ionicons.dart';
import '../core/utils/logger.dart';

/// Comprehensive media upload widget with bottom sheet menu
class MediaUploadWidget extends StatefulWidget {
  final String? currentImagePath;
  final Function(MediaUploadResult) onMediaSelected;
  final Function(List<MediaUploadResult>)?
  onMultipleMediaSelected; // NEW: Support multiple uploads
  final Function(String)? onMediaRemoved;
  final Function(double progress)?
  onUploadProgress; // NEW: Upload progress callback
  final Function(String error)? onUploadError; // NEW: Upload error callback
  final double? width;
  final double? height;
  final String? label;
  final String? hint;
  final bool showPreview;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;

  // Upload limits
  final int maxImages;
  final int maxPdfs;
  final bool allowImages;
  final bool allowPdfs;
  final bool allowCamera;
  final bool allowGallery;
  final bool allowFiles;

  const MediaUploadWidget({
    super.key,
    this.currentImagePath,
    required this.onMediaSelected,
    this.onMultipleMediaSelected, // NEW: Optional multiple media callback
    this.onMediaRemoved,
    this.onUploadProgress, // NEW: Upload progress callback
    this.onUploadError, // NEW: Upload error callback
    this.width,
    this.height,
    this.label,
    this.hint,
    this.showPreview = true,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.maxImages = 25,
    this.maxPdfs = 5,
    this.allowImages = true,
    this.allowPdfs = true,
    this.allowCamera = true,
    this.allowGallery = true,
    this.allowFiles = true,
  });

  @override
  State<MediaUploadWidget> createState() => _MediaUploadWidgetState();
}

class _MediaUploadWidgetState extends State<MediaUploadWidget> {
  bool _isUploading = false;
  String? _errorMessage;
  final ImagePicker _imagePicker = ImagePicker();

  // New state for enhanced upload flow
  final List<MediaUploadResult> _selectedMedia = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
        ],

        // Media preview
        if (widget.showPreview && widget.currentImagePath != null) ...[
          Container(
            width: widget.width ?? double.infinity,
            height: widget.height ?? 200,
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              border: Border.all(
                color: widget.borderColor ?? Colors.grey.shade300,
                width: widget.borderWidth,
              ),
            ),
            child: ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
              child: _buildImageWidget(widget.currentImagePath!),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Upload button with bottom sheet
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isUploading ? null : _showMediaUploadBottomSheet,
            icon:
                _isUploading
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.cloud_upload_outlined),
            label: Text(_isUploading ? 'Uploading...' : 'Media Upload'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        // Remove button
        if (widget.currentImagePath != null &&
            widget.onMediaRemoved != null) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _removeMedia,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Remove Media'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],

        // Hint text
        if (widget.hint != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.hint!,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildImageWidget(String imagePath, {double? width, double? height}) {
    final targetWidth = width ?? widget.width ?? double.infinity;
    final targetHeight = height ?? widget.height ?? 200;

    // Handle Firebase URLs
    if (imagePath.startsWith('https://firebasestorage.googleapis.com')) {
      return Image.network(
        imagePath,
        width: targetWidth,
        height: targetHeight,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: targetWidth,
            height: targetHeight,
            color: Colors.grey.shade100,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.red),
            ),
          );
        },
      );
    }

    // Handle local file paths and blob URLs
    try {
      if (kIsWeb) {
        // On web, use Image.network for blob URLs
        return Image.network(
          imagePath,
          width: targetWidth,
          height: targetHeight,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: targetWidth,
              height: targetHeight,
              color: Colors.grey.shade100,
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.red),
              ),
            );
          },
        );
      } else {
        // On mobile, use Image.file
        return Image.file(
          File(imagePath),
          width: targetWidth,
          height: targetHeight,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: targetWidth,
              height: targetHeight,
              color: Colors.grey.shade100,
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.red),
              ),
            );
          },
        );
      }
    } catch (e) {
      Logger.warning(
        'MediaUploadWidget: Failed to load image from path: $imagePath',
        e,
      );

      return Container(
        width: targetWidth,
        height: targetHeight,
        color: Colors.grey.shade100,
        child: const Center(child: Icon(Icons.broken_image, color: Colors.red)),
      );
    }
  }

  void _showMediaUploadBottomSheet() {
    _selectedMedia.clear(); // Clear previous selections

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // Prevent dismissing by tapping outside
      enableDrag: false, // Prevent dismissing by dragging
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => MediaUploadBottomSheet(
                  onCameraPressed:
                      widget.allowCamera
                          ? () => _uploadFromCamera(setModalState)
                          : null,
                  onGalleryPressed:
                      widget.allowGallery
                          ? () => _uploadFromGallery(setModalState)
                          : null,
                  onFilesPressed:
                      widget.allowFiles
                          ? () => _uploadFromFiles(setModalState)
                          : null,
                  allowImages: widget.allowImages,
                  allowPdfs: widget.allowPdfs,
                  maxImages: widget.maxImages,
                  maxPdfs: widget.maxPdfs,
                  currentImagePath: widget.currentImagePath,
                  selectedMedia: _selectedMedia,
                  onUploadPressed: _finalizeUpload,
                  onCancelPressed: _cancelUpload,
                  onRemoveMedia:
                      (index) => _removeSelectedMedia(index, setModalState),
                ),
          ),
    );
  }

  Future<void> _uploadFromCamera(StateSetter setModalState) async {
    // Don't close bottom sheet - keep it open for preview
    await _addMediaToSelection(() => _pickImageFromCamera(), setModalState);
  }

  Future<void> _uploadFromGallery(StateSetter setModalState) async {
    // Don't close bottom sheet - keep it open for preview
    await _addMultipleMediaToSelection(
      () => _pickImageFromGallery(),
      setModalState,
    );
  }

  Future<void> _uploadFromFiles(StateSetter setModalState) async {
    // Don't close bottom sheet - keep it open for preview
    await _addMediaToSelection(() => _pickFiles(), setModalState);
  }

  Future<MediaUploadResult?> _pickImageFromCamera() async {
    try {
      Logger.debug('MediaUploadWidget: Starting camera picker...');

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        Logger.debug(
          'MediaUploadWidget: Image captured from camera: ${image.name}',
        );

        final bytes = await image.readAsBytes();
        final fileName = 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';

        Logger.debug(
          'MediaUploadWidget: Read ${bytes.length} bytes from camera image',
        );

        // Use XFile path directly (works on both web and mobile)
        final path = image.path;

        if (path.isNotEmpty) {
          Logger.success(
            'MediaUploadWidget: Camera image stored successfully at: $path',
          );
          return MediaUploadResult(
            path: path,
            fileName: fileName,
            fileType: MediaFileType.image,
            fileSize: bytes.length,
          );
        } else {
          throw Exception('Failed to store camera image in local storage');
        }
      } else {
        Logger.warning('MediaUploadWidget: No image captured from camera');
        return null;
      }
    } catch (e) {
      Logger.error(
        'MediaUploadWidget: Error picking image from camera',
        error: e,
        stackTrace: StackTrace.current,
      );

      // Show detailed error message
      if (mounted) {
        String errorMessage = 'Failed to upload selected file';
        String technicalDetails = '';

        if (kIsWeb) {
          errorMessage =
              'Camera access failed. Please ensure your webcam is connected and permissions are granted.';
          technicalDetails = 'Web camera error: $e';
        } else if (e.toString().contains('permission')) {
          errorMessage =
              'Camera permission denied. Please enable camera access in your device settings.';
          technicalDetails = 'Permission error: $e';
        } else if (e.toString().contains('not available')) {
          errorMessage = 'Camera not available on this device.';
          technicalDetails = 'Hardware error: $e';
        } else if (e.toString().contains('Failed to store')) {
          errorMessage = 'Failed to save camera image. Please try again.';
          technicalDetails = 'Storage error: $e';
        } else {
          technicalDetails = 'Technical error: $e';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorMessage,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (kDebugMode && technicalDetails.isNotEmpty)
                  Text(
                    technicalDetails,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
      return null;
    }
  }

  /// Pick images from gallery
  /// On Android 13+ (API 33+), this automatically uses the Android Photo Picker API
  /// which provides privacy-compliant image selection without full gallery access.
  /// The READ_MEDIA_IMAGES permission in AndroidManifest.xml enables this behavior.
  Future<List<MediaUploadResult>> _pickImageFromGallery() async {
    try {
      Logger.debug('MediaUploadWidget: Starting gallery picker...');

      // On Android 13+, image_picker automatically uses Photo Picker API
      // when READ_MEDIA_IMAGES permission is declared (which it is in AndroidManifest.xml)
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      Logger.debug(
        'MediaUploadWidget: Selected ${images.length} images from gallery',
      );

      List<MediaUploadResult> results = [];
      List<String> failedImages = [];

      for (final image in images) {
        try {
          Logger.debug('MediaUploadWidget: Processing image: ${image.name}');

          final bytes = await image.readAsBytes();
          final fileName =
              'gallery_${DateTime.now().millisecondsSinceEpoch}_${image.name}';

          Logger.debug(
            'MediaUploadWidget: Read ${bytes.length} bytes from ${image.name}',
          );

          // Use XFile path directly (works on both web and mobile)
          final path = image.path;

          if (path.isNotEmpty) {
            Logger.success(
              'MediaUploadWidget: Gallery image stored successfully: $fileName',
            );
            results.add(
              MediaUploadResult(
                path: path,
                fileName: fileName,
                fileType: MediaFileType.image,
                fileSize: bytes.length,
              ),
            );
          } else {
            throw Exception('Failed to store image in local storage');
          }
        } catch (e) {
          Logger.error(
            'MediaUploadWidget: Error processing image ${image.name}',
            error: e,
          );
          failedImages.add('${image.name}: $e');
        }
      }

      // Show summary of results
      if (mounted && (results.isNotEmpty || failedImages.isNotEmpty)) {
        if (failedImages.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully processed ${results.length} image(s) from gallery',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (results.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Processed ${results.length} of ${images.length} images successfully',
                  ),
                  if (kDebugMode)
                    Text(
                      'Failed: ${failedImages.join(', ')}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      return results;
    } catch (e) {
      Logger.error(
        'MediaUploadWidget: Error picking image from gallery',
        error: e,
        stackTrace: StackTrace.current,
      );

      // Show detailed error message
      if (mounted) {
        String errorMessage = 'Failed to upload selected file';
        String technicalDetails = '';

        if (kIsWeb) {
          errorMessage =
              'Gallery access failed. Please try using the Files option instead.';
          technicalDetails = 'Web gallery error: $e';
        } else if (e.toString().contains('permission')) {
          errorMessage =
              'Gallery permission denied. Please enable photo access in your device settings.';
          technicalDetails = 'Permission error: $e';
        } else if (e.toString().contains('Failed to store')) {
          errorMessage = 'Failed to save gallery images. Please try again.';
          technicalDetails = 'Storage error: $e';
        } else {
          technicalDetails = 'Technical error: $e';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorMessage,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (kDebugMode && technicalDetails.isNotEmpty)
                  Text(
                    technicalDetails,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
      return [];
    }
  }

  Future<MediaUploadResult?> _pickFiles() async {
    try {
      Logger.debug('MediaUploadWidget: Starting file picker...');

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions:
            widget.allowImages && widget.allowPdfs
                ? [
                  'jpg',
                  'jpeg',
                  'png',
                  'gif',
                  'pdf',
                  'mp4',
                  'mov',
                  'avi',
                  'mkv',
                ]
                : widget.allowImages
                ? ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'avi', 'mkv']
                : ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileName = file.name;

        Logger.debug('MediaUploadWidget: File selected - $fileName');
        Logger.debug('MediaUploadWidget: Platform is web: $kIsWeb');
        Logger.debug('MediaUploadWidget: File path: ${file.path}');
        Logger.debug(
          'MediaUploadWidget: File bytes available: ${file.bytes != null}',
        );

        Uint8List? bytes;

        // Handle platform differences for getting file bytes
        if (kIsWeb) {
          // On web, use file.bytes directly
          bytes = file.bytes;
          Logger.debug(
            'MediaUploadWidget: Using file.bytes for web (${bytes?.length ?? 0} bytes)',
          );
        } else {
          // On mobile (Android/iOS), file.bytes is null, use file.path
          if (file.path != null) {
            try {
              final fileObj = File(file.path!);
              if (await fileObj.exists()) {
                bytes = await fileObj.readAsBytes();
                Logger.debug(
                  'MediaUploadWidget: Read ${bytes.length} bytes from file path: ${file.path}',
                );
              } else {
                throw Exception('Selected file does not exist: ${file.path}');
              }
            } catch (e) {
              Logger.error('MediaUploadWidget: Error reading file from path', error: e);
              throw Exception('Failed to read selected file: $e');
            }
          } else {
            throw Exception('No file path available for selected file');
          }
        }

        if (bytes != null && bytes.isNotEmpty) {
          final fileType = _getFileType(fileName);

          // Handle path for web vs mobile
          String path;
          if (kIsWeb) {
            // On web, create a data URL from bytes for all file types
            // This allows the repository to decode the bytes directly
            final base64 = base64Encode(bytes);
            String mimeType;
            if (fileType == MediaFileType.image) {
              mimeType = fileName.toLowerCase().endsWith('.png')
                  ? 'image/png'
                  : fileName.toLowerCase().endsWith('.gif')
                  ? 'image/gif'
                  : fileName.toLowerCase().endsWith('.webp')
                  ? 'image/webp'
                  : 'image/jpeg';
            } else if (fileType == MediaFileType.pdf) {
              mimeType = 'application/pdf';
            } else {
              // Video
              mimeType = fileName.toLowerCase().endsWith('.mp4')
                  ? 'video/mp4'
                  : fileName.toLowerCase().endsWith('.mov')
                  ? 'video/quicktime'
                  : 'video/*';
            }
            path = 'data:$mimeType;base64,$base64';
          } else {
            // On mobile, use file.path
            path = file.path ?? '';
            if (path.isEmpty) {
              throw Exception('No file path available for selected file');
            }
          }

          if (path.isNotEmpty) {
            Logger.success('MediaUploadWidget: File stored at - $path');

            return MediaUploadResult(
              path: path,
              fileName: fileName,
              fileType: fileType,
              fileSize: bytes.length,
            );
          } else {
            throw Exception('Failed to store file in local storage');
          }
        } else {
          throw Exception(
            'No file data available - file may be corrupted or empty',
          );
        }
      } else {
        Logger.warning('MediaUploadWidget: No file selected or result is empty');
        return null;
      }
    } catch (e) {
      Logger.error(
        'MediaUploadWidget: Error picking files',
        error: e,
        stackTrace: StackTrace.current,
      );

      // Show detailed error message
      if (mounted) {
        String errorMessage = 'Failed to upload selected file';
        String technicalDetails = '';

        if (kIsWeb) {
          errorMessage =
              'File upload failed on web. Please ensure your browser supports file uploads.';
          technicalDetails = 'Web file picker error: $e';
        } else if (e.toString().contains('permission')) {
          errorMessage =
              'File access permission denied. Please enable file access in your device settings.';
          technicalDetails = 'Permission error: $e';
        } else if (e.toString().contains('does not exist')) {
          errorMessage =
              'Selected file could not be found. Please try selecting a different file.';
          technicalDetails = 'File not found: $e';
        } else if (e.toString().contains('corrupted') ||
            e.toString().contains('empty')) {
          errorMessage =
              'Selected file appears to be corrupted or empty. Please try a different file.';
          technicalDetails = 'File data error: $e';
        } else {
          technicalDetails = 'Technical error: $e';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorMessage,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (kDebugMode && technicalDetails.isNotEmpty)
                  Text(
                    technicalDetails,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
      return null;
    }
  }

  MediaFileType _getFileType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    if (['pdf'].contains(extension)) {
      return MediaFileType.pdf;
    } else if ([
      'mp4',
      'mov',
      'avi',
      'mkv',
      'webm',
      'flv',
    ].contains(extension)) {
      return MediaFileType.video;
    } else {
      return MediaFileType.image;
    }
  }

  Future<void> _addMultipleMediaToSelection(
    Future<List<MediaUploadResult>> Function() pickFunction,
    StateSetter setModalState,
  ) async {
    if (kDebugMode) {
            Logger.debug('🎬 MediaUploadWidget: Starting multiple media selection...');
            Logger.debug(
        '📊 MediaUploadWidget: Current _selectedMedia count: ${_selectedMedia.length}',
      );
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final results = await pickFunction();

      if (results.isNotEmpty) {
        if (kDebugMode) {
          Logger.debug(
            '✅ MediaUploadWidget: ${results.length} media items selected successfully',
          );
          Logger.debug(
            '📁 MediaUploadWidget: Selected files: ${results.map((r) => r.fileName).join(', ')}',
          );
        }

        // Create new list reference to force Flutter to detect changes
        final updatedMedia = List<MediaUploadResult>.from(_selectedMedia)
          ..addAll(results);

        setState(() {
          _selectedMedia.clear();
          _selectedMedia.addAll(updatedMedia);
        });

        // Force modal state update with new list reference
        setModalState(() {
          if (kDebugMode) {
            Logger.debug(
              '🔄 MediaUploadWidget: Modal state updated for multiple selection, triggering rebuild',
            );
          }
        });

        if (kDebugMode) {
          Logger.debug(
            '📝 MediaUploadWidget: Added to selection. Total items: ${_selectedMedia.length}',
          );
          Logger.debug(
            '📋 MediaUploadWidget: List contents: ${_selectedMedia.map((m) => m.fileName).join(', ')}',
          );
        }

        // Show success message - removed to prevent duplicate snackbars
      } else {
        if (kDebugMode) {
          Logger.debug('⚠️ MediaUploadWidget: No media selected');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        Logger.debug('❌ MediaUploadWidget: Error during media selection: $e');
      }

      setState(() {
        _errorMessage = 'Failed to select media: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select media: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _addMediaToSelection(
    Future<MediaUploadResult?> Function() pickFunction,
    StateSetter setModalState,
  ) async {
    if (kDebugMode) {
            Logger.debug('🎬 MediaUploadWidget: Starting media selection...');
            Logger.debug(
        '📊 MediaUploadWidget: Current _selectedMedia count: ${_selectedMedia.length}',
      );
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final result = await pickFunction();

      if (result != null) {
        if (kDebugMode) {
          Logger.debug(
            '✅ MediaUploadWidget: Media selected successfully - ${result.fileType} (${result.fileName})',
          );
          Logger.debug('📁 MediaUploadWidget: Stored path: ${result.path}');
        }

        // Create new list reference to force Flutter to detect changes
        final updatedMedia = List<MediaUploadResult>.from(_selectedMedia)
          ..add(result);

        setState(() {
          _selectedMedia.clear();
          _selectedMedia.addAll(updatedMedia);
        });

        // Force modal state update with new list reference
        setModalState(() {
          if (kDebugMode) {
            Logger.debug(
              '🔄 MediaUploadWidget: Modal state updated, triggering rebuild',
            );
          }
        });

        if (kDebugMode) {
          Logger.debug(
            '📝 MediaUploadWidget: Added to selection. Total items: ${_selectedMedia.length}',
          );
          Logger.debug(
            '📋 MediaUploadWidget: List contents: ${_selectedMedia.map((m) => m.fileName).join(', ')}',
          );
        }

        // Show success message - removed to prevent duplicate snackbars
      } else {
        if (kDebugMode) {
          Logger.debug('❌ MediaUploadWidget: No media selected');
        }

        // Show immediate feedback for no selection
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No media selected. Please try again.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }

        setState(() {
          _errorMessage = 'Failed to select media. Please try again.';
        });
      }
    } catch (e) {
      if (kDebugMode) {
        Logger.debug('💥 MediaUploadWidget: Error selecting media: $e');
        Logger.debug('📊 MediaUploadWidget: Stack trace: ${StackTrace.current}');
      }

      // Show immediate error feedback
      if (mounted) {
        String errorMessage = 'Failed to upload selected file';
        String technicalDetails = '';

        if (e.toString().contains('permission')) {
          errorMessage =
              'Permission denied. Please check your device settings.';
          technicalDetails = 'Permission error: $e';
        } else if (e.toString().contains('Failed to store')) {
          errorMessage = 'Failed to save media file. Please try again.';
          technicalDetails = 'Storage error: $e';
        } else if (e.toString().contains('does not exist')) {
          errorMessage =
              'Selected file could not be found. Please try a different file.';
          technicalDetails = 'File not found: $e';
        } else {
          technicalDetails = 'Technical error: $e';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  errorMessage,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (kDebugMode && technicalDetails.isNotEmpty)
                  Text(
                    technicalDetails,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }

      setState(() {
        _errorMessage = 'Error selecting media: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _finalizeUpload() {
    if (kDebugMode) {
            Logger.debug(
        '🚀 MediaUploadWidget: Finalizing upload with ${_selectedMedia.length} items',
      );
    }

    if (_selectedMedia.isNotEmpty) {
      // Check if multiple media callback is provided
      if (widget.onMultipleMediaSelected != null) {
        // Upload all selected media
        if (kDebugMode) {
          Logger.debug(
            '📤 MediaUploadWidget: Uploading ${_selectedMedia.length} media items',
          );
        }

        widget.onMultipleMediaSelected!(_selectedMedia);

        // Close the bottom sheet
        Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${_selectedMedia.length} media item(s) uploaded successfully!',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Fallback to single media upload (backward compatibility)
        final primaryMedia = _selectedMedia.first;

        if (kDebugMode) {
          Logger.debug(
            '📤 MediaUploadWidget: Uploading primary media - ${primaryMedia.fileType} (${primaryMedia.fileName})',
          );
        }

        widget.onMediaSelected(primaryMedia);

        // Close the bottom sheet
        Navigator.pop(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${primaryMedia.fileType == MediaFileType.image
                    ? 'Image'
                    : primaryMedia.fileType == MediaFileType.video
                    ? 'Video'
                    : 'PDF'} uploaded successfully!',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      if (kDebugMode) {
        Logger.debug('⚠️ MediaUploadWidget: No media selected for upload');
      }
    }
  }

  void _cancelUpload() {
    if (kDebugMode) {
            Logger.debug(
        '❌ MediaUploadWidget: Cancelling upload, clearing ${_selectedMedia.length} items',
      );
    }

    _selectedMedia.clear();
    Navigator.pop(context);
  }

  void _removeSelectedMedia(int index, StateSetter setModalState) {
    if (kDebugMode) {
            Logger.debug('🗑️ MediaUploadWidget: Removing media at index $index');
    }

    setState(() {
      _selectedMedia.removeAt(index);
    });

    // Also update the modal state to rebuild the bottom sheet
    setModalState(() {});
  }

  void _removeMedia() {
    if (widget.currentImagePath != null && widget.onMediaRemoved != null) {
      widget.onMediaRemoved!(widget.currentImagePath!);
    }
  }
}

/// Bottom sheet for media upload options
class MediaUploadBottomSheet extends StatefulWidget {
  final VoidCallback? onCameraPressed;
  final VoidCallback? onGalleryPressed;
  final VoidCallback? onFilesPressed;
  final bool allowImages;
  final bool allowPdfs;
  final int maxImages;
  final int maxPdfs;
  final String? currentImagePath;
  final List<MediaUploadResult> selectedMedia;
  final VoidCallback onUploadPressed;
  final VoidCallback onCancelPressed;
  final Function(int) onRemoveMedia;

  const MediaUploadBottomSheet({
    super.key,
    this.onCameraPressed,
    this.onGalleryPressed,
    this.onFilesPressed,
    required this.allowImages,
    required this.allowPdfs,
    required this.maxImages,
    required this.maxPdfs,
    this.currentImagePath,
    required this.selectedMedia,
    required this.onUploadPressed,
    required this.onCancelPressed,
    required this.onRemoveMedia,
  });

  @override
  State<MediaUploadBottomSheet> createState() => _MediaUploadBottomSheetState();
}

class _MediaUploadBottomSheetState extends State<MediaUploadBottomSheet> {
  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
            Logger.debug(
        '📱 MediaUploadBottomSheet: Building with ${widget.selectedMedia.length} selected items',
      );
            Logger.debug(
        '📋 MediaUploadBottomSheet: Selected media files: ${widget.selectedMedia.map((m) => m.fileName).join(', ')}',
      );
            Logger.debug(
        '🔍 MediaUploadBottomSheet: Will show preview: ${widget.selectedMedia.isNotEmpty}',
      );
            Logger.debug(
        '🔍 MediaUploadBottomSheet: Will show upload button: ${widget.selectedMedia.isNotEmpty}',
      );
    }

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.cloud_upload_outlined, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Media Upload',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Limits info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getLimitsText(),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getPlatformHint(),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Selected media previews
            if (widget.selectedMedia.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Media (${widget.selectedMedia.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.selectedMedia.length,
                        itemBuilder: (context, index) {
                          final media = widget.selectedMedia[index];
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child:
                                      media.fileType == MediaFileType.image
                                          ? _buildImageWidget(
                                            media.path,
                                            width: 120,
                                            height: 120,
                                          )
                                          : media.fileType ==
                                              MediaFileType.video
                                          ? Container(
                                            color: Colors.grey.shade100,
                                            child: const Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.videocam,
                                                    color: Colors.blue,
                                                    size: 32,
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'VIDEO',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          : Container(
                                            color: Colors.grey.shade100,
                                            child: const Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.picture_as_pdf,
                                                    color: Colors.red,
                                                    size: 32,
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    'PDF',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                ),
                                // Remove button
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => widget.onRemoveMedia(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Current preview (if no new selections)
            if (widget.currentImagePath != null &&
                widget.selectedMedia.isEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildImageWidget(widget.currentImagePath!),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Upload options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  if (widget.onCameraPressed != null) ...[
                    _buildUploadOption(
                      context: context,
                      icon: Ionicons.camera_outline,
                      title: 'Camera',
                      subtitle: 'Take a photo',
                      onPressed: widget.onCameraPressed!,
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (widget.onGalleryPressed != null) ...[
                    _buildUploadOption(
                      context: context,
                      icon: Ionicons.images_outline,
                      title: 'Gallery',
                      subtitle: 'Choose from photos',
                      onPressed: widget.onGalleryPressed!,
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (widget.onFilesPressed != null) ...[
                    _buildUploadOption(
                      context: context,
                      icon: Ionicons.folder_outline,
                      title: 'Files',
                      subtitle: 'Browse files',
                      onPressed: widget.onFilesPressed!,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Upload button (only show if media is selected)
            if (widget.selectedMedia.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (kDebugMode) {
                        Logger.debug(
                          '🔘 MediaUploadBottomSheet: Showing Upload button for ${widget.selectedMedia.length} items',
                        );
                      }
                      widget.onUploadPressed();
                    },
                    icon: const Icon(Icons.cloud_upload),
                    label: Text(
                      'Upload ${widget.selectedMedia.length} ${widget.selectedMedia.length == 1 ? 'Item' : 'Items'}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              Builder(
                builder: (context) {
                  if (kDebugMode) {
                    Logger.debug(
                      '❌ MediaUploadBottomSheet: No Upload button - no media selected',
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],

            // Cancel button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onCancelPressed,
                  child: const Text('Cancel'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  String _getLimitsText() {
    final List<String> limits = [];

    if (widget.allowImages) {
      limits.add('Images: up to ${widget.maxImages}');
    }

    if (widget.allowPdfs) {
      limits.add('PDFs: up to ${widget.maxPdfs}');
    }

    return limits.join(' • ');
  }

  String _getPlatformHint() {
    if (kIsWeb) {
      return 'On web: Camera uses your webcam, Gallery opens file picker, Files opens file browser';
    }
    return 'Tap any option to upload media';
  }

  Widget _buildImageWidget(String imagePath, {double? width, double? height}) {
    final targetWidth = width ?? 120;
    final targetHeight = height ?? 120;

    if (kDebugMode) {
            Logger.debug(
        '🖼️ MediaUploadBottomSheet: Building image widget for path: $imagePath',
      );
    }

    // Handle Firebase URLs
    if (imagePath.startsWith('https://firebasestorage.googleapis.com')) {
      if (kDebugMode) {
        Logger.debug(
          '🌐 MediaUploadBottomSheet: Using Image.network for Firebase URL',
        );
      }
      return Image.network(
        imagePath,
        width: targetWidth,
        height: targetHeight,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: targetWidth,
            height: targetHeight,
            color: Colors.grey.shade100,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.red),
            ),
          );
        },
      );
    }

    // Handle local file paths and blob URLs
    try {
      if (kIsWeb) {
        // On web, use Image.network for blob URLs
        return Image.network(
          imagePath,
          width: targetWidth,
          height: targetHeight,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              Logger.debug('💥 MediaUploadBottomSheet: Image.network error: $error');
            }
            return Container(
              width: targetWidth,
              height: targetHeight,
              color: Colors.grey.shade100,
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.red),
              ),
            );
          },
        );
      } else {
        // On mobile, use Image.file
        return Image.file(
          File(imagePath),
          width: targetWidth,
          height: targetHeight,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            if (kDebugMode) {
              Logger.debug('💥 MediaUploadBottomSheet: Image.file error: $error');
            }
            return Container(
              width: targetWidth,
              height: targetHeight,
              color: Colors.grey.shade100,
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.red),
              ),
            );
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        Logger.debug(
          '❌ MediaUploadBottomSheet: Failed to load image from path: $imagePath',
        );
        Logger.debug('📊 MediaUploadBottomSheet: Error: $e');
      }

      return Container(
        width: targetWidth,
        height: targetHeight,
        color: Colors.grey.shade100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, color: Colors.red),
            const SizedBox(height: 4),
            Text(
              'Failed to load',
              style: TextStyle(color: Colors.red.shade600, fontSize: 10),
            ),
          ],
        ),
      );
    }
  }
}

/// Media upload result
class MediaUploadResult {
  final String path;
  final String fileName;
  final MediaFileType fileType;
  final int fileSize;

  MediaUploadResult({
    required this.path,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
  });
}

/// Media file types
enum MediaFileType { image, pdf, video }

/// Simple media upload widget for quick use
class SimpleMediaUpload extends StatelessWidget {
  final String? imagePath;
  final Function(String) onMediaSelected;
  final Function(List<String>)?
  onMultipleMediaSelected; // NEW: Support multiple uploads
  final Function()? onMediaRemoved;
  final double? width;
  final double? height;
  final String? label;
  final int maxImages;
  final int maxPdfs;
  final bool allowImages;
  final bool allowPdfs;

  const SimpleMediaUpload({
    super.key,
    this.imagePath,
    required this.onMediaSelected,
    this.onMultipleMediaSelected, // NEW: Optional multiple media callback
    this.onMediaRemoved,
    this.width,
    this.height,
    this.label,
    this.maxImages = 25,
    this.maxPdfs = 5,
    this.allowImages = true,
    this.allowPdfs = true,
  });

  @override
  Widget build(BuildContext context) {
    return MediaUploadWidget(
      currentImagePath: imagePath,
      onMediaSelected: (result) => onMediaSelected(result.path),
      onMultipleMediaSelected:
          onMultipleMediaSelected != null
              ? (results) =>
                  onMultipleMediaSelected!(results.map((r) => r.path).toList())
              : null,
      onMediaRemoved: onMediaRemoved != null ? (_) => onMediaRemoved!() : null,
      width: width,
      height: height,
      label: label,
      showPreview: true,
      maxImages: maxImages,
      maxPdfs: maxPdfs,
      allowImages: allowImages,
      allowPdfs: allowPdfs,
    );
  }
}
