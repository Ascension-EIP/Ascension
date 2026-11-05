// @date 2026-10-25
// @file upload_page.dart
// @brief File description.
// @project Ascension
// @author Nicolas TORO <nicolas.toro@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:old_mobile/shared/components/header.dart';
import 'package:old_mobile/shared/localization/app_localizations.dart';
import 'package:old_mobile/shared/components/video_upload.dart';

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
