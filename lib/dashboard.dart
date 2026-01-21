import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardScreen extends StatelessWidget {
   DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    final auth = FirebaseAuth.instance;
    final db = FirebaseFirestore.instance;
    final uid = auth.currentUser!.uid;
    final notesRef = db.collection('users').doc(uid).collection('notes');

    //calculate last 7 days 
    final now = DateTime.now();
    final start =
        DateTime(now.year, now.month, now.day).subtract( Duration(days: 6));
    final startTs = Timestamp.fromDate(start);

    //firestore stream fetch notes from last 7 days
    final stream = notesRef
        .where('createdAt', isGreaterThanOrEqualTo: startTs)
        .orderBy('createdAt', descending: true)
        .snapshots();

   
    final Color primary =  Color(0xFF0A6167);
    final Color accent =  Color(0xFFEA7A48);
    final Color bgColor =  Color.fromARGB(255, 205, 229, 229);
    final Color borderGrey =  Color(0xFFE0E0E0);

    return Scaffold(
      backgroundColor: bgColor,  

      body: SafeArea(
        //StreamBuilder
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: stream,
          builder: (context, snapshot) {
            //Error state
            if (snapshot.hasError) {
              return Center(child: Text('Error loading dashboard'));
            }

            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: primary));
            }

            final docs = snapshot.data?.docs ?? [];

            int happy = 0, soso = 0, sad = 0;

            final Map<String, int> dayCount = {};

            final Map<String, int> dayMoodScore = {};

            //Initialize the last 7 days 
            for (int i = 0; i < 7; i++) {
              final d = start.add(Duration(days: i));
              final key = _dayKey(d);
              dayCount[key] = 0;
              dayMoodScore[key] = 0;
            }

            //day Count + mood totals + daily scores
            for (final d in docs) {
              final data = d.data();
              final mood = (data['mood'] is int) ? data['mood'] as int : 0;
              final createdAt = data['createdAt'] as Timestamp?;
              if (createdAt == null) continue;

              final dt = createdAt.toDate();
              final key = _dayKey(dt);
              if (!dayCount.containsKey(key)) continue;

              // Increase notes for that day
              dayCount[key] = (dayCount[key] ?? 0) + 1;

              //Count moods for overall summary
              if (mood == 0) {
                happy++;
              } else if (mood == 1) {
                soso++;
              } else {
                sad++;
              }

              //Convert mood to score
              final score = (mood == 0) ? 2 : (mood == 1) ? 1 : 0;
              dayMoodScore[key] = (dayMoodScore[key] ?? 0) + score;
            }

            // Total notes
            final total = happy + soso + sad;

            // top mood based on highest count
            final topMood = _topMood(happy, soso, sad);

            // Best/Worst day = (sumScores / notesCount)
            String bestDay = '-';
            String worstDay = '-';
            double bestAvg = -1;
            double worstAvg = 999;

            dayCount.forEach((key, c) {
              final sum = dayMoodScore[key] ?? 0;

              final avg = c == 0 ? -1.0 : (sum / c).toDouble();

              if (avg >= 0 && avg > bestAvg) {
                bestAvg = avg;
                bestDay = key;
              }
              if (avg >= 0 && avg < worstAvg) {
                worstAvg = avg;
                worstDay = key;
              }
            });

            return SingleChildScrollView(
              padding:  EdgeInsets.all(18),

              child: Container(
                padding:  EdgeInsets.fromLTRB(18, 18, 18, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderGrey),
                ),
                child: Column(
                  children: [
                    //Overview summary
                    _CardBox(
                      borderGrey: borderGrey,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: primary,
                            child:  Icon(Icons.insights,
                                color: Colors.white),
                          ),
                           SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Last 7 Days Overview',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: primary,
                                  ),
                                ),
                                 SizedBox(height: 8),

                                //summary lines
                                Text('Total Notes: $total'),
                                Text('Top Mood: $topMood'),
                                Text(
                                    'Best Day: ${bestDay == "-" ? "-" : bestDay.substring(5)}'),
                                Text(
                                    'Worst Day: ${worstDay == "-" ? "-" : worstDay.substring(5)}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                     SizedBox(height: 14),

                    // Mood counts 
                    _CardBox(
                      borderGrey: borderGrey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.mood_rounded, color: accent),
                               SizedBox(width: 8),
                              Text(
                                'Mood Counts',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                           SizedBox(height: 12),

                          _MoodRow(
                            label: 'Happy 😊',
                            value: happy,
                            max: total == 0 ? 1 : total,
                            color: primary,
                          ),
                           SizedBox(height: 10),
                          _MoodRow(
                            label: 'So-so 😐',
                            value: soso,
                            max: total == 0 ? 1 : total,
                            color: primary,
                          ),
                           SizedBox(height: 10),
                          _MoodRow(
                            label: 'Sad 😔',
                            value: sad,
                            max: total == 0 ? 1 : total,
                            color: primary,
                          ),
                        ],
                      ),
                    ),
                     SizedBox(height: 14),

                    //Daily notes
                    _CardBox(
                      borderGrey: borderGrey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_month_rounded, color: accent),
                               SizedBox(width: 8),
                              Text(
                                'Daily Notes',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: primary,
                                ),
                              ),
                            ],
                          ),
                           SizedBox(height: 12),

                          //how many notes each day
                          ..._buildDailyBars(dayCount, primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // yyyy-mm-dd
  static String _dayKey(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  //top mood 
  static String _topMood(int happy, int soso, int sad) {
    final maxVal = [happy, soso, sad].reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return '-';
    if (maxVal == happy) return 'Happy 😊';
    if (maxVal == soso) return 'So-so 😐';
    return 'Sad 😔';
  }

  //daily progress
  static List<Widget> _buildDailyBars(
      Map<String, int> dayCount, Color barColor) {
    final maxCount = dayCount.values.isEmpty
        ? 1
        : dayCount.values.reduce((a, b) => a > b ? a : b);

    return dayCount.entries.map((e) {
      final ratio = maxCount == 0 ? 0.0 : (e.value / maxCount);

      return Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 70,
              child: Text(
                e.key.substring(5),
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 10,
                  backgroundColor: Colors.black12,
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
            ),

             SizedBox(width: 10),

            SizedBox(
              width: 28,
              child: Text(
                '${e.value}',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

// unify style for each section
class _CardBox extends StatelessWidget {
  final Widget child;
  final Color borderGrey;
   _CardBox({required this.child, required this.borderGrey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey),
        boxShadow:  [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}

//mood progress 
class _MoodRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;

   _MoodRow({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : (value / max);

    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style:  TextStyle(fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
         SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Text('$value', style:  TextStyle(fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}
