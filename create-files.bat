@echo off
setlocal EnableDelayedExpansion

echo Creating directories...
mkdir supabase\migrations 2>nul
mkdir supabase\functions\payment-webhook 2>nul
mkdir frontend\src 2>nul

echo Creating SQL migration...
(
echo -- Migration: Initial schema
echo CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
echo.
echo -- Studios
echo CREATE TABLE studios ^(
echo     id UUID PRIMARY KEY DEFAULT uuid_generate_v4^(^),
echo     name TEXT NOT NULL,
echo     description TEXT,
echo     capacity INTEGER DEFAULT 1,
echo     hourly_rate NUMERIC^(10,2^) NOT NULL,
echo     amenities TEXT[] DEFAULT '{}',
echo     is_active BOOLEAN DEFAULT true,
echo     created_at TIMESTAMPTZ DEFAULT NOW^(^)
echo ^);
echo.
echo -- Bookings
echo CREATE TABLE bookings ^(
echo     id UUID PRIMARY KEY DEFAULT uuid_generate_v4^(^),
echo     user_id UUID REFERENCES auth.users^(id^) ON DELETE CASCADE,
echo     studio_id UUID REFERENCES studios^(id^) ON DELETE CASCADE,
echo     booking_date DATE NOT NULL,
echo     start_time TIME NOT NULL,
echo     end_time TIME NOT NULL,
echo     duration_hours NUMERIC^(4,2^) NOT NULL,
echo     amount NUMERIC^(10,2^) NOT NULL,
echo     status TEXT DEFAULT 'pending_payment',
echo     payment_ref TEXT,
echo     payment_status TEXT DEFAULT 'pending',
echo     created_at TIMESTAMPTZ DEFAULT NOW^(^),
echo     updated_at TIMESTAMPTZ DEFAULT NOW^(^)
echo ^);
echo.
echo -- RLS
echo ALTER TABLE studios ENABLE ROW LEVEL SECURITY;
echo ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
echo.
echo CREATE POLICY "Studios public read" ON studios FOR SELECT USING ^(is_active = true^);
echo CREATE POLICY "Users own bookings" ON bookings FOR ALL USING ^(auth.uid^(^) = user_id^);
echo.
echo -- Functions
echo CREATE OR REPLACE FUNCTION check_availability^(
echo     p_studio_id UUID,
echo     p_date DATE,
echo     p_start TIME,
echo     p_end TIME
echo ^) RETURNS BOOLEAN AS $$
echo BEGIN
echo     RETURN NOT EXISTS ^(
echo         SELECT 1 FROM bookings
echo         WHERE studio_id = p_studio_id
echo         AND booking_date = p_date
echo         AND status NOT IN ^('cancelled', 'refunded'^)
echo         AND ^(start_time, end_time^) OVERLAPS ^(p_start, p_end^)
echo     ^);
echo END;
echo $$ LANGUAGE plpgsql SECURITY DEFINER;
echo.
echo -- Seed data
echo INSERT INTO studios ^(name, description, capacity, hourly_rate, amenities^) VALUES
echo     ^('Station A', 'Makeup station with professional lighting', 8, 80, ARRAY['Mixing Console', 'Keyboard', 'Drums']^),
echo     ^('Station B', 'Makeup station with professional lighting', 4, 60, ARRAY['DSLR', 'Strobes', 'Backdrops']^),
echo     ^('Studio Suite', 'Professional Studio with green screen', 6, 75, ARRAY['4K Camera', 'Green Screen', 'Lighting']^);
) > supabase\migrations\001_initial.sql

echo Creating HTML...
(
echo ^<!DOCTYPE html^>
echo ^<html lang="en"^>
echo ^<head^>
echo     ^<meta charset="UTF-8"^>
echo     ^<meta name="viewport" content="width=device-width, initial-scale=1.0"^>
echo     ^<title^>Leish Studios - Professional Studio Booking^</title^>
echo     ^<script src="https://cdn.tailwindcss.com"^>^</script^>
echo     ^<script src="https://unpkg.com/@supabase/supabase-js@2"^>^</script^>
echo     ^<link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700^&display=swap" rel="stylesheet"^>
echo     ^<style^>body{font-family:'Inter',sans-serif}^</style^>
echo ^</head^>
echo ^<body class="bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 min-h-screen text-white"^>
echo     ^<div id="app"^>^</div^>
echo     ^<script src="src/app.js"^>^</script^>
echo ^</body^>
echo ^</html^>
) > frontend\index.html

echo Creating JavaScript...
(
echo const SUPABASE_URL = 'YOUR_SUPABASE_URL';
echo const SUPABASE_ANON_KEY = 'YOUR_SUPABASE_ANON_KEY';
echo const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
echo let currentUser = null, studios = [], selectedStudio = null, bookingData = {};
echo document.addEventListener('DOMContentLoaded', init);
echo async function init() { await loadStudios(); render(); const { data: { session } } = await supabase.auth.getSession(); if (session) { currentUser = session.user; render(); } }
echo async function loadStudios() { const { data } = await supabase.from('studios').select('*').eq('is_active', true); if (data) studios = data; }
echo function render() { const app = document.getElementById('app'); if (!currentUser) { app.innerHTML = renderAuth(); attachAuthListeners(); } else if (!selectedStudio) { app.innerHTML = renderStudioList(); } else if (!bookingData.date) { app.innerHTML = renderBookingForm(); attachBookingListeners(); } else { app.innerHTML = renderPayment(); } }
echo function renderAuth() { return `^<div class="min-h-screen flex items-center justify-center p-4"^>^<div class="bg-white/10 backdrop-blur-lg rounded-2xl p-8 w-full max-w-md border border-white/20"^>^<h1 class="text-3xl font-bold mb-2 text-center"^>Leish Studios^</h1^>^<p class="text-gray-400 text-center mb-8"^>Professional Creative Spaces^</p^>^<form id="authForm" class="space-y-4"^>^<input type="email" id="email" placeholder="Email" required class="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:border-purple-500"^>^<input type="password" id="password" placeholder="Password" required class="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:border-purple-500"^>^<button type="submit" class="w-full py-3 bg-gradient-to-r from-purple-600 to-pink-600 rounded-lg font-semibold hover:opacity-90 transition"^>Continue^</button^>^</form^>^</div^>^</div^>`; }
echo function renderStudioList() { return `^<div class="max-w-6xl mx-auto px-4 py-8"^>^<header class="flex justify-between items-center mb-8"^>^<h1 class="text-2xl font-bold"^>Select Studio^</h1^>^<button onclick="logout()" class="text-sm text-gray-400 hover:text-white"^>Logout^</button^>^</header^>^<div class="grid md:grid-cols-2 gap-6"^>${studios.map(s =^> `^<div onclick="selectStudio('${s.id}')" class="bg-white/10 backdrop-blur rounded-xl p-6 border border-white/20 cursor-pointer hover:border-purple-500 transition group"^>^<div class="flex justify-between items-start mb-4"^>^<h3 class="text-xl font-semibold group-hover:text-purple-400 transition"^>${s.name}^</h3^>^<span class="text-2xl font-bold text-purple-400"^>RM${s.hourly_rate}^</span^>^</div^>^<p class="text-gray-400 mb-4"^>${s.description}^</p^>^<div class="flex gap-2 flex-wrap"^>${(s.amenities ^|^| []).map(a =^> `^<span class="text-xs bg-white/10 px-2 py-1 rounded"^>${a}^</span^>`).join('')}^</div^>^</div^>`).join('')}^</div^>^</div^>`; }
echo function renderBookingForm() { const tomorrow = new Date(); tomorrow.setDate(tomorrow.getDate() + 1); const minDate = tomorrow.toISOString().split('T')[0]; return `^<div class="max-w-2xl mx-auto px-4 py-8"^>^<button onclick="backToStudios()" class="text-gray-400 hover:text-white mb-4"^>← Back^</button^>^<h2 class="text-2xl font-bold mb-6"^>Book ${selectedStudio.name}^</h2^>^<form id="bookingForm" class="space-y-6 bg-white/10 backdrop-blur rounded-xl p-6 border border-white/20"^>^<div^>^<label class="block text-sm text-gray-400 mb-2"^>Date^</label^>^<input type="date" id="date" min="${minDate}" required class="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white focus:border-purple-500 focus:outline-none"^>^</div^>^<div class="grid grid-cols-2 gap-4"^>^<div^>^<label class="block text-sm text-gray-400 mb-2"^>Start Time^</label^>^<select id="startTime" required class="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white focus:border-purple-500 focus:outline-none"^>${generateTimeOptions()}^</select^>^</div^>^<div^>^<label class="block text-sm text-gray-400 mb-2"^>Duration^</label^>^<select id="duration" class="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white focus:border-purple-500 focus:outline-none"^>${[1,2,3,4,5,6,7,8].map(h =^> `^<option value="${h}"^>${h} hour${h^>1?'s':''}^</option^>`).join('')}^</select^>^</div^>^</div^>^<div class="p-4 bg-purple-500/20 rounded-lg border border-purple-500/30"^>^<div class="flex justify-between items-center"^>^<span class="text-gray-400"^>Total^</span^>^<span class="text-2xl font-bold" id="totalPrice"^>RM${selectedStudio.hourly_rate}^</span^>^</div^>^</div^>^<button type="submit" class="w-full py-4 bg-gradient-to-r from-purple-600 to-pink-600 rounded-lg font-semibold hover:opacity-90 transition"^>Proceed to Payment^</button^>^</form^>^</div^>`; }
echo function renderPayment() { return `^<div class="max-w-2xl mx-auto px-4 py-8 text-center"^>^<div class="bg-white/10 backdrop-blur rounded-xl p-8 border border-white/20"^>^<h2 class="text-2xl font-bold mb-4"^>Complete Payment^</h2^>^<p class="text-gray-400 mb-6"^>Booking ref: ${bookingData.ref}^</p^>^<div class="text-4xl font-bold text-purple-400 mb-8"^>RM${bookingData.amount}^</div^>^<button onclick="processPayment()" class="w-full py-4 bg-gradient-to-r from-purple-600 to-pink-600 rounded-lg font-semibold hover:opacity-90 transition mb-4"^>Pay Now^</button^>^<button onclick="reset()" class="text-gray-400 hover:text-white"^>Cancel^</button^>^</div^>^</div^>`; }
echo function generateTimeOptions() { let html = ''; for (let h = 9; h ^<= 21; h++) { const time = `${h.toString().padStart(2,'0')}:00`; html += `^<option value="${time}"^>${time}^</option^>`; } return html; }
echo function attachAuthListeners() { document.getElementById('authForm').addEventListener('submit', async (e) => { e.preventDefault(); const email = document.getElementById('email').value; const password = document.getElementById('password').value; let { data, error } = await supabase.auth.signInWithPassword({ email, password }); if (error) { ({ data, error } = await supabase.auth.signUp({ email, password })); } if (!error ^&^& data.user) { currentUser = data.user; render(); } else { alert(error.message); } }); }
echo function attachBookingListeners() { document.getElementById('bookingForm').addEventListener('submit', async (e) => { e.preventDefault(); const date = document.getElementById('date').value; const startTime = document.getElementById('startTime').value; const duration = parseInt(document.getElementById('duration').value); const amount = selectedStudio.hourly_rate * duration; const [h, m] = startTime.split(':').map(Number); const endHour = h + duration; const endTime = `${endHour.toString().padStart(2,'0')}:${m.toString().padStart(2,'0')}`; const { data: available } = await supabase.rpc('check_availability', { p_studio_id: selectedStudio.id, p_date: date, p_start: startTime, p_end: endTime }); if (!available) { alert('Time slot not available.'); return; } bookingData = { date, startTime, endTime, duration, amount, ref: 'LS' + Date.now() }; render(); }); document.getElementById('duration').addEventListener('change', (e) => { const total = selectedStudio.hourly_rate * parseInt(e.target.value); document.getElementById('totalPrice').textContent = 'RM' + total; }); }
echo window.selectStudio = (id) => { selectedStudio = studios.find(s =^> s.id === id); render(); };
echo window.backToStudios = () => { selectedStudio = null; bookingData = {}; render(); };
echo window.logout = async () => { await supabase.auth.signOut(); currentUser = null; selectedStudio = null; bookingData = {}; render(); };
echo window.reset = () => { bookingData = {}; render(); };
echo window.processPayment = async () => { const { data: booking, error } = await supabase.from('bookings').insert({ user_id: currentUser.id, studio_id: selectedStudio.id, booking_date: bookingData.date, start_time: bookingData.startTime, end_time: bookingData.endTime, duration_hours: bookingData.duration, amount: bookingData.amount, status: 'pending_payment', payment_ref: bookingData.ref }).select().single(); if (error) { alert('Booking failed: ' + error.message); return; } alert('Redirecting to payment...'); };
) > frontend\src\app.js

echo Creating Edge Function...
(
echo import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
echo import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
echo const corsHeaders = { "Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type" };
echo serve(async (req) => { if (req.method === "OPTIONS") { return new Response(null, { headers: corsHeaders }); } try { const supabase = createClient(Deno.env.get("SUPABASE_URL") ^|^| "", Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ^|^| ""); const payload = await req.json(); if (payload.status === 'completed' ^|^| payload.status === 'paid') { await supabase.from('bookings').update({ status: 'confirmed', payment_status: 'paid', updated_at: new Date().toISOString() }).eq('payment_ref', payload.reference_id); } return new Response(JSON.stringify({ success: true }), { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 200 }); } catch (error) { return new Response(JSON.stringify({ error: error.message }), { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }); } });
) > supabase\functions\payment-webhook\index.ts

echo Creating config files...
(
echo name = "leish-studios"
echo compatibility_date = "2024-01-01"
echo [site]
echo bucket = "./frontend"
) > wrangler.toml

(
echo { "name": "leish-studio", "scripts": { "deploy": "wrangler pages deploy frontend --project-name=leish-studios" }, "devDependencies": { "wrangler": "^3.0.0" } }
) > package.json

echo Done! Replace YOUR_SUPABASE_URL and YOUR_SUPABASE_ANON_KEY in frontend\src\app.js
pause