# =======================================================================================
#  POWERLEVEL10K CONFIGURATION | CHIMERA GUARDIAN ARCH
#  Pre-configured to replicate the modern Kali Linux Zsh prompt.
# =======================================================================================

# --- Enable Powerlevel10k Instant Prompt ---
# Speeds up shell startup.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- General ---
# Use Nerd Fonts for icons (requires ttf-jetbrains-mono-nerd installed).
typeset -g POWERLEVEL9K_MODE='nerdfont-complete'

# --- Prompt Style: Two Lines ---
# Replicates the Kali layout.
POWERLEVEL9K_PROMPT_ON_NEWLINE=true
POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX="┌──(" # Prefix for the first line
POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX="└─╼ "   # Prefix for the second line (where you type)

# --- Left Prompt Elements (First Line) ---
# Order: OS Icon -> User -> Host -> Directory
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon user host dir)

# --- Right Prompt Elements (First Line) ---
# Order: Command Status -> Execution Time -> Git Status
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time vcs)

# --- Styling: User & Host ---
# Red color, matching Kali.
POWERLEVEL9K_USER_FOREGROUND='red'
POWERLEVEL9K_HOST_FOREGROUND='red'
POWERLEVEL9K_USER_HOST_SEPARATOR='㉿' # Special Kali-style separator

# --- Styling: OS Icon (Chimera Enhancement) ---
# Use the Arch Linux logo instead of Kali's for a unique touch.
POWERLEVEL9K_OS_ICON_FOREGROUND='cyan'
POWERLEVEL9K_OS_ICON_CONTENT_EXPANSION='' # Arch Linux Nerd Font icon

# --- Styling: Directory ---
# White color for readability.
POWERLEVEL9K_DIR_FOREGROUND='white'
POWERLEVEL9K_DIR_ANCHOR_FOREGROUND='white' # Color for the '~' symbol in home directory

# --- Styling: Git Status (VCS) ---
# Yellow color for visibility.
POWERLEVEL9K_VCS_FOREGROUND='yellow'

# --- Final Prompt Character ($) ---
# Green for success, red for error status of the last command.
POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND='green'
POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_FOREGROUND='red'
POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_CONTENT_EXPANSION='$'
POWERLEVEL9K_PROMPT_CHAR_ERROR_VIINS_CONTENT_EXPANSION='$'

# --- To customize prompt further, run `p10k configure` or edit this file.