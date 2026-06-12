import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/database/database_helper.dart';
import '../../home/widgets/transaction_widgets.dart';

class HistoryScreen extends StatefulWidget {
  final Future<void> Function() onRefreshParent;
  final String Function(String category, String? desc) getCleanTitle;

  const HistoryScreen({
    super.key,
    required this.onRefreshParent,
    required this.getCleanTitle,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isLoading = true;

  static const _categories = [
    'All',
    'Food & Groceries',
    'Fuel & Transport',
    'Bills & Recharges',
    'Shopping',
    'Medical & Health',
    'Kheti/Farming',
    'Cash (ATM)',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final txs = await DatabaseHelper.instance.getAllTransactions();
      setState(() {
        _allTransactions = txs;
        _applyFilters();
      });
    } catch (e) {
      debugPrint("❌ History fetch error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredTransactions = _allTransactions.where((tx) {
        final category = tx['category'] as String? ?? 'General';
        final desc = tx['description'] as String? ?? '';
        final amount = tx['amount']?.toString() ?? '';
        final title = widget.getCleanTitle(category, desc).toLowerCase();

        final matchesCategory =
            _selectedCategory == 'All' || category == _selectedCategory;
        final matchesSearch =
            query.isEmpty ||
            title.contains(query) ||
            desc.toLowerCase().contains(query) ||
            amount.contains(query);

        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate(
    List<Map<String, dynamic>> txs,
  ) {
    final Map<String, List<Map<String, dynamic>>> groups = {};
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr = DateFormat(
      'yyyy-MM-dd',
    ).format(now.subtract(const Duration(days: 1)));

    for (final tx in txs) {
      final dateStr = tx['date'] as String? ?? '';
      if (dateStr.isEmpty) continue;
      try {
        final parsed = DateTime.parse(dateStr);
        final dayStr = DateFormat('yyyy-MM-dd').format(parsed);

        String groupTitle;
        if (dayStr == todayStr) {
          groupTitle = "Today";
        } else if (dayStr == yesterdayStr) {
          groupTitle = "Yesterday";
        } else {
          groupTitle = DateFormat('dd MMMM yyyy').format(parsed);
        }

        if (!groups.containsKey(groupTitle)) {
          groups[groupTitle] = [];
        }
        groups[groupTitle]!.add(tx);
      } catch (_) {
        const groupTitle = "Other";
        if (!groups.containsKey(groupTitle)) {
          groups[groupTitle] = [];
        }
        groups[groupTitle]!.add(tx);
      }
    }
    return groups;
  }

  void _openDetails(
    BuildContext context,
    Map<String, dynamic> tx,
    String title,
  ) {
    TransactionDetailSheet.show(
      context,
      tx: tx,
      title: title,
      onDelete: () => _confirmDeleteById(context, tx['id'] as int),
      onCategoryChanged: (_) async {
        await _loadTransactions();
        await widget.onRefreshParent();
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context, int txId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Delete Transaction?",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Kya aap sach me is transaction ko delete karna chahte hain?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteTransaction(txId);
      await _loadTransactions();
      await widget.onRefreshParent();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Transaction deleted"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return true;
    }
    return false;
  }

  Future<void> _confirmDeleteById(BuildContext context, int txId) async {
    await _confirmDelete(context, txId);
  }

  Widget _swipeBackground({
    required Color color,
    required IconData icon,
    required String label,
    required Alignment alignment,
    required EdgeInsets padding,
    bool reversed = false,
  }) {
    final children = [
      Icon(icon, color: Colors.white, size: 24),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ];

    return Container(
      color: color,
      alignment: alignment,
      padding: padding,
      child: Row(
        mainAxisAlignment: reversed
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: reversed ? children.reversed.toList() : children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedTransactions = _groupTransactionsByDate(_filteredTransactions);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          "Transaction History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar & Filter Chips Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search by merchant, amount or info...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor:
                      Theme.of(context).inputDecorationTheme.fillColor ??
                      Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => _applyFilters(),
              ),
            ),

            // Category filter chips
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: Theme.of(
                          context,
                        ).chipTheme.selectedColor,
                        backgroundColor: Theme.of(
                          context,
                        ).chipTheme.backgroundColor,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white10
                                      : Colors.grey[200]!),
                          ),
                        ),
                        showCheckmark: false,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = cat;
                              _applyFilters();
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            // List of Transactions
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : _filteredTransactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("📭", style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isNotEmpty ||
                                    _selectedCategory != 'All'
                                ? "Koi matching transactions nahi mile."
                                : "Abhi koi transactions nahi hain.",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTransactions,
                      color: Theme.of(context).colorScheme.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        itemCount: groupedTransactions.keys.length,
                        itemBuilder: (context, groupIndex) {
                          final groupDate = groupedTransactions.keys.elementAt(
                            groupIndex,
                          );
                          final txList = groupedTransactions[groupDate]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 8,
                                  top: 16,
                                  bottom: 8,
                                ),
                                child: Text(
                                  groupDate,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Card(
                                elevation: 0,
                                margin: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                color: Theme.of(context).cardTheme.color,
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: txList.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 1,
                                    indent: 70,
                                    endIndent: 20,
                                  ),
                                  itemBuilder: (context, index) {
                                    final tx = txList[index];
                                    final txId = tx['id'] as int;
                                    final category =
                                        tx['category'] as String? ?? 'General';
                                    final desc =
                                        tx['description'] as String? ?? '';
                                    final title = widget.getCleanTitle(
                                      category,
                                      desc,
                                    );

                                    return Dismissible(
                                      key: Key('history_${txId}_$groupDate'),
                                      direction: DismissDirection.horizontal,
                                      confirmDismiss: (direction) async {
                                        if (direction ==
                                            DismissDirection.endToStart) {
                                          return await _confirmDelete(
                                            context,
                                            txId,
                                          );
                                        } else {
                                          _openDetails(context, tx, title);
                                          return false;
                                        }
                                      },
                                      background: _swipeBackground(
                                        color: Colors.blue[600]!,
                                        icon: Icons.edit,
                                        label: "Edit Details",
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.only(
                                          left: 24,
                                        ),
                                      ),
                                      secondaryBackground: _swipeBackground(
                                        color: Colors.red[600]!,
                                        icon: Icons.delete_outline,
                                        label: "Delete",
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(
                                          right: 24,
                                        ),
                                        reversed: true,
                                      ),
                                      child: TransactionTile(
                                        tx: tx,
                                        title: title,
                                        onTap: () =>
                                            _openDetails(context, tx, title),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
