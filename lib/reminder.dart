import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:audioplayers/audioplayers.dart';

class ReminderScreen extends StatefulWidget {
  ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final AudioPlayer _player = AudioPlayer();

  String get uid => _auth.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _reminderDoc =>
      _db.collection('users').doc(uid).collection('settings').doc('reminder');

  bool enabled = false;
  int hour = 21;
  int minute = 0;
  bool loading = true;

  final Color primary = Color(0xFF0A6167);
  final Color accent = Color(0xFFEA7A48);
  final Color bgColor = Color.fromARGB(255, 205, 229, 229);
  final Color fieldBg = Color(0xFFF6F6F6);
  final Color borderGrey = Color(0xFFE0E0E0);

  String tone = 'gentle';
  String sound = 'default';
  List<String> customNotes = [];

  final List<String> gentleNotes = [
    "You are doing better than you think 🌿",
    "Take a deep breath — you are okay 💛",
    "Be gentle with yourself today 🤍",
    "Pause for a moment and appreciate yourself ☕",
    "Today is a fresh chance to begin again ✨",
    "Progress, not perfection 🌸",
  ];

  final List<String> motivationalNotes = [
    "Small steps still move you forward ✨",
    "You are stronger than you realize 💪",
    "Showing up today is already an achievement ✅",
    "Your effort matters more than you think 🌱",
    "Keep going — you’re building something beautiful 🔥",
    "One brave step is enough for today 🚀",
  ];

  final List<String> calmNotes = [
    "Slow down. You have time 🌙",
    "Let your shoulders drop. Breathe 🌬️",
    "It’s okay to rest — you’re not falling behind 🤍",
    "Quiet progress is still progress 🌿",
    "Peace looks good on you 🕊️",
    "You don’t need to do it all today 🍃",
  ];

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    await _initNotifications();
    await _load();
    if (mounted) setState(() => loading = false);

    if (enabled) {
      await _scheduleDaily(showSnack: false);
    }
  }

    Future<void> _initNotifications() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Amman'));

    final androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings = InitializationSettings(android: androidInit);
    await _notifications.initialize(initSettings);

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    final channel = AndroidNotificationChannel(
      'positive_reminder_channel',
      'Positive Reminders',
      description: 'Daily positive messages',
      importance: Importance.max,
    );

    await android?.createNotificationChannel(channel);
  }

  //Load settings from Firestore
  Future<void> _load() async {
    try {
      final snap = await _reminderDoc.get();
      final data = snap.data();

      if (data != null) {
        enabled = data['enabled'] == true;
        hour = (data['hour'] is int) ? data['hour'] as int : 21;
        minute = (data['minute'] is int) ? data['minute'] as int : 0;

        final t = (data['tone'] ?? '').toString().trim().toLowerCase();
        if (t == 'gentle' || t == 'motivational' || t == 'calm') tone = t;

        final s = (data['sound'] ?? '').toString().trim().toLowerCase();
        if (s.isNotEmpty) sound = s;

        final list = data['customNotes'];
        if (list is List) {
          customNotes = list.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}
  }

  // Save settings to Firestore
  Future<void> _save() async {
    await _reminderDoc.set({
      'enabled': enabled,
      'hour': hour,
      'minute': minute,
      'tone': tone,
      'sound': sound,
      'customNotes': customNotes,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

//time 24h
  String _fmtTime(int h, int m) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  tz.TZDateTime _nextInstance(int h, int m) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, h, m);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(Duration(days: 1));
    }
    return scheduled;
  }

  List<String> _toneList() {
    if (tone == 'motivational') return motivationalNotes;
    if (tone == 'calm') return calmNotes;
    return gentleNotes;
  }

  String _randomNote() {
    final combined = <String>[];
    combined.addAll(_toneList());
    combined.addAll(customNotes.where((e) => e.trim().isNotEmpty));
    if (combined.isEmpty) return "You are doing great 🌿";
    return combined[Random().nextInt(combined.length)];
  }

  AndroidNotificationDetails _androidDetails() {
    if (sound == 'default') {
      return AndroidNotificationDetails(
        'positive_reminder_channel',
        'Positive Reminders',
        channelDescription: 'Daily positive messages',
        importance: Importance.max,
        priority: Priority.high,
      );
    }

    return AndroidNotificationDetails(
      'positive_reminder_channel',
      'Positive Reminders',
      channelDescription: 'Daily positive messages',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(sound),
    );
  }

  // Send now
  Future<void> _sendNow() async {
    final note = _randomNote();
    final details = NotificationDetails(android: _androidDetails());

    try {
      await _notifications.show(
        2,
        'Gentle Reminder 💛',
        note,
        details,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sent now ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    }
  }

  //Schedule daily
  Future<void> _scheduleDaily({bool showSnack = true}) async {
    await _notifications.cancel(1);

    final note = _randomNote();
    final details = NotificationDetails(android: _androidDetails());

    await _notifications.zonedSchedule(
      1,
      'Gentle Reminder 💛',
      note,
      _nextInstance(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    if (showSnack && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Daily reminder set at ${_fmtTime(hour, minute)} ✅'),
        ),
      );
    }
  }

  Future<void> _cancelDaily() async {
    await _notifications.cancel(1);
    await _notifications.cancel(2);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reminders turned off ❌')),
    );
  }

  Future<void> _toggle(bool v) async {
    setState(() => enabled = v);
    await _save();

    if (enabled) {
      await _scheduleDaily();
    } else {
      await _cancelDaily();
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );
    if (picked == null) return;

    setState(() {
      hour = picked.hour;
      minute = picked.minute;
    });

    await _save();

    if (enabled) {
      await _scheduleDaily();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Time saved ✅ ${_fmtTime(hour, minute)}')),
      );
    }
  }

  // Tone dropdown
  Future<void> _setTone(String? v) async {
    if (v == null) return;
    setState(() => tone = v);
    await _save();
    if (enabled) await _scheduleDaily(showSnack: false);
  }

  // Sound dropdown
  Future<void> _setSound(String? v) async {
    if (v == null) return;
    setState(() => sound = v);
    await _save();

    if (sound != 'default') {
      try {
        await _player.stop();
        await _player.play(AssetSource('sounds/$sound.mp3'));
      } catch (_) {}
    }

    if (enabled) await _scheduleDaily(showSnack: false);
  }

  //Add custom note
  Future<void> _addCustomNote() async {
    final rootContext = context;
    final controller = TextEditingController();

    try {
     
      final result = await showDialog<String>(
        context: rootContext,
        useRootNavigator: true,
        builder: (dialogCtx) {
          return AlertDialog(
            title:  Text('Add your own note'),
            content: TextField(
              controller: controller,
              maxLines: 3,
              cursorColor: primary,
              decoration: InputDecoration(
                hintText: 'Write a positive note...',
                filled: true,
                fillColor: fieldBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.of(dialogCtx, rootNavigator: true).pop(),
                child: Text('Cancel', style: TextStyle(color: primary)),
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(accent),
                  foregroundColor:  WidgetStatePropertyAll(Colors.white),
                  overlayColor: WidgetStatePropertyAll(accent.withOpacity(0.15)),
                  elevation:  WidgetStatePropertyAll(0),
                  shadowColor:  WidgetStatePropertyAll(Colors.transparent),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;

             
                  Navigator.of(dialogCtx, rootNavigator: true).pop(text);
                },
                child:  Text(
                  'Add',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          );
        },
      );

      // cancelled
      if (result == null || result.trim().isEmpty) return;

      if (!mounted) return;
      setState(() => customNotes.add(result.trim()));

      await _save();

      if (!mounted) return;
      ScaffoldMessenger.of(rootContext).showSnackBar(
       SnackBar(content: Text('Added ✅')),
      );

      if (enabled) {
        await _scheduleDaily(showSnack: false);
      }
    } finally {
      controller.dispose();
    }
  }

  //Manage notes
  Future<void> _manageNotes() async {
    final rootContext = context;

    await showModalBottomSheet(
      context: rootContext,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your notes',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: primary,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  if (customNotes.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No custom notes yet.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: customNotes.length,
                        separatorBuilder: (_, __) => Divider(),
                        itemBuilder: (_, i) {
                          final note = customNotes[i];
                          return ListTile(
                            title: Text(note),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () async {
                                setLocal(() => customNotes.removeAt(i));
                                await _save();
                                if (enabled) {
                                  await _scheduleDaily(showSnack: false);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _dropDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primary),
      filled: true,
      fillColor: fieldBg,
      labelStyle: TextStyle(color: primary, fontWeight: FontWeight.w700),
      floatingLabelStyle: TextStyle(color: primary, fontWeight: FontWeight.w800),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 1.6),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filledBtnStyle = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(accent),
      foregroundColor: WidgetStatePropertyAll(Colors.white),
      overlayColor: WidgetStatePropertyAll(accent.withOpacity(0.15)),
      elevation: WidgetStatePropertyAll(0),
      shadowColor: WidgetStatePropertyAll(Colors.transparent),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    final outlinedBtnStyle = ButtonStyle(
      overlayColor: WidgetStatePropertyAll(accent.withOpacity(0.10)),
      elevation: WidgetStatePropertyAll(0),
      shadowColor: WidgetStatePropertyAll(Colors.transparent),
      side: WidgetStatePropertyAll(BorderSide(color: borderGrey)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    return Scaffold(
      backgroundColor: bgColor,
      body: loading
          ? Center(child: CircularProgressIndicator(color: primary))
          : SingleChildScrollView(
              padding: EdgeInsets.all(18),
              child: Container(
                padding: EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderGrey),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header + Toggle
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Positive Message',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: primary,
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                enabled
                                    ? 'On • ${_fmtTime(hour, minute)}'
                                    : 'Off',
                                style: TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: enabled,
                          onChanged: _toggle,
                          activeColor: accent,
                        ),
                      ],
                    ),

                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 16),

                    // Time
                    GestureDetector(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration:
                            _dropDecoration('Reminder time', Icons.access_time),
                        child: Row(
                          children: [
                            Text(
                              _fmtTime(hour, minute),
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.arrow_drop_down, color: primary),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Tone
                    DropdownButtonFormField<String>(
                      value: tone,
                      decoration: _dropDecoration('Tone', Icons.emoji_emotions),
                      dropdownColor: Colors.white,
                      icon: Icon(Icons.arrow_drop_down, color: primary),
                      items: [
                        DropdownMenuItem(
                            value: 'gentle', child: Text('Gentle')),
                        DropdownMenuItem(
                            value: 'motivational', child: Text('Motivational')),
                        DropdownMenuItem(value: 'calm', child: Text('Calm')),
                      ],
                      onChanged: _setTone,
                    ),

                    SizedBox(height: 14),

                    //Sound
                    DropdownButtonFormField<String>(
                      value: sound,
                      decoration: _dropDecoration('Sound', Icons.volume_up),
                      dropdownColor: Colors.white,
                      icon: Icon(Icons.arrow_drop_down, color: primary),
                      items: [
                        DropdownMenuItem(
                            value: 'default', child: Text('Default')),
                        DropdownMenuItem(value: 'bell', child: Text('Bell')),
                        DropdownMenuItem(value: 'chime', child: Text('Chime')),
                        DropdownMenuItem(value: 'soft', child: Text('Soft')),
                      ],
                      onChanged: _setSound,
                    ),

                    SizedBox(height: 18),

                    // Notes buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: outlinedBtnStyle,
                            onPressed: _addCustomNote,
                            icon: Icon(Icons.add, color: accent),
                            label: Text(
                              'Add note',
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: outlinedBtnStyle,
                            onPressed: _manageNotes,
                            icon: Icon(Icons.list_alt, color: primary),
                            label: Text(
                              'Manage (${customNotes.length})',
                              style: TextStyle(
                                color: primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // Send now
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        style: filledBtnStyle,
                        onPressed: _sendNow,
                        icon: Icon(Icons.send),
                        label: Text(
                          'Send now',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),

                    SizedBox(height: 12),
                    Text(
                      'You will receive one positive message every day at the selected time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
