import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:video_player/video_player.dart';

import '../Models/training_video_model.dart';
import '../Models/training_category_model.dart';
import '../Services/training_video_service.dart';

class EnhancedVideoInfo extends StatefulWidget {
  final String? categoryId;
  
  const EnhancedVideoInfo({super.key, this.categoryId});

  @override
  State<EnhancedVideoInfo> createState() => _EnhancedVideoInfoState();
}

class _EnhancedVideoInfoState extends State<EnhancedVideoInfo> {
  List<TrainingVideo> _videos = [];
  List<TrainingCategory> _categories = [];
  bool _isLoading = true;
  bool _playArea = false;
  bool _isPlaying = false;
  bool _disposed = false;
  int _isPlayingIndex = -1;
  VideoPlayerController? _controller;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _disposed = true;
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      List<TrainingVideo> videos;
      if (widget.categoryId != null) {
        videos = await TrainingVideoService.getVideosByCategory(widget.categoryId!);
      } else {
        videos = await TrainingVideoService.getAllVideos();
      }
      
      final categories = await TrainingVideoService.getAllCategories();
      
      setState(() {
        _videos = videos;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load videos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: _playArea == false
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xff0f17ad).withOpacity(0.8),
                    Color(0xFF6985e8).withOpacity(0.9),
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.centerRight,
                ),
              )
            : BoxDecoration(color: Color(0xFF6985e8)),
        child: Column(
          children: [
            _playArea == false ? _buildHeader() : _buildVideoHeader(),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(70),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 30),
                    _buildSearchBar(),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        SizedBox(width: 30),
                        Text(
                          widget.categoryId != null ? "Category Videos" : "All Training Videos",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2f2f51),
                          ),
                        ),
                        SizedBox(width: 135),
                        Row(
                          children: [
                            Icon(
                              Icons.loop,
                              size: 30,
                              color: Color(0xFF6d8dea),
                            ),
                            Text("Data"),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Expanded(child: _listView()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 70, left: 30, right: 30),
      width: MediaQuery.of(context).size.width,
      height: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: () {
                  Get.back();
                },
                child: Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFFfafafe)),
              ),
              Expanded(child: Container()),
              Icon(Icons.info_outline, size: 20, color: Color(0xFFfafafe)),
            ],
          ),
          SizedBox(height: 30),
          Text(
            "Training Videos",
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFFf4f5fd),
            ),
          ),
          SizedBox(height: 5),
          Text(
            "Professional Cleaning Training",
            style: TextStyle(
              fontSize: 25,
              color: Color(0xFFf4f5fd),
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Container(
                height: 30,
                width: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff0f17ad).withOpacity(0.8),
                      Color(0xFF6985e8).withOpacity(0.9),
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timer_outlined, size: 20, color: Color(0xFFfafafe)),
                    SizedBox(width: 5),
                    Text(
                      '${_videos.length} Videos',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFfafafe),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: Container()),
              Container(
                height: 30,
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff0f17ad).withOpacity(0.8),
                      Color(0xFF6985e8).withOpacity(0.9),
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.settings_outlined, size: 20, color: Color(0xFFfafafe)),
                    SizedBox(width: 15),
                    Text(
                      'Training Videos',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFfafafe),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoHeader() {
    return Container(
      child: Column(
        children: [
          Container(
            height: 100,
            padding: const EdgeInsets.only(top: 50, left: 30, right: 30),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFFfafafe)),
                ),
                Expanded(child: Container()),
                Icon(Icons.info_outline, size: 20, color: Color(0xFFfafafe)),
              ],
            ),
          ),
          _playView(context),
          _controlView(context),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search videos...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
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
    );
  }

  Widget _controlView(BuildContext context) {
    final noMute = (_controller?.value?.volume ?? 0) > 0;
    return Container(
      height: 120,
      width: MediaQuery.of(context).size.width,
      color: Color(0xFF6985e8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      offset: Offset(0.0, 0.0),
                      blurRadius: 4.0,
                      color: Color.fromARGB(50, 0, 0, 0),
                    ),
                  ],
                ),
                child: Icon(
                  noMute ? Icons.volume_up : Icons.volume_off,
                  color: Colors.white,
                ),
              ),
            ),
            onTap: () {
              if (noMute) {
                _controller?.setVolume(0);
              } else {
                _controller?.setVolume(1.0);
              }
              setState(() {});
            },
          ),
          TextButton(
            onPressed: () async {
              final index = _isPlayingIndex - 1;
              if (index >= 0 && _videos.length > 0) {
                _onTapVideo(index);
              } else {
                Get.snackbar(
                  "Video List",
                  "",
                  snackPosition: SnackPosition.BOTTOM,
                  icon: Icon(Icons.face, size: 30, color: Colors.white),
                  backgroundColor: Color(0xFF6985e8),
                  colorText: Colors.white,
                  messageText: Text(
                    "You have finished Watching all the Video. Congratulations !!",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                );
              }
            },
            child: Icon(Icons.fast_rewind, size: 36, color: Colors.white),
          ),
          TextButton(
            onPressed: () async {
              if (_isPlaying) {
                setState(() {
                  _isPlaying = false;
                });
                _controller?.pause();
              } else {
                setState(() {
                  _isPlaying = true;
                });
                _controller?.play();
              }
            },
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              size: 36,
              color: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () async {
              final index = _isPlayingIndex + 1;
              if (index <= _videos.length - 1) {
                _onTapVideo(index);
              } else {
                Get.snackbar(
                  "Video List",
                  "",
                  snackPosition: SnackPosition.BOTTOM,
                  icon: Icon(Icons.face, size: 30, color: Colors.white),
                  backgroundColor: Color(0xFF6985e8),
                  colorText: Colors.white,
                  messageText: Text(
                    "No more Video in the List",
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                );
              }
            },
            child: Icon(Icons.fast_forward, size: 36, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _playView(BuildContext context) {
    final controller = _controller;
    if (controller != null && controller.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: VideoPlayer(controller),
      );
    } else {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: Text(
            "Preparing...",
            style: TextStyle(fontSize: 20, color: Colors.white60),
          ),
        ),
      );
    }
  }

  var _onUpdateControllerTime;
  void _onControllerUpdate() async {
    if (_disposed) {
      return;
    }
    _onUpdateControllerTime = 0;
    final now = DateTime.now().microsecondsSinceEpoch;
    if (_onUpdateControllerTime > now) {
      return;
    }
    _onUpdateControllerTime = now + 500;
    final controller = _controller;
    if (controller == null) {
      debugPrint("controller is null");
      return;
    }
    if (!controller.value.isInitialized) {
      debugPrint("controller can not be initialised");
      return;
    }
    final playing = controller.value.isPlaying;
    _isPlaying = playing;
  }

  _onTapVideo(int index) async {
    if (index < 0 || index >= _videos.length) return;
    
    final video = _videos[index];
    final controller = VideoPlayerController.network(video.videoUrl);
    final old = _controller;
    _controller = controller;
    
    if (old != null) {
      old.removeListener(_onControllerUpdate);
      old.pause();
    }
    
    setState(() {
      controller
        ..initialize().then((_) {
          old?.dispose();
          _isPlayingIndex = index;
          controller.addListener(_onControllerUpdate);
          controller.play();
          setState(() {});
        });
    });
    
    // Increment view count
    try {
      await TrainingVideoService.incrementViewCount(video.id);
    } catch (e) {
      print('Failed to increment view count: $e');
    }
  }

  _listView() {
    final filteredVideos = _videos.where((video) {
      return video.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             video.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredVideos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No videos found' : 'No training videos available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 8),
      itemCount: filteredVideos.length,
      itemBuilder: (_, int index) {
        return GestureDetector(
          onTap: () {
            _onTapVideo(index);
            debugPrint(index.toString());
            setState(() {
              if (_playArea == false) {
                _playArea = true;
              }
            });
          },
          child: _buildCard(filteredVideos[index], index),
        );
      },
    );
  }

  _buildCard(TrainingVideo video, int index) {
    return Container(
      height: 135,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[300],
                ),
                child: video.thumbnailUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          video.thumbnailUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.video_library, size: 40, color: Colors.grey);
                          },
                        ),
                      )
                    : Icon(Icons.video_library, size: 40, color: Colors.grey),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5),
                    Text(
                      video.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                        SizedBox(width: 4),
                        Text(
                          video.duration,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.visibility, size: 16, color: Colors.grey[500]),
                        SizedBox(width: 4),
                        Text(
                          '${video.viewCount} views',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 80,
                height: 20,
                decoration: BoxDecoration(
                  color: Color(0xFFeaeefc),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    "Training",
                    style: TextStyle(color: Color(0xFF839fed), fontSize: 12),
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    for (int i = 0; i < 70; i++)
                      i.isEven
                          ? Container(
                              width: 3,
                              height: 1,
                              decoration: BoxDecoration(
                                color: Color(0xFF839fed),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            )
                          : Container(
                              width: 3,
                              height: 1,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
