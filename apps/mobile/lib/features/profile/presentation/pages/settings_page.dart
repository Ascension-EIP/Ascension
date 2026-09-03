// @date 2026-09-03
// @file settings_page.dart
// @brief File description.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:mobile/core/accessibility/accessibility_announcer.dart';
import 'package:mobile/core/accessibility/accessibility_settings_service.dart';
import 'package:mobile/core/audio/audio_service.dart';
import 'package:mobile/core/network/api_service.dart';
import 'package:mobile/shared/localization/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final AccessibilitySettingsService _a11y = AccessibilitySettingsService();
  late final TextEditingController _urlController;
  bool _saved = false;
  bool _musicEnabled = false;
  late bool _mockApiEnabled;
  int _sliderEpoch = 0;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiService().baseUrl);
    _musicEnabled = AudioService().musicEnabled;
    _mockApiEnabled = ApiService().mockMode;
    AudioService().addListener(_onAudioChanged);
  }

  void _onAudioChanged() {
    if (mounted) setState(() => _musicEnabled = AudioService().musicEnabled);
  }

  @override
  void dispose() {
    _urlController.dispose();
    AudioService().removeListener(_onAudioChanged);
    super.dispose();
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    await ApiService().setBaseUrl(url);
    if (!mounted) return;
    setState(() => _saved = true);
    AccessibilityAnnouncer.announce(context, 'URL du backend sauvegardée');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).t('settings.savedUrl')),
      ),
    );
  }

  Future<void> _onMockApiChanged(bool value) async {
    await ApiService().setMockMode(value);
    if (!mounted) return;
    setState(() => _mockApiEnabled = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Mode simulation activé : aucun appel serveur réel'
              : 'Mode simulation désactivé : les appels vont vers le backend',
        ),
      ),
    );
  }

  Future<void> _onThemeModeChanged(ThemeMode mode) async {
    await _a11y.setThemeMode(mode);
    if (mounted) setState(() {});
  }

  Future<void> _onHapticIntensityChanged(HapticIntensity intensity) async {
    await _a11y.setHapticIntensity(intensity);
    if (!mounted) return;

    switch (intensity) {
      case HapticIntensity.off:
        break;
      case HapticIntensity.light:
        await HapticFeedback.selectionClick();
      case HapticIntensity.medium:
        await HapticFeedback.lightImpact();
      case HapticIntensity.strong:
        await HapticFeedback.mediumImpact();
    }
  }

  Future<void> _resetA11yDefaults() async {
    await _a11y.resetToDefaults();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _sliderEpoch++);
    AccessibilityAnnouncer.announce(context, l10n.t('settings.resetAnnounce'));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.t('settings.resetDone'))));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('settings.title')), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text('Apparence', style: theme.textTheme.h4),
          const SizedBox(height: 8),
          _SelectRow<ThemeMode>(
            key: ValueKey('theme-$_sliderEpoch'),
            title: 'Thème',
            subtitle: 'Système, clair ou sombre',
            value: _a11y.themeMode,
            options: const {
              ThemeMode.system: 'Système',
              ThemeMode.light: 'Clair',
              ThemeMode.dark: 'Sombre',
            },
            onChanged: _onThemeModeChanged,
          ),
          const SizedBox(height: 20),
          const ShadSeparator.horizontal(),
          const SizedBox(height: 20),
          Text(l10n.t('settings.backend'), style: theme.textTheme.h4),
          const SizedBox(height: 8),
          _SwitchRow(
            title: 'Mode simulation (sans serveur)',
            subtitle: _mockApiEnabled
                ? 'Activé — connexion, inscription et analyses sont simulées localement.'
                : 'Désactivé — l\'app appelle le vrai backend ci-dessous.',
            value: _mockApiEnabled,
            onChanged: _onMockApiChanged,
          ),
          const SizedBox(height: 8),
          ShadInput(
            controller: _urlController,
            enabled: !_mockApiEnabled,
            keyboardType: TextInputType.url,
            autocorrect: false,
            minLines: 1,
            maxLines: 2,
            placeholder: Text(l10n.t('settings.backendHint')),
            onChanged: (_) {
              if (_saved) setState(() => _saved = false);
            },
            trailing: _saved
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
          ),
          const SizedBox(height: 4),
          Text(l10n.t('settings.backendHelper'), style: theme.textTheme.muted),
          const SizedBox(height: 16),
          ShadButton(
            width: double.infinity,
            enabled: !_mockApiEnabled,
            onPressed: _mockApiEnabled ? null : _save,
            leading: const Icon(Icons.save_outlined),
            child: Text(l10n.t('settings.save')),
          ),
          const SizedBox(height: 20),
          _SwitchRow(
            title: l10n.t('settings.music'),
            subtitle: l10n.t('settings.musicSubtitle'),
            value: _musicEnabled,
            onChanged: (value) {
              setState(() => _musicEnabled = value);
              AudioService().setMusicEnabled(value);
            },
          ),
          const SizedBox(height: 28),
          const ShadSeparator.horizontal(),
          const SizedBox(height: 20),
          Text(l10n.t('settings.accessibility'), style: theme.textTheme.h3),
          const SizedBox(height: 6),
          Text(
            l10n.t('settings.accessibilitySubtitle'),
            style: theme.textTheme.muted,
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _a11y,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShadCard(
                    title: Text(l10n.t('settings.readingDisplay')),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LabeledSlider(
                          key: ValueKey('textScale-$_sliderEpoch'),
                          label: l10n.t('settings.textSize'),
                          helpText: l10n.t('settings.textSizeHelp'),
                          valueLabel:
                              '${(_a11y.textScale * 100).round().toString()} %',
                          min: AccessibilitySettingsService.minTextScale,
                          max: AccessibilitySettingsService.maxTextScale,
                          value: _a11y.textScale,
                          onChanged: _a11y.setTextScale,
                        ),
                        const SizedBox(height: 8),
                        _SelectRow<AppLanguage>(
                          key: ValueKey('language-$_sliderEpoch'),
                          title: l10n.t('settings.language'),
                          subtitle: l10n.t('settings.languageSubtitle'),
                          value: _a11y.appLanguage,
                          options: {
                            AppLanguage.french: l10n.t('settings.languageFr'),
                            AppLanguage.english: l10n.t('settings.languageEn'),
                          },
                          onChanged: _a11y.setAppLanguage,
                        ),
                        const SizedBox(height: 8),
                        _SwitchRow(
                          title: l10n.t('settings.highContrast'),
                          subtitle: l10n.t('settings.highContrastHelp'),
                          value: _a11y.highContrast,
                          onChanged: _a11y.setHighContrast,
                        ),
                        const SizedBox(height: 8),
                        _SwitchRow(
                          title: l10n.t('settings.dyslexia'),
                          subtitle: l10n.t('settings.dyslexiaHelp'),
                          value: _a11y.dyslexiaProfile,
                          onChanged: _a11y.setDyslexiaProfile,
                        ),
                        const SizedBox(height: 8),
                        _LabeledSlider(
                          key: ValueKey('readingSpeed-$_sliderEpoch'),
                          label: l10n.t('settings.readingSpeed'),
                          helpText: l10n.t('settings.readingSpeedHelp'),
                          valueLabel:
                              '${_a11y.readingSpeed.toStringAsFixed(2)}×',
                          min: AccessibilitySettingsService.minReadingSpeed,
                          max: AccessibilitySettingsService.maxReadingSpeed,
                          value: _a11y.readingSpeed,
                          onChanged: _a11y.setReadingSpeed,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ShadCard(
                    title: Text(l10n.t('settings.interactionComfort')),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SwitchRow(
                          title: l10n.t('settings.reducedMotion'),
                          subtitle: l10n.t('settings.reducedMotionHelp'),
                          value: _a11y.reducedMotion,
                          onChanged: _a11y.setReducedMotion,
                        ),
                        const SizedBox(height: 8),
                        _SwitchRow(
                          title: l10n.t('settings.simplifiedUi'),
                          subtitle: l10n.t('settings.simplifiedUiHelp'),
                          value: _a11y.simplifiedInterface,
                          onChanged: _a11y.setSimplifiedInterface,
                        ),
                        const SizedBox(height: 8),
                        _SwitchRow(
                          title: l10n.t('settings.captions'),
                          subtitle: l10n.t('settings.captionsHelp'),
                          value: _a11y.captionsEnabled,
                          onChanged: _a11y.setCaptionsEnabled,
                        ),
                        const SizedBox(height: 8),
                        _SelectRow<HapticIntensity>(
                          key: ValueKey('haptic-$_sliderEpoch'),
                          title: l10n.t('settings.hapticIntensity'),
                          subtitle: l10n.t('settings.hapticHelp'),
                          value: _a11y.hapticIntensity,
                          options: {
                            HapticIntensity.off: l10n.t('settings.hapticOff'),
                            HapticIntensity.light: l10n.t(
                              'settings.hapticLight',
                            ),
                            HapticIntensity.medium: l10n.t(
                              'settings.hapticMedium',
                            ),
                            HapticIntensity.strong: l10n.t(
                              'settings.hapticStrong',
                            ),
                          },
                          onChanged: _onHapticIntensityChanged,
                        ),
                        const SizedBox(height: 8),
                        _SwitchRow(
                          title: l10n.t('settings.reducedInterruptions'),
                          subtitle: l10n.t('settings.reducedInterruptionsHelp'),
                          value: _a11y.reducedInterruptions,
                          onChanged: _a11y.setReducedInterruptions,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  ShadCard(
                    title: Text(l10n.t('settings.preview')),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.t('settings.previewText'),
                          style: theme.textTheme.p,
                        ),
                        const SizedBox(height: 10),
                        ShadButton.outline(
                          width: double.infinity,
                          leading: const Icon(Icons.restore),
                          onPressed: _resetA11yDefaults,
                          child: Text(l10n.t('settings.reset')),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Row pairing a title/subtitle with a trailing [ShadSwitch], mirroring the
/// former Material `SwitchListTile` layout.
class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.p),
              Text(subtitle, style: theme.textTheme.muted),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ShadSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}

/// Row pairing a title/subtitle with a trailing [ShadSelect], mirroring the
/// former Material `ListTile` + `DropdownButton` layout.
class _SelectRow<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const _SelectRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.p),
              Text(subtitle, style: theme.textTheme.muted),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ShadSelect<T>(
          initialValue: value,
          minWidth: 140,
          options: options.entries
              .map((e) => ShadOption(value: e.key, child: Text(e.value)))
              .toList(),
          selectedOptionBuilder: (context, v) => Text(options[v] ?? ''),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  final String label;
  final String helpText;
  final String valueLabel;
  final double min;
  final double max;
  final double value;
  final ValueChanged<double> onChanged;

  const _LabeledSlider({
    super.key,
    required this.label,
    required this.helpText,
    required this.valueLabel,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Semantics(
      slider: true,
      label: label,
      value: valueLabel,
      hint: helpText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.p)),
              Text(valueLabel, style: theme.textTheme.small),
            ],
          ),
          ShadSlider(
            min: min,
            max: max,
            initialValue: value,
            onChanged: onChanged,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(helpText, style: theme.textTheme.small),
          ),
        ],
      ),
    );
  }
}
