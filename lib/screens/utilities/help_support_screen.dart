import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/sketchy_container.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String _selectedCategory = 'All';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.grid_view_rounded},
    {'name': 'Refunds', 'icon': Icons.currency_rupee_rounded},
    {'name': 'Subscriptions', 'icon': Icons.stars_rounded},
    {'name': 'Verification', 'icon': Icons.verified_user_rounded},
    {'name': 'Safety', 'icon': Icons.shield_rounded},
    {'name': 'Account', 'icon': Icons.account_circle_rounded},
  ];

  final List<Map<String, String>> _allFaqs = [
    {
      'category': 'Refunds',
      'question': 'How does the 24-hour refund policy work?',
      'answer':
          'All premium subscriptions are billed via Google Play Billing. To request a refund for a recent purchase, visit play.google.com/store/account/subscriptions or contact our support team. Refund eligibility is governed by Google Play\'s refund policy.',
    },
    {
      'category': 'Subscriptions',
      'question': 'How do I cancel my Silver or Gold Pass Autopay subscription?',
      'answer':
          'Open the Google Play Store → Menu → Subscriptions → select FRND Buzz → tap Cancel Subscription. Google Play immediately stops future renewal charges. Your pass benefits remain active until the end of your current 28-day billing cycle.',
    },
    {
      'category': 'Subscriptions',
      'question': 'What happens when I cancel mid-cycle?',
      'answer':
          'Your pass benefits stay active until the end of your current 28-day billing period. Cancelling via Google Play simply stops the next auto-renewal charge.',
    },
    {
      'category': 'Verification',
      'question': 'How does student identity verification work?',
      'answer':
          'All accounts require registration with an active university institutional email address (.edu / campus domain) verified via a live OTP code challenge.',
    },
    {
      'category': 'Safety',
      'question': 'How do I report harassment or suspicious accounts?',
      'answer':
          'Tap the report/flag icon on any user profile or chat conversation. Reports are reviewed by our moderation team within 24 hours. Serious violations lead to immediate account termination.',
    },
    {
      'category': 'Safety',
      'question': 'What safety guidelines should I follow for offline campus meetups?',
      'answer':
          'Always meet in public, well-lit campus areas. Never share private residence hall codes or financial details, and inform friends of your meetup schedule.',
    },
    {
      'category': 'Account',
      'question': 'Can non-students or general public join FRND Campus?',
      'answer':
          'No. FRND Campus is strictly an exclusive, verified university community. Non-students, bots, and commercial advertisers are strictly prohibited and subject to hardware ban.',
    },
  ];

  List<Map<String, String>> get _filteredFaqs {
    return _allFaqs.where((faq) {
      return _selectedCategory == 'All' || faq['category'] == _selectedCategory;
    }).toList();
  }

  int _getCategoryCount(String category) {
    if (category == 'All') return _allFaqs.length;
    return _allFaqs.where((faq) => faq['category'] == category).length;
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(
              '$label copied to clipboard!',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
        backgroundColor: AppColors.textColor2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildFaqList() {
    if (_filteredFaqs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.textColor2.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 36,
                color: AppColors.textColor2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No matching questions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.inkBlack,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No FAQs available under $_selectedCategory.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'All';
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'Show All FAQs',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textColor2,
                side: const BorderSide(color: AppColors.textColor2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Grouping by category when 'All' is selected
    if (_selectedCategory == 'All') {
      final Map<String, List<Map<String, String>>> groupedFaqs = {};
      for (var faq in _filteredFaqs) {
        final cat = faq['category']!;
        groupedFaqs.putIfAbsent(cat, () => []).add(faq);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: groupedFaqs.entries.map((entry) {
          final catName = entry.key;
          final faqs = entry.value;
          final catIcon = _categories.firstWhere(
            (c) => c['name'] == catName,
            orElse: () => {'icon': Icons.help_outline_rounded},
          )['icon'] as IconData;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6.0, bottom: 8.0, left: 2.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.textColor2.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(catIcon, size: 13, color: AppColors.textColor2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      catName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textColor2,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.textColor2.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${faqs.length}',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textColor2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...faqs.map((faq) => _FaqAccordionItem(
                    key: ValueKey(faq['question']),
                    question: faq['question']!,
                    answer: faq['answer']!,
                    category: faq['category']!,
                    showCategoryTag: false,
                  )),
              const SizedBox(height: 10),
            ],
          );
        }).toList(),
      );
    }

    // Single selected category view
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _filteredFaqs.map((faq) => _FaqAccordionItem(
            key: ValueKey(faq['question']),
            question: faq['question']!,
            answer: faq['answer']!,
            category: faq['category']!,
            showCategoryTag: false,
          )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF4E5), // Cream background
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.textColor2.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.help_center_rounded,
                color: AppColors.textColor2,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'HELP & SUPPORT',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1A1A1A),
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(height: 1.0, color: const Color(0x121A1A1A)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: SketchyContainer(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Scroll Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _categories.map((catMap) {
                      final String catName = catMap['name'];
                      final IconData catIcon = catMap['icon'];
                      final bool isSelected = _selectedCategory == catName;
                      final int count = _getCategoryCount(catName);

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedCategory = catName;
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.textColor2
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.textColor2
                                      : const Color(0xFFE0E0E0),
                                  width: 1.2,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.textColor2.withValues(alpha: 0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    catIcon,
                                    size: 14,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey[700],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    catName,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.25)
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // Results Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory == 'All'
                          ? 'ALL FREQUENTLY ASKED QUESTIONS'
                          : 'TOPICS IN ${_selectedCategory.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[600],
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      '${_filteredFaqs.length} ${_filteredFaqs.length == 1 ? 'Result' : 'Results'}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textColor2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // FAQ Accordion List Section
                _buildFaqList(),

                const SizedBox(height: 16),
                const Divider(height: 24, thickness: 1, color: Color(0x1F000000)),

                // Still Need Help / Contact Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E2E2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.textColor2.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.support_agent_rounded,
                              color: AppColors.textColor2,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Still need assistance?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.inkBlack,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Our campus support team responds within 24 hours.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        onTap: () => _copyToClipboard('contact@frnd.buzz', 'Support Email'),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF4E1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.textColor2.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.mail_outline_rounded,
                                size: 18,
                                color: AppColors.textColor2,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'contact@frnd.buzz',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textColor2,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.textColor2,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.copy_rounded,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'COPY',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqAccordionItem extends StatefulWidget {
  final String question;
  final String answer;
  final String category;
  final bool showCategoryTag;

  const _FaqAccordionItem({
    super.key,
    required this.question,
    required this.answer,
    required this.category,
    this.showCategoryTag = true,
  });

  @override
  State<_FaqAccordionItem> createState() => _FaqAccordionItemState();
}

class _FaqAccordionItemState extends State<_FaqAccordionItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: _isExpanded ? const Color(0xFFFFFDF9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isExpanded ? AppColors.textColor2 : const Color(0xFFE2E2E2),
          width: _isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: _isExpanded
            ? [
                BoxShadow(
                  color: AppColors.textColor2.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.015),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.showCategoryTag) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.textColor2.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: AppColors.textColor2.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Text(
                                widget.category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textColor2,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                          ],
                          Text(
                            widget.question,
                            style: TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w700,
                              color: _isExpanded
                                  ? AppColors.textColor2
                                  : const Color(0xFF1A1A1A),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: _isExpanded
                              ? AppColors.textColor2.withValues(alpha: 0.1)
                              : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: _isExpanded
                              ? AppColors.textColor2
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity, height: 0),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(
                          height: 16,
                          thickness: 1,
                          color: Color(0x0F000000),
                        ),
                        Text(
                          widget.answer,
                          style: const TextStyle(
                            fontSize: 12.2,
                            height: 1.55,
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
