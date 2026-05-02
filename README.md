# LobeHub Flatpak Repository

Self-hosted Flatpak repository for LobeHub desktop app with automatic updates.

## Setup

### 1. Enable GitHub Pages
- Go to Settings → Pages
- Set Source to "GitHub Actions"

### 2. Add Repository to Your System
```bash
flatpak remote-add lobehub https://YOUR_USERNAME.github.io/lobehub-flatpak/repo.flatpakrepo
flatpak install lobehub com.lobehub.LobeHub
```

### 3. Updates
Updates are automatic:
```bash
flatpak update
```
Or wait for the daily cron job to fetch new versions from GitHub releases.

## How It Works
1. GitHub Actions runs daily checking for new LobeHub releases
2. `flatpak-external-data-checker` auto-updates the manifest
3. Flatter builds the Flatpak and publishes to GitHub Pages
4. Your system gets updates via `flatpak update`

## Security Notes for secureblue
- Flatpak sandboxing isolates the app from system
- No rpm-ostree layering = no reboots required
- Updates are atomic with rollback capability
- This follows secureblue's recommended app installation method
