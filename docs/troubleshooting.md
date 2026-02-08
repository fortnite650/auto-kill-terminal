# Troubleshooting

## Agent stopped running terminal commands

**Symptom:** The agent says something like "I'll skip the terminal command" or "the terminal appears to be unavailable" and refuses to run any shell commands.

**Cause:** Zombie terminals from previous commands have accumulated. The agent detects stale sessions and concludes the terminal system is broken.

**Fix:**
1. Open the VS Code terminal panel (`` Ctrl+` ``)
2. Look for multiple terminal tabs — some may be labeled with command names
3. Right-click each one → **Kill Terminal**
4. Once all orphaned terminals are gone, the agent will use the terminal normally
5. **Permanent fix:** Add terminal management rules from this repo to prevent recurrence

## Agent keeps retrying the same terminal

**Symptom:** The agent runs a command, gets no output or an error, and immediately retries the same command in the same terminal — sometimes in an infinite loop.

**Cause:** The agent is reusing a foreground shell session that's in a bad state (wrong directory, previous command still running, environment corrupted).

**Fix:** Kill all terminals manually, then add the `isBackground: true` rule to your agent instructions.

## Agent says "terminal is unresponsive"

**Symptom:** The agent reports that the terminal is unresponsive and either retries or gives up.

**Cause:** The agent spawned too many terminals and the system shell pool is saturated, or the agent is checking a terminal that was already killed or timed out.

**Fix:** Restart the terminal panel or Codespace if severely degraded. Add the full terminal management rules to prevent it from happening again.

## Install script doesn't detect my agent file

**Symptom:** Running `install.sh` says "No agent files found" even though you have one.

**Cause:** The script looks for files with exact names in the current directory. Custom filenames or non-standard locations won't be detected.

**Fix:** Use a specific flag: `bash install.sh --copilot` or `bash install.sh --claude`. Or manually copy the rules from the README.

## Rules work with one agent but not another

**Symptom:** GitHub Copilot follows the rules but Claude doesn't (or vice versa).

**Cause:** Each agent reads different instruction files. Copilot reads `.github/copilot-instructions.md`, Claude reads `CLAUDE.md`, etc.

**Fix:** Add the rules to ALL agent instruction files you use. The `install.sh --all` flag does this automatically.

