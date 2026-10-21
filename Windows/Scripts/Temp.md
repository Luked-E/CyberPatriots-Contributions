
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
