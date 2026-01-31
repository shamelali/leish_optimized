import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") || "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || ""
    );

    const { booking_id, amount, email, name, phone } = await req.json();
    
    const hitpayApiKey = Deno.env.get("HITPAY_API_KEY");
    const siteUrl = Deno.env.get("SITE_URL") || "https://leish.my";
    
    if (!hitpayApiKey) {
      throw new Error("HitPay API key not configured");
    }

    const hitpayResponse = await fetch("https://api.hitpay.app/v1/payment-requests", {
      method: "POST",
      headers: {
        "X-BUSINESS-API-KEY": hitpayApiKey,
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: JSON.stringify({
        amount: amount.toString(),
        currency: "MYR",
        email: email,
        name: name,
        phone: phone || "",
        reference_number: booking_id,
        webhook: `${siteUrl}/functions/v1/payment-webhook`,
        redirect_url: `${siteUrl}/booking-success?id=${booking_id}`,
        allow_repeated_payments: false,
      }),
    });

    if (!hitpayResponse.ok) {
      const errorText = await hitpayResponse.text();
      throw new Error(`HitPay error: ${errorText}`);
    }

    const hitpayData = await hitpayResponse.json();
    
    await supabase
      .from("bookings")
      .update({ 
        payment_gateway_ref: hitpayData.id,
        payment_url: hitpayData.url 
      })
      .eq("id", booking_id);

    return new Response(
      JSON.stringify({ 
        success: true,
        payment_url: hitpayData.url,
        payment_id: hitpayData.id 
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }
    );

  } catch (error) {
    console.error("Payment creation error:", error);
    return new Response(
      JSON.stringify({ success: false, error: error.message }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
    );
  }
});
