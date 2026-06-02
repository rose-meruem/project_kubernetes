# INC-000 — Docker Bridge Networking Blocked by nftables

## Summary

During Phase 1, Docker builds failed because containers could not reach PyPI.

The initial error appeared during dependency installation:

```text
Temporary failure in name resolution
/simple/fastapi/
```

Root cause: native nftables was blocking Docker bridge forwarding.

## Impact

The API image could not install Python dependencies during:

```bash
docker compose up -d --build
```

Failing Dockerfile step:

```dockerfile
RUN pip install --no-cache-dir -r requirements.txt
```

## Tests performed

Host internet worked:

```bash
curl -I https://pypi.org/simple/fastapi/
```

Docker bridge DNS failed:

```bash
docker run --rm alpine nslookup pypi.org
```

Docker bridge internet failed:

```bash
docker run --rm alpine ping -c 3 1.1.1.1
```

Docker host networking worked:

```bash
docker run --rm --network host alpine nslookup pypi.org
```

Docker bridge gateway worked:

```bash
docker run --rm alpine ping -c 3 172.17.0.1
```

Conclusion:

```text
Host internet: OK
Docker host network: OK
Container → docker0 gateway: OK
Container → internet: KO
```

## Root cause

Native nftables had a forward chain with a default drop policy:

```nft
table inet filter {
  chain forward {
    type filter hook forward priority filter
    policy drop
  }
}
```

Docker had iptables-nft rules, but this separate native nftables forward hook still dropped Docker bridge traffic before NAT could complete.

## Fix

Allow Docker private bridge subnets to forward through the host outbound interface.

Runtime fix:

```bash
sudo nft insert rule inet filter forward ip saddr 172.16.0.0/12 oifname "wlan0" accept
sudo nft insert rule inet filter forward ip daddr 172.16.0.0/12 iifname "wlan0" ct state established,related accept
```

Persistent fix in `/etc/nftables.conf`:

```nft
chain forward {
  type filter hook forward priority filter
  policy drop

  ip saddr 172.16.0.0/12 oifname "wlan0" accept
  ip daddr 172.16.0.0/12 iifname "wlan0" ct state established,related accept
}
```

Reload and validate:

```bash
sudo nft -c -f /etc/nftables.conf
sudo nft -f /etc/nftables.conf
sudo systemctl restart docker
```

## Validation

After the fix:

```bash
docker run --rm alpine ping -c 3 1.1.1.1
docker run --rm alpine nslookup pypi.org
docker run --rm alpine wget -qO- https://pypi.org | head
```

Result:

```text
Docker bridge networking restored.
Containers can reach the internet.
Docker builds can download dependencies.
```

## Lessons learned

- DNS errors can hide lower-level network forwarding issues.
- Always test raw IP connectivity before assuming DNS is the only problem.
- Compare Docker bridge networking with `--network host`.
- On systems using `iptables-nft`, also inspect native nftables rules.
- Docker rules can look correct while a separate nftables forward chain still blocks traffic.
