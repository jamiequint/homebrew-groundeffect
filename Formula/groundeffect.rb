class Groundeffect < Formula
  desc "Hyper-fast, private email and calendar indexing for Claude Code"
  homepage "https://github.com/jamiequint/groundeffect"
  version "0.5.4"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jamiequint/groundeffect/releases/download/v0.5.4/groundeffect-0.5.4-darwin-arm64.tar.gz"
      sha256 "e87aa21df49ecb81a519ea21a923889299aacd001ba0dfd8bc0018c00ac6d2aa"
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
