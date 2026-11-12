# CP Windows Checklist Audit

**Audited file:** `Windows/CP_WINDOWS_CHECKLIST.md` at commit `3b488e1` (after the 2.5 web-server split). Line numbers (`L123`) refer to that version.
**Scope:** the checklist only. The scripts were not audited.
**Evidence used:**
- the checklist itself
- `Windows/Scripts/ToDo.md`, a list of points missed on a practice image
- the competition debriefs and the "do not do unless told by the README" pages in `ULTIMATE CYBERPATRIOT WINDOWS CHECKLIST.pdf`. The markdown checklist lost those pages when it was converted.

Severity:
- **P1** means points are being missed or a scored service can break. Fix before competition.
- **P2** means the checklist is wrong or contradicts itself.
- **P3** is cleanup.

---

## 1. Top 10 fixes before competition

| # | Fix | Why | Where |
|---|-----|-----|-------|
| 1 | Add a **"Turn on Windows Defender Firewall (all profiles)"** step | The checklist never tells you to turn the firewall on. It was scored twice in Comp 3 ("Points for ... turning on the firewall"). | new item in 1.2 |
| 2 | Add exact **Configure Automatic Updates** GPO steps | ToDo #25 *"Windows automatically checks for updates"* was missed. L75 says to "configure automatic updates in Group Policy" but gives no path or values. | 1.1 #1 |
| 3 | Add **"Enumerate administrator accounts on elevation: Disabled"** | ToDo #21 was missed. The setting is not in the checklist anywhere. | 1.2 #1 or 1.3 #6 |
| 4 | Add explicit steps to **delete unauthorized users** and **remove non-README users from Administrators** | ToDo #4, #6 and #7 were missed (`alana`, `tina`, `peterson`). Section 1.4 #2 is a reference table with no steps for checking group membership. | 1.4 |
| 5 | Fix the share guidance: hidden `NAME$` shares are not default, and DCs need `NETLOGON` and `SYSVOL` | ToDo #22 *"hidden share USERS$"* was missed. The default-share list (L1002) omits `print$`, `NETLOGON` and `SYSVOL`, so following it on a DC breaks AD. | 1.5 #5, 2.2 #2 |
| 6 | Remove or flag settings that can **break scored services** | See section 3 of this audit: Restrict NTLM deny-all, CrashOnAuditFail, user rights without IIS/SQL exceptions, Apache `Listen <ip>`, MariaDB `skip-symbolic-links`, removing `BUILTIN\Administrators` from sysadmin. | 1.3, 2.5.2, 2.6 |
| 7 | **Restore the lost sections** (2.15 and 3.1–3.6) from the PDF and settle the contradictions | The TOC links to seven sections that don't exist. The PDF's do-not-do list contradicts the main sections. | TOC L39-L47 |
| 8 | Change `compmgnt.msc` to **`compmgmt.msc`** | The name is misspelled in all 5 places (L14, L520, L522, L567, L568). Typing it into Win+R fails. | 1.5 |
| 9 | **Fix every TOC anchor** | GitHub generates `#11-settings-app` from `## 1.1 Settings App`, but the TOC uses `#settings-app`, so every TOC link is broken. | L9-L47 |
| 10 | Add a **competition-day runbook** and a **README decision sheet** at the top | The README-dependent choices are scattered across 20 sections, and the "answer forensics before deleting anything" warning is buried in 1.11 #3. | new section 0 |

---

## 2. Missing items that cost or earn points (P1)

Each row comes from `ToDo.md` (missed on a practice image) or a debrief in the PDF.

| Scored item | Evidence | Checklist today | Add |
|-------------|----------|-----------------|-----|
| Firewall enabled | Comp 3 Win10 and Server 2019 debriefs | Missing. The only firewall content is individual rules (L166, L1029, L1077). | `wf.msc` → turn the firewall on for Domain, Private and Public, inbound **Block**, outbound Allow. CLI: `netsh advfirewall set allprofiles state on`. Also check `gpedit` → Network → Network Connections → Windows Defender Firewall for a planted "Protect all network connections: Disabled". |
| Windows automatically checks for updates | ToDo #25, Comp 4 README, Server 2022 semis ("allow auto updates, immediate installation") | Vague (L75) | `gpedit` → Windows Components → Windows Update → **Configure Automatic Updates = Enabled, 4 – Auto download and schedule the install**, plus **Allow Automatic Updates immediate installation = Enabled**. Check for sabotage too: "Specify intranet Microsoft update service location" pointing at a fake server, "Remove access to use all Windows Update features", and `wuauserv` set to Disabled. |
| Enumerate administrator accounts on elevation: Disabled | ToDo #21 | Missing | `gpedit` → Windows Components → Credential User Interface. Registry: `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\CredUI\EnumerateAdministrators = 0`. |
| Unauthorized user removed | ToDo #4, Comp 1/3 debriefs (hamburgerman, romeo, Trent) | One bullet (L472) | A step-by-step diff of `net user` against the README, with a note that `net user` also lists users that `lusrmgr` filters out of view. |
| "User X is not an administrator" | ToDo #6, #7, Comp 1 (Twellick, Davis), Comp 3 (cmoss) | No steps | `net localgroup Administrators` should contain only the README admins and the built-in Administrator. |
| Hidden share disabled | ToDo #22 (USERS$) | Not covered | Any share ending in `$` other than `ADMIN$`, `IPC$` and drive letters (`C$`, `D$`) is not a default share. |
| Prohibited MP3s removed | ToDo #27 | Present but buried (1.11 #3) | Move it into the runbook, after forensics. |
| Netcat backdoor removed | ToDo #31 | 1.7 only covers *running* processes | Add a file search: `where /r C:\ nc.exe ncat.exe nc64.exe`. Also check services, tasks and Run keys that point at it. |
| Plain-text password file removed | Comp 3 ("Deleted plain text file in shared documents") | Missing | Check `C:\Users\Public\Documents` and each user's Desktop/Documents for `*pass*`, `*cred*` and `*.txt` lists of credentials. Read them before deleting, because they are often forensics material. |
| Scan exclusion removed | Comp 3 Forensic 2 (sysinternals.exe) | Present (L583) | Add the **policy** location as well: `gpedit` → Microsoft Defender Antivirus → Exclusions. Exclusions set there are hidden/greyed in the Windows Security UI. |
| Defender turned back on | Common trick | Missing | `gpedit` → Microsoft Defender Antivirus → "Turn off Microsoft Defender Antivirus" and the Real-time Protection policies must be **Not Configured or Disabled**. The UI toggles are greyed out while a policy is set. |
| Third-party apps updated | Thunderbird, Notepad++, 7-Zip, LibreOffice, Chrome, Wireshark, FileZilla, WinRAR (Comps 2–4) | Listed (2.13) | Add `winget upgrade --id <id>` commands. That is the biggest speed win in section 2. |
| Edge removed when README names another browser | Server 2022 semis | Missing | A conditional step in 2.4 #5. |
| PowerShell transcription and script block logging | Server 2022 semis | Present (1.10 #1) | No change. |
| Admin and Guest accounts disabled | Server 2022 semis | Present (L321) | Add the caveat in section 3. |
| `users.bat` deleted | Server 2022 semis | In the list (L1678) | Add a search method, as for netcat. |

Other gaps worth adding (all low risk):
- **Winlogon `AutoAdminLogon` / `DefaultPassword`:** a plaintext password stored in the registry.
- **IFEO `Debugger` hijack:** `HKLM\...\Image File Execution Options\sethc.exe` set to cmd.exe. 1.11 #6 only checks for a replaced file.
- **Hosts file redirect via `Tcpip\Parameters\DataBasePath`.**
- **`WDigest\UseLogonCredential = 0`.**
- **Include command line in process creation events.**
- **Disable the "Windows PowerShell 2.0" feature.**
- **SNMP and OpenSSH Server as Optional Features.** On Windows 10/11 they are under Settings → Optional features, not Windows Features.
- **Recycle Bin check:** prohibited files and evidence end up there.
- **Remote-access tools in 2.14:** AnyDesk (Comp 2 forensics referenced its ports), TeamViewer, VNC servers. Also add **Tor Browser**, which is portable and never appears in Programs and Features.

---

## 3. Items that can break a scored service or lock you out (P1)

The checklist currently says to do each of these unconditionally.

| Line | Item | Risk | Recommendation |
|------|------|------|----------------|
| L330, L422 | Audit: Shut down system immediately if unable to log security audits = **Enabled** | The VM blue-screens when the Security log can't be written, and afterwards only admins can log on. CIS says **Disabled**. | Set Disabled and drop the "Strict" alternative. |
| L391 | Restrict NTLM: Incoming NTLM traffic = **Deny all** | Local accounts can't use Kerberos, so RDP (NLA/CredSSP) and SMB logons fail. That kills a required RDP or file-sharing service. | Move to the do-not-do list ("Audit only" at most). |
| L392 | Restrict NTLM: NTLM authentication in this domain = **Deny all** | On a DC, anything not using Kerberos breaks. | Move to the do-not-do list. |
| L301, L302, L296 | Batch logon = Admins + Backup Operators. Service logon = SYSTEM/LOCAL/NETWORK SERVICE only. Impersonate without IIS_IUSRS. | IIS app pools need `IIS_IUSRS` (CIS lists it as an exception for Impersonate, and app pools fail with "not granted the requested logon type" without batch logon). SQL Server, Apache and MariaDB services running under a service or user account stop starting once their account loses "Log on as a service". | Add: "If IIS is installed, keep IIS_IUSRS. Before removing an account from Log on as a service, check `services.msc` → Log On As." |
| L321 | Administrator account status = Disabled | Locks you out if your own account isn't really an admin. | "Only after confirming your (you) account is in Administrators and can elevate." Disabling scored in the Server 2022 semis, so keep the step. |
| L476 | "User must change password at next logon" for all users | Breaks any service or scheduled task that runs as that user. Not normally scored. | Make it optional and skip service accounts. |
| L1214-L1216 | Apache `Listen 192.168.1.100:80` | Binding to one IP drops `localhost`/127.0.0.1, which the scoring check or the web app may use. | Keep `Listen 80` unless the README names an IP. |
| L1234 | Apache `AllowOverride None` | Breaks apps that rely on `.htaccess` (WordPress, Laravel and similar). Comp 4's README said "keep this web application running" with "minimal changes". | Check `htdocs` for `.htaccess` first. |
| L1227 | htdocs Full Control only for SYSTEM and Administrators | Breaks the site if Apache runs as another account, and breaks PHP upload/cache folders. | Check the Apache service's "Log On As" first. |
| L1315 | `skip-symbolic-links` in `my.ini` | Deprecated in MySQL 8 and may be rejected by newer builds. An unknown option stops `mysqld` from starting, and the database-backed app goes down with it. | MariaDB only. Restart the service and confirm it is running immediately afterwards. |
| L1316 | `bind-address = 127.0.0.1` | Breaks remote database clients if the README requires them. | Conditional on the README. |
| L1275 | Remove `BUILTIN\Administrators` from sysadmin | You can lock yourself out of SQL Server if no other sysadmin login is known. | First confirm you can log in with another sysadmin login. |
| L1279 | Enable C2 Audit Mode | Deprecated. SQL Server **shuts down** if it can't write the audit file, and the file fills the disk. | Delete. |
| L1019 | `RejectUnencryptedAccess $true` | Clients without SMB3 encryption get refused. | Fine on modern images. Add "unless legacy clients use the share". |
| L629 / L620-L626 | System-wide Mandatory ASLR (`ForceRelocateImages`) | Known to break some older applications. | Keep, but note it as the first thing to undo if a scored app stops working. |
| L610 | Controlled Folder Access On | Blocks non-Microsoft editors (Notepad++ etc.) from saving into Desktop/Documents, including the Forensics Question files. | Answer forensics first, or allow the editor. |
| L954 | Remove Server roles not in the README | Roles take a long time to reinstall and their configuration is lost. | "Remove only roles the README clearly doesn't need. When unsure, leave the role and harden it." |
| L961 | Remove Windows Internal Database | WSUS, RDS Connection Broker and ADFS depend on it. | Check for those roles first. |

---

## 4. Technical errors and contradictions (P2)

**Settings and values**

| Line | Problem | Fix |
|------|---------|-----|
| L95 | Delivery Optimization says to use "Simple (99) or Bypass (100)" to disable peering. Bypass is deprecated on Windows 11. | Use **HTTP only (0)**. |
| L140-L141 | The screen saver path mentions "Hardware and Sound → Power Options", but the screen saver isn't there. 10 min here vs. "900 s or less" at L365. | Remove the Power Options path and pick one timeout (≤ 900 s). |
| L239-L264 | The checklist sets both the legacy Audit Policy and the Advanced Audit Policy without explaining how they interact. Once "Force audit policy subcategory settings" is Enabled (L333), the legacy settings are ignored. | Keep both, because some checks read the legacy view, but say so. Raise the Security log size: CIS asks for ≥ 196,608 KB, while L534 says 16–64 MB, and Success+Failure on every subcategory fills 64 MB quickly. |
| L358 | Cached logons "0 to 10 ... 0/2" is not an instruction. | Pick one (CIS: ≤ 4; it doesn't matter on non-domain machines). |
| L370 | "(if client agrees): ... Disabled if requiring strict enforcement" is backwards. The "(always)" setting is what enforces signing. | Enabled, and delete the parenthetical. |
| L390 | Force logoff when logon hours expire: "Disabled (or Enabled)". | **Enabled** (CIS). |
| L468 | "Standard Users: Administrator, DefaultAccount, Guest, WDAGUtilityAccount". These are built-in accounts, not standard users. | Rename the label to "Built-in accounts". |
| L483 vs L1685-L1686 | Three different "standard" passwords: `C1sc0!314159@SVT`, `C1sc0!314159???` (also used in the debriefs) and `CyberP12345@SVT`. | Pick one and use it everywhere. |
| L553 | The GUI step filters the **Security** log for 7045, but 7045 is logged in the **System** log. The PowerShell example at L563 correctly uses System. | Split the IDs by log. 4697 also needs "Audit Security System Extension". |
| L629 | The PowerShell command doesn't match the GUI list at L620-L626: it is missing CFG and heap integrity. | `Set-ProcessMitigation -System -Enable DEP,CFG,BottomUp,ForceRelocateImages,SEHOP,TerminateOnError` |
| L588 | A full scan takes a long time on a competition VM. There is no signature-update step. | Update signatures, run a Quick scan, and start the Full scan in the background while you work. |
| L853-L854 | `sfc` is listed before `DISM`. | Run DISM `/RestoreHealth` **first**, then `sfc /scannow`. Start it early, because it takes 15–30 min. |
| L867 | `dir /s /b C:\*.mp3 ...` also matches `C:\Windows\Media\*.wav` (system sounds) and app assets. | Search `C:\Users` and other non-system folders, and say "never delete from `C:\Windows` or `Program Files`". Delete image files (`.png/.jpg/.gif`, L865) only after judging each one. |
| L1064 | "SSL (TLS 1.0)". The GPO option is "SSL", which negotiates the highest TLS version. "Negotiate" is weaker. On Server 2008 R2/2012 without updates, RDP over SSL needs TLS 1.0, which 1.2 #7 disables. | "SSL", plus a note: don't disable TLS 1.0 on 2008/2012 if RDP is required. |
| L1155 | `Get-Package \| Uninstall-Package` only removes MSI-provider entries. EXE-installed browsers don't uninstall this way. | Use Programs and Features or `winget uninstall`. |
| L1187 | Extended Protection "(IIS 6, IIS 7, IIS 7.5)" is an outdated version list. | Remove the version list. |
| L1467 | IPv6 `DisabledComponents = 0xFF` is unsupported by Microsoft (Microsoft recommends `0x20`, prefer IPv4). | Uncheck the adapter binding when the README says to. Use 0x20 otherwise. |
| L1489 | `SynAttackProtect` is ignored on Vista and later (SYN protection is built in). | Keep it if you like, but label it a no-op. |
| L1500-L1504 | Says "Turn off multicast name resolution" turns off LLMNR **and mDNS**. It only disables LLMNR. This step also duplicates #3. | mDNS: `HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters\EnableMDNS = 0`. |
| L1494 | WPAD service: on Windows 10 1809+ the Startup type is greyed out in `services.msc`. | Use the registry instead: `...\Services\WinHttpAutoProxySvc\Start = 4`. |
| L1622 | "uninstall obsolete legacy runtimes (Java 6, 7, 8)". Java 8 is still a supported LTS. | "Remove if unauthorized or out of date. Update if the README requires it." |
| L1677 | `nginx.exe` is listed as a malicious binary. | nginx can be a required web server. Mark it "check README". |
| L667 | `SharpChrome` is listed as adware. | It is a credential-theft tool (GhostPack). Same action, more accurate label. |

**Process gaps**

| Line | Problem | Fix |
|------|---------|-----|
| L697, L715 | "(`Microsoft` exclusions)" and `-notlike "\Microsoft*"` skip planted tasks hidden under `\Microsoft\Windows\...`. | Skim the Microsoft folders for tasks whose actions point outside `System32`. |
| L719 | Unregistering a task destroys evidence. | Export the XML first (`Export-ScheduledTask`). |
| L734-L735 | WMI removal deletes consumers and filters but leaves `__FilterToConsumerBinding` orphaned. It also misses `ActiveScriptEventConsumer`. | Remove bindings first, then consumers (both types), then filters. |
| L823 | Execution policy: setting `RemoteSigned` through **GPO** overrides `-ExecutionPolicy Bypass`, so scripts downloaded from GitHub (Mark-of-the-Web) stop running. | Use `-Scope LocalMachine` only (as written), and add "run `Unblock-File` on downloaded scripts". |
| L1006 | "Stop Sharing on ... system-drive shares (`C_drive`)" | Add: never remove `ADMIN$`, `IPC$`, `C$`, `print$` (if printing), or `NETLOGON`/`SYSVOL` (DC). |
| L1526-L1530, 2.11 | No warning that **on a DC, `secpol.msc` changes are overridden** by the Default Domain Policy (account policy) and the Default Domain Controllers Policy (user rights and security options). There are no steps for domain user cleanup. | Add "On a DC, make 1.3 changes in `gpmc.msc`, not `secpol.msc`". Add ADUC steps for unauthorized domain users and for Domain/Enterprise/Schema Admins membership. |
| L1552 | No warning that resetting SPN/service-account passwords breaks the services that use them. | Add the warning, or update each service's logon. |
| L1572-L1596 | 2.12 #2 and #4 repeat Point and Print. | Merge them. |

**Duplicate topics** (pick one home for each and cross-reference from the other):

| Topic | Appears in |
|-------|------------|
| AutoRun | 1.1 #2, 1.9 #1 |
| Restrict anonymous / LimitBlankPasswordUse | 1.3 #6, 1.9 #2 |
| Clear pagefile | 1.3, 1.9 #3 |
| UAC | 1.2 #1, 1.3 UAC options |
| SmartScreen | 1.6 #2, 2.4 #4 |
| Scheduled tasks | 1.8, 1.10 #4 |
| SMB shares | 1.5 #5, 1.10 #9, 2.2 #2 |
| WPAD | 1.2 #7, 2.10 #5 |
| LLMNR/mDNS | 2.10 #3, #6 |

---

## 5. Lost content: section 2.15 and section 3 (P1)

The TOC (L39-L47) links to **2.15 Critical Policies: Do NOT Do Unless Instructed by README**, a **`# 3.`** heading and **3.1–3.6**. None of these exist. 3.7 sits directly under 2.14 with no parent heading.

The original material is in `ULTIMATE CYBERPATRIOT WINDOWS CHECKLIST.pdf`:
- the "All of this and below are do not do unless told by the read me!" block
- the Comp 1 / Comp 2 / Comp 3 Gold / Comp 4 Gold Semifinals debriefs (forensics answers and scored items)
- the full Comp 4 README (the E-Corp scenario)

Restore it.

The PDF's do-not-do list **contradicts** the main checklist, which tells you to do most of these items unconditionally. The team needs to settle each one. My recommendation per item:

| PDF "do not do" item | Checklist does it at | Recommendation |
|----------------------|----------------------|----------------|
| NTLMv2-only (refuse LM and NTLM) | 1.3 L387 | **Do it.** Commonly scored and low risk on Win10+/2016+. Skip only if the README mentions legacy clients. |
| Restrict anonymous access | 1.3 L376-L377, 1.9 #2 | **Do it.** It was scored in Comp 3 ("Do not allow anonymous enumeration of SAM accounts and shares"). |
| Rename/disable the built-in Administrator | 1.3 L321 | **Disable** after verifying your own admin login (scored in the Server 2022 semis). Renaming is optional. |
| Credential Guard | 2.1 L948 (mention) | **README only.** Needs VBS and can break VMs. |
| Disable SMBv1 | 2.1, 2.2 #1 | **Do it**, unless the README mentions XP/2003-era clients. |
| Disable Remote Registry | 2.7 #2, 2.9 | **Do it**, unless the README requires remote management. |
| Disable Print Spooler | 2.12 #1 | **Only if there is no printing in the README.** The current heading already says this. |
| Restrict PowerShell Remoting | 2.7 #1 | **Follow the README.** Comp 4 *required* WinRM for named users. |
| Command-line process auditing | missing | **Add it.** Harmless. |
| Advanced auditing | 1.3 #4 | **Do it.** "Audit computer account management" scored in Comp 3. |
| LSASS RunAsPPL | not in checklist | **README only.** Needs a reboot. |
| System32 permission changes | not in checklist | **Never.** |
| Disable LLMNR | 2.10 #3 | **Do it.** Harmless. |
| SYN flood protection | 2.10 #4 | Harmless no-op (see section 4). |

Add the items from section 3 of this audit (Restrict NTLM deny-all, CrashOnAuditFail, removing roles) to the restored 2.15 as well.

---

## 6. Structure and navigation (P2/P3)

| Line | Problem | Fix |
|------|---------|-----|
| L9-L47 | Every TOC anchor is wrong. GitHub anchors keep the number: `#11-settings-app`, `#1-general-security-settings-and-configurations`, `#251-internet-information-services-iis`. | Regenerate the anchors. |
| L319-L420 | The Security Options sub-groups (`### Accounts`, `### Audit`, …, `### Safe Alternative settings`) are the same heading level as the numbered items (`### 6.`). They show up as siblings of item 6 instead of children. | Change them to `####`. |
| L57-L63 | "Other security and compliance tools" (LGPO / Policy Analyzer) is an unnumbered `##` before 1.1. It has typos ("administator", "Select the your baseline") and placeholder paths. | Move it to an appendix or into 1.3, and finish the steps. |
| whole file | `$\to$` is LaTeX math. It renders on GitHub but shows up literally in many viewers and PDF exports. | Replace it with `→` or `>`. |
| whole file | `*` and `-` bullets are mixed. Stray blank lines in "Safe Alternative settings" (L420-L458). | Normalize. |
| L1445 | `**Bluetooth Support Service\` (\`bthserv\`)` — the bold and backtick are mismatched, so it renders broken. | `**Bluetooth Support Service** (\`bthserv\`)` |
| L82-L87 | Privacy section is vague ("where appropriate", "untrusted desktop applications"). | Give concrete toggles or remove it. |
| — | Items don't say whether they depend on the README, need a reboot, or are scored vs. defense-in-depth. | Add a tag per item (see section 8 of this audit). |

---

## 7. Speed: what can be set without clicking through GUIs

These are checklist items that are pure settings toggles. They are candidates for scripting, or for one-line commands in the checklist. I haven't checked them against the existing scripts.

| Mechanism | Checklist items |
|-----------|-----------------|
| **One `secedit` security template** (account, lockout, user rights, security options) | 1.3 #1, #2, #5, #6 (about 120 settings). The legacy audit policy can go in the same template (`[Event Audit]`). |
| **`auditpol`** | 1.3 #4 (one command per category) |
| **Registry / Administrative Templates** | 1.1 #2, #4–#7, 1.2 #1, #2, #7, 1.9 #1–#5, #7, 1.10 #1, 2.2 #4, 2.3 #4, #7, #9, 2.4 policies, 2.10 #3, #4, #6, 2.12 #2–#4, plus the new Firewall, Windows Update and CredUI items |
| **Service start type** | 2.3 #5, 2.7 #2, 2.9 (all), 2.10 #2, #5, 2.12 #1 |
| **PowerShell cmdlets** | 1.2 #4–#6, 1.5 #2, 1.6 #1, #4–#7, 2.1, 2.2 #1, #3, #5, firewall profiles |
| **winget** | 2.13 (each update is one line), 2.4 browser updates |
| **Script can only report; a human decides** | 1.4 (needs the README user list), 1.5 #3–#5, 1.7, 1.8, 1.11 #3–#5, 2.5, 2.6, 2.11, 2.14, and anything forensics-related |

Two rules make scripted or manual changes **keep** their points:

1. **Look for planted local Group Policy before trusting a fix.** If the image ships a local GPO such as "Turn off Microsoft Defender Antivirus", "Windows Defender Firewall: Protect all network connections = Disabled", or a WSUS redirect, a regedit or GUI fix gets **reverted at the next `gpupdate`**, and the point disappears later. Change Administrative Template settings in `gpedit.msc`, not raw regedit. Add a step early in the checklist: "Open gpedit and review every Configured setting under Computer and User Administrative Templates."
2. **Change security options through `secpol.msc` or `secedit`**, not regedit. A policy refresh re-applies the local security database over raw registry edits.

---

## 8. Proposed structure for the refactored checklist

```
0. Competition Day Runbook (new)
   0.1 First 15 minutes: read README, answer forensics BEFORE deleting anything, snapshot/notes
   0.2 README decision sheet: RDP? WinRM (which users)? File shares (which)? IIS/Apache/FTP/SMTP/SQL?
       Printing? Browser? Updates allowed? Required software? Groups to create?
   0.3 Order of operations + what needs a reboot
   0.4 Item tags: [Scored-seen] [README] [Reboot] [Risky] [Manual-only]
1. General (1.1-1.11), with the fixes above: firewall in 1.2, WU in 1.1, CredUI, explicit 1.4 steps
2. Features & Services (2.1-2.14), with the fixes above
   2.15 Do NOT do unless README (restored, reconciled with section 5 of this audit)
3. Competition debriefs & forensics (restored from the PDF)
   3.1 Golden rules   3.2-3.5 Comp 1-4 debriefs   3.6 Comp 4 README   3.7 Passwords (one password)
Appendix A: LGPO / Policy Analyzer   Appendix B: Event ID reference   Appendix C: Malicious file names
```

---

## 9. `ToDo.md` cross-reference

| ToDo item | Root cause in the checklist | Fixed by |
|-----------|-----------------------------|----------|
| 4) Remove unauthorized user alana | 1.4 has a single bullet, no procedure | Section 2 (unauthorized users) |
| 6) tina is not an administrator | 1.4 #2 is a reference table with no "remove from Administrators" step | Section 2 |
| 7) peterson is not an administrator | Same as #6 | Section 2 |
| 21) Enumerate administrator accounts on elevation | Setting is missing entirely | Section 2 |
| 22) Hidden share USERS$ disabled | The default-share list doesn't explain `$` shares | Section 2, section 4 (L1006) |
| 25) Windows automatically checks for updates | No GPO path or values | Section 2 |
| 27) Removed prohibited MP3 files | Present but buried after other 1.11 items | Runbook (section 8) |
| 31) Removed netcat backdoor | Only running processes are covered | Section 2 (file search) |
