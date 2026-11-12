import 'package:flutter/material.dart';

/// Where people can find the app. Shown on shared pictures.
const websiteHost = 'myrunningjournal.co.za';
const websiteUrl = 'https://$websiteHost';
const inviteLine = 'Join me on My Running Journal';

/// The text that goes with a shared picture: [base] plus an invitation and the
/// website, so the message works even where the picture's small print cannot be
/// read or tapped.
String withInvite(String base) =>
    '$base\n\n$inviteLine: $websiteUrl';

/// An invitation for the bottom of a shared picture: a line of text and the
/// website address. [compact] is for smaller poster footers.
class InviteFooter extends StatelessWidget {
  final bool compact;
  const InviteFooter({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(inviteLine,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w700)),
        SizedBox(height: compact ? 2 : 4),
        Text(websiteHost,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: const Color(0xFFFFE08A),
                fontSize: compact ? 13 : 16,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}
