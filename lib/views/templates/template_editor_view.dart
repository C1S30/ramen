import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/di/injection.dart';
import '../../controllers/template_controller.dart';
import '../../services/template_engine_service.dart';
import 'widgets/template_card.dart';

class YtDlpChipOption {
  final String flag;
  final String label;
  final String description;

  const YtDlpChipOption({
    required this.flag,
    required this.label,
    required this.description,
  });
}

class YtDlpCategory {
  final String title;
  final IconData icon;
  final List<YtDlpChipOption> options;

  const YtDlpCategory({
    required this.title,
    required this.icon,
    required this.options,
  });
}

class TemplateEditorView extends StatefulWidget {
  const TemplateEditorView({super.key});

  @override
  State<TemplateEditorView> createState() => _TemplateEditorViewState();
}

class _TemplateEditorViewState extends State<TemplateEditorView>
    with SingleTickerProviderStateMixin {
  final TemplateEngineService _engineService = getIt<TemplateEngineService>();

  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _customFlagsController = TextEditingController();
  final Set<String> _selectedFlags = {};

  static const List<YtDlpCategory> _categories = [
    YtDlpCategory(
      title: 'NETWORK & SPEED',
      icon: Icons.speed_rounded,
      options: [
        YtDlpChipOption(
          flag: '-N 8',
          label: '-N 8',
          description: '8 parallel fragments',
        ),
        YtDlpChipOption(
          flag: '-N 16',
          label: '-N 16',
          description: '16 high-speed fragments',
        ),
        YtDlpChipOption(
          flag: '--limit-rate 5M',
          label: '--limit-rate 5M',
          description: '5 MB/s bandwidth throttle',
        ),
        YtDlpChipOption(
          flag: '--limit-rate 10M',
          label: '--limit-rate 10M',
          description: '10 MB/s speed throttle',
        ),
        YtDlpChipOption(
          flag: '--retries 10',
          label: '--retries 10',
          description: '10 retry attempts on error',
        ),
        YtDlpChipOption(
          flag: '--socket-timeout 30',
          label: '--socket-timeout 30',
          description: '30s connection timeout',
        ),
        YtDlpChipOption(
          flag: '--force-ipv4',
          label: '--force-ipv4',
          description: 'Enforce IPv4 sockets',
        ),
      ],
    ),
    YtDlpCategory(
      title: 'DOWNLOADER ENGINE',
      icon: Icons.memory_rounded,
      options: [
        YtDlpChipOption(
          flag: '--downloader aria2c',
          label: '--downloader aria2c',
          description: 'Multi-connection aria2c',
        ),
        YtDlpChipOption(
          flag: '--no-part',
          label: '--no-part',
          description: 'Write directly to file',
        ),
        YtDlpChipOption(
          flag: '--no-continue',
          label: '--no-continue',
          description: 'Do not resume partials',
        ),
      ],
    ),
    YtDlpCategory(
      title: 'FORMAT & CONTAINER',
      icon: Icons.video_file_outlined,
      options: [
        YtDlpChipOption(
          flag: '--merge-output-format mp4',
          label: '--merge-output-format mp4',
          description: 'Lossless MP4 muxing',
        ),
        YtDlpChipOption(
          flag: '--merge-output-format mkv',
          label: '--merge-output-format mkv',
          description: 'Universal MKV container',
        ),
        YtDlpChipOption(
          flag: '--prefer-free-formats',
          label: '--prefer-free-formats',
          description: 'Prefer WebM and Opus',
        ),
        YtDlpChipOption(
          flag: '--recode-video mp4',
          label: '--recode-video mp4',
          description: 'Re-encode into MP4',
        ),
        YtDlpChipOption(
          flag: '--no-playlist',
          label: '--no-playlist',
          description: 'Single media entry only',
        ),
        YtDlpChipOption(
          flag: '--yes-playlist',
          label: '--yes-playlist',
          description: 'Download full playlist',
        ),
      ],
    ),
    YtDlpCategory(
      title: 'AUDIO EXTRACTION',
      icon: Icons.audiotrack_rounded,
      options: [
        YtDlpChipOption(
          flag: '-x',
          label: '-x (Extract Audio)',
          description: 'Extract audio stream',
        ),
        YtDlpChipOption(
          flag: '--audio-format mp3',
          label: '--audio-format mp3',
          description: 'Encode audio to MP3',
        ),
        YtDlpChipOption(
          flag: '--audio-format m4a',
          label: '--audio-format m4a',
          description: 'Clean AAC audio stream',
        ),
        YtDlpChipOption(
          flag: '--audio-format flac',
          label: '--audio-format flac',
          description: 'Lossless studio FLAC',
        ),
        YtDlpChipOption(
          flag: '--audio-format opus',
          label: '--audio-format opus',
          description: 'Modern Opus codec',
        ),
        YtDlpChipOption(
          flag: '--audio-quality 0',
          label: '--audio-quality 0',
          description: 'Best VBR quality',
        ),
        YtDlpChipOption(
          flag: '--audio-quality 320k',
          label: '--audio-quality 320k',
          description: '320 kbps constant bitrate',
        ),
      ],
    ),
    YtDlpCategory(
      title: 'SUBTITLES & CAPTIONS',
      icon: Icons.subtitles_rounded,
      options: [
        YtDlpChipOption(
          flag: '--embed-subs',
          label: '--embed-subs',
          description: 'Embed subs into media file',
        ),
        YtDlpChipOption(
          flag: '--write-subs',
          label: '--write-subs',
          description: 'Download subtitle file',
        ),
        YtDlpChipOption(
          flag: '--write-auto-subs',
          label: '--write-auto-subs',
          description: 'YouTube auto-generated subs',
        ),
        YtDlpChipOption(
          flag: '--sub-langs en.*',
          label: '--sub-langs en.*',
          description: 'English subtitle tracks',
        ),
        YtDlpChipOption(
          flag: '--sub-langs all',
          label: '--sub-langs all',
          description: 'All language subtitles',
        ),
        YtDlpChipOption(
          flag: '--convert-subs srt',
          label: '--convert-subs srt',
          description: 'Convert subtitle to SRT',
        ),
      ],
    ),
    YtDlpCategory(
      title: 'METADATA & ARTWORK',
      icon: Icons.art_track_rounded,
      options: [
        YtDlpChipOption(
          flag: '--embed-thumbnail',
          label: '--embed-thumbnail',
          description: 'Attach cover thumbnail art',
        ),
        YtDlpChipOption(
          flag: '--embed-metadata',
          label: '--embed-metadata',
          description: 'Tag artist, title & year',
        ),
        YtDlpChipOption(
          flag: '--embed-chapters',
          label: '--embed-chapters',
          description: 'Write video chapter markers',
        ),
        YtDlpChipOption(
          flag: '--write-thumbnail',
          label: '--write-thumbnail',
          description: 'Export cover thumbnail file',
        ),
      ],
    ),
    YtDlpCategory(
      title: 'SPONSORBLOCK & CLEANING',
      icon: Icons.content_cut_rounded,
      options: [
        YtDlpChipOption(
          flag: '--sponsorblock-remove sponsor',
          label: '--sponsorblock-remove sponsor',
          description: 'Remove sponsor segments',
        ),
        YtDlpChipOption(
          flag: '--sponsorblock-remove sponsor,intro,outro',
          label: '--sponsorblock-remove sponsor,intro,outro',
          description: 'Remove sponsor, intro, outro',
        ),
        YtDlpChipOption(
          flag: '--sponsorblock-mark all',
          label: '--sponsorblock-mark all',
          description: 'Mark sponsor chapters only',
        ),
      ],
    ),
    YtDlpCategory(
      title: 'BYPASS & WORKAROUNDS',
      icon: Icons.shield_outlined,
      options: [
        YtDlpChipOption(
          flag: '--geo-bypass',
          label: '--geo-bypass',
          description: 'Bypass geographic restrictions',
        ),
        YtDlpChipOption(
          flag: '--no-check-certificates',
          label: '--no-check-certificates',
          description: 'Skip SSL certificate validation',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _customFlagsController.dispose();
    super.dispose();
  }

  void _toggleFlag(String flag) {
    setState(() {
      if (_selectedFlags.contains(flag)) {
        _selectedFlags.remove(flag);
      } else {
        _selectedFlags.add(flag);
      }
    });
  }

  String _buildCompleteCommandLine() {
    final flags = <String>[..._selectedFlags];
    final extra = _customFlagsController.text.trim();
    if (extra.isNotEmpty) {
      flags.add(extra);
    }
    if (flags.isEmpty) {
      return 'yt-dlp [Select options below]';
    }
    return 'yt-dlp ${flags.join(' ')}';
  }

  void _saveTemplate(TemplateController controller) {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a template name',
            style: AppStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final rawFlags = <String>[..._selectedFlags];
    final extra = _customFlagsController.text.trim();
    if (extra.isNotEmpty) {
      rawFlags.addAll(_engineService.parseFlagsFromString(extra));
    }

    if (rawFlags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select at least one yt-dlp option chip',
            style: AppStyles.bodyMedium.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Tokenize all selected flags to ensure clean CLI execution
    final tokenized = _engineService.parseFlagsFromString(rawFlags.join(' '));

    controller.saveCustomTemplate(
      name: name,
      description: desc.isNotEmpty ? desc : 'Custom CLI template',
      flags: tokenized,
    );

    // Reset builder form
    setState(() {
      _nameController.clear();
      _descController.clear();
      _customFlagsController.clear();
      _selectedFlags.clear();
    });

    // Switch to Saved Templates tab
    _tabController.animateTo(0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Template "$name" created successfully',
          style: AppStyles.bodyMedium.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templateCtrl = context.watch<TemplateController>();
    final templates = templateCtrl.templates;
    final activeId = templateCtrl.selectedTemplate.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'CLI TEMPLATES',
          style: AppStyles.monoHeadline.copyWith(
            fontSize: 18,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              indicatorWeight: 2.5,
              labelColor: AppColors.accentBright,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppStyles.monoSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              tabs: [
                Tab(text: 'SAVED TEMPLATES (${templates.length})'),
                const Tab(text: '+ CREATE TEMPLATE'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Saved Templates List
          _buildSavedTemplatesList(templateCtrl, templates, activeId),

          // TAB 2: Categorized Chip Template Builder
          _buildCustomTemplateBuilder(templateCtrl),
        ],
      ),
    );
  }

  Widget _buildSavedTemplatesList(
    TemplateController templateCtrl,
    List<dynamic> templates,
    String activeId,
  ) {
    if (templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.tune_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text('No templates available', style: AppStyles.bodyLarge),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              onPressed: () => _tabController.animateTo(1),
              child: const Text('Create First Template'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: templates.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final template = templates[index];
        final isSelected = template.id == activeId;

        return TemplateCard(
          template: template,
          isSelected: isSelected,
          onSelect: () => templateCtrl.selectTemplate(template),
          onDelete: template.isBuiltIn
              ? null
              : () => templateCtrl.deleteTemplate(template.id),
        );
      },
    );
  }

  Widget _buildCustomTemplateBuilder(TemplateController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header description
          Text(
            'DESIGN CUSTOM TEMPLATE',
            style: AppStyles.caption.copyWith(letterSpacing: 1.0),
          ),
          const SizedBox(height: 6),
          Text(
            'Select yt-dlp arguments as chips across categories to assemble a reusable preset.',
            style: AppStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Template Name input
          TextField(
            controller: _nameController,
            style: AppStyles.bodyLarge,
            decoration: InputDecoration(
              labelText: 'Template Name *',
              labelStyle: AppStyles.caption,
              hintText: 'e.g. 1080p High Speed MP4',
              hintStyle: AppStyles.monoSmall.copyWith(
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Template Description input
          TextField(
            controller: _descController,
            style: AppStyles.bodyLarge,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              labelStyle: AppStyles.caption,
              hintText:
                  'e.g. 16 fragments with auto-embed metadata and MP4 output',
              hintStyle: AppStyles.monoSmall.copyWith(
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Live CLI Command Preview Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accentBright,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'LIVE CLI PREVIEW',
                          style: AppStyles.monoSmall.copyWith(
                            fontSize: 11,
                            color: AppColors.accentBright,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_selectedFlags.length} flags selected',
                      style: AppStyles.caption.copyWith(fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  _buildCompleteCommandLine(),
                  style: AppStyles.monoSmall.copyWith(
                    color: _selectedFlags.isEmpty
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Categorized Option Chips
          ..._categories.map((category) => _buildCategorySection(category)),

          const SizedBox(height: 12),

          // Custom Extra Flags Input
          TextField(
            controller: _customFlagsController,
            style: AppStyles.monoSmall.copyWith(color: AppColors.textPrimary),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Additional Custom Flags (Optional)',
              labelStyle: AppStyles.caption,
              hintText: 'e.g. --referer https://site.com --no-mtime',
              hintStyle: AppStyles.monoSmall.copyWith(
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save & Reset Action Buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () => _saveTemplate(controller),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'SAVE TEMPLATE',
                          style: AppStyles.monoHeadline.copyWith(
                            color: Colors.white,
                            fontSize: 13,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedFlags.clear();
                        _customFlagsController.clear();
                      });
                    },
                    child: Text('Reset', style: AppStyles.monoSmall),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCategorySection(YtDlpCategory category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header
          Row(
            children: [
              Icon(category.icon, size: 16, color: AppColors.accentBright),
              const SizedBox(width: 8),
              Text(
                category.title,
                style: AppStyles.monoSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.8,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Chips Wrap
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: category.options.map((option) {
              final isSelected = _selectedFlags.contains(option.flag);

              return Tooltip(
                message: option.description,
                child: FilterChip(
                  label: Text(option.label),
                  labelStyle: AppStyles.monoSmall.copyWith(
                    fontSize: 11,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.accent,
                  backgroundColor: AppColors.chipBackground,
                  checkmarkColor: Colors.white,
                  showCheckmark: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.accentBright
                          : AppColors.border,
                      width: 1,
                    ),
                  ),
                  onSelected: (_) => _toggleFlag(option.flag),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
