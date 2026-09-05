import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../data/remote/appwrite_report_service.dart';
import '../services/report_service.dart';
import '../widgets/issue_category_card.dart';
import '../widgets/location_card.dart';

class CreateReportScreen extends ConsumerStatefulWidget {
  const CreateReportScreen({super.key});

  @override
  ConsumerState<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends ConsumerState<CreateReportScreen> {
  final _picker = ImagePicker();
  final _descriptionController = TextEditingController();
  final _locationService = LocationService();

  XFile? _selectedImage;
  String _selectedCategory = 'Large pothole';

  bool _isLoadingLocation = false;
  String _address = 'মিরপুর, ঢাকা, বাংলাদেশ';
  double _latitude = 23.8103;
  double _longitude = 90.4125;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    final result = await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _address = result.address;
        _latitude = result.latitude;
        _longitude = result.longitude;
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _selectedImage = pickedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ছবি নির্বাচনে সমস্যা হয়েছে')),
            );
          }
        });
      }
    }
  }

  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ছবি নির্বাচন করুন',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('ক্যামেরা'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text('গ্যালারি'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitReport() async {
    if (_selectedImage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'অনুগ্রহ করে সমস্যার একটি ছবি তুলুন বা নির্বাচন করুন')),
          );
        }
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final String finalDesc = _descriptionController.text.trim().isEmpty
        ? 'নাগরিক কর্তৃক ম্যানুয়ালি রিপোর্টকৃত $_selectedCategory সমস্যা।'
        : _descriptionController.text.trim();

    // Submit to Appwrite
    final appwriteService = AppwriteReportService();
    final result = await appwriteService.submitReportToAppwriteResult(
      imageFile: _selectedImage!,
      category: _selectedCategory,
      confidence: 1.0,
      latitude: _latitude,
      longitude: _longitude,
      address: _address,
      description: finalDesc,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (result.isSuccess && result.report != null) {
        ref.read(reportListProvider.notifier).addReport(result.report!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('রিপোর্ট সফলভাবে জমা হয়েছে'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pushReplacementNamed(
          context,
          '/report-success',
          arguments: result.report!,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '⚠️ আপলোড ব্যর্থ হয়েছে: ${result.errorMessage ?? "অজানা ত্রুটি। পুনরায় চেষ্টা করুন।"}'),
            backgroundColor: Colors.deepOrange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('সমস্যার রিপোর্ট করুন'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Picker Section
            _selectedImage == null
                ? Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 1.5),
                    ),
                    child: InkWell(
                      onTap: _showImageSourceModal,
                      borderRadius: BorderRadius.circular(10),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded,
                              size: 48, color: AppColors.primary),
                          SizedBox(height: 12),
                          Text(
                            'সমস্যার ছবি তুলুন বা গ্যালারি থেকে নির্বাচন করুন',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'ক্যামেরা বা গ্যালারি ট্যাপ করুন',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 220,
                          width: double.infinity,
                          color: Colors.black12,
                          child: kIsWeb ||
                                  _selectedImage!.path.startsWith('blob:') ||
                                  _selectedImage!.path.startsWith('http')
                              ? Image.network(
                                  _selectedImage!.path,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_selectedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.edit_rounded,
                                color: Colors.white, size: 20),
                            onPressed: _showImageSourceModal,
                            tooltip: 'ছবি পরিবর্তন করুন',
                          ),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 20),

            // Issue Category Selector Card
            IssueCategoryCard(
              category: _selectedCategory,
              onCategoryChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategory = val;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Location Card
            LocationCard(
              address: _address,
              latitude: _latitude,
              longitude: _longitude,
              isLoading: _isLoadingLocation,
              onRefresh: _fetchLocation,
            ),
            const SizedBox(height: 16),

            // Description Input
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.description_outlined,
                            color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'সমস্যার বিবরণ (Description)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText:
                            'সমস্যাটি সম্পর্কে বিস্তারিত লিখুন (যেমন: কতদিন ধরে গর্ত তৈরি হয়েছে বা গাড়ি চলাচলে কী বাধা সৃষ্টি হচ্ছে)...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReport,
              child: _isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text('রিপোর্ট জমা দেওয়া হচ্ছে...'),
                      ],
                    )
                  : const Text('রিপোর্ট জমা দিন (Submit Report)'),
            ),
          ],
        ),
      ),
    );
  }
}
