import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:camera_app/display.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

final String nodeEndPoint = 'http://192.168.1.102:8080/upload';

void upload(File file) async {
  if (file == null) return;
  String base64Image = base64Encode(file.readAsBytesSync());
  String fileName = file.path.split("/").last;
  // print(nodeEndPoint);
  // http.post(nodeEndPoint, body: {
  //   "file": base64Image,
  //   "name": fileName,
  // }).then((res) {
  //   print(res.statusCode);
  // }).catchError((err) {
  //   print(err);
  // });
  var request = new http.MultipartRequest("POST", Uri.parse(nodeEndPoint));
 // request.fields['file'] = file; //base64Image;
  request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
     // contentType: new MediaType('image', 'png'),
  ));
  request.send().then((response) {
    if (response.statusCode == 200) print("Uploaded!");
  });
}

Future<void> main() async {
  final cameras = await availableCameras();

  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData(primarySwatch: Colors.pink),
      home: Camera(
        camera: firstCamera,
      ),
    ),
  );
}

class Camera extends StatefulWidget {
  final CameraDescription camera;

  const Camera({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  CameraState createState() => CameraState();
}

class CameraState extends State<Camera> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a Picture haha')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        onPressed: () async {
          try {
            await _initializeControllerFuture;

            final path = join(
              (await getTemporaryDirectory()).path,
              '${DateTime.now()}.png',
            );
            print(path);
            await _controller.takePicture(path);
            upload(File(path));

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisplayPicture(imagePath: path),
              ),
            );
          } catch (e) {
            print(e);
          }
        },
      ),
    );
  }
}

