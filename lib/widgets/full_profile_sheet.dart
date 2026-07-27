import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

const _burgundy = Color(0xFFA41534);
const _bgCream = Color(0xFFFDF4E5);

class FullProfileSheet extends StatelessWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onClose;
  final VoidCallback? onLike;
  final VoidCallback? onPass;
  final VoidCallback? onSuperlike;

  const FullProfileSheet({
    super.key,
    required this.profile,
    required this.onClose,
    this.onLike,
    this.onPass,
    this.onSuperlike,
  });

  int get photoCount {
    final pics = profile['pictures'] as List<dynamic>?;
    return (pics != null && pics.isNotEmpty) ? pics.length : 1;
  }

  String _getPhoto(int photoIndex) {
    final pics = profile['pictures'] as List<dynamic>?;
    if (pics != null && pics.isNotEmpty) {
      final idx = photoIndex % pics.length;
      final item = pics[idx];
      if (item is Map) return item['url']?.toString() ?? '';
      if (item is String) return item;
    }
    // Fallback
    final id = profile['_id']?.toString() ?? '0';
    final fallbacks = [
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&q=80',
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800&q=80',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&q=80',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&q=80',
    ];
    return fallbacks[id.codeUnitAt(0) % fallbacks.length];
  }

  String _formatHeight(dynamic cm) {
    if (cm == null) return '';
    final c = (cm as num).toInt();
    final total = c / 2.54;
    final ft = total ~/ 12;
    final inch = (total % 12).round();
    return "$c cm ($ft'$inch\")";
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: const Color(0xFFFFF5E9),
        child: SafeArea(
          child: Column(
            children: [
              // Header bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5E9).withOpacity(0.97),
                  border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.08))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'STUDENT PROFILE',
                      style: TextStyle(
                        color: _burgundy,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, (onLike != null || onPass != null) ? 100 : 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo 1
                      _detailPhoto(_getPhoto(0)),

                      const SizedBox(height: 16),

                      // Name & vitals card
                      _detailCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${profile['name']}, ${profile['age'] ?? '18'}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF040404),
                                  ),
                                ),
                                if (profile['identityStatus'] == 'verified') ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.verified, color: _burgundy, size: 22),
                                ],
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (profile['height'] != null)
                                  _chip(
                                    _formatHeight(profile['height']),
                                    icon: Icons.straighten_rounded,
                                  ),
                                if (profile['sexualOrientation'] != null)
                                  _chip('${profile['sexualOrientation']}'),
                                if (profile['lookingFor'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: _burgundy,
                                      borderRadius: BorderRadius.circular(40),
                                    ),
                                    child: Text(
                                      (profile['lookingFor'] as String).toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Photo 2
                      if (photoCount > 1) ...[
                        const SizedBox(height: 16),
                        _detailPhoto(_getPhoto(1)),
                      ],

                      // School & Course
                      if (profile['school'] != null || profile['course'] != null) ...[
                        const SizedBox(height: 16),
                        _detailCard(
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _burgundy.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: _burgundy.withOpacity(0.3)),
                                ),
                                child: const Icon(Icons.school_rounded, color: _burgundy, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'UNIVERSITY & COURSE',
                                      style: TextStyle(color: _burgundy, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      profile['school'] ?? 'Campus Student',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF040404)),
                                    ),
                                    if (profile['course'] != null)
                                      Text(
                                        profile['course'],
                                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Photo 3
                      if (photoCount > 2) ...[
                        const SizedBox(height: 16),
                        _detailPhoto(_getPhoto(2)),
                      ],

                      // Bio
                      if (profile['bio'] != null && (profile['bio'] as String).isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _detailCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ABOUT ME',
                                style: TextStyle(color: _burgundy, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '"${profile['bio']}"',
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFF040404),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Hobbies & Skills
                      if ((profile['hobbies'] as List?)?.isNotEmpty == true ||
                          (profile['skills'] as List?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 16),
                        _detailCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'INTERESTS & HOBBIES',
                                style: TextStyle(color: _burgundy, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ...?(profile['hobbies'] as List?)?.map((h) => _hobbyChip(h.toString())),
                                  ...?(profile['skills'] as List?)?.map((s) => _hobbyChip(s.toString())),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Sticky bottom action buttons
              if (onLike != null || onPass != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    border: Border(top: BorderSide(color: Colors.black.withOpacity(0.08))),
                  ),
                  child: Row(
                    children: [
                      if (onPass != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onPass,
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('PASS'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              side: BorderSide(color: Colors.black.withOpacity(0.15)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11),
                            ),
                          ),
                        ),
                      if (onPass != null && onLike != null)
                        const SizedBox(width: 12),
                      if (onLike != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onLike,
                            icon: const Icon(Icons.favorite_rounded, size: 16),
                            label: const Text('LIKE'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _burgundy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                              textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11),
                              elevation: 4,
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
    );
  }

  Widget _detailPhoto(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.black.withOpacity(0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: url.isNotEmpty
            ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.person, size: 80, color: Colors.grey))
            : const Icon(Icons.person, size: 80, color: Colors.grey),
      ),
    );
  }

  Widget _detailCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _chip(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: _bgCream,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: _burgundy), const SizedBox(width: 4)],
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _hobbyChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _bgCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.label_outline_rounded, size: 13, color: _burgundy),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
