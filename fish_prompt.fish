# name: scorphish

# This file is part of theme-scorphis

# Licensed under the MIT license:
# https://opensource.org/licenses/MIT
# Copyright (c) 2014, Pablo S. Blum de Aguiar <scorphus@gmail.com>

# TODO:
# 1) Check that asdf is installed
# 2) Check that specific plugin is installed
# 3) Check that version of the tool is set globally or locally
# 4) Cache the result


# This is temporary
source ~/.local/share/omf/themes/scorphish/fish_asdf.fish

function _prompt_rubies -a color -d 'Display current Ruby (rvm/rbenv/asdf)'
  [ "$theme_display_ruby" = 'no' ]; and return
  set -l ruby_version
  if type rvm-prompt >/dev/null 2>&1
    set ruby_version (rvm-prompt i v g | cut -d- -f2-)
  else if type rbenv >/dev/null 2>&1
    set ruby_version (rbenv version-name | cut -d- -f2-)
  else if asdf_installed and asdf_plugin_installed "ruby"
    set ruby_version (asdf_get_version "ruby")
  end

  [ -z "$ruby_version" ]; and return
  echo -n -s $color (echo -n -s $ruby_version)
end

function _prompt_virtualenv -a color -d "Display currently activated Python virtual environment"
  [ "$theme_display_virtualenv" = 'no' ]; and return
  
  if asdf_installed and asdf_plugin_installed "python"
    set python_version (asdf_get_version "python")
  else
    set python_version $PYTHON_VERSION
  end
  
  echo -n -s $color $python_version
  [ -n "$VIRTUAL_ENV" ]; and echo -n -s '@'(basename "$VIRTUAL_ENV")
end

function _prompt_rust -a color -d "Display currently activated Rust"
  [ "$theme_display_rust" != 'yes' ]; and return
  
  if asdf_installed and asdf_plugin_installed "rust"
    set rust_version (asdf_get_version "rust")
  else if type rustc >/dev/null 2>&1
    set rust_version (rustc --version | cut -d\  -f2)  # TODO: cache this
  end

  [ -z "$rust_version" ]; and return
  echo -n -s $color $rust_version 
end

function _prompt_node -a color -d "Display currently activated Node"
  if asdf_installed and asdf_plugin_installed "nodejs"
    set node_version (asdf_get_version "nodejs")
  else
    type -q nvm; and begin; set -q NVM_BIN; or return; end # Lazy loading
  
    if [ "$NVM_BIN" != "$LAST_NVM_BIN" -o -z "$NODE_VERSION" ]
      set -gx NODE_VERSION (node --version)
      set -gx LAST_NVM_BIN $NVM_BIN
    end

    set node_version $NODE_VERSION
  end

  [ "$theme_display_node" != 'yes' -o -z "$NODE_VERSION" ]; and return  
  echo -n -s $color $node_version
end

function _prompt_whoami -a sep_color -a color -d "Display user@host if on a SSH session"
  if set -q SSH_TTY
    echo -n -s $color (whoami)@(hostname) $sep_color '|'
  end
end

function _git_branch_name
  echo (command git symbolic-ref HEAD ^/dev/null | sed -e 's|^refs/heads/||')
end

function _is_git_dirty
  echo (command git status -s --ignore-submodules=dirty ^/dev/null)
end

function _git_ahead_count -a remote -a branch_name
  echo (command git log $remote/$branch_name..HEAD ^/dev/null | \
    grep '^commit' | wc -l | tr -d ' ')
end

function _git_dirty_remotes -a remote_color -a ahead_color
  set current_branch (command git rev-parse --abbrev-ref HEAD ^/dev/null)
  set current_ref (command git rev-parse HEAD ^/dev/null)

  for remote in (git remote | grep 'origin\|upstream')

    set -l git_ahead_count (_git_ahead_count $remote $current_branch)

    set remote_branch "refs/remotes/$remote/$current_branch"
    set remote_ref (git for-each-ref --format='%(objectname)' $remote_branch)
    if test "$remote_ref" != ''
      if test "$remote_ref" != $current_ref
        if [ $git_ahead_count != 0 ]
          echo -n "$remote_color!"
          echo -n "$ahead_color+$git_ahead_count$normal"
        end
      end
    end
  end
end

function _prompt_versions -a blue gray green orange red append

  set -l prompt_rubies (_prompt_rubies $red)

  if [ "$VIRTUAL_ENV" != "$LAST_VIRTUAL_ENV" -o -z "$PYTHON_VERSION" ]
    set -gx PYTHON_VERSION (python --version 2>&1 | cut -d\  -f2)
    set -gx LAST_VIRTUAL_ENV $VIRTUAL_ENV
  end

  set -l prompt_virtualenv (_prompt_virtualenv $blue)

  set -l prompt_rust (_prompt_rust $orange)

  set -l prompt_nvm (_prompt_node $green)

  echo -n -e -s "$prompt_rubies $prompt_virtualenv $prompt_rust $prompt_nvm" | string trim | string replace -ar " +" "$gray|" | tr -d '\n'
end

function _prompt_git -a gray normal orange red yellow
  if [ (_git_branch_name) ]
    set -l git_branch (_git_branch_name)

    set dirty_remotes (_git_dirty_remotes $red $orange)

    if [ (_is_git_dirty) ]
      echo -n -s $gray '‹' $yellow $git_branch $red '*' $dirty_remotes $gray '› '
    else
      echo -n -s $gray '‹' $yellow $git_branch $red $dirty_remotes $gray '› '
    end
  end
end

function _prompt_pwd
  set_color -o cyan
  printf '%s' (prompt_pwd)
end

function _prompt_status_arrows -a exit_code
  if test $exit_code -ne 0
    set arrow_colors 600 900 c00 f00
  else
    set arrow_colors 060 090 0c0 0f0
  end
  for arrow_color in $arrow_colors
    set_color $arrow_color
    printf '»'
  end
end

function fish_prompt
  set -l exit_code $status

  set -l gray (set_color 666)
  set -l blue (set_color blue)
  set -l red (set_color red)
  set -l normal (set_color normal)
  set -l yellow (set_color yellow)
  set -l orange (set_color ff9900)
  set -l green (set_color green)

  set_color -o 666
  printf '['

  _prompt_whoami $gray $green

  if not set -q theme_pwd_on_second_line
    _prompt_pwd
    set_color -o 666
    printf '|'
  end

  _prompt_versions $blue $gray $green $orange $red

  set_color -o 666
  printf '] ⚡️ %0.3fs' (math $CMD_DURATION / 1000)

  if set -q theme_git_info_on_first_line
    _prompt_git $gray $normal $orange $red $yellow
  end

  if set -q theme_pwd_on_second_line
    set_color -o 666
    printf '\n‹'
    _prompt_pwd
    set_color -o 666
    printf '›'
  end

  printf '\n'
  if not set -q theme_git_info_on_first_line
    _prompt_git $gray $normal $orange $red $yellow
  end
  _prompt_status_arrows $exit_code
  printf ' '

  set_color normal
end