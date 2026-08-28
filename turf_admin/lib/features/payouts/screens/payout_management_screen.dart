import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../providers/admin_payout_provider.dart';
import '../../../core/theme/app_theme.dart';

class PayoutManagementScreen extends StatefulWidget {
  const PayoutManagementScreen({super.key});

  @override
  _PayoutManagementScreenState createState() => _PayoutManagementScreenState();
}

class _PayoutManagementScreenState extends State<PayoutManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminPayoutProvider>(context, listen: false).fetchAllPayouts();
    });
  }

  void _showActionDialog(Map<String, dynamic> payout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('PROCESS SETTLEMENT', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18)),
        content: Text(
          'Confirm status update for Rs. ${payout['amount']} requested by ${payout['ownerId']?['name'] ?? 'Owner'}?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await Provider.of<AdminPayoutProvider>(context, listen: false)
                  .updatePayoutStatus(payout['_id'], 'failed');
              Navigator.pop(context);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout marked as failed')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            child: const Text('FAIL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await Provider.of<AdminPayoutProvider>(context, listen: false)
                  .updatePayoutStatus(payout['_id'], 'processed');
              Navigator.pop(context);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout processed successfully')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            child: const Text('PROCESS'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Consumer<AdminPayoutProvider>(
        builder: (context, provider, child) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    children: [
                      _buildExecutiveHeader(provider),
                      const SizedBox(height: 32),
                      _buildFilterBar(provider),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (provider.isLoading && provider.allPayouts.isEmpty)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else if (provider.filteredPayouts.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payments_outlined, size: 64, color: AppTheme.primaryColor.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        Text('NO PAYOUT RECORDS FOUND', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 12, letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final payout = provider.filteredPayouts[index];
                        return _buildPayoutCard(payout);
                      },
                      childCount: provider.filteredPayouts.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: AppTheme.headerGreen,
      surfaceTintColor: AppTheme.headerGreen,
      iconTheme: const IconThemeData(color: Colors.white, size: 20),
      centerTitle: true,
      title: Text(
        'PAYOUT AUDIT',
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2),
      ),
    );
  }

  Widget _buildExecutiveHeader(AdminPayoutProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppTheme.executiveGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          _buildSummaryItem('PENDING SETTLEMENTS', '₹ ${NumberFormat('#,##,###').format(provider.totalPendingAmount)}', Icons.hourglass_empty_rounded),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1), margin: const EdgeInsets.symmetric(horizontal: 20)),
          _buildSummaryItem('SETTLED TODAY', '₹ ${NumberFormat('#,##,###').format(provider.totalProcessedToday)}', Icons.check_circle_outline_rounded),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.7), size: 12),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.7), fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AdminPayoutProvider provider) {
    return Column(
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) => provider.setSearchQuery(value),
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Search by owner name...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.primaryColor),
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppTheme.cardBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppTheme.cardBorder)),
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(provider, 'all', 'ALL RECORDS'),
              const SizedBox(width: 8),
              _buildFilterChip(provider, 'pending', 'PENDING'),
              const SizedBox(width: 8),
              _buildFilterChip(provider, 'processed', 'PROCESSED'),
              const SizedBox(width: 8),
              _buildFilterChip(provider, 'failed', 'FAILED'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(AdminPayoutProvider provider, String status, String label) {
    final isSelected = provider.selectedStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => provider.setFilterStatus(status),
      labelStyle: GoogleFonts.outfit(
        fontSize: 10, 
        fontWeight: FontWeight.w900, 
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        letterSpacing: 1,
      ),
      selectedColor: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? AppTheme.primaryColor : AppTheme.cardBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      showCheckmark: false,
    );
  }

  Widget _buildPayoutCard(Map<String, dynamic> payout) {
    final status = payout['status'];
    final date = DateTime.parse(payout['createdAt']);
    final owner = payout['ownerId'] ?? {};
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(
            '₹ ${NumberFormat('#,##,###').format(payout['amount'])}',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textMain),
          ),
          subtitle: Text(
            '${owner['name'] ?? 'Unknown'} • ${DateFormat('dd MMM yyyy').format(date)}',
            style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
          ),
          trailing: _getTrailing(status),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _buildDetailRow('HOLDER NAME', owner['name'] ?? 'N/A'),
                  _buildDetailRow('ACCOUNT', payout['bankDetails']?['accountNumber'] ?? 'N/A', canCopy: true),
                  _buildDetailRow('IFSC', payout['bankDetails']?['ifscCode'] ?? 'N/A', canCopy: true),
                  _buildDetailRow('PHONE', owner['phone'] ?? 'N/A'),
                  _buildDetailRow('EMAIL', owner['email'] ?? 'N/A'),
                  if (payout['processedAt'] != null)
                    _buildDetailRow('SETTLED ON', DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(payout['processedAt']))),
                  if (status == 'pending') ...[
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _showActionDialog(payout),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'TAKE ACTION',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13),
                        ),
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

  Widget _getTrailing(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'processed': color = Colors.green; icon = Icons.verified_rounded; break;
      case 'pending': color = Colors.orange; icon = Icons.pending_rounded; break;
      default: color = Colors.redAccent; icon = Icons.error_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.outfit(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textSecondary.withOpacity(0.5), letterSpacing: 1),
          ),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMain),
              ),
              if (canCopy && value != 'N/A')
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.primaryColor),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('$label COPIED TO CLIPBOARD'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  padding: const EdgeInsets.only(left: 8),
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
