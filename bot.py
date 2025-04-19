import os
import discord
from discord.ext import commands
import asyncio
from dotenv import load_dotenv

# Load environment variables from .env
load_dotenv()
TOKEN = os.getenv("DISCORD_BOT_TOKEN")
GUILD_ID = None
CHANNEL_ID = None

# Check if the token is available
if not TOKEN:
    print("❌ Error: Bot token is not set. Please check the .env file.")
    exit(1)

# Set up the intents for the bot
intents = discord.Intents.default()
intents.message_content = True

# Initialize the bot with a command prefix and intents
bot = commands.Bot(command_prefix="!", intents=intents)
bot.remove_command("help")

# Event when bot is ready
@bot.event
async def on_ready():
    print(f"✅ Logged in as {bot.user} (ID: {bot.user.id})")
    print("Bot is ready!")

# Command: Ping
@bot.command()
async def ping(ctx):
    await ctx.send("Pong!")

# Command: Set server and channel for sending messages
@bot.command(aliases=["setserver"])
async def set_server(ctx, guild_id: int, channel_id: int):
    global GUILD_ID, CHANNEL_ID
    GUILD_ID = guild_id
    CHANNEL_ID = channel_id
    await ctx.send(f"✅ Set to Guild `{guild_id}` and Channel `{channel_id}`.")

# Command: Say message in the pre-configured channel
@bot.command()
async def say(ctx, *, message: str):
    if GUILD_ID and CHANNEL_ID:
        channel = bot.get_channel(CHANNEL_ID)
        if channel:
            await channel.send(message)
        else:
            await ctx.send("❌ Invalid channel ID.")
    else:
        await ctx.send("❌ Use `!setserver <guild_id> <channel_id>` first.")

# Command: Send a DM to a user
@bot.command()
async def dm(ctx, user_id: int, *, message: str):
    try:
        user = await bot.fetch_user(user_id)
        await user.send(message)
        await ctx.send(f"✅ Sent DM to {user.mention}")
    except discord.Forbidden:
        await ctx.send("❌ User has DMs disabled or blocked the bot.")

# Command: Send an example embed
@bot.command()
async def embed(ctx):
    e = discord.Embed(title="Example Embed", description="This is an example.", color=0x3498db)
    e.add_field(name="Field 1", value="Hello world!", inline=False)
    await ctx.send(embed=e)

# Command: Display available commands
@bot.command()
async def help(ctx):
    help_text = """
**Available Commands**
`!ping` - Bot replies with Pong  
`!say <message>` - Sends a message in set channel  
`!dm <user_id> <message>` - Send DM to user  
`!embed` - Sends an embed  
`!setserver <guild_id> <channel_id>` - Sets the channel for `!say`  
`exit` - Closes the bot (from console)
"""
    await ctx.send(help_text)

# Helper function to simulate console input
async def console_input():
    await bot.wait_until_ready()
    
    global CHANNEL_ID

    if not CHANNEL_ID:
        # Try to auto-select a valid channel if not set yet
        for guild in bot.guilds:
            for channel in guild.text_channels:
                if channel.permissions_for(guild.me).send_messages:
                    CHANNEL_ID = channel.id
                    print(f"ℹ️ Auto-selected channel: {channel.name} in {guild.name}")
                    break
            if CHANNEL_ID:
                break

    if not CHANNEL_ID:
        print("❌ No valid channel found. Use `!setserver` in Discord.")
        return

    # Start accepting commands from the console
    while True:
        command = input("Enter command (e.g., !ping): ").strip()
        
        if command.lower() == "exit":
            print("Exiting...")
            await bot.close()
            break

        if not command.startswith("!"):
            print("⚠️ Console commands must start with '!'. Try again.")
            continue
        
        # Split the command and arguments
        parts = command.split()
        command_name = parts[0][1:]  # Remove the "!" from command
        args = parts[1:]  # Get the arguments

        # Check if the command exists in the bot
        command_obj = bot.get_command(command_name)
        if command_obj:
            # Create a fake context object
            class FakeContext:
                def __init__(self):
                    self.bot = bot
                    self.author = bot.user
                    self.guild = None
                    self.channel = bot.get_channel(CHANNEL_ID)
                    self.message = None

                async def send(self, content=None, **kwargs):
                    if content:
                        print(f"Sent message to channel {self.channel.name}: {content}")
            
            ctx = FakeContext()
            try:
                await command_obj(ctx, *args)  # Invoke the command
                print(f"✅ Executed: {command}")
            except Exception as e:
                print(f"❌ Error while executing `{command}`: {e}")
        else:
            print(f"❌ Unknown command: {command}")

# Main function to run both bot and console input
async def main():
    bot_task = asyncio.create_task(bot.start(TOKEN))
    console_task = asyncio.create_task(console_input())
    await asyncio.gather(bot_task, console_task)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Bot manually stopped.")
