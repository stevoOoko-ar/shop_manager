#!/bin/bash
# PostgreSQL Migration Helper for Shop Manager
# This script helps migrate from SQLite to PostgreSQL

set -e

echo "🗄️ Shop Manager - SQLite to PostgreSQL Migration"
echo "=================================================="
echo ""
echo "Prerequisites:"
echo "1. Create PostgreSQL database on Render: https://dashboard.render.com"
echo "2. Copy the DATABASE_URL from Render"
echo ""

read -p "Do you have your PostgreSQL DATABASE_URL? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please create a PostgreSQL database first."
    exit 1
fi

read -p "Paste your DATABASE_URL: " DATABASE_URL

# Validate URL
if [[ ! $DATABASE_URL =~ postgresql:// ]]; then
    echo "❌ Invalid DATABASE_URL format. Should start with 'postgresql://'"
    exit 1
fi

echo ""
echo "📝 Updating backend/app.py..."

# Replace SQLite URL with PostgreSQL URL
sed -i.bak "s|DATABASE_URL = \"sqlite:///./shop_manager.db\"|DATABASE_URL = \"$DATABASE_URL\"|g" backend/app.py

echo "📦 Installing PostgreSQL driver..."
pip install psycopg2-binary
pip freeze > backend/requirements.txt

echo ""
echo "📋 Updated files:"
echo "  ✅ backend/app.py - Changed DATABASE_URL"
echo "  ✅ backend/requirements.txt - Added psycopg2-binary"
echo ""
echo "🚀 Next steps:"
echo "  1. Test locally: python -m uvicorn app:app --reload"
echo "  2. Commit changes: git add -A && git commit -m 'Migrate to PostgreSQL'"
echo "  3. Push to Render: git push"
echo "  4. Render will auto-deploy with PostgreSQL connection"
echo ""
echo "✨ Done! Your app will now use PostgreSQL which persists on Render."
