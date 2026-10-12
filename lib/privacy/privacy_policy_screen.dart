import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: const SingleChildScrollView(
              key: Key('privacy-policy-scroll'),
              padding: EdgeInsets.fromLTRB(24, 20, 24, 40),
              child: SelectionArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PolicyParagraph(
                      'This Privacy Policy explains how Pathly and its '
                      'developer, DaMo Studio, handle information when you '
                      'use the app.',
                    ),
                    _PolicyHeading('Information Stored on Your Device'),
                    _PolicyParagraph(
                      'Pathly stores gameplay progress locally on your device, '
                      'including completed level identifiers, best move '
                      'counts, and best completion times.',
                    ),
                    _PolicyParagraph(
                      'Local progress is not used for cloud account sync and '
                      'is not uploaded as a player profile.',
                    ),
                    _PolicyHeading('Analytics'),
                    _PolicyParagraph(
                      'Pathly uses Firebase Analytics to understand how the '
                      'app is used and to improve the game. Firebase Analytics '
                      'may collect or process app interactions, app lifecycle '
                      'and activity information, device and app information, '
                      'app-instance identifiers or similar Firebase-generated '
                      'identifiers, and approximate or coarse geographic '
                      'information derived by Firebase from network '
                      'information where applicable.',
                    ),
                    _PolicyParagraph(
                      'Advertising ID collection is disabled by Pathly. Pathly '
                      'does not request Android location permissions and does '
                      'not collect precise GPS location.',
                    ),
                    _PolicyParagraph(
                      'Pathly logs these gameplay and usage metrics:\n'
                      '• share_app_click when the Share Pathly button is tapped\n'
                      '• level_complete when a level is successfully completed',
                    ),
                    _PolicyParagraph(
                      'The level_complete event may include the level '
                      'identifier, season number, level number, move count, and '
                      'completion time. These are gameplay and usage metrics, '
                      'not personal profile information.',
                    ),
                    _PolicyHeading('Crash Reporting'),
                    _PolicyParagraph(
                      'Pathly uses Firebase Crashlytics to diagnose crashes and '
                      'improve app stability. Crashlytics may process crash '
                      'logs, stack traces, app or device state relevant to a '
                      'crash, installation identifiers, and session-related '
                      'diagnostic information.',
                    ),
                    _PolicyParagraph(
                      'Pathly does not manually collect passwords, contacts, '
                      'messages, photos, microphone recordings, or precise '
                      'location for crash reporting.',
                    ),
                    _PolicyHeading('Sharing'),
                    _PolicyParagraph(
                      'The Share Pathly feature opens the Android system share '
                      'chooser and shares a fixed promotional message. Pathly '
                      'does not read your contacts or inspect the share '
                      'destination you select. Tapping the Share Pathly button '
                      'is logged as a Firebase Analytics interaction.',
                    ),
                    _PolicyHeading('Third-Party Services'),
                    _PolicyParagraph(
                      'Firebase Analytics and Firebase Crashlytics are provided '
                      'by Google. Analytics and Crashlytics data may be '
                      'processed by Google and Firebase according to their '
                      'applicable terms and privacy practices. Pathly and DaMo '
                      'Studio do not sell personal information.',
                    ),
                    _PolicyHeading('Data Retention and Deletion'),
                    _PolicyParagraph(
                      'Local gameplay progress remains on your device until you '
                      "clear Pathly's app data or uninstall Pathly.",
                    ),
                    _PolicyParagraph(
                      'Retention of Firebase Analytics and Crashlytics data is '
                      'managed through Firebase and Google service settings and '
                      'policies.',
                    ),
                    _PolicyHeading("Children's Privacy"),
                    _PolicyParagraph(
                      'Pathly does not knowingly collect personal information '
                      'directly through forms, accounts, or user-submitted '
                      'profiles.',
                    ),
                    _PolicyHeading('Permissions'),
                    _PolicyParagraph(
                      'Pathly does not request access to contacts, the camera, '
                      'the microphone, photos or media, or precise location.',
                    ),
                    _PolicyHeading('Contact'),
                    _PolicyParagraph(
                      'Developer: DaMo Studio\n'
                      'Website: https://damo-studio.com\n'
                      'Privacy Policy: '
                      'https://damo-studio.com/pathly-privacypolicy\n'
                      'Privacy contact: info@damo-studio.com',
                      key: Key('privacy-policy-contact'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PolicyHeading extends StatelessWidget {
  const _PolicyHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PolicyParagraph extends StatelessWidget {
  const _PolicyParagraph(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: const Color(0xFFD2DCE9),
          height: 1.5,
        ),
      ),
    );
  }
}
