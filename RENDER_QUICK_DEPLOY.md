# ⚡ Quick Deploy to Render - 5 Minutes

Deploy Eden M-KOPA platform to Render in 5 minutes!

---

## 🚀 One-Click Deployment

### Step 1: Click Deploy Button (1 minute)

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/sammysam254/edenlock)

This will:
- ✅ Create all 4 services automatically
- ✅ Set up build and start commands
- ✅ Configure health checks

---

### Step 2: Add Environment Variables (2 minutes)

After services are created, add these variables:

#### Dashboard Service
```
NEXT_PUBLIC_SUPABASE_URL=https://xrmriwtedyaqzwxouyfx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_anon_key_here
```

#### Blockchain Listener
```
BLOCKCHAIN_URL=https://eden-blockchain-server.onrender.com
SUPABASE_URL=https://xrmriwtedyaqzwxouyfx.supabase.co
SUPABASE_SERVICE_KEY=your_service_key_here
```

---

### Step 3: Wait for Deployment (2 minutes)

Watch the logs as Render:
- ✅ Builds all services
- ✅ Installs dependencies
- ✅ Starts services
- ✅ Runs health checks

---

## ✅ Verify Deployment

### Test Dashboard
```
https://eden-dashboard.onrender.com
```
Should show Eden Dashboard homepage

### Test Blockchain API
```
https://eden-blockchain-server.onrender.com/api/info
```
Should return JSON with blockchain info

### Test Super Admin
```
https://eden-dashboard.onrender.com/super-admin
```
Should show login page

### Test Administrator
```
https://eden-dashboard.onrender.com/admin
```
Should show dashboard

---

## 🎉 Done!

Your Eden platform is live!

**URLs:**
- Dashboard: `https://eden-dashboard.onrender.com`
- Super Admin: `https://eden-dashboard.onrender.com/super-admin`
- Administrator: `https://eden-dashboard.onrender.com/admin`
- Blockchain API: `https://eden-blockchain-server.onrender.com`

---

## 📱 Next Steps

1. **Create Super Admin** in Supabase
2. **Log in** to super admin dashboard
3. **Create administrators**
4. **Start enrolling customers!**

---

## 💰 Cost

**Free Tier:**
- All services free for 750 hours/month
- Services spin down after 15 minutes
- Perfect for testing

**Production:**
- Upgrade to Starter ($7/month per service)
- Always-on services
- No spin down delay

**Recommended:**
- Dashboard: Starter ($7/month)
- Blockchain: Starter ($7/month)
- Listeners: Free
- **Total: $14/month**

---

## 🆘 Need Help?

See full guide: `RENDER_COMPLETE_DEPLOYMENT.md`

---

**Quick Deploy Version:** 1.0.0  
**Time Required:** 5 minutes  
**Difficulty:** Easy ✅
