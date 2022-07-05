# Run books

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