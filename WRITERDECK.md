# Setting Up Manuscripts on a WriterDeck

This guide walks you through setting up Manuscripts on a Raspberry Pi Zero 2W WriterDeck from scratch.

## Prerequisites

- Raspberry Pi Zero 2W with Raspberry Pi OS (Bookworm or later)
- A screen and keyboard connected
- Internet connection (for initial setup only)

## 1. Install System Dependencies

```bash
sudo apt update
sudo apt install git python3-full python3-pip python3-venv cage foot pandoc libreoffice fonts-noto-mono
```

## 2. Clone the Repository

```bash
cd ~
git clone https://github.com/corycaean/manuscripts.git
```

## 3. Set Up the Python Environment

```bash
cd ~/manuscripts
python3 -m venv .venv
.venv/bin/pip install textual tree-sitter tree-sitter-markdown
```

This creates a virtual environment with all dependencies. It only needs to be done once — it survives reboots.

## 4. Test It

```bash
cd ~/manuscripts
./run.sh
```

You should see the Manuscripts app. Press `n` to create a new manuscript, type something, press `Ctrl+S` to save, and `Ctrl+M` to return to the list. Press `Ctrl+Q` to quit.

## 5. Set Up Cage + Foot

Cage is a minimal Wayland compositor and Foot is a lightweight terminal. Together they let Manuscripts run full-screen without a desktop environment.

### Configure Foot

```bash
mkdir -p ~/.config/foot
nano ~/.config/foot/foot.ini
```

Paste this:

```ini
[main]
font=Noto Sans Mono:size=14:antialias=true:hinting=true

[mouse]
hide-when-typing=yes
```

Adjust `size=14` to whatever looks right on your screen.

### Test Cage + Foot

```bash
cage -d -- foot -e bash -c "cd ~/manuscripts && ./run.sh"
```

The `-d` flag tells Cage there's no mouse. If everything looks good, move on to auto-launch.

## 6. Auto-Launch on Boot

Edit your `.bashrc`:

```bash
nano ~/.bashrc
```

Add this at the very end:

```bash
if [ "$(tty)" = "/dev/tty1" ] && [ -z "$WAYLAND_DISPLAY" ]; then
    cage -d -- foot -e bash -c "cd ~/manuscripts && ./run.sh"
fi
```

This only runs on the first console (tty1) and only if Wayland isn't already running, so SSH sessions are unaffected.

Reboot to test:

```bash
sudo reboot
```

The Pi should boot straight into Manuscripts.

## 7. Keyboard Shortcuts

### Projects Screen

| Key | Action |
|-----|--------|
| n | New manuscript |
| d | Delete manuscript |
| e | Toggle exports view |

Type in the search bar to filter manuscripts by name. Press the down arrow to move to the list.

### Editor

| Key | Action |
|-----|--------|
| Ctrl+R | Insert citation |
| Ctrl+N | Insert blank footnote |
| Ctrl+B | Bold |
| Ctrl+I | Italic |
| Ctrl+O | Manage sources |
| Ctrl+S | Save |
| Ctrl+M | Return to manuscripts |
| Ctrl+H | Toggle keybindings panel |
| Ctrl+P | Command palette |

### Workflow for Citations

1. Press `Ctrl+N` to insert a footnote (`^[]`)
2. With your cursor between the brackets, press `Ctrl+R` to search and insert a citation

## 8. Exporting

Open the command palette with `Ctrl+P` and select Export. Choose PDF, DOCX, or Markdown. Export progress is shown in the status bar at the bottom of the screen.

Exports are saved to `~/Documents/Manuscripts/exports/`.

## Troubleshooting

**"externally-managed-environment" error when running pip:**
Use the venv setup in step 3. Don't run `pip install` directly — always use `.venv/bin/pip`.

**App looks broken in the default terminal:**
Use Cage + Foot (step 5). The default Raspberry Pi terminal doesn't handle Textual's rendering well.

**Bold/italic text not highlighting:**
Make sure `tree-sitter` and `tree-sitter-markdown` are installed in the venv (step 3).

**Export takes a long time:**
This is normal on the Pi Zero 2W. The status bar shows progress so you know it's working.

**SSH into the Pi:**
You can also run Manuscripts over SSH from another computer. Your Mac/PC terminal handles the rendering fine: `ssh pi@<ip-address>` then `cd manuscripts && ./run.sh`.
