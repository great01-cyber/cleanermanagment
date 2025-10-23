import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../Services/videoInfo.dart';
import 'Cleaners Dashboard/CleanersDashboard.dart';



class UserTraining extends StatefulWidget {
  const UserTraining({super.key});

  @override
  State<UserTraining> createState() => _UserTrainingState();
}

class _UserTrainingState extends State<UserTraining> {

  List info=[];
  _initData(){
    DefaultAssetBundle.of(context).loadString("json/info.json").then((value){
      setState(() {
        info= json.decode(value);
      });
    });
  }

  @override
  void initState(){
    super.initState();
    _initData();
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
        ),
        backgroundColor: Color(0xFFfbfcff),
        body: Container(
          padding: const EdgeInsets.only(top: 10, left:30, right:30),
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
                  SizedBox(width: 10,),
                  Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF3b3c5c)),
                  SizedBox(width: 15,),
                  Icon(Icons.arrow_forward_ios, size: 20, color: Color(0xFF3b3c5c)),
                ],
              ),
              SizedBox(height: 15,),
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
                  SizedBox(width: 5,),
                  InkWell(
                    onTap: (){
                      Get.to(()=>VideoInfo());},
                    child: Icon(Icons.arrow_forward, size: 20, color: Color(0xFF3b3c5c),),
                  ),
                ],
              ),
              SizedBox(height: 20,),
              Container(
                width: MediaQuery.of(context).size.width,
                height: 220,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [
                          Color(0xff0f17ad).withOpacity(0.8),
                          Color(0xFF6985e8).withOpacity(0.9),
                        ],
                        begin: Alignment.bottomLeft,
                        end: Alignment.centerRight
                    ),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10), bottomLeft: Radius.circular(10),
                        topRight: Radius.circular(80), bottomRight: Radius.circular(10)
                    ),
                    boxShadow: [
                      BoxShadow(
                          offset: Offset(10, 10),
                          blurRadius: 20,
                          color: Color(0xFF6985e8).withOpacity(0.2)
                      ),
                    ]


                ),
                child: Container(
                  padding: EdgeInsets.only(left:20, top:25, right: 20,),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Training",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFFf4f5fd),
                        ),
                      ),
                      SizedBox(height: 5,),
                      Text(
                        "Changing Blue Rolls",
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xFFf4f5fd),
                        ),
                      ),
                      SizedBox(height: 5,),
                      Text(
                        "Change Liquid Hand Wash",
                        style: TextStyle(
                          fontSize: 25,
                          color: Color(0xFFf4f5fd),
                        ),
                      ),
                      SizedBox(height: 20,),
                      Row(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.timer, size: 20, color: Color(0xFFf4f5fd),),
                              SizedBox(width: 10,),
                              Text(
                                "5 mins",
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
                                    )
                                  ]
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => VideoInfo()), // Replace NewPage with your destination page
                                  );
                                },
                                child: Icon(
                                  Icons.play_circle_fill,
                                  color: Colors.white,
                                  size: 60,
                                ),
                              )

                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(height: 5,),
              Container(
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
                                fit: BoxFit.fill
                            ),
                            boxShadow: [
                              BoxShadow(
                                  blurRadius: 40,
                                  offset: Offset(8, 10),
                                  color: Color(0xFF6985e8).withOpacity(0.3)
                              )
                            ]
                        )

                    ),
                    Container(
                        height: 200,
                        width: 350,
                        margin: EdgeInsets.only(right: 200, bottom: 30),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                              image: AssetImage("assets/images/cleaner.png"),
                              fit: BoxFit.fill
                          ),
                        )
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
                          SizedBox(height: 10,),
                          RichText(text: TextSpan(
                              text: "Keep it Up\n",
                              style: TextStyle(
                                color: Color(0xFFa2a2b1),
                                fontSize: 16,
                              ),
                              children: [
                                TextSpan(
                                    text: "stick to your plan"
                                )
                              ]
                          ))
                        ],
                      ),
                    )
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    "Area of Focus",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF302F51), // Corrected color syntax
                    ),
                  ),
                ],
              ),
              Expanded(child: OverflowBox(
                maxWidth:MediaQuery.of(context).size.width,
                child: MediaQuery.removePadding(
                  removeTop: true,
                  context: context,
                  child: ListView.builder(
                    itemCount: (info.length.toDouble()/2).toInt(),
                    itemBuilder: (_, i){
                      int a = 2*i; //0, 2,
                      int b = 2*i +1; //1, 3
                      return Row(
                        children: [
                          Container(
                            height: 170,
                            width: (MediaQuery.of(context).size.width-90)/2,
                            margin: EdgeInsets.only(left: 30, bottom: 15, top: 15),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                image: DecorationImage(
                                  image: AssetImage(
                                      info[a]['img']),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                      blurRadius: 3,
                                      offset: Offset(5,5),
                                      color: Color(0xFF6985e8).withOpacity(0.1)
                                  ),
                                ]
                            ),
                            child: Center(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Text(
                                  info[a]["title"],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6588f4), // Corrected color syntax
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            height: 170,
                            width: (MediaQuery.of(context).size.width-90)/2,
                            margin: EdgeInsets.only(left: 30, bottom: 15, top: 15),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                image: DecorationImage(
                                  image: AssetImage(
                                      info[b]['img']),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                      blurRadius: 3,
                                      offset: Offset(5,5),
                                      color: Color(0xFF6985e8).withOpacity(0.1)
                                  ),
                                ]
                            ),
                            child: Center(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Text(
                                  info[b]["title"],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6588f4), // Corrected color syntax
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              )

              ),
            ],
          ),
        ));
  }
}
