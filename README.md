# Run books

## Deploying
```
colmena apply --build-on-target
```


## Running ipfs

In a tmux (for debugging):

```
GOLOG_LOG_LEVEL="canonical-log=info" LIBP2P_RCMGR=1 ipfs init
GOLOG_LOG_LEVEL="canonical-log=info" LIBP2P_RCMGR=1 ipfs daemon
```


## How to update grafana password

```
grafana-cli --homepath=/var/lib/grafana admin reset-admin-password
```

## ACME is failing.

Is ipfs.marcopolo.io pointed at the correct spot? Update cloudlflare.

## Webtransport

```
/p2p/12D3KooWKasdPzM2iDcBQTHP3YWR8DdgAoBMP4BqXWvxhuCVAYFU

/ip4/18.237.216.248/udp/4002/quic/webtransport/certhash/uEiD_zsX_4c3px3fXGcR7l7Y1uuUVBNrzvDZ3Yo0gG7icvg/certhash/uEiDa3KMjw1j1X7eoyNBLODDh_4TEsKFNKTE7T2Ji-QTE-w/p2p/12D3KooWKasdPzM2iDcBQTHP3YWR8DdgAoBMP4BqXWvxhuCVAYFU

```