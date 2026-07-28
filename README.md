# Inception-of-Things

```
qemu-monitor-command --domain alpinelinux3.21 --hmp --cmd 'hostfwd_add tcp::2222-:22'
```

```
ip -f inet addr show virbr0 | awk '/inet / {print $2}'
```

```
curl --silent --location "https://api.github.com/repos/canonical/cloud-utils/releases/latest" | grep -m 1 '"url":' | cut -d ':' -f 2,3 | tr -d '[:blank:]' | sed 's/,*$//g' | xargs -n1 curl -s | grep -e tarball_url | cut -d ':' -f 2,3 | tr -d '[:blank:]' | sed 's/,*$//g' | xargs -n1 curl -L -o "cloud-init-utils.gz"
```

```
DESTDIR=$HOME make install
```
