class Groundeffect < Formula
  desc "Hyper-fast, private email and calendar indexing for Claude Code"
  homepage "https://github.com/jamiequint/groundeffect"
  version "0.3.5"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jamiequint/groundeffect/releases/download/v0.3.5/groundeffect-0.3.5-darwin-arm64.tar.gz"
      sha256 "7e644f5a5262450f84479af62e9ee7c5724320860f7972cc895d0698d854ee9b"
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
    require "fileutils"

    plist_path = Dir.home + "/Library/LaunchAgents/com.groundeffect.daemon.plist"
    skill_dest = Dir.home + "/.claude/skills/groundeffect"
    skill_source = share/"groundeffect/skill"

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

    # Copy skill files to ~/.claude/skills/groundeffect
    # Use shell commands to bypass homebrew sandbox restrictions on user directories
    if Dir.exist?(skill_source)
      `rm -rf '#{skill_dest}' && mkdir -p '#{skill_dest}' && cp -R '#{skill_source}/'* '#{skill_dest}/'` rescue nil
    end

    # Add Claude Code permissions
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
