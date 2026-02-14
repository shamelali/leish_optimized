
Action: file_editor create /app/leish-studio-complete/README.md --file-text "# Leish Studio - Render Deployment

## Quick Deploy Steps

### 1. Update GitHub
Replace your `frontend/index.html` with the content from `/app/leish-studio-complete/index.html`

### 2. Render Settings
- **Publish Directory**: `frontend`

### 3. Supabase Setup

#### A. Create Admin User
1. Go to **Supabase Dashboard** → **Authentication** → **Users**
2. Click **Add user** → **Create new user**
3. Enter:
   - Email: `leishtudio.main@gmail.com`
   - Password: `lindan95`
   - Check ✓ **Auto Confirm User**
4. Click **Create user**

#### B. Run SQL Setup
1. Go to **SQL Editor** in Supabase
2. Copy and run the SQL from `SUPABASE_SETUP.sql`

#### C. Create Storage Bucket
1. Go to **Storage** in Supabase
2. Click **New bucket**
3. Name: `images`
4. Check ✓ **Public bucket**
5. Click **Create bucket**

#### D. Add Storage Policies
In Storage → images bucket → Policies, add:

**Policy 1: Public Read**
- Name: `Allow public read`
- Allowed operation: SELECT
- Target roles: anon, authenticated
- Policy definition: `true`

**Policy 2: Admin Upload**
- Name: `Allow admin upload`
- Allowed operation: INSERT
- Target roles: authenticated  
- Policy definition: `(auth.jwt() ->> 'email') = 'leishtudio.main@gmail.com'`

**Policy 3: Admin Delete**
- Name: `Allow admin delete`
- Allowed operation: DELETE
- Target roles: authenticated
- Policy definition: `(auth.jwt() ->> 'email') = 'leishtudio.main@gmail.com'`

---

## Features Implemented

### User Features
- ✅ Google Sign-in (primary)
- ✅ Email/Password Sign-in
- ✅ Studio Booking
- ✅ Gallery Section (Station: 6 images, Studio: 6 images)
- ✅ User Dashboard with booking history

### Admin Features (yoursite.com/admin)
- ✅ Dashboard with stats
- ✅ Logo/Branding management
- ✅ Station A & B image management
- ✅ Upcoming Studio photo management
- ✅ Gallery management (add/delete images)
- ✅ View all bookings

### Admin Login
- Email: `leishtudio.main@gmail.com`
- Password: `lindan95`
"
Observation: Create successful: /app/leish-studio-complete/README.md
