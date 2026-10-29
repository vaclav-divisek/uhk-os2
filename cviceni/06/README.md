# Cvičení 06 – Hardware, oprávnění a odkazy

Podle **NDG Linux Essentials** a labů **Linux I.**:

- **Module 12 – Understanding Computer Hardware**
- **Module 13 – Where Data is Stored**
- Linux I. – **Hardware Configuration**, **File Permissions**, **Filesystem Links**

**Vstupní požadavky:** samostudium Module 12 a 13, splněné *Lab 12 + Chapter 12 Exam*, *Lab 13 + Chapter 13 Exam*, Exams z předchozích modulů a *Midterm Exam (Modules 2–9)*.

Vše si zkoušíme v laboratorním prostředí **NDG NETLAB+** na [portal.netdevgroup.com](https://portal.netdevgroup.com/).

---

## 0. Příprava prostředí

1. Přihlas se na [portal.netdevgroup.com](https://portal.netdevgroup.com/) a spusť **Lab** příslušného modulu.
2. Jsi přihlášen jako **`sysadmin`**, heslo pro `sudo` je **`netlab123`**.
3. Pracovní adresář:

```bash
mkdir -p ~/cv06
cd ~/cv06
```

> ⚠️ NDG lab běží v **kontejneru** – sdílí jádro a hardware s hostitelským serverem.
> Proto některé hardwarové příkazy (`lspci`, `lsusb`, `modprobe`…) mohou vypsat **hardware serveru**,
> **nic**, nebo skončit chybou. To je v pořádku – jde o to pochopit, co příkaz dělá.

---

# 1. Hardware Configuration

## 1.1 Základní hardware

Komponenty **nezbytné pro provoz** počítače:

| Komponenta | Co dělá | Kde v Linuxu zjistím |
|---|---|---|
| **CPU** (procesor) | zpracovává data, provádí výpočty | `lscpu`, `/proc/cpuinfo` |
| **RAM** (operační paměť) | **dočasně** ukládá data systému a programů (po vypnutí zmizí) | `free`, `/proc/meminfo` |
| **Firmware** (BIOS / UEFI) | spustí zavádění systému, pomáhá jádru rozpoznat zařízení | `/sys/firmware` |
| **Úložiště** (disky) | **trvale** ukládá data | `lsblk`, `df` |

## 1.2 CPU

```bash
lscpu                         # přehled: architektura, počet jader, model, cache
lscpu | grep 'Model name'
nproc                         # jen počet dostupných jader
cat /proc/cpuinfo             # detailně – blok pro KAŽDÉ jádro
grep -c processor /proc/cpuinfo       # počet logických CPU
grep 'model name' /proc/cpuinfo | head -1
uname -m                      # architektura (x86_64, aarch64…)
uname -a                      # jádro, hostname, architektura
```

> Slidy uvádí „podrobnosti o CPU: `uname`" – `uname` ve skutečnosti vypisuje hlavně informace
> o **jádře** (verze, architektura), ne o procesoru. Na CPU je `lscpu` a `/proc/cpuinfo`.

## 1.3 RAM

```bash
cat /proc/meminfo | head
# MemTotal:       132014640 kB
# MemFree:         67439868 kB
# MemAvailable:    99487364 kB
# Buffers:          2116936 kB
# Cached:          27429740 kB

free                          # shrnutí v kB
free -h                       # čitelně (Gi, Mi) – nejpraktičtější
free -m                       # v MB
```

| Sloupec `free` | Význam |
|---|---|
| `total` | celková paměť |
| `used` | použitá programy |
| `free` | úplně nevyužitá |
| `buff/cache` | použitá jako **cache disku** – systém ji uvolní, když ji programy potřebují |
| `available` | kolik je **reálně k dispozici** pro nové programy (free + uvolnitelná cache) |
| řádek `Swap` | odkládací prostor na disku, když dojde RAM |

> 💡 Malé `free` není problém – Linux nevyužitou RAM používá jako cache. Důležitý je sloupec **`available`**.

## 1.4 Firmware – BIOS a UEFI

Firmware je software uložený přímo na základní desce. Po zapnutí **otestuje hardware a spustí zavádění** operačního systému.

| | BIOS | UEFI |
|---|---|---|
| celý název | *Basic Input Output System* | *Unified Extensible Firmware Interface* |
| stáří | od 80. let | moderní náhrada BIOSu |
| disky | tabulka oddílů MBR (max. 2 TB) | GPT (obří disky, víc oddílů) |
| navíc | — | Secure Boot, grafické rozhraní, rychlejší start |

Do nastavení firmwaru se dostaneš klávesou při startu – podle výrobce **F2, F12, Esc nebo Del**.

```bash
ls /sys/firmware/efi && echo "UEFI" || echo "BIOS (nebo kontejner)"
```

> Slidy píší, že UEFI je náhrada BIOSu „s totožnými funkcemi" – přesněji: zvládá **totéž co BIOS a něco navíc**.

## 1.5 Úložiště (mass storage)

Typy rozhraní disků:

| Rozhraní | Popis | Zařízení v Linuxu |
|---|---|---|
| **IDE** (PATA) | staré paralelní rozhraní | `/dev/hda`… (dnes i `/dev/sd*`) |
| **SCSI** | serverové disky | `/dev/sda`, `/dev/sdb`… |
| **SATA** | dnešní běžné HDD/SSD | `/dev/sda`… |
| **USB** | externí disky, flash disky | `/dev/sdb`… |
| **NVMe** | moderní rychlá SSD (přes PCIe) | `/dev/nvme0n1`… |

```bash
lsblk                         # disky a oddíly ve stromové struktuře
df -h                         # obsazenost připojených souborových systémů
ls -l /dev/sd* /dev/nvme* 2>/dev/null
```

## 1.6 Coldplug a hotplug

| Typ | Kdy se připojuje | Příklad |
|---|---|---|
| **Coldplug** | jen při **vypnutém** počítači | CPU, RAM, PCI karty, interní disky (u běžných PC) |
| **Hotplug** (*plug and play*) | za **běhu** systému | USB flash disk, myš, klávesnice |

## 1.7 Hardwarové prostředky

Jak zařízení komunikují se systémem:

| Prostředek | Význam | Kde se podívat |
|---|---|---|
| **IO Ports** | adresy, přes které CPU posílá zařízení příkazy | `/proc/ioports` |
| **IO Memory** | oblasti paměti namapované na zařízení (předávání dat) | `/proc/iomem` |
| **IRQ** (*Interrupt Request*) | signál, kterým zařízení **přeruší** CPU („mám data, obsluž mě") | `/proc/interrupts` |
| **DMA** (*Direct Memory Access*) | zařízení zapisuje/čte **přímo do RAM** bez zatěžování CPU | `/proc/dma` |

```bash
cat /proc/interrupts | head
sudo cat /proc/ioports | head
cat /proc/dma
```

## 1.8 Sběrnice – `lspci`, `lsusb`

Komponenty spolu komunikují přes **sběrnice** (*bus*):

- **interní** – uvnitř počítače (PCI, PCI Express),
- **externí** – pro připojení zařízení zvenku (USB, Thunderbolt),
- **bridge** (most) – propojuje různé sběrnice mezi sebou.

```bash
lspci                         # zařízení na sběrnici PCI (síťovka, grafika, řadiče disků…)
# 00:00.0 Host bridge: Intel Corporation 5520 I/O Hub to ESI Port (rev 13)
# 00:01.0 PCI bridge: Intel Corporation 5520/5500/X58 I/O Hub PCI Express Root Port 1
lspci -k                      # + jaký ovladač (modul jádra) zařízení používá

lsusb                         # zařízení na sběrnici USB
# Bus 002 Device 006: ID 0624:0249 Avocent Corp. Virtual Keyboard/Mouse
# Bus 002 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
#                        └──┬────┘
#                    výrobce:zařízení (vendor:product)

lsusb -v -d 0624:0249         # detail jednoho zařízení podle ID
usb-devices                   # jiný podrobný výpis USB zařízení
```

> V NDG kontejneru mohou `lspci` / `lsusb` chybět nebo nic nevypsat.

## 1.9 Jak jádro spravuje hardware

| Nástroj | Co dělá |
|---|---|
| **udev** | správce zařízení – vytváří a maže soubory v **`/dev`** podle toho, co se připojí / odpojí |
| **sysfs** | **virtuální** souborový systém v paměti, připojený do **`/sys`** – stav a konfigurace jádra a zařízení |
| **procfs** | **virtuální** souborový systém připojený do **`/proc`** – informace o procesech, hardwaru a jádře |
| **hald** | *HAL daemon* – sledoval připojená zařízení; **zastaralý**, nahrazen udev / systemd |
| **D-Bus** | softwarová sběrnice pro komunikaci mezi procesy (**IPC** – *Interprocess Communication*) |

```bash
ls /dev | head                # soubory zařízení (vytváří udev)
ls /sys/class                 # třídy zařízení (net, block, tty…)
ls /sys/class/net             # síťová rozhraní
ls /proc | head               # čísla = běžící procesy, zbytek = info o systému
cat /proc/version             # verze jádra
```

> Soubory v `/proc` a `/sys` **nejsou na disku** – jádro je generuje „za běhu", když je čteš.
> Proto mají velikost 0 (`ls -l /proc/cpuinfo`), a přesto obsahují data.

## 1.10 Moduly jádra

**Modul jádra** (*kernel module*) je kus softwaru, který jádro **načte za běhu**, typicky **ovladač zařízení** (síťovka, USB, souborový systém). Moduly se obvykle načítají **automaticky** podle připojeného hardwaru.

```bash
lsmod                         # načtené moduly
# Module                  Size  Used by
# dccp                   73728  1 dccp_diag
# └─ název               └─ velikost v B
#                               └─ počet a seznam modulů, které ho používají
lsmod | grep usb

modinfo ext4                  # podrobnosti o modulu: popis, autor, licence, závislosti
modinfo -d ext4               # jen popis

sudo modprobe dummy           # ruční načtení modulu (vč. závislostí)
lsmod | grep dummy
sudo modprobe -r dummy        # odebrání modulu

# seznam VŠECH dostupných modulů pro aktuální jádro
find /lib/modules/$(uname -r) -name '*.ko*' | head
```

> ⚠️ **Opravy oproti slidům:**
> - `modprobe -l` (výpis dostupných modulů) v současných distribucích **neexistuje** – použij `find /lib/modules/$(uname -r) -name '*.ko*'`.
> - Ve slidech je text u `modprobe` prohozený – ukázka `modprobe -l` patří k větě o seznamu modulů, ne k ručnímu načtení.
> - V kontejneru NDG `modprobe` nejspíš **nepůjde** (kontejner nemůže měnit jádro hostitele).

---

# 2. File Permissions (oprávnění)

## 2.1 Uživatelé a skupiny

Každý soubor má **vlastníka (uživatele)** a **skupinu**. Kdo soubor vytvoří, ten ho vlastní; skupinou se stane jeho **primární skupina**.

```bash
id                            # kdo jsem a v jakých skupinách
# uid=1001(sysadmin) gid=1001(sysadmin) groups=1001(sysadmin),4(adm),27(sudo)
#     └ moje UID       └ primární skupina   └ všechny skupiny
id root
whoami                        # jen jméno
groups                        # jen skupiny
# sysadmin adm sudo
```

## 2.2 `su` a `sudo` – práce jako jiný uživatel

| | `su` | `sudo` |
|---|---|---|
| co dělá | otevře **nový shell** jako jiný uživatel (výchozí root) | spustí **jeden příkaz** jako jiný uživatel (výchozí root) |
| čí heslo | **cílového** uživatele (rootovo) | **moje** |
| syntaxe | `su [VOLBY] [UZIVATEL]` | `sudo [VOLBY] PRIKAZ` |
| ukončení | `exit` | po provedení příkazu |

```bash
sudo whoami                   # root
sudo cat /etc/shadow | head -3

su - sysadmin                 # nový login shell jako sysadmin (heslo netlab123)
exit
```

Login shell (`su -`, `su -l`, `su --login`) **načte prostředí cílového uživatele** (`PATH`, domovský adresář…) – doporučená varianta.

> ⚠️ Ve slidech je `su –` s typografickou pomlčkou – v terminálu musí být **`su -`**.
>
> 💡 V praxi se preferuje `sudo` – každý admin používá **svůj účet**, je dohledatelné, kdo co udělal
> (`/var/log/auth.log`), a nikdo nemusí znát rootovo heslo.

## 2.3 Změna vlastníka – `chown`, `chgrp`, `newgrp`

```bash
cd ~/cv06
touch nullfile
ls -l nullfile
# -rw-rw-r-- 1 sysadmin sysadmin 0 Oct 29 17:30 nullfile

sudo chown root nullfile              # změna vlastníka – JEN root
ls -l nullfile
# -rw-rw-r-- 1 root sysadmin 0 Oct 29 17:30 nullfile

sudo chown root:adm nullfile          # vlastník i skupina najednou
sudo chown :sysadmin nullfile         # jen skupina
sudo chown -R sysadmin:sysadmin ~/cv06  # rekurzivně celý adresář
```

**Změna skupiny** – `chgrp` (vlastník souboru smí změnit skupinu na **jinou svou** skupinu, root na libovolnou):

```bash
touch soubor.txt
chgrp adm soubor.txt                  # bez sudo – jsem členem adm
ls -l soubor.txt
```

**Dočasná změna primární skupiny** – `newgrp` (nové soubory pak dostanou tuto skupinu):

```bash
newgrp adm                            # otevře nový shell s primární skupinou adm
id                                    # gid=4(adm)
touch newfile.txt
ls -l newfile.txt
# -rw-rw-r-- 1 sysadmin adm 0 Oct 29 20:00 newfile.txt
exit                                  # zpět do původního shellu
```

> Ve slidech chybí krok `touch newfile.txt` mezi `newgrp adm` a `ls -l`.

## 2.4 Čtení oprávnění v `ls -l`

```
-rwxr-xr-x 1 root root 133792 Jan 18 2018 /bin/ls
│└┬┘└┬┘└┬┘   └─┬┘ └─┬┘
│ │  │  │      │    └─ skupina vlastník
│ │  │  │      └─ uživatel vlastník
│ │  │  └─ ostatní (others)  r-x
│ │  └─ skupina (group)      r-x
│ └─ vlastník (user)         rwx
└─ typ souboru (- soubor, d adresář, l odkaz…)
```

**Tři sady oprávnění:**

| Sada | Pro koho |
|---|---|
| **u** (*user*) | vlastník souboru |
| **g** (*group*) | členové skupiny, která soubor vlastní |
| **o** (*others*) | **všichni ostatní** – kdo není vlastník ani ve skupině |

> Systém vyhodnocuje **jen jednu sadu**: jsem vlastník → platí `u`; jinak jsem ve skupině → `g`; jinak → `o`.
> Vlastník s `---` tedy soubor nepřečte, i když `o` má `r--`.

Viz také [význam sloupců `ls -l` v cvičení 03](../03/README.md#význam-sloupců-ls--l).

## 2.5 Co znamená `r`, `w`, `x` – soubor vs. adresář

| Oprávnění | Soubor | Adresář |
|---|---|---|
| **r** (*read*) | číst a kopírovat obsah | **vypsat jména** souborů (`ls`) – bez dalších detailů |
| **w** (*write*) | měnit obsah | **přidávat a mazat** soubory v adresáři |
| **x** (*execute*) | **spustit** jako program | **vstoupit** (`cd`) a používat adresář v cestě |

> ⚠️ **Smazání souboru** závisí na právech k **adresáři** (`w` + `x`), ne k souboru samotnému!

Vyzkoušej:

```bash
cd ~/cv06
mkdir test_dir
echo "tajne" > test_dir/a.txt

chmod u-x test_dir            # adresář bez x
ls test_dir                   # jména vidím (ls: cannot access ... u detailů)
cd test_dir                   # Permission denied
cat test_dir/a.txt            # Permission denied – bez x nejde přes adresář

chmod u=x test_dir            # jen x, bez r
ls test_dir                   # Permission denied – nevypíšu obsah
cat test_dir/a.txt            # tajne – když znám jméno, dostanu se k souboru!

chmod u=rx test_dir           # r + x, bez w
rm test_dir/a.txt             # Permission denied – bez w nesmažu
touch test_dir/b.txt          # Permission denied

chmod u=rwx test_dir          # zpět
```

## 2.6 `chmod` – změna oprávnění

```
chmod MODE SOUBOR…
```

Měnit oprávnění smí **vlastník souboru** nebo **root**. Dva způsoby zápisu:

### Symbolický způsob (relativní)

**Kdo** + **operátor** + **oprávnění**:

| Kdo | | Operátor | | Oprávnění |
|---|---|---|---|---|
| `u` vlastník | | `+` přidat | | `r` čtení |
| `g` skupina | | `-` odebrat | | `w` zápis |
| `o` ostatní | | `=` nastavit přesně | | `x` spuštění |
| `a` všichni | | | | |

| Příklad | Význam |
|---|---|
| `chmod u+x myscript` | přidá **spuštění** vlastníkovi |
| `chmod g-w file1` | odebere **zápis** skupině |
| `chmod o=r,g-w,u+x myscript` | ostatním **jen čtení**, skupině odebere zápis, vlastníkovi přidá spuštění |
| `chmod a= file1` | **nikdo nic** (`---------`) |
| `chmod a+r file1` | všichni smí číst |
| `chmod -R g+w adresar` | rekurzivně celý adresář |

> Ve slidech je `chmod a=- file1` – správně **`chmod a= file1`** (nebo `chmod a-rwx file1`).

### Osmičkový způsob (numerický)

Každé oprávnění má hodnotu, **sečtou se** – a zadávají se **vždy 3 číslice** (vlastník, skupina, ostatní):

| Oprávnění | Hodnota |
|---|---|
| `r` | **4** |
| `w` | **2** |
| `x` | **1** |
| `-` | 0 |

| Číslice | = | Oprávnění |
|---|---|---|
| 7 | 4+2+1 | `rwx` |
| 6 | 4+2 | `rw-` |
| 5 | 4+1 | `r-x` |
| 4 | 4 | `r--` |
| 0 | 0 | `---` |

| Příklad | Výsledek | Typické použití |
|---|---|---|
| `chmod 755 skript.sh` | `rwxr-xr-x` | programy, skripty, adresáře |
| `chmod 644 soubor.txt` | `rw-r--r--` | běžné soubory |
| `chmod 764 myscript` | `rwxrw-r--` | |
| `chmod 744 myscript` | `rwxr--r--` | |
| `chmod 700 ~/privat` | `rwx------` | soukromý adresář |
| `chmod 600 ~/.ssh/id_rsa` | `rw-------` | soukromé klíče |
| `chmod 000 myfile` | `---------` | |

```bash
touch pokus.txt
chmod 640 pokus.txt ; ls -l pokus.txt     # -rw-r-----
chmod u+x,o+r pokus.txt ; ls -l pokus.txt # -rwxr--r--
stat -c '%a %A %n' pokus.txt              # 744 -rwxr--r-- pokus.txt  ← osmičkově i symbolicky
```

## 2.7 Speciální oprávnění – setuid, setgid, sticky bit

| Oprávnění | Na čem | Symbol | Osmičkově | Co dělá |
|---|---|---|---|---|
| **setuid** | spustitelný soubor | `s` místo `x` u **vlastníka** (`u+s`) | **4000** | program běží s právy **vlastníka souboru**, ne toho, kdo ho spustil |
| **setgid** | spustitelný soubor | `s` místo `x` u **skupiny** (`g+s`) | **2000** | program běží s právy **skupiny souboru** |
| **setgid** | adresář | `s` místo `x` u **skupiny** (`g+s`) | **2000** | nové soubory uvnitř dostanou **skupinu adresáře** |
| **sticky bit** | adresář | `t` místo `x` u **ostatních** (`o+t`) | **1000** | soubory smí mazat jen jejich **vlastník**, vlastník adresáře nebo root |

> Malé **`s` / `t`** = speciální oprávnění **i** `x` je nastaveno.
> Velké **`S` / `T`** = speciální oprávnění je nastaveno, ale **`x` chybí** (většinou chyba v nastavení).

### setuid – příklad `passwd`

```bash
ls -l /usr/bin/passwd
# -rwsr-xr-x 1 root root 59640 Jan 25 2018 /usr/bin/passwd
#     ^ s místo x
```

Hesla jsou v `/etc/shadow`, kam smí zapisovat **jen root**. Přesto si běžný uživatel může změnit heslo – `passwd` má setuid, takže běží **s právy roota**.

```bash
ls -l /etc/shadow                             # -rw-r----- root shadow – sysadmin nemá zápis
find /usr/bin -perm -4000 2>/dev/null         # všechny setuid programy
```

```bash
cp /bin/ls ~/cv06/mujls
chmod u+s mujls ; ls -l mujls     # -rwsr-xr-x  (symbolicky přidat)
chmod u-s mujls ; ls -l mujls     # -rwxr-xr-x  (symbolicky odebrat)
chmod 4755 mujls ; ls -l mujls    # -rwsr-xr-x  (numericky přidat: 4000 + 755)
chmod 0755 mujls ; ls -l mujls    # -rwxr-xr-x  (numericky odebrat)
```

> 💡 Proto jádro **ignoruje setuid u skriptů** – viz [cvičení 05](../05/README.md#oprávnění). Setuid je silný a nebezpečný nástroj.

### setgid na adresáři – sdílený adresář týmu

```bash
sudo mkdir /tmp/data
sudo chgrp adm /tmp/data
sudo chmod 2775 /tmp/data             # nebo: sudo chmod g+s /tmp/data
ls -ld /tmp/data
# drwxrwsr-x 2 root adm 4096 Oct 29 23:20 /tmp/data
#       ^ s u skupiny

touch /tmp/data/novy.txt
ls -l /tmp/data/novy.txt
# -rw-rw-r-- 1 sysadmin adm ...   ← skupina adm (z adresáře), ne sysadmin

sudo chmod g-s /tmp/data              # odebrání (nebo: sudo chmod 0775 /tmp/data)
```

### sticky bit – příklad `/tmp`

```bash
ls -ld /tmp
# drwxrwxrwt 1 root root 0 Oct 17 19:17 /tmp
#          ^ t u ostatních
```

Do `/tmp` smí zapisovat **všichni** (`rwx` pro ostatní), ale díky sticky bitu nikdo **nesmaže cizí soubory**.

```bash
mkdir ~/cv06/sdilene
chmod 1777 ~/cv06/sdilene ; ls -ld ~/cv06/sdilene   # drwxrwxrwt
chmod o-t ~/cv06/sdilene ; ls -ld ~/cv06/sdilene    # drwxrwxrwx
chmod o+t ~/cv06/sdilene                            # zpět
```

### Shrnutí příkazů

| | Přidat symbolicky | Přidat osmičkově | Odebrat |
|---|---|---|---|
| setuid | `chmod u+s soubor` | `chmod 4755 soubor` | `chmod u-s` / `chmod 0755` |
| setgid | `chmod g+s soubor/adresar` | `chmod 2775 …` | `chmod g-s` / `chmod 0775` |
| sticky | `chmod o+t adresar` | `chmod 1777 adresar` | `chmod o-t` / `chmod 0777` |

> Čtvrtá (první) číslice se sčítá stejně: `6755` = setuid + setgid, `0` = žádné speciální.

## 2.8 `umask` – výchozí oprávnění nových souborů

`umask` určuje, **jaká oprávnění se ODEBEROU** novým souborům a adresářům při vytvoření. Na už existující soubory ani na setuid / setgid / sticky nemá vliv.

| Typ | Maximum | Symbolicky |
|---|---|---|
| soubor | **666** | `rw-rw-rw-` (soubory nikdy nedostanou `x` automaticky) |
| adresář | **777** | `rwxrwxrwx` |

**Výsledné oprávnění = maximum − umask**

| umask | Soubor | Adresář | Použití |
|---|---|---|---|
| `002` | 666−002 = **664** `rw-rw-r--` | 777−002 = **775** `rwxrwxr-x` | Ubuntu – běžný uživatel (skupina smí zapisovat) |
| `022` | **644** `rw-r--r--` | **755** `rwxr-xr-x` | root, mnoho distribucí |
| `077` | **600** `rw-------` | **700** `rwx------` | soukromé – nikdo jiný nic |
| `027` | **640** `rw-r-----` | **750** `rwxr-x---` | skupina čte, ostatní nic |

```bash
umask                         # 0002
umask -S                      # u=rwx,g=rwx,o=rx  (symbolicky)
touch a.txt ; mkdir a_dir
ls -ld a.txt a_dir            # -rw-rw-r--  drwxrwxr-x

umask 077                     # změna jen pro aktuální shell
touch b.txt ; mkdir b_dir
ls -ld b.txt b_dir            # -rw-------  drwx------
umask 002                     # zpět
```

> Trvale se `umask` nastavuje v `~/.bashrc`.
> (Přesně řečeno se umask neodečítá, ale „maskuje" bitově – pro běžné hodnoty jako výše to vychází stejně.)

---

# 3. Filesystem Links (odkazy)

**Odkaz** (*link*) umožňuje přistupovat k jednomu souboru přes **více jmen**. Dva typy: **pevné** (*hard*) a **měkké / symbolické** (*soft / symbolic*).

## 3.1 Nejdřív: co je inode

Soubor se v Linuxu skládá ze dvou částí:

```
 jméno v adresáři            inode č. 95813671              data na disku
┌──────────────┐          ┌──────────────────────┐       ┌──────────────┐
│ profile.txt ─┼─────────►│ vlastník, práva,     │──────►│ Hello my     │
└──────────────┘          │ velikost, časy,      │       │ name is Joe… │
                          │ počet odkazů: 1,     │       └──────────────┘
                          │ kde leží data        │
                          └──────────────────────┘
```

- **inode** = záznam s **metadaty** souboru (vše kromě jména) a odkazem na data. Má **číslo**.
- **jméno** souboru je jen **položka v adresáři**, která ukazuje na inode.

```bash
ls -i ~/cv06                  # čísla inodů
stat ~/Documents/profile.txt  # všechna metadata, vč. Inode a Links
```

## 3.2 Pevný odkaz (hard link)

Pevný odkaz = **další jméno pro stejný inode**. Obě jména jsou **naprosto rovnocenná** – žádné není „originál".

```
 profile.txt   ─┐
                ├──► inode 95813671 (Links: 2) ──► data
 myprofile.txt ─┘
```

```
ln CIL JMENO_ODKAZU           # bez -s
```

```bash
cd ~/cv06
cp ~/Documents/profile.txt .
ls -l profile.txt
# -rw-r--r-- 1 sysadmin sysadmin 110 Oct 29 16:24 profile.txt
#            └ počet pevných odkazů = 1

ln profile.txt myprofile.txt
ls -li profile.txt myprofile.txt
# 95813671 -rw-r--r-- 2 sysadmin sysadmin 110 Oct 29 16:24 myprofile.txt
# 95813671 -rw-r--r-- 2 sysadmin sysadmin 110 Oct 29 16:24 profile.txt
# └─ stejný inode          └─ už 2 odkazy

echo "Novy radek" >> myprofile.txt
tail -1 profile.txt           # Novy radek  ← je to TENTÝŽ soubor

rm profile.txt                # smaže jen jedno jméno
cat myprofile.txt             # data jsou pořád tady
ls -l myprofile.txt           # počet odkazů zase 1
```

> Data se smažou, až když zmizí **poslední** pevný odkaz (počet odkazů klesne na 0).

## 3.3 Měkký (symbolický) odkaz (soft / symlink)

Symbolický odkaz = **samostatný malý soubor**, který obsahuje **cestu** k jinému souboru. Funguje jako **zástupce** (*shortcut*) ve Windows.

```
 file2.txt (vlastní inode, typ l) ──"file1.txt"──► file1.txt ──► inode ──► data
```

```
ln -s CIL JMENO_ODKAZU
```

```bash
cd ~/cv06
echo "Obsah" > file1.txt
ln -s file1.txt file2.txt
ls -l file*
# -rw-rw-r-- 1 sysadmin sysadmin 6 Oct 29 02:48 file1.txt
# lrwxrwxrwx 1 sysadmin sysadmin 9 Oct 29 02:49 file2.txt -> file1.txt
# ^ typ l                        ^ velikost 9 B = délka textu "file1.txt"

cat file2.txt                 # Obsah  ← čte se přes odkaz
ls -li file1.txt file2.txt    # RŮZNÉ inody
readlink file2.txt            # file1.txt – kam odkaz vede

# poškozený (broken) odkaz
rm file1.txt
ls -l file2.txt               # odkaz zůstal (barevně červeně), ale cíl neexistuje
cat file2.txt                 # No such file or directory
```

> - Symlink má vždy oprávnění `lrwxrwxrwx` – rozhodují **oprávnění cíle**.
> - Symlink **nezvyšuje** počet odkazů cílového souboru.
> - Relativní cesta v symlinku se počítá **od umístění odkazu**, ne od aktuálního adresáře.

Symlinky v systému:

```bash
ls -l /bin                    # lrwxrwxrwx … /bin -> usr/bin
ls -l /bin/systemd 2>/dev/null
# lrwxrwxrwx 1 root root 20 Feb 28 21:03 /bin/systemd -> /lib/systemd/systemd
ls -l /etc/alternatives | head
find /usr/bin -type l | head  # všechny symlinky v /usr/bin
```

Typické použití: **zkratky** k hluboko zanořeným adresářům, a když vývojáři **přesunou** soubor jinam – na starém místě nechají symlink, aby staré cesty fungovaly dál.

```bash
ln -s /var/log ~/logy         # zkratka na adresář
cd ~/logy && pwd              # /home/sysadmin/logy
pwd -P                        # /var/log – skutečná cesta
cd ~
```

## 3.4 Pevný vs. symbolický odkaz

| | Pevný (`ln`) | Symbolický (`ln -s`) |
|---|---|---|
| co to je | další **jméno** pro stejný inode | samostatný soubor s **cestou** k cíli |
| inode | **stejný** jako cíl | **vlastní** |
| v `ls -l` | vypadá jako běžný soubor, počet odkazů > 1 | typ `l`, šipka `->` na cíl |
| na **adresář** | ❌ nejde | ✅ jde |
| přes **jiný souborový systém** (oddíl, disk) | ❌ nejde | ✅ jde |
| smazání cíle | data **zůstanou** (dokud existuje aspoň jedno jméno) | odkaz **přestane fungovat** (broken link) |
| přesun cíle | funguje dál | rozbije se (u relativní cesty i při přesunu odkazu) |
| programy ho poznají? | **ne** – nerozeznatelný od běžného souboru | ano (`ls -l`, `readlink`, `test -L`) |

**Výhody symbolických odkazů:** fungují na adresáře, přes různé souborové systémy, a v `ls -l` je hned vidět, kam vedou.

**Výhody pevných odkazů:** programy je nerozeznají od běžného souboru, nemohou se „rozbít" a data nezmizí, dokud neodstraníš všechny odkazy.

Hledání odkazů:

```bash
find ~ -samefile ~/cv06/myprofile.txt   # všechny pevné odkazy na stejný inode
find ~ -inum 95813671                   # totéž podle čísla inode
find ~ -type l                          # všechny symlinky
find ~ -xtype l                         # jen POŠKOZENÉ symlinky
```

---

# Úlohy k procvičení

Pracuj v `~/cv06`.

### 1. Hardware Configuration

1. Zjisti model procesoru, počet jader a architekturu.
2. Kolik má systém celkem RAM a kolik je reálně k dispozici? Vypiš to čitelně.
3. Zjisti verzi jádra.
4. Vypiš, které moduly jádra jsou načtené, a spočítej je.
5. Zjisti popis a licenci modulu `ext4` (nebo jiného z `lsmod`).
6. Zjisti, jaké disky a oddíly systém vidí a jak jsou zaplněné.
7. Vypiš síťová rozhraní z `/sys/class/net`.

### 2. File Permissions

8. Zjisti své UID, primární skupinu a všechny skupiny.
9. Vytvoř `skript.sh` a nastav mu `rwxr-x---` – jednou symbolicky, jednou osmičkově.
10. Vytvoř `tajne.txt`, ke kterému má přístup **jen vlastník** (čtení a zápis).
11. Co znamená `chmod 754`? Napiš symbolicky. A co `rw-r-----` osmičkově?
12. Vytvoř adresář `~/cv06/zkouska` a soubor v něm. Odeber adresáři právo `w` a zkus soubor smazat. Proč to nejde?
13. Změň vlastníka souboru `nullfile` na `root` a skupinu na `adm`. Vrať zpět.
14. Najdi v `/usr/bin` všechny programy se setuid. Proč ho má `passwd`?
15. Vytvoř sdílený adresář `/tmp/tym` se skupinou `adm`, do kterého smí všichni ze skupiny zapisovat, nové soubory dostanou skupinu `adm` a nikdo nesmaže cizí soubor.
16. Nastav `umask` tak, aby nové soubory měly `rw-r-----`. Ověř a vrať zpět.

### 3. Filesystem Links

17. Vytvoř `original.txt` a pevný odkaz `kopie_hard.txt`. Ověř, že mají stejný inode a počet odkazů 2.
18. Vytvoř symbolický odkaz `kopie_soft.txt` na `original.txt`. Porovnej inody.
19. Smaž `original.txt`. Který z odkazů stále funguje a proč?
20. Vytvoř v domovském adresáři symlink `dokumenty`, který vede na `~/Documents`.
21. Zkus vytvořit pevný odkaz na adresář `/etc`. Co se stane?
22. Najdi v `~` všechny poškozené symlinky.

<details>
<summary>Řešení</summary>

```bash
cd ~/cv06

# 1
lscpu | grep -E 'Model name|^CPU\(s\)|Architecture'

# 2
free -h                       # total a available

# 3
uname -r

# 4
lsmod
lsmod | tail -n +2 | wc -l    # bez hlavičky

# 5
modinfo -d ext4
modinfo -l ext4

# 6
lsblk
df -h

# 7
ls /sys/class/net

# 8
id

# 9
touch skript.sh
chmod u=rwx,g=rx,o= skript.sh
chmod 750 skript.sh
ls -l skript.sh               # -rwxr-x---

# 10
touch tajne.txt
chmod 600 tajne.txt           # rw-------

# 11
# 754 = rwxr-xr--
# rw-r----- = 640

# 12
mkdir zkouska ; touch zkouska/soubor
chmod u-w zkouska
rm zkouska/soubor             # Permission denied – mazání = změna adresáře → potřebuje w na adresáři
chmod u+w zkouska

# 13
touch nullfile
sudo chown root:adm nullfile
ls -l nullfile
sudo chown sysadmin:sysadmin nullfile

# 14
find /usr/bin -perm -4000 2>/dev/null
ls -l /usr/bin/passwd         # -rwsr-xr-x – musí zapisovat do /etc/shadow, kam smí jen root

# 15
sudo mkdir /tmp/tym
sudo chgrp adm /tmp/tym
sudo chmod 3775 /tmp/tym      # 2000 setgid + 1000 sticky + 775
ls -ld /tmp/tym               # drwxrwsr-t

# 16
umask 027
touch maska.txt ; ls -l maska.txt    # -rw-r-----
umask 002

# 17
echo "Ahoj" > original.txt
ln original.txt kopie_hard.txt
ls -li original.txt kopie_hard.txt

# 18
ln -s original.txt kopie_soft.txt
ls -li original.txt kopie_soft.txt   # různé inody, kopie_soft.txt -> original.txt

# 19
rm original.txt
cat kopie_hard.txt            # Ahoj – stejný inode, data existují dál
cat kopie_soft.txt            # No such file or directory – ukazuje na jméno, které zmizelo

# 20
ln -s ~/Documents ~/dokumenty
ls -l ~/dokumenty
ls ~/dokumenty/

# 21
ln /etc ~/etc_hard            # ln: /etc: hard link not allowed for directory

# 22
find ~ -xtype l
```
</details>

---

# Tahák

### Hardware

| Potřebuju… | Příkaz |
|---|---|
| info o CPU | `lscpu`, `cat /proc/cpuinfo`, `nproc` |
| info o RAM | `free -h`, `cat /proc/meminfo` |
| verze jádra / architektura | `uname -r`, `uname -m`, `uname -a` |
| disky a oddíly | `lsblk`, `df -h` |
| PCI / USB zařízení | `lspci [-k]`, `lsusb [-v -d ID]`, `usb-devices` |
| přerušení, IO porty, DMA | `/proc/interrupts`, `/proc/ioports`, `/proc/dma` |
| načtené moduly | `lsmod` |
| info o modulu | `modinfo modul` |
| načíst / odebrat modul | `sudo modprobe modul`, `sudo modprobe -r modul` |
| všechny dostupné moduly | `find /lib/modules/$(uname -r) -name '*.ko*'` |

### Oprávnění

| Potřebuju… | Příkaz |
|---|---|
| kdo jsem, skupiny | `id`, `whoami`, `groups` |
| příkaz jako root / shell jako jiný uživatel | `sudo prikaz`, `su - uzivatel` |
| změnit vlastníka / skupinu | `sudo chown user:group soubor`, `chgrp group soubor` |
| dočasně jiná primární skupina | `newgrp skupina` |
| přidat / odebrat právo | `chmod u+x`, `chmod g-w`, `chmod o=r`, `chmod a=` |
| nastavit osmičkově | `chmod 755` (`rwxr-xr-x`), `644` (`rw-r--r--`), `600`, `700` |
| r / w / x hodnoty | 4 / 2 / 1 |
| setuid / setgid / sticky | `u+s` (4000), `g+s` (2000), `o+t` (1000) |
| najít setuid programy | `find / -perm -4000 2>/dev/null` |
| oprávnění osmičkově | `stat -c '%a %n' soubor` |
| výchozí oprávnění | `umask`, `umask 022` (soubory 666−, adresáře 777−) |

### Odkazy

| Potřebuju… | Příkaz |
|---|---|
| pevný odkaz | `ln cil jmeno` |
| symbolický odkaz | `ln -s cil jmeno` |
| číslo inode | `ls -i`, `stat soubor` |
| kam vede symlink | `ls -l`, `readlink odkaz` |
| všechny pevné odkazy na soubor | `find / -samefile soubor` |
| všechny / poškozené symlinky | `find kde -type l` / `find kde -xtype l` |

---

# Příprava na cvičení 07

Samostudium, splněné laby a testy z modulu:

- **Linux Essentials – Module 14 – Network Configuration**
