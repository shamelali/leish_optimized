# src/app.js
@"
const SUPABASE_URL = 'https://zpsjsbrssadvwrlgggev.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpwc2pzYnJzc2FkdndybGdnZ2V2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk4MzA4OTgsImV4cCI6MjA4NTQwNjg5OH0.EKfNUVaoUp58XDUVW43xswBdPZqgIMBs-4BmGaarm8Q';
// In your app.js - Collection ID acts as public identifier
// No public key needed for HitPay redirect
// You'll create payment sessions via Edge Function
const PAYMENT_COLLECTION_ID = 'your-collection-id'; // Public
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// State
let currentUser = null;
let studios = [];
let selectedStudio = null;
let bookingData = {};

// Initialize
document.addEventListener('DOMContentLoaded', init);

async function init() {
    await loadStudios();
    render();
    
    // Check auth
    const { data: { session } } = await supabase.auth.getSession();
    if (session) {
        currentUser = session.user;
        render();
    }
}

async function loadStudios() {
    const { data, error } = await supabase
        .from('studios')
        .select('*')
        .eq('is_active', true);
    
    if (!error) studios = data || [];
}

function render() {
    const app = document.getElementById('app');
    
    if (!currentUser) {
        app.innerHTML = renderAuth();
        attachAuthListeners();
    } else if (!selectedStudio) {
        app.innerHTML = renderStudioList();
        attachStudioListeners();
    } else if (!bookingData.date) {
        app.innerHTML = renderBookingForm();
        attachBookingListeners();
    } else {
        app.innerHTML = renderPayment();
    }
}

function renderAuth() {
    return \`
        <div class="min-h-screen flex items-center justify-center p-4">
            <div class="bg-white/10 backdrop-blur-lg rounded-2xl p-8 w-full max-w-md border border-white/20">
                <h1 class="text-3xl font-bold mb-2 text-center">Leish Studios</h1>
                <p class="text-gray-400 text-center mb-8">Professional Creative Spaces</p>
                
                <form id="authForm" class="space-y-4">
                    <input type="email" id="email" placeholder="Email" required
                        class="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:border-purple-500">
                    <input type="password" id="password" placeholder="Password" required
                        class="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white placeholder-gray-400 focus:outline-none focus:border-purple-500">
                    <button type="submit" class="w-full py-3 bg-gradient-to-r from-purple-600 to-pink-600 rounded-lg font-semibold hover:opacity-90 transition">
                        Continue
                    </button>
                </form>
                
                <p class="text-center mt-4 text-sm text-gray-400">
                    No account? One will be created automatically
                </p>
            </div>
        </div>
    \`;
}

function renderStudioList() {
    return \`
        <div class="max-w-6xl mx-auto px-4 py-8">
            <header class="flex justify-between items-center mb-8">
                <h1 class="text-2xl font-bold">Select Studio</h1>
                <button onclick="logout()" class="text-sm text-gray-400 hover:text-white">Logout</button>
            </header>
            
            <div class="grid md:grid-cols-2 gap-6">
                \${studios.map(s => \`
                    <div onclick="selectStudio('\${s.id}')" class="bg-white/10 backdrop-blur rounded-xl p-6 border border-white/20 cursor-pointer hover:border-purple-500 transition group">
                        <div class="flex justify-between items-start mb-4">
                            <h3 class="text-xl font-semibold group-hover:text-purple-400 transition">\${s.name}</h3>
                            <span class="text-2xl font-bold text-purple-400">RM\${s.hourly_rate}</span>
                        </div>
                        <p class="text-gray-400 mb-4">\${s.description}</p>
                        <div class="flex gap-2 flex-wrap">
                            \${(s.amenities || []).map(a => \`<span class="text-xs bg-white/10 px-2 py-1 rounded">\${a}</span>\`).join('')}
                        </div>
                    </div>
                \`).join('')}
            </div>
        </div>
    \`;
}

function renderBookingForm() {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const minDate = tomorrow.toISOString().split('T')[0];
    
    return \`
        <div class="max-w-2xl mx-auto px-4 py-8">
            <button onclick="backToStudios()" class="text-gray-400 hover:text-white mb-4">← Back to Studios</button>
            
            <h2 class="text-2xl font-bold mb-6">Book \${selectedStudio.name}</h2>
            
            <form id="bookingForm" class="space-y-6 bg-white/10 backdrop-blur rounded-xl p-6 border border-white/20">
                <div>
                    <label class="block text-sm text-gray-400 mb-2">Date</label>
                    <input type="date" id="date" min="\${minDate}" required
                        class="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white focus:border-purple-500 focus:outline-none">
                </div>
                
                <div class="grid grid-cols-2 gap-4">
                    <div>
                        <label class="block text-sm text-gray-400 mb-2">Start Time</label>
                        <select id="startTime" required class="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white focus:border-purple-500 focus:outline-none">
                            \${generateTimeOptions()}
                        </select>
                    </div>
                    <div>
                        <label class="block text-sm text-gray-400 mb-2">Duration</label>
                        <select id="duration" class="w-full px-4 py-3 bg-white/10 border border-white/20 rounded-lg text-white focus:border-purple-500 focus:outline-none">
                            \${[1,2,3,4,5,6,7,8].map(h => \`<option value="\${h}">\${h} hour\${h>1?'s':''}</option>\`).join('')}
                        </select>
                    </div>
                </div>
                
                <div class="p-4 bg-purple-500/20 rounded-lg border border-purple-500/30">
                    <div class="flex justify-between items-center">
                        <span class="text-gray-400">Total</span>
                        <span class="text-2xl font-bold" id="totalPrice">RM\${selectedStudio.hourly_rate}</span>
                    </div>
                </div>
                
                <button type="submit" class="w-full py-4 bg-gradient-to-r from-purple-600 to-pink-600 rounded-lg font-semibold hover:opacity-90 transition">
                    Proceed to Payment
                </button>
            </form>
        </div>
    \`;
}

function renderPayment() {
    return \`
        <div class="max-w-2xl mx-auto px-4 py-8 text-center">
            <div class="bg-white/10 backdrop-blur rounded-xl p-8 border border-white/20">
                <h2 class="text-2xl font-bold mb-4">Complete Payment</h2>
                <p class="text-gray-400 mb-6">Booking ref: \${bookingData.ref}</p>
                
                <div class="text-4xl font-bold text-purple-400 mb-8">RM\${bookingData.amount}</div>
                
                <button onclick="processPayment()" class="w-full py-4 bg-gradient-to-r from-purple-600 to-pink-600 rounded-lg font-semibold hover:opacity-90 transition mb-4">
                    Pay with HitPay/Billplz
                </button>
                
                <button onclick="reset()" class="text-gray-400 hover:text-white">Cancel</button>
            </div>
        </div>
    \`;
}

// Helper functions
function generateTimeOptions() {
    let html = '';
    for (let h = 9; h <= 21; h++) {
        const time = \`\${h.toString().padStart(2,'0')}:00\`;
        html += \`<option value="\${time}">\${time}</option>\`;
    }
    return html;
}

function attachAuthListeners() {
    document.getElementById('authForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;
        
        // Try sign in first, then sign up
        let { data, error } = await supabase.auth.signInWithPassword({ email, password });
        
        if (error) {
            ({ data, error } = await supabase.auth.signUp({ email, password }));
        }
        
        if (!error && data.user) {
            currentUser = data.user;
            render();
        } else {
            alert(error.message);
        }
    });
}

function attachStudioListeners() {
    // Click handlers in HTML
}

function attachBookingListeners() {
    document.getElementById('bookingForm').addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const date = document.getElementById('date').value;
        const startTime = document.getElementById('startTime').value;
        const duration = parseInt(document.getElementById('duration').value);
        const amount = selectedStudio.hourly_rate * duration;
        
        // Calculate end time
        const [h, m] = startTime.split(':').map(Number);
        const endHour = h + duration;
        const endTime = \`\${endHour.toString().padStart(2,'0')}:\${m.toString().padStart(2,'0')}\`;
        
        // Check availability
        const { data: available } = await supabase.rpc('check_availability', {
            p_studio_id: selectedStudio.id,
            p_date: date,
            p_start: startTime,
            p_end: endTime
        });
        
        if (!available) {
            alert('Time slot not available. Please select another time.');
            return;
        }
        
        bookingData = { date, startTime, endTime, duration, amount, ref: 'LS' + Date.now() };
        render();
    });
    
    document.getElementById('duration').addEventListener('change', (e) => {
        const total = selectedStudio.hourly_rate * parseInt(e.target.value);
        document.getElementById('totalPrice').textContent = 'RM' + total;
    });
}

// Global functions
window.selectStudio = (id) => {
    selectedStudio = studios.find(s => s.id === id);
    render();
};

window.backToStudios = () => {
    selectedStudio = null;
    bookingData = {};
    render();
};

window.logout = async () => {
    await supabase.auth.signOut();
    currentUser = null;
    selectedStudio = null;
    bookingData = {};
    render();
};

window.reset = () => {
    bookingData = {};
    render();
};

window.processPayment = async () => {
  // Create booking first
  const { data: booking, error } = await supabase
    .from('bookings')
    .insert({...})
    .select()
    .single();
  
  if (error) {
    alert('Booking failed: ' + error.message);
    return;
  }
  
  // Call Edge Function to create payment
  const { data: payment } = await supabase.functions.invoke('create-payment', {
    body: {
      booking_id: booking.id,
      amount: bookingData.amount,
      email: currentUser.email,
      name: bookingData.name || currentUser.email
    }
  });
  
  // Redirect to HitPay
  window.location.href = payment.payment_url;
};
"@ | Out-File -FilePath "frontend\src\app.js" -Encoding UTF8