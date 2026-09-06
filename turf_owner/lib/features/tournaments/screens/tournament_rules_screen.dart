import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/tournament_model.dart';
import '../../../providers/tournament_provider.dart';

class TournamentRulesScreen extends StatefulWidget {
  final Tournament tournament;

  const TournamentRulesScreen({super.key, required this.tournament});

  @override
  State<TournamentRulesScreen> createState() => _TournamentRulesScreenState();
}

class _TournamentRulesScreenState extends State<TournamentRulesScreen> {
  late List<String> _rules;
  final TextEditingController _customRuleController = TextEditingController();
  bool _isSaving = false;

  final List<String> _suggestedRules = [
    '⏰ Teams must report at least 15 minutes before scheduled match time',
    '👟 Only rubber-soled turf shoes or flat trainers allowed (strictly no metal spikes)',
    '⚖️ The Referee / Umpire decision is final and binding on all parties',
    '🚫 Zero tolerance for foul language, unsporting behavior, or physical aggression',
    '📋 Valid photo ID is mandatory for player verification before kickoff',
    '🔄 Maximum of 2 rolling substitutions permitted per half',
    '🌧️ Weather or turf condition delays will be handled by venue officials',
    '⏱️ Matches consist of two equal halves with a 5-minute break',
    '⚠️ Teams arriving more than 10 minutes late will forfeit the fixture',
  ];

  @override
  void initState() {
    super.initState();
    _rules = List<String>.from(widget.tournament.rules);
  }

  @override
  void dispose() {
    _customRuleController.dispose();
    super.dispose();
  }

  void _addRule(String rule) {
    final trimmed = rule.trim();
    if (trimmed.isEmpty) return;
    if (_rules.contains(trimmed)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This rule is already added!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _rules.add(trimmed);
      _customRuleController.clear();
    });
  }

  void _removeRule(int index) {
    setState(() {
      _rules.removeAt(index);
    });
  }

  Future<void> _saveRules() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final provider = Provider.of<TournamentProvider>(context, listen: false);
      final success = await provider.updateTournament(widget.tournament.id, {
        'rules': _rules,
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tournament rules updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, _rules);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update tournament rules. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          '${widget.tournament.name.toUpperCase()} RULES',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tournament Header Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOURNAMENT GUIDELINES',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryColor,
                                  letterSpacing: 1,
                                ),
                              ),
                              Text(
                                'Set ground rules, dress codes & match conduct for all participating teams.',
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Suggested Rules
                  Text(
                    'SUGGESTED RULES (TAP TO ADD)',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _suggestedRules.map((suggestion) {
                      final isAdded = _rules.contains(suggestion);
                      return ActionChip(
                        onPressed: isAdded ? null : () => _addRule(suggestion),
                        backgroundColor: isAdded ? Colors.grey[100] : Colors.white,
                        side: BorderSide(
                          color: isAdded
                              ? Colors.grey.withOpacity(0.3)
                              : AppTheme.primaryColor.withOpacity(0.25),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAdded ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                              size: 14,
                              color: isAdded ? Colors.grey : AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                suggestion,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: isAdded ? Colors.grey[500] : Colors.grey[800],
                                  fontWeight: isAdded ? FontWeight.normal : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // Active Rules Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CONFIGURED RULES (${_rules.length})',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.textSecondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      if (_rules.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() => _rules.clear()),
                          child: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_rules.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.withOpacity(0.15)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.rule_folder_outlined, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            'No rules configured yet',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap suggestions above or enter custom rules below.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._rules.asMap().entries.map((entry) {
                      final index = entry.key;
                      final rule = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.12)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  rule,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF1A1A1A),
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _removeRule(index),
                            ),
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 20),

                  // Custom Rule Input Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customRuleController,
                            textCapitalization: TextCapitalization.sentences,
                            style: GoogleFonts.poppins(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Type custom rule and press add...',
                              hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onSubmitted: _addRule,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_rounded, color: AppTheme.primaryColor, size: 28),
                          onPressed: () => _addRule(_customRuleController.text),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveRules,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'SAVE TOURNAMENT RULES',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
