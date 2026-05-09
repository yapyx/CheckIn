import 'package:flutter/material.dart';

class CareStatusCard extends StatelessWidget {
  const CareStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      color: Color(0xFFE6F1FF),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(child: Icon(Icons.work_rounded)),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('I am working now!',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  Text('Will see your message soon. Sent 10:30 AM'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
