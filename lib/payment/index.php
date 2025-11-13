<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Gateway</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="hero-container">
        <div class="hero-content">
            <h1 class="hero-title">Secure Payment Gateway</h1>
            <p class="hero-subtitle">Fast, secure, and reliable payment processing</p>
            
            <div class="payment-input-section">
                <h2>Enter Payment Amount</h2>
                <div class="amount-input-container">
                    <span class="currency-symbol">₹</span>
                    <input type="number" id="payment-amount" min="1" step="0.01" placeholder="Enter amount" required>
                </div>
                <p class="amount-hint">Enter the amount you want to pay</p>
            </div>

            <div class="features-grid">
                <div class="feature-item">
                    <span class="feature-icon">🔒</span>
                    <h3>Secure</h3>
                    <p>End-to-end encryption for all transactions</p>
                </div>
                <div class="feature-item">
                    <span class="feature-icon">⚡</span>
                    <h3>Fast</h3>
                    <p>Quick processing within seconds</p>
                </div>
                <div class="feature-item">
                    <span class="feature-icon">✅</span>
                    <h3>Reliable</h3>
                    <p>99.9% success rate for all payments</p>
                </div>
            </div>

            <div class="payment-methods-preview">
                <div class="accepted-methods">
                    <span class="method-icon">💳</span>
                    <span class="method-icon">🏦</span>
                    <span class="method-icon">📱</span>
                </div>
                <p class="methods-text">We accept Credit/Debit Cards, Net Banking, and UPI</p>
            </div>

            <button class="make-payment-btn" onclick="proceedToPayment()" disabled>
                Make Payment
                <span class="btn-icon">→</span>
            </button>
        </div>
    </div>

    <script>
        const amountInput = document.getElementById('payment-amount');
        const payButton = document.querySelector('.make-payment-btn');

        amountInput.addEventListener('input', function() {
            const amount = parseFloat(this.value);
            payButton.disabled = !amount || amount <= 0;
        });

        function proceedToPayment() {
            const amount = document.getElementById('payment-amount').value;
            if (amount && amount > 0) {
                window.location.href = `process_payment.php?amount=${encodeURIComponent(amount)}`;
            }
        }
    </script>
</body>
</html> 