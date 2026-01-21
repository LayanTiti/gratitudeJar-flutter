import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
   ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool loading = true;
  bool editing = false;

  String email = '';
  String fullName = '';

  final Color primary =  Color(0xFF0A6167);
  final Color accent =  Color(0xFFEA7A48);
  final Color bgColor =  Color.fromARGB(255, 205, 229, 229);
  final Color fieldBg =  Color(0xFFF6F6F6);
  final Color borderGrey =  Color(0xFFE0E0E0);

  User get _user => _auth.currentUser!;
  String get uid => _user.uid;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(uid);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  //FirebaseAuth + Firestore
  Future<void> _loadProfile() async {
    try {
      email = _user.email ?? '';
      fullName = (_user.displayName ?? '').trim();

      final snap = await _userDoc.get();
      final data = snap.data();

      if (data != null) {
        final fsName = (data['fullName'] ?? '').toString().trim();
        if (fsName.isNotEmpty) fullName = fsName;
      }

      if (fullName.isEmpty) fullName = 'User';

      _nameController.text = fullName;
      _emailController.text = email;

      if (data == null) {
        await _userDoc.set({
          'fullName': fullName,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {
      email = _user.email ?? '';
      fullName = (_user.displayName ?? 'User').trim();
      if (fullName.isEmpty) fullName = 'User';
      _nameController.text = fullName;
      _emailController.text = email;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  //update Name + Firestore
  Future<void> _save() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => loading = true);

    try {
      await _user.updateDisplayName(newName);
      await _userDoc.set({
        'fullName': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      fullName = newName;
      editing = false;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Profile updated ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: label, 
      hintText: hint,
      prefixIcon: Icon(icon, color: enabled ? primary : Colors.grey.shade500),
      filled: true,
      fillColor: enabled ? fieldBg : Colors.grey.shade200,
      contentPadding:  EdgeInsets.symmetric(horizontal: 14, vertical: 16),

      
      labelStyle: TextStyle(
        color: primary,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: TextStyle(
        color: primary,
        fontWeight: FontWeight.w800,
      ),

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
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  // reset password dialog
  Future<void> _showResetPasswordDialog() async {
    final userEmail = (_user.email ?? '').trim();

    return showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Change Password'),
          content: Text(
            'A reset link will be sent to:\n$userEmail',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: primary)),
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(accent),
                foregroundColor:  WidgetStatePropertyAll(Colors.white),
                elevation:  WidgetStatePropertyAll(0),
                shadowColor:
                     WidgetStatePropertyAll(Colors.transparent),
                overlayColor: WidgetStatePropertyAll(accent.withOpacity(0.15)),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              onPressed: () async {
                try {
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: userEmail);

                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Reset link sent ✅')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: $e')),
                  );
                }
              },
              child:  Text(
                'Send Link',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );
  }

  void _toggleEdit() {
    setState(() {
      editing = !editing;
      _nameController.text = fullName; 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      body: loading
          ? Center(child: CircularProgressIndicator(color: primary))
          : SafeArea(
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: TextSelectionThemeData(
                    cursorColor: primary,
                    selectionColor: primary.withOpacity(0.25),
                    selectionHandleColor: primary,
                  ),
                ),
                child: SingleChildScrollView(
                  padding:  EdgeInsets.all(16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    children: [
                      // Header card 
                      Container(
                        width: double.infinity,
                        padding:  EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderGrey),
                          boxShadow:  [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: primary,
                              child:
                                   Icon(Icons.person, color: Colors.white),
                            ),
                             SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                fullName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                       SizedBox(height: 14),

                      //Account Details card
                      Container(
                        width: double.infinity,
                        padding:  EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderGrey),
                          boxShadow:  [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            //Edit icon
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Account Details',
                                    style: TextStyle(
                                      color: primary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: editing ? 'Cancel' : 'Edit',
                                  icon: Icon(
                                    editing ? Icons.close : Icons.edit,
                                    color: primary,
                                  ),
                                  onPressed: _toggleEdit,
                                ),
                              ],
                            ),
                             SizedBox(height: 10),

                            // Full Name 
                            TextField(
                              controller: _nameController,
                              enabled: editing,
                              cursorColor: primary,
                              decoration: _decoration(
                                label: 'Full Name',
                                icon: Icons.badge,
                                hint: 'Your full name',
                                enabled: editing,
                              ),
                            ),

                             SizedBox(height: 14),

                            // Email 
                            TextField(
                              controller: _emailController,
                              enabled: false,
                              decoration: _decoration(
                                label: 'Email',
                                icon: Icons.email,
                                enabled: false,
                              ),
                            
                              style: TextStyle(
                                color:  Color.fromARGB(255, 193, 193, 193),
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                             SizedBox(height: 14),

                            // Change password button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: _showResetPasswordDialog,
                                icon:
                                    Icon(Icons.lock_reset, color: accent),
                                label: Text(
                                  'Change Password',
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: borderGrey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),

                             SizedBox(height: 14),

                            
                            if (editing)
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor:
                                        WidgetStatePropertyAll(accent),
                                    foregroundColor:
                                         WidgetStatePropertyAll(
                                            Colors.white),
                                    elevation:
                                         WidgetStatePropertyAll(0),
                                    shadowColor:
                                         WidgetStatePropertyAll(
                                            Colors.transparent),
                                    overlayColor: WidgetStatePropertyAll(
                                        accent.withOpacity(0.15)),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                    ),
                                  ),
                                  onPressed: _save,
                                  child:  Text(
                                    'Save',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              )
                            else
                               Text(
                                'Tap the pencil to edit your name.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
