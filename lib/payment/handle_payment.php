<?php
session_start();

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $payment_method = $_POST['payment_method'];
    $amount = $_POST['amount'];
    $payment_details = [];
    $success = true; // For demo purposes
    $transaction_id = 'TXN' . time() . rand(1000, 9999);
    $date = date('d M Y, h:i A');

    switch($payment_method) {
        case 'card':
            $payment_details = [
                'method' => 'Credit/Debit Card',
                'card_number' => '****' . substr($_POST['card_number'], -4),
                'card_holder' => $_POST['card_name']
            ];
            break;

        case 'upi':
            $payment_details = [
                'method' => 'UPI',
                'upi_id' => $_POST['upi_id']
            ];
            break;

        case 'netbanking':
            $payment_details = [
                'method' => 'Net Banking',
                'bank' => $_POST['bank_name']
            ];
            break;
    }

    echo "<!DOCTYPE html>
          <html>
          <head>
              <meta charset='UTF-8'>
              <meta name='viewport' content='width=device-width, initial-scale=1.0'>
              <title>Payment Receipt</title>
              <link rel='stylesheet' href='style.css'>
          </head>
          <body>
              <div class='receipt-container'>
                  <div class='receipt-header'>
                      " . ($success ? 
                          "<div class='success-animation'>
                              <svg class='checkmark' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 52 52'>
                                  <circle class='checkmark-circle' cx='26' cy='26' r='25' fill='none'/>
                                  <path class='checkmark-check' fill='none' d='M14.1 27.2l7.1 7.2 16.7-16.8'/>
                              </svg>
                          </div>" : 
                          "<div class='error-icon'>❌</div>")
                      . "
                      <h2>" . ($success ? 'Payment Successful!' : 'Payment Failed') . "</h2>
                  </div>

                  <div class='receipt-body'>
                      <div class='receipt-section'>
                          <div class='receipt-row'>
                              <span class='label'>Amount Paid</span>
                              <span class='value amount-value'>₹" . number_format($amount, 2) . "</span>
                          </div>
                          <div class='receipt-row'>
                              <span class='label'>Transaction ID</span>
                              <span class='value'>" . $transaction_id . "</span>
                          </div>
                          <div class='receipt-row'>
                              <span class='label'>Date & Time</span>
                              <span class='value'>" . $date . "</span>
                          </div>
                      </div>

                      <div class='receipt-section payment-method-details'>
                          <h3>Payment Method</h3>
                          <div class='method-info'>
                              <span class='method-icon'>" . 
                                  ($payment_method == 'card' ? '💳' : 
                                  ($payment_method == 'upi' ? '📱' : '🏦')) . 
                              "</span>
                              <div class='method-details'>";

    foreach ($payment_details as $key => $value) {
        if ($key !== 'method') {
            echo "<p><span class='detail-label'>" . ucfirst(str_replace('_', ' ', $key)) . ":</span> " . htmlspecialchars($value) . "</p>";
        }
    }

    echo "                </div>
                      </div>
                  </div>

                  <div class='receipt-footer'>
                      <button onclick='window.print()' class='action-button print-button'>
                          🖨️ Print Receipt
                      </button>
                      <button onclick='window.location.href=\"index.php\"' class='action-button home-button'>
                          Return to Home
                      </button>
                  </div>
              </div>
          </body>
          </html>";
} else {
    header("Location: index.php");
    exit();
}
?> 