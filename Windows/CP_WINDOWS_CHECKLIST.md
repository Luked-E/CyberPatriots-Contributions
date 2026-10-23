# Ultimate CyberPatriot Windows Security Master Guide & Checklist

A comprehensive, consolidated security guide and operational checklist for CyberPatriot Windows desktop and Windows Server competitions (Windows 10, Windows 11, Server 2008, Server 2019, and Server 2022).

---

## Table of Contents

- [1. General Security Settings and Configurations](#general-security-settings-and-configurations)
  - [1.1 Settings App](#settings-app)
  - [1.2 Control Panel](#control-panel)
  - [1.3 Local Security Policy (secpol.msc & gpedit.msc)](#local-security-policy-secpolmsc--gpeditmsc)
  - [1.4 Local Users and Groups (lusrmgr.msc)](#local-users-and-groups-lusrmgrmsc)
  - [1.5 Computer Management (compmgnt.msc)](#computer-management-compmgntmsc)
  - [1.6 Windows Security & Threat Protection](#windows-security--threat-protection)
  - [1.7 Task Manager](#task-manager)
  - [1.8 Task Scheduler (taskschd.msc)](#task-scheduler-taskschdmsc)
  - [1.9 Registry Editor (regedit.exe)](#registry-editor-regeditexe)
  - [1.10 Command Prompt & PowerShell Security Commands](#command-prompt--powershell-security-commands)
  - [1.11 File System, Drive Security & Prohibited Media Files](#file-system-drive-security--prohibited-media-files)
- [2. Features, Applications, Services, and Servers](#features-applications-services-and-servers)
  - [2.1 Server Roles & Windows Features Framework](#server-roles--windows-features-framework)
  - [2.2 SMB & Windows File Sharing](#smb--windows-file-sharing)
  - [2.3 Remote Desktop Services (RDP)](#remote-desktop-services-rdp)
  - [2.4 Web Browsers (Chrome, Firefox, Internet Explorer, Edge)](#web-browsers-chrome-firefox-internet-explorer-edge)
  - [2.5 Web Servers (IIS, Apache, Abyss Web Server)](#web-servers-iis-apache-abyss-web-server)
  - [2.6 Database Servers (Microsoft SQL Server & MariaDB / MySQL)](#database-servers-microsoft-sql-server--mariadb--mysql)
  - [2.7 Remote Administration & Management (WinRM, PowerShell Remoting, Remote Registry)](#remote-administration--management-winrm-powershell-remoting-remote-registry)
  - [2.8 Email & Messaging Servers (SMTP)](#email--messaging-servers-smtp)
  - [2.9 Network Services & Legacy Protocols (FTP, TFTP, Telnet, SNMP, SSDP, UPnP, RIP Listener, Simple TCP/IP)](#network-services--legacy-protocols-ftp-tftp-telnet-snmp-ssdp-upnp-rip-listener-simple-tcpip)
  - [2.10 Network Stack & Name Resolution (IPv6, NetBIOS over TCP/IP, LLMNR, DNS Client, SYN Flood Protection)](#network-stack--name-resolution-ipv6-netbios-over-tcpip-llmnr-dns-client-syn-flood-protection)
  - [2.11 Active Directory Domain Services & GPMC (Domain Controllers)](#active-directory-domain-services--gpmc-domain-controllers)
  - [2.12 Print Spooler & Printer Drivers](#print-spooler--printer-drivers)
  - [2.13 Third-Party Software Management & Required Updates](#third-party-software-management--required-updates)
  - [2.14 Unauthorized Software, Hacking Tools & Malware Removal](#unauthorized-software-hacking-tools--malware-removal)
  - [2.15 Critical Policies: Do NOT Do Unless Instructed by README](#critical-policies-do-not-do-unless-instructed-by-readme)
- [3. Competition Scenarios, Forensics Solutions & Reference Notes](#competition-scenarios-forensics-solutions--reference-notes)
  - [3.1 General Competition Strategy & Golden Rules](#general-competition-strategy--golden-rules)
  - [3.2 Competition 1 (25-26 Windows 11) Debrief & Forensics](#competition-1-25-26-windows-11-debrief--forensics)
  - [3.3 Competition 2 (25-26 Windows 11) Debrief & Forensics](#competition-2-25-26-windows-11-debrief--forensics)
  - [3.4 Competition 3 Gold (Server 2019) Debrief & Forensics](#competition-3-gold-server-2019-debrief--forensics)
  - [3.5 Competition 4 Gold Semifinals (Windows 11 / Server 2022) Debrief & Forensics](#competition-4-gold-semifinals-windows-11--server-2022-debrief--forensics)
  - [3.6 Complete Readme / Scenario Reference (Mr. Robot / E-Corp Challenge)](#complete-readme--scenario-reference-mr-robot--e-corp-challenge)
  - [3.7 CyberPatriot Master Password & Credential Cheatsheet](#cyberpatriot-master-password--credential-cheatsheet)

---

# 1. General Security Settings and Configurations

> **Important**: This section contains baseline security configurations that should universally be enforced on every Windows workstation or server image, organized strictly by the application/console used to manage them. Application-, server-, protocol-, and feature-specific settings (such as RDP, SMB, IIS, SQL, Chrome, WinRM, etc.) are separated into the second major section.

---

## 1.1 Settings App

Access via: `Win + I` or Start Menu $\to$ **Settings**

### 1. Windows Updates
- **Path**: `Settings` $\to$ `Update & Security` (Windows 10) / `Windows Update` (Windows 11) $\to$ **Check for updates**.
- **Rule**: Run updates if permitted.
  > [!WARNING]
  > Always check the README first! Some competition scenarios state: *"Due to time restraints, management requests that you do NOT install Windows Updates. However, you should ensure that the computer is configured to automatically install updates."* If so, configure automatic updates in Group Policy but do not click "Install now".

### 2. AutoPlay Configuration
- **Path**: `Settings` $\to$ `Devices` (or `Bluetooth & devices`) $\to$ **AutoPlay**.
- **Setting**: Toggle **"Use AutoPlay for all media and devices"** to **Off**.
- **Security Justification**: Prevents automatic execution of malicious payloads from USB flash drives, network shares, and optical discs.

### 3. Privacy & Background Apps
- **Path**: `Settings` $\to$ `Privacy` (or `Privacy & security`).
- **Settings**:
  - Turn off diagnostic feedback telemetry where appropriate.
  - Disable unneeded background app execution and camera/microphone access for untrusted desktop applications.

### 4. Disable Delivery Optimization Peer-to-Peer Update Sharing
- **Path (Settings GUI)**:
  - On **Windows 10**: `Settings` $\to$ `Update & Security` $\to$ `Delivery Optimization`.
  - On **Windows 11**: `Settings` $\to$ `Windows Update` $\to$ `Advanced options` $\to$ `Delivery Optimization`.
  - Toggle **"Allow downloads from other PCs"** to **Off**.
  - *(Optional alternate)*: If local update sharing is instructed, select **"Devices on my local network"** instead of the public Internet.
- **Alternative Method (Group Policy GUI)**:
  - `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Windows Components` $\to$ `Delivery Optimization` $\to$ Double-click **Download Mode** $\to$ Select **Enabled** $\to$ Choose **Simple (99)** or **Bypass (100)** to disable peering.
- **Security Justification**: Delivery Optimization turns machines into peer-to-peer nodes uploading chunks over the network. Disabling it stops bandwidth hijacking and untrusted peer caching.

### 5. Turn Off Developer Mode
- **Path (Settings GUI)**:
  - On **Windows 10**: `Settings` $\to$ `Update & Security` $\to$ `For developers`.
  - On **Windows 11**: `Settings` $\to$ `System` (or `Privacy & security`) $\to$ `For developers`.
  - Toggle **Developer Mode** to **Off**.
- **Alternative Method (Group Policy GUI)**:
  - `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Windows Components` $\to$ `App Package Deployment` $\to$ **"Allows development of Windows Store applications and installing them from an integrated development environment (IDE)"** $\to$ Set to **Disabled**.
- **Security Justification**: Developer Mode permits sideloading unsigned UWP packages and enables Device Portal and SSH server listener services.

### 6. Disable Lock Screen Notification Previews
- **Path (Settings GUI)**:
  - `Settings` $\to$ `System` $\to$ `Notifications` (or `Notifications & actions` on Windows 10).
  - **Uncheck**: **"Show notifications on the lock screen"**.
  - **Uncheck**: **"Show reminders and incoming VoIP calls on the lock screen"**.
- **Alternative Method (Group Policy GUI)**:
  - `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `System` $\to$ `Logon` $\to$ **"Turn off app notifications on the lock screen"** $\to$ Set to **Enabled**.
- **Security Justification**: Prevents unauthorized physical walk-up observers from reading sensitive 2FA codes, password reset notifications, or enterprise alerts when locked.

### 7. Disable Clipboard History & Cross-Device Cloud Sync
- **Path (Settings GUI)**:
  - `Settings` $\to$ `System` $\to$ `Clipboard`.
  - Toggle **Clipboard history** to **Off**.
  - Under **Sync across your devices**, set the toggle to **Off**.
  - Click **Clear clipboard data** to wipe existing clipboard buffers.
- **Alternative Method (Group Policy GUI)**:
  - `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `System` $\to$ `OS Policies`:
    - **"Allow Clipboard History"** $\to$ Set to **Disabled**.
    - **"Allow Clipboard synchronization across devices"** $\to$ Set to **Disabled**.
- **Security Justification**: Clipboard history stores copied strings (including credentials and tokens) in memory and potentially syncs unencrypted paste buffers to cloud profiles.

### 8. Modern Remote Desktop Toggle Verification
- **Path (Settings GUI)**:
  - `Settings` $\to$ `System` $\to$ `Remote Desktop`.
  - If RDP is **NOT authorized**: Verify toggle is **Off**; if On, toggle it to **Off** and confirm.
  - If RDP is **REQUIRED**: Toggle to **On**, expand settings, and ensure **"Require computers to use Network Level Authentication (NLA) to connect"** is checked.
- **Security Justification**: In Windows 10/11, toggling RDP in `sysdm.cpl` can sometimes leave the modern UWP Settings toggle out of sync.

---

## 1.2 Control Panel

Access via: `Win + R` $\to$ `control` $\to$ Enter

### 1. User Account Control (UAC)
- **Path**: `Control Panel` $\to$ `User Accounts` $\to$ `User Accounts` $\to$ **Change User Account Control settings**.
- **Configuration**: Drag slider to the top setting: **Always notify** (*"Always notify me when apps try to install software or make changes to my computer"*).
- **Behavior**: Ensures UAC prompts on the secure desktop for all administrative credential elevations.

### 2. Screen Saver & Lockout Password
- **Path**: `Control Panel` $\to$ `Appearance and Personalization` $\to$ `Change screen saver` (or `Control Panel` $\to$ `Hardware and Sound` $\to$ `Power Options`).
- **Configuration**:
  - Select a screen saver (e.g., Blank or Mystify).
  - Set **Wait** timeout to **10 minutes** (or 5 minutes if specified).
  - Check the box: **"On resume, display logon screen"**.
- **Security Justification**: Prevents unauthorized physical walk-up access when a workstation is left unattended.

### 3. File Explorer Options (Clean Directory Visibility)
- **Path**: `Control Panel` $\to$ `File Explorer Options` (or `Folder Options`) $\to$ **View** tab.
- **Configurations**:
  - Select **"Show hidden files, folders, and drives"**.
  - Uncheck **"Hide extensions for known file types"** (vital to spot double-extension malware like `taskmgr.exe.exe` or `malware.pdf.exe`).
  - Uncheck **"Hide protected operating system files (Recommended)"** when investigating hidden rootkits/backdoors.

### 4. Enforce Advanced Network Sharing Settings
- **Path (Control Panel GUI)**:
  - `Control Panel` $\to$ `Network and Internet` $\to$ `Network and Sharing Center` $\to$ `Change advanced sharing settings`.
  - Under **Guest or Public (current profile)**:
    - Select: **"Turn off network discovery"**.
    - Select: **"Turn off file and printer sharing"**.
  - Under **All Networks**:
    - Under *Public folder sharing*: Select **"Turn off Public folder sharing"**.
    - Under *Password protected sharing*: Select **"Turn on password protected sharing"** (*CRITICAL*).
  - Click **Save changes**.
- **Alternative Method (Native CLI Tool - Admin)**:
  ```cmd
  netsh advfirewall firewall set rule group="Network Discovery" new enable=No
  netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=No profile=public
  ```
- **Security Justification**: Unauthenticated guest access to shared folders and open network discovery are frequently scored vulnerabilities across all Windows versions.

### 5. Enforce Password Requirement on Wakeup
- **Path (Control Panel GUI)**:
  - `Control Panel` $\to$ `Hardware and Sound` $\to$ `Power Options` $\to$ `Require a password on wakeup` (or `Choose what the power buttons do`).
  - Click **"Change settings that are currently unavailable"**.
  - Select **"Require a password (recommended)"** $\to$ Click **Save changes**.
- **Alternative Method (Native Powercfg Utility - Admin)**:
  ```cmd
  powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 1
  powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 1
  powercfg /SETACTIVE SCHEME_CURRENT
  ```
- **Security Justification**: Prevents bypassing the Windows lock screen when waking a computer from sleep or standby.

### 6. Configure System Protection & Baseline Restore Points
- **Path (System Properties GUI)**:
  - `Win + R` $\to$ `sysdm.cpl` $\to$ `System Protection` tab.
  - Select system volume **`Local Disk (C:) (System)`** $\to$ Click **Configure...**.
  - Select **"Turn on system protection"** $\to$ Allocate 5–10% disk usage $\to$ Click **Apply** $\to$ Click **OK**.
  - Click **Create...** $\to$ Enter title `CP Baseline Initial Clean` $\to$ Click **Create**.
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  Enable-ComputerRestore -Drive "C:\"
  vssadmin resize shadowstorage /on=C: /for=C: /maxsize=10%
  Checkpoint-Computer -Description "CyberPatriot Baseline Clean" -RestorePointType "MODIFY_SETTINGS"
  ```
- **Security Justification**: Establishing a clean baseline shadow copy provides a rollback mechanism if administrative changes break scoring services.

### 7. Internet Options Security Zones & Protocol Hardening
- **Path (Internet Options GUI)**:
  - `Win + R` $\to$ `inetcpl.cpl` $\to$ Enter.
  - **Security Tab**: Click **"Reset all zones to default level"**; ensure Restricted sites zone is set to **High**; verify **"Enable Protected Mode"** is checked.
  - **Connections Tab**: Click **LAN settings** $\to$ **Uncheck "Automatically detect settings"** (mitigates WPAD poisoning attacks).
  - **Advanced Tab**:
    - Check: **"Do not save encrypted pages to disk"**.
    - Check: **"Empty Temporary Internet Files folder when browser is closed"**.
    - Check: **"Warn about certificate address mismatch"**.
    - Uncheck: **Use SSL 3.0**, **Use TLS 1.0**, **Use TLS 1.1**.
    - Check: **Use TLS 1.2**, **Use TLS 1.3**.
  - Click **Apply** $\to$ Click **OK**.
- **Security Justification**: Legacy Windows system components, WinINet APIs, BITS, and PowerShell web cmdlets inherit proxy, certificate validation, and TLS ciphers directly from Internet Options.

---

## 1.3 Local Security Policy (secpol.msc & gpedit.msc)

Access via: `Win + R` $\to$ `secpol.msc` $\to$ Enter (or `gpedit.msc` for full Group Policy)

### 1. Account Policies: Password Policy
Navigate to: `Security Settings` $\to$ `Account Policies` $\to$ `Password Policy`

| Policy Name | Recommended Setting | Alternate Competition Setting | Notes |
| :--- | :--- | :--- | :--- |
| **Enforce password history** | **24 passwords remembered** | 24 | Prevents password recycling |
| **Maximum password age** | **30 days** | 42 days (Domain Standard) | Forces periodic rotation |
| **Minimum password age** | **3 days** | 5 days | Prevents rapid cycling through history |
| **Minimum password length** | **14 characters** | 8 - 15 characters | Defense against brute-force attacks |
| **Password must meet complexity requirements** | **Enabled** | Enabled | Requires uppercase, lowercase, numbers, symbols |
| **Store passwords using reversible encryption** | **Disabled** | Disabled | Storing reversible hashes is a critical vulnerability |

### 2. Account Policies: Account Lockout Policy
Navigate to: `Security Settings` $\to$ `Account Policies` $\to$ `Account Lockout Policy`

| Policy Name | Recommended Setting | Alternative Setting | Notes |
| :--- | :--- | :--- | :--- |
| **Account lockout duration** | **30 minutes** | 10 minutes | Time an account stays locked |
| **Account lockout threshold** | **5 invalid logon attempts** | 20 attempts | Mitigates brute-force/dictionary attacks |
| **Reset account lockout counter after** | **30 minutes** | 30 minutes | Must match or be less than lockout duration |

### 3. Local Policies: Audit Policy
Navigate to: `Security Settings` $\to$ `Local Policies` $\to$ `Audit Policy`
- Enforce full visibility across the OS: **Double-click every policy and check BOTH Success and Failure**:
  - Audit account logon events: **Success, Failure**
  - Audit account management: **Success, Failure**
  - Audit directory service access: **Success, Failure**
  - Audit logon events: **Success, Failure**
  - Audit object access: **Success, Failure**
  - Audit policy change: **Success, Failure**
  - Audit privilege use: **Success, Failure**
  - Audit process tracking: **Success, Failure**
  - Audit system events: **Success, Failure**

### 4. Advanced Audit Policy Configuration
Navigate to: `Security Settings` $\to$ `Advanced Audit Policy Configuration` $\to$ `System Audit Policies - Local Group Policy Object`
- Set **Success and Failure** for all subcategories, paying particular attention to:
  - `Account Logon` $\to$ Audit Credential Validation: **Success, Failure**
  - `Account Management` $\to$ Audit User Account Management: **Success, Failure**
  - `Account Management` $\to$ Audit Computer Account Management: **Success, Failure** (Scores points in Comp 3 / Win 10!)
  - `Logon/Logoff` $\to$ Audit Logon / Audit Logoff / Audit Special Logon: **Success, Failure**
  - `Object Access` $\to$ Audit File System: **Success, Failure**
  - `Policy Change` $\to$ Audit Audit Policy Change / Authentication Policy Change: **Success, Failure**
  - *(Leave Global Object Access Auditing alone unless specified)*.

### 5. Local Policies: User Rights Assignment
Navigate to: `Security Settings` $\to$ `Local Policies` $\to$ `User Rights Assignment`

| User Right | Authorized Entities Only | Entities to Remove |
| :--- | :--- | :--- |
| **Access this computer from the network** | `Administrators`, `Authenticated Users` | Remove `Everyone`, `Guests`, `Users` |
| **Allow log on locally** | `Administrators` *(and authorized console users)* | Remove unauthorized standard users / guests |
| **Bypass traverse checking** | `Administrators` | Remove `Everyone`, `Users` |
| **Deny access to this computer from the network** | `ANONYMOUS LOGON`, `Guest` | Ensure anonymous/guest cannot authenticate over network |
| **Force shutdown from a remote system** | `Administrators` | Remove any non-admin entity |
| **Generate security audits** | `LOCAL SERVICE`, `NETWORK SERVICE` | Strictly limit to core service identities |
| **Log on as a service** | `LOCAL SYSTEM`, `LOCAL SERVICE`, `NETWORK SERVICE` | Remove unauthorized user accounts |
| **Restore files and directories** | `Administrators` | Remove unauthorized operators |
| **Shut down the system** | `Administrators`, `Backup Operators` | Remove standard `Users` |
| **Act as part of the operating system** | *(None / Empty)* | Remove ANY user or group listed here! |

### 6. Local Policies: Security Options (Core Operating System Hardening)
Navigate to: `Security Settings` $\to$ `Local Policies` $\to$ `Security Options`

#### Accounts
- **Accounts: Administrator account status**: **Disabled** (Ensure you are logged into another authorized administrative account before disabling!).
- **Accounts: Guest account status**: **Disabled**.
- **Accounts: Limit local account use of blank passwords to console logon only**: **Enabled**.

#### Audit
- **Audit: Shut down system immediately if unable to log security audits**: **Enabled** (or No Change if unstable).
- **Audit: Audit the access of global system objects**: No Change.
- **Audit: Audit the use of Backup and Restore privilege**: No Change.

#### Devices
- **Devices: Allow undock without having to log on**: **Disabled**.
- **Devices: Allowed to format and eject removable media**: **Administrators**.
- **Devices: Prevent users from installing printer drivers**: **Enabled**.
- **Devices: Restrict CD-ROM access to locally logged-on user only**: **Enabled**.
- **Devices: Restrict floppy access to locally logged-on user only**: **Enabled**.

#### Interactive Logon
- **Interactive logon: Do not display last user name**: **Enabled**.
- **Interactive logon: Do not require CTRL+ALT+DEL**: **Disabled** (forces CTRL+ALT+DEL before login prompt to block fake logon dialogs).
- **Interactive logon: Message text for users attempting to log on**: Set organizational legal warning banner (e.g., *"Authorized Use Only. All activities are monitored and logged."*).
- **Interactive logon: Message title for users attempting to log on**: Set banner title (e.g., *"WARNING: Legal Notice"*).
- **Interactive logon: Number of previous logons to cache (in case domain controller is not available)**: Set to **0** (or 1).
- **Interactive logon: Prompt user to change password before expiration**: **14 days** (or 5 days).
- **Interactive logon: Display user information when the session is locked**: **Do not display user information**.

#### Recovery Console & Shutdown
- **Recovery console: Allow automatic administrative logon**: **Disabled**.
- **Recovery console: Allow floppy copy and access to all drives and all folders**: **Disabled**.
- **Shutdown: Allow system to be shut down without having to log on**: **Disabled**.
- **Shutdown: Clear virtual memory pagefile**: **Enabled** (clears residual plain-text secrets on shutdown).

#### User Account Control (UAC Group Policy Options)
- **User Account Control: Admin Approval Mode for the Built-in Administrator account**: **Enabled**.
- **User Account Control: Allow UIAccess applications to prompt for elevation without using the secure desktop**: **Disabled**.
- **User Account Control: Behavior of the elevation prompt for administrators in Admin Approval Mode**: **Prompt for consent on the secure desktop** (or Prompt for credentials).
- **User Account Control: Behavior of the elevation prompt for standard users**: **Automatically deny elevation requests** (or Prompt for credentials).
- **User Account Control: Detect application installations and prompt for elevation**: **Enabled**.
- **User Account Control: Only elevate executables that are signed and validated**: **Enabled** (or evaluate if testing unsigned legacy tools).
- **User Account Control: Run all administrators in Admin Approval Mode**: **Enabled**.
- **User Account Control: Switch to the secure desktop when prompting for elevation**: **Enabled**.

### 7. Enforce Explicit Deny User Rights
- **Path (`secpol.msc` GUI)**:
  - `Security Settings` $\to$ `Local Policies` $\to$ `User Rights Assignment`.
  - **Deny log on locally**: Double-click $\to$ Add `Guest` $\to$ Click OK.
  - **Deny log on through Remote Desktop Services**: Double-click $\to$ Add `Guest; ANONYMOUS LOGON` $\to$ Click OK.
  - **Deny log on as a batch job**: Double-click $\to$ Add `Guest` $\to$ Click OK.
  - **Deny log on as a service**: Double-click $\to$ Add `Guest` $\to$ Click OK.
- **Alternative Method (`secedit` CLI Tool - Admin)**:
  ```cmd
  secedit /export /cfg C:\secpol_export.inf
  ```
  *Append to `C:\secpol_export.inf` under `[Privilege Rights]`*:
  ```ini
  [Privilege Rights]
  SeDenyInteractiveLogonRight = *S-1-5-32-546
  SeDenyRemoteInteractiveLogonRight = *S-1-5-32-546,*S-1-5-7
  SeDenyBatchLogonRight = *S-1-5-32-546
  SeDenyServiceLogonRight = *S-1-5-32-546
  ```
  ```cmd
  secedit /configure /db secedit.sdb /cfg C:\secpol_export.inf /areas USER_RIGHTS
  del C:\secpol_export.inf
  gpupdate /force
  ```
- **Security Justification**: Explicit `Deny` rights override any accidental or inherited group grants, ensuring the Guest account and unauthenticated callers can never execute code locally or over RDP.

### 8. Restrict High-Risk Administrative Privileges
- **Path (`secpol.msc` GUI)**:
  - In `Local Policies` $\to$ `User Rights Assignment`, ensure the following are restricted strictly to `Administrators` (remove standard users, developers, and third-party software accounts):
    - **Debug programs (`SeDebugPrivilege`)**: Strictly `Administrators` *(Stops process memory dumping of LSASS)*.
    - **Take ownership of files or other objects (`SeTakeOwnershipPrivilege`)**: Strictly `Administrators`.
    - **Load and unload device drivers (`SeLoadDriverPrivilege`)**: Strictly `Administrators`.
    - **Create symbolic links (`SeCreateSymbolicLinkPrivilege`)**: Strictly `Administrators`.
    - **Impersonate a client after authentication (`SeImpersonatePrivilege`)**: Strictly `Administrators`, `LOCAL SERVICE`, `NETWORK SERVICE`, `SERVICE`.
    - **Manage auditing and security log (`SeSecurityPrivilege`)**: Strictly `Administrators`.
    - **Back up files and directories (`SeBackupPrivilege`)**: Strictly `Administrators`, `Backup Operators`.
- **Security Justification**: `SeDebugPrivilege` allows any user process to inspect and inject code into arbitrary system memory (including dumping cleartext credentials from `lsass.exe`).

### 9. Configure Machine Inactivity Screen Lockout Limit
- **Path (`secpol.msc` GUI)**:
  - `Security Settings` $\to$ `Local Policies` $\to$ `Security Options` $\to$ **"Interactive logon: Machine inactivity limit"**.
  - Double-click $\to$ Check **"Define this policy setting"** $\to$ Enter **`900`** seconds (15 minutes) or **`300`** seconds (5 minutes).
  - Click **Apply** $\to$ Click **OK**.
- **Security Justification**: Directly forces the operating system screen lock timer via Group Policy, superseding individual user overrides.

### 10. Block Microsoft Accounts & Anonymous Fallback
- **Path (`secpol.msc` GUI)**:
  - In `Local Policies` $\to$ `Security Options`:
    - **"Accounts: Block Microsoft accounts"**: Set to **"Users cannot add or log on with Microsoft accounts"**.
    - **"Network security: Allow LocalSystem NULL session fallback"**: Set to **Disabled**.
    - **"Network security: Allow PKU2U authentication requests to this computer to use online identities"**: Set to **Disabled**.
- **Security Justification**: Blocking Microsoft accounts ensures workstations rely strictly on local or domain SAM databases, preventing rogue external live/cloud credentials from bypassing local policies.

---

## 1.4 Local Users and Groups (lusrmgr.msc)

Access via: `Win + R` $\to$ `lusrmgr.msc` $\to$ Enter

### 1. User Account Auditing & Remediation
- **Review README first**: Cross-reference the users list in `lusrmgr.msc` against authorized users in the competition README.
- **Guest Account**:
  - Right-click `Guest` $\to$ `Properties` $\to$ Check **"Account is disabled"**.
- **Unauthorized Users**:
  - Right-click unauthorized/rogue accounts (e.g., `hamburgerman`, `romeo`, `fsociety`, `darkarmy`) $\to$ **Delete**.
- **Authorized Accounts Configuration**:
  - Right-click each authorized user $\to$ `Properties`:
    - Check **"User must change password at next logon"** (except on your current active administrator account).
    - Uncheck **"User cannot change password"**.
    - Uncheck **"Password never expires"**.
    - Uncheck **"Account is disabled"** (unless explicitly retired).
    - Uncheck **"Account is locked out"**.
- **Resetting Passwords**:
  - Right-click user $\to$ `Set Password` $\to$ `Proceed`.
  - Enter a complex password complying with security policy (e.g., `PP@@ssword12345` or `C1sc0!314159???` or `CyberP12345@SVT`).

### 2. Group Membership Auditing
- **Administrators Group**:
  - Click `Groups` $\to$ Double-click `Administrators`.
  - Check members against README: Remove unauthorized users (e.g., demote users that should only be standard users such as `cmoss`, `jchutney`, `sjacobs`, `twellick` if specified).
  - Select user $\to$ Click **Remove**.
- **Backup Operators Group**:
  - Check members: Remove users who should not have backup privileges (e.g., `dalderson`).
- **Creating Required Groups**:
  - `Groups` $\to$ Right-click empty area $\to$ `New Group` $\to$ Provide name and add authorized users.
- **Preservation Rule**:
  - **Do NOT delete any built-in/default Windows groups!**

### 3. Audit and Disable Built-in System Utility Accounts
- **Path (`lusrmgr.msc` GUI)**:
  - In `Users`, locate `DefaultAccount` $\to$ Properties $\to$ Check **"Account is disabled"**.
  - Locate `WDAGUtilityAccount` (Windows Defender Application Guard) $\to$ Properties $\to$ Check **"Account is disabled"** (unless Application Guard is active).
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  Disable-LocalUser -Name "DefaultAccount" -ErrorAction SilentlyContinue
  Disable-LocalUser -Name "WDAGUtilityAccount" -ErrorAction SilentlyContinue
  ```
- **Security Justification**: Attackers frequently activate dormant built-in utility accounts to create backdoor administrative accounts that evade basic user list sweeps.

### 4. Audit Sensitive Auxiliary Local Groups
- **Path (`lusrmgr.msc` GUI)**:
  - Click `Groups` and inspect each of the following groups, removing unauthorized members:
    - **Remote Management Users** (only authorized admins/WinRM users).
    - **Distributed COM Users** (remove unauthorized standard users).
    - **Event Log Readers** (ensure standard users cannot harvest logs for credentials).
    - **Performance Log Users** & **Performance Monitor Users** (used for reconnaissance).
    - **Cryptographic Operators** (ensure only SYSTEM / authorized admins).
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  $groups = @("Remote Management Users", "Distributed COM Users", "Event Log Readers", "Performance Log Users", "Cryptographic Operators")
  foreach ($grp in $groups) {
      Write-Host "=== Members of $grp ===" -ForegroundColor Cyan
      Get-LocalGroupMember -Group $grp -ErrorAction SilentlyContinue | Select-Object Name, PrincipalSource
  }
  ```
- **Security Justification**: Subtly granting standard users membership in auxiliary groups preserves persistent backdoors without modifying the `Administrators` group.

### 5. Automated Local User Account Security Audit via PowerShell
- **PowerShell (Admin) Command**:
  ```powershell
  Get-LocalUser | Select-Object Name, Enabled, PasswordRequired, PasswordLastSet, PasswordNeverExpires, UserMayChangePassword, LastLogon, Description | Sort-Object Enabled -Descending | Format-Table -AutoSize
  ```
- **Remediation Script**:
  ```powershell
  # Force all local users to require passwords and enforce expiration
  Get-LocalUser | Where-Object { $_.Name -ne "DefaultAccount" -and $_.Name -ne "WDAGUtilityAccount" } | ForEach-Object {
      Set-LocalUser -Name $_.Name -PasswordNeverExpires $false
  }
  ```
- **Security Justification**: Instantly identifies dormant accounts, accounts with passwords set to never expire, accounts with blank passwords, or accounts that have never logged on.

---

## 1.5 Computer Management (compmgnt.msc)

Access via: `Win + R` $\to$ `compmgnt.msc` $\to$ Enter

### 1. Disk Management & File System Integrity
- **Path**: `Storage` $\to$ `Disk Management`.
- **Enforcement**: Verify all active volumes are formatted with **NTFS** (or ReFS where applicable). Convert any FAT/FAT32 volumes if present:
  ```cmd
  convert C: /fs:ntfs
  ```

### 2. Event Viewer Log Sizes & Settings
- **Path**: `System Tools` $\to$ `Event Viewer` $\to$ `Windows Logs`.
- **Right-click `Security`, `System`, `Application`** $\to$ `Properties`:
  - Verify **Maximum log size** is at least **16384 KB** but choose **65536 KB** if available.
  - Ensure **"Overwrite events as needed"** is selected so auditing does not abruptly halt.

### 3. Device Manager Hidden Device Audit
- **Path (Device Manager GUI)**:
  - `devmgmt.msc` $\to$ Click `View` menu $\to$ Check **"Show hidden devices"**.
  - Expand **Network adapters**: Look for unauthorized virtual adapters (`TAP-Windows Adapter`, `TeamViewer VPN`, `LogMeIn Hamachi`, `OpenVPN`). Right-click rogue adapter $\to$ **Uninstall device** $\to$ Check *"Delete driver software"*.
  - Expand **Universal Serial Bus controllers**: Check for suspicious hardware dongles or emulated input devices.
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  Get-NetAdapter -IncludeHidden | Select-Object Name, InterfaceDescription, Status, MacAddress | Format-Table -AutoSize
  # Disable rogue adapter:
  # Disable-NetAdapter -Name "<RogueAdapterName>" -Confirm:$false
  ```
- **Security Justification**: Rogue VPN network interfaces allow remote attackers to bypass the local Windows Firewall profile.

### 4. Security Event Log Threat Hunting (Critical Event IDs)
- **Path (Event Viewer GUI)**:
  - `eventvwr.msc` $\to$ `Windows Logs` $\to$ `Security` $\to$ Click **Filter Current Log...** in right pane.
  - Filter by Event IDs: `4624, 4625, 4720, 4726, 4728, 4732, 4697, 7045, 1102`.
- **Event ID Quick Reference**:
  - **4624**: Successful Logon (Inspect Logon Type 3 [Network] or 10 [RDP]).
  - **4625**: Failed Logon (Brute-force / password spraying detection).
  - **4720 / 4726**: User Account Created / Deleted.
  - **4728 / 4732**: Member Added to Privileged Groups.
  - **7045 / 4697**: New Service Installed (Primary persistence vector!).
  - **1102**: Audit Log Cleared (Attacker anti-forensics).
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  Get-WinEvent -FilterHashtable @{LogName='System'; Id=7045} -MaxEvents 20 -ErrorAction SilentlyContinue | Select-Object TimeCreated, @{Name="ServiceName";Expression={$_.Properties[0].Value}}, @{Name="ImagePath";Expression={$_.Properties[1].Value}} | Format-Table -AutoSize
  ```

### 5. Integrated Share Management via Computer Management
- **Path (`compmgnt.msc` GUI)**:
  - `compmgnt.msc` $\to$ `System Tools` $\to$ `Shared Folders`.
  - **Shares**: Right-click any unauthorized non-default share $\to$ Click **Stop Sharing**.
  - **Sessions**: Right-click rogue active network connections $\to$ Click **Close Session**.
  - **Open Files**: View files currently locked or accessed over the network by remote machines.

---

## 1.6 Windows Security & Threat Protection

Access via: `Win + S` $\to$ Type `Windows Security` $\to$ Enter

### 1. Virus & Threat Protection
- **Real-Time Protection**: Ensure toggle is **On**.
- **Cloud-delivered Protection**: Ensure toggle is **On**.
- **Automatic Sample Submission**: Ensure toggle is **On**.
- **Scan Exclusions Check (CRITICAL FORENSICS / BACKDOOR POINT)**:
  - Navigate to: `Virus & threat protection settings` $\to$ `Manage settings` $\to$ Scroll down to **Exclusions** $\to$ `Add or remove exclusions`.
  - Inspect all folders and files listed.
  - **Remove malicious scan exclusions** (e.g., `sysinternals.exe`, temporary scripts, malware directories).
- **Run Scan**:
  - Click `Scan options` $\to$ Select **Full scan** $\to$ **Scan now**.

### 2. Windows SmartScreen
- **Path**: `Windows Security` $\to$ `App & browser control` $\to$ `Reputation-based protection settings`.
- **Configurations**:
  - **Check apps and files**: Set to **Warn** or **Block**.
  - **SmartScreen for Microsoft Edge**: Set to **On**.
  - **SmartScreen for Microsoft Store apps**: Set to **Warn** or **Block**.

### 3. Enforce Tamper Protection
- **Path (Windows Security GUI)**:
  - `Windows Security` $\to$ `Virus & threat protection` $\to$ `Virus & threat protection settings` $\to$ `Manage settings`.
  - Toggle **Tamper Protection** to **On**.
- **Verification / Audit Command**:
  ```powershell
  Get-MpComputerStatus | Select-Object IsTamperProtected, RealTimeProtectionEnabled
  ```
- **Security Justification**: Prevents unauthorized scripts, malware, or registry hacks from silently disabling Microsoft Defender Antivirus or modifying threat exclusion paths.

### 4. Enable Controlled Folder Access (Ransomware Protection)
- **Path (Windows Security GUI)**:
  - `Windows Security` $\to$ `Virus & threat protection` $\to$ `Manage ransomware protection`.
  - Toggle **Controlled folder access** to **On**.
  - Click **Protected folders** to verify `Documents`, `Pictures`, `Desktop`, `Videos` are listed.
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  Set-MpPreference -EnableControlledFolderAccess Enabled
  ```
- **Security Justification**: Restricts untrusted executables from writing to or encrypting default user document folders.

### 5. System-Wide Exploit Protection (DEP, ASLR, SEHOP)
- **Path (Windows Security GUI)**:
  - `Windows Security` $\to$ `App & browser control` $\to$ `Exploit protection settings`.
  - Under **System settings**, configure:
    - **Control Flow Guard (CFG)**: **On by default**.
    - **Data Execution Prevention (DEP)**: **On by default (Always On)**.
    - **Force randomization for images (Mandatory ASLR)**: **On by default**.
    - **Validate exception chains (SEHOP)**: **On by default**.
    - **Validate heap integrity**: **On by default**.
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  Set-ProcessMitigation -System -Enable DEP,BottomUp,ForceRelocateImages,SEHOP
  ```
- **Security Justification**: Hardens the Windows kernel and process memory space against buffer overflows, ROP gadgets, and shellcode execution.

### 6. Enable Potentially Unwanted Application (PUA) Protection
- **PowerShell (Admin) Command**:
  ```powershell
  Set-MpPreference -PUAProtection Enabled
  ```
- **Alternative Method (Group Policy GUI)**:
  - `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Windows Components` $\to$ `Microsoft Defender Antivirus` $\to$ **"Configure detection for potentially unwanted applications"** $\to$ Set to **Enabled (Block)**.
- **Security Justification**: Automatically blocks adware, bundleware, coin miners, and questionable system utilities.

### 7. Enable Network Protection for Defender
- **PowerShell (Admin) Command**:
  ```powershell
  Set-MpPreference -EnableNetworkProtection Enabled
  ```
- **Alternative Method (Group Policy GUI)**:
  - `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Windows Components` $\to$ `Microsoft Defender Antivirus` $\to$ `Windows Defender Exploit Guard` $\to$ `Network Protection` $\to$ **"Prevent users and apps from accessing dangerous websites"** $\to$ Set to **Enabled (Block)**.
- **Security Justification**: Extends SmartScreen reputation filtering to all outbound network traffic from any application, blocking C2 beacons to malicious domains.

---

## 1.7 Task Manager

Access via: `Ctrl + Shift + Esc` $\to$ Click `More details`

### 1. Startup Applications
- **Tab**: `Startup` (or `Startup apps` on Win 11).
- **Audit**: Inspect all programs set to execute at boot.
- **Action**: Right-click and **Disable** unauthorized launchers, unknown update utilities, hacking payloads, torrent tools, or suspicious scripts.

### 2. Running Processes
- **Tab**: `Processes` / `Details`.
- **Audit**: Scan for rogue process names:
  - Dual extensions: `taskmgr.exe.exe`, `svchost.exe.exe`
  - Netcat/Reverse shells: `nc.exe`, `meterpreter`
  - Adware/Trojan agents: `SharpChrome`, `IOTransfer`
- **Action**: End unauthorized process tree and locate parent binary on disk for deletion.

### 3. Expose Image Path Name and Command Line Columns
- **Path (Task Manager GUI)**:
  - Navigate to the **Details** tab $\to$ Right-click any column header $\to$ Click **Select columns**.
  - Check **Image path name** and **Command line** $\to$ Click **OK**.
  - **Triage Rules**:
    - Any instance of `svchost.exe`, `lsass.exe`, `csrss.exe`, or `services.exe` NOT originating from `C:\Windows\System32\` is malicious.
    - Any process whose command line includes `-enc`, `-EncodedCommand`, `bypass`, `hidden`, or suspicious sockets must be investigated.

### 4. Services Tab Triage in Task Manager
- **Path (Task Manager GUI)**:
  - Click the **Services** tab $\to$ Click **Status** header to sort by `Running`.
  - Scan *Description* and *Group* for unverified services $\to$ Right-click rogue service $\to$ Click **Stop**.
  - Click **Open Services** at the bottom to set Startup type to **Disabled** in `services.msc`.

### 5. Users Tab Disconnected Session Termination
- **Path (Task Manager GUI)**:
  - Click the **Users** tab $\to$ Review list of active sessions.
  - If an unauthorized user or disconnected ghost session is visible: Right-click user $\to$ Click **Sign off** (or **Disconnect**).

---

## 1.8 Task Scheduler (taskschd.msc)

Access via: `Win + R` $\to$ `taskschd.msc` $\to$ Enter (or `control schedtasks`)

### 1. Scheduled Task Auditing
- **Path**: `Task Scheduler Library`.
- **Review**: Inspect all scheduled jobs in root and subfolders (`Microsoft` exclusions).
- **Suspicious Indicators**:
  - Tasks running scripts from `C:\Users\...\AppData\Local\Temp` or `C:\Windows\Temp`.
  - Powershell encoded commands (`powershell.exe -enc ...` or `-nop -w hidden`).
  - Tasks executing batch files (`users.bat`, `run.bat`).
- **Remediation**: Right-click task $\to$ **Disable** or **Delete**.

### 2. Deep Inspection of Task Triggers & Privileges
- **Path (`taskschd.msc` GUI)**:
  - Select task $\to$ `Properties`.
  - **Triggers Tab**: Inspect triggers set to *"At log on of any user"* or *"At startup"*.
  - **Actions Tab**: Inspect the binary executed (`cmd.exe /c`, `powershell.exe -enc`, `wscript.exe`, or batch files).
  - **General Tab**: Check if **"Run with highest privileges"** or **"Hidden"** is enabled on unknown tasks.
  - Right-click unauthorized task $\to$ Click **Disable** or **Delete**.

### 3. PowerShell Non-Microsoft Scheduled Tasks Query
- **PowerShell (Admin) Command**:
  ```powershell
  Get-ScheduledTask | Where-Object { $_.TaskPath -notlike "\Microsoft*" -and $_.TaskPath -notlike "\Apple*" } | Select-Object TaskName, TaskPath, State, @{Name="Execute";Expression={$_.Actions.Execute}}, @{Name="Arguments";Expression={$_.Actions.Arguments}} | Format-Table -AutoSize
  ```
- **Remediation**:
  ```powershell
  Unregister-ScheduledTask -TaskName "<SuspiciousTaskName>" -Confirm:$false
  ```

### 4. Inspect WMI Event Subscription Persistence
- **PowerShell (Admin) Command**:
  ```powershell
  Write-Host "=== WMI Event Filters ===" -ForegroundColor Yellow
  Get-CimInstance -Namespace root\subscription -ClassName __EventFilter | Select-Object Name, Query
  Write-Host "=== WMI Command Line Consumers ===" -ForegroundColor Yellow
  Get-CimInstance -Namespace root\subscription -ClassName CommandLineEventConsumer | Select-Object Name, CommandLineTemplate, ExecutablePath
  Write-Host "=== WMI Filter To Consumer Bindings ===" -ForegroundColor Yellow
  Get-CimInstance -Namespace root\subscription -ClassName __FilterToConsumerBinding | Select-Object Filter, Consumer
  ```
- **Remediation**:
  ```powershell
  Get-CimInstance -Namespace root\subscription -ClassName CommandLineEventConsumer | Where-Object { $_.Name -like "*malicious*" -or $_.CommandLineTemplate -like "*powershell*" } | Remove-CimInstance
  Get-CimInstance -Namespace root\subscription -ClassName __EventFilter | Where-Object { $_.Name -like "*malicious*" } | Remove-CimInstance
  ```
- **Security Justification**: WMI event subscriptions provide fileless persistence that triggers payload execution when specific events occur without appearing in Task Scheduler.

---

## 1.9 Registry Editor (regedit.exe)

Access via: `Win + R` $\to$ `regedit` $\to$ Enter

### 1. Disable CD/Media AutoRun
- **Path**: `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer`
- **Action**: Create or modify `NoDriveTypeAutoRun` (DWORD) $\to$ Value: `0x000000FF` (255 decimal).

### 2. Restrict Anonymous SAM Enumeration
- **Path**: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa`
- **Action**:
  - `RestrictAnonymous` (DWORD) $\to$ Value: `1`
  - `RestrictAnonymousSAM` (DWORD) $\to$ Value: `1`
  - `LimitBlankPasswordUse` (DWORD) $\to$ Value: `1`

### 3. Clear Pagefile at Shutdown
- **Path**: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management`
- **Action**: `ClearPageFileAtShutdown` (DWORD) $\to$ Value: `1`.

### 4. Enforce Safe DLL Search Mode
- **Path**: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager`
- **Value Name**: `SafeDllSearchMode` (REG_DWORD) $\to$ Value: `1`.
- **Security Justification**: Mitigates DLL search-order hijacking by forcing the OS to search directories in the system path (`System32`, `Windows`) before looking in the current working directory.

### 5. Validate Winlogon Shell & Userinit Integrity
- **Path**: `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`
- **Audited Values**:
  - `Shell`: Must be strictly `explorer.exe` (REG_SZ).
  - `Userinit`: Must be strictly `C:\Windows\system32\userinit.exe,` (REG_SZ - note the trailing comma!).
- **Security Justification**: Classic registry persistence location where adversaries execute trojans at the moment of user interactive logon.

### 6. Clean Run and RunOnce Startup Registry Hives
- **Paths**:
  - `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run` and `RunOnce`
  - `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` and `RunOnce`
  - `HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run` and `RunOnce`
- **Action**: Open `regedit.exe`, navigate to each path, and delete values pointing to unauthorized binaries, reverse shells, or suspicious batch files.

### 7. Clean AppInit_DLLs Injection Registry Keys
- **Path**: `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows`
- **Audited Values**:
  - `AppInit_DLLs`: Must be completely **blank**.
  - `LoadAppInit_DLLs`: Must be `0` (REG_DWORD).
- **Security Justification**: AppInit_DLLs forces every user-mode process loading `user32.dll` to silently load specified DLLs into its address space.

---

## 1.10 Command Prompt & PowerShell Security Commands

Run administrative shell via: `Win + X` $\to$ **Windows Terminal (Admin)** or `powershell` (Run as Administrator)

### 1. PowerShell Script & Module Auditing
Enable detailed administrative logging via Group Policy (`gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Windows Components` $\to$ `Windows PowerShell`):
- **Turn on PowerShell Script Block Logging**: **Enabled**.
- **Turn on PowerShell Module Logging**: **Enabled** (Add `*` under Module Names).
- **Turn on PowerShell Transcription**: **Enabled**.

### 2. Verifying PowerShell Version
```powershell
$PSVersionTable.PSVersion
```
*(Windows PowerShell 5.1 is the latest built-in OS version; PowerShell Core 7 is an optional separate install).*

### 3. Group Policy Refresh
Whenever policies are modified in `secpol.msc` or `gpedit.msc`, force an immediate re-application across all user and machine scopes:
```cmd
gpupdate /force
```

### 4. Querying Scheduled Tasks
```powershell
schtasks /query /fo LIST /v | Out-File -FilePath C:\tasks_audit.txt
```

### 5. Inspecting Active Network Sockets & Bound Ports
```cmd
netstat -ano | findstr LISTENING
```

### 6. Enforce PowerShell Execution Policy
```powershell
Get-ExecutionPolicy -List
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
```
*(Restricts execution of unsigned scripts downloaded from the Internet while allowing local administrative scripts).*

### 7. DNS Cache Forensics and Cleansing
```cmd
ipconfig /displaydns | more
ipconfig /flushdns
```
*(Inspects recently resolved domain names for C2 activity and flushes poisoned DNS records).*

### 8. Map Listening Ports to Owning Process Names & File Paths
```powershell
Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort, OwningProcess, @{Name="ProcessName";Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}}, @{Name="Path";Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Path}} | Sort-Object LocalPort | Format-Table -AutoSize
```
*(Directly correlates open TCP listening sockets with their exact executable paths).*

### 9. Query SMB Shares and Sessions via PowerShell
```powershell
Get-SmbShare | Format-Table -AutoSize
Get-SmbSession | Format-Table -AutoSize
Get-SmbOpenFile | Format-Table -AutoSize
```

---

## 1.11 File System, Drive Security & Prohibited Media Files

### 1. Root Drive Permissions & System Directories
- **Path**: `C:\` $\to$ Right-click $\to$ `Properties` $\to$ `Security` tab.
- **Rules**:
  - Restrict access control on root drive.
  - Inspect `C:\Windows\System32`: Remove `Everyone: Full Control`.
  - Ensure only `SYSTEM` and `Administrators` have Full Control.
  - Review permissions using `icacls`:
    ```cmd
    icacls "C:\Windows\System32" /verify
    ```

### 2. Operating System File Integrity Repair (SFC & DISM)
```cmd
sfc /scannow
DISM /Online /Cleanup-Image /RestoreHealth
```
*(Repairs corrupted system files, system DLLs, and broken firewall/auditing providers altered by rootkits).*


### 3. Hosts File Cleansing
- **Location**: `C:\Windows\System32\drivers\etc\hosts`
- **Inspection**: Open file with Notepad as Administrator.
- **Action**: Remove malicious redirections that redirect antivirus update servers, Microsoft URLs, or search engines to loopback or rogue IP addresses. Retain only default localhost entries (`127.0.0.1 localhost`).

### 4. Prohibited Media Files Searching & Deletion
Search through drive for unauthorized audio, video, picture, and game files (`.mp3`, `.mp4`, `.mov`, `.avi`, `.png`, `.jpg`, `.gif`, etc.):
```cmd
dir /s /b C:\*.mp3 C:\*.mp4 C:\*.mov C:\*.avi C:\*.wav C:\*.mkv
```
> [!CAUTION]
> **Forensics Question Warning**: Sometimes a media or text file contains the answer to a forensics question! Always copy/read forensics answer candidates before deleting files. Once answers are submitted and verified, delete unauthorized media files.

### 5. Hunt and Remove NTFS Alternate Data Streams (ADS)
- **Command Line (Admin)**:
  ```cmd
  dir /R C:\Users\
  ```
- **PowerShell Alternative**:
  ```powershell
  Get-ChildItem -Path C:\Users -Recurse -ErrorAction SilentlyContinue | Get-Item -Stream * -ErrorAction SilentlyContinue | Where-Object { $_.Stream -ne ':$DATA' } | Select-Object PSPath, Stream, Length | Format-Table -AutoSize
  ```
- **Remediation**:
  ```powershell
  Remove-Item -Path "C:\path\to\file.txt" -Stream "hidden_stream_name"
  ```
- **Security Justification**: Adversaries attach hidden executables to benign files using alternate streams (e.g., `calc.txt:backdoor.exe`), hiding malware from standard Explorer views.

### 6. Audit Unattended Setup & Sysprep Passwords
- **PowerShell (Admin) Command**:
  ```powershell
  $answerFiles = @(
      "C:\Windows\Panther\Unattend.xml",
      "C:\Windows\Panther\Unattend\Unattend.xml",
      "C:\Windows\System32\sysprep\sysprep.xml",
      "C:\Windows\System32\sysprep\Panther\Unattend.xml"
  )
  foreach ($f in $answerFiles) {
      if (Test-Path $f) {
          Write-Host "Found setup answer file: $f" -ForegroundColor Red
          Select-String -Path $f -Pattern "Password", "AdministratorPassword", "PlainText"
      }
  }
  ```
- **Remediation**: Record valid credentials for forensics question verification, then delete the answer files or scrub plain-text XML password tags.

### 7. Verify Accessibility Binaries Against Sticky Keys Backdoors
- **PowerShell (Admin) Audit**:
  ```powershell
  $cmdHash = (Get-FileHash C:\Windows\System32\cmd.exe).Hash
  $accessibilityFiles = @("sethc.exe", "utilman.exe", "osk.exe", "narrator.exe", "magnify.exe")
  foreach ($f in $accessibilityFiles) {
      $path = "C:\Windows\System32\$f"
      if (Test-Path $path) {
          $hash = (Get-FileHash $path).Hash
          if ($hash -eq $cmdHash) {
              Write-Host "CRITICAL BACKDOOR DETECTED: $f is a renamed copy of cmd.exe!" -ForegroundColor Red
          } else {
              Write-Host "$f verified: Hash does not match cmd.exe" -ForegroundColor Green
          }
      }
  }
  ```
- **Remediation**: If a binary matches `cmd.exe`, run `sfc /scanfile=C:\Windows\System32\<file>` to restore the genuine signed Microsoft accessibility binary.

---
---

# 2. Features, Applications, Services, and Servers

> **Important**: This section contains instructions for enabling, disabling, and hardening specific Windows features, third-party software, background services, network servers, and protocols.

---

## 2.1 Server Roles & Windows Features Framework

### 1. Windows 10 & 11 Features Configuration
- **GUI Path**: `Control Panel` $\to$ `Programs` $\to$ `Programs and Features` $\to$ **Turn Windows features on or off**.
- **Action**:
  - **Disable / Uncheck**:
    - `SMB 1.0/CIFS File Sharing Support`
    - `Telnet Client`
    - `TFTP Client`
    - `Simple TCP/IP Services`
    - `Internet Information Services` (unless designated as web server)
    - `FTP Server`
    - `Internet Printing Client`
  - **Keep / Enable**:
    - `.NET Framework` (required for system utilities)
    - `Windows Defender Application Guard` / `Virtual Machine Platform` (if Credential Guard is instructed).

### 2. Windows Server (2008, 2019, 2022) Roles & Features Management
- **GUI Path**: `Server Manager` $\to$ `Manage` $\to$ **Remove Roles and Features**.
- **Procedure**:
  - **Step 1 - Server Roles**: Uncheck roles not explicitly requested by README:
    - Remove `DHCP Server`, `Print and Document Services`, `Remote Desktop Services`, `Active Directory Certificate Services`, `Active Directory Domain Services` (unless designated domain controller).
    - Maintain required roles (e.g., `Web Server (IIS)`, `DNS Server`).
  - **Step 2 - Features**: Uncheck unneeded/legacy features:
    - `SMB 1.0/CIFS File Sharing Support`
    - `Telnet Client` / `Telnet Server`
    - `TFTP Client`
    - `Simple TCP/IP Services`
    - `Windows Internal Database`
    - `XPS Viewer`

### 3. Audit and Disable WSL and Windows Sandbox
- **Path (Windows Features GUI)**:
  - In `Turn Windows features on or off`, uncheck:
    - **Windows Subsystem for Linux**
    - **Windows Sandbox**
    - **Virtual Machine Platform** (unless required by Credential Guard).
  - Click **OK** $\to$ Reboot if prompted.
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
  Disable-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM" -NoRestart
  ```
- **Security Justification**: WSL allows users to run Linux binaries, unmonitored bash scripts, and network services that bypass standard Windows endpoint security and firewall rules.

### 4. Scripted Feature Auditing via PowerShell
- **PowerShell (Admin) Command**:
  ```powershell
  Get-WindowsOptionalFeature -Online | Where-Object State -eq "Enabled" | Select-Object FeatureName | Sort-Object FeatureName
  ```

---

## 2.2 SMB & Windows File Sharing

### 1. Disable SMBv1 Protocol
- **Method 1 - Windows Features GUI**:
  - `Control Panel` $\to$ `Programs and Features` $\to$ `Turn Windows features on or off` $\to$ Uncheck **SMB 1.0/CIFS File Sharing Support**.
- **Method 2 - PowerShell (Admin)**:
  ```powershell
  Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
  Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
  Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
  ```

### 2. File Share Management (fsmgmt.msc & net share)
- **GUI Path**: `Win + R` $\to$ `fsmgmt.msc` $\to$ Enter.
- **Shares Configuration**:
  - Click **Shares** in left pane.
  - **Mandatory Default Administrative Shares (DO NOT DELETE)**:
    - `ADMIN$`
    - `C$`
    - `IPC$`
  - **Action**: Right-click and **Stop Sharing** on any unauthorized, excessive, or system-drive shares (e.g., `greybeard`, `Public`, `SharedDocs`, `C_drive`).
- **Sessions & Open Files**:
  - In `fsmgmt.msc`, click **Sessions** $\to$ Click **Disconnect All Sessions** from top Action menu.
- **Command Line Auditing**:
  ```cmd
  net share
  net share <shareName> /delete
  ```

### 3. SMB Security Options (Local Security Policy)
Navigate to: `secpol.msc` $\to$ `Security Settings` $\to$ `Local Policies` $\to$ `Security Options`:

| Policy Name | Hardened Value |
| :--- | :--- |
| **Microsoft network server: Digitally sign communications (always)** | **Enabled** |
| **Microsoft network server: Digitally sign communications (if client agrees)** | **Enabled** |
| **Microsoft network client: Digitally sign communications (always)** | **Disabled** (or Enabled if all servers support it) |
| **Microsoft network client: Digitally sign communications (if server agrees)** | **Enabled** |
| **Microsoft network client: Send unencrypted password to third-party SMB servers** | **Disabled** |
| **Microsoft network server: Disconnect clients when logon hours expire** | **Enabled** |
| **Network access: Allow anonymous SID/Name translation** | **Disabled** |
| **Network access: Do not allow anonymous enumeration of SAM accounts** | **Enabled** |
| **Network access: Do not allow anonymous enumeration of SAM accounts and shares** | **Enabled** |
| **Network access: Do not allow storage of passwords and credentials for network authentication** | **Enabled** |
| **Network access: Let Everyone permissions apply to anonymous users** | **Disabled** |
| **Network access: Named Pipes that can be accessed anonymously** | **Enable setting, leave string box completely blank** |
| **Network access: Remotely accessible registry paths** | **Enable setting, leave string box completely blank** |
| **Network access: Remotely accessible registry paths and sub-paths** | **Enable setting, leave string box completely blank** |
| **Network access: Restrict anonymous access to Named Pipes and Shares** | **Enabled** |
| **Network access: Shares that can be accessed anonymously** | **Set to None / Null** |
| **Network access: Sharing and security model for local accounts** | **Classic - local users authenticate as themselves** |
| **Network security: Do not store LAN Manager hash value on next password change** | **Enabled** |
| **Network security: LAN Manager authentication level** | **Send NTLMv2 responses only. Refuse LM & NTLM** |
| **Network security: Minimum session security for NTLM SSP based clients** | **Enable all 4 options** (Require NTLMv2, 128-bit encryption) |
| **Network security: Minimum session security for NTLM SSP based servers** | **Enable all 4 options** (Require NTLMv2, 128-bit encryption) |

### 4. Enforce SMBv3 Encryption
- **PowerShell (Admin) Command**:
  ```powershell
  Set-SmbServerConfiguration -EncryptData $true -Force
  Set-SmbServerConfiguration -RejectUnencryptedAccess $true -Force
  ```
- **Security Justification**: Protects network file transfers against packet sniffing and man-in-the-middle tampering over local subnets.

### 5. Mitigate SMBGhost (CVE-2020-0796) Compression Vulnerability
- **Path**: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters`
- **Value Name**: `DisableCompression` (REG_DWORD) $\to$ Value: `1`.
- **Security Justification**: Blocks remote pre-authentication code execution in SMBv3 compression on unpatched Windows 10 versions 1903/1909 and Server 2019. *(Note: Microsoft provides no GUI or cmdlet alternative for disabling SMB compression)*.

### 6. Restrict SMB Ports on External / Public Interfaces
- **Path (Windows Defender Firewall GUI)**:
  - Open `wf.msc` $\to$ Inbound Rules.
  - Locate rules named **File and Printer Sharing (SMB-In)**.
  - Double-click rule $\to$ `Advanced` tab $\to$ Uncheck **Public** (ensure rule applies only to Private or Domain profiles).
- **Security Justification**: Prevents unauthorized lateral movement and remote SMB access from untrusted external networks.

---

## 2.3 Remote Desktop Services (RDP)


### 1. Modern Remote Desktop Toggle Verification
- **Path (Settings GUI)**:
  - `Settings` $\to$ `System` $\to$ `Remote Desktop`.
  - If RDP is **NOT authorized**: Verify toggle is **Off**; if On, toggle it to **Off** and confirm.
  - If RDP is **REQUIRED**: Toggle to **On**, expand settings, and ensure **"Require computers to use Network Level Authentication (NLA) to connect"** is checked.
- **Security Justification**: In Windows 10/11, toggling RDP in `sysdm.cpl` can sometimes leave the modern UWP Settings toggle out of sync.

### 2. System Properties Configuration (sysdm.cpl)
- **GUI Path**: `Win + R` $\to$ `sysdm.cpl` $\to$ Enter $\to$ **Remote** tab.
- **When RDP is NOT required**:
  - Uncheck **"Allow Remote Assistance connections to this computer"**.
  - Select **"Don't allow remote connections to this computer"**.
- **When RDP IS required (Per README)**:
  - Select **"Allow remote connections to this computer"**.
  - Ensure the checkbox is checked: **"Allow connections only from computers running Remote Desktop with Network Level Authentication (recommended)"** (NLA).

### 3. Remote Desktop User Group Management (lusrmgr.msc)
- **Path**: `lusrmgr.msc` $\to$ `Groups` $\to$ **Remote Desktop Users**.
- **Action**: Remove unauthorized users. Ensure only authorized RDP accounts specified in the README are members.

### 4. Remote Desktop Group Policy Hardening
Navigate to: `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Windows Components` $\to$ `Remote Desktop Services` $\to$ `Remote Desktop Session Host`:
- Under **Security**:
  - **Require secure RPC communication**: **Enabled**.
  - **Set client connection encryption level**: **Enabled** $\to$ Set to **High Level** (or FIPS Compliant).
  - **Require use of specific security layer for remote (RDP) connections**: **Enabled** $\to$ Set to **SSL (TLS 1.0)** or **Negotiate**.
  - **Require user authentication for remote connections by using Network Level Authentication (NLA)**: **Enabled**.
- Under **Session Time Limits**:
  - **Set time limit for active but idle Remote Desktop Services sessions**: **30 minutes**.
  - **Set time limit for disconnected sessions**: **1 minute** (or 15 minutes).

### 5. RDP Windows Services Configuration
- Services Console (`services.msc`):
  - `Remote Desktop Services` (`TermService`): If RDP is needed $\to$ **Automatic**; If RDP is prohibited $\to$ **Disabled**.
  - `Remote Desktop Services UserMode Port Redirector`: Disable if not needed.
  - `Remote Desktop Configuration`: Disable if not needed.

### 6. RDP Firewall Rule
- If RDP is prohibited: Block inbound TCP port **3389** in Windows Defender Firewall with Advanced Security.

### 7. Enable Restricted Administration Mode for RDP
- **Path (Group Policy GUI)**:
  - `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `System` $\to$ `Credentials Delegation`.
  - Double-click policy: **"Restrict delegation of credentials to remote servers"**.
  - Select **Enabled** $\to$ Select **"Require Restricted Admin"** $\to$ Click OK.
- **Security Justification**: Prevents reusable credentials (pass-the-hash or plaintext passwords) from being stored in memory on the target remote server during RDP sessions.

### 8. Configure Custom RDP Port via Registry (When Required)
- **Path**: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`
- **Value Name**: `PortNumber` (REG_DWORD) $\to$ Value: Custom decimal port (e.g., `3390`). *(Note: Windows provides no GUI to rebind the Terminal Server port)*.
- **Firewall Rule via PowerShell (Admin)**:
  ```powershell
  New-NetFirewallRule -DisplayName "RDP-Custom-Port" -Direction Inbound -Protocol TCP -LocalPort 3390 -Action Allow
  ```

### 9. Restrict Drive and Device Redirection over RDP
- **Path (Group Policy GUI)**:
  - `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Windows Components` $\to$ `Remote Desktop Services` $\to$ `Remote Desktop Session Host` $\to$ `Device and Resource Redirection`.
  - Enable the following policies:
    - **Do not allow drive redirection**: **Enabled**.
    - **Do not allow COM port redirection**: **Enabled**.
    - **Do not allow LPT port redirection**: **Enabled**.
- **Security Justification**: Blocks malicious files on a connecting client machine from automatically mounting inside the RDP host session.

---

## 2.4 Web Browsers (Chrome, Firefox, Internet Explorer, Edge)

### 1. Google Chrome
- **Set as Default**: Ensure Chrome is set as default system web browser when dictated by organizational policy.
- **Update**: Click `Three dots` $\to$ `Help` $\to$ `About Google Chrome` $\to$ Download and apply latest stable release.
- **Intrusive Ads & Popups**:
  - Navigate to: `chrome://settings/content/ads` $\to$ Ensure **"Blocked on sites that show intrusive or misleading ads"** is selected.
  - Navigate to: `chrome://settings/content/popups` $\to$ Set to **"Don't allow sites to send pop-ups or use redirects"**.
- **Extensions**:
  - Navigate to: `chrome://extensions` $\to$ Remove any suspicious add-ons (e.g., adware toolbars, `SharpChrome`).
- **In-Browser Security Hardening**:
  - **Safe Browsing**: Navigate to `chrome://settings/security` $\to$ Select **"Enhanced protection"**.
  - **Third-Party Cookies**: Navigate to `chrome://settings/cookies` $\to$ Select **"Block third-party cookies"**.
  - **Password Manager**: Navigate to `chrome://password-manager/settings` $\to$ Toggle **"Offer to save passwords"** to **Off**.

### 2. Mozilla Firefox
- **Update**: Click `Menu icon` $\to$ `Help` $\to$ `About Firefox` $\to$ Check for Updates.
- **General Settings**:
  - Check **"Automatically install updates (recommended)"**.
- **Privacy & Security Settings**:
  - **Pop-up Windows**: Check **"Block pop-up windows"** and **"Warn you when websites try to install add-ons"**.
  - **Security / Deceptive Content**:
    - Check **"Block dangerous and deceptive content"**.
    - Check **"Block dangerous downloads"**.
    - Check **"Warn you about unwanted and uncommon software"**.
  - **Permissions / Autoplay**:
    - Under `Permissions` $\to$ `Autoplay` $\to$ `Settings` $\to$ Set Default for all websites to **"Block Audio and Video"**.
- **Extensions & Themes**:
  - `Menu` $\to$ `Add-ons and Themes` $\to$ `Extensions` $\to$ Remove unapproved extensions.

### 3. Internet Explorer (Legacy Systems)
- **Version**: Verify Internet Explorer 11 is installed.
- **Pop-up Blocker**: `Tools` $\to$ `Pop-up Blocker` $\to$ **Turn On Pop-up Blocker**.
- **Manage Add-ons**:
  - `Tools` $\to$ `Manage Add-ons` $\to$ Under `Show: All add-ons` $\to$ Right-click **Adobe Flash Player** $\to$ **Disable**.
  - Disable all third-party search helper bars and unauthorized extensions.
- **Internet Explorer Enhanced Security Configuration (IE ESC)**:
  - On Server 2008 / 2012 / 2016 / 2019: In Server Manager, verify IE ESC status per competition requirements.

### 4. Microsoft Edge
- **SmartScreen**: Settings $\to$ Privacy, search, and services $\to$ Turn on **Microsoft Defender SmartScreen**.
- **Block Potentially Unwanted Apps**: Toggle to **On**.
- **Password Manager**: Navigate to `edge://settings/passwords` $\to$ Toggle **"Offer to save passwords"** to **Off**.

### 5. Audit and Remove Unapproved Browsers
- **Path (Control Panel / Settings GUI)**:
  - `Control Panel` $\to$ `Programs and Features` $\to$ Scan for and **Uninstall** unauthorized browsers: `Tor Browser`, `Brave`, `Opera`, `Vivaldi`, `UC Browser`.
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  $unapproved = @("Tor Browser", "Brave", "Opera", "Vivaldi", "UCBrowser")
  Get-Package | Where-Object { $unapproved -contains $_.Name } | Uninstall-Package
  ```

---

## 2.5 Web Servers (IIS, Apache, Abyss Web Server)

### 1. Internet Information Services (IIS Manager)
Access via: `Win + R` $\to$ `inetmgr` $\to$ Enter

- **Bindings & Ports**:
  - Bindings must be restricted strictly to authorized ports: **80 (HTTP)** and **443 (HTTPS)**.
  - Remove unexpected port listeners.
- **Logging Configuration**:
  - Select server/site $\to$ **Logging**:
    - Format: **W3C**.
    - Verify log directory: Move off the system root drive if specified, or enforce strict NTFS permissions (Administrators and SYSTEM only).
    - Ensure logging records Client IP, User Name, Method, URI Stem, HTTP Status, and User Agent.
- **Default & Sample Content**:
  - Expand `Sites` $\to$ Remove `Default Web Site` or remove default placeholder files (`iisstart.htm`, `iisstart.png`).
  - Delete sample sites and virtual directories (e.g., `IISHelp`, `MSADC`, sample SDK applications).
- **Anonymous Authentication**:
  - Select Site $\to$ `Authentication`:
    - If Anonymous Authentication is used, ensure the anonymous identity does not have Write/Modify NTFS permissions on web folders.
    - If Basic Authentication is enabled: Configure **Only Use Basic Authentication with SSL**.
- **ISAPI Filters & Handler Mappings**:
  - Remove unused or obsolete ISAPI filters.
  - Remove unnecessary handler mappings (e.g., legacy `.asp`, `.cer`, `.cdx` mappings if only static HTML or .NET is served).
  - Remove unused WebDAV authoring rules.
- **Extended Protection**:
  - For SSL/TLS-protected sites: Enable **Extended Protection** (IIS 6, IIS 7, IIS 7.5).
- **Application Pool Security**:
  - Ensure Application Pools run under dedicated low-privileged identities (`ApplicationPoolIdentity` or `NetworkService`), never as `Administrator` or `LocalSystem`.
- **Remove IIS7 Metabase Compatibility Feature**:
  - Remove via Roles & Features if legacy IIS 6 management compatibility is not required.

### 2. Apache HTTP Server (e.g., C:\Apache24)
- **Install Location**: Ensure binary remains at designated path (e.g., `C:\Apache24`).
- **Configuration File**: `C:\Apache24\conf\httpd.conf`
  - Remove or comment out default test pages (`test.php`, default info pages).
  - Disable directory browsing: Change `Options Indexes FollowSymLinks` to:
    ```apache
    Options FollowSymLinks
    ```
  - Restrict bindings to specific IP addresses:
    ```apache
    Listen 192.168.1.100:80
    ```
  - Configure ServerTokens and ServerSignature to suppress version banners:
    ```apache
    ServerTokens Prod
    ServerSignature Off
    ```
- **Web Application Directory Permissions**:
  - `C:\Apache24\htdocs`:
  - Right-click $\to$ `Properties` $\to$ `Security`:
    - Remove `Everyone: Full Control`.
    - Grant Full Control only to `SYSTEM` and `Administrators`.
  - Enable Object Access auditing in Group Policy for `C:\Apache24\htdocs`.

### 3. Abyss Web Server
- **Unauthorized Software Warning**: If Abyss Web Server is found running on a workstation/server where it was not authorized by the README $\to$ Stop service and uninstall completely via Control Panel.

### 4. IIS Request Filtering and Security Response Headers
- **Path (IIS Manager GUI - `inetmgr`)**:
  - Select Site $\to$ Double-click **Request Filtering**:
    - **HTTP Verbs Tab**: Click **Deny Verb...** in right pane $\to$ Deny `TRACE`, `TRACK`, `DEBUG`.
    - **File Name Extensions Tab**: Click **Deny File Name Extension...** $\to$ Add `.bak`, `.inc`, `.old`, `.sql`, `.config`.
  - Select Site $\to$ Double-click **HTTP Response Headers**:
    - Add `X-Frame-Options`: `SAMEORIGIN` (prevents Clickjacking).
    - Add `X-Content-Type-Options`: `nosniff` (prevents MIME confusion).
    - Add `Strict-Transport-Security`: `max-age=31536000; includeSubDomains` (enforces HSTS).
- **Security Justification**: Hardens web endpoints against common OWASP Top 10 attacks, clickjacking, and information disclosure.

### 5. Apache `.htaccess` Override Restrictions & Slowloris Mitigation
- **Configuration Directives (`C:\Apache24\conf\httpd.conf`)**:
  ```apache
  <Directory "C:/Apache24/htdocs">
      AllowOverride None
      Options -Indexes +FollowSymLinks
      Require all granted
  </Directory>

  TraceEnable Off
  Timeout 60
  KeepAliveTimeout 5
  ```
- **Security Justification**: Prevents unauthorized web developers or attackers from modifying server settings via hidden `.htaccess` files and mitigates Slowloris DoS attacks.

---

## 2.6 Database Servers (Microsoft SQL Server & MariaDB / MySQL)

### 1. Microsoft SQL Server
- **SQL Server Configuration Manager**:
  - `SQL Server Network Configuration` $\to$ `Protocols for <InstanceName>`:
    - **Disable Dynamic Port Assignments**: Assign a fixed TCP port (default 1433) or keep internal.
    - **Disable All Protocols except TCP/IP**: Disable `Shared Memory` (if cross-process not needed), `Named Pipes`, and `VIA`.
    - **Force Encryption**: Right-click Protocols $\to$ `Properties` $\to$ Set **Force Encryption** to **Yes**.
    - Configure SQL Server with an SSL Certificate from a Trusted Authority.
- **SQL Server Management Studio (SSMS) Hardening**:
  - **Remove Sample Databases**: Delete databases such as `AdventureWorks`, `Northwind`, `pubs`.
  - **Authentication Mode**: Enable Windows Authentication mode where possible, or enforce strong passwords for SQL Authentication logins.
  - **Audit Logging**: Set **Login Auditing** to **Both failed and successful logins** (or **Failed logins only**).
  - **Disable xp_cmdshell (CRITICAL VULNERABILITY)**:
    ```sql
    EXEC sp_configure 'show advanced options', 1;
    RECONFIGURE;
    EXEC sp_configure 'xp_cmdshell', 0;
    RECONFIGURE;
    ```
  - **Remove Public Permissions for Extended Stored Procedures**: Revoke `EXECUTE` permissions on extended stored procedures from the `public` role.
  - **Limit Sysadmin Role**:
    - The `sysadmin` fixed server role must contain no more than 2 authorized administrator logins.
    - Remove `BUILTIN\Administrators` from the `sysadmin` role.
  - **Service Accounts**: Service accounts must NOT be members of the `sysadmin` server role.
  - **Disable Guest Account**: Disable the `guest` user in user databases and master.
  - **Password Rotation**: Update SQL passwords older than 70 days; enforce password complexity.
  - **C2 Audit Mode**: Enable C2 Audit Mode if high-business-impact (HBI) data is transported.
  - **Secure SQL Log Files**: Secure SQL log and `.mdf`/`.ldf` directories with restrictive NTFS ACLs.

### 2. MariaDB / MySQL (e.g., C:\MariaDB)
- **Install Location**: Maintain original install location (e.g., `C:\MariaDB`).
- **Initial Hardening**:
  - Remove test databases (`DROP DATABASE test;`).
  - Ensure `root` has a strong password (no blank passwords allowed!).
  - Restrict `root` login strictly to `localhost`:
    ```sql
    DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
    DELETE FROM mysql.user WHERE User='';
    FLUSH PRIVILEGES;
    ```
- **Application Database Protection**:
  - Verify and preserve critical business databases (e.g., `ecorp_directory`).
  - Repair damaged/dropped tables from backup or migration scripts if an attack occurred.

### 3. SQL Server Surface Area Reduction
- **Services Console & SSMS Query**:
  - Open `services.msc` $\to$ Double-click **SQL Server Browser** (`SQLBrowser`) $\to$ Click **Stop** $\to$ Set **Startup type** to **Disabled** (UDP port 1434 exposes instance enumeration).
  - Execute in SSMS:
    ```sql
    EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
    EXEC sp_configure 'clr enabled', 0; RECONFIGURE;
    EXEC sp_configure 'Ole Automation Procedures', 0; RECONFIGURE;
    EXEC sp_configure 'remote access', 0; RECONFIGURE;
    EXEC sp_configure 'Database Mail XPs', 0; RECONFIGURE;
    ```
- **Security Justification**: Eliminates secondary code execution avenues frequently leveraged by SQL injection payloads.

### 4. MariaDB / MySQL Configuration Hardening (`my.ini`)
- **Directives under `[mysqld]` in `my.ini`**:
  ```ini
  [mysqld]
  local_infile = 0
  skip-symbolic-links
  bind-address = 127.0.0.1
  ```
- **Security Justification**: `local_infile = 1` allows attackers with basic query access to exfiltrate arbitrary files from the Windows host (`LOAD DATA LOCAL INFILE 'C:/Windows/win.ini'`).

---

## 2.7 Remote Administration & Management (WinRM, PowerShell Remoting, Remote Registry)

### 1. Windows Remote Management (WinRM)
- **README Check**: Determine if WinRM is authorized for temporary management.
- **If WinRM is PROHIBITED**:
  - Disable service via PowerShell:
    ```powershell
    Disable-PSRemoting -Force
    Stop-Service WinRM
    Set-Service WinRM -StartupType Disabled
    ```
- **If WinRM is REQUIRED**:
  - Open `lusrmgr.msc` $\to$ `Groups` $\to$ **Remote Management Users**.
  - Remove all unauthorized users.
  - Add only authorized users explicitly listed in the README (e.g., `ealderson`, `lchong`, `tcolby`, `sknowles`, `twellick`).

### 2. Remote Registry Service
- **Status**: Remote Registry exposes the system configuration over TCP port 445 and should almost always be disabled.
- **Configuration**:
  - Open `services.msc` $\to$ Double-click **Remote Registry**.
  - Click **Stop**.
  - Set **Startup type** to **Disabled** (or **Manual** on legacy Server 2008 if mandated).

### 3. Disable WinRM Basic Auth & Unencrypted Traffic
- **Command Line (Admin)**:
  ```cmd
  winrm set winrm/config/service/auth @{Basic="false"}
  winrm set winrm/config/client/auth @{Basic="false"}
  winrm set winrm/config/service @{AllowUnencrypted="false"}
  winrm set winrm/config/client @{AllowUnencrypted="false"}
  ```
- **Security Justification**: Enforces Kerberos or certificate encryption on WinRM sessions, preventing credential capture on the network.

### 4. Verify WinRM TrustedHosts is Not Wildcard
- **PowerShell (Admin) Command**:
  ```powershell
  # Check current TrustedHosts value:
  Get-Item WSMan:\localhost\Client\TrustedHosts
  # Clear wildcard TrustedHosts:
  Set-Item WSMan:\localhost\Client\TrustedHosts -Value "" -Force
  ```
- **Security Justification**: A wildcard `*` permits WinRM to authenticate to rogue servers without verifying their identity.

---

## 2.8 Email & Messaging Servers (SMTP)

### 1. General Audit & Hardening
- **Audit**: Inspect if SMTP is required by the competition scenario.
- **If SMTP is UNNECESSARY**:
  - Remove SMTP feature via Server Manager / Windows Features.
  - Disable the **Simple Mail Transfer Protocol (SMTP)** service (`SMTPSVC`).
  - Block TCP port **25** on the firewall.
- **If SMTP IS REQUIRED**:
  - **Authentication**: Enable strong authentication; disable anonymous relaying.
  - **Encryption**: Enforce TLS encryption for incoming/outgoing SMTP traffic.
  - **Logging**: Enable verbose W3C logging for SMTP sessions.
  - **Bad Mail Folder**: Relocate the default `BadMail` directory away from the system drive root.

### 2. Enforce SMTP Relay Restrictions
- **Path (IIS 6.0 Manager GUI)**:
  - Open IIS 6.0 Manager $\to$ Right-click `[SMTP Virtual Server]` $\to$ `Properties` $\to$ `Access` tab.
  - Click **Relay...** $\to$ Select **"Only the list below"** $\to$ Ensure list contains only `127.0.0.1` (or is empty).
  - Uncheck: *"Allow all computers which successfully authenticate to relay"*.
  - Click **OK** $\to$ Click **Apply**.
- **Security Justification**: Prevents the SMTP server from functioning as an open relay for spam and phishing campaigns.

### 3. Disable SMTP User Enumeration (VRFY & EXPN)
- **Path (IIS 6.0 Manager GUI)**:
  - In SMTP Virtual Server Properties, navigate to `Delivery` or `Advanced` tab $\to$ Turn off support for `VRFY` and `EXPN` commands.
- **Security Justification**: Prevents remote attackers from querying the mail server to harvest valid user accounts.

---

## 2.9 Network Services & Legacy Protocols (FTP, TFTP, Telnet, SNMP, SSDP, UPnP, RIP Listener, Simple TCP/IP)

### 1. Vulnerable Services to Stop and Disable
Open `services.msc` $\to$ Double-click each service $\to$ Click **Stop** $\to$ Set **Startup type** to **Disabled**:

| Service Name | Display Name | Port / Risk | Action |
| :--- | :--- | :--- | :--- |
| `ftpsvc` | **Microsoft FTP Service** | TCP 21 (Plaintext credentials) | **Disable & Stop** |
| `TlntSvr` | **Telnet** | TCP 23 (Plaintext credentials) | **Disable & Stop** |
| `SNMPTRAP` | **SNMP Trap** | UDP 162 (Cleartext monitoring data) | **Disable & Stop** |
| `SimpTcp` | **Simple TCP/IP Services** | TCP/UDP 7, 9, 13, 17, 19 | **Disable & Stop** |
| `upnphost` | **UPnP Device Host** | Port 2869 (Remote exploit surface) | **Disable & Stop** |
| `SSDPSRV` | **SSDP Discovery** | UDP 1900 (DDoS amplification, UPnP) | **Disable & Stop** |
| `RipListener` | **Routing Information Protocol (RIP) Listener** | UDP 520 (Route spoofing) | **Disable & Stop** |
| `RpcLocator` | **Remote Procedure Call (RPC) Locator** | Legacy RPC locator service | **Disable & Stop** |
| `SharedAccess` | **Internet Connection Sharing (ICS)** | Rogue DHCP/NAT forwarding | **Disable & Stop** |
| `RemoteRegistry`| **Remote Registry** | TCP 445 (Remote registry edits) | **Disable & Stop** |
| `Browser` | **Computer Browser** | Legacy NetBIOS master browser | **Disable & Stop** |
| `RemoteAccess` | **Routing and Remote Access** | Unauthorized routing/VPN gateway | **Disable & Stop** |
| `W3SVC` | **World Wide Web Publishing Service** | TCP 80/443 (Disable if not a web server) | **Disable if unneeded** |

### 2. Vital Services to KEEP RUNNING (Set to Automatic)
- `wuauserv` (**Windows Update**)
- `EventLog` (**Windows Event Log**)
- `MpsSvc` (**Windows Defender Firewall**)
- `WinDefend` (**Microsoft Defender Antivirus Service**)
- `Dnscache` (**DNS Client**)
- `LanmanServer` (**Server** - keep running for required administrative shares)
- `LanmanWorkstation` (**Workstation**)
- `Dhcp` (**DHCP Client**)

### 3. Disable Xbox and Gaming Background Services (Win 10/11)
- **Path (`services.msc` GUI)**:
  - Locate each of the following four services, double-click $\to$ Click **Stop** $\to$ Set **Startup type** to **Disabled**:
    - `Xbox Accessory Management Service` (`XboxGipSvc`)
    - `Xbox Live Auth Manager` (`XblAuthManager`)
    - `Xbox Live Game Save` (`XblGameSave`)
    - `Xbox Live Networking Service` (`XboxNetApiSvc`)
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  $gamingServices = @("XblAuthManager", "XblGameSave", "XboxGipSvc", "XboxNetApiSvc")
  foreach ($svc in $gamingServices) {
      Get-Service -Name $svc -ErrorAction SilentlyContinue | Set-Service -StartupType Disabled -PassThru | Stop-Service -Force -ErrorAction SilentlyContinue
  }
  ```
- **Security Justification**: Standard CyberPatriot scoring items for client desktop images; gaming services represent unnecessary attack surface.

### 4. Disable Bluetooth Support Service
- **Path (`services.msc` GUI)**:
  - Locate **Bluetooth Support Service` (`bthserv`) $\to$ Click **Stop** $\to$ Set **Startup type** to **Disabled**.
- **Security Justification**: Closes potential wireless attack vectors on desktop and laptop competition images.

### 5. Disable Downloaded Maps Manager
- **Path (`services.msc` GUI)**:
  - Locate **Downloaded Maps Manager** (`MapsBroker`) $\to$ Click **Stop** $\to$ Set **Startup type** to **Disabled**.

### 6. Disable Remote Desktop Services UserMode Port Redirector
- **Path (`services.msc` GUI)**:
  - Locate **Remote Desktop Services UserMode Port Redirector** (`UmRdpService`) $\to$ Click **Stop** $\to$ Set **Startup type** to **Disabled** if device redirection is not needed.

---

## 2.10 Network Stack & Name Resolution (IPv6, NetBIOS over TCP/IP, LLMNR, DNS Client, SYN Flood Protection)

### 1. Disable IPv6 (When Instructed by README)
- **Method 1 - Network Adapter GUI**:
  - `Control Panel` $\to$ `Network and Internet` $\to$ `Network Connections` $\to$ `Change adapter settings`.
  - Right-click adapter $\to$ `Properties`.
  - Uncheck **Internet Protocol Version 6 (TCP/IPv6)** $\to$ Click **OK**.
- **Method 2 - Registry**:
  - `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters`
  - Create/modify DWORD: `DisabledComponents` $\to$ Set value to `0xFF` (255 decimal).

### 2. Disable NetBIOS over TCP/IP
- **GUI Path**:
  - Open Network Adapter Properties $\to$ Double-click **Internet Protocol Version 4 (TCP/IPv4)**.
  - Click **Advanced** $\to$ Navigate to **WINS** tab.
  - Select radio button: **"Disable NetBIOS over TCP/IP"** $\to$ Click **OK**.
- **Service**:
  - In `services.msc`, locate **TCP/IP NetBIOS Helper** (`lmhosts`) $\to$ **Stop** and set to **Disabled**.

### 3. Disable LLMNR (Link-Local Multicast Name Resolution)
- **Group Policy Path**:
  - `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Network` $\to$ `DNS Client`.
  - Locate policy: **"Turn Off Multicast Name Resolution"**.
  - Set to **Enabled** (this turns LLMNR OFF, preventing LLMNR poisoning attacks like Responder).

### 4. TCP/IP Network Stack Hardening (SYN Flood Protection)
Navigate to: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters`
Create/modify the following DWORD (32-bit) values:

| Value Name | Recommended Setting | Purpose |
| :--- | :--- | :--- |
| `SynAttackProtect` | **2** | Hardens TCP stack against SYN flood DoS attacks |
| `EnableICMPRedirect` | **0** | Disables ICMP redirect route manipulation |
| `DisableIPSourceRouting` | **2** | Disables IP source routing to prevent packet spoofing |
| `PerformRouterDiscovery`| **0** | Disables automatic router discovery |

### 5. Disable WinHTTP Web Proxy Auto-Discovery Service
- **Path (`services.msc` GUI)**:
  - Locate **WinHTTP Web Proxy Auto-Discovery Service** (`WinHttpAutoProxySvc`).
  - Click **Stop** $\to$ Set **Startup type** to **Disabled**.
- **Security Justification**: Combined with the Control Panel LAN settings check, this completely halts the system from sending WPAD discovery broadcasts over DHCP or DNS.

### 6. Disable Multicast DNS (mDNS)
- **Path (Group Policy GUI)**:
  - `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Network` $\to$ `DNS Client`.
  - Locate policy: **"Turn off multicast name resolution"**.
  - Double-click $\to$ Select **Enabled** (turns off both LLMNR and mDNS broadcast queries).
  - Click **Apply** $\to$ Click **OK**.

---

## 2.11 Active Directory Domain Services & GPMC (Domain Controllers)

*Applicable when the image is a Domain Controller:*

### 1. Active Directory Users and Computers (dsa.msc)
- **Privileged Groups Audit**:
  - Navigate to `Builtin` and `Users` containers.
  - Inspect memberships of high-privilege groups:
    - `Domain Admins`
    - `Enterprise Admins`
    - `Schema Admins`
    - `Administrators`
    - `Remote Desktop Users`
    - `Backup Operators`
  - **Action**: Right-click group $\to$ `Properties` $\to$ `Members` tab $\to$ Remove any unauthorized accounts.

### 2. Group Policy Management Console (gpmc.msc)
- **Default Domain Policy**:
  - Right-click `Default Domain Policy` $\to$ `Edit`.
  - Confirm Password Policy (14+ characters, complexity enabled, history 24) and Account Lockout Policy (5 attempts, 30 min duration).
- **Default Domain Controllers Policy**:
  - Edit policy: Enable auditing for Directory Service Access, Account Management, and Logon Events.

### 3. Protect Against AS-REP Roasting
- **Path (`dsa.msc` GUI)**:
  - Open `dsa.msc` $\to$ Double-click user $\to$ `Account` tab.
  - Under *Account options*, ensure **"Do not require Kerberos preauthentication"** is **Unchecked**.
- **Alternative Method (PowerShell - Admin on DC)**:
  ```powershell
  Get-ADUser -Filter {DoesNotRequirePreAuth -eq $true} | Set-ADAccountControl -DoesNotRequirePreAuth $false
  ```
- **Security Justification**: Accounts with Kerberos pre-authentication disabled allow attackers to request AS-REP packets without authorization and crack the user's password offline.

### 4. Audit Service Principal Names (SPNs) Against Kerberoasting
- **Command Line (Admin on DC)**:
  ```cmd
  setspn -T %USERDNSDOMAIN% -Q */*
  ```
- **Audit Action**: Ensure service accounts registered with SPNs have strong 25+ character passwords and do not belong to `Domain Admins`.

### 5. Reset the `krbtgt` Account Password Twice Following Compromise
- **Path (`dsa.msc` GUI)**:
  - Locate `krbtgt` account $\to$ Right-click $\to$ Click **Reset Password...**.
  - Assign a complex 30+ character random password $\to$ Wait 15 minutes for replication $\to$ Reset a second time.
- **Security Justification**: Completely invalidates forged Kerberos Golden Tickets that may have been created during a simulated breach.

### 6. Enable Active Directory Recycle Bin
- **PowerShell (Admin on DC)**:
  ```powershell
  Enable-ADOptionalFeature 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target (Get-ADForest).Name -Confirm:$false
  ```
- **Security Justification**: Allows instant recovery of accidentally or maliciously deleted domain objects without requiring an authoritative restore.

---

## 2.12 Print Spooler & Printer Drivers

### 1. Disable Print Spooler (If Not a Dedicated Print Server)
- **Vulnerability Context**: Mitigates PrintNightmare (CVE-2021-34527, CVE-2021-1675) and remote DLL injection.
- **Action**:
  - `services.msc` $\to$ Locate **Print Spooler** (`Spooler`).
  - Click **Stop** $\to$ Set **Startup type** to **Disabled**.

### 2. Restrict Printer Driver Installations
- **Group Policy Path**:
  - `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Printers`.
  - Policy: **"Disallow installation of printers using kernel-mode drivers"** $\to$ **Enabled**.
  - Policy: **"Point and Print Restrictions"** $\to$ **Enabled** (Configure to show warning and elevation prompt when installing drivers for new servers).
- **Local Security Policy**:
  - `secpol.msc` $\to$ `Security Options` $\to$ **"Devices: Prevent users from installing printer drivers"** $\to$ **Enabled**.

### 3. Block Inbound Remote Printing Connections (PrintNightmare Fix)
- **Path (Group Policy GUI)**:
  - `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Printers`.
  - Locate policy: **"Allow Print Spooler to accept client connections"**.
  - Double-click $\to$ Select **Disabled** $\to$ Click **Apply** $\to$ Click **OK**.
  - Restart Print Spooler service (`services.msc` $\to$ right-click `Print Spooler` $\to$ `Restart`).
- **Security Justification**: Keeps local printing functioning normally while completely blocking remote RPC clients from sending print jobs to exploit PrintNightmare.

### 4. Restrict Point and Print Driver Installations to Administrators via GPO
- **Path (Group Policy GUI)**:
  - `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Printers`.
  - Double-click **"Limits print driver installation to Administrators"** $\to$ Set to **Enabled**.
  - Double-click **"Point and Print Restrictions"** $\to$ Set to **Enabled**:
    - Under *"When installing drivers for a new connection"*: Select **Show warning and elevation prompt**.
    - Under *"When updating drivers for an existing connection"*: Select **Show warning and elevation prompt**.
  - Click **Apply** $\to$ Click **OK**.

---

## 2.13 Third-Party Software Management & Required Updates

Keep business-critical applications installed, verified, and updated to the latest secure releases:

- **Notepad++**:
  - Vulnerabilities in v8.5.7 and older (CVE-2023-40031, CVE-2023-40036, CVE-2023-40164, CVE-2023-40166) allow arbitrary code execution.
  - Update via: `?` menu $\to$ `Update Notepad++`, or install latest installer from official repository.
- **7-Zip**:
  - Verify installed version; update to latest release to patch memory corruption / integer overflow CVEs.
- **Wireshark & Npcap**:
  - Check the README: If declared as required business software $\to$ Update Wireshark to latest release. If unauthorized $\to$ Uninstall Wireshark and Npcap.
- **LibreOffice**:
  - Update to latest version (`Help` $\to$ `Check for Updates`).
- **Mozilla Thunderbird**:
  - Update to latest version (`Help` $\to$ `About Thunderbird`).
- **FileZilla Client**:
  - Update to latest release (`Help` $\to$ `Check for Updates`).
- **WinRAR**:
  - Update to patch code execution vulnerabilities (CVE-2023-38831) or uninstall if unauthorized.
- **Java Runtime Environment (JRE / JDK) Hardening**:
  - Open `Control Panel` $\to$ Click `Java` $\to$ `Security` tab:
    - **Uncheck**: **"Enable Java content for browser and Web Start applications"**.
    - Set Security Level to: **Very High**.
  - Update to latest release or uninstall obsolete legacy runtimes (Java 6, 7, 8).
- **Adobe Acrobat Reader Hardening**:
  - Open Adobe Reader $\to$ `Edit` $\to$ `Preferences`:
    - Under `Security (Enhanced)`: Ensure **"Enable Protected Mode at startup"** and **"Enable Enhanced Security"** are Checked.
    - Under `JavaScript`: **Uncheck "Enable Acrobat JavaScript"** (blocks PDF-based JavaScript exploit payloads).
- **Microsoft Office Trust Center Macro & Protected View Hardening**:
  - In Word/Excel: `File` $\to$ `Options` $\to$ `Trust Center` $\to$ `Trust Center Settings`:
    - Under `Macro Settings`: Select **"Disable all macros with notification"**.
    - Under `Protected View`: Ensure all three Protected View checkboxes are enabled.

---

## 2.14 Unauthorized Software, Hacking Tools & Malware Removal

### 1. Software Removal (Control Panel $\to$ Programs and Features)
Scan installed programs list and **Uninstall** unauthorized utilities:
- **Hacking / Pen-Testing Tools**:
  - `Nmap` / `Zenmap`
  - `Wireshark` / `Npcap` / `WinPcap` (unless kept per README)
  - `Cain & Abel`
  - `John the Ripper`
  - `Netcat` (`nc.exe`)
  - `Burp Suite Community Edition`
  - `Metasploit` / `Meterpreter`
  - `fgdump` / `pwdump`
- **P2P & File Sharing**:
  - `uTorrent`, `BitTorrent`, `qBittorrent`
- **Adware & Suspicious System Utilities**:
  - `CCleaner` (`cclearer.exe` / compromised binaries)
  - `IOTransfer`
  - `SharpChrome`
  - `Rejetto HttpFileServer` (`HFS 2.3x`)
  - `WinHTTPTrack`
- **Entertainment, Media & Cloud Sync**:
  - Video games & game launchers (e.g., Steam, Riot, Epic, `Games Games Games`)
  - `iTunes`, `Bonjour`, `Apple Software Update`, `Apple Mobile Device Support`
  - `Jellyfin Media Player`
  - `Google Drive`, `Dropbox`
  - `DeepFreeze Enterprise`
  - `VMware Workstation` / `VirtualBox` (unless authorized virtualization)
  - `Python 3` (if not an approved development host)

### 2. Common Malicious Binaries Checklist
Search files (`Win + S` or Command Prompt) and eliminate known malicious tools:
```
Win1.exe
Win2.exe
Win3.exe
backd00r.exe
asdf.exe
BFK.exe
taskmgr.exe.exe
spyr.exe
nc.exe
fgdump.exe
nginx.exe
users.bat
```

### 3. Expanded Offensive Hacking & Credential Dumping Tool Hunt
- **PowerShell File Search**:
  ```powershell
  $badTools = @("mimikatz.exe", "procdump.exe", "ipscan.exe", "hydra.exe", "aircrack-ng.exe", "hashcat.exe", "ophcrack.exe", "responder.py", "responder.exe")
  Get-ChildItem -Path C:\ -Include $badTools -Recurse -ErrorAction SilentlyContinue | Select-Object FullName
  ```

### 4. Expanded Remote Access Trojans (RATs) & Remote Tools List
- **Path (Control Panel $\to$ Programs and Features)**:
  - Locate and uninstall: `TeamViewer`, `LogMeIn`, `Hamachi`, `TightVNC`, `UltraVNC`, `Ammyy Admin`, `Supremo`, `Radmin`.

### 5. Steganography & Hidden Archive Utilities Hunt
- **Path (Control Panel $\to$ Programs and Features)**:
  - Locate and uninstall: `OpenStego`, `QuickStego`, `Steghide`, `Audacity` (if unapproved media manipulation is suspected).

---

## 2.15 Critical Policies: Do NOT Do Unless Instructed by README

> [!CAUTION]
> In CyberPatriot, certain extreme security baselines can break simulated business functionality, scoring engines, or competition parameters. **Only implement the following items if explicitly directed by the scenario README:**

1. **Disable LM & NTLMv1 Authentication** (Setting NTLMv2 only via secpol or registry can break legacy scoring engines or remote test runners).
2. **Restrict Anonymous Access to Extreme Levels** (May break automated grading scripts communicating via RPC).
3. **Rename or Disable Built-in Administrator Account** (If the scoring system logs in as `Administrator`, renaming or disabling it will cause loss of scoring connectivity).
4. **Enable Credential Guard** (Requires Virtualization Based Security + UEFI lock; can cause VM boot failures if nested virtualization is unsupported).
5. **Disable SMBv1** (Only verify if the scoring engine relies on SMBv1 shares before terminating).
6. **Disable Remote Registry Service** (Some remote scoring platforms query registry hives remotely).
7. **Disable Print Spooler** (If the scenario specifically defines the server as a print server).
8. **Restrict PowerShell Remoting** (If management relies on PowerShell CIM/WSMan sessions).
9. **Enable Process Creation Command Line Logging** (`gpedit.msc` $\to$ Include command line in process creation events).
10. **Enable High-Volume Advanced Auditing** (Can flood event logs and exhaust memory on older images).
11. **Protect LSASS as a Protected Process (RunAsPPL)**:
    - Path: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa`
    - Value: `RunAsPPL` (DWORD) = `1` or `2`.
12. **Restrict System32 ACL Permissions** (Aggressive permission stripping on System32 can render Windows unbootable).
13. **Disable LLMNR** (Ensure name resolution for competition intranet hosts is not disrupted).
14. **Enable SYN Flood Protection** (Can occasionally discard grading check packets if thresholds are exceeded).
15. **Clarify Consequences of Global IPv6 Disabling**: Do not disable IPv6 globally unless specified in the scenario instructions, as doing so can break internal Windows update services and automated scoring scripts.
16. **Clarify Consequences of Renaming Built-in Guest Account**: Always disable the `Guest` account first. Do not rename it unless explicitly graded, as automated grading scripts querying the account by name may fail.

---
---

# 3. Competition Scenarios, Forensics Solutions & Reference Notes

---

## 3.1 General Competition Strategy & Golden Rules

1. **Rule 1: Always Read the README First!**
   - Follow with strict guidance. Identify authorized administrators, authorized standard users, required services, permitted software, and forbidden changes.
2. **Rule 2: Complete Forensics Questions Early!**
   - Forensics questions often reference files, users, or logs that might be deleted or altered during cleanup. Find and record answers before modifying the system.
3. **Rule 3: Take Notes on Forensics Files Before Deleting Media**:
   - Some files contain secret messages, keys, or hashes necessary for scoring points.
4. **Rule 4: Empty the Recycle Bin**:
   - Simple points are often awarded for emptying the desktop Recycle Bin.
5. **Rule 5: Keep the Firewall ON**:
   - Images frequently spawn with the firewall disabled or set to unshielded profiles.
6. **Rule 6: Antivirus Scanning**:
   - Install/update antivirus, check scan exclusions first, and run a complete system scan.

---

## 3.2 Competition 1 (25-26 Windows 11) Debrief & Forensics

### Key Findings & Actions Taken
- **Software Requirements**: Keep Notepad++ and update to latest version.
- **RDP Configuration**: Remote Desktop was required $\to$ Configured RDP service to **Automatic**, enabled NLA, set encryption level to **High**.
- **Group Cleanups**:
  - Inspected Remote Desktop Users group: Discovered unauthorized managers in the group $\to$ Removed unauthorized members.
  - Added authorized user `edarby`.
- **Software Removed**: `Wireshark` and `Npcap` removed.
- **Malware & Virus Detection**:
  - Found 2 malicious files using `icacls` permission checks.
- **Security Baseline**:
  - Configured UAC to Always Notify.
  - Hardened TCP/IP NetBIOS Helper.
  - Configured SMB Direct.

### Forensics Questions & Answers
- **Forensic 1**:
  - **Question**: Forensic text inspection.
  - **Answer**: `I know you are a fraud!` (or `Games Games Games` in alternate variant).
- **Forensic 2**:
  - **Question**: Unauthorized RDP members / Notepad++ vulnerabilities.
  - **Answer 1**: `there are 4RDP group managers that were not meant to be in that group`
  - **Answer 2 (Notepad++ v8.5.7 CVEs)**:
    - `CVE-2023-40031`
    - `CVE-2023-40036`
    - `CVE-2023-40164`
    - `CVE-2023-40166`
- **Accounts Removed**: `hamburgerman`, `darkarmy`, `fsociety`.

---

## 3.3 Competition 2 (25-26 Windows 11) Debrief & Forensics

### Key Findings & Actions Taken
- **Software Updates**: Updated `LibreOffice`, `7-Zip`.
- **User Rights Auditing**:
  - Used `secpol.msc` $\to$ `User Rights Assignment` to discover unauthorized users granted the right to log on through Terminal Services.
  - Demoted unauthorized administrators to standard users.
- **Web Root Discovery**:
  - Used Internet Information Services (IIS) Manager to trace the web application root server directory.

### Forensics Questions & Answers
- **Forensic 1 (AnyDesk Rogue Port Identification)**:
  - Traced AnyDesk active listening ports using Resource Monitor:
  - **Answer**: `7070, 50001`
- **Forensic 2 (Cisco CVE Investigation)**:
  - Search for Cisco bug advisory:
  - **CVE ID**: `CVE-2024-20432`
  - **Cisco Bug ID**: `CSCwj10299`
  - **Affected Product**: `Cisco Nexus Dashboard Fabric Controller`

---

## 3.4 Competition 3 Gold (Server 2019) Debrief & Forensics

### Key Findings & Actions Taken
- **Software Updates**: Updated `FileZilla`, `Wireshark`, `Google Chrome`, `Notepad++`, `WinRAR`.
- **Software Uninstalled**: `Nmap`, `Java 8`, `cclearer.exe`, `Abyss Web Server`, `Meterpreter`.
- **Account Modifications**:
  - Managed accounts: `cmoss`, `dealderson`, `hamburgerman`, `romeo`.
  - Demoted `cmoss` from Administrators group.
  - Removed `dalderson` from Backup Operators group.
  - Deleted unauthorized accounts: `hamburgerman`, `romeo`.
- **Auditing Point Scored**: Enabled auditing for **Computer Account Management** [Failure].
- **Network & Services**:
  - Enabled Windows Defender Firewall.
  - Disabled `SNMP Trap` service.
  - Turned off Remote Desktop sharing.
  - Configured Chrome setting: **"Chrome blocks intrusive ads"**.

### Forensics Questions & Answers
- **Forensic 1 (MD5 Hash Directory Path)**:
  - Hash provided: Answer requested as full directory path of the binary matching the hash.
- **Forensic 2 (Antivirus Scan Exclusion)**:
  - Discovered Windows Defender exclusion: `sysinternals.exe`.
  - **Answer**: `sysinternals.exe`
  - **Action**: Deleted the scan exclusion in Windows Security.
- **Forensic 3 (Secret Message in Shared Documents)**:
  - Plaintext file located in shared documents directory: Deleted file after extracting answer.
  - **Decoded ASCII / Hash Strings**:
    - ASCII Hex: `64 43 6F 64 65 20 41 53 43 49 49` (Decodes to: `dCode ASCII`)
    - Cipher/Hash: One-time pad / SHA-1 hash (`4AB27250D85CE1187FC97F34D38E01648B6114E1`)

---

## 3.5 Competition 4 Gold Semifinals (Windows 11 / Server 2022) Debrief & Forensics

### Windows Server 2022 Semifinals Summary
- **Software Removed**:
  - `iTunes`, `VMware`, `Apple Mobile Device Support`, `Apple Software Update`, `Bonjour`, `Google Drive`, `Microsoft Edge`, `DeepFreeze Enterprise`.
- **Software Updated**:
  - `Google Chrome`, `Wireshark`, `Notepad++`, `7-Zip`.
- **Features Turned On**:
  - Automatic Updates (immediate installation).
  - PowerShell Script Block Logging.
  - PowerShell Transaction / Transcription.
- **Accounts Disabled / Fixed**:
  - Disabled built-in `Administrator` account (after verifying alternative admin access).
  - Disabled built-in `Guest` account.
  - Demoted `twellick` and `davis` from Administrators to normal users.
- **Forensics Answers**:
  - **Forensic 1**: `server authentication, client authentication`
  - **Forensic 3**: Secret batch script payload in `users.bat`:
    - Content: `REM When we lose our principles, we invite chaos.`
    - Action: Submitted string and deleted `users.bat`.

---

## 3.6 Complete Readme / Scenario Reference (Mr. Robot / E-Corp Challenge)

### Background Scenario Text
> *"It is company policy to use only Windows 11 on this computer. Management has decided that the default web browser for all users on this computer should be the latest stable version of Google Chrome. Other business related software includes Notepad++, 7-Zip, and Wireshark. These should remain installed and kept up-to-date. Please ensure that the below services are kept in the original install location. Due to time restraints, management requests that you do NOT install Windows Updates. However, you should ensure that the computer is configured to automatically install updates.*
>
> *Due to a recent security breach, the company has migrated the web application located on the Linux Mint web server to this system. Apache2 and MariaDB are installed and running on this computer. These services must remain installed at their current locations of C:\Apache24 and C:\MariaDB respectively. The web application is located in the "C:\Apache24\htdocs" directory. You must keep this web application running and accessible. Please only make minimal changes to the code when instructed.*
>
> *Currently, the web application uses the MariaDB database "ecorp_directory". Please ensure that this database remains intact and data is not altered. During the original attack, the database somehow lost all of its tables. Please find and fix the issue to prevent further data loss.*
>
> *In order to temporarily manage this system, this system has Windows Remote Management (WinRM) enabled. The following users should be granted access to this system via WinRM: ealderson, lchong, tcolby, sknowles, and twellick."*

### Authorized User Roles & Passwords Table

| Username | Authorized System Role | Password | WinRM Access Authorized? |
| :--- | :--- | :--- | :--- |
| **twellick** *(You)* | Administrator | `3Corp3x3cutive` | **Yes** |
| **jplofe** | Administrator | `AuditM4n@g3r` | No |
| **pmccleery** | Administrator | `root` | No |
| **wbraddock** | Administrator | `NetworkB0ss` | No |
| **ealderson** | Administrator | `samsep10l` | **Yes** |
| **lchong** | Administrator | `t3chn1t!on` | **Yes** |
| **sswailem** | Administrator | `data` | No |
| **pprice** | Standard User | *(Reset to compliant password)* | No |
| **sknowles** | Standard User | *(Reset to compliant password)* | **Yes** |
| **tcolby** | Standard User | *(Reset to compliant password)* | **Yes** |
| **jchutney** | Standard User | *(Reset to compliant password)* | No |
| **sweinsberg** | Standard User | *(Reset to compliant password)* | No |
| **sjacobs** | Standard User | *(Reset to compliant password)* | No |
| **lspencer** | Standard User | *(Reset to compliant password)* | No |
| **mralbern** | Standard User | *(Reset to compliant password)* | No |
| **jrobinson** | Standard User | *(Reset to compliant password)* | No |
| **gsheldern** | Standard User | *(Reset to compliant password)* | No |
| **coshearn** | Standard User | *(Reset to compliant password)* | No |
| **jlaslen** | Standard User | *(Reset to compliant password)* | No |
| **kshelvern** | Standard User | *(Reset to compliant password)* | No |
| **jtholdon** | Standard User | *(Reset to compliant password)* | No |
| **belkarn** | Standard User | *(Reset to compliant password)* | No |
| **bharper** | Standard User | *(Reset to compliant password)* | No |

---

## 3.7 CyberPatriot Master Password & Credential Cheatsheet

Use these standardized complex passwords when rotating passwords for authorized users:

- `PP@@ssword12345`
- `C1sc0!314159???`
- `CyberP12345@SVT`
- `Cisco!314159!`
- `3Corp3x3cutive`
- `AuditM4n@g3r`
- `NetworkB0ss`
- `t3chn1t!on`
