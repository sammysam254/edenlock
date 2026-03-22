# 🚀 Render Single Service Deployment Guide

Deploy the ENTIRE Eden platform (Dashboard + Blockchain + Listener) in ONE web service!

---

## ✨ Benefits of Single Service Deployment

- ✅ **Lower Cost** - Only $7/month instead of $21/month
- ✅ **Simpler Setup** - One service to manage
- ✅ **Faster Communication** - Services communicate via localhost
- ✅ **Easier Monitoring** - One set of logs to check

---

## 📋 What Gets Deployed

In this single service, you get:
1. **Next.js Dashboard** (Port 3000) - Frontend
2. **Blockchain Server** (Port 5000) - Payment API
3. **Blockchain Listener** (Background) - Payment monitoring

All running together in one container!

---

## 🚀 Deployment Steps

### Step 1: Go to Render Dashboard

1. Visit https://dashboard.render.com
2. Click **"New +"** → **"Web Service"**
3. Connect your GitHub repository: `sammysam254/edenlock`

---

### Step 2: Configure Service

**Basic Settings:**
```
Name: eden-platform
Region: Oregon (or closest to you)
Branch: main
Root Directory: (leave empty)
Environment: Docker
```

**Build & Deploy:**
```
Dockerfile Path: ./Dockerfile
Docker Command: (leave empty - uses CMD from Dockerfile)
```

---

### Step 3: Add Environment Variables

Click **"Advanced"** → **"Add Environment Variable"**

Add these variables:

```bash
# Node.js Configuration
NODE_VERSION=18.17.0
NODE_ENV=production
PORT=3000

# Python Configuration
PYTHON_VERSION=3.11.0
BLOCKCHAIN_PORT=5000
SYNC_INTERVAL=15

# Supabase Configuration (REQUIRED)
NEXT_PUBLIC_SUPABASE_URL=https://xrmriwtedyaqzwxouyfx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_URL=https://xrmriwtedyaqzwxouyfx.supabase.co
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Blockchain Configuration
BLOCKCHAIN_URL=http://localhost:5000
```

**⚠️ Important:** Replace the Supabase keys with your actual keys!

---

### Step 4: Deploy

1. Click **"Create Web Service"**
2. Render will:
   - ✅ Clone your repository
   - ✅ Build Docker image
   - ✅ Install Node.js dependencies
   - ✅ Build Next.js app
   - ✅ Install Python dependencies
   - ✅ Start all services
3. Wait 5-10 minutes for deployment

---

## 📊 Monitoring Deployment

### Watch Build Logs

In the Render dashboard, click on your service and watch the logs:

```
🔨 Building Eden Platform...
📦 Building Dashboard...
✓ Next.js build complete
🐍 Installing Backend Dependencies...
✓ Backend dependencies installed
⛓️ Installing Blockchain Dependencies...
✓ Blockchain dependencies installed
✅ Build Complete!

🚀 Starting Eden Platform...
📦 Starting Blockchain Server on port 5000...
🔄 Starting Blockchain Listener...
🌐 Starting Dashboard on port 3000...
✓ All services running!
```

---

## ✅ Verify Deployment

### Test Dashboard
```
https://eden-platform.onrender.com
```
Should show: Eden Dashboard homepage

### Test Super Admin
```
https://eden-platform.onrender.com/super-admin
```
Should show: Super Admin login

### Test Administrator
```
https://eden-platform.onrender.com/admin
```
Should show: Administrator dashboard

### Test Blockchain API
```
https://eden-platform.onrender.com:5000/api/info
```
Should return: JSON with blockchain info

---

## 🔧 Service URLs

After deployment, your URLs will be:

```
Main Dashboard:
https://eden-platform.onrender.com

Super Admin:
https://eden-platform.onrender.com/super-admin

Administrator:
https://eden-platform.onrender.com/admin

Blockchain API:
http://localhost:5000/api/info (internal)
```

---

## 💰 Pricing

### Free Tier
- ✅ 750 hours/month free
- ⚠️ Spins down after 15 minutes of inactivity
- ⚠️ 30-60 second cold start

### Starter Plan ($7/month)
- ✅ Always on (no spin down)
- ✅ Instant response
- ✅ 512 MB RAM
- ✅ 0.5 CPU
- ✅ Perfect for production

### Recommended
**Starter Plan** - $7/month for production use

---

## 🐛 Troubleshooting

### Issue: Build fails
**Check:**
1. Dockerfile syntax is correct
2. All dependencies in requirements.txt
3. Build logs for specific errors

**Solution:**
```bash
# Test locally first
docker build -t eden-test .
docker run -p 3000:3000 -p 5000:5000 eden-test
```

### Issue: Services not starting
**Check:**
1. Environment variables are set
2. Ports 3000 and 5000 are not conflicting
3. Start script has execute permissions

**Solution:**
Check logs in Render dashboard for specific errors

### Issue: Dashboard loads but blockchain API fails
**Check:**
1. BLOCKCHAIN_URL is set to http://localhost:5000
2. Blockchain server started successfully
3. Port 5000 is not blocked

**Solution:**
Check service logs for blockchain server errors

### Issue: Supabase connection fails
**Check:**
1. SUPABASE_URL is correct
2. SUPABASE_SERVICE_KEY is correct (not anon key)
3. Supabase project is active

**Solution:**
Verify keys in Supabase dashboard → Settings → API

---

## 📱 Update Android App

After deployment, update your Android provisioning QR code:

Edit `android/provisioning/provisioning.json`:
```json
{
  "android.app.extra.PROVISIONING_ADMIN_EXTRAS_BUNDLE": {
    "supabase_url": "https://xrmriwtedyaqzwxouyfx.supabase.co",
    "supabase_key": "your_anon_key",
    "dashboard_url": "https://eden-platform.onrender.com"
  }
}
```

---

## 🔄 Continuous Deployment

Render automatically redeploys when you push to GitHub:

```bash
# Make changes
git add .
git commit -m "Update feature"
git push origin main

# Render automatically rebuilds and redeploys
```

---

## 📊 Monitoring

### View Logs
1. Go to service in Render dashboard
2. Click **"Logs"** tab
3. See real-time logs from all services

### View Metrics
1. Go to service in Render dashboard
2. Click **"Metrics"** tab
3. View CPU, Memory, Request metrics

### Set Up Alerts
1. Go to service settings
2. Enable email notifications
3. Get notified of deployment failures

---

## 🎯 Production Checklist

Before going live:

- [ ] Service deployed and showing "Live"
- [ ] Environment variables configured
- [ ] Dashboard accessible
- [ ] Super admin page loads
- [ ] Administrator page loads
- [ ] Blockchain API responding
- [ ] Database schema deployed in Supabase
- [ ] RLS policies enabled
- [ ] First super admin created
- [ ] Test administrator created
- [ ] Test customer enrolled
- [ ] Test device activated
- [ ] Test payment processed
- [ ] Monitoring enabled
- [ ] Custom domain configured (optional)

---

## 🌐 Custom Domain (Optional)

### Add Custom Domain

1. Go to service in Render
2. Click **"Settings"** → **"Custom Domain"**
3. Add domain: `app.edenservices.ke`
4. Add DNS record:
```
Type: CNAME
Name: app
Value: eden-platform.onrender.com
```
5. Wait for SSL certificate (automatic)

---

## 🎉 Deployment Complete!

Your Eden M-KOPA platform is now live on Render!

**Access Your Platform:**
- Dashboard: https://eden-platform.onrender.com
- Super Admin: https://eden-platform.onrender.com/super-admin
- Administrator: https://eden-platform.onrender.com/admin

**Cost:** $7/month (Starter plan recommended)

**Next Steps:**
1. Create your first super admin in Supabase
2. Log in to super admin dashboard
3. Create administrators
4. Start enrolling customers!

---

## 📞 Support

**Render Support:**
- Docs: https://render.com/docs
- Community: https://community.render.com
- Status: https://status.render.com

**Eden Support:**
- GitHub: https://github.com/sammysam254/edenlock/issues
- Email: support@edenservices.ke

---

**Deployment Guide Version:** 2.0.0  
**Last Updated:** March 22, 2026  
**Deployment Type:** Single Web Service (Docker)  
**Cost:** $7/month (Starter) or Free (with spin down)  
**Status:** Production Ready ✅
