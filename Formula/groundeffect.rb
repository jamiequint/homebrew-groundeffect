class Groundeffect < Formula
  desc "Hyper-fast, private email and calendar indexing for Claude Code"
  homepage "https://github.com/jamiequint/groundeffect"
  version "0.3.4"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/jamiequint/groundeffect/releases/download/v0.3.4/groundeffect-0.3.4-darwin-arm64.tar.gz"
      sha256 "adb8ba9e9141fcc209dddaf80dd69520a2c180b2966a46f915da8b763be53f00"
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

    # Install daemon (fresh install only)
    unless File.exist?(plist_path)
      system "#{bin}/groundeffect", "daemon", "install"
    else
      # Upgrade: restart existing daemon
      system "launchctl", "kickstart", "-k", "gui/#{Process.uid}/com.groundeffect.daemon"
    end

    # Copy skill files to ~/.claude/skills/groundeffect
    if Dir.exist?(skill_source)
      FileUtils.mkdir_p(skill_dest)
      FileUtils.cp_r(Dir.glob("#{skill_source}/*"), skill_dest)
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
