# CyberPatriot System Hardening Checklist

> **Important:** Follow the challenge README exactly. It defines required users, groups, services, ports, software, and other exceptions. Complete forensic questions **before** making changes that could destroy evidence. Verify commands and service requirements before removing or disabling anything.

## Quick Rules

- **Google is your friend.** Look up anything you don't understand.
- If a command fails, review the error and syntax; use `sudo` only when administrator privileges are required.
- When a command contains a placeholder such as `$user`, replace it with the correct value—do not type the placeholder literally.
- Record changes, suspicious findings, removed malware, and anything needed for the forensic answers.
- When a step's order does not matter, use the checklist sections as a guide; prioritize the README and forensics first.

---

# Part 1 — General Workflow

## 1. Initial Setup and Forensics

- [ ] Load the image and add the team hash.
- [ ] Read the README carefully; read it again and record every instruction.
- [ ] Record explicitly allowed users, groups, ports, services, and software.
- [ ] Answer the forensic questions **before** changing the system.
- [ ] Record any evidence or information needed to answer the questions.
- [ ] Empty the Recycle Bin / Trash when appropriate after completing forensics.
- [ ] Keep notes of actions taken and anything removed.

## 2. Inspect the System

- [ ] Open Task Manager (Windows) or System Monitor / `top` / `ps aux` (Linux).
- [ ] Review running processes and resource usage for unusual activity.
- [ ] Review running services; document suspicious or unauthorized services.
- [ ] Review user profiles and accounts, including hidden or unexpected profiles.
- [ ] Check scheduled tasks (Windows) or cron / startup jobs (Linux).
- [ ] Review startup programs and resource-heavy items.
- [ ] Check installed applications and packages for unauthorized software or hacking tools.
- [ ] Check for suspicious open ports and network shares.
- [ ] Search for prohibited files and file types (the “Easter egg hunt”).
- [ ] Check service and system logs for unusual activity.

## 3. Users and Accounts

- [ ] Compare all users and groups with the README.
- [ ] Remove or disable unauthorized accounts and review associated files.
- [ ] Disable Guest access unless the README explicitly requires it.
- [ ] Confirm account types and administrator privileges are appropriate.
- [ ] Review privileged accounts, including Linux UID 0 accounts and sudo/admin groups.
- [ ] Review `sudoers` and `sudoers.d` for unexpected permissions or passwordless rules.
- [ ] Check SSH `authorized_keys` files for unknown keys.
- [ ] Set strong passwords and appropriate password / lockout policies.
- [ ] Secure root access; do not disable or lock accounts blindly if the README requires them.

## 4. Malware and Software

- [ ] Install and update the approved antivirus / anti-malware tool.
- [ ] Update antivirus definitions twice before running the scan, if required by the checklist.
- [ ] Run the scan; document findings and removals.
- [ ] On Linux, consider `rkhunter` and `chkrootkit` if appropriate and available.
- [ ] Remove unauthorized software and packages after verifying they are not required.
- [ ] Update required software (for example, browser, office suite, Adobe software, Bash, kernel, and README-listed services).
- [ ] Configure automatic updates.
- [ ] Check package integrity and repositories when appropriate.

## 5. Security Configuration

- [ ] Enable the host firewall.
- [ ] Apply appropriate inbound / outbound firewall rules and close unauthorized ports.
- [ ] Apply secure password and account lockout policies.
- [ ] Review local security policy and Group Policy (Windows).
- [ ] Enable relevant auditing and logging.
- [ ] Review browser security (for example, block unwanted pop-ups and automatic downloads).
- [ ] Review Internet Options (Windows).
- [ ] Disable remote access, file sharing, printer sharing, or database remote access **unless required by the README**.
- [ ] Review service configurations and ensure required services are legitimate and securely configured.
- [ ] Enable BitLocker if supported and appropriate.
- [ ] Review permissions and access-control lists.
- [ ] Check system hardening settings against the relevant baseline.
- [ ] Restart when needed to finish updates, then verify the settings again.

---

# Part 2 — Windows Checklist

## Windows Accounts and Policies

- [ ] Review Users and Groups; remove unauthorized users and their associated files where appropriate.
- [ ] Confirm each account has the correct account type and privileges.
- [ ] Disable Guest access unless explicitly required.
- [ ] Set strong passwords for existing users.
- [ ] Review Local Security Policy and Group Policy (`mmc.exe`).
- [ ] Configure password policies in accordance with the competition requirements and README.
- [ ] Configure account lockout policies.
- [ ] Enable auditing.
- [ ] Review scheduled tasks and startup items for persistence mechanisms.

### Password-policy notes from the supplied checklist

Use the policy required by the competition / README. The original notes list these example values:

- Minimum password length: **14 characters** (another section lists 8 or 10; confirm the required value).
- Password complexity: enabled.
- Reversible encryption: disabled.
- Password history: 5.
- Maximum password age: 30 days for administrators and 90 days for users (as listed in the notes).
- Minimum password age: 10–30 days (as listed in the notes).
- Account lockout duration: 30 minutes.
- Account lockout threshold: 3–10 invalid attempts.
- Reset lockout counter after: 30 minutes.

## Windows Firewall, Software, and Updates

- [ ] Ensure Windows Firewall is enabled.
- [ ] Install and run Microsoft Security Baseline Assessment, if required / available.
- [ ] Review installed software; remove applications that are not allowed or needed.
- [ ] Install Windows updates; restart later if needed, then restart and verify completion.
- [ ] Update third-party software (for example, Firefox, LibreOffice, and Adobe applications).
- [ ] Review browser security settings and Internet Options.
- [ ] Review services; disable only those confirmed unnecessary and not required by the README.
- [ ] Check listening ports and investigate unexpected listeners.
- [ ] Search the file system for prohibited file types and hidden files.
- [ ] Review Task Manager, startup applications, scheduled tasks, and resource usage.
- [ ] Enable BitLocker if supported and appropriate.
- [ ] Use Windows administrative tools in Control Panel as needed.

---

# Part 3 — Linux / Ubuntu Checklist

> Commands below are retained from the supplied notes as reference examples. Linux distributions and versions differ. Confirm the README and installed system before applying configuration changes. Review destructive commands carefully.

## 1. Users, Root, and SSH

- [ ] Review `/etc/passwd`, `/etc/group`, `/etc/sudoers`, and `/etc/sudoers.d`.
- [ ] Check which accounts have UID 0, can log in, and are allowed by the README.
- [ ] Remove unauthorized accounts only after confirming they are not required.
- [ ] Check home directories for unauthorized files and tools.
- [ ] Disable guest access if appropriate. The supplied notes reference `/etc/lightdm/lightdm.conf` and `allow-guest=false`.
- [ ] Secure SSH if SSH is required. The supplied notes reference `/etc/ssh/sshd_config` and `PermitRootLogin no`.
- [ ] Review `~/.ssh/authorized_keys` for unknown keys.
- [ ] Review sudo rules for unexpected `NOPASSWD` or authentication-bypass entries.

Useful inspection commands:

```bash
getent passwd
getent group
sudo ss -ln
service --status-all
systemctl list-units --type=service --all
ps aux
top
```

## 2. Passwords and Authentication

The supplied Linux notes list these example settings. Confirm the applicable policy and distribution before editing PAM or login configuration.

- `/etc/login.defs`: `PASS_MIN_DAYS 7`, `PASS_MAX_DAYS 90`, `PASS_WARN_AGE 14`
- `/etc/pam.d/common-password`: notes mention `minlen=8` or `minlen=10`, and `remember=3`
- `/etc/pam.d/common-auth`: notes mention removing `nullok` and configuring lockout
- Existing users may need policy applied separately with `chage`.

Example commands from the notes:

```bash
sudo chage -l username
sudo chage -M 90 -m 7 -W 14 username
```

Do not paste configuration fragments into PAM files without checking the existing syntax and the distribution's supported authentication modules.

## 3. Updates and Automatic Updates

- [ ] Update package lists and install security / system updates.
- [ ] Update the kernel, Bash, and README-required services.
- [ ] Configure automatic updates and daily update checks.
- [ ] Check that required applications and services are updated.

Example commands from the notes:

```bash
sudo apt update
sudo apt upgrade
sudo apt full-upgrade
sudo apt install unattended-upgrades
sudo dpkg-reconfigure unattended-upgrades
```

## 4. Firewall and Ports

- [ ] Check listening ports and compare them with the README.
- [ ] Investigate each unexpected listener and identify its owning process / package.
- [ ] Enable the firewall and set rules that match the required services.
- [ ] Recheck listening ports after changes.

Example commands from the notes:

```bash
sudo ss -ln
sudo lsof -i :PORT
whereis PROGRAM
dpkg -S /path/to/program
sudo ufw status verbose
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw logging on
```

Replace `PORT`, `PROGRAM`, and paths with the actual values. Do not remove packages or kill processes until you have verified what they are and whether they are required.

## 5. Services, Packages, and Malware

- [ ] Verify all services are legitimate and required.
- [ ] Review service configuration files for insecure settings.
- [ ] Disable or remove prohibited services only after checking the README.
- [ ] Inspect installed packages for unauthorized software or hacking tools.
- [ ] Check for rootkits using approved tools if appropriate.
- [ ] Review package repositories, trusted keys, and package integrity.
- [ ] Check scheduled jobs and startup scripts for suspicious persistence.

Example commands from the notes:

```bash
service --status-all
systemctl list-units --type=service --all
sudo crontab -l
sudo ls /etc/cron.*
cat /etc/crontab
sudo find / -perm /6000 -type f 2>/dev/null
```

## 6. Files and Permissions

- [ ] Search home directories and the file system for unauthorized media, archives, pictures, and tools.
- [ ] Review hidden files and directories.
- [ ] Check permissions on sensitive files and user home directories.
- [ ] Review suspicious SUID binaries.
- [ ] Check mounted filesystems and shared directories.

Useful commands:

```bash
ls -la
ls -Ra
find /dir/ -name 'name*'
find /dir/ -user username
find /dir/ -mmin 30
file filename
```

Be careful with recursive searches and permission changes. Do not blindly apply broad permission commands to every home directory or system file.

## 7. Additional Linux Hardening

- [ ] Review sysctl settings and network protections against an appropriate baseline.
- [ ] Review IPv6 configuration; disable it only if the README and network requirements allow.
- [ ] Review `umask`, session timeout, and account expiry defaults.
- [ ] Review GRUB security settings only if required and understood.
- [ ] Consider AIDE, Fail2ban, and Lynis if allowed and appropriate for the image.
- [ ] If Apache is allowed, review its security configuration.
- [ ] If MySQL is installed, review whether remote access is required and disable it if not.
- [ ] Review CUPS / printer sharing and network shares.
- [ ] Verify all changes and ensure required services still work.

---

# Part 4 — Easter Egg Hunt / Prohibited Files

- [ ] Search user directories and common application folders.
- [ ] Enable viewing hidden files in the file manager.
- [ ] Search for prohibited media, archives, games, and hacking tools as defined by the README.
- [ ] Inspect suspicious files before deleting them; preserve anything needed for forensic questions.
- [ ] Check application directories and startup locations.
- [ ] Document what was removed.

Example Linux file-type search (review the patterns and scope before running):

```bash
sudo find / -type f \( \
  -iname '*.mp3' -o -iname '*.mp4' -o -iname '*.avi' -o \
  -iname '*.mkv' -o -iname '*.wav' -o -iname '*.ogg' -o \
  -iname '*.flac' -o -iname '*.zip' -o -iname '*.rar' -o \
  -iname '*.7z' -o -iname '*.png' -o -iname '*.jpg' -o \
  -iname '*.jpeg' -o -iname '*.gif' \
\) 2>/dev/null
```

---

# Part 5 — Useful Command-Line Reference

## System and Navigation

| Command | Purpose |
|---|---|
| `pwd` | Show the current directory |
| `ls -la` | List files, including hidden files |
| `ls -R` | List directories recursively |
| `cd folder` | Change directory |
| `cd ..` | Move up one directory |
| `cd -` | Return to the previous directory |
| `whoami` | Show the current user |
| `w` | Show logged-in users |
| `uptime` | Show system uptime |
| `date` | Show system date and time |
| `uname -a` | Show system and kernel information |
| `head -n 1 /etc/issue` | Show the first line of the issue file |
| `mount` | Show mounted filesystems |
| `df -h` | Show free disk space |
| `free` | Show memory and swap usage |

## Files and Searching

| Command | Purpose |
|---|---|
| `cat file` | Print file contents |
| `less file` | View a file page by page |
| `head file` / `tail file` | Show the start / end of a file |
| `grep pattern file` | Search for a pattern |
| `grep -i pattern file` | Search case-insensitively |
| `grep -r pattern dir` | Search recursively |
| `grep -v pattern file` | Show lines that do not match |
| `find /dir -name 'name*'` | Find files by name |
| `find /dir -user username` | Find files owned by a user |
| `whereis command` | Find binary, source, or manual locations |
| `which command` | Locate a command |
| `file filename` | Identify a file type |
| `cp source destination` | Copy a file |
| `cp -r source destination` | Copy a directory recursively |
| `mv source destination` | Move or rename a file |
| `mkdir folder` | Create a directory |
| `rmdir folder` | Remove an empty directory |
| `rm file` | Remove a file — use caution |
| `chmod mode file` | Change permissions — use caution |
| `chown user:group file` | Change file ownership — use caution |
| `ln -s source destination` | Create a symbolic link |

## Processes and Services

| Command | Purpose |
|---|---|
| `ps aux` | List processes |
| `top` | Monitor processes in real time |
| `systemctl list-units --type=service --all` | List services |
| `service --status-all` | Show service status |
| `kill PID` | Send a signal to a process |
| `pkill name` | Signal processes by name |
| `killall name` | Signal processes by name |

## Archives and Encryption

| Command | Purpose |
|---|---|
| `tar -cf archive.tar file1 file2` | Create a tar archive |
| `tar -xf archive.tar` | Extract a tar archive |
| `tar -czf archive.tar.gz file1 file2` | Create a gzip-compressed tar archive |
| `tar -xzf archive.tar.gz` | Extract a gzip-compressed tar archive |
| `gzip file` | Compress a file |
| `gzip -d file.gz` | Decompress a gzip file |
| `gpg -c file` | Encrypt a file with GPG |
| `gpg file.gpg` | Attempt to process a GPG file; use the appropriate decryption command / options for the file |

## Package Management

| Command | Purpose |
|---|---|
| `sudo apt update` | Refresh package lists |
| `sudo apt upgrade` | Upgrade installed packages |
| `dpkg -i package.deb` | Install a local Debian package |
| `apt-cache policy package` | Show package versions and repository policy |
| `dpkg-query -l` | List package information |

## SSH and Keyboard Shortcuts

| Shortcut / Command | Purpose |
|---|---|
| `ssh user@host` | Connect to a remote host |
| `ssh user@host -p PORT` | Connect using a specified port |
| `scp file user@host:/path` | Copy a file to a remote host |
| `Ctrl + Shift + C` | Copy selected terminal text |
| `Ctrl + Shift + V` | Paste into the terminal |
| `Ctrl + C` | Interrupt the current command |
| `Ctrl + R` | Search command history |
| `Ctrl + A` / `Ctrl + E` | Move to start / end of command line |
| `Ctrl + U` / `Ctrl + K` | Clear from cursor to start / end of line |
| `Ctrl + Z` | Suspend the current foreground process |

---

# Part 6 — Final Verification

- [ ] Re-read the README and confirm every required action is complete.
- [ ] Confirm forensic questions are answered and evidence was preserved.
- [ ] Confirm allowed users, groups, ports, services, and software remain functional.
- [ ] Confirm firewall is enabled and only required ports are exposed.
- [ ] Confirm updates and antivirus scans completed.
- [ ] Confirm password policies, auditing, browser settings, and security policies.
- [ ] Confirm suspicious scheduled tasks, processes, startup items, and files were investigated.
- [ ] Restart if required for updates, then recheck firewall, services, users, and ports.
- [ ] Record any unresolved issue instead of making an uncertain change.

**Remember:** Google anything you do not understand—but verify that the instructions match the operating system version and the challenge README.
