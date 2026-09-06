// @date 2026-09-07
// @file settings_page.dart
// @brief Page des paramètres de l'application Ascension avec intégration Forui.
// @project Ascension
// @author Christophe Vandevoir <christophe.vandevoir@epitech.eu>, Nicolas TORO <nicolas.toro@epitech.eu>, Gianni TUERO <gianni.tuero@epitech.eu>
// @copyright (c) 2026 Ascension
// @status done
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
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
    final l10n = AppLocalizations.of(context);
    await _a11y.resetToDefaults();
    if (!mounted) return;
    setState(() => _sliderEpoch++);
    AccessibilityAnnouncer.announce(context, l10n.t('settings.resetDone'));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.t('settings.resetDone'))));
  }

  @override
  Widget build(BuildContext context) {
    final typo = context.theme.typography;
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('settings.title')), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'Apparence',
            style: typo.display.lg.copyWith(fontWeight: FontWeight.w700),
          ),
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
          const FDivider(),
          const SizedBox(height: 20),
          Text(
            l10n.t('settings.backend'),
            style: typo.display.lg.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _SwitchRow(
            title: 'Mode simulation (sans serveur)',
            subtitle: _mockApiEnabled
                ? 'Activé — connexion, inscription et analyses sont simulées localement.'
                : 'Désactivé — l\'app appelle le vrai backend ci-dessous.',
            value: _mockApiEnabled,
            onChanged: _onMockApiChanged,
          ),
          const SizedBox(height: 12),
          FTextField(
            control: FTextFieldControl.managed(controller: _urlController),
            enabled: !_mockApiEnabled,
            keyboardType: TextInputType.url,
            hint: l10n.t('settings.backendHint'),
            description: Text(l10n.t('settings.backendHelper')),
            suffixBuilder: _saved
                ? (context, style, variants) => const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 20,
                  )
                : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FButton(
              onPress: _mockApiEnabled ? null : _save,
              prefix: const Icon(Icons.save_outlined),
              child: Text(l10n.t('settings.save')),
            ),
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
          const FDivider(),
          const SizedBox(height: 20),
          Text(
            l10n.t('settings.accessibility'),
            style: typo.display.xl2.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.t('settings.accessibilitySubtitle'),
            style: typo.body.sm.copyWith(color: colors.mutedForeground),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _a11y,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('settings.readingDisplay'),
                            style: typo.body.md.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 12),
                          _SelectRow<AppLanguage>(
                            key: ValueKey('language-$_sliderEpoch'),
                            title: l10n.t('settings.language'),
                            subtitle: l10n.t('settings.languageSubtitle'),
                            value: _a11y.appLanguage,
                            options: {
                              AppLanguage.french: l10n.t('settings.languageFr'),
                              AppLanguage.english: l10n.t(
                                'settings.languageEn',
                              ),
                            },
                            onChanged: _a11y.setAppLanguage,
                          ),
                          const SizedBox(height: 12),
                          _SwitchRow(
                            title: l10n.t('settings.highContrast'),
                            subtitle: l10n.t('settings.highContrastHelp'),
                            value: _a11y.highContrast,
                            onChanged: _a11y.setHighContrast,
                          ),
                          const SizedBox(height: 12),
                          _SwitchRow(
                            title: l10n.t('settings.dyslexia'),
                            subtitle: l10n.t('settings.dyslexiaHelp'),
                            value: _a11y.dyslexiaProfile,
                            onChanged: _a11y.setDyslexiaProfile,
                          ),
                          const SizedBox(height: 12),
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
                  ),
                  const SizedBox(height: 14),
                  FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('settings.interactionComfort'),
                            style: typo.body.md.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SwitchRow(
                            title: l10n.t('settings.reducedMotion'),
                            subtitle: l10n.t('settings.reducedMotionHelp'),
                            value: _a11y.reducedMotion,
                            onChanged: _a11y.setReducedMotion,
                          ),
                          const SizedBox(height: 12),
                          _SwitchRow(
                            title: l10n.t('settings.simplifiedUi'),
                            subtitle: l10n.t('settings.simplifiedUiHelp'),
                            value: _a11y.simplifiedInterface,
                            onChanged: _a11y.setSimplifiedInterface,
                          ),
                          const SizedBox(height: 12),
                          _SwitchRow(
                            title: l10n.t('settings.captions'),
                            subtitle: l10n.t('settings.captionsHelp'),
                            value: _a11y.captionsEnabled,
                            onChanged: _a11y.setCaptionsEnabled,
                          ),
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 12),
                          _SwitchRow(
                            title: l10n.t('settings.reducedInterruptions'),
                            subtitle: l10n.t(
                              'settings.reducedInterruptionsHelp',
                            ),
                            value: _a11y.reducedInterruptions,
                            onChanged: _a11y.setReducedInterruptions,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('settings.preview'),
                            style: typo.body.md.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.t('settings.previewText'),
                            style: typo.body.sm,
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FButton(
                              variant: .outline,
                              prefix: const Icon(Icons.restore),
                              onPress: _resetA11yDefaults,
                              child: Text(l10n.t('settings.reset')),
                            ),
                          ),
                        ],
                      ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Semantics(
        container: true,
        label: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
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
    final typo = context.theme.typography;
    final colors = context.theme.colors;
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
              Expanded(
                child: Text(
                  label,
                  style: typo.body.md.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                valueLabel,
                style: typo.body.sm.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Slider(
            min: min,
            max: max,
            value: value.clamp(min, max),
            activeColor: colors.primary,
            inactiveColor: colors.muted,
            onChanged: onChanged,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              helpText,
              style: typo.body.xs.copyWith(color: colors.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }
}
