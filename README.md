## Scorphish (Modernized)

Compact. Sufficient. Fast.

### Layout

```
                                                          ⚡️ 1.2s  ← previous cmd duration (right-aligned)
‹main*› ~/p/foo 18:26:44        Go:1.24 | Py:3.12                  ← git + path + time ... versions
»»»»                                                               ← input line
```

- **Duration** — tiered formatting: `42ms`, `1.2s`, `2m05s`, `1h30m`. Color escalates with time.
- **Git** — branch, dirty `*`, ahead `+N` per remote. Left side, high visibility.
- **Path** — fish abbreviated `prompt_pwd`.
- **Time** — `HH:MM:SS` after path.
- **Versions** — right-aligned, `Name:Version` format, dimmed. Only detected languages shown.
- **Arrows** — green gradient on success, red gradient on failure.

### Environment Detection

| Language | Manager Support | Toggle | Default |
|----------|----------------|--------|---------|
| Go | direct | `theme_display_go` | **off** |
| Rust | rustup | `theme_display_rust` | **off** |
| Node | nvm, fnm, volta, mise | `theme_display_node` | **on** |
| Bun | direct | `theme_display_bun` | **off** |
| Deno | direct | `theme_display_deno` | **off** |
| Python | venv, conda, uv, poetry | `theme_display_python` | **on** |
| Ruby | mise, asdf, rvm, rbenv | `theme_display_ruby` | **off** |

All detectors are cached — subprocess only runs on first call or environment change.

### Configuration

Add to `~/.config/fish/conf.d/omf.fish`:

```fish
# Enable opt-in language detection
set -g theme_display_go yes
set -g theme_display_rust yes

# Disable default-on detection
set -g theme_display_node no
set -g theme_display_python no

# Disable git info entirely
set -g theme_display_git no

# Disable only git dirty check (faster prompt in large repos)
set -g theme_display_git_dirty no
```

### Special Environments

- **SSH** — shows `user@host` prefix
- **Container/Devcontainer/Codespace** — shows hostname in orange

### Acknowledgments

Based on the original Scorphish theme by Pablo S. Blum de Aguiar.
