<?php

// Fee Categories Configuration
$FEE_CATEGORIES = [
    'tuition' => [
        'name' => 'Tuition Fees',
        'description' => 'Regular academic tuition fees',
        'processing_fee' => 0.015, // 1.5% processing fee
        'late_fee' => 100, // Late fee amount
        'adjustable' => true,
        'refundable' => true
    ],
    'library' => [
        'name' => 'Library Fees',
        'description' => 'Library membership and services',
        'processing_fee' => 0,
        'late_fee' => 50,
        'adjustable' => true,
        'refundable' => true
    ],
    'transport' => [
        'name' => 'Transport Fees',
        'description' => 'Transportation service fees',
        'processing_fee' => 0.01, // 1% processing fee
        'late_fee' => 75,
        'adjustable' => true,
        'refundable' => true
    ],
    'deposit' => [
        'name' => 'Security Deposit',
        'description' => 'Refundable security deposit',
        'processing_fee' => 0,
        'late_fee' => 0,
        'adjustable' => true,
        'refundable' => true
    ]
];

// Payment Method Configuration
$PAYMENT_METHODS = [
    'card' => [
        'name' => 'Credit/Debit Card',
        'processing_fee' => 0.02, // 2% processing fee
        'min_amount' => 100,
        'max_amount' => 200000
    ],
    'upi' => [
        'name' => 'UPI Payment',
        'processing_fee' => 0.008, // 0.8% processing fee
        'min_amount' => 1,
        'max_amount' => 100000
    ],
    'netbanking' => [
        'name' => 'Net Banking',
        'processing_fee' => 0.015, // 1.5% processing fee
        'min_amount' => 100,
        'max_amount' => 200000
    ]
];

// Fee Adjustment Rules
$ADJUSTMENT_RULES = [
    'scholarship' => [
        'max_percentage' => 100,
        'applicable_categories' => ['tuition']
    ],
    'sibling_discount' => [
        'percentage' => 10,
        'applicable_categories' => ['tuition', 'transport']
    ],
    'early_payment' => [
        'percentage' => 5,
        'applicable_categories' => ['tuition', 'transport', 'library']
    ]
];

// Refund Policy Configuration
$REFUND_POLICY = [
    'deposit' => [
        'full_refund_period' => 30, // days
        'processing_fee' => 50
    ],
    'tuition' => [
        'refund_percentage' => [
            30 => 75, // Within 30 days: 75% refund
            60 => 50, // Within 60 days: 50% refund
            90 => 25  // Within 90 days: 25% refund
        ],
        'processing_fee' => 100
    ]
];

// Export configurations
return [
    'categories' => $FEE_CATEGORIES,
    'payment_methods' => $PAYMENT_METHODS,
    'adjustment_rules' => $ADJUSTMENT_RULES,
    'refund_policy' => $REFUND_POLICY
];
?>