import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final RtcEngine engine;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.engine,
  });

  @override
  _VideoCallScreenState createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isJoined = false;
  int? _remoteUid;
  bool _isCameraOn = true;
  bool _isMicOn = true;
  bool _isVideoReady = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndSetupVideo();
  }

  Future<void> _checkPermissionsAndSetupVideo() async {
    var status = await [Permission.camera, Permission.microphone].request();
    if (status[Permission.camera]!.isDenied || status[Permission.microphone]!.isDenied) {
      setState(() {
        _errorMessage = 'يلزم السماح باستخدام الكاميرا والميكروفون';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يلزم السماح باستخدام الكاميرا والميكروفون'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'الإعدادات',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
      return;
    }

    await _setupVideo();
  }

  Future<void> _setupVideo() async {
    try {
      String sanitizedChannelName = widget.channelName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
      if (sanitizedChannelName.isEmpty || sanitizedChannelName.length > 64) {
        throw Exception('اسم القناة غير صالح: $sanitizedChannelName');
      }
      print('محاولة الانضمام إلى القناة: "$sanitizedChannelName"');

      // إعداد جودة الفيديو العالية
      await widget.engine.setVideoEncoderConfiguration(
        const VideoEncoderConfiguration(
          dimensions: VideoDimensions(width: 1280, height: 720),
          frameRate: 30,
          bitrate: 2500,
          orientationMode: OrientationMode.orientationModeAdaptive,
        ),
      );

      // إعداد جودة الصوت العالية
      await widget.engine.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicHighQualityStereo,
        scenario: AudioScenarioType.audioScenarioMeeting,
      );

      // تفعيل الفيديو
      await widget.engine.enableVideo();

      // إعداد معالج الأحداث
      widget.engine.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('تم الانضمام إلى القناة: ${connection.channelId}');
            setState(() => _isJoined = true);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            print('المستخدم البعيد $remoteUid انضم');
            setState(() => _remoteUid = remoteUid);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            print('المستخدم البعيد $remoteUid غير متصل');
            setState(() => _remoteUid = null);
          },
          onError: (ErrorCodeType err, String msg) {
            setState(() {
              _errorMessage = 'خطأ Agora: $msg (الكود: $err)';
            });
            print('خطأ Agora: الكود: $err, الرسالة: $msg');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('خطأ Agora: $msg (الكود: $err)'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      );

      // الانضمام إلى القناة
      await widget.engine.joinChannel(
        token: '',
        channelId: sanitizedChannelName,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
        ),
      );

      // بدء المعاينة المحلية
      await widget.engine.startPreview();
      setState(() => _isVideoReady = true);
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في إعداد الفيديو: $e';
      });
      print('خطأ في إعداد الفيديو: $e');
      if (e is AgoraRtcException) {
        print('AgoraRtcException: الكود: ${e.code}, الرسالة: ${e.message}');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في إعداد الفيديو: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleCamera() async {
    try {
      print('تغيير حالة الكاميرا: ${_isCameraOn ? "إيقاف" : "تشغيل"}');
      await widget.engine.enableLocalVideo(!_isCameraOn);
      setState(() {
        _isCameraOn = !_isCameraOn;
        print('حالة الكاميرا الجديدة: $_isCameraOn');
      });
    } catch (e) {
      print('خطأ في تشغيل/إيقاف الكاميرا: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تشغيل/إيقاف الكاميرا: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleMicrophone() async {
    try {
      print('تغيير حالة الميكروفون: ${_isMicOn ? "إيقاف" : "تشغيل"}');
      await widget.engine.muteLocalAudioStream(!_isMicOn);
      setState(() {
        _isMicOn = !_isMicOn;
        print('حالة الميكروفون الجديدة: $_isMicOn');
      });
    } catch (e) {
      print('خطأ في تشغيل/إيقاف الميكروفون: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تشغيل/إيقاف الميكروفون: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    print('مغادرة القناة والتخلص من الموارد');
    widget.engine.leaveChannel();
    widget.engine.stopPreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // عرض الفيديو
          _buildVideoView(),
          // رسالة الخطأ إذا وجدت
          if (_errorMessage != null)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.red.withOpacity(0.8),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          // أزرار التحكم
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // زر الكاميرا
                FloatingActionButton(
                  heroTag: 'camera',
                  backgroundColor: _isCameraOn ? Colors.blue : Colors.grey,
                  onPressed: _toggleCamera,
                  child: Icon(_isCameraOn ? Icons.videocam : Icons.videocam_off),
                ),
                const SizedBox(width: 20),
                // زر الميكروفون
                FloatingActionButton(
                  heroTag: 'mic',
                  backgroundColor: _isMicOn ? Colors.blue : Colors.grey,
                  onPressed: _toggleMicrophone,
                  child: Icon(_isMicOn ? Icons.mic : Icons.mic_off),
                ),
                const SizedBox(width: 20),
                // زر إنهاء المكالمة
                FloatingActionButton(
                  heroTag: 'end',
                  backgroundColor: Colors.red,
                  onPressed: () {
                    print('إنهاء المكالمة');
                    widget.engine.leaveChannel();
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.call_end),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoView() {
    if (!_isJoined || !_isVideoReady) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 10),
            Text(
              'جاري الاتصال بالمكالمة...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // الفيديو البعيد (الشاشة الكبيرة)
        Center(
          child: _remoteUid != null
              ? AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: widget.engine,
              canvas: VideoCanvas(
                uid: _remoteUid,
                renderMode: RenderModeType.renderModeFit,
              ),
            ),
          )
              : const Center(
            child: Text(
              'في انتظار انضمام الشخص الآخر...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        // الفيديو المحلي (الشاشة الصغيرة)
        if (_isCameraOn)
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: widget.engine,
                  canvas: const VideoCanvas(
                    uid: 0,
                    renderMode: RenderModeType.renderModeFit,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}