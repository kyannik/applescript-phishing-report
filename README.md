[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GitHub Pages](https://img.shields.io/badge/docs-GitHub%20Pages-brightgreen)](https://kyannik.github.io/applescript-phishing-report/)

# Phishing Report — Quick Action for Apple Mail

**One-click phishing reporting from Apple Mail.** Select a suspicious email, press a shortcut, and it's forwarded as a `.eml` attachment to three reporting services — with full original headers preserved.

## Why report phishing?

Most people just delete phishing emails. But reporting them helps:

- **Take down phishing sites** — services like Netcraft actively shut down fraudulent pages
- **Protect others** — reported emails feed into blocklists used by email providers worldwide
- **Train detection systems** — organizations like APWG use reports to improve automated filters

This Quick Action makes reporting as easy as pressing a keyboard shortcut. No copy-pasting URLs, no filling out web forms — just select and report.

---

## What does it do?

Forwards selected email(s) in Apple Mail as `.eml` attachments to three phishing reporting services.
Each selected email is sent as its own separate report — one report email per phishing message.
Original headers (IP, DKIM, Return-Path, Received chain, SPF, Authentication-Results etc.) are fully preserved.

### Recipients

| Address | Organization | Scope |
|---------|-------------|-------|
| `reportphishing@apwg.org` | Anti-Phishing Working Group | Global |
| `scam@netcraft.com` | Netcraft (Takedown Service) | Global |
| `phishing@verbraucherzentrale.nrw` | Verbraucherzentrale NRW | Germany |

### Report format

Each report email contains:
- **Subject:** `[Phishing Report] 2026-04-03T14:32:05 #1` (timestamp + sequential index)
- **Body:** Structured metadata (sender, subject, date received) for quick analyst triage
- **Attachment:** The original phishing email as `.eml` with full headers

---

## Compatibility

- Requires macOS 10.14 (Mojave) or newer
- Tested with Apple Mail and Automator
- Works with IMAP and POP accounts (email must be fully downloaded)

---

## Install (one-time, ~5 minutes)

### Step 1: Download the script

Download [`report_phishing.applescript`](report_phishing.applescript) or clone this repo:

```bash
git clone https://github.com/kyannik/applescript-phishing-report.git
```

### Step 2: Create Quick Action in Automator

1. Open **Automator** (Spotlight → "Automator")
2. **New Document** → choose **Quick Action**
3. Set at the top:
   - "Workflow receives": **no input**
   - "in": **Mail.app**
4. Search the action library on the left: **"Run AppleScript"**
5. Drag the action into the workflow area
6. Paste the entire contents of `report_phishing.applescript`
7. Save as: **"Report Phishing"**

### Step 3: Assign keyboard shortcut (optional)

1. **System Settings** → **Keyboard** → **Keyboard Shortcuts**
2. Select **"Services"** on the left
3. Under **"General"** or **"Mail"** find **"Report Phishing"**
4. Assign a shortcut, e.g.: `⌃⌥⌘P` (Ctrl+Option+Cmd+P)

### Step 4: Grant permissions (first run)

macOS will automatically prompt for permissions on first run — just click "OK".

If the dialog was accidentally dismissed:
- **System Settings** → **Privacy & Security** → **Automation**
- Allow **Automator** to control **Mail**

If file access errors occur:
- **System Settings** → **Privacy & Security** → **Full Disk Access**
- Enable **Automator**

---

## Usage

### Via right-click:
1. Select email(s) in Mail
2. Right-click → **Services** → **Report Phishing**

### Via keyboard shortcut:
1. Select email(s) in Mail
2. Press shortcut (e.g. `⌃⌥⌘P`)

### What happens:
- Each selected email is reported as a **separate** message with one `.eml` attachment
- Selecting 5 emails → 5 report emails are sent, each with subject `[Phishing Report] ... #1` through `#5`
- No review window — press the shortcut and it's done
- Emails not fully downloaded (IMAP) are skipped with a notice

### Review mode (optional):

To review each report before sending, change these lines in the script:
```applescript
-- Comment out or delete this line:
-- send newMessage

-- Insert instead (before "end if"):
set visible of newMessage to true
activate
```
This opens the compose window for manual review before sending.

---

## QA and known quirks

This script has been tested against known Apple Mail AppleScript issues:

| Issue | Mitigation |
|-------|------------|
| **Async attachment bug** — Mail.app sends before attachments finish loading | `delay 2` before each `send` call |
| **IMAP partial download** — `source` returns empty for undownloaded messages | Guard checks for `missing value` / empty string, skips with notice |
| **File handle leak** — error during write leaves file handle open | Nested `try` block in error handler ensures `close access` |
| **Filename collision** — rapid re-runs overwrite temp files | Timestamp in filenames (`phishing_20260403_143205_1.eml`) |
| **Temp file cleanup** — `.eml` files with sensitive content left on disk | Automatic deletion after send |

---

## Notes

- The `.eml` file contains all headers and the text body of the original email. Binary attachments of the phishing mail are not fully included in Mail.app's raw source (irrelevant for header analysis).
- Temp files are automatically deleted after sending.
- Some email providers have their own spam reporting mechanisms (e.g., via webmail). Check if your provider offers one and use it in addition to this script.
- iCloud spam can optionally also be reported to `abuse@icloud.com`.

---

## Customization

### Change recipients
Edit the `reportAddresses` list at the top of the script:
```applescript
set reportAddresses to {"reportphishing@apwg.org", "scam@netcraft.com", "phishing@verbraucherzentrale.nrw"}
```

### Send from a specific account
Add a `sender` property if you have multiple Mail accounts:
```applescript
set newMessage to make new outgoing message with properties {subject:reportSubject, content:reportBody, sender:"you@example.com"}
```

---

## Contributing

Contributions are welcome! Please:

1. Fork the repo
2. Create a feature branch (`git checkout -b my-feature`)
3. Test with Apple Mail on your macOS version
4. Submit a PR with a description of what you changed and why

If you find a bug, please [open an issue](https://github.com/kyannik/applescript-phishing-report/issues) with your macOS version and a description of what happened.

---

## License

[MIT](LICENSE) — use it, modify it, share it.
