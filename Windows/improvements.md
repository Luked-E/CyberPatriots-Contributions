# CyberPatriot Windows Checklist Improvements & Additions (Staging)

This staging document catalogs researched and validated security configurations, Group Policy settings, GUI procedures, and defensive commands identified as missing from [`ULTIMATE_CYBERPATRIOT_WINDOWS_CHECKLIST.md`](file:///c:/Users/Luke/Documents/Projects/CyberPatriots/Ultimate%20Windows/ULTIMATE_CYBERPATRIOT_WINDOWS_CHECKLIST.md).

> [!NOTE]
> Per hardening guidelines, all configurations that can be managed via graphical interfaces (Settings App, Control Panel, Local Security Policy, Group Policy, Services) or native command-line utilities (`powercfg`, `netsh`, `secedit`, PowerShell security cmdlets) **strictly utilize those native methods**. Direct registry modifications have been removed for all settings where standard GUI or management tool alternatives exist, retaining registry instructions solely for low-level configurations that lack any alternative interface.

---

## Table of Staged Improvements & Implementation Index

| Section | Domain / Tool | New Settings Staged | Primary Management Method | Key Focus Areas |
| :--- | :--- | :---: | :--- | :--- |
| [**Section 1.1**](#11-settings-app) | Settings App | 5 | Settings GUI & Group Policy | Delivery Optimization P2P, Developer Mode, Lock screen notifications, Clipboard history, Remote Desktop toggle |
| [**Section 1.2**](#12-control-panel) | Control Panel | 4 | Control Panel GUI, `powercfg`, `netsh` | Advanced Network Sharing, Password on Wakeup, System Protection/Restore, Internet Options/TLS |
| [**Section 1.3**](#13-local-security-policy-secpolmsc--gpeditmsc) | Local Security Policy | 4 | `secpol.msc` GUI & `secedit` | Explicit Deny logon rights, Sensitive user rights (`SeDebugPrivilege`, etc.), Machine inactivity limit, Block Microsoft Accounts |
| [**Section 1.4**](#14-local-users-and-groups-lusrmgrmsc) | Local Users and Groups | 3 | `lusrmgr.msc` GUI & PowerShell | Built-in utility accounts (`DefaultAccount`, `WDAG`), Sensitive local groups audit, PowerShell local user inspection |
| [**Section 1.5**](#15-computer-management-compmgntmsc) | Computer Management | 3 | `compmgnt.msc` GUI & Event Viewer | Hidden device manager audit, Security event ID threat hunting, Integrated shared folders console |
| [**Section 1.6**](#16-windows-security--threat-protection) | Windows Security | 5 | Windows Security GUI & Defender Cmdlets | Tamper Protection, Controlled Folder Access (Ransomware), System Exploit Protection (DEP/ASLR/SEHOP), PUA Protection, Network Protection |
| [**Section 1.7**](#17-task-manager) | Task Manager | 3 | Task Manager GUI | Image Path & Command Line columns, Services tab audit, Users tab interactive session termination |
| [**Section 1.8**](#18-task-scheduler-taskschdmsc) | Task Scheduler | 3 | `taskschd.msc` GUI & PowerShell WMI | Trigger/privilege inspection, Non-Microsoft scheduled tasks query, WMI event subscription persistence |
| [**Section 1.9**](#19-registry-editor-exclusive-configurations-regeditexe) | Registry Editor (Exclusive) | 4 | `regedit.exe` (No GUI Alternative) | Safe DLL Search Mode, Winlogon Shell/Userinit integrity, Run/RunOnce audit, AppInit_DLLs wipe |
| [**Section 1.10**](#110-command-prompt--powershell-security-commands)| Command Line & PowerShell | 5 | PowerShell Cmdlets & OS Binaries | Execution policy enforcement, SFC & DISM repair, DNS cache display/flush, TCP connection-to-process mapping, PowerShell SMB inspection |
| [**Section 1.11**](#111-file-system-drive-security--prohibited-media-files)| File System & Drive Security | 3 | File System Tools & PowerShell | Alternate Data Streams (ADS) hunting, Unattend/Sysprep credential harvesting, Accessibility backdoor checks (sethc/utilman) |
| [**Section 2.1**](#21-server-roles--windows-features-framework) | Server Roles & Features | 2 | Windows Features GUI & PowerShell | WSL & Windows Sandbox auditing, PowerShell feature inspection/removal |
| [**Section 2.2**](#22-smb--windows-file-sharing) | SMB & File Sharing | 3 | PowerShell SMB & Windows Firewall GUI | SMBv3 Encryption, SMBGhost mitigation, Firewall SMB interface filtering |
| [**Section 2.3**](#23-remote-desktop-services-rdp) | Remote Desktop (RDP) | 3 | Group Policy (`gpedit.msc`) & Registry | Restricted Administration Mode, Custom RDP port, Device/Drive redirection restrictions |
| [**Section 2.4**](#24-web-browsers-chrome-firefox-internet-explorer-edge) | Web Browsers | 3 | In-Browser Settings GUI | Chrome browser security, Edge browser settings, Unauthorized browser removal (Tor/Brave/Opera) |
| [**Section 2.5**](#25-web-servers-iis-apache-abyss-web-server) | Web Servers | 2 | IIS Manager GUI & Apache Config | IIS Request Filtering & HTTP security headers, Apache `.htaccess` override & Slowloris mitigations |
| [**Section 2.6**](#26-database-servers-microsoft-sql-server--mariadb--mysql) | Database Servers | 2 | SSMS, Services GUI, `my.ini` Config | SQL Server Browser & CLR/OLE/Database Mail surface reduction, MariaDB `local_infile` & bind-address hardening |
| [**Section 2.7**](#27-remote-administration--management-winrm-powershell-remoting-remote-registry) | Remote Administration | 2 | `winrm` CLI & WSMan Provider | WinRM listener encryption & basic auth disabling, TrustedHosts wildcard prevention |
| [**Section 2.8**](#28-email--messaging-servers-smtp) | Email Servers (SMTP) | 2 | IIS 6.0 Manager GUI | SMTP open relay prevention (`127.0.0.1` restriction), VRFY/EXPN user enumeration disabling |
| [**Section 2.9**](#29-network-services--legacy-protocols) | Network Services | 4 | Services Console (`services.msc`) | Xbox & gaming services disabling, Bluetooth service disabling, MapsBroker disabling, UmRdpService disabling |
| [**Section 2.10**](#210-network-stack--name-resolution) | Network Stack | 2 | Services GUI & Group Policy GUI | WinHTTP Web Proxy Auto-Discovery service disabling, Multicast DNS (mDNS) GPO disabling |
| [**Section 2.11**](#211-active-directory-domain-services--gpmc-domain-controllers) | Active Directory (AD DS) | 4 | `dsa.msc` GUI & ActiveDirectory Module | AS-REP Roasting protection, Kerberoasting SPN audit, `krbtgt` password rotation, AD Recycle Bin enablement |
| [**Section 2.12**](#212-print-spooler--printer-drivers) | Print Spooler | 2 | Group Policy (`gpedit.msc`) GUI | Inbound client connection blocking (RPC PrintNightmare fix), Point and Print driver admin restriction GPO |
| [**Section 2.13**](#213-third-party-software-management--required-updates) | Third-Party Software | 3 | Application GUI Preferences | Java runtime browser plugin disabling & update, Adobe Acrobat JavaScript disabling & Protected Mode, MS Office macro & Protected View policies |
| [**Section 2.14**](#214-unauthorized-software-hacking-tools--malware-removal) | Malware & Hacking Tools | 3 | PowerShell File Auditing & Uninstall GUI | Credential dumpers (Mimikatz, Procdump), Unauthorized remote access tools (TeamViewer, VNC), Steganography tools (OpenStego) |
| [**Section 2.15**](#215-critical-policies-do-not-do-unless-instructed-by-readme) | Critical "Do NOT Do" | 2 | Competition Strategy Guidance | Global IPv6 disabling consequences, Built-in Guest account renaming warning |

---

# Part 1: General Security Settings and Configurations

---

## 1.1 Settings App

### Improvement 1.1.1: Disable Delivery Optimization Peer-to-Peer Update Sharing
- **Description**: Delivery Optimization turns Windows machines into peer-to-peer (P2P) nodes that upload update chunks to other machines over the local network or the Internet. In competition environments, this can saturate the connection and is frequently scored as an unhardened update distribution setting.
- **Primary Method (Settings GUI)**:
  1. Press `Win + I` to open **Settings**.
  2. On **Windows 10**: Navigate to `Update & Security` $\to$ `Delivery Optimization`.
  3. On **Windows 11**: Navigate to `Windows Update` $\to$ `Advanced options` $\to$ `Delivery Optimization`.
  4. Toggle **"Allow downloads from other PCs"** to **Off**.
  5. *(Optional alternate)*: If the README specifically instructs local intranet update sharing, select the radio button **"Devices on my local network"** instead of "Devices on the internet and my local network".
- **Alternative Method (Group Policy GUI)**:
  1. Press `Win + R` $\to$ Type `gpedit.msc` $\to$ Press Enter.
  2. Navigate to `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Windows Components` $\to$ `Delivery Optimization`.
  3. Double-click **Download Mode** $\to$ Select **Enabled** $\to$ Choose **Simple (99)** or **Bypass (100)** from the dropdown to completely disable P2P peering.
  4. Click **Apply** $\to$ Click **OK**.
- **Verification / Audit**:
  - In Settings, verify the toggle displays **Off**.
  - In Group Policy, verify the policy state displays **Enabled (Simple/Bypass)**.
- **Caveats**: Ensure the `Delivery Optimization` service (`DoSvc`) remains on Automatic or Manual so local updates continue downloading directly from Microsoft over standard HTTPS.

---

### Improvement 1.1.2: Turn Off Developer Mode
- **Description**: Enabling Developer Mode allows installing and debugging unverified, self-signed Universal Windows Platform (UWP) apps, modifies firewall rules to open diagnostic ports, and enables the Device Portal and an SSH server listener.
- **Primary Method (Settings GUI)**:
  1. Press `Win + I` to open **Settings**.
  2. On **Windows 10**: Navigate to `Update & Security` $\to$ `For developers`.
  3. On **Windows 11**: Navigate to `System` (or `Privacy & security`) $\to$ `For developers`.
  4. Locate the **Developer Mode** toggle switch and turn it **Off**.
  5. If prompted with *"Turn on developer mode?"* or warning dialogs, ensure it is set to **Don't allow** or disabled.
- **Alternative Method (Group Policy GUI)**:
  1. Open `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Windows Components` $\to$ `App Package Deployment`.
  2. Locate policy: **"Allows development of Windows Store applications and installing them from an integrated development environment (IDE)"**.
  3. Double-click $\to$ Select **Disabled** $\to$ Click **Apply** $\to$ Click **OK**.
- **Verification / Audit**:
  - In Settings, confirm the toggle is **Off**.
- **Caveats**: If Developer Mode was previously active, verify in `services.msc` that `SSH Server Broker` and `SSH Server Proxy` services are not running.

---

### Improvement 1.1.3: Disable Lock Screen Notification Previews
- **Description**: By default, Windows displays notification banners, calendar events, incoming VoIP previews, and messages on the lock screen before credentials are submitted. Attackers can view sensitive verification codes and user activity without authenticating.
- **Primary Method (Settings GUI)**:
  1. Press `Win + I` $\to$ Navigate to `System` $\to$ `Notifications` (or `Notifications & actions` on Windows 10).
  2. Expand notifications settings or scroll to the top checkbox list.
  3. **Uncheck**: **"Show notifications on the lock screen"**.
  4. **Uncheck**: **"Show reminders and incoming VoIP calls on the lock screen"**.
- **Alternative Method (Group Policy GUI)**:
  1. Open `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `System` $\to$ `Logon`.
  2. Locate policy: **"Turn off app notifications on the lock screen"**.
  3. Double-click $\to$ Select **Enabled** $\to$ Click **Apply** $\to$ Click **OK**.
- **Verification / Audit**:
  - Lock the screen (`Win + L`) and verify no application toast popups appear over the lock screen wallpaper.

---

### Improvement 1.1.4: Disable Clipboard History & Cross-Device Cloud Sync
- **Description**: Windows Clipboard History caches copied text, file paths, and images in memory, allowing access via `Win + V`. If cloud clipboard sync is active, sensitive strings and credentials can leak across user accounts or network endpoints.
- **Primary Method (Settings GUI)**:
  1. Press `Win + I` $\to$ Navigate to `System` $\to$ `Clipboard`.
  2. Toggle **Clipboard history** to **Off**.
  3. Under **Sync across your devices**, ensure the toggle is set to **Off** (or select "Automatically sync text that I copy" is disabled).
  4. Click **Clear clipboard data** to wipe existing clipboard buffers.
- **Alternative Method (Group Policy GUI)**:
  1. Open `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `System` $\to$ `OS Policies`.
  2. Double-click **"Allow Clipboard History"** $\to$ Select **Disabled** $\to$ Click OK.
  3. Double-click **"Allow Clipboard synchronization across devices"** $\to$ Select **Disabled** $\to$ Click OK.
- **Verification / Audit**:
  - Press `Win + V` on the desktop; a notification must appear stating that clipboard history is turned off.

---

### Improvement 1.1.5: Verify Settings App Remote Desktop Toggle
- **Description**: In Windows 10 (version 1809+) and Windows 11, the modern Settings app manages Remote Desktop through modern APIs. Toggling RDP in `sysdm.cpl` can sometimes fail to update the modern application state or Windows Firewall rules on certain builds.
- **Primary Method (Settings GUI)**:
  1. Press `Win + I` $\to$ Navigate to `System` $\to$ `Remote Desktop`.
  2. If RDP is **NOT authorized**:
     - Verify the **Remote Desktop** toggle switch is set to **Off**.
     - If it is On, toggle it to **Off** and click **Confirm** in the popup dialog.
  3. If RDP is **REQUIRED** by README:
     - Toggle **Remote Desktop** to **On**.
     - Click the chevron to expand settings and check **"Require computers to use Network Level Authentication (NLA) to connect"**.
- **Alternative Method (Group Policy GUI)**:
  1. Open `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Windows Components` $\to$ `Remote Desktop Services` $\to$ `Remote Desktop Session Host` $\to$ `Connections`.
  2. Double-click **"Allow users to connect remotely by using Remote Desktop Services"**.
  3. Select **Disabled** (if prohibited) or **Enabled** (if required).
- **Verification / Audit**:
  - In Settings, confirm the toggle matches the state specified in the README.

---

## 1.2 Control Panel

### Improvement 1.2.1: Enforce Advanced Network Sharing Settings
- **Description**: Default Windows configurations frequently leave Network Discovery, unauthenticated Public Folder sharing, and anonymous file sharing enabled. Hardening advanced sharing settings secures local interfaces against unauthenticated network probes.
- **Primary Method (Control Panel GUI)**:
  1. Open Control Panel (`Win + R` $\to$ `control` $\to$ Enter).
  2. Navigate to `Network and Internet` $\to$ `Network and Sharing Center`.
  3. In the left navigation pane, click **"Change advanced sharing settings"**.
  4. Expand **Guest or Public (current profile)**:
     - Select: **"Turn off network discovery"**.
     - Select: **"Turn off file and printer sharing"**.
  5. Expand **Private** (if active):
     - Select: **"Turn off network discovery"** (or turn on only if explicit printer sharing is required).
  6. Expand **All Networks**:
     - Under *Public folder sharing*: Select **"Turn off Public folder sharing"**.
     - Under *Password protected sharing*: Select **"Turn on password protected sharing"** (*CRITICAL*).
  7. Click **Save changes** at the bottom of the window.
- **Alternative Method (Native Command Prompt - Admin)**:
  ```cmd
  REM Disable Network Discovery firewall rules across all profiles
  netsh advfirewall firewall set rule group="Network Discovery" new enable=No

  REM Disable File and Printer Sharing firewall rules on Public profiles
  netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=No profile=public
  ```
- **Verification / Audit**:
  ```powershell
  Get-NetFirewallRule -DisplayGroup "Network Discovery" | Select-Object DisplayName, Profile, Enabled
  ```

---

### Improvement 1.2.2: Enforce Password Requirement on Wakeup
- **Description**: Prevents bypassing the Windows lock screen when waking a computer from sleep or standby, ensuring unauthorized physical walk-up access is blocked.
- **Primary Method (Control Panel GUI)**:
  1. Open Control Panel $\to$ `Hardware and Sound` $\to$ `Power Options`.
  2. In the left pane, click **"Require a password on wakeup"** (or click **"Choose what the power buttons do"**).
  3. Click the administrative link: **"Change settings that are currently unavailable"**.
  4. Under the *Password protection on wakeup* section, select the radio button: **"Require a password (recommended)"**.
  5. Click **Save changes**.
- **Alternative Method (Native Powercfg Utility - Admin)**:
  ```cmd
  REM Enforce password on AC power (plugged in) and DC power (battery)
  powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 1
  powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_NONE CONSOLELOCK 1
  powercfg /SETACTIVE SCHEME_CURRENT
  ```
- **Verification / Audit Command**:
  ```cmd
  powercfg /Q SCHEME_CURRENT SUB_NONE CONSOLELOCK
  ```
  *(Verify `Current AC Power Setting Index: 0x00000001` and `Current DC Power Setting Index: 0x00000001`)*.

---

### Improvement 1.2.3: Configure System Protection & Restore Points
- **Description**: System Protection takes volume shadow copies of core Windows system files, registry hives, and drivers. Establishing a clean restore point at the start of a round provides a rollback mechanism if administrative changes inadvertently break scoring services.
- **Primary Method (System Properties GUI)**:
  1. Press `Win + R` $\to$ Type `sysdm.cpl` $\to$ Press Enter.
  2. Navigate to the **System Protection** tab.
  3. Under *Protection Settings*, select system volume **`Local Disk (C:) (System)`** $\to$ Click **Configure...**.
  4. Select the radio button: **"Turn on system protection"**.
  5. Under *Disk Space Usage*, drag the slider to allocate between **5% and 10%** (approx. 5 GB to 10 GB) $\to$ Click **Apply** $\to$ Click **OK**.
  6. Back on the System Protection tab, click the **Create...** button.
  7. Enter a descriptive title (e.g., `CP Baseline Initial Clean`) $\to$ Click **Create**.
  8. Wait for the dialog stating: *"The restore point was created successfully."*
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  # Enable System Restore on C:
  Enable-ComputerRestore -Drive "C:\"
  # Set Shadow Storage allocation to 10%
  vssadmin resize shadowstorage /on=C: /for=C: /maxsize=10%
  # Create immediate baseline restore point
  Checkpoint-Computer -Description "CyberPatriot Baseline Clean" -RestorePointType "MODIFY_SETTINGS"
  ```
- **Verification / Audit Command**:
  ```powershell
  Get-ComputerRestorePoint
  ```

---

### Improvement 1.2.4: Internet Options Security Zones & Protocol Hardening
- **Description**: Legacy Windows system components, WinINet APIs, BITS, and desktop background tasks inherit proxy, TLS ciphers, and cache policies from the classic Internet Options control panel.
- **Primary Method (Internet Options GUI)**:
  1. Press `Win + R` $\to$ Type `inetcpl.cpl` $\to$ Press Enter.
  2. **Security Tab**:
     - Click **"Reset all zones to default level"**.
     - Click **Restricted sites** $\to$ Ensure Security level is set to **High**.
     - Verify **"Enable Protected Mode"** is checked.
  3. **Connections Tab**:
     - Click **LAN settings** $\to$ **Uncheck "Automatically detect settings"** (disables WPAD poisoning vulnerability).
     - Ensure no unauthorized proxy server checkbox is populated.
  4. **Advanced Tab**:
     - Scroll to the *Security* sub-section:
     - Check: **"Do not save encrypted pages to disk"**.
     - Check: **"Empty Temporary Internet Files folder when browser is closed"**.
     - Check: **"Warn about certificate address mismatch"**.
     - Check: **"Check for publisher's certificate revocation"** & **"Check for server certificate revocation"**.
     - Uncheck: **Use SSL 3.0**, **Use TLS 1.0**, **Use TLS 1.1**.
     - Check: **Use TLS 1.2**, **Use TLS 1.3** (if available).
  5. Click **Apply** $\to$ Click **OK**.
- **Verification / Audit**:
  - Re-open `inetcpl.cpl` and verify checkboxes under Security and Advanced tabs remain active.

---

## 1.3 Local Security Policy (`secpol.msc` & `gpedit.msc`)

### Improvement 1.3.1: Enforce Explicit Deny User Rights
- **Description**: Explicit `Deny` user rights take precedence over any `Allow` rights granted through group inheritance. Adding the built-in `Guest` account and anonymous callers to these policies ensures they cannot acquire local or remote execution tokens.
- **Primary Method (`secpol.msc` GUI)**:
  1. Press `Win + R` $\to$ Type `secpol.msc` $\to$ Press Enter.
  2. Navigate to `Security Settings` $\to$ `Local Policies` $\to$ `User Rights Assignment`.
  3. Configure the following four policies:
     - **Deny log on locally**: Double-click $\to$ Click **Add User or Group...** $\to$ Enter `Guest` $\to$ Click OK.
     - **Deny log on through Remote Desktop Services**: Double-click $\to$ Click **Add User or Group...** $\to$ Enter `Guest; ANONYMOUS LOGON` $\to$ Click OK.
     - **Deny log on as a batch job**: Double-click $\to$ Add `Guest` $\to$ Click OK.
     - **Deny log on as a service**: Double-click $\to$ Add `Guest` $\to$ Click OK.
  4. Click **Apply** and **OK** on each dialog.
- **Alternative Method (`secedit` CLI Tool - Admin)**:
  ```cmd
  REM Export current security database
  secedit /export /cfg C:\secpol_export.inf
  ```
  *Append or edit the following keys in `C:\secpol_export.inf` under `[Privilege Rights]`*:
  ```ini
  [Privilege Rights]
  SeDenyInteractiveLogonRight = *S-1-5-32-546
  SeDenyRemoteInteractiveLogonRight = *S-1-5-32-546,*S-1-5-7
  SeDenyBatchLogonRight = *S-1-5-32-546
  SeDenyServiceLogonRight = *S-1-5-32-546
  ```
  ```cmd
  REM Re-apply modified security template
  secedit /configure /db secedit.sdb /cfg C:\secpol_export.inf /areas USER_RIGHTS
  del C:\secpol_export.inf
  gpupdate /force
  ```
- **Verification / Audit**:
  - Open `secpol.msc` and verify that `Guest` and `ANONYMOUS LOGON` appear under the designated Deny policies.
- **Caveats**: **NEVER** add `Administrator`, `Authenticated Users`, or `Administrators` to any of the *Deny* policies, as this will immediately lock you out of the system.

---

### Improvement 1.3.2: Restrict High-Risk Administrative Privileges
- **Description**: Specific Windows user rights grant near-unrestricted control over kernel memory, system drivers, and audit infrastructure. Restricting these rights strictly to `Administrators` prevents privilege escalation and credential theft via LSASS memory dumping.
- **Primary Method (`secpol.msc` GUI)**:
  1. Open `secpol.msc` $\to$ `Local Policies` $\to$ `User Rights Assignment`.
  2. Inspect each of the following policies; remove any standard user accounts, developer accounts, or third-party service groups, retaining only the authorized entities listed:
     - **Debug programs (`SeDebugPrivilege`)**: Strictly `Administrators`. *(Critical: Prevents unauthorized tools from reading process memory)*.
     - **Take ownership of files or other objects (`SeTakeOwnershipPrivilege`)**: Strictly `Administrators`.
     - **Load and unload device drivers (`SeLoadDriverPrivilege`)**: Strictly `Administrators`.
     - **Create symbolic links (`SeCreateSymbolicLinkPrivilege`)**: Strictly `Administrators`.
     - **Impersonate a client after authentication (`SeImpersonatePrivilege`)**: Strictly `Administrators`, `LOCAL SERVICE`, `NETWORK SERVICE`, `SERVICE`.
     - **Manage auditing and security log (`SeSecurityPrivilege`)**: Strictly `Administrators`.
     - **Back up files and directories (`SeBackupPrivilege`)**: Strictly `Administrators`, `Backup Operators`.
  3. Click **Apply** $\to$ Click **OK**.
- **Verification / Audit Command**:
  ```cmd
  whoami /priv
  ```
- **Caveats**: Stripping `LOCAL SERVICE` or `NETWORK SERVICE` from `SeImpersonatePrivilege` can break core Windows RPC services and Print Spooler. Ensure only standard/unauthorized user accounts are removed.

---

### Improvement 1.3.3: Configure Machine Inactivity Screen Lockout Limit
- **Description**: Enforces an operating-system-level inactivity timer that automatically locks the workstation screen after a specified duration of idle time, mitigating physical walk-up exploitation.
- **Primary Method (`secpol.msc` GUI)**:
  1. Open `secpol.msc` $\to$ `Security Settings` $\to$ `Local Policies` $\to$ `Security Options`.
  2. Locate policy: **"Interactive logon: Machine inactivity limit"**.
  3. Double-click to open properties.
  4. Check the box: **"Define this policy setting"**.
  5. Enter: **`900`** seconds (15 minutes) or **`300`** seconds (5 minutes if specified).
  6. Click **Apply** $\to$ Click **OK**.
- **Verification / Audit**:
  - In `secpol.msc`, verify the policy displays `900 or fewer seconds`. Run `gpupdate /force` to ensure immediate application.

---

### Improvement 1.3.4: Block Microsoft Accounts & Anonymous Fallback
- **Description**: Windows 10 and 11 allow users to link consumer Microsoft accounts (Hotmail/Outlook) to local profiles. Blocking consumer cloud accounts prevents credential synchronization bypasses and keeps authentication local.
- **Primary Method (`secpol.msc` GUI)**:
  1. Open `secpol.msc` $\to$ `Local Policies` $\to$ `Security Options`.
  2. Locate: **"Accounts: Block Microsoft accounts"**:
     - Double-click $\to$ Select: **"Users cannot add or log on with Microsoft accounts"** $\to$ Click OK.
  3. Locate: **"Network security: Allow LocalSystem NULL session fallback"**:
     - Double-click $\to$ Select: **Disabled** $\to$ Click OK.
  4. Locate: **"Network security: Allow PKU2U authentication requests to this computer to use online identities"**:
     - Double-click $\to$ Select: **Disabled** $\to$ Click OK.
  5. Run `gpupdate /force` in command prompt.
- **Verification / Audit**:
  - Open `secpol.msc` $\to$ `Security Options` and confirm all three policies display their hardened states.

---

## 1.4 Local Users and Groups (`lusrmgr.msc`)

### Improvement 1.4.1: Audit and Disable Built-in System Utility Accounts
- **Description**: Windows creates internal utility accounts (`DefaultAccount`, `WDAGUtilityAccount`) that should remain disabled when not in active service. Attackers often activate these accounts, reset their passwords, and add them to privileged groups to maintain stealth persistence.
- **Primary Method (`lusrmgr.msc` GUI)**:
  1. Press `Win + R` $\to$ Type `lusrmgr.msc` $\to$ Press Enter.
  2. Click **Users** in the left navigation tree.
  3. Right-click **`DefaultAccount`** $\to$ Click **Properties**.
     - Ensure the checkbox is checked: **"Account is disabled"**.
     - Click **Apply** $\to$ Click **OK**.
  4. Right-click **`WDAGUtilityAccount`** (Windows Defender Application Guard) $\to$ Click **Properties**.
     - If Application Guard is not in use, ensure **"Account is disabled"** is checked.
     - Click **Apply** $\to$ Click **OK**.
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  # Disable DefaultAccount and WDAGUtilityAccount
  Disable-LocalUser -Name "DefaultAccount" -ErrorAction SilentlyContinue
  Disable-LocalUser -Name "WDAGUtilityAccount" -ErrorAction SilentlyContinue
  ```
- **Verification / Audit Command**:
  ```powershell
  Get-LocalUser -Name "DefaultAccount", "WDAGUtilityAccount" | Select-Object Name, Enabled
  ```
  *(Both should return `Enabled: False`)*.

---

### Improvement 1.4.2: Audit Sensitive Auxiliary Local Groups
- **Description**: Attackers frequently grant standard user accounts membership in specialized non-Administrator groups to gain remote execution, reconnaissance, or log-clearing rights without raising alarms in the `Administrators` group.
- **Primary Method (`lusrmgr.msc` GUI)**:
  1. Open `lusrmgr.msc` $\to$ Click **Groups**.
  2. Inspect each of the following groups:
     - **Remote Management Users**: Remove all members unless explicitly authorized for WinRM management in the README.
     - **Distributed COM Users**: Remove any standard user accounts.
     - **Event Log Readers**: Ensure unauthorized users cannot read security logs.
     - **Performance Log Users** & **Performance Monitor Users**: Remove unauthorized users.
     - **Cryptographic Operators**: Ensure unauthorized users cannot access crypto providers.
  3. To remove an unauthorized member: Double-click the group $\to$ Select the user $\to$ Click **Remove** $\to$ Click **Apply** $\to$ Click **OK**.
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  # Audit members of sensitive auxiliary groups
  $groups = @("Remote Management Users", "Distributed COM Users", "Event Log Readers", "Performance Log Users", "Cryptographic Operators")
  foreach ($grp in $groups) {
      Write-Host "=== Members of $grp ===" -ForegroundColor Cyan
      Get-LocalGroupMember -Group $grp -ErrorAction SilentlyContinue | Select-Object Name, PrincipalSource
  }
  # Remove rogue member:
  # Remove-LocalGroupMember -Group "Remote Management Users" -Member "<UnauthorizedUser>"
  ```

---

### Improvement 1.4.3: Automated Local User Account Security Audit via PowerShell
- **Description**: Quickly inspects all local user accounts in the SAM database to identify unauthorized accounts, accounts with passwords set to never expire, accounts with blank passwords, or dormant accounts.
- **PowerShell (Admin) Command**:
  ```powershell
  Get-LocalUser | Select-Object Name, Enabled, PasswordRequired, PasswordLastSet, PasswordNeverExpires, UserMayChangePassword, LastLogon, Description | Sort-Object Enabled -Descending | Format-Table -AutoSize
  ```
- **Remediation Script (PowerShell)**:
  ```powershell
  # Force all local users to require passwords and enforce expiration
  Get-LocalUser | Where-Object { $_.Name -ne "DefaultAccount" -and $_.Name -ne "WDAGUtilityAccount" } | ForEach-Object {
      Set-LocalUser -Name $_.Name -PasswordNeverExpires $false
  }
  ```

---

## 1.5 Computer Management (`compmgnt.msc`)

### Improvement 1.5.1: Device Manager Hidden Device Audit
- **Description**: Adversaries often leave virtual network interfaces (e.g., OpenVPN TAP/TUN adapters, Hamachi adapters) or malicious USB hardware emulators installed to bypass physical and host firewall controls.
- **Primary Method (Device Manager GUI)**:
  1. Press `Win + R` $\to$ Type `devmgmt.msc` $\to$ Press Enter (or access via `compmgnt.msc` $\to$ `Device Manager`).
  2. Click the **View** menu at the top $\to$ Check **"Show hidden devices"**.
  3. Expand **Network adapters**:
     - Look for unauthorized virtual adapters: `TAP-Windows Adapter`, `TeamViewer VPN Adapter`, `LogMeIn Hamachi Virtual Ethernet Adapter`, `OpenVPN Data Channel Offload`.
     - Right-click rogue adapter $\to$ Click **Uninstall device** $\to$ Check *"Delete the driver software for this device"* $\to$ Click **Uninstall**.
  4. Expand **Ports (COM & LPT)** and **Universal Serial Bus controllers**:
     - Check for unauthorized serial communication bridges or USB storage dongles.
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  # List all network adapters including virtual and hidden devices
  Get-NetAdapter -IncludeHidden | Select-Object Name, InterfaceDescription, Status, MacAddress | Format-Table -AutoSize
  # Disable rogue network adapter
  Disable-NetAdapter -Name "<RogueAdapterName>" -Confirm:$false
  ```

---

### Improvement 1.5.2: Security Event Log Threat Hunting (Critical Event IDs)
- **Description**: Event Viewer contains high-fidelity telemetry revealing active intrusions, recently installed persistence services, and unauthorized brute-force attempts.
- **Primary Method (Event Viewer GUI)**:
  1. Press `Win + R` $\to$ Type `eventvwr.msc` $\to$ Navigate to `Windows Logs` $\to$ `Security`.
  2. In the right Action pane, click **Filter Current Log...**.
  3. In the `<All Event IDs>` box, enter the following comma-separated list:
     `4624, 4625, 4720, 4726, 4728, 4732, 4697, 7045, 1102`
  4. Click **OK**.
- **Event ID Quick Reference**:
  - **4624 (Logon)**: Look for **Logon Type 3** (Network) or **Logon Type 10** (RDP).
  - **4625 (Failed Logon)**: Pinpoints active brute-force attacks.
  - **4720 / 4726**: User Account Created / Deleted.
  - **4728 / 4732**: Member Added to Administrators.
  - **7045 / 4697**: New Service Installed.
  - **1102**: Audit Log Cleared.
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  # Query the last 20 service installations:
  Get-WinEvent -FilterHashtable @{LogName='System'; Id=7045} -MaxEvents 20 -ErrorAction SilentlyContinue | Select-Object TimeCreated, @{Name="ServiceName";Expression={$_.Properties[0].Value}}, @{Name="ImagePath";Expression={$_.Properties[1].Value}} | Format-Table -AutoSize
  ```

---

### Improvement 1.5.3: Integrated Share Management via Computer Management
- **Description**: Provides unified visibility into active shares, remote sessions, and open file locks directly within the Computer Management snap-in.
- **Primary Method (`compmgnt.msc` GUI)**:
  1. Open `compmgnt.msc` $\to$ Navigate to `System Tools` $\to$ `Shared Folders`.
  2. Click **Shares**:
     - Right-click any non-default share $\to$ Click **Stop Sharing**.
  3. Click **Sessions**:
     - Right-click unauthorized remote session $\to$ Click **Close Session**.
  4. Click **Open Files**:
     - Inspect files currently locked over the network by remote machines.

---

## 1.6 Windows Security & Threat Protection

### Improvement 1.6.1: Enforce Tamper Protection
- **Description**: Tamper Protection prevents malicious apps and unauthorized PowerShell scripts from altering security settings, disabling real-time scanning, turning off cloud protection, or adding scan exclusions.
- **Primary Method (Windows Security GUI)**:
  1. Open **Windows Security** (`Win + S` $\to$ `Windows Security`).
  2. Click **Virus & threat protection**.
  3. Under *Virus & threat protection settings*, click **Manage settings**.
  4. Scroll down to locate **Tamper Protection**.
  5. Ensure the toggle switch is set to **On**.
- **Verification / Audit Command**:
  ```powershell
  Get-MpComputerStatus | Select-Object IsTamperProtected, RealTimeProtectionEnabled
  ```
  *(Must show `IsTamperProtected: True`)*.

---

### Improvement 1.6.2: Enable Controlled Folder Access (Ransomware Protection)
- **Description**: Controlled Folder Access locks standard user directories against modification by untrusted binaries, stopping ransomware and wipers from destroying user files.
- **Primary Method (Windows Security GUI)**:
  1. In **Windows Security**, click **Virus & threat protection**.
  2. Scroll down to the bottom and click **Manage ransomware protection**.
  3. Toggle **Controlled folder access** to **On**.
  4. Click **Protected folders** to verify `Documents`, `Pictures`, `Videos`, `Music`, and `Desktop` are listed.
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  Set-MpPreference -EnableControlledFolderAccess Enabled
  ```
- **Verification / Audit Command**:
  ```powershell
  (Get-MpPreference).EnableControlledFolderAccess
  ```

---

### Improvement 1.6.3: System-Wide Exploit Protection (DEP, ASLR, SEHOP)
- **Description**: Exploit Protection applies system-level mitigations against common exploitation techniques including buffer overflows, return-oriented programming (ROP), and heap corruption.
- **Primary Method (Windows Security GUI)**:
  1. In **Windows Security**, click **App & browser control**.
  2. Under *Exploit protection*, click **Exploit protection settings**.
  3. Under the **System settings** tab, verify and configure each mitigation:
     - **Control Flow Guard (CFG)**: **On by default**.
     - **Data Execution Prevention (DEP)**: **On by default (Always On)**.
     - **Force randomization for images (Mandatory ASLR)**: **On by default**.
     - **Randomize memory allocations (Bottom-up ASLR)**: **On by default**.
     - **High-entropy ASLR**: **On by default**.
     - **Validate exception chains (SEHOP)**: **On by default**.
     - **Validate heap integrity**: **On by default**.
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  # Enforce DEP system-wide (AlwaysOn)
  Set-ProcessMitigation -System -Enable DEP
  # Enforce Mandatory ASLR system-wide
  Set-ProcessMitigation -System -Enable BottomUp,ForceRelocateImages
  # Enforce SEHOP system-wide
  Set-ProcessMitigation -System -Enable SEHOP
  ```
- **Verification / Audit Command**:
  ```powershell
  Get-ProcessMitigation -System
  ```

---

### Improvement 1.6.4: Enable Potentially Unwanted Application (PUA) Protection
- **Description**: PUA protection identifies and blocks adware, torrent downloaders, cryptominers, and deceptive bundled software before they execute.
- **Primary Method (PowerShell - Admin)**:
  ```powershell
  Set-MpPreference -PUAProtection Enabled
  ```
- **Alternative Method (Group Policy GUI)**:
  1. Open `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Windows Components` $\to$ `Microsoft Defender Antivirus`.
  2. Double-click **"Configure detection for potentially unwanted applications"**.
  3. Select **Enabled** $\to$ Under Options, select **Block** $\to$ Click OK.
- **Verification / Audit Command**:
  ```powershell
  (Get-MpPreference).PUAProtection
  ```

---

### Improvement 1.6.5: Enable Network Protection for Defender
- **Description**: Network Protection extends SmartScreen reputation checks to all outbound network traffic from any desktop application, blocking connection attempts to malicious command-and-control (C2) domains and phishing IP addresses.
- **Primary Method (PowerShell - Admin)**:
  ```powershell
  Set-MpPreference -EnableNetworkProtection Enabled
  ```
- **Alternative Method (Group Policy GUI)**:
  1. Open `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Windows Components` $\to$ `Microsoft Defender Antivirus` $\to$ `Windows Defender Exploit Guard` $\to$ `Network Protection`.
  2. Double-click **"Prevent users and apps from accessing dangerous websites"**.
  3. Select **Enabled** $\to$ Under Options, select **Block** $\to$ Click OK.
- **Verification / Audit Command**:
  ```powershell
  (Get-MpPreference).EnableNetworkProtection
  ```

---

## 1.7 Task Manager

### Improvement 1.7.1: Expose Image Path Name and Command Line Columns
- **Primary Method (Task Manager GUI)**:
  1. Open Task Manager (`Ctrl + Shift + Esc`).
  2. Click **More details** at the bottom if running in compact mode.
  3. Navigate to the **Details** tab.
  4. Right-click any column header (e.g., `Name`, `PID`, `Status`) $\to$ Click **Select columns**.
  5. Check **Image path name** and **Command line** $\to$ Click **OK**.
  6. Audit paths: Any critical system process (`svchost.exe`, `lsass.exe`, `csrss.exe`) not originating from `C:\Windows\System32\` is malicious.

---

### Improvement 1.7.2: Services Tab Triage in Task Manager
- **Primary Method (Task Manager GUI)**:
  1. In Task Manager, click the **Services** tab.
  2. Click the **Status** column header to sort all services so that `Running` services appear at the top.
  3. Scan the *Description* and *Group* columns for unverified third-party services.
  4. Right-click suspicious service $\to$ Click **Stop**.
  5. Click **Open Services** at the bottom of the tab to jump to `services.msc` and set the Startup type to **Disabled**.

---

### Improvement 1.7.3: Users Tab Disconnected Session Termination
- **Primary Method (Task Manager GUI)**:
  1. In Task Manager, click the **Users** tab.
  2. Review the list of active sessions.
  3. If an unauthorized user or disconnected ghost session is visible:
     - Right-click the user $\to$ Click **Sign off** (or **Disconnect**).

---

## 1.8 Task Scheduler (`taskschd.msc`)

### Improvement 1.8.1: Deep Inspection of Task Triggers & Privileges
- **Primary Method (`taskschd.msc` GUI)**:
  1. Press `Win + R` $\to$ Type `taskschd.msc` $\to$ Press Enter.
  2. Expand `Task Scheduler Library` in the left tree.
  3. Click each task and review the lower center panes:
     - **Triggers Tab**: Inspect triggers set to *"At log on of any user"* or *"At startup"*.
     - **Actions Tab**: Inspect the binary executed. Look for `cmd.exe /c`, `powershell.exe -enc`, `wscript.exe`, or scripts in `AppData\Local\Temp`.
     - **General Tab**: Check if **"Run with highest privileges"** or **"Hidden"** is enabled on unknown tasks.
  4. Right-click unauthorized task $\to$ Click **Disable** or **Delete**.

---

### Improvement 1.8.2: PowerShell Non-Microsoft Scheduled Tasks Query
- **PowerShell (Admin) Command**:
  ```powershell
  # Filter out all standard built-in Microsoft tasks to isolate third-party and suspicious tasks
  Get-ScheduledTask | Where-Object { $_.TaskPath -notlike "\Microsoft*" -and $_.TaskPath -notlike "\Apple*" } | Select-Object TaskName, TaskPath, State, @{Name="Execute";Expression={$_.Actions.Execute}}, @{Name="Arguments";Expression={$_.Actions.Arguments}} | Format-Table -AutoSize
  ```
- **Remediation**:
  ```powershell
  Unregister-ScheduledTask -TaskName "<SuspiciousTaskName>" -Confirm:$false
  ```

---

### Improvement 1.8.3: Inspect WMI Event Subscription Persistence
- **Description**: WMI event subscriptions provide fileless persistence that triggers payload execution when specific events occur without creating a scheduled task.
- **PowerShell (Admin) Audit**:
  ```powershell
  Write-Host "=== WMI Event Filters ===" -ForegroundColor Yellow
  Get-CimInstance -Namespace root\subscription -ClassName __EventFilter | Select-Object Name, Query
  Write-Host "=== WMI Command Line Consumers ===" -ForegroundColor Yellow
  Get-CimInstance -Namespace root\subscription -ClassName CommandLineEventConsumer | Select-Object Name, CommandLineTemplate, ExecutablePath
  Write-Host "=== WMI Filter To Consumer Bindings ===" -ForegroundColor Yellow
  Get-CimInstance -Namespace root\subscription -ClassName __FilterToConsumerBinding | Select-Object Filter, Consumer
  ```
- **Remediation Script**:
  ```powershell
  # Remove rogue WMI Consumers and Filters
  Get-CimInstance -Namespace root\subscription -ClassName CommandLineEventConsumer | Where-Object { $_.Name -like "*malicious*" -or $_.CommandLineTemplate -like "*powershell*" } | Remove-CimInstance
  Get-CimInstance -Namespace root\subscription -ClassName __EventFilter | Where-Object { $_.Name -like "*malicious*" } | Remove-CimInstance
  ```

---

## 1.9 Registry Editor (Exclusive Configurations: `regedit.exe`)

> [!NOTE]
> The configurations in this section **do not possess graphical interface alternatives or native management cmdlets** in standalone Windows environments. They must be configured directly via `regedit.exe`.

### Improvement 1.9.1: Enforce Safe DLL Search Mode
- **Description**: Forces Windows to search system directories before searching the current working directory, stopping DLL preloading and search-order hijacking attacks.
- **Registry Key**: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager`
- **Value Name**: `SafeDllSearchMode`
- **Type**: `REG_DWORD`
- **Data**: `1`
- **Verification / Audit Command**:
  ```powershell
  (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager").SafeDllSearchMode
  ```

---

### Improvement 1.9.2: Validate Winlogon Shell & Userinit Integrity
- **Description**: Attackers append secondary payloads to the Winlogon `Userinit` or `Shell` registry values so they execute whenever a user logs on.
- **Registry Key**: `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon`
- **Audited Values**:
  - `Shell`: Must be strictly `explorer.exe` (REG_SZ).
  - `Userinit`: Must be strictly `C:\Windows\system32\userinit.exe,` (REG_SZ - trailing comma mandatory).
- **Verification / Audit Command**:
  ```powershell
  Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" | Select-Object Shell, Userinit
  ```

---

### Improvement 1.9.3: Clean Run and RunOnce Startup Registry Hives
- **Registry Paths to Inspect**:
  - `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run` and `RunOnce`
  - `HKCU\Software\Microsoft\Windows\CurrentVersion\Run` and `RunOnce`
  - `HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run` and `RunOnce`
- **Audit Action**: Open `regedit.exe`, navigate to each path, and delete values pointing to unauthorized binaries, reverse shells, or suspicious batch files.

---

### Improvement 1.9.4: Clean AppInit_DLLs Injection Registry Keys
- **Description**: The `AppInit_DLLs` registry infrastructure causes every user-mode process loading `user32.dll` to silently load specified DLLs into its address space.
- **Registry Key**: `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows`
- **Audited Values**:
  - `AppInit_DLLs`: Must be completely **blank**.
  - `LoadAppInit_DLLs`: Must be `0` (REG_DWORD).
- **Verification / Audit Command**:
  ```powershell
  Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" -Name AppInit_DLLs, LoadAppInit_DLLs
  ```

---

## 1.10 Command Prompt & PowerShell Security Commands

### Improvement 1.10.1: Enforce PowerShell Execution Policy
- **PowerShell (Admin) Command**:
  ```powershell
  # Check current execution policy across scopes
  Get-ExecutionPolicy -List
  # Enforce RemoteSigned policy system-wide
  Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
  ```

---

### Improvement 1.10.2: Operating System File Integrity Repair (SFC & DISM)
- **Command Line (Admin)**:
  ```cmd
  REM Scan and repair corrupted Windows system files
  sfc /scannow

  REM Restore component store health
  DISM /Online /Cleanup-Image /RestoreHealth
  ```

---

### Improvement 1.10.3: DNS Cache Forensics and Cleansing
- **Command Line (Admin)**:
  ```cmd
  REM Display recently resolved domains to trace malicious C2 lookups
  ipconfig /displaydns | more

  REM Flush cached DNS entries
  ipconfig /flushdns
  ```

---

### Improvement 1.10.4: Map Listening Ports to Owning Process Names
- **PowerShell (Admin) Command**:
  ```powershell
  Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort, OwningProcess, @{Name="ProcessName";Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}}, @{Name="Path";Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).Path}} | Sort-Object LocalPort | Format-Table -AutoSize
  ```

---

### Improvement 1.10.5: Query SMB Shares and Sessions via PowerShell
- **PowerShell (Admin) Command**:
  ```powershell
  # View all SMB shares
  Get-SmbShare | Format-Table -AutoSize
  # View active remote authenticated sessions
  Get-SmbSession | Format-Table -AutoSize
  # View files currently opened by remote clients
  Get-SmbOpenFile | Format-Table -AutoSize
  ```

---

## 1.11 File System, Drive Security & Prohibited Media Files

### Improvement 1.11.1: Hunt and Remove NTFS Alternate Data Streams (ADS)
- **Primary Method (Native Command Prompt - Admin)**:
  ```cmd
  REM Search user profile directories for Alternate Data Streams
  dir /R C:\Users\
  ```
- **PowerShell Alternative**:
  ```powershell
  Get-ChildItem -Path C:\Users -Recurse -ErrorAction SilentlyContinue | Get-Item -Stream * -ErrorAction SilentlyContinue | Where-Object { $_.Stream -ne ':$DATA' } | Select-Object PSPath, Stream, Length | Format-Table -AutoSize
  ```

---

### Improvement 1.11.2: Audit Unattended Setup & Sysprep Passwords
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

---

### Improvement 1.11.3: Verify Accessibility Binaries Against Sticky Keys Backdoors
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

# Part 2: Features, Applications, Services, and Servers

---

## 2.1 Server Roles & Windows Features Framework

### Improvement 2.1.1: Audit and Disable WSL and Windows Sandbox
- **Primary Method (Windows Features GUI)**:
  1. Open Control Panel $\to$ `Programs` $\to$ `Turn Windows features on or off`.
  2. Scroll down and uncheck:
     - **Windows Subsystem for Linux**
     - **Windows Sandbox**
     - **Virtual Machine Platform** (unless required by Credential Guard)
  3. Click **OK** $\to$ Reboot when prompted if requested.
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  # Disable WSL feature
  Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
  # Disable Windows Sandbox
  Disable-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM" -NoRestart
  ```

---

### Improvement 2.1.2: Scripted Feature Auditing via PowerShell
- **PowerShell (Admin) Command**:
  ```powershell
  # List all currently enabled optional features
  Get-WindowsOptionalFeature -Online | Where-Object State -eq "Enabled" | Select-Object FeatureName | Sort-Object FeatureName
  ```

---

## 2.2 SMB & Windows File Sharing

### Improvement 2.2.1: Enforce SMBv3 Encryption
- **Primary Method (PowerShell SMB Module - Admin)**:
  ```powershell
  # Enforce SMB encryption globally across all shares:
  Set-SmbServerConfiguration -EncryptData $true -Force
  # Reject unencrypted client connections:
  Set-SmbServerConfiguration -RejectUnencryptedAccess $true -Force
  ```
- **Verification / Audit Command**:
  ```powershell
  Get-SmbServerConfiguration | Select-Object EncryptData, RejectUnencryptedAccess
  ```

---

### Improvement 2.2.2: Mitigate SMBGhost (CVE-2020-0796) Compression Vulnerability
- **Description**: Disables SMBv3 compression to block remote pre-authentication code execution on unpatched Windows 10 versions 1903/1909 and Server 2019. *(Note: Microsoft provides no GUI or cmdlet alternative for disabling SMB compression; it requires setting `DisableCompression`)*.
- **Registry Key**: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters`
- **Value Name**: `DisableCompression`
- **Type**: `REG_DWORD`
- **Data**: `1`
- **Verification / Audit Command**:
  ```powershell
  (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters").DisableCompression
  ```

---

### Improvement 2.2.3: Restrict SMB Ports on External / Public Interfaces
- **Primary Method (Windows Defender Firewall GUI)**:
  1. Open `wf.msc` (Windows Defender Firewall with Advanced Security).
  2. Click **Inbound Rules** in the left tree.
  3. Filter or locate rules named **File and Printer Sharing (SMB-In)**.
  4. Double-click the rule $\to$ Navigate to the **Advanced** tab:
     - Uncheck **Public** (ensure rule only applies to Private or Domain profiles).
  5. Click **Apply** $\to$ Click **OK**.

---

## 2.3 Remote Desktop Services (RDP)

### Improvement 2.3.1: Enable Restricted Administration Mode for RDP
- **Description**: Prevents reusable credentials (pass-the-hash or plaintext passwords) from being stored in memory on the target remote server during RDP sessions.
- **Primary Method (Group Policy GUI)**:
  1. Open `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `System` $\to$ `Credentials Delegation`.
  2. Double-click policy: **"Restrict delegation of credentials to remote servers"**.
  3. Select **Enabled** $\to$ From the dropdown select **"Require Restricted Admin"**.
  4. Click **Apply** $\to$ Click **OK**.
- **Verification / Audit**:
  - In `gpedit.msc`, confirm the policy status displays **Enabled**.

---

### Improvement 2.3.2: Configure Custom RDP Port (When Required)
- **Description**: Relocates the RDP listening socket away from default port 3389 when specified by competition instructions. *(Note: Windows provides no GUI to modify the listening port; it must be modified in the Terminal Server registry hive)*.
- **Registry Key**: `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp`
- **Value Name**: `PortNumber`
- **Type**: `REG_DWORD`
- **Data**: Decimal port number (e.g., `3390`).
- **Firewall Rule Creation via PowerShell (Admin)**:
  ```powershell
  New-NetFirewallRule -DisplayName "RDP-Custom-3390" -Direction Inbound -Protocol TCP -LocalPort 3390 -Action Allow
  ```

---

### Improvement 2.3.3: Restrict Drive and Device Redirection over RDP
- **Primary Method (Group Policy GUI)**:
  1. Open `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Windows Components` $\to$ `Remote Desktop Services` $\to$ `Remote Desktop Session Host` $\to$ `Device and Resource Redirection`.
  2. Double-click and enable each of the following policies:
     - **Do not allow drive redirection**: **Enabled**.
     - **Do not allow COM port redirection**: **Enabled**.
     - **Do not allow LPT port redirection**: **Enabled**.
  3. Click **Apply** $\to$ Click **OK**.

---

## 2.4 Web Browsers (Chrome, Firefox, Internet Explorer, Edge)

### Improvement 2.4.1: Google Chrome In-Browser Security Hardening
- **Primary Method (Chrome Browser GUI)**:
  1. Launch Google Chrome.
  2. **Safe Browsing**: Navigate to `chrome://settings/security` $\to$ Select the radio button: **"Enhanced protection"**.
  3. **Third-Party Cookies**: Navigate to `chrome://settings/cookies` $\to$ Select: **"Block third-party cookies"**.
  4. **Password Manager**: Navigate to `chrome://password-manager/settings` $\to$ Toggle **"Offer to save passwords"** to **Off**.
  5. **Popups & Redirects**: Navigate to `chrome://settings/content/popups` $\to$ Ensure **"Don't allow sites to send pop-ups or use redirects"** is selected.

---

### Improvement 2.4.2: Microsoft Edge In-Browser Security Hardening
- **Primary Method (Edge Browser GUI)**:
  1. Launch Microsoft Edge.
  2. **SmartScreen**: Navigate to `edge://settings/privacy` $\to$ Scroll down to the *Security* section:
     - Toggle **"Microsoft Defender SmartScreen"** to **On**.
     - Toggle **"Block potentially unwanted apps"** to **On**.
  3. **Password Manager**: Navigate to `edge://settings/passwords` $\to$ Toggle **"Offer to save passwords"** to **Off**.

---

### Improvement 2.4.3: Audit and Remove Unapproved Browsers
- **Primary Method (Control Panel / Settings GUI)**:
  1. Open `Control Panel` $\to$ `Programs and Features`.
  2. Scan for and **Uninstall** unauthorized browsers: `Tor Browser`, `Brave`, `Opera`, `Vivaldi`, `UC Browser`.
- **Alternative Method (PowerShell - Admin)**:
  ```powershell
  $unapproved = @("Tor Browser", "Brave", "Opera", "Vivaldi", "UCBrowser")
  Get-Package | Where-Object { $unapproved -contains $_.Name } | Uninstall-Package
  ```

---

## 2.5 Web Servers (IIS, Apache, Abyss Web Server)

### Improvement 2.5.1: IIS Request Filtering and Security Response Headers
- **Primary Method (IIS Manager GUI - `inetmgr`)**:
  1. Open IIS Manager (`Win + R` $\to$ `inetmgr` $\to$ Enter).
  2. Select the target website $\to$ Double-click **Request Filtering**:
     - Click **HTTP Verbs** tab in center pane $\to$ In right Action pane, click **Deny Verb...** $\to$ Enter `TRACE` $\to$ Click OK. Repeat for `TRACK` and `DEBUG`.
     - Click **File Name Extensions** tab $\to$ In right Action pane, click **Deny File Name Extension...** $\to$ Add `.bak`, `.inc`, `.old`, `.sql`, `.config`.
  3. Select the target website $\to$ Double-click **HTTP Response Headers**:
     - Click **Add...** $\to$ Name: `X-Frame-Options`, Value: `SAMEORIGIN`.
     - Click **Add...** $\to$ Name: `X-Content-Type-Options`, Value: `nosniff`.
     - Click **Add...** $\to$ Name: `Strict-Transport-Security`, Value: `max-age=31536000; includeSubDomains`.

---

### Improvement 2.5.2: Apache `.htaccess` Override Restrictions & Slowloris Mitigation
- **Primary Method (Apache Configuration File - `httpd.conf`)**:
  1. Open `C:\Apache24\conf\httpd.conf` in an administrative text editor.
  2. Locate the `<Directory "C:/Apache24/htdocs">` block and configure:
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
  3. Save the file and restart the Apache service:
     ```cmd
     net stop Apache2.4 && net start Apache2.4
     ```

---

## 2.6 Database Servers (Microsoft SQL Server & MariaDB / MySQL)

### Improvement 2.6.1: SQL Server Surface Area Reduction
- **Primary Method (Services Console & SSMS)**:
  1. Open `services.msc` $\to$ Double-click **SQL Server Browser** (`SQLBrowser`) $\to$ Click **Stop** $\to$ Set **Startup type** to **Disabled**.
  2. Open SQL Server Management Studio (SSMS) $\to$ Connect to Database Engine $\to$ Execute query:
     ```sql
     EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
     EXEC sp_configure 'clr enabled', 0; RECONFIGURE;
     EXEC sp_configure 'Ole Automation Procedures', 0; RECONFIGURE;
     EXEC sp_configure 'remote access', 0; RECONFIGURE;
     EXEC sp_configure 'Database Mail XPs', 0; RECONFIGURE;
     ```

---

### Improvement 2.6.2: MariaDB / MySQL Configuration Hardening (`my.ini`)
- **Primary Method (MariaDB Configuration File - `my.ini`)**:
  1. Open `C:\MariaDB\data\my.ini` (or `C:\Program Files\MariaDB...\my.ini`).
  2. Under the `[mysqld]` section header, add:
     ```ini
     [mysqld]
     local_infile = 0
     skip-symbolic-links
     bind-address = 127.0.0.1
     ```
  3. Save the file and restart MariaDB via `services.msc`.

---

## 2.7 Remote Administration & Management (WinRM, PowerShell Remoting, Remote Registry)

### Improvement 2.7.1: Disable WinRM Basic Auth & Unencrypted Traffic
- **Primary Method (Native WinRM CLI - Admin)**:
  ```cmd
  winrm set winrm/config/service/auth @{Basic="false"}
  winrm set winrm/config/client/auth @{Basic="false"}
  winrm set winrm/config/service @{AllowUnencrypted="false"}
  winrm set winrm/config/client @{AllowUnencrypted="false"}
  ```

---

### Improvement 2.7.2: Verify WinRM TrustedHosts is Not Wildcard
- **Primary Method (PowerShell WSMan Provider - Admin)**:
  ```powershell
  # Check current TrustedHosts value:
  Get-Item WSMan:\localhost\Client\TrustedHosts
  # Clear wildcard TrustedHosts:
  Set-Item WSMan:\localhost\Client\TrustedHosts -Value "" -Force
  ```

---

## 2.8 Email & Messaging Servers (SMTP)

### Improvement 2.8.1: Enforce SMTP Relay Restrictions
- **Primary Method (IIS 6.0 Manager GUI)**:
  1. Open IIS 6.0 Manager.
  2. Right-click `[SMTP Virtual Server]` $\to$ Select `Properties` $\to$ Navigate to `Access` tab.
  3. Click **Relay...** $\to$ Select the radio button: **"Only the list below"**.
  4. Ensure the list contains only `127.0.0.1` (or is empty).
  5. Uncheck: *"Allow all computers which successfully authenticate to relay"*.
  6. Click **OK** $\to$ Click **Apply**.

---

### Improvement 2.8.2: Disable SMTP User Enumeration (VRFY & EXPN)
- **Primary Method (IIS 6.0 Manager GUI)**:
  1. In SMTP Virtual Server Properties, navigate to the **Delivery** or **Advanced** tab.
  2. Turn off support for `VRFY` and `EXPN` queries to prevent remote user account harvesting.

---

## 2.9 Network Services & Legacy Protocols

### Improvement 2.9.1: Disable Xbox and Gaming Background Services (Win 10/11)
- **Primary Method (Services Console - `services.msc`)**:
  1. Press `Win + R` $\to$ Type `services.msc` $\to$ Press Enter.
  2. Locate each of the following four services, double-click $\to$ Click **Stop** $\to$ Set **Startup type** to **Disabled**:
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

---

### Improvement 2.9.2: Disable Bluetooth Support Service
- **Primary Method (Services Console - `services.msc`)**:
  1. Open `services.msc` $\to$ Locate **Bluetooth Support Service** (`bthserv`).
  2. Click **Stop** $\to$ Set **Startup type** to **Disabled**.

---

### Improvement 2.9.3: Disable Downloaded Maps Manager
- **Primary Method (Services Console - `services.msc`)**:
  1. Open `services.msc` $\to$ Locate **Downloaded Maps Manager** (`MapsBroker`).
  2. Click **Stop** $\to$ Set **Startup type** to **Disabled**.

---

### Improvement 2.9.4: Disable Remote Desktop Services UserMode Port Redirector
- **Primary Method (Services Console - `services.msc`)**:
  1. Open `services.msc` $\to$ Locate **Remote Desktop Services UserMode Port Redirector** (`UmRdpService`).
  2. Click **Stop** $\to$ Set **Startup type** to **Disabled**.

---

## 2.10 Network Stack & Name Resolution

### Improvement 2.10.1: Disable WinHTTP Web Proxy Auto-Discovery Service
- **Primary Method (Services Console - `services.msc`)**:
  1. Open `services.msc` $\to$ Locate **WinHTTP Web Proxy Auto-Discovery Service** (`WinHttpAutoProxySvc`).
  2. Click **Stop** $\to$ Set **Startup type** to **Disabled**.

---

### Improvement 2.10.2: Disable Multicast DNS (mDNS)
- **Primary Method (Group Policy GUI)**:
  1. Open `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Network` $\to$ `DNS Client`.
  2. Locate policy: **"Turn off multicast name resolution"**.
  3. Double-click $\to$ Select **Enabled** (this turns off both LLMNR and mDNS broadcast queries).
  4. Click **Apply** $\to$ Click **OK**.

---

## 2.11 Active Directory Domain Services & GPMC (Domain Controllers)

### Improvement 2.11.1: Protect Against AS-REP Roasting
- **Primary Method (PowerShell ActiveDirectory Module - Admin on DC)**:
  ```powershell
  # Find accounts vulnerable to AS-REP Roasting:
  Get-ADUser -Filter {DoesNotRequirePreAuth -eq $true} | Select-Object SamAccountName
  # Enforce Kerberos preauthentication:
  Get-ADUser -Filter {DoesNotRequirePreAuth -eq $true} | Set-ADAccountControl -DoesNotRequirePreAuth $false
  ```
- **Alternative Method (`dsa.msc` GUI)**:
  1. Open `dsa.msc` $\to$ Double-click user $\to$ Navigate to **Account** tab.
  2. Under *Account options*, scroll and ensure **"Do not require Kerberos preauthentication"** is **Unchecked**.

---

### Improvement 2.11.2: Audit Service Principal Names (SPNs) Against Kerberoasting
- **Primary Method (Native Setspn Utility - Admin on DC)**:
  ```cmd
  setspn -T %USERDNSDOMAIN% -Q */*
  ```
- **Audit Action**: Ensure service accounts registered with SPNs have strong 25+ character passwords and do not belong to `Domain Admins`.

---

### Improvement 2.11.3: Reset the `krbtgt` Account Password Twice Following Compromise
- **Primary Method (`dsa.msc` GUI)**:
  1. Open `dsa.msc` $\to$ Locate `krbtgt` account $\to$ Right-click $\to$ Click **Reset Password...**.
  2. Assign a complex 30+ character random password.
  3. Wait 15 minutes for domain-wide replication.
  4. Reset the password a second time to invalidate older Kerberos ticket grants.

---

### Improvement 2.11.4: Enable Active Directory Recycle Bin
- **Primary Method (PowerShell - Admin on DC)**:
  ```powershell
  Enable-ADOptionalFeature 'Recycle Bin Feature' -Scope ForestOrConfigurationSet -Target (Get-ADForest).Name -Confirm:$false
  ```

---

## 2.12 Print Spooler & Printer Drivers

### Improvement 2.12.1: Block Inbound Remote Printing Connections (PrintNightmare Fix)
- **Primary Method (Group Policy GUI)**:
  1. Open `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Printers`.
  2. Locate policy: **"Allow Print Spooler to accept client connections"**.
  3. Double-click $\to$ Select **Disabled**.
  4. Click **Apply** $\to$ Click **OK**.
  5. Restart the Print Spooler service (`services.msc` $\to$ right-click `Print Spooler` $\to$ `Restart`).

---

### Improvement 2.12.2: Restrict Point and Print Driver Installations to Administrators
- **Primary Method (Group Policy GUI)**:
  1. Open `gpedit.msc` $\to$ `Computer Configuration` $\to$ `Administrative Templates` $\to$ `Printers`.
  2. Double-click **"Limits print driver installation to Administrators"** (or **"Point and Print Restrictions"**).
  3. Select **Enabled**.
  4. Under Point and Print security prompts:
     - *"When installing drivers for a new connection"*: Select **Show warning and elevation prompt**.
     - *"When updating drivers for an existing connection"*: Select **Show warning and elevation prompt**.
  5. Click **Apply** $\to$ Click **OK**.

---

## 2.13 Third-Party Software Management & Required Updates

### Improvement 2.13.1: Java Runtime Environment (JRE / JDK) Hardening
- **Primary Method (Control Panel GUI)**:
  1. Open Control Panel $\to$ Click `Java` (or run `C:\Program Files\Java\...\javacpl.exe`).
  2. Click the **Security** tab:
     - **Uncheck**: **"Enable Java content for browser and Web Start applications"**.
     - Set Security Level to: **Very High**.
  3. Click **Apply** $\to$ Click **OK**.

---

### Improvement 2.13.2: Adobe Acrobat Reader Hardening
- **Primary Method (Acrobat Preferences GUI)**:
  1. Open Adobe Acrobat Reader $\to$ Click `Edit` $\to$ `Preferences`.
  2. Under `Security (Enhanced)`: Ensure **"Enable Protected Mode at startup"** and **"Enable Enhanced Security"** are Checked.
  3. Under `JavaScript`: **Uncheck "Enable Acrobat JavaScript"**.
  4. Click **OK**.

---

### Improvement 2.13.3: Microsoft Office Trust Center Macro & Protected View Hardening
- **Primary Method (Office Application GUI)**:
  1. Open Word or Excel $\to$ `File` $\to$ `Options` $\to$ `Trust Center` $\to$ `Trust Center Settings`.
  2. Under `Macro Settings`: Select **"Disable all macros with notification"**.
  3. Under `Protected View`: Ensure all three checkboxes are checked.
  4. Click **OK**.

---

## 2.14 Unauthorized Software, Hacking Tools & Malware Removal

### Improvement 2.14.1: Expanded Offensive Hacking & Credential Dumping Tool List
- **PowerShell File Search**:
  ```powershell
  $badTools = @("mimikatz.exe", "procdump.exe", "ipscan.exe", "hydra.exe", "aircrack-ng.exe", "hashcat.exe", "ophcrack.exe", "responder.py", "responder.exe")
  Get-ChildItem -Path C:\ -Include $badTools -Recurse -ErrorAction SilentlyContinue | Select-Object FullName
  ```

---

### Improvement 2.14.2: Expanded Remote Access Trojans (RATs) & Remote Tools List
- **Primary Method (Programs and Features GUI)**:
  1. Open Control Panel $\to$ `Programs and Features`.
  2. Locate and uninstall: `TeamViewer`, `LogMeIn`, `Hamachi`, `TightVNC`, `UltraVNC`, `Ammyy Admin`, `Supremo`, `Radmin`.

---

### Improvement 2.14.3: Steganography & Hidden Archive Utilities Hunt
- **Primary Method (Programs and Features GUI)**:
  1. Open Control Panel $\to$ `Programs and Features`.
  2. Locate and uninstall: `OpenStego`, `QuickStego`, `Steghide`, `Audacity` (if unapproved media manipulation is suspected).

---

## 2.15 Critical Policies: Do NOT Do Unless Instructed by README

### Improvement 2.15.1: Clarify Consequences of Global IPv6 Disabling
- **Operational Guidance**: Do not disable IPv6 globally unless specified in the scenario instructions, as doing so can break internal Windows update services and automated scoring scripts.

---

### Improvement 2.15.2: Clarify Consequences of Renaming Built-in Guest Account
- **Operational Guidance**: Always disable the `Guest` account first. Do not rename it unless explicitly graded, as automated grading scripts querying the account by name may fail.
