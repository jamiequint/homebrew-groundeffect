# GroundEffect

Hyper-fast, local Gmail and Google Calendar indexing for Claude Code.

GroundEffect is a local headless IMAP/CalDAV client, Claude Code skill, and MCP server built in Rust with LanceDB.

This is the official Homebrew tap for [GroundEffect](https://github.com/jamiequint/groundeffect).

## Installation

```bash
brew tap jamiequint/groundeffect
brew install groundeffect
```

## Setup

After installation, follow the caveats shown by Homebrew, or run:

```bash
groundeffect-daemon setup --install
```

This will:
1. Configure daemon settings interactively
2. Install a launchd agent for auto-start at login

## Usage

GroundEffect is designed to be used through Claude Code's MCP integration. Once set up, ask Claude Code:

```
"Add my Gmail account to groundeffect"     # Add account with OAuth
"Show my sync status"                       # Check sync progress
"Search my emails for quarterly report"    # Semantic search
"Show me my recent emails"                 # List recent messages
"What meetings do I have tomorrow?"        # Calendar search
```

### CLI Commands (Alternative)

The daemon can also be managed via CLI:

```bash
groundeffect-daemon configure    # Change settings (logging, poll intervals, etc.)
groundeffect-daemon status       # Check daemon status
```

## Uninstallation

```bash
brew uninstall groundeffect
```

The launchd agent is automatically removed during uninstall.

## More Information

See the [main repository](https://github.com/jamiequint/groundeffect) for full documentation.
