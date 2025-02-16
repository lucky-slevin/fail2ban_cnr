# fail2ban_ip_checkandreport

A Bash script to check and report banned IPs from Fail2Ban to AbuseIPDB. Additionally, suspicious IPs are automatically blocked via UFW (Uncomplicated Firewall).

## 📋Requirements

The script requires the following packages:

 - fail2ban (to retrieve banned IPs)
 - ufw (to block IPs)
 - curl (to communicate with APIs)
 - jq (to process JSON data)

## 🔧Installing the required packages

### Debian/Ubuntu:
```bash
sudo apt update && sudo apt install -y fail2ban ufw curl jq
```
### CentOS/RHEL:
```bash
sudo yum install -y epel-release
sudo yum install -y fail2ban ufw curl jq
```
### Arch Linux:
```bash
sudo pacman -Syu fail2ban ufw curl jq
```
## 🚀 Usage
### 1️⃣Ensure Fail2Ban is running
Make sure Fail2Ban is installed and running with active bans:

```bash
sudo fail2ban-client status
```
If you see a list of banned IPs, you're good to go.
### 2️⃣Make the script executable

```bash
chmod +x fail2ban_ip_checkandreport.sh
```

### 3️⃣Run the script manually

```bash
./fail2ban_ip_checkandreport.sh
```

## 🔄Automating execution with Cron (Recommended)
To automatically run the script every 20 minutes, add the following line to your crontab:

```bash
*/20 * * * * /path/to/script/fail2ban_ip_checkandreport.sh
```
To edit your crontab, use:
```bash
crontab -e
```
## 🔑 API Keys
The script requires an AbuseIPDB API key to report malicious IPs.
You can get a free API key from AbuseIPDB and add it to the script:
```bash
ABUSEIPDB_API_KEY="YOUR_API_KEY_HERE"
```
## 🛠Troubleshooting & Debugging

If the script does not work as expected, run it in debug mode:
```bash
bash -x ./fail2ban_ip_checkandreport.sh
```
This will print detailed output of the script’s execution.

📜 **License**: MIT
👨‍💻 Developed by lucky_slevin
