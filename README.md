# Inception-of-Things


## Dependencies:

- cloud-utils
- xorriso
- ln -s genisoimage xorrisofs

### Install cloud-utils

```bash
cd $HOME/Downloads
wget https://github.com/canonical/cloud-utils/archive/refs/tags/0.34.tar.gz
mv 0.34.tar.gz cloud-utils-0.34.tar.gz
tar axvf cloud-utils-0.34.tar.gz
cd cloud-utils-0.34
DESTDIR=$HOME make install
```

### Install xorriso (and link genisoimage)

```bash
cd $HOME/Downloads
wget https://www.gnu.org/software/xorriso/xorriso-1.5.8.pl02.tar.gz
tar axvf xorriso-1.5.8.pl02.tar.gz
cd xorriso-1.5.8
./configure --prefix=$HOME/usr
make install -j4
```

Use your directory (prefix, where you installed the commands)

```bash
cd $HOME/usr/bin
ln -s xorrisofs genisoimage
```
