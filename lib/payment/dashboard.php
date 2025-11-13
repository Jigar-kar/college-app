<?php
require_once('FeeManager.php');
require_once('PaymentProcessor.php');

session_start();

$feeManager = new FeeManager();
$paymentProcessor = new PaymentProcessor();

// Get fee configurations
$config = require_once(__DIR__ . '/config/fees_config.php');
$feeCategories = $config['categories'];
$paymentMethods = $config['payment_methods'];

// Initialize summary statistics
$totalCollected = 0;
$pendingPayments = 0;
$totalRefunds = 0;

// Placeholder for actual database queries
$recentTransactions = [
    // Sample data - replace with actual database records
    [
        'transaction_id' => 'TXN' . time() . rand(1000, 9999),
        'fee_type' => 'tuition',
        'amount' => 5000,
        'status' => 'completed',
        'date' => date('Y-m-d H:i:s')
    ]
];
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fee Management Dashboard</title>
    <link rel="stylesheet" href="style.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="dashboard-container">
        <header class="dashboard-header">
            <h1>Fee Management Dashboard</h1>
            <div class="header-actions">
                <button onclick="window.location.href='process_payment.php'" class="action-button">
                    New Payment
                </button>
                <button onclick="generateReport()" class="action-button secondary">
                    Generate Report
                </button>
            </div>
        </header>

        <div class="dashboard-stats">
            <div class="stat-card">
                <h3>Total Collections</h3>
                <p class="stat-value">₹<?php echo number_format($totalCollected, 2); ?></p>
            </div>
            <div class="stat-card">
                <h3>Pending Payments</h3>
                <p class="stat-value">₹<?php echo number_format($pendingPayments, 2); ?></p>
            </div>
            <div class="stat-card">
                <h3>Total Refunds</h3>
                <p class="stat-value">₹<?php echo number_format($totalRefunds, 2); ?></p>
            </div>
        </div>

        <div class="dashboard-content">
            <div class="content-section">
                <h2>Fee Categories</h2>
                <div class="fee-categories">
                    <?php foreach ($feeCategories as $type => $category): ?>
                    <div class="category-card">
                        <h3><?php echo htmlspecialchars($category['name']); ?></h3>
                        <p><?php echo htmlspecialchars($category['description']); ?></p>
                        <div class="category-details">
                            <span>Processing Fee: <?php echo ($category['processing_fee'] * 100) . '%'; ?></span>
                            <span>Late Fee: ₹<?php echo $category['late_fee']; ?></span>
                        </div>
                        <button onclick="window.location.href='process_payment.php?type=<?php echo $type; ?>'" 
                                class="action-button">
                            Pay Now
                        </button>
                    </div>
                    <?php endforeach; ?>
                </div>
            </div>

            <div class="content-section">
                <h2>Recent Transactions</h2>
                <div class="transactions-table">
                    <table>
                        <thead>
                            <tr>
                                <th>Transaction ID</th>
                                <th>Fee Type</th>
                                <th>Amount</th>
                                <th>Status</th>
                                <th>Date</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            <?php foreach ($recentTransactions as $transaction): ?>
                            <tr>
                                <td><?php echo htmlspecialchars($transaction['transaction_id']); ?></td>
                                <td><?php echo htmlspecialchars($transaction['fee_type']); ?></td>
                                <td>₹<?php echo number_format($transaction['amount'], 2); ?></td>
                                <td>
                                    <span class="status-badge <?php echo $transaction['status']; ?>">
                                        <?php echo ucfirst($transaction['status']); ?>
                                    </span>
                                </td>
                                <td><?php echo $transaction['date']; ?></td>
                                <td>
                                    <button onclick="viewReceipt('<?php echo $transaction['transaction_id']; ?>')"
                                            class="action-button small">
                                        View Receipt
                                    </button>
                                </td>
                            </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <script>
    function viewReceipt(transactionId) {
        // Implement receipt view logic
        window.location.href = `receipt.php?id=${transactionId}`;
    }

    function generateReport() {
        // Implement report generation logic
        window.location.href = 'generate_report.php';
    }
    </script>
</body>
</html>