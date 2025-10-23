import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:video_player/video_player.dart';


class VideoInfo extends StatefulWidget {
  const VideoInfo({super.key});

  @override
  State<VideoInfo> createState() => _VideoInfoState();
}

class _VideoInfoState extends State<VideoInfo> {
  List videoinfo = [];
  bool _playArea = false;
  bool _isPlaying = false;
  bool _disposed = false;
  int _isPlayingIndex = -1;
  VideoPlayerController? _controller;
  _initData() async {
    await DefaultAssetBundle.of(context)
        .loadString("json/videoinfo.json")
        .then((value) {
      setState(() {
        videoinfo = json.decode(value);
      });
      videoinfo = json.decode(value);
    });
  }

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _disposed = true;
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            decoration: _playArea == false
                ? BoxDecoration(
              gradient: LinearGradient(colors: [
                Color(0xff0f17ad).withOpacity(0.8),
                Color(0xFF6985e8).withOpacity(0.9),
              ], begin: Alignment.bottomLeft, end: Alignment.centerRight),
            )
                : BoxDecoration(color: Color(0xFF6985e8)),
            child: Column(
              children: [
                _playArea == false
                    ? Container(
                  padding:
                  const EdgeInsets.only(top: 70, left: 30, right: 30),
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
                            child: Icon(Icons.arrow_back_ios_new,
                                size: 20, color: Color(0xFFfafafe)),
                          ),
                          Expanded(child: Container()),
                          Icon(Icons.info_outline,
                              size: 20, color: Color(0xFFfafafe)),
                        ],
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Text(
                        "Changing Blue Rolls",
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFFf4f5fd),
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        "Change Liquid Hand Wash",
                        style: TextStyle(
                          fontSize: 25,
                          color: Color(0xFFf4f5fd),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
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
                                  end: Alignment.centerRight),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 20,
                                  color: Color(0xFFfafafe),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text('68 Mins',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFFfafafe),
                                    )),
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
                                  end: Alignment.centerRight),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.settings_outlined,
                                  size: 20,
                                  color: Color(0xFFfafafe),
                                ),
                                SizedBox(
                                  width: 15,
                                ),
                                Text('Cleaning Videos',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFFfafafe),
                                    )),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                )
                    : Container(
                  child: Column(
                    children: [
                      Container(
                          height: 100,
                          padding: const EdgeInsets.only(
                              top: 50, left: 30, right: 30),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  Get.back();
                                },
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  size: 20,
                                  color: Color(0xFFfafafe),
                                ),
                              ),
                              Expanded(child: Container()),
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Color(0xFFfafafe),
                              ),
                            ],
                          )),
                      _playView(context),
                      _controlView(context),
                    ],
                  ),
                ),
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
                          SizedBox(
                            height: 30,
                          ),
                          Row(
                            children: [
                              SizedBox(
                                width: 30,
                              ),
                              Text("Important Lessons",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2f2f51),
                                  )),
                              SizedBox(
                                width: 135,
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.loop,
                                    size: 30,
                                    color: Color(0xFF6d8dea),
                                  ),
                                  Text(
                                    "Data",
                                    style: TextStyle(),
                                  )
                                ],
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Expanded(child: _listView()),
                        ],
                      ),
                    )),
              ],
            )));
  }

  Widget _controlView(BuildContext context) {
    final noMute =(_controller?.value?.volume??0)>0;
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
                  decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                    BoxShadow(
                        offset: Offset(0.0, 0.0),
                        blurRadius: 4.0,
                        color: Color.fromARGB(50, 0, 0, 0))
                  ]
                  ),
                  child: Icon(
                    noMute?Icons.volume_up:Icons.volume_off, color: Colors.white,
                  )
              ),
            ),
            onTap: (){
              if(noMute) {
                _controller?.setVolume(0);
              }else{
                _controller?.setVolume(1.0);
              }
              setState(() {

              });
            },
          ),
          TextButton(
            onPressed: () async {
              final index = _isPlayingIndex - 1;
              if (index > 0 && videoinfo.length > 0) {
                _onTapVideo(index);
              } else {
                Get.snackbar("Video List", "",
                    snackPosition: SnackPosition.BOTTOM,
                    icon: Icon(
                      Icons.face,
                      size: 30,
                      color: Colors.white,
                    ),
                    backgroundColor: Color(0xFF6985e8),
                    colorText: Colors.white,
                    messageText: Text(
                      "You have finished Watching all the Video. Congratulations !!",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ));
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
              // Your logic here
            },
            child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                size: 36, color: Colors.white),
          ),
          TextButton(
            onPressed: () async {
              final index = _isPlayingIndex + 1;
              if (index <= videoinfo.length - 1) {
                _onTapVideo(index);
              } else {
                Get.snackbar("Video List", "",
                    snackPosition: SnackPosition.BOTTOM,
                    icon: Icon(
                      Icons.face,
                      size: 30,
                      color: Colors.white,
                    ),
                    backgroundColor: Color(0xFF6985e8),
                    colorText: Colors.white,
                    messageText: Text(
                      "No more Video in the List",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ));
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
              )));
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

  _onTapVideo(int index) {
    final controller =
    VideoPlayerController.network(videoinfo[index]["videoUrl"]);
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
  }

  _listView() {
    return ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 8,
        ),
        itemCount: videoinfo.length,
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
            child: _buildCard(index),
          );
        });
  }

  _buildCard(int index) {
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
                    image: DecorationImage(
                        image: AssetImage(videoinfo[index]["thumbnail"]),
                        fit: BoxFit.cover)),
              ),
              SizedBox(
                width: 10,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    videoinfo[index]["title"],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Text(
                        videoinfo[index]["time"],
                        style: TextStyle(color: Colors.grey[500]),
                      )),
                ],
              )
            ],
          ),
          SizedBox(
            height: 10,
          ),
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
                    "15s rest",
                    style: TextStyle(color: Color(0xFF839fed)),
                  ),
                ),
              ),
              Row(
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
                    )
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}
