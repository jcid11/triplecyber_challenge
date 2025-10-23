import 'package:flutter/material.dart';
import 'package:triplecyber_challenge/utils/reusable_widgets/build_text.dart';

void showLoadingDialog(BuildContext context, {String message = 'Loading...'}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min, // keeps dialog small
          children: [
            const SizedBox(height: 12,),
            const SizedBox(
              height: 48,
              width: 48,
              child: CircularProgressIndicator(strokeWidth: 6),
            ),
            const SizedBox(height: 20),
            BuildText(
              text: message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    },
  );
}
