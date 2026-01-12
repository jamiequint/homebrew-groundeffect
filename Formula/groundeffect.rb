class Groundeffect < Formula
  desc "Hyper-fast, private email and calendar indexing for Claude Code"
  homepage "https://github.com/jamiequint/groundeffect"
  version "0.4.2"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jamiequint/groundeffect/releases/download/v0.4.2/groundeffect-0.4.2-darwin-arm64.tar.gz"
      sha256 "d88f85b5d7cff78bb497a0b607019de8d61a933d497971b7a7000a52bb306419"
    end
  end

  def install
    bin.install "groundeffect"
    bin.install "groundeffect-daemon"
    bin.install "groundeffect-mcp"

    # Install skill files to share directory
    (share/"groundeffect/skill").install Dir["skill/*"] if Dir.exist?("skill")
  end

  def post_install
    plist_path = Dir.home + "/Library/LaunchAgents/com.groundeffect.daemon.plist"

    # Install or restart daemon
    service_target = "gui/#{Process.uid}/com.groundeffect.daemon"
    unless File.exist?(plist_path)
      # Fresh install
      system "#{bin}/groundeffect", "daemon", "install"
    else
      # Restart daemon using backticks to avoid homebrew error tracking
      # launchctl returns non-zero even on success, but daemon restart isn't critical
      `launchctl kickstart -k #{service_target} 2>&1` rescue nil
    end

    # Add Claude Code permissions (also installs skill files)
    system "#{bin}/groundeffect", "config", "add-permissions"
  end

  def caveats
    <<~EOS
      To complete setup:

      1. Add your Google OAuth credentials to ~/.zshrc or ~/.bashrc:
         export GROUNDEFFECT_GOOGLE_CLIENT_ID="your-client-id"
         export GROUNDEFFECT_GOOGLE_CLIENT_SECRET="your-client-secret"

         Get credentials from: https://console.cloud.google.com/apis/credentials
         (Create OAuth 2.0 Client ID > Desktop app, enable Gmail & Calendar APIs)

      2. Reload your shell and add an account:
         source ~/.zshrc  # or restart terminal
         groundeffect account add
    EOS
  end

  def uninstall_preflight
    system "#{bin}/groundeffect", "daemon", "uninstall" rescue nil
  end

  def post_uninstall
    require "fileutils"
    FileUtils.rm_rf(Dir.home + "/.config/groundeffect")
    FileUtils.rm_rf(Dir.home + "/.local/share/groundeffect")
    FileUtils.rm_rf(Dir.home + "/.claude/skills/groundeffect")
  end

  test do
    assert_match "groundeffect", shell_output("#{bin}/groundeffect --help")
    assert_match "groundeffect-daemon", shell_output("#{bin}/groundeffect-daemon --help")
  end
end
