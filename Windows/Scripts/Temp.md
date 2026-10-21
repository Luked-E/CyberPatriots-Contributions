
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