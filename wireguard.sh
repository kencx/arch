#!/usr/bin/env bash

# be aware of the 5 device limitation. This output may be suppressed from the redirection below.
# {"detail":"This account already has the maximum number of devices.","code":"MAX_DEVICES_REACHED"}

account_number="$1"

die() {
    echo "[-] Error: $1" >&2
    exit 1
}

if [[ $# -lt 1 ]]; then
    die "Missing account number"
fi

type wg >/dev/null || die "Please install wg and then try again."
type curl >/dev/null || die "Please install curl and then try again."
type jq >/dev/null || die "Please install jq and then try again."

private_key="$(wg genkey)"
public_key="$(wg pubkey <<<"${private_key}")"

# get access token
access_token=$(curl -s -X POST 'https://api.mullvad.net/auth/v1/token' -H 'accept: application/json' -H 'content-type: application/json' -d '{ "account_number": "'${account_number}'" }' | jq -r .access_token)

# post hijack_dns setting and get device name and ipaddr
jblob=$(curl -s -X POST 'https://api.mullvad.net/accounts/v1/devices' -H "Authorization: Bearer ${access_token}" -H 'content-type: application/json' -d '{"pubkey":"'${public_key}'","hijack_dns":false}')

device_name=$(echo ${jblob} | jq -r .name)
wg_ipaddr=$(echo ${jblob} | jq -r .ipv4_address)
wg_ipaddr6=$(echo ${jblob} | jq -r .ipv6_address)

echo "Mullvad Device Name: $(echo -n ${device_name})"
echo "Public Key: $(echo -n ${public_key})"
echo "WIREGUARD_PRIVATE_KEY=$(echo -n ${private_key})"
echo "WIREGUARD_ADDRESSES=$(echo -n ${wg_ipaddr})"
echo "WIREGUARD_ADDRESSES=$(echo -n ${wg_ipaddr6})"
