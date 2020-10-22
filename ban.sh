#!/bin/bash

# This checks if you have jq installed
command -v jq >/dev/null 2>&1 || { echo >&2 "Please install \"jq\" first. Aborting."; exit 1; }

# Temp file
AWS_IP_RANGES_FILE="`mktemp /tmp/amazon-ip-ranges.XXXXXXXXXX`"
GCP_IP_RANGES_FILE="`mktemp /tmp/google-ip-ranges.XXXXXXXXXX`"

# Adjust CLIENT variable so it calls bitcoin-cli with the right parameters
# Non standart installations need to add -conf=/PATHtoYOUR/bitcoin.conf -datadir=/PATH/to/YOUR/Datadir/
CLIENT=/usr/local/bin/bitcoin-cli

# Ban Time in seconds, 2592000 = 30 days
BAN_TIME="2592000"

# Get list of Amazon IP Ranges http://docs.aws.amazon.com/general/latest/gr/aws-ip-ranges.html
wget -qO- https://ip-ranges.amazonaws.com/ip-ranges.json -O $AWS_IP_RANGES_FILE
# Get list of GCP IP Ranges https://cloud.google.com/vpc/docs/configure-private-google-access
wget -qO- https://www.gstatic.com/ipranges/cloud.json -O $GCP_IP_RANGES_FILE

# Extract IPV4 and IPV6 ranges
AWS_IP_RANGES=`jq -r '.prefixes[].ip_prefix, .ipv6_prefixes[].ipv6_prefix' $AWS_IP_RANGES_FILE`
GCP_IP_RANGES=`grep -Po '"ipv.*": *"\K[^"]*' GCP_IP_RANGES_FILE`

# Ban extracted ranges with bicoin-cli using BAN_TIME
for RANGE in $AWS_IP_RANGES; do
  $($CLIENT setban $RANGE "add" ${BAN_TIME})
done

# Ban extracted ranges with bicoin-cli using BAN_TIME
for RANGE in $GCP_IP_RANGES; do
  $($CLIENT setban $RANGE "add" ${BAN_TIME})
done

# Remove tmp file
rm $AWS_IP_RANGES_FILE
rm $GCP_IP_RANGES_FILE
