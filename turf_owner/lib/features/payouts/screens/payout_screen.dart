import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/payout_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class PayoutScreen extends StatefulWidget {
  const PayoutScreen({super.key});

  @override
  _PayoutScreenState createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  final _amountController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PayoutProvider>(context, listen: false);
      provider.fetchWalletData();
      provider.fetchPayoutHistory();
    });
  }

  Future<void> _submitRequest() async {
    if (_amountController.text.isEmpty || _accountNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PLEASE FILL ALL FIELDS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }

    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('MINIMUM PAYOUT IS RS. 500', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await Provider.of<PayoutProvider>(context, listen: false).requestPayout(
      amount,
      {
        'accountNumber': _accountNumberController.text,
        'ifscCode': _ifscController.text,
        'accountHolderName': _nameController.text,
      },
    );

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PAYOUT REQUEST SUBMITTED!', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
        )
      );
      _amountController.clear();
      // Keep bank details for convenience in next request? Or clear? 
      // Usually good to keep if they don't change.
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('INSUFFICIENT BALANCE OR SERVER ERROR', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text('WALLET & PAYOUTS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<PayoutProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchWalletData();
              await provider.fetchPayoutHistory();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(provider),
                  const SizedBox(height: 32),
                  _buildPayoutForm(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('RECENT SETTLEMENTS'),
                  const SizedBox(height: 16),
                  _buildPayoutHistoryList(provider),
                  const SizedBox(height: 32),
                  _buildSectionHeader('ABOUT PAYOUTS'),
                  const SizedBox(height: 16),
                  _buildAboutCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(PayoutProvider provider) {
    final balance = provider.walletData?['availableBalance'] ?? 0.0;
    final totalRevenue = provider.walletData?['totalRevenue'] ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AVAILABLE BALANCE',
            style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Text(
            'Rs. ${NumberFormat('#,##,###').format(balance)}',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('TOTAL REVENUE', 'Rs. ${NumberFormat('#,##,###').format(totalRevenue)}'),
              _buildStatItem('PENDING', 'Rs. ${NumberFormat('#,##,###').format(provider.walletData?['pendingPayouts'] ?? 0.0)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppTheme.textSecondary,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutForm() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REQUEST SETTLEMENT', 
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 1)
          ),
          const SizedBox(height: 24),
          _buildTextField('WITHDRAWAL AMOUNT', _amountController, Icons.currency_rupee_rounded, TextInputType.number),
          const SizedBox(height: 20),
          _buildTextField('ACCOUNT NUMBER', _accountNumberController, Icons.account_balance_wallet_outlined, TextInputType.number),
          const SizedBox(height: 20),
          _buildTextField('IFSC CODE', _ifscController, Icons.code_rounded, TextInputType.text),
          const SizedBox(height: 20),
          _buildTextField('ACCOUNT HOLDER NAME', _nameController, Icons.person_outline_rounded, TextInputType.text),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
                shadowColor: AppTheme.primaryColor.withOpacity(0.3),
              ),
              child: _isSubmitting 
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('SUBMIT PAYOUT REQUEST', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textSecondary, letterSpacing: 1),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: type,
          style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textMain, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.primaryColor.withOpacity(0.3), size: 18),
            filled: true,
            fillColor: AppTheme.bgColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16), 
              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildPayoutHistoryList(PayoutProvider provider) {
    if (provider.payouts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            Icon(Icons.history_rounded, color: AppTheme.textSecondary.withOpacity(0.2), size: 40),
            const SizedBox(height: 12),
            Text('NO RECENT SETTLEMENTS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppTheme.textSecondary.withOpacity(0.5), fontSize: 10, letterSpacing: 1)),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.payouts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final payout = provider.payouts[index];
        final date = DateTime.parse(payout['createdAt']);
        final status = payout['status'];
        
        Color statusColor;
        IconData statusIcon;
        switch (status) {
          case 'processed':
            statusColor = Colors.green;
            statusIcon = Icons.check_circle_rounded;
            break;
          case 'pending':
            statusColor = Colors.orange;
            statusIcon = Icons.pending_rounded;
            break;
          default:
            statusColor = Colors.red;
            statusIcon = Icons.error_rounded;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withOpacity(0.01))),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rs. ${NumberFormat('#,##,###').format(payout['amount'])}', 
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal()),
                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status.toUpperCase(), 
                    style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 1)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 16),
              ),
              const SizedBox(width: 12),
              Text('SETTLEMENT CYCLE', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, color: AppTheme.primaryColor)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Payouts are processed within 2-3 business days. Minimum payout amount is Rs. 500 for verified accounts.',
            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMain.withOpacity(0.7), height: 1.5),
          ),
        ],
      ),
    );
  }
}
