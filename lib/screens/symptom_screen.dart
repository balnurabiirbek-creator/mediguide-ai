import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_localizations.dart';
import '../utils/app_constants.dart';
import '../services/health_services.dart';
import '../services/providers.dart';
import '../models/models.dart';
import '../widgets/common_widgets.dart';

class SymptomCheckerScreen extends StatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  State<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends State<SymptomCheckerScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<String> _selectedSymptoms = [];
  SymptomAnalysisResult? _result;
  bool _isAnalyzing = false;

  late final AnimationController _resultController;
  late final Animation<double> _resultFade;

  final List<String> _commonSymptoms = [
    'Headache',
    'Fever',
    'Cough',
    'Sore throat',
    'Fatigue',
    'Nausea',
    'Dizziness',
    'Runny nose',
    'Back pain',
    'Chest pain',
    'Shortness of breath',
    'Rash',
    'Vomiting',
    'Diarrhea',
    'Joint pain',
    'Eye pain',
  ];

  @override
  void initState() {
    super.initState();
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _resultFade = CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _resultController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _addSymptom(String symptom) {
    final s = AppLocalizations.canonicalSymptom(symptom).trim();
    if (s.isEmpty) return;

    if (!_selectedSymptoms.contains(s.toLowerCase())) {
      setState(() {
        _selectedSymptoms.add(s.toLowerCase());
        _result = null;
      });
      _controller.clear();
    }
  }

  void _removeSymptom(String symptom) {
    setState(() {
      _selectedSymptoms.remove(symptom);
      _result = null;
    });
  }

  Future<void> _analyze() async {
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('addAtLeastOneSymptom')),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _result = null;
    });

    await Future.delayed(const Duration(milliseconds: 2000));

    final result = SymptomService.analyzeSymptoms(_selectedSymptoms);

    if (mounted) {
      context.read<UserProvider>().addRecentActivity({
        'icon': '🔬',
        'title': context.tr('symptomChecker'),
        'subtitle': _selectedSymptoms.take(3).join(', '),
      });

      setState(() {
        _result = result;
        _isAnalyzing = false;
      });

      _resultController.forward(from: 0);
    }
  }

  Color get _severityColor {
    switch (_result?.severity) {
      case SeverityLevel.low:
        return AppColors.lowSeverity;
      case SeverityLevel.medium:
        return AppColors.mediumSeverity;
      case SeverityLevel.high:
        return AppColors.highSeverity;
      default:
        return AppColors.primary;
    }
  }

  String get _severityLabel {
    switch (_result?.severity) {
      case SeverityLevel.low:
        return 'Low';
      case SeverityLevel.medium:
        return 'Medium';
      case SeverityLevel.high:
        return 'High';
      default:
        return 'Unknown';
    }
  }

  String get _severityEmoji {
    switch (_result?.severity) {
      case SeverityLevel.low:
        return '🟢';
      case SeverityLevel.medium:
        return '🟡';
      case SeverityLevel.high:
        return '🔴';
      default:
        return '⚪';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('symptomChecker')),
        backgroundColor: AppColors.background,
        actions: [
          if (_result != null || _selectedSymptoms.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                setState(() {
                  _selectedSymptoms.clear();
                  _result = null;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientCard(
              child: Row(
                children: [
                  const Text(
                    '🤖',
                    style: TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('aiSymptomAnalysis'),
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          context.tr('symptomAnalysisSubtitle'),
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              context.tr('addSymptoms'),
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: context.tr('typeSymptom'),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textHint,
                      ),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _controller.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onFieldSubmitted: _addSymptom,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: AppDimensions.inputHeight,
                  width: AppDimensions.inputHeight,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => _addSymptom(_controller.text),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              context.tr('commonSymptoms'),
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonSymptoms.map((symptom) {
                final isSelected =
                    _selectedSymptoms.contains(symptom.toLowerCase());

                return TagChip(
                  label: context.symptomLabel(symptom),
                  isSelected: isSelected,
                  onTap: () => isSelected
                      ? _removeSymptom(symptom.toLowerCase())
                      : _addSymptom(symptom),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            if (_selectedSymptoms.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr(
                      'selected',
                      params: {'count': '${_selectedSymptoms.length}'},
                    ),
                    style: AppTextStyles.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedSymptoms.clear()),
                    child: Text(context.tr('clearAll')),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedSymptoms
                    .map(
                      (s) => TagChip(
                        label: context.symptomLabel(_capitalizeWords(s)),
                        isSelected: true,
                        onRemove: () => _removeSymptom(s),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
            ],

            PrimaryButton(
              label:
                  _isAnalyzing
                      ? context.tr('analyzing')
                      : context.tr('analyzeSymptoms'),
              onTap: _isAnalyzing ? null : _analyze,
              isLoading: _isAnalyzing,
              icon: _isAnalyzing ? null : Icons.biotech_rounded,
            ),

            if (_isAnalyzing) ...[
              const SizedBox(height: 32),
              _buildLoadingState(),
            ],

            if (_result != null) ...[
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _resultFade,
                child: _buildResults(),
              ),
            ],

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('⚠️'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr('medicalDisclaimer'),
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return AppCard(
      child: Column(
        children: [
          const SizedBox(height: 12),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('analyzingSymptomsTitle'),
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'aiProcessingCount',
              params: {'count': '${_selectedSymptoms.length}'},
            ),
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...[
            context.tr('matchingPatterns'),
            context.tr('evaluatingSeverity'),
            context.tr('generatingRecommendations'),
          ].map(
            (step) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    step,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final result = _result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _severityColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _severityColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Text(
                _severityEmoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${context.tr('severity')}: ',
                          style: AppTextStyles.headlineSmall.copyWith(
                            fontSize: 15,
                          ),
                        ),
                        SeverityBadge(
                          label: context.dynamicText(_severityLabel),
                          color: _severityColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.dynamicText(result.recommendation),
                      style: AppTextStyles.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        if (result.shouldSeeDoctor) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_hospital_rounded,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🏥 ${context.tr('consultDoctor')}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        Text(
          context.tr('possibleConditions'),
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: 12),

        ...result.possibleConditions.asMap().entries.map((entry) {
          final diagnosis = entry.value;
          return AnimatedListItem(
            index: entry.key,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            context.dynamicText(diagnosis.condition),
                            style: AppTextStyles.headlineSmall,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            context.tr(
                              'matchPercent',
                              params: {
                                'count': diagnosis.confidence.toStringAsFixed(0),
                              },
                            ),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.dynamicText(diagnosis.description),
                      style: AppTextStyles.bodyMedium,
                    ),
                    if (diagnosis.matchedSymptoms.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: diagnosis.matchedSymptoms
                            .map(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.divider,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  context.symptomLabel(_capitalizeWords(s)),
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: diagnosis.confidence / 100,
                        backgroundColor: AppColors.divider,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          diagnosis.confidence > 70
                              ? AppColors.primary
                              : diagnosis.confidence > 40
                                  ? AppColors.warning
                                  : AppColors.textHint,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        const SizedBox(height: 20),

        Text(
          context.tr('recommendedActions'),
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: 12),

        AppCard(
          child: Column(
            children: result.suggestedActions.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key < result.suggestedActions.length - 1
                      ? 12
                      : 0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        context.dynamicText(entry.value),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

String _capitalizeWords(String value) {
  return value
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map(
        (part) => part[0].toUpperCase() + part.substring(1).toLowerCase(),
      )
      .join(' ');
}
