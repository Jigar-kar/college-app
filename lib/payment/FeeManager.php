<?php
class FeeManager {
    private $config;
    private $db; // Database connection placeholder

    public function __construct() {
        $this->config = require_once(__DIR__ . '/config/fees_config.php');
    }

    public function calculateFeeAmount($feeType, $amount, $paymentMethod, $dueDate = null) {
        $feeCategory = $this->config['categories'][$feeType] ?? null;
        $paymentConfig = $this->config['payment_methods'][$paymentMethod] ?? null;

        if (!$feeCategory || !$paymentConfig) {
            throw new Exception('Invalid fee type or payment method');
        }

        $totalAmount = $amount;

        // Add processing fees
        $processingFee = $amount * ($feeCategory['processing_fee'] + $paymentConfig['processing_fee']);
        $totalAmount += $processingFee;

        // Add late fee if applicable
        if ($dueDate && strtotime($dueDate) < time()) {
            $totalAmount += $feeCategory['late_fee'];
        }

        return [
            'base_amount' => $amount,
            'processing_fee' => $processingFee,
            'late_fee' => $dueDate && strtotime($dueDate) < time() ? $feeCategory['late_fee'] : 0,
            'total_amount' => $totalAmount
        ];
    }

    public function applyAdjustment($feeType, $amount, $adjustmentType) {
        $adjustment = $this->config['adjustment_rules'][$adjustmentType] ?? null;
        $feeCategory = $this->config['categories'][$feeType] ?? null;

        if (!$adjustment || !$feeCategory || !$feeCategory['adjustable']) {
            throw new Exception('Invalid adjustment type or fee is not adjustable');
        }

        if (!in_array($feeType, $adjustment['applicable_categories'])) {
            throw new Exception('Adjustment not applicable to this fee type');
        }

        $adjustmentAmount = $amount * ($adjustment['percentage'] / 100);
        return [
            'original_amount' => $amount,
            'adjustment_amount' => $adjustmentAmount,
            'final_amount' => $amount - $adjustmentAmount
        ];
    }

    public function calculateRefund($feeType, $amount, $paymentDate) {
        $refundPolicy = $this->config['refund_policy'][$feeType] ?? null;
        $feeCategory = $this->config['categories'][$feeType] ?? null;

        if (!$refundPolicy || !$feeCategory || !$feeCategory['refundable']) {
            throw new Exception('Refund not available for this fee type');
        }

        $daysSincePayment = floor((time() - strtotime($paymentDate)) / (60 * 60 * 24));

        // Handle deposit refunds
        if ($feeType === 'deposit') {
            if ($daysSincePayment <= $refundPolicy['full_refund_period']) {
                return [
                    'original_amount' => $amount,
                    'refund_amount' => $amount - $refundPolicy['processing_fee'],
                    'processing_fee' => $refundPolicy['processing_fee']
                ];
            }
        }

        // Handle other fee types
        $refundPercentage = 0;
        foreach ($refundPolicy['refund_percentage'] as $days => $percentage) {
            if ($daysSincePayment <= $days) {
                $refundPercentage = $percentage;
                break;
            }
        }

        $refundAmount = ($amount * $refundPercentage / 100) - $refundPolicy['processing_fee'];
        return [
            'original_amount' => $amount,
            'refund_amount' => max(0, $refundAmount),
            'processing_fee' => $refundPolicy['processing_fee']
        ];
    }

    public function validatePaymentMethod($method, $amount) {
        $paymentConfig = $this->config['payment_methods'][$method] ?? null;

        if (!$paymentConfig) {
            throw new Exception('Invalid payment method');
        }

        if ($amount < $paymentConfig['min_amount'] || $amount > $paymentConfig['max_amount']) {
            throw new Exception(
                sprintf(
                    'Amount must be between %s and %s for %s',
                    $paymentConfig['min_amount'],
                    $paymentConfig['max_amount'],
                    $paymentConfig['name']
                )
            );
        }

        return true;
    }
}
?>