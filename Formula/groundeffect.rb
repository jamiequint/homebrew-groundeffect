class Groundeffect < Formula
  desc "Hyper-fast, private email and calendar indexing for Claude Code"
  homepage "https://github.com/jamiequint/groundeffect"
  version "0.2.1"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jamiequint/groundeffect/releases/download/v0.2.1/groundeffect-0.2.1-darwin-arm64.tar.gz"
      sha256 "4e57c348e7755aeb44e94f22246d5ef5f666a958c0283e40c9e5724b0b20b393"
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

      2. Run the setup wizard:
         groundeffect-daemon setup --install

      3. Allow Claude Code to run groundeffect commands:
         groundeffect config add-permissions

      4. (Alternative) For MCP-based integration, add to ~/.claude.json:
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

      5. Add a Google account by asking Claude Code:
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
