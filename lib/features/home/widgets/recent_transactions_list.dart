import 'package:flutter/material.dart';
import '../../../../data/database/database_helper.dart';
import 'transaction_widgets.dart';

class RecentTransactionsList extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final String Function(String category, String? desc) getCleanTitle;
  final Future<void> Function() onRefresh;

  const RecentTransactionsList({
    super.key,
    required this.transactions,
    required this.getCleanTitle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Transactions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "View All",
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: transactions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Text("📭", style: TextStyle(fontSize: 32)),
                        SizedBox(height: 8),
                        Text(
                          "Abhi koi transaction nahi hai.",
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length > 5 ? 5 : transactions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 70, endIndent: 20),
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    final txId = tx['id'] as int;
                    final category = tx['category'] as String? ?? 'General';
                    final desc = tx['description'] as String? ?? '';
                    final title = getCleanTitle(category, desc);
                    final style = resolveCategoryStyle(category);

                    return Dismissible(
                      key: Key(txId.toString()),
                      direction: DismissDirection.horizontal,
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.endToStart) {
                          return await _confirmDelete(context, txId);
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
                        padding: const EdgeInsets.only(left: 24),
                      ),
                      secondaryBackground: _swipeBackground(
                        color: Colors.red[600]!,
                        icon: Icons.delete_outline,
                        label: "Delete",
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        reversed: true,
                      ),
                      child: AnimatedTransactionTile(
                        child: TransactionTile(
                          tx: tx,
                          title: title,
                          onTap: () => _openDetails(context, tx, title),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _openDetails(BuildContext context, Map<String, dynamic> tx, String title) {
    TransactionDetailSheet.show(
      context,
      tx: tx,
      title: title,
      onDelete: () => _confirmDeleteById(context, tx['id'] as int),
      onCategoryChanged: (_) => onRefresh(),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, int txId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Transaction?", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Kya aap sach me is transaction ko delete karna chahte hain?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteTransaction(txId);
      await onRefresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transaction deleted"), backgroundColor: Colors.redAccent),
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
      Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    ];

    return Container(
      color: color,
      alignment: alignment,
      padding: padding,
      child: Row(
        mainAxisAlignment: reversed ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: reversed ? children.reversed.toList() : children,
      ),
    );
  }
}
