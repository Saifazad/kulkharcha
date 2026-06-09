import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../data/database/database_helper.dart';

/// Resolves category -> icon, bgColor, iconColor
({IconData icon, Color iconColor, Color bgColor}) resolveCategoryStyle(String category) {
  switch (category) {
    case 'Food & Groceries':
      return (icon: Icons.restaurant,       iconColor: Colors.orange, bgColor: const Color(0xFFFFF3E0));
    case 'Kheti/Farming':
      return (icon: Icons.agriculture,      iconColor: Colors.green,  bgColor: const Color(0xFFE8F5E9));
    case 'Bills & Recharges':
      return (icon: Icons.receipt_long,     iconColor: Colors.blue,   bgColor: const Color(0xFFE3F2FD));
    case 'Fuel & Transport':
      return (icon: Icons.local_gas_station,iconColor: Colors.pink,   bgColor: const Color(0xFFFCE4EC));
    case 'Shopping':
      return (icon: Icons.shopping_bag,     iconColor: Colors.purple, bgColor: const Color(0xFFF3E5F5));
    case 'Medical & Health':
      return (icon: Icons.medical_services, iconColor: Colors.red,    bgColor: const Color(0xFFFFEBEE));
    case 'Cash (ATM)':
      return (icon: Icons.local_atm,        iconColor: Colors.teal,   bgColor: const Color(0xFFE0F2F1));
    default:
      return (icon: Icons.payment,          iconColor: Colors.grey,   bgColor: const Color(0xFFF5F5F5));
  }
}

/// Relative time formatter
String getRelativeTime(String dateStr) {
  try {
    final parsedDate = DateTime.parse(dateStr);
    final now = DateTime.now();
    final diff = now.difference(parsedDate);
    final isToday = parsedDate.year == now.year &&
        parsedDate.month == now.month &&
        parsedDate.day == now.day;

    if (isToday) {
      if (diff.inSeconds < 60) return "Just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      return "${diff.inHours}h ago";
    } else {
      final yesterday = now.subtract(const Duration(days: 1));
      if (parsedDate.year == yesterday.year &&
          parsedDate.month == yesterday.month &&
          parsedDate.day == yesterday.day) {
        return "Yesterday";
      }
      return DateFormat('dd MMM yyyy').format(parsedDate);
    }
  } catch (_) {
    return dateStr;
  }
}

bool _isValidLocation(String? location) {
  if (location == null || location.isEmpty) return false;
  const invalid = {'Local', 'Location Disabled', 'Patna, Bihar'};
  return !invalid.contains(location);
}

// ─── Transaction Tile ────────────────────────────────────────────────────────

class TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  final String title;
  final VoidCallback onTap;

  const TransactionTile({
    super.key,
    required this.tx,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final category = tx['category'] as String? ?? 'General';
    final location = tx['location'] as String?;
    final amount = (tx['amount'] as num).toDouble();
    final dateStr = tx['date'] as String? ?? '';
    final style = resolveCategoryStyle(category);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: style.bgColor,
              radius: 20,
              child: Icon(style.icon, color: style.iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "-₹${amount.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        getRelativeTime(dateStr),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const Text("  •  ", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        category,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  if (_isValidLocation(location)) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 12),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              location!,
                              style: const TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animated wrapper ────────────────────────────────────────────────────────

class AnimatedTransactionTile extends StatefulWidget {
  final Widget child;
  const AnimatedTransactionTile({super.key, required this.child});

  @override
  State<AnimatedTransactionTile> createState() => _AnimatedTransactionTileState();
}

class _AnimatedTransactionTileState extends State<AnimatedTransactionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuad));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(opacity: _fade, child: widget.child),
    );
  }
}

// ─── Transaction Detail Bottom Sheet ─────────────────────────────────────────

class TransactionDetailSheet extends StatefulWidget {
  final Map<String, dynamic> tx;
  final String title;
  final Future<void> Function() onDelete;
  final Future<void> Function(String newCategory) onCategoryChanged;

  const TransactionDetailSheet({
    super.key,
    required this.tx,
    required this.title,
    required this.onDelete,
    required this.onCategoryChanged,
  });

  static void show(
    BuildContext context, {
    required Map<String, dynamic> tx,
    required String title,
    required Future<void> Function() onDelete,
    required Future<void> Function(String) onCategoryChanged,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionDetailSheet(
        tx: tx,
        title: title,
        onDelete: onDelete,
        onCategoryChanged: onCategoryChanged,
      ),
    );
  }

  @override
  State<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<TransactionDetailSheet> {
  static const _categories = [
    'Food & Groceries',
    'Fuel & Transport',
    'Bills & Recharges',
    'Shopping',
    'Medical & Health',
    'Kheti/Farming',
    'Cash (ATM)',
    'General',
  ];

  late String _currentCategory;

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.tx['category'] as String? ?? 'General';
  }

  @override
  Widget build(BuildContext context) {
    final amount   = (widget.tx['amount'] as num).toDouble();
    final dateStr  = widget.tx['date'] as String? ?? '';
    final desc     = widget.tx['description'] as String? ?? '';
    final location = widget.tx['location'] as String?;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 50, height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 24),

          // Title + amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "₹${amount.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat('dd MMMM yyyy, hh:mm a').format(DateTime.parse(dateStr)),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),

          // Category dropdown
          const Text("Category", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _currentCategory,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (newCat) async {
                  if (newCat != null && newCat != _currentCategory) {
                    await DatabaseHelper.instance.updateTransactionCategory(
                      widget.tx['id'] as int,
                      newCat,
                    );
                    setState(() => _currentCategory = newCat);
                    await widget.onCategoryChanged(newCat);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Location (if valid)
          if (_isValidLocation(location)) ...[
            const Text("Spent Location", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location!,
                          style: const TextStyle(color: Color(0xFF2E7D32), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const Text("Detected via SMS context location",
                            style: TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.map_outlined, color: Color(0xFF2E7D32)),
                    onPressed: () async {
                      final url = Uri.parse(
                          "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}");
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Raw SMS text
          const Text("Raw SMS Text", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
            child: Text(desc, style: TextStyle(color: Colors.grey[700], fontSize: 12, height: 1.4)),
          ),
          const SizedBox(height: 28),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await widget.onDelete();
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E20),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Done",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
