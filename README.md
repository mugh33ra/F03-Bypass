# 🔓 URL Encode / Path Normalization Bypass Tool

A fast, parallel **URL path normalization & encoding bypass testing tool** written in pure **Bash**, designed for **security researchers, bug bounty hunters, and penetration testers**.

This tool automates detection of access control bypasses caused by:
- URL encoding inconsistencies
- Path traversal normalization
- Reverse proxy vs backend parsing differences
- WAF / CDN path handling issues

---

## ✨ Features

- 🚀 Parallel requests for fast scanning
- 🧠 Smart `--path-as-is` usage only when curl would normalize paths
- 🎯 Accurate status-based detection
  - `2xx` → real success (bypass)
  - `3xx` → interesting behavior
  - `4xx` → blocked
  - `5xx` → backend / WAF anomalies
- 🔁 Dynamic payload substitution using `${pat}`
- 📄 Custom payload wordlist support
- 🧩 Custom HTTP method support
- 🧷 Custom headers support (repeatable)
- 📏 Response length comparison
- 🧪 Reproducible curl command output
- 🖥️ Clean, colored terminal output
- 🧷 Bypass with headers support

---

## 📦 Requirements

- Bash 4.3+
- curl
- tput

Tested on Linux, macOS, and WSL.

---

## 📁 File Structure

```text
.
├── 403bypass.sh
├── payloads.txt
└── README.md
```
---

## 🚀 Usage

```bash
Usage: 403bypass.sh -u <url> [options]
Options:
  -u, --url        Specify <Target_Url>
  -m, --method     Specify Method <POST, PUT, PATCH> (Default, GET)
  -H, --header     Add custom header (repeatable)
  -a, --all        Run both URL encode and header bypass tests
  -h, --help       Display help and exit
```

---

## 🧪 Examples

```bash
./403bypass.sh -u https://example.com/admin

./403bypass.sh -u https://example.com/api/admin -m POST

./403bypass.sh -u https://example.com/admin \
  -H "Authorization: Bearer TOKEN" \
  -H "X-Forwarded-For: 127.0.0.1"

./403bypass.sh -u https://example.com/admin \
  -H "Authorization: Bearer TOKEN" \
  --all
```

---

# 👤 Author
[@me_dheeraj](https://x.com/me_dheeraj)

## Enhanced By Ahmad Mugheera
- 🐦 X (Twitter): [@mugh33ra](https://x.com/mugh33ra)
- 💼 LinkedIn: [@mugh33ra](www.linkedin.com/in/ahmadmugheera)
- 🧑‍💻 GitHub: @mugh33ra
- ⭐ If you find this tool useful, consider starring the repository.








