import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../Services/EnhancedVideoInfo.dart';
import '../Models/training_video_model.dart';
import '../Models/training_category_model.dart';
import '../Services/training_video_service.dart';
import 'Cleaners Dashboard/CleanersDashboard.dart';

class EnhancedUserTraining extends StatefulWidget {
  const EnhancedUserTraining({super.key});

  @override
  State<EnhancedUserTraining> createState() => _EnhancedUserTrainingState();
}

class _EnhancedUserTrainingState extends State<EnhancedUserTraining> {
  List<TrainingVideo> _videos = [];
  List<TrainingCategory> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final videos = await TrainingVideoService.getAllVideos();
      final categories = await TrainingVideoService.getAllCategories();
      
      setState(() {
        _videos = videos;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load training content: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: GestureDetector(
          onTap: () {
            Get.off(CleanersDashboard());
          },
          child: Text("User Training"),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Content',
          ),
        ],
      ),
      backgroundColor: Color(0xFFfbfcff),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Container(
              padding: const EdgeInsets.only(top: 10, left: 30, right: 30),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        "Training",
                        style: TextStyle(
                          fontSize: 30,
                          color: Color(0xFF302f51),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Expanded(child: Container()),
                      Icon(Icons.arrow_back_ios, size: 20, color: Color(0xFF3b3c5c)),
                      SizedBox(width: 10),
                      Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF3b3c5c)),
                      SizedBox(width: 15),
                      Icon(Icons.arrow_forward_ios, size: 20, color: Color(0xFF3b3c5c)),
                    ],
                  ),
                  SizedBox(height: 15),
                  
                  // Search bar
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 10),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search training videos...',
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
                  ),
                  
                  Row(
                    children: [
                      Text(
                        "Your Training Videos",
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFF414160),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Expanded(child: Container()),
                      Text(
                        "Details ",
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFF6588f4),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 5),
                      InkWell(
                        onTap: () {
                          Get.to(() => EnhancedVideoInfo());
                        },
                        child: Icon(Icons.arrow_forward, size: 20, color: Color(0xFF3b3c5c)),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  
                  // Featured video card
                  if (_videos.isNotEmpty) _buildFeaturedVideoCard(_videos.first),
                  
                  SizedBox(height: 5),
                  
                  // Motivational card
                  _buildMotivationalCard(),
                  
                  SizedBox(height: 20),
                  
                  Row(
                    children: [
                      Text(
                        "Training Categories",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF302F51),
                        ),
                      ),
                    ],
                  ),
                  
                  // Categories grid
                  Expanded(
                    child: _buildCategoriesGrid(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFeaturedVideoCard(TrainingVideo video) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xff0f17ad).withOpacity(0.8),
            Color(0xFF6985e8).withOpacity(0.9),
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomLeft: Radius.circular(10),
          topRight: Radius.circular(80),
          bottomRight: Radius.circular(10),
        ),
        boxShadow: [
          BoxShadow(
            offset: Offset(10, 10),
            blurRadius: 20,
            color: Color(0xFF6985e8).withOpacity(0.2),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.only(left: 20, top: 25, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Featured Training",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFf4f5fd),
              ),
            ),
            SizedBox(height: 5),
            Text(
              video.title,
              style: TextStyle(
                fontSize: 20,
                color: Color(0xFFf4f5fd),
              ),
            ),
            SizedBox(height: 5),
            Text(
              video.description,
              style: TextStyle(
                fontSize: 25,
                color: Color(0xFFf4f5fd),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Row(
                  children: [
                    Icon(Icons.timer, size: 20, color: Color(0xFFf4f5fd)),
                    SizedBox(width: 10),
                    Text(
                      video.duration,
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFFf4f5fd),
                      ),
                    ),
                  ],
                ),
                Expanded(child: Container()),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF5564d8),
                        blurRadius: 10,
                        offset: Offset(4, 8),
                      ),
                    ],
                  ),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EnhancedVideoInfo(),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.play_circle_fill,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationalCard() {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 180,
      child: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            margin: EdgeInsets.only(top: 30),
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: AssetImage("assets/images/card.jpg"),
                fit: BoxFit.fill,
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 40,
                  offset: Offset(8, 10),
                  color: Color(0xFF6985e8).withOpacity(0.3),
                ),
              ],
            ),
          ),
          Container(
            height: 200,
            width: 350,
            margin: EdgeInsets.only(right: 200, bottom: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: AssetImage("assets/images/cleaner.png"),
                fit: BoxFit.fill,
              ),
            ),
          ),
          Container(
            width: double.maxFinite,
            height: 100,
            margin: EdgeInsets.only(left: 150, top: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You doing Great",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6588f4),
                  ),
                ),
                SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    text: "Keep it Up\n",
                    style: TextStyle(
                      color: Color(0xFFa2a2b1),
                      fontSize: 16,
                    ),
                    children: [
                      TextSpan(text: "stick to your plan"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final filteredCategories = _categories.where((category) {
      return category.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No categories found' : 'No training categories available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return OverflowBox(
      maxWidth: MediaQuery.of(context).size.width,
      child: MediaQuery.removePadding(
        removeTop: true,
        context: context,
        child: ListView.builder(
          itemCount: (filteredCategories.length.toDouble() / 2).toInt(),
          itemBuilder: (_, i) {
            int a = 2 * i;
            int b = 2 * i + 1;
            return Row(
              children: [
                _buildCategoryCard(filteredCategories[a]),
                if (b < filteredCategories.length) _buildCategoryCard(filteredCategories[b]),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryCard(TrainingCategory category) {
    final categoryVideos = _videos.where((video) => video.category == category.id).toList();
    
    return Container(
      height: 170,
      width: (MediaQuery.of(context).size.width - 90) / 2,
      margin: EdgeInsets.only(left: 30, bottom: 15, top: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            blurRadius: 3,
            offset: Offset(5, 5),
            color: Color(0xFF6985e8).withOpacity(0.1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Navigate to category videos
          Get.to(() => EnhancedVideoInfo(categoryId: category.id));
        },
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category icon
            Container(
              width: 60,
              height: 60,
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Color(0xFF6985e8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.video_library,
                size: 30,
                color: Color(0xFF6985e8),
              ),
            ),
            
            // Category name
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6588f4),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            SizedBox(height: 5),
            
            // Video count
            Text(
              '${categoryVideos.length} videos',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
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
