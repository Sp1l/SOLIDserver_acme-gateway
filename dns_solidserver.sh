#!/usr/bin/env sh

########################################################################
# SOLIDserver AcmeGateway hook script for acme.sh
#
# Environment variables:
#   - SOLIDserver_URL:      Full URL to AcmeGateway authRequest API
#                           (mandatory)
#   - SOLIDserver_hostname: hostname to put in payload
#                           (optional)
#
# Accompanying REST service authenticates based on caller
#
# Author: Bernard Spil <brnrd at FreeBSD dot org>

# -- dns_solidserver_add() - Add TXT record --------------------------------
# Usage: dns_solidserver_add _acme-challenge.subdomain.domain.com "XyZ123..."

dns_solidserver_add() {
    fulldomain=$1
    txtvalue=$2
    _dns_solidserver "add" "$fulldomain" "$txtvalue"
    return "$?"
}

#-- dns_solidserver_rm() - Remove TXT record ------------------------------
# Usage: dns_solidserver_rm _acme-challenge.subdomain.domain.com "XyZ123..."

dns_solidserver_rm() {
    fulldomain=$1
    txtvalue=$2
    _dns_solidserver "rm" "$fulldomain" "$txtvalue"
    return "$?"
}

###################  Private functions below ###################

# -- _dns_solidserver() - Add/Remove TXT record ---------------------------
# Usage: _dns_solidserver (add|rm) $fulldomain $token
_dns_solidserver() {
    action=$1
    fulldomain=$2
    txtvalue=$3

    if [ "$action" == "rm" ] ; then
       method="DELETE"
       logtxt="remove"
    else
       method=""
       logtxt="add"
    fi

    _info "dns_solidserver.sh: Executing \"$action\" for \"$fulldomain\""
    _debug "and token \"$token\""

    SOLIDserver_URL="${SOLIDserver_URL:-$(_readaccountconf_mutable SOLIDserver_URL)}"
    SOLIDserver_hostname="${SOLIDserver_hostname:-$(_readaccountconf_mutable SOLIDserver_hostname)}"
    
    _debug2 "Using URL $SOLIDserver_URL"

    payloadfmt='{"subjectAltName": "%s", "token": "%s"'
    if [ -n "${SOLIDserver_hostname}" ]; then
        payloadfmt=$payloadfmt', "hostname": "%s"}'
        payload=$(printf "$payloadfmt" "$fulldomain" "$token" "$SOLIDserver_hostname")
    else
        payloadfmt=$payloadfmt'}'
        payload=$(printf "$payloadfmt" "$fulldomain" "$token")
    fi

    echo "Posting payload \"$payload\""
   
    response="$(_post "$payload" "$SOLIDserver_URL" "" "$method" "application/json")"
    exit_code="$?"
    if [ "$exit_code" -eq 0 ]; then
        _info "dns_solidserver.sh: TXT record $logtxt successful."
    else
        _err "dns_solidserver.sh: Couldn't $logtxt the TXT record, exit code $exit_code"
    fi
    _debug2 response "$response"

    _saveaccountconf_mutable SOLIDserver_URL  "$SOLIDserver_URL"
    _saveaccountconf_mutable SOLIDserver_hostname  "$SOLIDserver_hostname"
    return "$exit_code"
}

    
