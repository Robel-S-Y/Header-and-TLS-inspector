#!/bin/zsh

# Logo and description
echo "\033[1;32m"
echo "                ████████╗  ██╗                              "
echo "                ██════██║  ██║                       \033[0m"
echo "\033[1;33m                      ██║  ██║                              "
echo "                ████████║  ██║                              "
echo "                ██ ╔════╝  ██║                       \033[0m"
echo "\033[0;31m                ███████╗   ██║                              "
echo "                ╚══════╝   ╚═╝                       \033[0m"
echo "              \033[1;36m       Zhè Hēikè \033[1;32m"
echo "   ---------------------------------------------------------"
echo "       \033[1;36m           Header and TLS inspector\033[0m"
echo "       \033[1;36m                   Done by:Robel Y.\033[0m"
echo "   ---------------------------------------------------------"

#url input
echo  "Enter the URL(Domain name) : "
read URL


# Initialization
MISSING_COUNT=0
SECURE_COUNT=0


#security header,

Hs=("X-Frame-Options"
    "X-Content-Type-Options"
    "Strict-Transport-Security"
    "Content-Security-Policy"
    "Referrer-Policy"
    "Permissions-Policy"
    "Cross-Origin-Embedder-Policy"
    "Cross-Origin-Resource-Policy"
    "Cross-Origin-Opener-Policy"
)
echo "\nchecking security headers for:\033[0;31m \"$URL\"\033[0m"

echo "---------------------------------------------\n"

for H in "${Hs[@]}"; do
  Response=$(curl -s -I "https://$URL"| grep -i "$H")
if [ -z "$Response" ]; then
   echo "\033[1;31m[!]Missing Security header : $H\033[0m"
    ((c++))
MISSING_COUNT=$((MISSING_COUNT + 1))
else
c=0
fi
done

if [ c!==0 ]; then
echo "\nTotal Number Of Missing Security Headers: \033[1;31m$c\033[0m"
else
echo "\n All security headers are present, \033[0;31m\"no worries\"\033[0m"
fi

echo "---------------------------------------------\n"

# Check for HTTP to HTTPS redirection
echo "\nChecking for HTTP to HTTPS redirection..."
REDIRECT=$(curl -s -o /dev/null -w "%{redirect_url}" "http://$URL")
if [[ $REDIRECT == https* ]]; then
  echo "\033[1;32mHTTP to HTTPS redirection: Enabled\033[0m (Redirects to $REDIRECT)"
  SECURE_COUNT=$((SECURE_COUNT + 1))
else
  echo "\033[1;31mHTTP to HTTPS redirection: Not Enabled\033[0m"
  MISSING_COUNT=$((MISSING_COUNT + 1))
fi

# Check for HSTS enforcement
echo "\nChecking for HSTS (Strict-Transport-Security) header..."
HSTS=$(curl -s -I "https://$URL" | grep -i "Strict-Transport-Security")
if [ -n "$HSTS" ]; then
  echo "\033[1;32mHSTS enforcement: Enabled\033[0m"
  SECURE_COUNT=$((SECURE_COUNT + 1))
else
  echo "\033[1;31mHSTS enforcement: Not Enabled\033[0m"
  MISSING_COUNT=$((MISSING_COUNT + 1))
fi

# List of protocols to check
PROTOCOLS=(
  "ssl2"
  "ssl3"
  "tls1"
  "tls1_1"
  "tls1_2"
  "tls1_3"
)

echo "\nTesting SSL/TLS protocols for: $URL\033[0m"
echo "-------------------------------------------------------------"

# Loop through each protocol and test its availability
for PROTOCOL in "${PROTOCOLS[@]}"; do
  RESULT=$(openssl s_client -$PROTOCOL -connect "$URL:443" < /dev/null 2>&1)
  if echo "$RESULT" | grep -q "handshake failure"; then
    echo "\033[1;31m$PROTOCOL: disabled\033[0m"  # Red color for disabled
    MISSING_COUNT=$((MISSING_COUNT + 1))
  elif echo "$RESULT" | grep -q "CONNECTED"; then
    echo "\033[1;32m$PROTOCOL: enabled\033[0m"   # Green color for enabled
    SECURE_COUNT=$((SECURE_COUNT + 1))
  else
    echo "\033[1;33m$PROTOCOL: unable to determine\033[0m"  # Yellow for undetermined
    MISSING_COUNT=$((MISSING_COUNT + 1))
  fi
done

echo "-------------------------------------------------------------"

# Check for TLS Fallback SCSV support
echo "\nChecking TLS Fallback SCSV support..."
TLS_RESULT=$(echo | openssl s_client -tls1_2 -fallback_scsv -connect "$DOMAIN:443" 2>&1)
if echo "$TLS_RESULT" | grep -q "inappropriate fallback"; then
  echo "\033[1;32mTLS Fallback SCSV: supported\033[0m"  # Green for supported
  SECURE_COUNT=$((SECURE_COUNT + 1))
else
  echo "\033[1;31mTLS Fallback SCSV: not supported\033[0m"  # Red for not supported
  MISSING_COUNT=$((MISSING_COUNT + 1))
fi

# Overall Assessment
echo "\n-------------------------------------------------------------"
echo "Overall Security Assessment:"
if [ "$MISSING_COUNT" -eq 0 ]; then
  echo "\033[1;32mExcellent! No missing security features.\033[0m"
       b="is good securiy"
elif [ "$MISSING_COUNT" -le 3 ]; then
  echo "\033[1;33mGood, but a few improvements needed ($MISSING_COUNT missing features).\033[0m"
else
  echo "\033[1;31mPoor! Many missing security features ($MISSING_COUNT missing).\033[0m"
fi
echo "-------------------------------------------------------------"
echo "\n\033[1;33m--------Finished scanning--------\033[0m"
