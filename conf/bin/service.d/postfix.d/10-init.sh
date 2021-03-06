# force new copy of hosts there (otherwise links could be outdated)
mkdir -p /var/spool/postfix/etc
cp -f /etc/hosts       /var/spool/postfix/etc/hosts
cp -f /etc/resolv.conf /var/spool/postfix/etc/resolv.conf
cp -f /etc/services    /var/spool/postfix/etc/services

# General
go-replace --mode=lineinfile \
    -s '/myhostname[ ]* =/c\' -r "myhostname = $HOSTNAME" \
    -s '/inet_interfaces[ ]* =/c\' -r "inet_interfaces = 127.0.0.1" \
    -- /etc/postfix/main.cf

## REPLAYHOST
if [[ -n "${POSTFIX_RELAYHOST+x}" ]]; then
    go-replace --mode=lineinfile \
        -s '/relayhost[ ]* =/c\' -r "relayhost = $POSTFIX_RELAYHOST" \
        -- /etc/postfix/main.cf
fi

## MYNETWORKS
if [[ -n "${POSTFIX_MYNETWORKS+x}" ]]; then
    go-replace --mode=lineinfile \
        -s '/mynetworks[ ]* =/c\' -r "mynetworks = $POSTFIX_MYNETWORKS" \
        -- /etc/postfix/main.cf
fi

# generate aliases db
newaliases || :
