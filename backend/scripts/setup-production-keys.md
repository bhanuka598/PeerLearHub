# Production Admin Key Setup Guide

## 🚀 Production Deployment Admin Key Setup

### **Important Production Security Principles:**

1. **NEVER auto-generate keys in production**
2. **Keys must be pre-generated and securely stored**
3. **Use environment variables or secret management**
4. **Never commit actual keys to version control**
5. **Rotate keys periodically**

---

## 📋 Production Setup Steps

### **Step 1: Generate Admin Key Locally**

```bash
cd backend
npm run generate-admin-key
```

This will give you a secure key like: `AbC123!@#xyz789$%^def456&*ghi`

### **Step 2: Set Environment Variable**

#### **Option A: Environment Variable (Recommended for small deployments)**
```bash
export MODERATOR_ADMIN_KEY=your-generated-key-here
```

#### **Option B: .env File (Development/Staging only)**
```bash
# Add to .env file
MODERATOR_ADMIN_KEY=your-generated-key-here
```

#### **Option C: Cloud Secret Management (Production)**
```bash
# AWS Secrets Manager
aws secretsmanager create-secret \
  --name peer-learn-hub/moderator-admin-key \
  --secret-string "your-generated-key-here"

# Google Secret Manager
gcloud secrets create moderator-admin-key \
  --data-file=<(echo "your-generated-key-here")

# Azure Key Vault
az keyvault secret set \
  --vault-name your-key-vault \
  --name moderator-admin-key \
  --value your-generated-key-here
```

### **Step 3: Update Production Deployment**

#### **Docker/Container:**
```dockerfile
# Dockerfile
ENV MODERATOR_ADMIN_KEY=${MODERATOR_ADMIN_KEY}
```

```bash
# Run container
docker run -e MODERATOR_ADMIN_KEY=your-key your-app
```

#### **Kubernetes:**
```yaml
# Secret
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
type: Opaque
stringData:
  moderator-admin-key: your-generated-key-here

# Deployment
env:
  - name: MODERATOR_ADMIN_KEY
    valueFrom:
      secretKeyRef:
        name: app-secrets
        key: moderator-admin-key
```

#### **Heroku:**
```bash
heroku config:set MODERATOR_ADMIN_KEY=your-generated-key-here
```

#### **Vercel/Netlify:**
```bash
# Set in dashboard or CLI
vercel env add MODERATOR_ADMIN_KEY production
```

---

## 🔑 Key Rotation Strategy

### **Monthly Rotation (Recommended):**
1. Generate new admin key
2. Update environment variable
3. Restart application
4. Share new key with moderators
5. Keep old key for 24-48 hours as backup
6. Remove old key after confirmed success

### **Emergency Rotation:**
1. Immediately generate new key
2. Update environment variable
3. Restart application
4. Notify moderators of new key
5. Revoke old key access

---

## 🛡️ Security Best Practices

### **Key Storage:**
- ✅ Use environment variables
- ✅ Use cloud secret management
- ✅ Encrypt at rest
- ✅ Access logging
- ❌ Never commit to git
- ❌ Never hardcode in application
- ❌ Never store in config files

### **Key Access:**
- ✅ Need-to-know basis
- ✅ Document who has access
- ✅ Regular access reviews
- ❌ No public access
- ❌ No shared credentials
- ❌ No unlimited access

### **Key Management:**
- ✅ Regular rotation
- ✅ Different keys per environment
- ✅ Backup procedures
- ✅ Incident response plan
- ❌ No key reuse
- ❌ No weak keys
- ❌ No long expiration

---

## 📊 Environment-Specific Setup

### **Development:**
```bash
# Auto-generated key displayed in logs
# Or set manually for consistency
MODERATOR_ADMIN_KEY=dev-key-123
```

### **Staging:**
```bash
# Different key from development
MODERATOR_ADMIN_KEY=staging-key-456
```

### **Production:**
```bash
# Strong, unique key
MODERATOR_ADMIN_KEY=prod-AbC123!@#xyz789$%^def456&*ghi
```

---

## 🚨 Incident Response

### **If Key is Compromised:**
1. **Immediately** generate new key
2. Update all production environments
3. Restart all application instances
4. Notify all moderators
5. Review access logs
6. Implement additional security measures
7. Document the incident

### **If Key is Lost:**
1. Generate new key
2. Update environment variable
3. Restart application
4. Share with authorized moderators
5. Update documentation

---

## 🔍 Monitoring & Auditing

### **Track Key Usage:**
- Log all moderator registration attempts
- Monitor failed authentication attempts
- Alert on suspicious activity
- Regular security audits

### **Example Monitoring:**
```javascript
// Add to your backend
app.post('/api/auth/register-moderator', async (req, res) => {
  const { adminKey } = req.body;
  
  // Log registration attempt (without the key)
  console.log(`Moderator registration attempt from ${req.ip} at ${new Date().toISOString()}`);
  
  // Your existing logic...
});
```

---

## 📝 Checklist for Production Deployment

- [ ] Generate secure admin key
- [ ] Set environment variable in production
- [ ] Test moderator registration with new key
- [ ] Document key location and access
- [ ] Set up key rotation schedule
- [ ] Configure monitoring and alerts
- [ ] Create incident response plan
- [ ] Train moderators on key usage
- [ ] Remove development endpoints
- [ ] Enable production security features

---

## 🎯 Quick Start for Production

```bash
# 1. Generate key
npm run generate-admin-key

# 2. Set environment variable
export MODERATOR_ADMIN_KEY=your-generated-key

# 3. Deploy your application
npm run deploy

# 4. Test moderator registration
# Use the generated key in the moderator registration form
```

---

**Remember:** In production, the admin key is a critical security credential. Treat it with the same care as database passwords or API keys.
