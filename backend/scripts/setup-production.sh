#!/bin/bash

# Production Admin Key Setup Script
# This script helps you set up admin keys for production deployment

set -e

echo "=========================================="
echo "  Production Admin Key Setup"
echo "=========================================="
echo ""

# Check if .env file exists
if [ -f .env ]; then
    echo "⚠️  .env file already exists"
    echo "   Current MODERATOR_ADMIN_KEY will be preserved"
    echo ""
fi

# Generate new admin key
echo "🔑 Generating new admin key..."
ADMIN_KEY=$(npm run generate-admin-key-quiet 2>/dev/null)

echo "✅ Admin key generated"
echo ""
echo "📝 Your new admin key:"
echo "   $ADMIN_KEY"
echo ""

# Ask if user wants to add to .env file
read -p "Add this key to .env file? (y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Backup existing .env file
    if [ -f .env ]; then
        cp .env .env.backup
        echo "📦 Backed up existing .env file to .env.backup"
    fi
    
    # Add or update MODERATOR_ADMIN_KEY
    if [ -f .env ] && grep -q "MODERATOR_ADMIN_KEY" .env; then
        # Update existing key (platform-specific)
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/^MODERATOR_ADMIN_KEY=.*/MODERATOR_ADMIN_KEY=$ADMIN_KEY/" .env
        else
            # Linux
            sed -i "s/^MODERATOR_ADMIN_KEY=.*/MODERATOR_ADMIN_KEY=$ADMIN_KEY/" .env
        fi
        echo "✅ Updated MODERATOR_ADMIN_KEY in .env file"
    else
        # Add new key
        echo "MODERATOR_ADMIN_KEY=$ADMIN_KEY" >> .env
        echo "✅ Added MODERATOR_ADMIN_KEY to .env file"
    fi
else
    echo "⏭️  Skipping .env file update"
fi

echo ""
echo "=========================================="
echo "  Setup Complete"
echo "=========================================="
echo ""
echo "🚀 Next Steps:"
echo "   1. For local development: The key is in your .env file"
echo "   2. For production deployment: Set as environment variable"
echo "      export MODERATOR_ADMIN_KEY=$ADMIN_KEY"
echo ""
echo "📖 For detailed deployment instructions, see:"
echo "   scripts/setup-production-keys.md"
echo ""
echo "⚠️  Security Reminders:"
echo "   - Never commit .env file to version control"
echo "   - Use different keys for different environments"
echo "   - Rotate keys periodically"
echo "   - Share only with authorized personnel"
echo "=========================================="
