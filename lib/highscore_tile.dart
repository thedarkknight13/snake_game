import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HighscoreTile extends StatelessWidget {
  const HighscoreTile({
    super.key,
    required this.documentId,
  });

  final String documentId;

  @override
  Widget build(BuildContext context) {
    // Get collection of highscores
    CollectionReference highscores = FirebaseFirestore.instance.collection(
      "high_scores",
    );

    return FutureBuilder(
      future: highscores.doc(documentId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          Map<String, dynamic> data =
              snapshot.data!.data() as Map<String, dynamic>;
          return Row(
            children: [
              Text(data['score'].toString()),
              const SizedBox(width: 10),
              Text(data['name']),
            ],
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
