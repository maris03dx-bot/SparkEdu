import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class AnonymousVideoCallScreen extends StatefulWidget {
  final String subject;
  final bool isTeacher;

  const AnonymousVideoCallScreen({
    super.key,
    required this.subject,
    this.isTeacher = false,
  });

  @override
  State<AnonymousVideoCallScreen> createState() =>
      _AnonymousVideoCallScreenState();
}

class _AnonymousVideoCallScreenState
    extends State<AnonymousVideoCallScreen> {
  // ==========================================================
  // LIVEKIT
  // ==========================================================

  static const String tokenServerId = "sparkedu-r22ltv";

  Room? room;

  bool isConnecting = true;
  bool isMuted = true;
  bool isCameraOff = true;

  String? errorMessage;

  // ==========================================================
  // AUDIO OPTIONS
  // ==========================================================

  static const AudioCaptureOptions audioOptions =
      AudioCaptureOptions(
    echoCancellation: true,
    noiseSuppression: true,
    autoGainControl: true,
    highPassFilter: true,
    typingNoiseDetection: true,
  );

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();
    connectToRoom();
  }

  // ==========================================================
  // SUBJECT-SPECIFIC ROOM NAME
  // ==========================================================

  String get roomName {
    final cleanSubject = widget.subject
        .toLowerCase()
        .replaceAll(
          RegExp(r'[^a-z0-9]+'),
          '_',
        )
        .replaceAll(
          RegExp(r'_+'),
          '_',
        )
        .replaceAll(
          RegExp(r'^_|_$'),
          '',
        );

    return 'sparkedu_anonymous_$cleanSubject';
  }

  // ==========================================================
  // CONNECT TO LIVEKIT
  // ==========================================================

  Future<void> connectToRoom() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        isConnecting = false;
        errorMessage = 'Please login first.';
      });

      return;
    }

    try {
      // ========================================================
      // DEVELOPMENT TOKEN SERVER
      // ========================================================

      final tokenSource = DevelopmentTokenSource(
        id: tokenServerId,
      );

      final response = await tokenSource.fetch(
        TokenRequestOptions(
          roomName: roomName,
          participantIdentity:
              '${widget.isTeacher ? "teacher" : "student"}_${user.uid}',
          participantName:
              widget.isTeacher ? 'Teacher' : 'Student',
          participantAttributes: {
            'role': widget.isTeacher ? 'teacher' : 'student',
            'subject': widget.subject,
          },
        ),
      );

      // ========================================================
      // CREATE ROOM
      // ========================================================

      final newRoom = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioCaptureOptions: audioOptions,
        ),
      );

      room = newRoom;

      newRoom.addListener(_roomChanged);

      // ========================================================
      // CONNECT
      // ========================================================

      await newRoom.connect(
        response.serverUrl,
        response.participantToken,
      );

      // ========================================================
      // START WITH CAMERA OFF
      // ========================================================

      final localParticipant = newRoom.localParticipant;

      if (localParticipant != null) {
        try {
          await localParticipant.setCameraEnabled(false);
        } catch (e) {
          debugPrint(
            'Initial camera disable failed: $e',
          );
        }

        try {
          await localParticipant.setMicrophoneEnabled(
            false,
            audioCaptureOptions: audioOptions,
          );
        } catch (e) {
          debugPrint(
            'Initial microphone disable failed: $e',
          );
        }
      }

      if (!mounted) return;

      setState(() {
        isConnecting = false;
        isMuted = true;
        isCameraOff = true;
      });
    } catch (e) {
      debugPrint(
        'LiveKit connection error: $e',
      );

      if (!mounted) return;

      setState(() {
        isConnecting = false;
        errorMessage = 'Unable to join video call.\n\n$e';
      });
    }
  }

  // ==========================================================
  // ROOM CHANGED
  // ==========================================================

  void _roomChanged() {
    if (!mounted) return;

    setState(() {});
  }

  // ==========================================================
  // MICROPHONE TOGGLE
  // ==========================================================

  Future<void> toggleMicrophone() async {
    final currentRoom = room;

    if (currentRoom == null) {
      return;
    }

    final localParticipant =
        currentRoom.localParticipant;

    if (localParticipant == null) {
      return;
    }

    try {
      final bool shouldEnable = isMuted;

      await localParticipant.setMicrophoneEnabled(
        shouldEnable,
        audioCaptureOptions: audioOptions,
      );

      if (!mounted) return;

      setState(() {
        isMuted = !shouldEnable;
      });
    } catch (e) {
      debugPrint(
        'Microphone toggle failed: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Microphone could not be changed.\n$e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // CAMERA TOGGLE
  // ==========================================================

  Future<void> toggleCamera() async {
    final currentRoom = room;

    if (currentRoom == null) {
      return;
    }

    final localParticipant =
        currentRoom.localParticipant;

    if (localParticipant == null) {
      return;
    }

    try {
      final bool shouldEnable = isCameraOff;

      await localParticipant.setCameraEnabled(
        shouldEnable,
        cameraCaptureOptions:
            const CameraCaptureOptions(
          cameraPosition: CameraPosition.front,
          stopCameraCaptureOnMute: true,
        ),
      );

      if (!mounted) return;

      setState(() {
        isCameraOff = !shouldEnable;
      });
    } catch (e) {
      debugPrint(
        'Camera toggle failed: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Camera could not be changed.\n$e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // LEAVE CALL
  // ==========================================================

  Future<void> leaveCall() async {
    final currentRoom = room;

    if (currentRoom != null) {
      try {
        currentRoom.removeListener(
          _roomChanged,
        );

        await currentRoom.disconnect();
      } catch (e) {
        debugPrint(
          'Disconnect error: $e',
        );
      }
    }

    room = null;

    if (!mounted) return;

    Navigator.pop(context);
  }

  // ==========================================================
  // GET ACTIVE VIDEO TRACK
  //
  // When camera is OFF, no video widget is rendered.
  // This prevents the previous frame from staying visible.
  // ==========================================================

  VideoTrack? getVideoTrack(
    Participant participant,
  ) {
    for (final publication
        in participant.videoTrackPublications) {
      if (publication.muted) {
        continue;
      }

      if (!publication.subscribed) {
        continue;
      }

      final track = publication.track;

      if (track is VideoTrack) {
        return track;
      }
    }

    return null;
  }

  // ==========================================================
  // PARTICIPANT LABEL
  // ==========================================================

  String getParticipantLabel(
    Participant participant,
    int index,
  ) {
    if (participant is LocalParticipant) {
      return widget.isTeacher ? 'Teacher' : 'You';
    }

    return 'Student $index';
  }

  // ==========================================================
  // PARTICIPANT TILE
  // ==========================================================

  Widget buildParticipantTile(
    Participant participant,
    int index,
  ) {
    final videoTrack = getVideoTrack(
      participant,
    );

    final bool isLocal =
        participant is LocalParticipant;

    final String label =
        getParticipantLabel(
      participant,
      index,
    );

    final bool showVideo =
        videoTrack != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF202124),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ====================================================
          // VIDEO OR CAMERA-OFF PLACEHOLDER
          // ====================================================

          Positioned.fill(
            child: showVideo
                ? VideoTrackRenderer(
                    videoTrack,
                    fit: VideoViewFit.cover,

                    // IMPORTANT:
                    // Do not mirror the front camera.
                    mirrorMode:
                        VideoViewMirrorMode.off,
                  )
                : Container(
                    color: const Color(0xFF303134),
                    child: Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor:
                                isLocal
                                    ? Colors.blue
                                    : Colors.indigo,
                            child: Icon(
                              widget.isTeacher &&
                                      isLocal
                                  ? Icons.school
                                  : Icons.person,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          const Text(
                            'Camera off',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          // ====================================================
          // PARTICIPANT NAME
          // ====================================================

          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // ====================================================
          // CAMERA OFF ICON
          // ====================================================

          if (!showVideo)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius:
                      BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.videocam_off,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // GET ALL PARTICIPANTS
  // ==========================================================

  List<Participant> getParticipants() {
    final currentRoom = room;

    if (currentRoom == null) {
      return [];
    }

    final List<Participant> participants = [];

    // --------------------------------------------------------
    // LOCAL
    // --------------------------------------------------------

    final localParticipant =
        currentRoom.localParticipant;

    if (localParticipant != null) {
      participants.add(
        localParticipant,
      );
    }

    // --------------------------------------------------------
    // REMOTE
    // --------------------------------------------------------

    participants.addAll(
      currentRoom.remoteParticipants.values,
    );

    return participants;
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final participants =
        getParticipants();

    return Scaffold(
      backgroundColor: const Color(0xFF111111),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          widget.subject,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: isConnecting
          ? const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  SizedBox(
                    height: 18,
                  ),
                  Text(
                    'Joining anonymous video call...',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.video_call_outlined,
                          color: Colors.red,
                          size: 70,
                        ),
                        const SizedBox(
                          height: 18,
                        ),
                        Text(
                          errorMessage!,
                          textAlign:
                              TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(
                              context,
                            );
                          },
                          child: const Text(
                            'Go Back',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // ==========================================
                    // CALL HEADER
                    // ==========================================

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      color: const Color(
                        0xFF1E1E1E,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.visibility_off,
                            color:
                                Colors.white70,
                            size: 19,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: Text(
                              'Anonymous ${widget.subject} call',
                              style:
                                  const TextStyle(
                                color:
                                    Colors.white70,
                                fontSize:
                                    13,
                              ),
                            ),
                          ),
                          Text(
                            '${participants.length}',
                            style:
                                const TextStyle(
                              color:
                                  Colors.white,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            width: 5,
                          ),
                          const Icon(
                            Icons.people,
                            color:
                                Colors.white70,
                            size: 18,
                          ),
                        ],
                      ),
                    ),

                    // ==========================================
                    // VIDEO GRID
                    // ==========================================

                    Expanded(
                      child: participants.isEmpty
                          ? const Center(
                              child: Text(
                                'Waiting for participants...',
                                style: TextStyle(
                                  color:
                                      Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : LayoutBuilder(
                              builder:
                                  (
                                context,
                                constraints,
                              ) {
                                final int
                                    participantCount =
                                    participants.length;

                                final int columns =
                                    participantCount <=
                                            1
                                        ? 1
                                        : participantCount <=
                                                4
                                            ? 2
                                            : 3;

                                return GridView.builder(
                                  padding:
                                      const EdgeInsets.all(
                                    10,
                                  ),
                                  itemCount:
                                      participantCount,
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        columns,
                                    crossAxisSpacing:
                                        10,
                                    mainAxisSpacing:
                                        10,
                                    childAspectRatio:
                                        0.78,
                                  ),
                                  itemBuilder:
                                      (
                                    context,
                                    index,
                                  ) {
                                    return buildParticipantTile(
                                      participants[
                                          index],
                                      index,
                                    );
                                  },
                                );
                              },
                            ),
                    ),

                    // ==========================================
                    // CONTROLS
                    // ==========================================

                    SafeArea(
                      top: false,
                      child: Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        color:
                            const Color(
                          0xFF1E1E1E,
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            // ==================================
                            // MICROPHONE
                            // ==================================

                            CircleAvatar(
                              radius: 27,
                              backgroundColor:
                                  isMuted
                                      ? Colors.red
                                      : Colors.white
                                          .withValues(
                                          alpha:
                                              0.12,
                                        ),
                              child:
                                  IconButton(
                                tooltip:
                                    isMuted
                                        ? 'Turn microphone on'
                                        : 'Turn microphone off',
                                onPressed:
                                    toggleMicrophone,
                                icon:
                                    Icon(
                                  isMuted
                                      ? Icons.mic_off
                                      : Icons.mic,
                                  color:
                                      Colors.white,
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 18,
                            ),

                            // ==================================
                            // CAMERA
                            // ==================================

                            CircleAvatar(
                              radius: 27,
                              backgroundColor:
                                  isCameraOff
                                      ? Colors.red
                                      : Colors.white
                                          .withValues(
                                          alpha:
                                              0.12,
                                        ),
                              child:
                                  IconButton(
                                tooltip:
                                    isCameraOff
                                        ? 'Turn camera on'
                                        : 'Turn camera off',
                                onPressed:
                                    toggleCamera,
                                icon:
                                    Icon(
                                  isCameraOff
                                      ? Icons.videocam_off
                                      : Icons.videocam,
                                  color:
                                      Colors.white,
                                ),
                              ),
                            ),

                            const SizedBox(
                              width: 18,
                            ),

                            // ==================================
                            // END CALL
                            // ==================================

                            CircleAvatar(
                              radius: 30,
                              backgroundColor:
                                  Colors.red,
                              child:
                                  IconButton(
                                tooltip:
                                    'Leave call',
                                onPressed:
                                    leaveCall,
                                icon:
                                    const Icon(
                                  Icons.call_end,
                                  color:
                                      Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    final currentRoom = room;

    if (currentRoom != null) {
      currentRoom.removeListener(
        _roomChanged,
      );

      currentRoom.disconnect();
    }

    super.dispose();
  }
}