import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _NoteInput {
  final String text;
  final int mood;
  _NoteInput(this.text, this.mood);
}

class _HomeScreenState extends State<HomeScreen> {
  // Firebase 
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  
  final Color primary =  Color(0xFF0A6167);
  final Color accent =  Color(0xFFF08A5D);
  final Color bgColor =  Color.fromARGB(255, 205, 229, 229);
  final Color fieldBg =  Color(0xFFF6F6F6);
  final Color borderGrey =  Color(0xFFE0E0E0);
  final Color fabOrange =  Color(0xFFEA7A48);

  // current user id
  String get uid => _auth.currentUser!.uid;

  //notes and user reference
  CollectionReference<Map<String, dynamic>> get _notesRef =>
      _db.collection('users').doc(uid).collection('notes');

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(uid);

  String fullName = 'User';
  bool profileLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFullName();
  }

  //load full name from Firestore 
  Future<void> _loadFullName() async {
    try {
      final u = _auth.currentUser;
      String name = (u?.displayName ?? '').trim();

      final snap = await _userDoc.get();
      final data = snap.data();

      if (data != null) {
        final fsName = (data['fullName'] ?? '').toString().trim();
        if (fsName.isNotEmpty) name = fsName;
      }

      if (name.isEmpty) name = 'User';

      if (!mounted) return;
      setState(() {
        fullName = name;
        profileLoading = false;
      });
    } catch (_) {
      final name = (_auth.currentUser?.displayName ?? 'User').trim();
      if (!mounted) return;
      setState(() {
        fullName = name.isEmpty ? 'User' : name;
        profileLoading = false;
      });
    }
  }

  // timestamp format
  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d  $hh:$mm';
  }

  // mood emojه
  String _moodEmoji(int mood) {
    if (mood == 1) return '😐';
    if (mood == 2) return '😔';
    return '😊';
  }

  String _moodText(int mood) {
    if (mood == 1) return 'So-so';
    if (mood == 2) return 'Sad';
    return 'Happy';
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  //TextField inside 
  InputDecoration _dialogFieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fieldBg,
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
    );
  }

  //Add note 
  Future<void> _addNoteDialog() async {
    final rootContext = context; 
    final controller = TextEditingController();
    int selectedMood = 0;

    try {
      final result = await showDialog<_NoteInput>(
        context: rootContext,
        useRootNavigator: true, 
        builder: (dialogCtx) {
          return StatefulBuilder(
            builder: (_, setLocalState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'New Gratitude Note',
                  style: TextStyle(color: primary, fontWeight: FontWeight.w800),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //note text
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      decoration: _dialogFieldDecoration(
                        'Write one thing you are grateful for...',
                      ),
                    ),
                     SizedBox(height: 16),

                    //mood title
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'How was your day?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                     SizedBox(height: 10),

                    //mood buttons
                    Row(
                      children: [
                        Expanded(
                          child: _MoodButton(
                            label: 'Happy',
                            emoji: '😊',
                            isSelected: selectedMood == 0,
                            primary: primary,
                            onTap: () => setLocalState(() => selectedMood = 0),
                          ),
                        ),
                         SizedBox(width: 10),
                        Expanded(
                          child: _MoodButton(
                            label: 'So-so',
                            emoji: '😐',
                            isSelected: selectedMood == 1,
                            primary: primary,
                            onTap: () => setLocalState(() => selectedMood = 1),
                          ),
                        ),
                         SizedBox(width: 10),
                        Expanded(
                          child: _MoodButton(
                            label: 'Sad',
                            emoji: '😔',
                            isSelected: selectedMood == 2,
                            primary: primary,
                            onTap: () => setLocalState(() => selectedMood = 2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  //cancel
                  TextButton(
                    onPressed: () =>
                        Navigator.of(dialogCtx, rootNavigator: true).pop(),
                    child: Text('Cancel', style: TextStyle(color: primary)),
                  ),

                  //save
                  ElevatedButton(
                    style: _primaryButtonStyle(),
                    onPressed: () {
                      final text = controller.text.trim();
                      if (text.isEmpty) return;

                      Navigator.of(dialogCtx, rootNavigator: true).pop(
                        _NoteInput(text, selectedMood),
                      );
                    },
                    child:  Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result == null) return; 

      //Firestore saving after dialog closes
      await _notesRef.add({
        'text': result.text,
        'mood': result.mood,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(rootContext).showSnackBar(
         SnackBar(content: Text('Saved ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      controller.dispose();
    }
  }

  // Edit note 
  Future<void> _editNoteDialog(String docId, String oldText, int oldMood) async {
    final rootContext = context;
    final controller = TextEditingController(text: oldText);
    int selectedMood = oldMood;

    try {
      final result = await showDialog<_NoteInput>(
        context: rootContext,
        useRootNavigator: true, 
        builder: (dialogCtx) {
          return StatefulBuilder(
            builder: (_, setLocalState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Text(
                  'Edit Note',
                  style: TextStyle(color: primary, fontWeight: FontWeight.w800),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //note text
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      decoration: _dialogFieldDecoration('Update your note...'),
                    ),
                     SizedBox(height: 16),

                    //mood title
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'How was your day?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
                    ),
                     SizedBox(height: 10),

                    // mood buttons
                    Row(
                      children: [
                        Expanded(
                          child: _MoodButton(
                            label: 'Happy',
                            emoji: '😊',
                            isSelected: selectedMood == 0,
                            primary: primary,
                            onTap: () => setLocalState(() => selectedMood = 0),
                          ),
                        ),
                         SizedBox(width: 10),
                        Expanded(
                          child: _MoodButton(
                            label: 'So-so',
                            emoji: '😐',
                            isSelected: selectedMood == 1,
                            primary: primary,
                            onTap: () => setLocalState(() => selectedMood = 1),
                          ),
                        ),
                         SizedBox(width: 10),
                        Expanded(
                          child: _MoodButton(
                            label: 'Sad',
                            emoji: '😔',
                            isSelected: selectedMood == 2,
                            primary: primary,
                            onTap: () => setLocalState(() => selectedMood = 2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  // cancel
                  TextButton(
                    onPressed: () =>
                        Navigator.of(dialogCtx, rootNavigator: true).pop(),
                    child: Text('Cancel', style: TextStyle(color: primary)),
                  ),

                  //update 
                  ElevatedButton(
                    style: _primaryButtonStyle(),
                    onPressed: () {
                      final newText = controller.text.trim();
                      if (newText.isEmpty) return;

                      Navigator.of(dialogCtx, rootNavigator: true).pop(
                        _NoteInput(newText, selectedMood),
                      );
                    },
                    child:  Text('Update'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result == null) return; 

      //firestore saving after dialog closes
      await _notesRef.doc(docId).update({
        'text': result.text,
        'mood': result.mood,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(rootContext).showSnackBar(
         SnackBar(content: Text('Updated ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      controller.dispose();
    }
  }

  // delete note
  Future<void> _deleteNote(String docId) async {
    try {
      await _notesRef.doc(docId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Deleted 🗑️')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    //stream realtime (snapshots)
    final notesStream =
        _notesRef.orderBy('createdAt', descending: true).snapshots();

    return Stack(
      children: [
        Container(color: bgColor),

        SafeArea(
          child: Padding(
            padding:  EdgeInsets.all(16),
            child: Column(
              children: [
                //Header card
                Container(
                  width: double.infinity,
                  padding:  EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderGrey),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: primary,
                        child: Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                       SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome 👋',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: primary,
                              ),
                            ),
                            Text(
                              profileLoading ? 'Loading...' : fullName,
                              style:  TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                             SizedBox(height: 6),
                             Text(
                              'Tap + to add a gratitude note.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                 SizedBox(height: 14),

                //Notes list
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: notesStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return  Center(child: Text('Error loading notes'));
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: primary),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Text(
                            "No notes yet.\nAdd your first gratitude note 🌿",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.6),
                              fontSize: 14,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: EdgeInsets.only(bottom: 90),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();

                          final text = (data['text'] ?? '').toString();
                          final mood =
                              (data['mood'] is int) ? data['mood'] as int : 0;

                          final createdAt = data['createdAt'] as Timestamp?;
                          final updatedAt = data['updatedAt'] as Timestamp?;

                          final subtitle = updatedAt != null
                              ? 'Updated: ${_formatTimestamp(updatedAt)}'
                              : 'Created: ${_formatTimestamp(createdAt)}';

                          return Dismissible(
                            key: ValueKey(doc.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: EdgeInsets.only(bottom: 12),
                              padding: EdgeInsets.only(right: 20),
                              alignment: Alignment.centerRight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.redAccent,
                              ),
                              child:
                                   Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) => _deleteNote(doc.id),
                            child: Container(
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderGrey),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: primary,
                                  child: Text(
                                    _moodEmoji(mood),
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                                title: Text(
                                  text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  '$subtitle  •  ${_moodText(mood)}',
                                  style: TextStyle(fontSize: 12),
                                ),
                                trailing: IconButton(
                                  tooltip: 'Edit',
                                  icon: Icon(Icons.edit, color: primary),
                                  onPressed: () =>
                                      _editNoteDialog(doc.id, text, mood),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

  //add note
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: fabOrange,
            elevation: 3,
            onPressed: _addNoteDialog,
            child:  Icon(Icons.add, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

//Mood button 
class _MoodButton extends StatelessWidget {
  final String label;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primary;

   _MoodButton({
    required this.label,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : Colors.black26,
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style:  TextStyle(fontSize: 22)),
             SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
