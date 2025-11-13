<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Payment Success - Home</title>
    <link rel="stylesheet" href="style.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
</head>
<body>
    <div class="container">
        <div class="success-card">
            <div class="success-icon">
                <i class="fas fa-check-circle"></i>
            </div>
            <h2>Payment Successful!</h2>
            
            <div class="transaction-details">
                <h3>Transaction Details</h3>
                <div class="detail-item">
                    <span>Transaction ID:</span>
                    <span id="transactionId"></span>
                </div>
                <div class="detail-item">
                    <span>Amount Paid:</span>
                    <span id="amountPaid"></span>
                </div>
                <div class="detail-item">
                    <span>Payment Method:</span>
                    <span id="paymentMethod"></span>
                </div>
                <div class="detail-item">
                    <span>Date:</span>
                    <span id="paymentDate"></span>
                </div>
            </div>

            <div class="actions">
                <button class="download-button" onclick="downloadReceipt()">
                    <i class="fas fa-download"></i> Download Receipt
                </button>
                <button class="new-payment-button" onclick="window.location.href='payment.html'">
                    <i class="fas fa-plus"></i> New Payment
                </button>
            </div>
        </div>
    </div>

    <script>
        document.addEventListener('DOMContentLoaded', function() {
            // Get transaction details from URL parameters
            const urlParams = new URLSearchParams(window.location.search);
            const transactionData = {
                id: urlParams.get('txn_id'),
                amount: urlParams.get('amount'),
                method: urlParams.get('method'),
                date: urlParams.get('date')
            };

            // Display transaction details
            document.getElementById('transactionId').textContent = transactionData.id || 'N/A';
            document.getElementById('amountPaid').textContent = `₹${parseFloat(transactionData.amount || 0).toFixed(2)}`;
            document.getElementById('paymentMethod').textContent = (transactionData.method || '').toUpperCase();
            document.getElementById('paymentDate').textContent = decodeURIComponent(transactionData.date || '');
        });

        function downloadReceipt() {
            // Create receipt content
            const receiptContent = `
Payment Receipt
--------------
Transaction ID: ${document.getElementById('transactionId').textContent}
Amount: ${document.getElementById('amountPaid').textContent}
Method: ${document.getElementById('paymentMethod').textContent}
Date: ${document.getElementById('paymentDate').textContent}
            `.trim();

            // Create blob and download
            const blob = new Blob([receiptContent], { type: 'text/plain' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `receipt_${document.getElementById('transactionId').textContent}.txt`;
            document.body.appendChild(a);
            a.click();
            window.URL.revokeObjectURL(url);
            document.body.removeChild(a);
        }
    </script>

    <style>
        .success-card {
            text-align: center;
            padding: 40px;
        }

        .success-icon {
            font-size: 64px;
            color: var(--success-color);
            margin-bottom: 20px;
            animation: scaleIn 0.5s ease-out;
        }

        @keyframes scaleIn {
            from {
                transform: scale(0);
            }
            to {
                transform: scale(1);
            }
        }

        .transaction-details {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin: 30px 0;
            text-align: left;
        }

        .detail-item {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #eee;
        }

        .detail-item:last-child {
            border-bottom: none;
        }

        .actions {
            display: flex;
            gap: 15px;
            justify-content: center;
            margin-top: 30px;
        }

        .download-button, .new-payment-button {
            padding: 12px 25px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
            display: flex;
            align-items: center;
            gap: 8px;
            transition: all 0.3s ease;
        }

        .download-button {
            background-color: var(--primary-color);
            color: white;
        }

        .new-payment-button {
            background-color: #f8f9fa;
            color: var(--text-color);
            border: 2px solid var(--border-color);
        }

        .download-button:hover, .new-payment-button:hover {
            transform: translateY(-2px);
        }
    </style>
</body>
</html> 