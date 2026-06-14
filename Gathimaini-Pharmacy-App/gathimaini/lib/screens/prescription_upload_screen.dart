import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../Widgets/custom_button.dart';
import '../models/prescription.dart';
import '../services/auth_service.dart';
import '../services/pharmacy_service.dart';

class PrescriptionUploadScreen extends StatefulWidget {
  const PrescriptionUploadScreen({super.key});

  @override
  State<PrescriptionUploadScreen> createState() =>
      _PrescriptionUploadScreenState();
}

class _PrescriptionUploadScreenState extends State<PrescriptionUploadScreen> {
  String? _selectedFilePath;
  bool _isDocument = false;
  String? _fileName;
  final ImagePicker _picker = ImagePicker();
  final _notesController = TextEditingController();
  bool _isUploading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitPrescription() async {
    if (_selectedFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo or PDF first.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final user = AuthService.instance.currentUser;
      final name = user?.name ?? 'Guest';
      final id =
          'RX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      final rx = Prescription(
        id: id,
        customerName: name,
        date: 'Just now',
        fileUrl: _selectedFilePath,
        notes: _notesController.text.trim(),
        isDocument: _isDocument,
      );

      await PharmacyService.instance.addPrescription(rx);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription submitted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          source == ImageSource.camera ? 'Open camera?' : 'Open gallery?',
        ),
        content: Text(
          source == ImageSource.camera
              ? 'Take a clear photo of your prescription.'
              : 'Choose a clear photo of your prescription from your gallery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (ok == true) {
      try {
        final image = await _picker.pickImage(source: source, imageQuality: 85);
        if (!mounted) return;
        if (image != null) {
          setState(() {
            _selectedFilePath = image.path;
            _fileName = image.name;
            _isDocument = false;
          });
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<void> _pickDocument() async {
    if (!mounted) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: kIsWeb,
      );
      if (!mounted) return;

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFilePath = result.files.single.path ?? 'web-document.pdf';
          _fileName = result.files.single.name;
          _isDocument = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick document: $e')));
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Document (PDF)'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickDocument();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload prescription')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Upload a clear photo of your prescription. Our pharmacists will review it and prepare your order.',
            style: TextStyle(
              fontSize: 15.5,
              color: Color(0xFF586B62),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _showPickerOptions,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 220,
              decoration: BoxDecoration(
                color: _selectedFilePath != null
                    ? const Color(0xFFEAF7EF)
                    : const Color(0xFFF0F4F2),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _selectedFilePath != null
                      ? const Color(0xFF1B8F4A)
                      : const Color(0xFFDCE5E0),
                  width: 2,
                ),
              ),
              child: _selectedFilePath != null
                  ? (_isDocument
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.picture_as_pdf,
                                color: Color(0xFF1B8F4A),
                                size: 56,
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                ),
                                child: Text(
                                  _fileName ?? 'Document selected',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF1B8F4A),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tap to change',
                                style: TextStyle(
                                  color: Color(0xFF1B8F4A),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                kIsWeb
                                    ? Image.network(
                                        _selectedFilePath!,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(_selectedFilePath!),
                                        fit: BoxFit.cover,
                                      ),
                                Container(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: Colors.white,
                                          size: 56,
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Tap to change',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.upload_file_rounded,
                            color: Color(0xFF8BA396),
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Tap to take a photo, choose\nfrom gallery, or upload a PDF',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF586B62),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Additional notes (optional)',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF123A28),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Any special instructions or allergies?',
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: SizedBox(
          height: 54,
          child: CustomButton(
            label: 'Submit prescription',
            onPressed: _submitPrescription,
            loading: _isUploading,
            borderRadius: 18,
          ),
        ),
      ),
    );
  }
}
