import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reader_settings.dart';
import '../providers/settings_provider.dart';
import '../theme/reader_colors.dart';
import '../widgets/setting_row.dart';
import 'color_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Widget _buildSection(String title, ThemeData theme, List<Widget> children) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
                letterSpacing: 1.2,
                fontSize: 11,
              ),
            ),
          ),
          Card(
            margin: EdgeInsets.zero,
            color: isDark ? const Color(0xFF0A0A0A) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: isDark ? 0.6 : 0.8),
                width: 0.8,
              ),
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: isDark ? 0.6 : 0.8),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _SettingsLivePreview(settings: settings),
          _buildSection(
            'Reading Profile',
            theme,
            [
              _WpmControl(
                value: settings.wordsPerMinute,
                onChanged: notifier.setWordsPerMinute,
              ),
            ],
          ),
          _buildSection(
            'Typography & Layout',
            theme,
            [
              SettingTile(
                title: 'Font family',
                subtitle: 'Choose reader font style',
                trailing: DropdownButton<ReaderFontType>(
                  value: settings.fontType,
                  underline: const SizedBox.shrink(),
                  icon: const Icon(Icons.arrow_drop_down),
                  onChanged: (v) =>
                      v == null ? null : notifier.setFontType(v),
                  items: const [
                    DropdownMenuItem(
                        value: ReaderFontType.system, child: Text('System')),
                    DropdownMenuItem(
                        value: ReaderFontType.serif, child: Text('Serif')),
                    DropdownMenuItem(
                        value: ReaderFontType.sans, child: Text('Sans')),
                    DropdownMenuItem(
                        value: ReaderFontType.monospace, child: Text('Mono')),
                  ],
                ),
              ),
              SettingTile(
                title: 'Font size',
                subtitle: 'Text size in RSVP panel: ${settings.fontSize.round()}px',
                below: Slider(
                  min: ReaderSettings.minFontSize,
                  max: ReaderSettings.maxFontSize,
                  divisions:
                      (ReaderSettings.maxFontSize - ReaderSettings.minFontSize)
                          .round(),
                  value: settings.fontSize,
                  label: settings.fontSize.round().toString(),
                  onChanged: notifier.setFontSize,
                ),
              ),
              SettingTile(
                title: 'Words per entry',
                subtitle: 'Flashing chunks at once',
                below: Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 1, label: Text('1')),
                      ButtonSegment(value: 2, label: Text('2')),
                      ButtonSegment(value: 3, label: Text('3')),
                      ButtonSegment(value: 4, label: Text('4')),
                      ButtonSegment(value: 5, label: Text('5')),
                    ],
                    selected: {settings.wordsPerEntry},
                    onSelectionChanged: (s) =>
                        notifier.setWordsPerEntry(s.first),
                  ),
                ),
              ),
            ],
          ),
          _buildSection(
            'Interface & Theme',
            theme,
            [
              SettingTile(
                title: 'Helper text',
                subtitle: 'Show full text panel below the reader',
                trailing: Switch(
                  value: settings.showHelperText,
                  onChanged: notifier.setShowHelperText,
                ),
              ),
              SettingTile(
                title: 'Theme Mode',
                subtitle: 'Global application theme',
                below: Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                          value: ThemeMode.system, label: Text('System')),
                      ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (s) => notifier.setThemeMode(s.first),
                  ),
                ),
              ),
              SettingTile(
                title: 'Reader colors',
                subtitle: 'Customize background and highlights',
                trailing: Icon(
                  Icons.chevron_right,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ColorSettingsScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// WPM control: slider + exact numeric input (spec §5A), kept in sync.
class _WpmControl extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _WpmControl({required this.value, required this.onChanged});

  @override
  State<_WpmControl> createState() => _WpmControlState();
}

class _WpmControlState extends State<_WpmControl> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value.toString());

  @override
  void didUpdateWidget(_WpmControl old) {
    super.didUpdateWidget(old);
    final text = widget.value.toString();
    if (_controller.text != text) _controller.text = text;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit(String raw) {
    final parsed = int.tryParse(raw);
    if (parsed == null) {
      _controller.text = widget.value.toString();
      return;
    }
    final clamped =
        parsed.clamp(ReaderSettings.minWpm, ReaderSettings.maxWpm);
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SettingTile(
      title: 'Reading speed',
      subtitle: 'Words per minute',
      trailing: SizedBox(
        width: 84,
        child: TextField(
          controller: _controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: isDark ? 0.6 : 0.8),
                width: 0.8,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.6),
                width: 0.8,
              ),
            ),
          ),
          onSubmitted: _commit,
          onEditingComplete: () => _commit(_controller.text),
        ),
      ),
      below: Slider(
        min: ReaderSettings.minWpm.toDouble(),
        max: ReaderSettings.maxWpm.toDouble(),
        divisions: ReaderSettings.maxWpm - ReaderSettings.minWpm,
        value: widget.value.toDouble(),
        label: '${widget.value} WPM',
        onChanged: (v) => widget.onChanged(v.round()),
      ),
    );
  }
}

class _SettingsLivePreview extends StatelessWidget {
  final ReaderSettings settings;
  const _SettingsLivePreview({required this.settings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final colors = ReaderColors.resolve(settings, scheme);
    final fontFamily = readerFontFamily(settings.fontType);

    final focusTextStyle = TextStyle(
      fontSize: settings.fontSize,
      fontWeight: FontWeight.w700,
      color: colors.currentWord,
      fontFamily: fontFamily,
    );

    final String prefixText;
    final String orpWordPrefix;
    final String orpLetter;
    final String orpWordSuffix;
    final String suffixText;

    switch (settings.wordsPerEntry) {
      case 1:
        prefixText = '';
        orpWordPrefix = 'Re';
        orpLetter = 'a';
        orpWordSuffix = 'der';
        suffixText = '';
      case 2:
        prefixText = 'Speed ';
        orpWordPrefix = 're';
        orpLetter = 'a';
        orpWordSuffix = 'der';
        suffixText = '';
      case 3:
        prefixText = 'Super ';
        orpWordPrefix = 're';
        orpLetter = 'a';
        orpWordSuffix = 'der';
        suffixText = ' app';
      case 4:
        prefixText = 'Our super ';
        orpWordPrefix = 're';
        orpLetter = 'a';
        orpWordSuffix = 'der';
        suffixText = ' app';
      case 5:
      default:
        prefixText = 'This is our ';
        orpWordPrefix = 're';
        orpLetter = 'a';
        orpWordSuffix = 'der';
        suffixText = ' app';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : scheme.outlineVariant.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Focus section preview
          Container(
            color: colors.focusBackground,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            width: double.infinity,
            alignment: Alignment.center,
            child: Column(
              children: [
                // Top guide line
                Container(
                  width: 160,
                  height: 1.5,
                  color: colors.guideLine,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: focusTextStyle,
                      children: [
                        if (prefixText.isNotEmpty)
                          TextSpan(text: prefixText),
                        TextSpan(text: orpWordPrefix),
                        TextSpan(
                          text: orpLetter,
                          style: focusTextStyle.copyWith(color: colors.centralLetter),
                        ),
                        TextSpan(text: orpWordSuffix),
                        if (suffixText.isNotEmpty)
                          TextSpan(text: suffixText),
                      ],
                    ),
                  ),
                ),
                // Bottom guide line
                Container(
                  width: 160,
                  height: 1.5,
                  color: colors.guideLine,
                ),
              ],
            ),
          ),
          // Helper section preview
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.fastOutSlowIn,
            child: settings.showHelperText
                ? Column(
                    children: [
                      const Divider(height: 1),
                      Container(
                        color: colors.background,
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              fontFamily: fontFamily,
                              color: colors.currentWord.withValues(alpha: 0.8),
                            ),
                            children: [
                              const TextSpan(text: 'This is a typography preview showing the '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: colors.helperHighlight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'helper panel',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.black : Colors.white,
                                      fontFamily: fontFamily,
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(text: ' when reading.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
