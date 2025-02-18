import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class ZoomPage extends StatefulWidget {
  final int classId;
  final int sectionId;
  final int studentId;
  final String subjectId;
  final String alamat;
  final String status;

  const ZoomPage({
    Key? key,
    required this.classId,
    required this.sectionId,
    required this.studentId,
    required this.subjectId,
    required this.alamat,
    required this.status,
  }) : super(key: key);

  @override
  _ZoomPageState createState() => _ZoomPageState();
}

class _ZoomPageState extends State<ZoomPage> {
  String? roomId;

  Future<void> startMeeting() async {
    final String url =
        'http://api-pinakad.pintarkerja.com/room.php?class_id=${widget.classId}&subject_id=${widget.subjectId}';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'error') {
        print('Error: ${data['message']}');
      } else {
        setState(() {
          roomId = data['room'];
        });
        print('Room ID: $roomId');
        await joinRoom(roomId!);
      }
    } else {
      print('Failed to load room ID');
    }
  }

  Future<void> joinRoom(String roomId) async {
    try {
      var jitsiMeetPlugin = JitsiMeet(); // Create an instance of JitsiMeet
      var options = JitsiMeetConferenceOptions(
        room: roomId,
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": false,
        },
        featureFlags: {
          FeatureFlags.addPeopleEnabled: true,
          FeatureFlags.welcomePageEnabled: true,
          // Add other features as needed
        },
        userInfo: JitsiMeetUserInfo(
          displayName: "Your Name",
          email: "your-email@example.com",
        ),
      );

      await jitsiMeetPlugin.join(options); // Use the instance to call join
    } catch (error) {
      print('Error joining the room: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zoom Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await startMeeting(); // Start meeting and join the room when button is pressed
              },
              child: const Text('Start Meeting'),
            ),
            if (roomId != null) ...[
              const SizedBox(height: 20),
              Text('Room ID: $roomId'),
            ],
          ],
        ),
      ),
    );
  }
}
