class Groundeffect < Formula
  desc "Hyper-fast, private email and calendar indexing for Claude Code"
  homepage "https://github.com/jamiequint/groundeffect"
  version "0.2.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jamiequint/groundeffect/releases/download/v0.2.0/groundeffect-0.2.0-darwin-arm64.tar.gz"
      sha256 "a4987c44ce1372f1a49992dcf901b3d7e7753ddac89464bf214e67653bf89d1a"
    end
  end

  def install
    bin.install "groundeffect"
    bin.install "groundeffect-daemon"
    bin.install "groundeffect-mcp"
  end

  def post_install
    # Restart daemon if it's running (e.g., after upgrade)
    plist = Dir.home + "/Library/LaunchAgents/com.groundeffect.daemon.plist"
    if File.exist?(plist)
      # Try launchctl kickstart first
      unless system "launchctl", "kickstart", "-k", "gui/#{Process.uid}/com.groundeffect.daemon"
        # Fallback: kill the process and let launchd restart it (due to KeepAlive)
        system "pkill", "-f", "groundeffect-daemon"
      end
    end
  end

  def caveats
    <<~EOS
      To complete setup:

      1. Create ~/.secrets with your Google OAuth credentials:
         export GROUNDEFFECT_GOOGLE_CLIENT_ID="your-client-id"
         export GROUNDEFFECT_GOOGLE_CLIENT_SECRET="your-client-secret"

         Then add to ~/.zshrc or ~/.bashrc:
         source ~/.secrets

      2. Choose integration method for Claude Code:

         OPTION A: Skill (Recommended - faster)
         mkdir -p ~/.claude/skills
         git clone https://github.com/jamiequint/groundeffect.git /tmp/groundeffect
         cp -r /tmp/groundeffect/skill ~/.claude/skills/groundeffect

         OPTION B: MCP Server (for non-Claude Code users)
         Add to ~/.claude.json:
         {
           "mcpServers": {
             "groundeffect": {
               "type": "stdio",
               "command": "groundeffect-mcp",
               "env": {
                 "GROUNDEFFECT_GOOGLE_CLIENT_ID": "${GROUNDEFFECT_GOOGLE_CLIENT_ID}",
                 "GROUNDEFFECT_GOOGLE_CLIENT_SECRET": "${GROUNDEFFECT_GOOGLE_CLIENT_SECRET}"
               }
             }
           }
         }

      3. Run the setup wizard:
         groundeffect-daemon setup --install

         Settings can be changed later with: groundeffect-daemon configure
         Note: "Max concurrent fetches" = IMAP connections (Gmail limit: 15)

      4. Add a Google account by asking Claude Code:
         "Add my Gmail account to groundeffect"

      Get OAuth credentials from: https://console.cloud.google.com/apis/credentials
      (Create OAuth 2.0 Client ID > Desktop app, enable Gmail & Calendar APIs)
    EOS
  end

  def uninstall_preflight
    system "#{bin}/groundeffect-daemon", "setup", "--uninstall" rescue nil
  end

  def post_uninstall
    rm_rf Dir.home + "/.config/groundeffect"
    rm_rf Dir.home + "/.local/share/groundeffect"
  end

  test do
    assert_match "groundeffect", shell_output("#{bin}/groundeffect --help")
    assert_match "groundeffect-daemon", shell_output("#{bin}/groundeffect-daemon --help")
  end
end
