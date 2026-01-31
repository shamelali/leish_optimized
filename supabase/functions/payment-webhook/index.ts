import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const HITPAY_API_KEY = Deno.env.get("HITPAY_API_KEY");
const HITPAY_SALT = Deno.env.get("HITPAY_SALT");

serve(async (req) => {
  const { booking_id, amount, email, name } = await req.json();
  
  // Create HitPay payment request
  const response = await fetch("https://api.hitpay.app/v1/payment-requests", {
    method: "POST",
    headers: {
      "X-BUSINESS-API-KEY": HITPAY_API_KEY,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount: amount.toString(),
      currency: "MYR",
      email: email,
      name: name,
      reference_number: booking_id,
      webhook: `${Deno.env.get("SITE_URL")}/functions/v1/payment-webhook`,
      redirect_url: `${Deno.env.get("SITE_URL")}/booking-success`,
    }),
  });
  
  const data = await response.json();
  
  return new Response(JSON.stringify({ 
    payment_url: data.url // Redirect user here
  }), {
    headers: { "Content-Type": "application/json" },
  });
});