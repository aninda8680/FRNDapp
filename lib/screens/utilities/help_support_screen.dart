import 'package:flutter/material.dart';
import '../../widgets/sketchy_container.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _allFaqs = [
    {
      'category': 'Refunds',
      'question': 'How does the 24-hour refund policy work?',
      'answer': 'We honor an unconditional 24-hour refund window starting from your purchase timestamp. Request a refund via app settings or support, and Razorpay will process a 100% reversal to your original payment method within 5–7 business days.',
    },
    {
      'category': 'Subscriptions',
      'question': 'How do I cancel my Silver or Gold Pass Autopay subscription?',
      'answer': 'Go to Profile Settings > Manage Subscription > Cancel Autopay. Razorpay immediately cancels future recurring charges. Your pass benefits remain active until the end of your 30-day billing cycle.',
    },
    {
      'category': 'Subscriptions',
      'question': 'What happens when I cancel Autopay mid-cycle?',
      'answer': 'Your pass benefits stay active until 11:59 PM on Day 30. Canceling Autopay simply ensures your UPI or card will not be debited for the subsequent monthly cycle.',
    },
    {
      'category': 'Verification',
      'question': 'How does student identity verification work?',
      'answer': 'All accounts require registration with an active university institutional email address (.edu / campus domain) verified via a live OTP code challenge.',
    },
    {
      'category': 'Safety',
      'question': 'How do I report harassment or suspicious accounts?',
      'answer': 'Tap the report/flag icon on any user profile or chat conversation. Reports are reviewed by our moderation team within 24 hours. Serious violations lead to immediate account termination.',
    },
    {
      'category': 'Safety',
      'question': 'What safety guidelines should I follow for offline campus meetups?',
      'answer': 'Always meet in public, well-lit campus areas. Never share private residence hall codes or financial details, and inform friends of your meetup schedule.',
    },
    {
      'category': 'Account',
      'question': 'Can non-students or general public join FRND Campus?',
      'answer': 'No. FRND Campus is strictly an exclusive, verified university community. Non-students, bots, and commercial advertisers are strictly prohibited and subject to hardware ban.',
    },
  ];

  List<Map<String, String>> get _filteredFaqs {
    return _allFaqs.where((faq) {
      final matchesCategory = _selectedCategory == 'All' || faq['category'] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          faq['question']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', 'Refunds', 'Subscriptions', 'Verification', 'Safety', 'Account'];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF4E5), // Cream background
      appBar: AppBar(
        title: const Text(
          'HELP & FAQ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
            letterSpacing: 1.8,
          ),
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
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFA41534).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.help_center_rounded,
                        color: Color(0xFFA41534),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Frequently Asked Questions',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Find quick answers & support guidelines',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Search queries, refunds, rules...',
                    hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
                    prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFFA41534)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFA41534), width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E2E2)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Category Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: FilterChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF333333),
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: const Color(0xFFA41534),
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFFA41534) : const Color(0xFFDCDCDC),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // FAQ Accordions List
                if (_filteredFaqs.isEmpty) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Column(
                        children: [
                          Icon(Icons.search_off_rounded, size: 40, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'No questions match "$_searchQuery"',
                            style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  ..._filteredFaqs.map((faq) => _FaqAccordionItem(
                        question: faq['question']!,
                        answer: faq['answer']!,
                        category: faq['category']!,
                      )),
                ],

                const SizedBox(height: 20),
                const Divider(height: 24, thickness: 1, color: Color(0x1F000000)),

                // Still Have Questions Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E2E2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA41534).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.support_agent_rounded, color: Color(0xFFA41534), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Still need assistance?',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.black),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Contact support desk at support@frndapp.edu',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey[700]),
                            ),
                          ],
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

  const _FaqAccordionItem({
    required this.question,
    required this.answer,
    required this.category,
  });

  @override
  State<_FaqAccordionItem> createState() => _FaqAccordionItemState();
}

class _FaqAccordionItemState extends State<_FaqAccordionItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: _isExpanded ? const Color(0xFFFAF0E6) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isExpanded ? const Color(0xFFA41534) : const Color(0xFFE2E2E2),
          width: _isExpanded ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
            childrenPadding: const EdgeInsets.only(left: 12.0, right: 12.0, bottom: 12.0),
            iconColor: const Color(0xFFA41534),
            collapsedIconColor: Colors.black54,
            onExpansionChanged: (expanded) {
              setState(() {
                _isExpanded = expanded;
              });
            },
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2.0, right: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFA41534).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFA41534),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.question,
                    style: TextStyle(
                      fontSize: 12.8,
                      fontWeight: FontWeight.w700,
                      color: _isExpanded ? const Color(0xFFA41534) : const Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.answer,
                  style: const TextStyle(
                    fontSize: 12.0,
                    height: 1.5,
                    color: Color(0xFF444444),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
