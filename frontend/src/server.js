const express = require('express');
const axios = require('axios');
require('dotenv').config();

const app = express();
app.use(express.json());

// API endpoint to create Billplz bill
app.post('/api/create-payment', async (req, res) => {
  const { bookingId, email, name, amount, description } = req.body;
  
  try {
    const response = await axios.post(
      'https://www.billplz.com/api/v3/bills',
      {
        collection_id: process.env.BILLPLZ_COLLECTION_ID,
        email: email,
        name: name,
        amount: amount * 100, // Convert to cents
        callback_url: `${process.env.BASE_URL}/api/payment-callback`,
        redirect_url: `${process.env.BASE_URL}/payment-success`,
        description: description,
        reference_1_label: 'Booking ID',
        reference_1: bookingId
      },
      {
        auth: {
          username: process.env.BILLPLZ_API_KEY,
          password: ''
        }
      }
    );
    
    res.json({ url: response.data.url });
  } catch (error) {
    res.status(500).json({ error: 'Payment creation failed' });
  }
});

// Payment callback endpoint
app.post('/api/payment-callback', (req, res) => {
  const { id, paid, x_signature } = req.body;
  
  // Verify signature
  // Update booking status in database
  
  res.sendStatus(200);
});

app.listen(3000, () => console.log('Server running on port 3000'));
