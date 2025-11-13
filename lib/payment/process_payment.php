<?php
// Start the session if needed
session_start();

// Get and validate the amount
$amount = isset($_GET['amount']) ? floatval($_GET['amount']) : 0;
if ($amount <= 0) {
    header("Location: index.php");
    exit();
}
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Form</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="payment-container">
        <div class="payment-header">
            <h2>Payment Details</h2>
            <div class="amount-display">
                <span class="amount-label">Amount to Pay</span>
                <span class="amount-value">₹<?php echo number_format($amount, 2); ?></span>
            </div>
        </div>

        <form action="handle_payment.php" method="POST">
            <input type="hidden" name="amount" value="<?php echo htmlspecialchars($amount); ?>">
            <div class="payment-methods">
                <h3>Select Payment Method</h3>
                
                <!-- Card Payment Option -->
                <div class="payment-option">
                    <input type="radio" id="card" name="payment_method" value="card">
                    <label for="card">
                        <span class="payment-icon">💳</span>
                        <span class="payment-label">Credit/Debit Card</span>
                    </label>
                    <div class="payment-details card-details hidden">
                        <div class="form-group">
                            <label>Card Number</label>
                            <input type="text" name="card_number" placeholder="1234 5678 9012 3456" maxlength="16">
                        </div>
                        <div class="form-row">
                            <div class="form-group">
                                <label>Expiry Date</label>
                                <input type="text" name="card_expiry" placeholder="MM/YY">
                            </div>
                            <div class="form-group">
                                <label>CVV</label>
                                <input type="password" name="card_cvv" placeholder="123" maxlength="3">
                            </div>
                        </div>
                        <div class="form-group">
                            <label>Card Holder Name</label>
                            <input type="text" name="card_name" placeholder="Name on card">
                        </div>
                    </div>
                </div>

                <!-- UPI Payment Option -->
                <div class="payment-option">
                    <input type="radio" id="upi" name="payment_method" value="upi">
                    <label for="upi">
                        <span class="payment-icon">📱</span>
                        <span class="payment-label">UPI Payment</span>
                    </label>
                    <div class="payment-details upi-details hidden">
                        <div class="form-group">
                            <label>UPI ID</label>
                            <input type="text" name="upi_id" placeholder="username@upi">
                        </div>
                    </div>
                </div>

                <!-- Net Banking Option -->
                <div class="payment-option">
                    <input type="radio" id="netbanking" name="payment_method" value="netbanking">
                    <label for="netbanking">
                        <span class="payment-icon">🏦</span>
                        <span class="payment-label">Net Banking</span>
                    </label>
                    <div class="payment-details netbanking-details hidden">
                        <div class="form-group">
                            <label>Select Bank</label>
                            <select name="bank_name">
                                <option value="">Choose your bank</option>
                                <option value="sbi">State Bank of India</option>
                                <option value="hdfc">HDFC Bank</option>
                                <option value="icici">ICICI Bank</option>
                                <option value="axis">Axis Bank</option>
                            </select>
                        </div>
                    </div>
                </div>
            </div>

            <button type="submit" class="pay-button">
                Pay Now <span class="amount-text">₹<?php echo number_format($amount, 2); ?></span>
            </button>
        </form>
    </div>

    <script>
        // Show/hide payment details based on selection
        document.querySelectorAll('input[name="payment_method"]').forEach(radio => {
            radio.addEventListener('change', function() {
                // Hide all payment details first
                document.querySelectorAll('.payment-details').forEach(detail => {
                    detail.classList.add('hidden');
                });
                
                // Show selected payment method details
                if (this.checked) {
                    const details = document.querySelector('.' + this.value + '-details');
                    if (details) {
                        details.classList.remove('hidden');
                    }
                }
            });
        });
    </script>
</body>
</html> 