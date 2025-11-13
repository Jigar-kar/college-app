document.addEventListener('DOMContentLoaded', function() {
    const payAmount = document.getElementById('payAmount');
    const amountDisplay = document.getElementById('amount');
    const chargesDisplay = document.getElementById('charges');
    const payButton = document.getElementById('payButton');
    const notification = document.getElementById('notification');
    const notificationText = document.getElementById('notificationText');
    const paymentOptions = document.querySelectorAll('.payment-option');
    
    // GST rate
    const GST_RATE = 0.18;
    
    // Payment method charges
    const CHARGES = {
        upi: 0.008, // 0.8%
        card: 0.02  // 2%
    };

    // Show/hide payment inputs based on selection
    document.querySelectorAll('input[name="paymentMethod"]').forEach(radio => {
        radio.addEventListener('change', function() {
            // Hide all input sections first
            document.querySelector('.upi-input').classList.add('hidden');
            document.querySelector('.card-input').classList.add('hidden');
            
            // Remove selected class from all options
            paymentOptions.forEach(option => option.classList.remove('selected'));
            
            // Show selected input section
            if (this.value === 'upi') {
                document.querySelector('.upi-input').classList.remove('hidden');
                document.getElementById('upiOption').classList.add('selected');
            } else if (this.value === 'card') {
                document.querySelector('.card-input').classList.remove('hidden');
                document.getElementById('cardOption').classList.add('selected');
            }
            
            calculateCharges();
        });
    });

    // Calculate charges when amount changes
    payAmount.addEventListener('input', calculateCharges);

    function calculateCharges() {
        const amount = parseFloat(payAmount.value) || 0;
        const selectedMethod = document.querySelector('input[name="paymentMethod"]:checked')?.value;
        
        let charges = 0;
        if (selectedMethod) {
            charges = amount * CHARGES[selectedMethod];
            charges = Math.max(charges, 10); // Minimum charge of ₹10
            const gst = charges * GST_RATE;
            charges += gst;
        }

        amountDisplay.textContent = `₹${amount.toFixed(2)}`;
        chargesDisplay.textContent = `+₹${charges.toFixed(2)} charges (incl. GST)`;
        
        // Enable/disable pay button
        payButton.disabled = amount <= 0 || !selectedMethod;
    }

    // Handle payment submission
    function processPayment(paymentData) {
        payButton.disabled = true;
        payButton.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Processing...';

        // Create form data
        const formData = new FormData();
        formData.append('paymentMethod', paymentData.method);
        formData.append('amount', paymentData.amount);
        formData.append('charges', paymentData.charges);

        if (paymentData.method === 'upi') {
            formData.append('upiId', paymentData.upiId);
        } else if (paymentData.method === 'card') {
            formData.append('cardNumber', paymentData.cardNumber);
            formData.append('cardName', paymentData.cardName);
            // Don't send CVV for security
        }

        // Send to server
        fetch('process_payment.php', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            if (data.success) {
                // Redirect to home page with transaction details
                const params = new URLSearchParams({
                    txn_id: data.transaction.id,
                    amount: data.transaction.amount,
                    method: paymentData.method,
                    date: encodeURIComponent(data.transaction.date)
                });
                window.location.href = `home.php?${params.toString()}`;
            } else {
                throw new Error(data.message);
            }
        })
        .catch(error => {
            showNotification(error.message || 'Payment failed', 'error');
            payButton.disabled = false;
            payButton.innerHTML = '<i class="fas fa-lock"></i> Pay Securely';
        });
    }

    // Update the pay button click handler
    payButton.addEventListener('click', function() {
        const amount = parseFloat(payAmount.value);
        const selectedMethod = document.querySelector('input[name="paymentMethod"]:checked')?.value;
        
        if (!amount || !selectedMethod) {
            showNotification('Please enter amount and select payment method', 'error');
            return;
        }

        let paymentData = {
            method: selectedMethod,
            amount: amount,
            charges: calculateCharges(amount, selectedMethod)
        };

        if (selectedMethod === 'upi') {
            const upiId = document.getElementById('upiId').value;
            if (!upiId || !upiId.includes('@')) {
                showNotification('Please enter a valid UPI ID', 'error');
                return;
            }
            paymentData.upiId = upiId;
        } else if (selectedMethod === 'card') {
            const cardNumber = document.getElementById('cardNumber').value;
            const expiry = document.getElementById('expiry').value;
            const cvv = document.getElementById('cvv').value;
            const cardName = document.getElementById('cardName').value;

            if (!validateCard(cardNumber, expiry, cvv, cardName)) {
                return;
            }
            paymentData.cardNumber = cardNumber;
            paymentData.cardName = cardName;
        }

        processPayment(paymentData);
    });

    function validateCard(cardNumber, expiry, cvv, cardName) {
        if (cardNumber.length !== 16 || !/^\d+$/.test(cardNumber)) {
            showNotification('Please enter a valid 16-digit card number', 'error');
            return false;
        }

        if (!expiry.match(/^(0[1-9]|1[0-2])\/([0-9]{2})$/)) {
            showNotification('Please enter a valid expiry date (MM/YY)', 'error');
            return false;
        }

        if (cvv.length !== 3 || !/^\d+$/.test(cvv)) {
            showNotification('Please enter a valid 3-digit CVV', 'error');
            return false;
        }

        if (!cardName.trim()) {
            showNotification('Please enter the card holder name', 'error');
            return false;
        }

        return true;
    }

    function showNotification(message, type) {
        notificationText.textContent = message;
        notification.className = `notification ${type} show`;
        
        setTimeout(() => {
            notification.className = 'notification';
        }, 3000);
    }

    function resetForm() {
        payAmount.value = '0';
        document.querySelectorAll('input[name="paymentMethod"]').forEach(radio => radio.checked = false);
        document.querySelector('.upi-input').classList.add('hidden');
        document.querySelector('.card-input').classList.add('hidden');
        document.getElementById('upiId').value = '';
        document.getElementById('cardNumber').value = '';
        document.getElementById('expiry').value = '';
        document.getElementById('cvv').value = '';
        document.getElementById('cardName').value = '';
        paymentOptions.forEach(option => option.classList.remove('selected'));
        calculateCharges();
        payButton.innerHTML = '<i class="fas fa-lock"></i> Pay Securely';
        payButton.disabled = false;
    }

    // Format card number with spaces
    document.getElementById('cardNumber').addEventListener('input', function(e) {
        this.value = this.value.replace(/\D/g, '').substring(0, 16);
    });

    // Format expiry date
    document.getElementById('expiry').addEventListener('input', function(e) {
        this.value = this.value.replace(/\D/g, '')
            .replace(/^(\d{2})/, '$1/')
            .substring(0, 5);
    });

    // Only allow numbers in CVV
    document.getElementById('cvv').addEventListener('input', function(e) {
        this.value = this.value.replace(/\D/g, '').substring(0, 3);
    });
}); 