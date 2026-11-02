# name: scorphish
# Modernized fish shell theme
#
# Original: Pablo S. Blum de Aguiar <scorphus@gmail.com>
# Modernized: Slahser
#
# Layout:
#                                              ⚡️ 1.2s  (right-aligned on previous output line)
#   ‹main*› ~/p/foo 18:26:44      Go:1.24 | Py:3.12    (git + path + time ... versions)
#   »»»»                                                (input line)


# --- Pre-exec hook: track whether a command actually ran ---
function _scorphish_preexec --on-event fish_preexec
  set -g _SCORPHISH_CMD_RAN 1
end

# --- Helpers ---

function _visible_width -d "Visible char count after stripping ANSI escapes"
  string length -- (string replace -ra '\e(?:\[[0-9;]*m|\(B)' '' -- "$argv")
end

function _format_duration -a ms -d "Human-readable duration with tier formatting"
  if test $ms -lt 1000
    printf '%dms' $ms
  else if test $ms -lt 60000
    printf '%.1fs' (math "$ms / 1000")
  else if test $ms -lt 3600000
    printf '%dm%02ds' (math -s0 "$ms / 60000") (math -s0 "($ms % 60000) / 1000")
  else
    printf '%dh%02dm' (math -s0 "$ms / 3600000") (math -s0 "($ms % 3600000) / 60000")
  end
end

# --- Version detectors (cached, minimal fork after first call) ---
# Disable any with: set -g theme_display_<lang> no

function _detect_go
  test "$theme_display_go" != yes; and return
  type -q go; or return
  set -l p (type -p go)
  if test "$p" != "$_CGO_P"; or not set -q _CGO_V
    set -gx _CGO_V (string match -r '\d+\.\d+[\.\d]*' (go version 2>/dev/null))
    set -gx _CGO_P "$p"
  end
  test -n "$_CGO_V"; and echo "Go:$_CGO_V"
end

function _detect_rust
  test "$theme_display_rust" != yes; and return
  type -q rustc; or return
  if string match -q 'rustup default*' -- $history[1]; or not set -q _CRS_V
    set -gx _CRS_V (string split ' ' -- (rustc --version 2>/dev/null))[2]
  end
  test -n "$_CRS_V"; and echo "Rust:$_CRS_V"
end

function _detect_node
  test "$theme_display_node" = no; and return
  type -q node; or return
  # Support nvm (lazy), fnm, volta, mise
  if type -q nvm; and not set -q NVM_BIN; and not set -q FNM_DIR; and not set -q VOLTA_HOME; and not set -q MISE_SHELL
    return
  end
  set -l k "$NVM_BIN:$FNM_MULTISHELL_PATH:$VOLTA_HOME"
  if test "$k" != "$_CND_K"; or not set -q _CND_V
    set -gx _CND_V (string replace 'v' '' -- (node --version 2>/dev/null))
    set -gx _CND_K "$k"
  end
  test -n "$_CND_V"; and echo "Node:$_CND_V"
end

function _detect_bun
  test "$theme_display_bun" != yes; and return
  type -q bun; or return
  if not set -q _CBN_V
    set -gx _CBN_V (bun --version 2>/dev/null)
  end
  test -n "$_CBN_V"; and echo "Bun:$_CBN_V"
end

function _detect_deno
  test "$theme_display_deno" != yes; and return
  type -q deno; or return
  if not set -q _CDN_V
    set -l out (deno --version 2>/dev/null)
    set -gx _CDN_V (string match -r '\d+\.\d+\.\d+' -- $out[1])
  end
  test -n "$_CDN_V"; and echo "Deno:$_CDN_V"
end

function _detect_python
  test "$theme_display_python" = no; and return
  type -q python; or return
  set -l k "$VIRTUAL_ENV:$CONDA_DEFAULT_ENV"
  if test "$k" != "$_CPY_K"; or not set -q _CPY_V
    set -gx _CPY_V (string split ' ' -- (python --version 2>&1))[2]
    set -gx _CPY_K "$k"
  end
  set -l out "Py:$_CPY_V"
  if test -n "$CONDA_DEFAULT_ENV"
    set out "$out@$CONDA_DEFAULT_ENV"
  else if test -n "$VIRTUAL_ENV"
    set out "$out@"(basename "$VIRTUAL_ENV")
  end
  echo $out
end

function _detect_ruby
  test "$theme_display_ruby" != yes; and return
  type -q ruby; or return
  set -l p (type -p ruby)
  if test "$p" != "$_CRB_P"; or not set -q _CRB_V
    if type -q mise
      set -gx _CRB_V (string trim -- (mise current ruby 2>/dev/null))
    else if type -q asdf
      set -gx _CRB_V (string split ' ' -- (asdf current ruby 2>/dev/null))[2]
    else if type -q rvm-prompt
      set -gx _CRB_V (rvm-prompt i v g 2>/dev/null)
    else if type -q rbenv
      set -gx _CRB_V (rbenv version-name 2>/dev/null)
    else
      set -gx _CRB_V (string split ' ' -- (ruby --version 2>/dev/null))[2]
    end
    set -gx _CRB_P "$p"
  end
  test -n "$_CRB_V"; and echo "Ruby:$_CRB_V"
end

# --- Status arrows ---

function _prompt_status_arrows -a exit_code
  if test $exit_code -ne 0
    set colors 600 900 c00 f00
  else
    set colors 060 090 0c0 0f0
  end
  for c in $colors
    set_color $c
    printf '»'
  end
end

# --- Main prompt ---

function fish_prompt
  set -l exit_code $status
  set -l cmd_dur $CMD_DURATION

  # Colors — cyberpunk palette
  set -l gray (set_color 8888aa)        # cool gray with blue tint
  set -l red (set_color ff2266)         # neon pink-red
  set -l normal (set_color normal)
  set -l yellow (set_color ffdd00)      # electric yellow
  set -l orange (set_color ff6622)      # hot orange
  set -l green (set_color 22ffaa)       # neon mint
  set -l cyan (set_color -o 00eeff)     # electric cyan
  set -l dim (set_color 888)             # muted gray for versions/time
  set -l dim2 (set_color 555)            # darker gray for separators

  # ── Duration: standalone line, right-aligned ──
  if set -q _SCORPHISH_CMD_RAN; and test $cmd_dur -gt 0
    set -l dur_color $dim
    test $cmd_dur -ge 1000; and set dur_color (set_color ffdd00)   # electric yellow
    test $cmd_dur -ge 10000; and set dur_color (set_color ff2266)  # neon pink-red
    set -l dur_str (_format_duration $cmd_dur)
    set -l dur_w (_visible_width "$dur_str")
    set -l dur_pad (math "$COLUMNS - $dur_w")
    test $dur_pad -lt 0; and set dur_pad 0
    printf '%*s%s%s%s\n' $dur_pad '' "$dur_color" "$dur_str" "$normal"
    set -e _SCORPHISH_CMD_RAN
  end

  # ── Line 1: left side ──
  set -l left ''

  # SSH user@host
  if set -q SSH_TTY
    set left "$left$green"(whoami)'@'(hostname)"$gray|"
  # Container / devcontainer / codespace
  else if test -f /.dockerenv; or set -q container; or set -q REMOTE_CONTAINERS; or set -q CODESPACES
    set left "$left$orange"(hostname)"$gray|"
  end

  # Git branch + dirty + ahead
  if test "$theme_display_git" != no
    set -l branch (command git symbolic-ref --short HEAD 2>/dev/null)
    if test -n "$branch"
      set -l g "$gray‹$yellow$branch"
      if test "$theme_display_git_dirty" != no
        command git diff-index --quiet HEAD -- 2>/dev/null; or set g "$g$red*"
        set -l cur_ref (command git rev-parse HEAD 2>/dev/null)
        for remote in (command git remote 2>/dev/null)
          set -l ahead (command git rev-list --count "$remote/$branch..HEAD" 2>/dev/null)
          if test -n "$ahead"; and test "$ahead" != 0
            set -l rref (command git for-each-ref --format='%(objectname)' "refs/remotes/$remote/$branch")
            if test -n "$rref"; and test "$rref" != "$cur_ref"
              set g "$g$red!$orange+$ahead"
            end
          end
        end
      end
      set left "$left$g$gray› "
    end
  end

  # Abbreviated path
  set left "$left$cyan"(prompt_pwd)"$normal "

  # Current time
  set left "$left$dim"(date +%H:%M:%S)"$normal"

  # ── Line 1: right side (language versions, right-aligned) ──
  set -l ver_parts
  for v in (_detect_go) (_detect_rust) (_detect_node) (_detect_bun) (_detect_deno) (_detect_python) (_detect_ruby)
    test -n "$v"; and set -a ver_parts "$v"
  end

  set -l right ''
  if test (count $ver_parts) -gt 0
    set right "$dim"(string join "$dim2 | $dim" $ver_parts)"$normal"
  end

  # ── Render line 1 ──
  set -l left_w (_visible_width "$left")
  set -l right_w (_visible_width "$right")
  set -l pad (math "$COLUMNS - $left_w - $right_w")

  if test $right_w -gt 0; and test $pad -ge 2
    printf '%s%*s%s\n' "$left" $pad '' "$right"
  else
    printf '%s\n' "$left"
  end

  # ── Line 2: status arrows ──
  _prompt_status_arrows $exit_code
  printf ' '
  set_color normal
end
