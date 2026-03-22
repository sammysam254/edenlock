# 🚀 Complete Render Deployment Guide - Eden M-KOPA Platform

Deploy the entire Eden platform (Dashboard + Backend + Blockchain) on Render.com

---

## 📋 Prerequisites

1. **Render Account** - Sign up at https://render.com
2. **GitHub Repository** - https://github.com/sammysam254/edenlock
3. **Supabase Account** - Database already set up
4. **Environment Variables** - Supabase URL and keys

---

## 🎯 Deployment Overview

We'll deploy 4 services on Render:
1. **Dashboard** (Next.js Web Service) - Frontend
2. **Blockchain Server** (Python Web Service) - Custom blockchain API
3. **Blockchain Listener** (Python Background Worker) - Payment monitoring
4. **Web3 Listener** (Python Background Worker) - Optional for Polygon/BSC

---

## 🚀 Step-by-Step Deployment

### Step 1: Connect GitHub Repository

1. Go to https://dashboard.render.com
2. Click **"New +"** → **"Blueprint"**
3. Connect your GitHub account
4. Select repository: `sammysam254/edenlock`
5. Click **"Connect"**

Render will automatically detect the `render.yaml` file and create all services!

---

### Step 2: Configure Environment Variables

After services are created, configure each service:

#### 🌐 Dashboard Service (eden-dashboard)

Navigate to: Dashboard → Environment

Add these variables:
```
NEXT_PUBLIC_SUPABASE_URL=https://xrmriwtedyaqzwxouyfx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key_here
NODE_ENV=production
NODE_VERSION=18.17.0
```

#### 🔗 Blockchain Server (eden-blockchain-server)

Navigate to: Blockchain Server → Environment

Add these variables:
```
PORT=5000
BLOCKCHAIN_DIFFICULTY=2
PYTHON_VERSION=3.11.0
```

#### 🔄 Blockchain Listener (eden-blockchain-listener)

Navigate to: Blockchain Listener → Environment

Add these variables:
```
BLOCKCHAIN_URL=https://eden-blockchain-server.onrender.com
SUPABASE_URL=https://xrmriwtedyaqzwxouyfx.supabase.co
SUPABASE_SERVICE_KEY=your_supabase_service_role_key_here
SYNC_INTERVAL=15
PYTHON_VERSION=3.11.0
```

#### 🌍 Web3 Listener (eden-web3-listener) - Optional

Navigate to: Web3 Listener → Environment

Add these variables:
```
RPC_URL=https://polygon-rpc.com
CONTRACT_ADDRESS=your_contract_address_here
CHAIN_ID=137
SUPABASE_URL=https://xrmriwtedyaqzwxouyfx.supabase.co
SUPABASE_SERVICE_KEY=your_supabase_service_role_key_here
PYTHON_VERSION=3.11.0
```

---

### Step 3: Deploy Services

1. **Automatic Deployment**
   - Render will automatically build and deploy all services
   - Wait for all services to show "Live" status (5-10 minutes)

2. **Manual Deployment** (if needed)
   - Go to each service
   - Click **"Manual Deploy"** → **"Deploy latest commit"**

---

### Step 4: Verify Deployments

#### ✅ Dashboard
```
URL: https://eden-dashboard.onrender.com
Test: Open in browser, should see Eden Dashboard homepage
```

#### ✅ Blockchain Server
```
URL: https://eden-blockchain-server.onrender.com/api/info
Test: Should return JSON with blockchain info
```

#### ✅ Blockchain Listener
```
Check: Logs should show "Eden Blockchain Listener initialized"
```

#### ✅ Web3 Listener (if enabled)
```
Check: Logs should show "Eden Listener initialized"
```

---

## 🔧 Service URLs

After deployment, you'll have these URLs:

```
Dashboard:
https://eden-dashboard.onrender.com

Super Admin:
https://eden-dashboard.onrender.com/super-admin

Administrator:
https://eden-dashboard.onrender.com/admin

Blockchain API:
https://eden-blockchain-server.onrender.com/api/info
https://eden-blockchain-server.onrender.com/api/chain
https://eden-blockchain-server.onrender.com/api/mine
```

---

## 📱 Update Android App

After deployment, update the Android provisioning QR code:

1. Edit `android/provisioning/provisioning.json`
2. Update these fields:
```json
{
  "android.app.extra.PROVISIONING_ADMIN_EXTRAS_BUNDLE": {
    "supabase_url": "https://xrmriwtedyaqzwxouyfx.supabase.co",
    "supabase_key": "your_supabase_anon_key",
    "blockchain_url": "https://eden-blockchain-server.onrender.com"
  }
}
```

---

## 🔄 Continuous Deployment

Render automatically deploys when you push to GitHub:

```bash
# Make changes
git add .
git commit -m "Update feature"
git push origin main

# Render automatically deploys all services
```

---

## 💰 Render Pricing

### Free Tier (Starter Plan)
- **Web Services**: Free for 750 hours/month
- **Background Workers**: Free for 750 hours/month
- **Limitations**: 
  - Services spin down after 15 minutes of inactivity
  - Spin up takes 30-60 seconds on first request

### Paid Plans
- **Starter**: $7/month per service (always on)
- **Standard**: $25/month per service (more resources)
- **Pro**: $85/month per service (high performance)

### Recommended Setup
```
Dashboard: Starter ($7/month) - Always on for users
Blockchain Server: Starter ($7/month) - Always on
Blockchain Listener: Free - Can tolerate spin down
Web3 Listener: Free - Optional

Total: $14/month for production-ready setup
```

---

## 🐛 Troubleshooting

### Issue: Dashboard not loading
**Solution:**
1. Check environment variables are set
2. Check build logs for errors
3. Verify Supabase URL is correct

### Issue: Blockchain listener not syncing
**Solution:**
1. Check BLOCKCHAIN_URL points to blockchain server
2. Verify SUPABASE_SERVICE_KEY is correct
3. Check logs for connection errors

### Issue: Services spinning down
**Solution:**
1. Upgrade to Starter plan ($7/month)
2. Or set up a cron job to ping services every 10 minutes

### Issue: Build fails
**Solution:**
1. Check `render.yaml` syntax
2. Verify all dependencies in requirements.txt
3. Check build logs for specific errors

---

## 📊 Monitoring

### View Logs
1. Go to service in Render dashboard
2. Click **"Logs"** tab
3. View real-time logs

### View Metrics
1. Go to service in Render dashboard
2. Click **"Metrics"** tab
3. View CPU, Memory, Request metrics

### Set Up Alerts
1. Go to service settings
2. Enable email notifications
3. Set up Slack/Discord webhooks

---

## 🔒 Security Best Practices

### 1. Environment Variables
- ✅ Never commit `.env` files
- ✅ Use Render's environment variable management
- ✅ Rotate keys regularly

### 2. Supabase Security
- ✅ Use service role key only in backend
- ✅ Use anon key in frontend
- ✅ Enable RLS policies

### 3. API Security
- ✅ Add rate limiting
- ✅ Enable CORS properly
- ✅ Use HTTPS only

---

## 🚀 Production Checklist

Before going live:

- [ ] All services deployed and "Live"
- [ ] Environment variables configured
- [ ] Dashboard accessible at custom domain
- [ ] Blockchain server responding to API calls
- [ ] Blockchain listener syncing payments
- [ ] Database schema deployed in Supabase
- [ ] RLS policies enabled
- [ ] First super admin created
- [ ] Test administrator created
- [ ] Test customer enrolled
- [ ] Test device activated
- [ ] Test payment processed
- [ ] QR code provisioning tested
- [ ] Device lock/unlock tested
- [ ] Monitoring and alerts set up

---

## 🎯 Custom Domain Setup

### Add Custom Domain to Dashboard

1. Go to Dashboard service in Render
2. Click **"Settings"** → **"Custom Domain"**
3. Add your domain: `dashboard.edenservices.ke`
4. Add DNS records:
```
Type: CNAME
Name: dashboard
Value: eden-dashboard.onrender.com
```

5. Wait for SSL certificate (automatic)

---

## 📞 Support

### Render Support
- Documentation: https://render.com/docs
- Community: https://community.render.com
- Status: https://status.render.com

### Eden Support
- GitHub Issues: https://github.com/sammysam254/edenlock/issues
- Email: support@edenservices.ke

---

## 🎉 Deployment Complete!

Your Eden M-KOPA platform is now live on Render!

**Access Your Platform:**
- Dashboard: https://eden-dashboard.onrender.com
- Super Admin: https://eden-dashboard.onrender.com/super-admin
- Administrator: https://eden-dashboard.onrender.com/admin
- Blockchain API: https://eden-blockchain-server.onrender.com/api/info

**Next Steps:**
1. Create your first super admin in Supabase
2. Log in to super admin dashboard
3. Create administrators
4. Start enrolling customers!

---

**Deployment Guide Version:** 1.0.0  
**Last Updated:** March 22, 2026  
**Platform:** Render.com  
**Status:** Production Ready ✅
