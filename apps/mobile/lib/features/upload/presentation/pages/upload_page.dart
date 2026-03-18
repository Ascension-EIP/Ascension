import 'package:flutter/material.dart';
import 'package:mobile/shared/components/header.dart';
import 'package:mobile/shared/localization/app_localizations.dart';
import 'package:mobile/shared/components/video_upload.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: Header(
        title: l10n.t('upload.title'),
        description: l10n.t('upload.description'),
      ),
      body: VideoUpload(),
    );
  }
}
