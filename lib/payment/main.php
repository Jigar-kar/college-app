<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Gateway - Home</title>
    <link rel="stylesheet" href="style.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        .hero-section {
            text-align: center;
            padding: 60px 20px;
            background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
            border-radius: 15px;
            margin-bottom: 40px;
        }

        .hero-title {
            font-size: 2.5em;
            color: var(--text-color);
            margin-bottom: 20px;
        }

        .hero-subtitle {
            color: #666;
            margin-bottom: 30px;
            font-size: 1.2em;
        }

        .features-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 40px;
        }

        .feature-card {
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            transition: transform 0.3s ease;
        }

        .feature-card:hover {
            transform: translateY(-5px);
        }

        .feature-icon {
            font-size: 2em;
            color: var(--primary-color);
            margin-bottom: 15px;
        }

        .make-payment-btn {
            background-color: var(--primary-color);
            color: white;
            padding: 15px 40px;
            border: none;
            border-radius: 8px;
            font-size: 1.2em;
            cursor: pointer;
            transition: all 0.3s ease;
            display: inline-flex;
            align-items: center;
            gap: 10px;
        }

        .make-payment-btn:hover {
            background-color: var(--secondary-color);
            transform: translateY(-2px);
        }

        .recent-transactions {
            margin-top: 40px;
            background: white;
            padding: 25px;
            border-radius: 10px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }

        .transaction-list {
            margin-top: 20px;
        }

        .transaction-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 15px;
            border-bottom: 1px solid #eee;
        }

        .transaction-item:last-child {
            border-bottom: none;
        }

        .transaction-info {
            display: flex;
            align-items: center;
            gap: 15px;
        }

        .transaction-amount {
            font-weight: bold;
            color: var(--primary-color);
        }

        .method-badge {
            padding: 5px 10px;
            border-radius: 15px;
            font-size: 0.9em;
            background: #e9ecef;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="hero-section">
            <h1 class="hero-title">Welcome to Payment Gateway</h1>
            <p class="hero-subtitle">Fast, secure, and reliable payment processing</p>
            <button class="make-payment-btn" onclick="window.location.href='index.html'">
                <i class="fas fa-credit-card"></i> Make Payment
            </button>
        </div>

        <div class="features-grid">
            <div class="feature-card">
                <div class="feature-icon">
                    <i class="fas fa-bolt"></i>
                </div>
                <h3>Quick Payments</h3>
                <p>Process payments instantly with UPI or card</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon">
                    <i class="fas fa-shield-alt"></i>
                </div>
                <h3>Secure</h3>
                <p>Bank-grade security for all transactions</p>
            </div>
            <div class="feature-card">
                <div class="feature-icon">
                    <i class="fas fa-receipt"></i>
                </div>
                <h3>Instant Receipt</h3>
                <p>Get digital receipts immediately</p>
            </div>
        </div>

        <div class="recent-transactions">
            <h2>Recent Transactions</h2>
            <div class="transaction-list">
                <?php
                try {
                    $db = new PDO("mysql:host=localhost;dbname=payment_system", "root", "");
                    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
                    
                    $stmt = $db->query("SELECT * FROM payments ORDER BY payment_date DESC LIMIT 5");
                    $transactions = $stmt->fetchAll(PDO::FETCH_ASSOC);

                    foreach ($transactions as $transaction) {
                        echo '<div class="transaction-item">
                                <div class="transaction-info">
                                    <i class="fas fa-' . ($transaction['payment_method'] == 'upi' ? 'mobile-alt' : 'credit-card') . '"></i>
                                    <div>
                                        <div>' . $transaction['transaction_id'] . '</div>
                                        <small>' . date('d M Y, H:i', strtotime($transaction['payment_date'])) . '</small>
                                    </div>
                                </div>
                                <div class="transaction-amount">
                                    ₹' . number_format($transaction['amount'], 2) . '
                                    <span class="method-badge">' . strtoupper($transaction['payment_method']) . '</span>
                                </div>
                            </div>';
                    }
                } catch(PDOException $e) {
                    echo '<p>No recent transactions</p>';
                }
                ?>
            </div>
        </div>
    </div>
</body>
</html> 