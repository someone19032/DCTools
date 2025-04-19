# check_env.py
import os
from dotenv import load_dotenv
import sys

# Load the environment variables
load_dotenv()

# Get the token from .env
TOKEN = os.getenv("DISCORD_BOT_TOKEN")

# Check if it's missing or empty
if not TOKEN or TOKEN.strip() == "":
    print("❌ DISCORD_BOT_TOKEN is missing or invalid.")
    os.system("pause")
    sys.exit(1)
