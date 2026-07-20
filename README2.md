---

# Part 2 — Cryptographic Protocol Implementation & Network Security Threat Analysis

## 1. Security-Principle Mapping & Cryptographic Justifications

### Security Principles Addressed
* **RSA Implementation:** Addresses **Confidentiality**, **Authentication**, and **Non-Repudiation**. 
  * *Confidentiality:* When a student like Ananya Sharma sends sensitive information encrypted with the server's public key, only the server holding the corresponding private key can decrypt it.
  * *Authentication & Non-Repudiation:* When an instructor like Dr. Ramesh Iyer signs grade records using their private key, anyone can verify the signature using Dr. Iyer's public key, proving the data originated from him and preventing him from denying it later.
* **Diffie-Hellman Implementation:** Addresses **Confidentiality** (specifically Key Exchange and Perfect Forward Secrecy). It lets two users, say Aarav and Bhavna, agree on a shared secret key across an insecure campus network without ever broadcasting the key itself.

### Why Diffie-Hellman is Key Exchange vs. RSA Encryption
Diffie-Hellman is purely a key agreement protocol because it gives two parties a mathematical framework to compute a matching symmetric key without sending secret data over the wire, but it cannot take raw text and convert it into ciphertext. RSA, on the other hand, is a full asymmetric cryptosystem that provides explicit mathematical operations for both key generation and direct payload encryption ($c = m^e \bmod n$) and decryption ($m = c^d \bmod n$). In real systems, Diffie-Hellman is used first to safely agree on a shared key, which is then passed to a fast symmetric algorithm (like AES) to encrypt actual user data.

---

## 2. CampusConnect Network Security Threat-Model Analysis

### (a) Firewall Placement, Type, and Traffic-Filtering Rule
* **Placement & Recommended Type:** We recommend a **dual-layer firewall setup**: a **hardware Web Application Firewall (WAF) / Next-Generation Firewall** at the network boundary (DMZ entrance) combined with a local **software firewall (such as `ufw` or `iptables`)** running directly on the Linux server hosting CampusConnect.
* **Traffic-Filtering Rule:** The host-based software firewall must enforce a rule blocking all external SSH access while allowing remote administration strictly from an internal campus management IP range:
  `ALLOW tcp FROM 10.0.10.0/24 TO any PORT 22 PROTOCOL tcp` (Denies all incoming port 22 connections from external public IP addresses).

### (b) Intrusion Detection System (IDS) Strategy
CampusConnect should deploy **both** Host-based IDS (HIDS) and Network-based IDS (NIDS):
* **HIDS Choice:** A HIDS (like OSSEC or Wazuh) installed on the application server is essential because it monitors local system call logs, file modification checksums, and unauthorized privilege escalation attempts that network sniffers cannot see.
* **NIDS Choice:** A NIDS (like Suricata or Snort) at the network TAP/SPAN port is essential because it analyzes raw unencrypted packet headers across the subnet to detect volume-based DDoS attacks and malicious port scans before they reach individual hosts.

### (c) HTTP vs. HTTPS Analysis
* **Protocol Recommendation:** CampusConnect’s login page must immediately mandate **HTTPS** using TLS 1.3.
* **Vulnerability Prevented:** Transitioning to HTTPS prevents **Credential Sniffing (Eavesdropping)** and **Session Hijacking (Man-in-the-Middle attacks)** by encrypting cleartext HTTP POST traffic that contains student and faculty passwords transmitted over unsecured campus Wi-Fi networks.

### (d) Least Privilege & Multi-Factor Authentication (MFA) Design
* **MFA Architecture:** The authentication system requires two distinct factors:
  1. *Knowledge Factor:* User password or passphrase.
  2. *Possession Factor:* Time-based One-Time Password (TOTP) generated via a mobile authenticator app (e.g., Google Authenticator).
* **Role-Based Access Control (RBAC) Permissions:**
  * **Students (e.g., Chirag Verma):** Granted `READ` access solely to their personal profile and grades, and `UPDATE` access restricted to registering for open course offerings in the enrollment table.
  * **Instructors (e.g., Sunita Deshmukh):** Granted `READ/WRITE` access to assigned course sections, student class lists, and grade assignment tables.
  * **Admins:** Granted full system permissions (`CREATE`, `READ`, `UPDATE`, `DELETE`) over user accounts, course catalog listings, database maintenance, and security audit logs.

### (e) Passive vs. Active Threat Classification
* **Scenario Description:** An attacker sitting in the campus library connects to the open Wi-Fi network and runs a packet analyzer (like Wireshark) to silently capture plain HTTP traffic directed at CampusConnect's login page, extracting student usernames and passwords as they pass through the air.
* **Explicit Classification:** **Passive Attack**.
* **Justification:** This threat is classified as a passive attack because the attacker merely eavesdrops on and records unencrypted data in transit without altering packet contents, injecting malicious code, or interfering with CampusConnect's server performance.