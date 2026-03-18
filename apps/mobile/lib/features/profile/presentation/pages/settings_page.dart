import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiService().baseUrl);
    _musicEnabled = AudioService().musicEnabled;
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
    AccessibilityAnnouncer.announce(context, l10n.t('settings.resetAnnounce'));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.t('settings.resetDone'))));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('settings.title')), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(l10n.t('settings.backend'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            keyboardType: TextInputType.url,
            autocorrect: false,
            minLines: 1,
            maxLines: 2,
            onChanged: (_) {
              if (_saved) setState(() => _saved = false);
            },
            decoration: InputDecoration(
              labelText: l10n.t('settings.backendUrl'),
              hintText: l10n.t('settings.backendHint'),
              helperText: l10n.t('settings.backendHelper'),
              border: const OutlineInputBorder(),
              suffixIcon: _saved
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(l10n.t('settings.save')),
            ),
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.t('settings.music')),
            subtitle: Text(l10n.t('settings.musicSubtitle')),
            value: _musicEnabled,
            onChanged: (value) {
              setState(() => _musicEnabled = value);
              AudioService().setMusicEnabled(value);
            },
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 20),
          Text(
            l10n.t('settings.accessibility'),
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.t('settings.accessibilitySubtitle'),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _a11y,
            builder: (context, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingSectionCard(
                    title: l10n.t('settings.readingDisplay'),
                    children: [
                      _LabeledSlider(
                        label: l10n.t('settings.textSize'),
                        helpText: l10n.t('settings.textSizeHelp'),
                        valueLabel:
                            '${(_a11y.textScale * 100).round().toString()} %',
                        min: AccessibilitySettingsService.minTextScale,
                        max: AccessibilitySettingsService.maxTextScale,
                        value: _a11y.textScale,
                        onChanged: _a11y.setTextScale,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.t('settings.language')),
                        subtitle: Text(l10n.t('settings.languageSubtitle')),
                        trailing: DropdownButton<AppLanguage>(
                          value: _a11y.appLanguage,
                          onChanged: (value) {
                            if (value != null) {
                              _a11y.setAppLanguage(value);
                            }
                          },
                          items: [
                            DropdownMenuItem(
                              value: AppLanguage.french,
                              child: Text(l10n.t('settings.languageFr')),
                            ),
                            DropdownMenuItem(
                              value: AppLanguage.english,
                              child: Text(l10n.t('settings.languageEn')),
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.t('settings.highContrast')),
                        subtitle: Text(l10n.t('settings.highContrastHelp')),
                        value: _a11y.highContrast,
                        onChanged: _a11y.setHighContrast,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.t('settings.dyslexia')),
                        subtitle: Text(l10n.t('settings.dyslexiaHelp')),
                        value: _a11y.dyslexiaProfile,
                        onChanged: _a11y.setDyslexiaProfile,
                      ),
                      _LabeledSlider(
                        label: l10n.t('settings.readingSpeed'),
                        helpText: l10n.t('settings.readingSpeedHelp'),
                        valueLabel: '${_a11y.readingSpeed.toStringAsFixed(2)}×',
                        min: AccessibilitySettingsService.minReadingSpeed,
                        max: AccessibilitySettingsService.maxReadingSpeed,
                        value: _a11y.readingSpeed,
                        onChanged: _a11y.setReadingSpeed,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SettingSectionCard(
                    title: l10n.t('settings.interactionComfort'),
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.t('settings.reducedMotion')),
                        subtitle: Text(l10n.t('settings.reducedMotionHelp')),
                        value: _a11y.reducedMotion,
                        onChanged: _a11y.setReducedMotion,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.t('settings.simplifiedUi')),
                        subtitle: Text(l10n.t('settings.simplifiedUiHelp')),
                        value: _a11y.simplifiedInterface,
                        onChanged: _a11y.setSimplifiedInterface,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.t('settings.captions')),
                        subtitle: Text(l10n.t('settings.captionsHelp')),
                        value: _a11y.captionsEnabled,
                        onChanged: _a11y.setCaptionsEnabled,
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.t('settings.hapticIntensity')),
                        subtitle: Text(l10n.t('settings.hapticHelp')),
                        trailing: DropdownButton<HapticIntensity>(
                          value: _a11y.hapticIntensity,
                          onChanged: (value) {
                            if (value != null) {
                              _onHapticIntensityChanged(value);
                            }
                          },
                          items: [
                            DropdownMenuItem(
                              value: HapticIntensity.off,
                              child: Text(l10n.t('settings.hapticOff')),
                            ),
                            DropdownMenuItem(
                              value: HapticIntensity.light,
                              child: Text(l10n.t('settings.hapticLight')),
                            ),
                            DropdownMenuItem(
                              value: HapticIntensity.medium,
                              child: Text(l10n.t('settings.hapticMedium')),
                            ),
                            DropdownMenuItem(
                              value: HapticIntensity.strong,
                              child: Text(l10n.t('settings.hapticStrong')),
                            ),
                          ],
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.t('settings.reducedInterruptions')),
                        subtitle: Text(
                          l10n.t('settings.reducedInterruptionsHelp'),
                        ),
                        value: _a11y.reducedInterruptions,
                        onChanged: _a11y.setReducedInterruptions,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SettingSectionCard(
                    title: l10n.t('settings.preview'),
                    children: [
                      Text(
                        l10n.t('settings.previewText'),
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _resetA11yDefaults,
                              icon: const Icon(Icons.restore),
                              label: Text(l10n.t('settings.reset')),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _SettingSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingSectionCard({required this.title, required this.children});

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
              Expanded(child: Text(label)),
              Text(valueLabel, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          Slider(min: min, max: max, value: value, onChanged: onChanged),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(helpText, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
