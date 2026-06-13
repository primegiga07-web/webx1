import 'package:flutter/material.dart';
import '../auth_theme.dart';
import '../mock_data.dart';
import '../services/api_service.dart';
import 'withdraw_successful_dialog.dart';

class WithdrawRequestDialog extends StatefulWidget {
  final int currentBalance;
  final VoidCallback onWithdrawalSuccess;

  const WithdrawRequestDialog({
    super.key,
    required this.currentBalance,
    required this.onWithdrawalSuccess,
  });

  @override
  State<WithdrawRequestDialog> createState() => _WithdrawRequestDialogState();
}

class _WithdrawRequestDialogState extends State<WithdrawRequestDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  bool _isLoading = false;
  String? _errorText;
  double _rupeeValue = 0.0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_updateRupeeConversion);
  }

  void _updateRupeeConversion() {
    final text = _amountController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _rupeeValue = 0.0;
      });
      return;
    }

    final coins = int.tryParse(text);
    if (coins != null) {
      setState(() {
        _rupeeValue = coins * 0.01; // 1 Rocket coin = 0.01 rupees
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _upiController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final name = _nameController.text.trim();
    final upiId = _upiController.text.trim();
    final amountText = _amountController.text.trim();

    if (name.isEmpty || upiId.isEmpty || amountText.isEmpty) {
      setState(() {
        _errorText = "Please fill in all fields.";
      });
      return;
    }

    if (!upiId.contains('@')) {
      setState(() {
        _errorText = "Please enter a valid UPI ID (e.g. user@upi).";
      });
      return;
    }

    final coins = int.tryParse(amountText);
    if (coins == null || coins < 1000) {
      setState(() {
        _errorText = "Minimum withdrawal limit is 1000 Rocket Coins.";
      });
      return;
    }

    if (coins > widget.currentBalance) {
      setState(() {
        _errorText = "Insufficient balance.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    if (MockData.useRealBackend) {
      final res = await ApiService.requestWithdrawal(name, upiId, coins);
      setState(() {
        _isLoading = false;
      });

      if (res['success'] == true) {
        if (mounted) {
          Navigator.pop(context); // Close request modal
          widget.onWithdrawalSuccess(); // Refresh profile state
          
          // Show dynamic success modal
          showDialog(
            context: context,
            barrierColor: Colors.black.withAlpha(160),
            builder: (context) => const WithdrawSuccessfulDialog(),
          );
        }
      } else {
        setState(() {
          _errorText = res['error'] ?? "Withdrawal request failed. Try again.";
        });
      }
    } else {
      // Mock Success
      await Future.delayed(const Duration(milliseconds: 1000));
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onWithdrawalSuccess();
        
        showDialog(
          context: context,
          barrierColor: Colors.black.withAlpha(160),
          builder: (context) => const WithdrawSuccessfulDialog(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B), // Premium dark theme matching profile card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Withdraw Request",
                    style: TextStyle(
                      fontFamily: AuthTheme.fontFamily,
                      fontWeight: FontWeight.w600,
                      fontSize: 20.0,
                      color: Colors.white,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white60,
                      size: 24.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              Text(
                "Available balance: ${widget.currentBalance} Rocket Coins",
                style: const TextStyle(
                  fontFamily: AuthTheme.fontFamily,
                  fontSize: 13.0,
                  color: AuthTheme.textGrey,
                ),
              ),
              const SizedBox(height: 20.0),

              // Full Name field
              _buildLabel("Full Name"),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration("Enter your full name"),
              ),
              const SizedBox(height: 16.0),

              // UPI ID field
              _buildLabel("UPI ID"),
              TextField(
                controller: _upiController,
                style: const TextStyle(color: Colors.white),
                decoration: _buildInputDecoration("example@upi"),
              ),
              const SizedBox(height: 16.0),

              // Rocket Coins Amount field
              _buildLabel("Withdraw Coins"),
              TextField(
                controller: _amountController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: _buildInputDecoration("Min 1000 coins"),
              ),
              const SizedBox(height: 12.0),

              // Coin-to-Rupee conversion preview
              if (_rupeeValue > 0)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF334155),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Estimated Value:",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13.0,
                          fontFamily: AuthTheme.fontFamily,
                        ),
                      ),
                      Text(
                        "₹ ${_rupeeValue.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Color(0xFF4ADE80),
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                          fontFamily: AuthTheme.fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),

              if (_errorText != null) ...[
                const SizedBox(height: 16.0),
                Text(
                  _errorText!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 24.0),

              // Confirm button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AuthTheme.primary.withAlpha(100),
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20.0,
                        width: 20.0,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        "Confirm Withdrawal",
                        style: TextStyle(
                          fontFamily: AuthTheme.fontFamily,
                          fontWeight: FontWeight.w600,
                          fontSize: 15.0,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: AuthTheme.fontFamily,
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30, fontSize: 14.0),
      filled: true,
      fillColor: const Color(0xFF0F172A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: Color(0xFF334155), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: AuthTheme.primary, width: 1.5),
      ),
    );
  }
}
