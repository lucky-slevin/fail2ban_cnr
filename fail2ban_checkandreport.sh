#!/bin/bash

# Log file
LOG_FILE="/var/log/fail2ban_ip_checkandreport.log"

# Console output colors (not written to the log)
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# AbuseIPDB API Key
ABUSEIPDB_API_KEY="[YOUR_OWN_AbuseIPDB_API_KEY]"

# Function to block high-risk IPs
block_ip_if_high_risk() {
    local score=$1
    local ip=$2
    local action="No action"

    if [ "$score" -ge 71 ]; then
        if sudo ufw status | grep -q "$ip"; then
            action="Already blocked"
        else
            sudo ufw deny from "$ip" >/dev/null 2>&1
            action="IP blocked"
        fi
    fi

    echo "$action"
}

# Function to report an IP to AbuseIPDB
report_ip_to_abuseipdb() {
    local ip=$1
    response=$(curl -s -X POST "https://api.abuseipdb.com/api/v2/report" \
        --data-urlencode "ip=$ip" \
        --data-urlencode "categories=18,22" \
        -H "Key: $ABUSEIPDB_API_KEY" \
        -H "Accept: application/json")

    if echo "$response" | grep -q "errors"; then
        error_msg=$(echo "$response" | jq -r '.errors[0].detail')
        echo "Failed: $error_msg"
    else
        echo "Reported to AbuseIPDB"
    fi
}

# Retrieve banned IPs from fail2ban
banned_ips=$(sudo fail2ban-client banned | sed 's/[^0-9. ]//g' | xargs -n1)

if [ -z "$banned_ips" ]; then
    echo "[INFO] No banned IPs found." | tee -a "$LOG_FILE"
    exit 0
fi

# Separator line with timestamp
echo -e "\n[$(date +"%d.%m.%Y %H:%M:%S")] -- Scan started --" | tee -a "$LOG_FILE"

# Iterate through the banned IPs
for ip in $banned_ips; do
    country=$(curl -s "http://ip-api.com/json/${ip}" | jq -r '.country // "Unknown"')
    isp=$(curl -s "http://ip-api.com/json/${ip}" | jq -r '.isp // "Unknown"')

    # Fetch data from AbuseIPDB
    abuse_data=$(curl -sG "https://api.abuseipdb.com/api/v2/check" \
        --data-urlencode "ipAddress=${ip}" \
        -H "Key: $ABUSEIPDB_API_KEY" \
        -H "Accept: application/json")

    # Safely extract the score
    score=$(echo "$abuse_data" | jq -r '.data.abuseConfidenceScore // 0' | grep -Eo '^[0-9]+$' || echo 0)
    reports=$(echo "$abuse_data" | jq -r '.data.totalReports // 0' | grep -Eo '^[0-9]+$' || echo 0)

    # Determine score category
    if [ "$score" -le 33 ]; then
        score_text="LOW"
        color=$GREEN
    elif [ "$score" -le 66 ]; then
        score_text="MIDDLE"
        color=$YELLOW
    else
        score_text="HIGH"
        color=$RED
    fi

    # Block IP if the score is high
    action=$(block_ip_if_high_risk "$score" "$ip")

    # If the score is very high, report the IP to AbuseIPDB
    if [ "$score" -ge 85 ]; then
        report_action=$(report_ip_to_abuseipdb "$ip")
        action="$action | $report_action"
    fi

    # Final logging format
    log_entry="[$(date +"%d.%m.%Y %H:%M:%S")] $ip - $score_text ($score) - $reports Reports - Country: $country, ISP: $isp - [$action]"

    # Print output with color in the console
    echo -e "$color$log_entry$NC"

    # Write output without color to the log
    echo "$log_entry" >> "$LOG_FILE"

done

