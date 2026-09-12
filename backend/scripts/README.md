# Admin Key Management Scripts

This directory contains scripts for managing admin keys for moderator registration in production environments.

## 🚨 Production Security

**In production, admin keys are NEVER auto-generated.** You must generate and set them before deployment.

## 📜 Available Scripts

### 1. **generate-admin-key.js** - Generate a secure admin key
```bash
# Full display with instructions
npm run generate-admin-key

# Quiet mode (output only the key, for scripts)
node scripts/generate-admin-key.js --quiet
```

### 2. **setup-production.sh** - Linux/Mac production setup
```bash
chmod +x scripts/setup-production.sh
./scripts/setup-production.sh
```

### 3. **setup-production.bat** - Windows production setup
```cmd
scripts\setup-production.bat
```

## 🚀 Quick Start

### For Development:
```bash
# Start server - it will auto-generate a key if not set
npm start
# Check console for the generated key
```

### For Production:
```bash
# Step 1: Generate a secure key
npm run generate-admin-key

# Step 2: Set environment variable
export MODERATOR_ADMIN_KEY=your-generated-key

# Step 3: Deploy your application
npm start
```

## 🌍 Environment-Specific Behavior

### Development Mode (NODE_ENV != production):
- ✅ Auto-generates key if not set
- ✅ Displays key in console logs
- ✅ `/api/admin/key` endpoint available
- ⚠️  For development only

### Production Mode (NODE_ENV = production):
- ❌ **Requires** `MODERATOR_ADMIN_KEY` environment variable
- ❌ Server **fails to start** if key not set
- ❌ Auto-generation disabled
- ❌ `/api/admin/key` endpoint disabled
- ✅ Maximum security

## 📋 Production Deployment Checklist

- [ ] Generate secure admin key using `npm run generate-admin-key`
- [ ] Set `MODERATOR_ADMIN_KEY` environment variable
- [ ] Set `NODE_ENV=production`
- [ ] Test moderator registration with the key
- [ ] Document the key location (secure storage)
- [ ] Remove any development endpoints
- [ ] Monitor for failed authentication attempts
- [ ] Set up key rotation schedule

## 🔑 Key Rotation

### Monthly Rotation:
```bash
# 1. Generate new key
npm run generate-admin-key

# 2. Update environment variable
export MODERATOR_ADMIN_KEY=new-key

# 3. Restart application
npm restart

# 4. Share new key with moderators
# 5. Keep old key for 24-48 hours as backup
# 6. Remove old key after confirmation
```

## 📖 Detailed Documentation

For comprehensive production setup instructions, see:
- [setup-production-keys.md](./setup-production-keys.md)

## ⚠️ Security Best Practices

1. **Never commit actual keys to version control**
2. **Use different keys for different environments**
3. **Rotate keys regularly (monthly recommended)**
4. **Use cloud secret management in production**
5. **Monitor key usage and failed attempts**
6. **Have an incident response plan ready**
7. **Share keys only with authorized personnel**

## 🆘 Troubleshooting

### Server fails to start in production:
```
❌ CRITICAL: MODERATOR_ADMIN_KEY environment variable is required in production!
```
**Solution:** Set the environment variable before starting the server.

### Can't access moderator registration:
**Solution:** Ensure you're using the correct admin key from your environment variable.

### Key generation fails:
**Solution:** Ensure Node.js crypto module is available and you have proper permissions.

## 📞 Support

For issues or questions about admin key management, refer to the main project documentation or contact your system administrator.
