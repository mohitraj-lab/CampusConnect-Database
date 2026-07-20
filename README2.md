# CampusConnect Data & Security Layer

**Database Engine:** MySQL 8.0 (InnoDB)  
**Security Architecture:** Asymmetric Cryptography (RSA) & Key Agreement (Diffie-Hellman)

---

## Part 1 — Schema Design, Normalization, Indexing & Concurrency

### 1. Schema Design & Normalization

#### What happens if we don't normalize?
Imagine running a university database where all student details, course information, and grades are dumped into one massive spreadsheet or a single unorganized table called `flat_enrollments`. It might seem easy at first, but it quickly leads to severe data maintenance issues:

* **Insertion Anomaly:** You cannot add a newly created course to the database unless at least one student registers for it first.
* **Deletion Anomaly:** If only one student is enrolled in an elective course and they decide to drop it, deleting their record unintentionally wipes out the entire course's existence from the university records.
* **Update Anomaly:** If a professor like Dr. Sharma changes her office location or email ID, you would have to manually update thousands of individual student enrollment rows. Missing even a single row leaves the database in an inconsistent state.

#### Functional Dependencies Identified
Through system analysis, we identified the following functional dependencies:
* `student_id` $\rightarrow$ `first_name`, `last_name`, `email`, `department`
* `course_id` $\rightarrow$ `course_code`, `course_name`, `credits`
* (`student_id`, `course_id`) $\rightarrow$ `grade`, `enrollment_date`

#### Normalization Journey (1NF to 3NF)
To eliminate these risks, we normalized the structure step by step:
* **1NF (First Normal Form):** We eliminated multi-valued attributes and ensured that every cell contains atomic, indivisible values. A unique Primary Key was established for every table.
* **2NF (Second Normal Form):** We removed partial key dependencies. Attributes like `course_name` depend solely on the `course_id`, not on the combined composite key (`student_id`, `course_id`). Thus, course data was moved into its own dedicated table.
* **3NF (Third Normal Form):** We removed transitive dependencies. Non-key fields like `department` were separated so that no non-key attribute relies on another non-key attribute.

---

### 2. Performance & Indexing Strategy

To keep queries running fast as the student body grows, we implemented two key indexing strategies:
* **Foreign Key Indexes:** We created explicit indexes on `student_id` and `course_id` inside the `enrollments` table. This drastically reduces query execution time during complex multi-table `JOIN` operations.
* **Composite Index:** We created a composite index on `(course_id, grade)`. This specifically optimizes analytical queries that calculate class distributions or fetch top-performing students per course without scanning the entire table.

---

### 3. Concurrency Control & Isolation Levels

* **Default Isolation Level (`REPEATABLE READ`):** MySQL InnoDB uses `REPEATABLE READ` along with Next-Key Locking. This prevents non-repeatable reads and phantom reads during concurrent seat bookings.
* **Mitigating Race Conditions:** When hundreds of students try to register for a high-demand course with limited seats at the exact same second, race conditions can cause overbooking. We solved this by using explicit pessimistic row locking (`SELECT ... FOR UPDATE`) inside an atomic database transaction to lock the course seat count until the transaction completes.

---

# Part 2 — Cryptographic Implementation & Network Security Threat Analysis

## 1. Security-Principle Mapping & Cryptographic Justifications

### Security Principles Addressed
* **RSA Implementation:** Covers **Confidentiality**, **Authentication**, and **Non-Repudiation**.
  * *Confidentiality:* When a student like Ananya Sharma transmits sensitive login credentials encrypted with the server's public key, only the server holding the corresponding private key can decrypt and read them.
  * *Authentication & Non-Repudiation:* When an instructor like Dr. Ramesh Iyer signs grade submissions using his private key, anyone can verify the signature using Dr. Iyer's public key. This proves the grades came directly from him and prevents him from denying the action later.
* **Diffie-Hellman Implementation:** Covers **Confidentiality** (specifically Key Exchange and Perfect Forward Secrecy). It allows two parties, like Aarav and Bhavna, to establish a shared secret key across an open campus Wi-Fi network without ever transmitting the key itself over the wire.

### Why Diffie-Hellman is Key Exchange vs. RSA Encryption
Diffie-Hellman is strictly a key agreement protocol—it provides a mathematical framework for two remote parties to calculate a matching symmetric key over an untrusted network. However, it cannot take an arbitrary piece of text and convert it into ciphertext. 

RSA, on the other hand, is a full asymmetric cryptosystem. It provides explicit mathematical operations for key generation, direct payload encryption ($c = m^e \bmod n$), and decryption ($m = c^d \bmod n$). In real-world security systems, Diffie-Hellman is used first to safely agree on a secret key, which is then handed off to a fast symmetric algorithm (like AES) to handle actual data encryption.

---

## 2. CampusConnect Network Security Threat-Model Analysis

### (a) Firewall Placement, Type, and Traffic-Filtering Rule
* **Placement & Recommended Type:** We recommend a **hybrid dual-layer firewall setup**: a **hardware Web Application Firewall (WAF) / Next-Generation Firewall** at the network boundary (DMZ entrance) combined with a local **software firewall (such as `ufw` or `iptables`)** running directly on the Linux server hosting CampusConnect.
* **Traffic-Filtering Rule:** The host-level software firewall must enforce a strict administrative rule blocking all public SSH attempts except from the internal management network:
  `ALLOW tcp FROM 10.0.10.0/24 TO any PORT 22 PROTOCOL tcp` (Denies all external incoming connections on port 22).

### (b) Intrusion Detection System (IDS) Strategy
CampusConnect should deploy **both** Host-based IDS (HIDS) and Network-based IDS (NIDS):
* **HIDS Choice:** A HIDS (such as OSSEC or Wazuh) installed on the server is essential because it monitors local system call logs, file integrity checksums, and unauthorized privilege escalation attempts that network sniffers cannot see.
* **NIDS Choice:** A NIDS (such as Suricata or Snort) placed at the network TAP/SPAN port is essential because it analyzes raw unencrypted packet headers across the subnet to catch volume-based DDoS attacks and port scans before they reach individual machines.

### (c) HTTP vs. HTTPS Analysis
* **Protocol Recommendation:** CampusConnect’s login portal must strictly mandate **HTTPS** using TLS 1.3.
* **Vulnerability Prevented:** Transitioning to HTTPS prevents **Credential Sniffing (Eavesdropping)** and **Session Hijacking (Man-in-the-Middle attacks)** by encrypting cleartext HTTP POST traffic containing student and faculty passwords over unsecured campus Wi-Fi networks.

### (d) Least Privilege & Multi-Factor Authentication (MFA) Design
* **MFA Architecture:** The authentication process requires two distinct factors:
  1. *Knowledge Factor:* Master user password or passphrase.
  2. *Possession Factor:* Time-based One-Time Password (TOTP) generated via a mobile authenticator app (such as Google Authenticator).
* **Role-Based Access Control (RBAC) Permissions:**
  * **Students (e.g., Chirag Verma):** Granted `READ` access solely to their personal profile and grades, and `UPDATE` access restricted strictly to active course registration tables.
  * **Instructors (e.g., Sunita Deshmukh):** Granted `READ/WRITE` access to assigned course sections, student class lists, and grade assignment tables.
  * **Admins:** Granted full administrative rights (`CREATE`, `READ`, `UPDATE`, `DELETE`) across user accounts, course catalog structures, system maintenance, and audit log reviews.

### (e) Passive vs. Active Threat Classification
* **Scenario Description:** An attacker sitting in the campus library connects to the open Wi-Fi network and uses a packet sniffer (like Wireshark) to silently capture plain HTTP traffic sent to CampusConnect's login page, extracting student usernames and passwords as they travel over the airwaves.
* **Explicit Classification:** **Passive Attack**.
* **Justification:** This threat is classified as a passive attack because the attacker merely eavesdrops on and records unencrypted network traffic without altering packet contents, injecting malicious payloads, or interfering with CampusConnect's server performance.