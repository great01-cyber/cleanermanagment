import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../Models/training_video_model.dart';
import '../Models/training_category_model.dart';
import '../Services/training_video_service.dart';
import '../Services/video_migration_service.dart';

class AdminVideoManagementScreen extends StatefulWidget {
  const AdminVideoManagementScreen({super.key});

  @override
  State<AdminVideoManagementScreen> createState() => _AdminVideoManagementScreenState();
}

class _AdminVideoManagementScreenState extends State<AdminVideoManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Data lists
  List<TrainingVideo> _videos = [];
  List<TrainingCategory> _categories = [];

  // Loading states
  bool _isLoadingVideos = true;
  bool _isLoadingCategories = true;
  bool _isUploading = false;

  // Upload form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();

  // Selected files and category
  File? _selectedVideoFile;
  File? _selectedThumbnailFile;
  String? _selectedCategoryId;

  // Web-specific file storage
  Uint8List? _selectedVideoBytes;
  Uint8List? _selectedThumbnailBytes;
  String? _selectedVideoName;
  String? _selectedThumbnailName;

  // Search and filter
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadVideos(),
      _loadCategories(),
    ]);
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoadingVideos = true);
    try {
      final videos = await TrainingVideoService.getAllVideos();
      setState(() {
        _videos = videos;
        _isLoadingVideos = false;
      });
    } catch (e) {
      setState(() => _isLoadingVideos = false);
      _showErrorSnackBar('Failed to load videos: $e');
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoadingCategories = true);
    try {
      final categories = await TrainingVideoService.getAllCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      _showErrorSnackBar('Failed to load categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Video Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.video_library), text: 'All Videos'),
            Tab(icon: Icon(Icons.upload), text: 'Upload Video'),
            Tab(icon: Icon(Icons.category), text: 'Categories'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'migrate',
                child: Row(
                  children: [
                    Icon(Icons.upload_file, size: 20),
                    SizedBox(width: 8),
                    Text('Migrate from JSON'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sample',
                child: Row(
                  children: [
                    Icon(Icons.add_circle, size: 20),
                    SizedBox(width: 8),
                    Text('Add Sample Data'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVideosList(),
          _buildUploadForm(),
          _buildCategoriesList(),
        ],
      ),
    );
  }

  Widget _buildVideosList() {
    if (_isLoadingVideos) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredVideos = _videos.where((video) {
      return video.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          video.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search videos...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              )
                  : null,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ),
        ),

        // Videos list
        Expanded(
          child: filteredVideos.isEmpty
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No videos found', style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredVideos.length,
            itemBuilder: (context, index) {
              final video = filteredVideos[index];
              return _buildVideoCard(video);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard(TrainingVideo video) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Thumbnail placeholder
                Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.play_circle_outline, size: 32),
                ),
                const SizedBox(width: 12),

                // Video info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        video.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.category, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            video.category,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            video.duration,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.visibility, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${video.viewCount} views',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                PopupMenuButton<String>(
                  onSelected: (value) => _handleVideoAction(value, video),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),

            // Upload info
            const SizedBox(height: 8),
            Text(
              'Uploaded by ${video.uploadedByName} on ${_formatDate(video.uploadedAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload New Training Video',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Video file selection
          _buildFileSelector(
            title: 'Select Video File',
            subtitle: 'Choose a video file (MP4, MOV, AVI)',
            file: _selectedVideoFile,
            onTap: _selectVideoFile,
            icon: Icons.video_file,
          ),

          const SizedBox(height: 16),

          // Thumbnail file selection
          _buildFileSelector(
            title: 'Select Thumbnail (Optional)',
            subtitle: 'Choose a thumbnail image (JPG, PNG)',
            file: _selectedThumbnailFile,
            onTap: _selectThumbnailFile,
            icon: Icons.image,
          ),

          const SizedBox(height: 24),

          // Form fields
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Video Title *',
              border: OutlineInputBorder(),
              hintText: 'Enter video title',
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description *',
              border: OutlineInputBorder(),
              hintText: 'Enter video description',
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          // Category selection
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            decoration: const InputDecoration(
              labelText: 'Category *',
              border: OutlineInputBorder(),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category.id,
                child: Text(category.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedCategoryId = value);
            },
          ),

          const SizedBox(height: 16),

          TextField(
            controller: _durationController,
            decoration: const InputDecoration(
              labelText: 'Duration',
              border: OutlineInputBorder(),
              hintText: 'e.g., 5 minutes, 2:30',
            ),
          ),

          const SizedBox(height: 32),

          // Upload button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _uploadVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUploading
                  ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Uploading...'),
                ],
              )
                  : const Text('Upload Video', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSelector({
    required String title,
    required String subtitle,
    required File? file,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    String displayText = subtitle;
    bool hasFile = false;

    if (kIsWeb) {
      if (icon == Icons.video_file && _selectedVideoName != null) {
        displayText = _selectedVideoName!;
        hasFile = true;
      } else if (icon == Icons.image && _selectedThumbnailName != null) {
        displayText = _selectedThumbnailName!;
        hasFile = true;
      }
    } else {
      if (file != null) {
        displayText = file.path.split('/').last;
        hasFile = true;
      }
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.deepPurple),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayText,
                    style: TextStyle(
                      fontSize: 14,
                      color: hasFile ? Colors.deepPurple : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.upload_file, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList() {
    if (_isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.withOpacity(0.1),
              child: const Icon(Icons.category, color: Colors.deepPurple),
            ),
            title: Text(category.name),
            subtitle: Text('${category.videoCount} videos'),
            trailing: PopupMenuButton<String>(
              onSelected: (value) => _handleCategoryAction(value, category),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // File selection methods
  Future<void> _selectVideoFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;

        // Handle web platform differently
        if (kIsWeb) {
          // For web, store the bytes and filename
          if (pickedFile.bytes != null) {
            setState(() {
              _selectedVideoBytes = pickedFile.bytes;
              _selectedVideoName = pickedFile.name;
              _selectedVideoFile = null; // Clear file reference for web
            });
          } else {
            _showErrorSnackBar('Failed to read video file');
          }
        } else {
          // For mobile/desktop platforms
          final file = File(pickedFile.path!);
          if (TrainingVideoService.isValidVideoFile(file)) {
            setState(() => _selectedVideoFile = file);
          } else {
            _showErrorSnackBar('Please select a valid video file (MP4, MOV, AVI)');
          }
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select video file: $e');
    }
  }

  Future<void> _selectThumbnailFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;

        // Handle web platform differently
        if (kIsWeb) {
          // For web, store the bytes and filename
          if (pickedFile.bytes != null) {
            setState(() {
              _selectedThumbnailBytes = pickedFile.bytes;
              _selectedThumbnailName = pickedFile.name;
              _selectedThumbnailFile = null; // Clear file reference for web
            });
          } else {
            _showErrorSnackBar('Failed to read image file');
          }
        } else {
          // For mobile/desktop platforms
          final file = File(pickedFile.path!);
          if (TrainingVideoService.isValidImageFile(file)) {
            setState(() => _selectedThumbnailFile = file);
          } else {
            _showErrorSnackBar('Please select a valid image file (JPG, PNG, GIF)');
          }
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select thumbnail file: $e');
    }
  }

  // Upload video
  Future<void> _uploadVideo() async {
    if (kIsWeb) {
      if (_selectedVideoBytes == null) {
        _showErrorSnackBar('Please select a video file');
        return;
      }
    } else {
      if (_selectedVideoFile == null) {
        _showErrorSnackBar('Please select a video file');
        return;
      }
    }

    // For web, show a message that uploads are not supported yet
    if (kIsWeb) {
      _showErrorSnackBar('Video uploads are not supported on web yet. Please use the mobile app for uploading videos.');
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a video title');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter a video description');
      return;
    }

    if (_selectedCategoryId == null) {
      _showErrorSnackBar('Please select a category');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Get current user info
      final userInfo = await TrainingVideoService.getCurrentUserInfo();

      // Generate unique filename
      final videoFileName = TrainingVideoService.generateFileName(
        kIsWeb ? _selectedVideoName! : _selectedVideoFile!.path.split('/').last,
      );

      // Upload video file
      String videoUrl;
      if (kIsWeb) {
        videoUrl = await TrainingVideoService.uploadVideoFromBytes(
          _selectedVideoBytes!,
          videoFileName,
        );
      } else {
        videoUrl = await TrainingVideoService.uploadVideo(
          _selectedVideoFile!,
          videoFileName,
        );
      }

      // Upload thumbnail if provided
      String thumbnailUrl = '';
      if (kIsWeb) {
        if (_selectedThumbnailBytes != null) {
          final thumbnailFileName = TrainingVideoService.generateFileName(_selectedThumbnailName!);
          thumbnailUrl = await TrainingVideoService.uploadThumbnailFromBytes(
            _selectedThumbnailBytes!,
            thumbnailFileName,
          );
        }
      } else {
        if (_selectedThumbnailFile != null) {
          final thumbnailFileName = TrainingVideoService.generateFileName(
            _selectedThumbnailFile!.path.split('/').last,
          );
          thumbnailUrl = await TrainingVideoService.uploadThumbnail(
            _selectedThumbnailFile!,
            thumbnailFileName,
          );
        }
      }

      // Create video model
      final video = TrainingVideo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategoryId!,
        videoUrl: videoUrl,
        thumbnailUrl: thumbnailUrl,
        duration: _durationController.text.trim().isEmpty
            ? 'Unknown'
            : _durationController.text.trim(),
        uploadedBy: userInfo['id']!,
        uploadedByName: userInfo['name']!,
        uploadedAt: DateTime.now(), categoryId: '',
      );

      // Save to Firestore
      await TrainingVideoService.saveVideoMetadata(video);

      // Update category video count
      await TrainingVideoService.updateCategoryVideoCount(_selectedCategoryId!);

      // Reset form
      _resetForm();

      // Reload data
      await _loadData();

      _showSuccessSnackBar('Video uploaded successfully!');

    } catch (e) {
      _showErrorSnackBar('Failed to upload video: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _durationController.clear();
    _selectedVideoFile = null;
    _selectedThumbnailFile = null;
    _selectedCategoryId = null;

    // Clear web-specific data
    _selectedVideoBytes = null;
    _selectedThumbnailBytes = null;
    _selectedVideoName = null;
    _selectedThumbnailName = null;
  }

  // Action handlers
  void _handleVideoAction(String action, TrainingVideo video) {
    switch (action) {
      case 'edit':
        _editVideo(video);
        break;
      case 'delete':
        _deleteVideo(video);
        break;
    }
  }

  void _handleCategoryAction(String action, TrainingCategory category) {
    switch (action) {
      case 'edit':
        _editCategory(category);
        break;
      case 'delete':
        _deleteCategory(category);
        break;
    }
  }

  void _editVideo(TrainingVideo video) {
    // TODO: Implement edit functionality
    _showInfoSnackBar('Edit functionality coming soon!');
  }

  void _deleteVideo(TrainingVideo video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: Text('Are you sure you want to delete "${video.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await TrainingVideoService.deleteVideo(video.id);
                await _loadVideos();
                _showSuccessSnackBar('Video deleted successfully!');
              } catch (e) {
                _showErrorSnackBar('Failed to delete video: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editCategory(TrainingCategory category) {
    // TODO: Implement edit category functionality
    _showInfoSnackBar('Edit category functionality coming soon!');
  }

  void _deleteCategory(TrainingCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await TrainingVideoService.deleteCategory(category.id);
                await _loadCategories();
                _showSuccessSnackBar('Category deleted successfully!');
              } catch (e) {
                _showErrorSnackBar('Failed to delete category: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Utility methods
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Handle menu actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'migrate':
        _migrateFromJson();
        break;
      case 'sample':
        _addSampleData();
        break;
    }
  }

  // Migrate videos from JSON
  Future<void> _migrateFromJson() async {
    try {
      _showInfoSnackBar('Starting migration from JSON...');
      await VideoMigrationService.checkAndMigrate();
      await _loadData();
      _showSuccessSnackBar('Migration completed successfully!');
    } catch (e) {
      _showErrorSnackBar('Migration failed: $e');
    }
  }

  // Add sample data
  Future<void> _addSampleData() async {
    try {
      _showInfoSnackBar('Adding sample data...');
      await VideoMigrationService.createSampleCategories();
      await VideoMigrationService.createSampleVideos();
      await _loadData();
      _showSuccessSnackBar('Sample data added successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to add sample data: $e');
    }
  }
}
