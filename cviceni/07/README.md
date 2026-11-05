# Cvičení 07 – Síť: základy, konfigurace a diagnostika

Podle **NDG Linux Essentials** a labů **Linux II.**:

- **Module 14 – Network Configuration**
- Linux II. – **13 Networking Fundamentals**, **14 Network Configuration**, **15 Network Troubleshooting**

**Vstupní požadavky:** samostudium Module 14, splněné *Lab 14 + Chapter 14 Exam* a Exams z předchozích modulů.

> 📌 **Nezapomeň:** **cvičení 08 bude samostudium** (podle posledního slidu) – viz [Příprava na cvičení 08](#příprava-na-cvičení-08).
>
> Vyučující na cvičení prosí o vyplnění dotazníku: <https://forms.gle/sYCqibNuUcWfC5XF6>

Vše si zkoušíme v laboratorním prostředí **NDG NETLAB+** na [portal.netdevgroup.com](https://portal.netdevgroup.com/).

---

## 0. Příprava prostředí

1. Přihlas se na [portal.netdevgroup.com](https://portal.netdevgroup.com/) a spusť **Lab 14**.
2. Jsi přihlášen jako **`sysadmin`**, heslo pro `sudo` je **`netlab123`**.
3. Pracovní adresář:

```bash
mkdir -p ~/cv07
cd ~/cv07
```

> ⚠️ **Omezení NDG labu:**
>
> - Lab běží v **kontejneru bez přístupu na internet**. `ping 8.8.8.8`, `dig google.com`, `traceroute`
>   ven apod. **neprojdou** – i to je ale užitečné vidět (jak vypadá chyba).
> - Změny konfigurace (`ip addr add`, `route add`, `hostname nové_jméno`…) mohou skončit chybou
>   `Operation not permitted` – kontejner nemusí mít právo měnit síť. **Neměň nastavení `eth0`** –
>   mohl bys labu odříznout síť (pomůže pak jen restart labu). Příkazy, které síť mění, jsou v návodu
>   označené jako **„jen ukázka"**.
> - Některé nástroje (`nmcli`, `hostnamectl`, `resolvectl`, `ethtool`, `lshw`, `nc`, `traceroute`)
>   v labu nemusí být nainstalované. `apt install` nefunguje (není internet).
> - Výstupy ve slidech jsou **přeložené do češtiny** – v terminálu budou **anglicky**
>   (`Kernel IP routing table`, ne „Směrovací tabulka IP jádra"). Klíčová slova v konfiguračních
>   souborech se **nepřekládají** nikdy (`nameserver`, `search`, `dhcp4: true`…).

---

# 1. Networking Fundamentals

## 1.1 Co počítač potřebuje, aby byl v síti

Síť je potřeba pro aktualizace softwaru i pro služby (sdílení souborů, web, e-mail…).
Aby se systém připojil, musí mít nastavené **tři věci**:

| Co | K čemu | Příklad | Jak zjistím |
|---|---|---|---|
| **IP adresa + maska** | „moje adresa" a jak velká je moje síť | `192.168.1.2/24` | `ip addr`, `ifconfig` |
| **Výchozí brána** (gateway) | kam posílat pakety **mimo** moji síť | `192.168.1.1` | `ip route`, `route -n` |
| **DNS server** | kdo mi přeloží jméno (`google.com`) na IP adresu | `8.8.8.8` | `cat /etc/resolv.conf` |

Nastavit je jde **ručně (staticky)**, nebo je počítač dostane **automaticky přes DHCP**
(typicky doma od Wi-Fi routeru, ve firmě od DHCP serveru).

### Veřejné a privátní adresy

- **Veřejná adresa** je v celém internetu **jedinečná** a je z internetu dosažitelná. Přiděluje ji
  IANA → regionální registr (pro Evropu **RIPE NCC**) → poskytovatel internetu.
- **Privátní adresa** je vyčleněná pro **vnitřní sítě** (domácnost, firma, škola, NDG lab).
  Stejné privátní adresy používají miliony sítí najednou, proto se do internetu **nesměrují**.
  Ven se jde přes router, který je přeloží na svou veřejnou adresu (**NAT**).

Pro veřejné sítě není vyčleněný jeden konkrétní rozsah. **Veřejná je každá adresa, která není
v tabulce níže**, např. `8.8.8.8` (DNS Googlu) nebo `1.1.1.1` (DNS Cloudflare).

**Rozsahy vyhrazené pro speciální účely (RFC 1918, RFC 6890):**

| Rozsah | K čemu je vyčleněný | Veřejný? |
|---|---|---|
| `10.0.0.0/8` (10.0.0.0 – 10.255.255.255) | **privátní** – velké sítě (firmy) | ❌ |
| `172.16.0.0/12` (172.16.0.0 – 172.31.255.255) | **privátní** – střední sítě, Docker | ❌ |
| `192.168.0.0/16` (192.168.0.0 – 192.168.255.255) | **privátní** – domácí a malé sítě | ❌ |
| `100.64.0.0/10` | **CGNAT** – sdílené adresy u poskytovatele (mobilní data, někteří ISP) | ❌ |
| `127.0.0.0/8` (127.0.0.0 – 127.255.255.255) | **loopback** – „já sám", rozhraní `lo`; nejpoužívanější je `127.0.0.1` = jméno **`localhost`** (viz níže) | ❌ |
| `169.254.0.0/16` | **link-local** – nedostal jsem adresu od DHCP | ❌ |
| `192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24` | **dokumentace** – pro příklady v návodech a učebnicích | ❌ |
| `224.0.0.0/4` (224 – 239) | **multicast** – vysílání skupině počítačů | ❌ |
| `240.0.0.0/4` (240 – 255) | rezervováno (`255.255.255.255` = broadcast) | ❌ |
| **všechno ostatní** | **veřejné adresy** | ✅ |

> 💡 **Jak poznám, že jsem za NAT:** `ip addr` ukáže privátní adresu (např. `192.168.1.2`), ale web
> typu *ifconfig.me* ukáže jinou, **veřejnou** – to je adresa routeru. Dostanu-li od poskytovatele
> na routeru adresu ze `100.64.0.0/10`, jsem za NAT ještě jednou (CGNAT) a zvenku se ke mně
> nikdo nepřipojí.

**Proč musí mít domácí (firemní, školní) síť privátní adresy:**

1. **Veřejné adresy nejsou moje.** Každou veřejnou adresu už někdo vlastní (Google, banka, jiný
   poskytovatel). Kdybych si doma nastavil třeba `8.8.8.8`, můj počítač by si myslel, že Google je
   v mé síti, a posílal by dotazy sobě místo Googlu – Google by pro mě přestal fungovat.
   Privátní rozsahy nevlastní nikdo, takže **nikomu nekonfliktuji**.
2. **Veřejných IPv4 adres je málo.** IPv4 má jen ~4,3 miliardy adres a zařízení je víc než lidí na Zemi
   (telefon, notebook, televize, tiskárna…). Volné IPv4 adresy došly kolem roku 2011–2019
   (RIPE NCC rozdal poslední blok v roce 2019). Domácnost proto dostane od poskytovatele **jednu**
   veřejnou adresu (nebo ani tu – CGNAT) a všechna zařízení za routerem sdílí tu jednu přes **NAT**.
3. **Privátní adresy můžou používat všichni zároveň.** Já doma mám `192.168.1.10`, soused taky
   `192.168.1.10` – nevadí to, protože tyto adresy se **nikdy nedostanou do internetu**: routery
   poskytovatelů pakety s privátní adresou zahazují a NAT na mém routeru je přepíše na veřejnou adresu.
4. **Bezpečnost jako bonus.** Zařízení s privátní adresou **není přímo dosažitelné z internetu** – kdo
   zvenku neví, za kterým routerem a na kterém portu je, nemá jak se k tiskárně nebo kameře připojit,
   pokud ho router sám nepustí (přesměrování portu). Není to ale náhrada firewallu.

```
   domácí síť (privátní)                       internet (veřejné)
   notebook  192.168.1.10 ─┐
   telefon   192.168.1.11 ─┼─► router ── NAT ──► 85.70.x.x ──► 8.8.8.8
   tiskárna  192.168.1.20 ─┘   192.168.1.1        (1 veřejná adresa
                               (brána)             pro celou domácnost)
```

> 💡 Proto má skoro každý domácí router adresu `192.168.0.1` nebo `192.168.1.1` a NDG lab
> `192.168.1.x` – všechny ty sítě vedle sebe existují bez problému.
>
> **IPv6** tento problém nemá – adres je tolik, že každé zařízení může mít vlastní veřejnou.
> I tam ale existuje obdoba privátních adres (`fc00::/7`) a vždy link-local `fe80::/10`.

### Loopback a `localhost`

Celý rozsah **`127.0.0.0/8`** (127.0.0.0 – 127.255.255.255, ~16,7 milionu adres) je vyhrazený pro
**loopback** – pakety neodejdou ze síťové karty, ale „otočí se" uvnitř počítače a vrátí se zpět
na stejný počítač. Funguje i bez síťové karty a bez kabelu.

- Prakticky se používá **`127.0.0.1`** – a místo ní jde psát jméno **`localhost`**.
  Překlad zajišťuje `/etc/hosts` (řádek `127.0.0.1 localhost`), takže funguje i bez DNS.
- Odpovídá na **jakoukoliv** adresu z rozsahu – `ping 127.0.0.1`, `ping 127.1.2.3` i `ping localhost`
  dopadnou stejně.
- V IPv6 je loopback jen jedna adresa: **`::1`** (v `/etc/hosts` jako `::1 localhost ip6-localhost`).

```bash
ping -c 2 localhost          # = ping 127.0.0.1
ping -c 2 127.5.5.5          # i tohle je loopback
ip addr show lo              # inet 127.0.0.1/8 scope host lo
grep localhost /etc/hosts    # 127.0.0.1 localhost  /  ::1 localhost ip6-localhost
getent hosts localhost       # jak se localhost přeloží
```

**K čemu je to dobré:**

| Použití | Příklad |
|---|---|
| test, že funguje síťový stack počítače | `ping localhost` (krok 3 v kapitole 3.1) |
| připojení ke službě na **vlastním** počítači | `ssh localhost`, `nc -zv localhost 22`, v prohlížeči `http://localhost:8080` při vývoji webu |
| služba dostupná **jen lokálně**, ne ze sítě | databáze poslouchá na `127.0.0.1:3306` – zvenku se k ní nikdo nepřipojí (viz `ss -tuln` v kapitole 3.4) |

> ❗ `localhost` je vždy **ten počítač, na kterém příkaz právě běží**. Když se přes `ssh` přihlásíš
> na server a napíšeš `localhost`, myslíš tím **server**, ne svůj notebook.

### Historické třídy adres

V testech se ještě objevují (dnes se místo nich používá prefix `/x`, tzv. CIDR):

| Třída | První oktet | Výchozí maska | Privátní rozsah v této třídě |
|---|---|---|---|
| A | 1 – 126 | `/8` | `10.0.0.0/8` |
| B | 128 – 191 | `/16` | `172.16.0.0/12` |
| C | 192 – 223 | `/24` | `192.168.0.0/16` |
| D | 224 – 239 | – | multicast |
| E | 240 – 255 | – | rezervováno |

(`127` chybí v tabulce záměrně – je to loopback.)

## 1.2 IP adresa a maska

**IPv4 adresa** = 4 čísla 0–255 (oktety), např. `192.168.1.2`. **Maska** říká, která část
adresy je **síť** a která **počítač** (host):

```
IP adresa:   192.168.1.2
maska:       255.255.255.0   = /24 (24 jedniček na začátku)
             └─── síť ───┘└ host
síť:         192.168.1.0/24  → adresy 192.168.1.0 – 192.168.1.255
             192.168.1.0     = adresa sítě (nepoužitelná pro počítač)
             192.168.1.255   = broadcast (všem v síti)
             .1 – .254       = 254 adres pro počítače
```

| Prefix | Maska | Adres v síti | Použitelných pro počítače |
|---|---|---|---|
| `/8` | 255.0.0.0 | 16 777 216 | 16 777 214 |
| `/16` | 255.255.0.0 | 65 536 | 65 534 |
| `/24` | 255.255.255.0 | 256 | 254 |
| `/25` | 255.255.255.128 | 128 | 126 |
| `/26` | 255.255.255.192 | 64 | 62 |
| `/30` | 255.255.255.252 | 4 | 2 (spoj dvou routerů) |
| `/32` | 255.255.255.255 | 1 | jeden konkrétní počítač |

**Speciální adresy** (stručně, celý přehled je v [1.1](#veřejné-a-privátní-adresy)):

| Rozsah | Význam |
|---|---|
| `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` | **privátní** – vnitřní sítě, do internetu se nesměrují (NAT) |
| `127.0.0.0/8` (hlavně `127.0.0.1`) | **loopback** – „já sám", rozhraní `lo` |
| `169.254.0.0/16` | adresa, kterou si počítač dá sám, když **nedostal odpověď od DHCP** – typický příznak problému |
| `0.0.0.0` | „jakákoliv adresa" (v `ss` = poslouchá na všech rozhraních, v route = výchozí trasa) |

**IPv6** – 128bitové adresy psané šestnáctkově, např. `fe80::42:c0ff:fea8:102`.
Loopback je `::1`, adresy začínající `fe80::` jsou **link-local** (platí jen v místní síti).

## 1.3 Směrování a výchozí brána

```
                 stejná síť → posílám PŘÍMO
  [PC 192.168.1.2] ─────────────────────── [PC 192.168.1.50]
         │
         │ jiná síť (internet, 10.x…) → posílám na BRÁNU
         ▼
  [router 192.168.1.1] ──► internet
```

- Cíl je ve **stejné síti** → směrování není potřeba, paket jde přímo.
- Cíl je **jinde** → první „skok" (hop) je **směrovač (brána)** dané sítě.
- O tom rozhoduje **směrovací tabulka** jádra:

```bash
ip route                 # nový způsob
# default via 192.168.1.1 dev eth0
# 192.168.1.0/24 dev eth0 proto kernel scope link src 192.168.1.2

route -n                 # starý způsob (-n = čísla, nepřekládat na jména)
# Kernel IP routing table
# Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
# 0.0.0.0         192.168.1.1     0.0.0.0         UG    0      0        0 eth0
# 192.168.1.0     0.0.0.0         255.255.255.0   U     0      0        0 eth0
```

| Sloupec / příznak | Význam |
|---|---|
| `0.0.0.0` / `default` | **výchozí trasa** – „všechno ostatní" |
| `Gateway 0.0.0.0` nebo `*` | brána není potřeba, síť je přímo připojená |
| `U` | trasa je aktivní (up) |
| `G` | jde se přes bránu (gateway) |
| `H` | trasa k jednomu počítači (host) |
| `Iface` | kterým rozhraním paket odejde |

**Jak jádro vybírá trasu:** vyhraje **nejkonkrétnější** shoda (nejdelší prefix).
Když slidy ukazují v tabulce `192.168.1.0/255.255.255.192` (= /26) i `192.168.1.0/255.255.255.0`
(= /24), pak pro `192.168.1.10` vyhraje `/26`, pro `192.168.1.100` (mimo /26) `/24`.
Výchozí trasa `0.0.0.0/0` je nejméně konkrétní – použije se, až když nic jiného nesedí.

> ⚠️ **Chyba ve slidech („Výchozí trasa"):** po příkazu `route add default gw 192.168.1.1 eth1`
> slidy píší, že paket bude předán na adresu **192.168.1.224**. Správně na **192.168.1.1** –
> to je brána zadaná v příkazu.

## 1.4 DNS – překlad jmen na adresy

**DNS** (Domain Name System) je distribuovaná databáze „jméno → IP adresa" pro celý internet.
Linux při překladu jména postupuje takto:

```
ping server1
   │
   ▼
/etc/nsswitch.conf   řádek  hosts: files dns   ← POŘADÍ
   │
   ├─ 1. files → /etc/hosts       (ruční tabulka, platí jen pro tento počítač)
   └─ 2. dns   → DNS servery z /etc/resolv.conf
```

```bash
cat /etc/hosts
# 127.0.0.1   localhost
# 192.168.1.2 localhost

grep hosts /etc/nsswitch.conf
# hosts:          files dns

cat /etc/resolv.conf
# nameserver 127.0.0.11
```

### Rozdíl mezi `/etc/nsswitch.conf`, `/etc/hosts` a `/etc/resolv.conf`

Všechny tři souvisí s překladem jmen, ale každý odpovídá na **jinou otázku**:

| Soubor | Odpovídá na otázku | Co v něm je | Příklad řádku |
|---|---|---|---|
| **`/etc/nsswitch.conf`** | **V jakém pořadí** a **kde** hledat? | pořadí zdrojů (`files`, `dns`…) – pro jména počítačů, ale i pro uživatele, skupiny… | `hosts: files dns` |
| **`/etc/hosts`** | **Jakou IP má toto jméno?** (odpověď rovnou) | pevná tabulka „IP → jméno" **jen pro tento počítač** | `192.168.1.50 server1` |
| **`/etc/resolv.conf`** | **Koho se zeptat**, když to v `/etc/hosts` není? | adresy **DNS serverů** a doména pro doplnění | `nameserver 8.8.8.8` |

**Přirovnání – hledám telefonní číslo kamaráda:**

- `nsswitch.conf` = můj **postup**: „nejdřív se podívám do svého notesu, pak zavolám na informace".
- `hosts` = můj **vlastní notes** – pár čísel, které si píšu sám; nikdo jiný je nevidí.
- `resolv.conf` = **číslo na informace** (DNS server) – neobsahuje žádná jména, jen komu zavolat.

**Co z toho plyne v praxi:**

| Situace | Který soubor | Proč |
|---|---|---|
| Chci, aby `server1` ukazoval na `192.168.1.50` jen u mě (test, server bez DNS záznamu) | `/etc/hosts` | ruční záznam, má přednost před DNS |
| Nefunguje mi překlad žádných jmen z internetu | `/etc/resolv.conf` | chybí nebo je špatný `nameserver` |
| Záznam v `/etc/hosts` se ignoruje | `/etc/nsswitch.conf` | chybí `files`, nebo je `dns` **před** `files` |
| Chci zablokovat web (např. reklamy) | `/etc/hosts` | `0.0.0.0 reklamy.example.com` – jméno se přeloží na nesmysl |

> ❗ `/etc/hosts` vyhrává jen díky pořadí `files dns` v `nsswitch.conf`. Kdyby tam bylo
> `hosts: dns files`, systém by se nejdřív zeptal DNS serveru.
>
> ❗ `host` a `dig` čtou **jen** `resolv.conf` (ptají se rovnou DNS) – `nsswitch.conf` ani `hosts` neřeší.
> Celou cestu jako běžné programy (`ping`, prohlížeč, `ssh`) projde **`getent hosts jméno`**.
>
> 🔐 Úpravou `/etc/hosts` jde podvrhnout, kam vede třeba `banka.cz` – proto ho smí měnit jen root
> a útočníci (malware) ho rádi upravují. Když se „známý web chová divně", podívej se i sem.

**`/etc/resolv.conf`** – správný zápis (klíčová slova anglicky!):

```
# /etc/resolv.conf
search sample.com            # doplní doménu ke krátkým jménům: www → www.sample.com
nameserver 191.74.10.12      # DNS server (max. 3 řádky nameserver, ptá se v pořadí)
nameserver 8.8.8.8
```

> ⚠️ **Opravy oproti slidům:**
>
> - Ve slidech je `doména sample.com` a `vyhledávání sample.com` – v souboru musí být anglicky
>   **`domain`** a **`search`**. Navíc se `domain` a `search` navzájem vylučují – platí ta,
>   která je v souboru **poslední**, takže stačí jedna z nich.
> - `sortlist` je reálná, ale v praxi skoro nepoužívaná volba – nemusíš ji znát.

Na moderních systémech se soubor často **generuje automaticky** (DHCP, NetworkManager,
systemd-resolved) – ruční úprava se pak při dalším připojení přepíše.

### Dotazy na DNS – `host`, `dig`, `getent`

```bash
host example.com             # jméno → IP
host 173.230.129.147         # IP → jméno (zpětný / reverse dotaz)
host -t ns sample.com        # DNS servery domény (NS záznamy)
host -t mx sample.com        # poštovní servery (MX záznamy)

dig example.com              # podrobný výpis (pro ladění DNS)
dig +short example.com       # jen výsledná IP
dig -x 8.8.8.8               # zpětný dotaz
dig +trace example.com       # celá cesta od kořenových serverů

getent hosts localhost       # překlad PŘESNĚ jako ho dělá systém (/etc/hosts + DNS)
```

Jak číst `dig`:

```
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 12345     ← NOERROR = OK, NXDOMAIN = jméno neexistuje
;; QUESTION SECTION:
;example.com.                   IN      A                     ← na co jsem se ptal (A = IPv4)
;; ANSWER SECTION:
example.com.            3600    IN      A       93.184.215.14 ← odpověď, 3600 s platnost (TTL)
;; SERVER: 127.0.0.11#53(127.0.0.11)                          ← kdo odpověděl (port 53)
```

> `host` a `dig` se ptají **přímo DNS serveru** a `/etc/hosts` **ignorují**.
> Proto `host server1` nenajde jméno, které je jen v `/etc/hosts` – `getent hosts server1` ano.
>
> 🧪 V NDG bez internetu dotazy na veřejné domény skončí `connection timed out; no servers could be reached`.

## 1.5 Porty a protokoly – TCP, UDP, ICMP

IP adresa určuje **počítač**, **port** (0–65535) určuje **službu** na něm.

| Protokol | Vlastnost | Příklad použití |
|---|---|---|
| **TCP** | spojení, potvrzování, spolehlivý | web, ssh, e-mail |
| **UDP** | bez spojení, rychlý, bez záruky | DNS dotazy, streaming, DHCP |
| **ICMP** | diagnostika a chybové zprávy, **nemá porty** | `ping`, `traceroute` |

| Port | Služba | | Port | Služba |
|---|---|---|---|---|
| 20, 21/tcp | FTP | | 53/udp+tcp | DNS |
| 22/tcp | SSH, SCP, SFTP | | 67, 68/udp | DHCP |
| 23/tcp | Telnet | | 80/tcp | HTTP |
| 25/tcp | SMTP (pošta) | | 443/tcp | HTTPS |

```bash
grep -w 22/tcp /etc/services        # seznam známých portů je v /etc/services
grep -wE '^(ssh|domain|https)' /etc/services
```

**ICMP – běžné zprávy:**

| Zpráva | Kdy přijde |
|---|---|
| Echo Request / Echo Reply | `ping` a odpověď na něj |
| Destination Unreachable | cíl (síť, počítač, port) je nedosažitelný |
| Redirect | „použij jiný (lepší) router" |
| Time Exceeded | paketu došel **TTL** – využívá `traceroute` |
| Source Quench | „zpomal, jsem přetížený" – dnes **zastaralá** (RFC 6633), v praxi se nepoužívá |

## 1.6 Vzdálený přístup – `ftp`, `telnet` a proč dnes `ssh`

```bash
ftp 192.168.1.2              # přenos souborů, výzva ftp>  (help, ls, get, put, bye)
telnet 192.168.1.2           # vzdálený terminál (démon telnetd)
telnet -l testuser hostname  # přihlásit se jako konkrétní uživatel
telnet localhost 25          # TRIK: test, jestli na portu 25 něco poslouchá
```

> ⚠️ **Chyba ve slidech:** `telnet -l hostname testuser` – přepínač `-l` bere **jméno uživatele**,
> správně **`telnet -l testuser hostname`**.

🔐 **FTP i Telnet posílají vše včetně hesla jako čistý text** – kdokoliv v síti ho odposlechne.
Dnes se používá šifrované **SSH**:

| Starý (nešifrovaný) | Náhrada přes SSH (port 22) |
|---|---|
| `telnet server` | `ssh uzivatel@server` |
| `ftp server` | `sftp uzivatel@server` |
| kopírování přes FTP | `scp soubor.txt uzivatel@server:/tmp/` |

```bash
ssh sysadmin@localhost       # první připojení se ptá na otisk klíče (yes) → uloží do ~/.ssh/known_hosts
exit                         # zpět
```

> 🧪 V NDG nemusí běžet SSH server – pak `Connection refused`. Telnet a FTP se dnes hodí hlavně
> na test portu (`telnet host port`) – na to je ale lepší `nc -zv host port` (kapitola 3.7).

---

# 2. Network Configuration

## 2.1 Síťová rozhraní

**Síťové rozhraní** = bod připojení počítače k síti – **hardwarové** (síťová karta, NIC)
nebo **softwarové** (loopback `lo`, virtuální `veth` v kontejneru, VPN `tun0`).

| Název | Co to je |
|---|---|
| `lo` | loopback, 127.0.0.1 |
| `eth0`, `eth1` | klasické názvy ethernetu (a v kontejnerech) |
| `ens3`, `enp4s0` | moderní „předvídatelné" názvy podle umístění na sběrnici (`en` = ethernet, `p4s0` = PCI bus 4, slot 0) |
| `wlan0`, `wlp2s0` | Wi-Fi |

```bash
ip link                      # všechna rozhraní a jejich stav
ip -br link                  # stručně (brief)
# lo        UNKNOWN  00:00:00:00:00:00 <LOOPBACK,UP,LOWER_UP>
# eth0@if5  UP       02:42:c0:a8:01:02 <BROADCAST,MULTICAST,UP,LOWER_UP>
ip link show eth0            # jen jedno rozhraní
ls /sys/class/net            # rozhraní, jak je vidí jádro (viz cv06 – sysfs)
```

Příznaky: **`UP`** = rozhraní je zapnuté (administrativně), **`LOWER_UP`** = je fyzicky připojený
kabel / linka, `BROADCAST`, `MULTICAST` = umí broadcast a multicast.

> ⚠️ **Chyba ve slidech (ip link):** u `ens3` je výpis `<LOOPBACK,UP,LOWER_UP>`. Příznak `LOOPBACK`
> má jen rozhraní `lo` – ethernet má `<BROADCAST,MULTICAST,UP,LOWER_UP>`.

## 2.2 Staré nástroje vs. `iproute2`

Balík **net-tools** (`ifconfig`, `route`, `netstat`, `arp`) je **zastaralý** (deprecated). Nové
distribuce používají **iproute2** – příkaz **`ip`** a **`ss`**. Staré příkazy ale stále potkáš.

| Starý příkaz | Nový (iproute2) | K čemu |
|---|---|---|
| `ifconfig` | `ip address`, `ip link`, `ip -s link` | adresy a rozhraní (+ statistiky) |
| `route` | `ip route` | směrovací tabulka |
| `arp` | `ip neighbor` | sousedé – tabulka IP ↔ MAC (ARP) |
| `iptunnel` | `ip tunnel` | tunely |
| `nameif` | `ip link set eth0 name lan0` | přejmenování rozhraní |
| `ipmaddr` | `ip maddress` | multicastové adresy |
| `netstat` | `ss`, `ip route`, `ip -s link` | spojení a porty, trasy, statistiky |

> ⚠️ **Opravy oproti slidům (tabulka iproute2):**
>
> - Ve slidech jsou **přeložené názvy příkazů** – `ip adresa`, `trasa`, `tunel ip`, `název sady odkazů ip`.
>   V terminálu fungují jen anglicky: `ip address`, `route`, `ip tunnel`, `ip link set … name …`.
> - U `arp → ip neighbor` slidy píší „hostitelé, kteří sdílejí **stejnou IP adresu**" – správně
>   „hostitelé ve **stejné síti** (na stejné lince)". Stejnou IP adresu nesmí mít dva počítače.
> - Nadpis jednoho slidu je „Příkaz **ipconfig**" – to je příkaz Windows. V Linuxu **`ifconfig`**.

Příkaz `ip` jde **zkracovat**: `ip a` = `ip addr` = `ip address`, `ip r` = `ip route`,
`ip n` = `ip neigh`, `ip l` = `ip link`.

## 2.3 IP adresa – `ifconfig` a `ip addr`

**Zobrazení:**

```bash
ip addr                      # nebo  ip a
# 1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 ...
#     inet 127.0.0.1/8 scope host lo
# 2: eth0@if5: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 ...
#     link/ether 02:42:c0:a8:01:02 brd ff:ff:ff:ff:ff:ff     ← MAC adresa
#     inet 192.168.1.2/24 brd 192.168.1.255 scope global eth0 ← IPv4 / prefix, broadcast
ip -br addr                  # stručně: rozhraní, stav, adresy
ip -4 addr show eth0         # jen IPv4 jen pro eth0
ip -s addr                   # + statistiky (přijaté/odeslané pakety, chyby)

ifconfig                     # starý způsob – jen aktivní rozhraní
ifconfig -a                  # i vypnutá
ifconfig eth0
# eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1450
#       inet 192.168.1.2  netmask 255.255.255.0  broadcast 192.168.1.255
#       ether 02:42:c0:a8:01:02  txqueuelen 0  (Ethernet)
#       RX packets 13  bytes 1038 (1.0 KB)       ← přijato
#       TX packets 8  bytes 648 (648.0 B)        ← odesláno
#       RX errors 0  dropped 0 ...               ← chyby → problém s kartou/kabelem
```

**Nastavení** – ⚠️ **jen ukázka, v NDG nespouštěj na `eth0`:**

| Úkon | Starý | Nový |
|---|---|---|
| přidat adresu | `sudo ifconfig eth0 172.16.25.130 netmask 255.255.255.0` | `sudo ip addr add 172.16.25.130/24 dev eth0` |
| odebrat adresu | – | `sudo ip addr del 172.16.25.130/24 dev eth0` |
| zapnout rozhraní | `sudo ifconfig eth0 up` | `sudo ip link set eth0 up` |
| vypnout rozhraní | `sudo ifconfig eth0 down` | `sudo ip link set eth0 down` |

> ❗ Slidy u těchto příkazů ukazují výzvu `sysadmin@localhost:~$` **bez `sudo`** – změna sítě
> vyžaduje **root**, jinak `Permission denied` / `Operation not permitted`.
>
> ❗ Rozdíl: `ifconfig eth0 ADRESA` **nahradí** stávající adresu, `ip addr add` **přidá** další
> (rozhraní může mít adres víc).
>
> ❗ Změny přes `ifconfig`, `ip` i `route` platí **jen do restartu**. Trvalé nastavení se dělá
> v konfiguračních souborech – kapitola 2.6.

## 2.4 Směrovací tabulka – `route` a `ip route`

```bash
ip route                     # zobrazit
route -n                     # zobrazit (staře)
netstat -rn                  # zobrazit (ještě jinak)
ip route get 8.8.8.8         # KUDY by šel paket na tuto adresu (výborné na ladění)
```

Úpravy – ⚠️ **jen ukázka:**

| Úkon | Starý | Nový |
|---|---|---|
| výchozí brána | `sudo route add default gw 192.168.1.1` | `sudo ip route add default via 192.168.1.1` |
| trasa do sítě | `sudo route add -net 192.56.78.0 netmask 255.255.255.0 gw 192.168.1.1 dev eth0` | `sudo ip route add 192.56.78.0/24 via 192.168.1.1 dev eth0` |
| smazat trasu | `sudo route del -net 192.56.78.0 netmask 255.255.255.0` | `sudo ip route del 192.56.78.0/24` |

Po přidání trasy ověříš dostupnost: `ping 192.168.1.1`.

> ⚠️ **Zastaralé ve slidech:** `route -Cn` vypisuje **směrovací cache** jádra. Ta byla odstraněna
> v jádře 3.6 (2012) – na současných systémech je výpis prázdný. Nauč se ho jen jako „existuje".

## 2.5 Jméno počítače – `hostname`, `hostnamectl`

```bash
hostname                     # jméno počítače
hostname -s                  # krátké jméno (short)
hostname -f                  # plné jméno s doménou (FQDN), např. www.sample.com
hostname -I                  # všechny IP adresy počítače (bonus, velmi praktické)
cat /etc/hostname            # odsud se jméno načte při startu
sudo hostname example.sample.com   # ⚠️ jen ukázka – změna do restartu
```

Na systémech se **systemd** je náhradou **`hostnamectl`**:

```bash
hostnamectl                  # = hostnamectl status
#  Static hostname: localhost
#        Icon name: computer-vm
#          Chassis: vm
#       Machine ID: 5b91eb5e...
#          Boot ID: c04fc73d...
#   Virtualization: kvm
# Operating System: Ubuntu 18.04.2 LTS
#           Kernel: Linux 4.15.0-45-generic
#     Architecture: x86-64
sudo hostnamectl set-hostname server1          # trvale (zapíše /etc/hostname)
sudo hostnamectl set-hostname "Pepův notebook" --pretty
```

| Typ jména | Pravidla | Příklad |
|---|---|---|
| **static** | jen `a-z`, `0-9`, `-`, `.`; uloženo v `/etc/hostname` | `localhost`, `ndg-server` |
| **pretty** | libovolné znaky UTF-8, pro lidi | `Sářin notebook` |
| **transient** | dočasné, nastavuje jádro, může ho změnit DHCP / DNS za běhu | `localhost` |

> 🧪 V kontejneru bez systemd vypíše `hostnamectl` chybu *System has not been booted with systemd*.
>
> Slidy uvádí pro Red Hat soubor `/etc/sysconfig/network` – to platí pro staré verze (RHEL 6).
> Od RHEL 7 používá i Red Hat **`/etc/hostname`**.

## 2.6 Trvalá konfigurace – liší se podle distribuce

### Red Hat / CentOS / Fedora (starší způsob)

**`/etc/sysconfig/network`** – globální nastavení:

```
NETWORKING=yes
HOSTNAME=server1.sample.com
GATEWAY=192.168.0.1
```

**`/etc/sysconfig/network-scripts/ifcfg-eth0`** – nastavení jednoho rozhraní:

```
DEVICE=eth0              # název zařízení
NM_CONTROLLED=no         # nespravuje ho NetworkManager
ONBOOT=yes               # zapnout při startu
TYPE=Ethernet
BOOTPROTO=none           # statická konfigurace (dhcp = automaticky)
IPADDR=192.168.0.3
NETMASK=255.255.255.0    # nebo PREFIX=24
GATEWAY=192.168.0.1
DNS1=192.168.0.254
```

> ⚠️ **Opravy oproti slidům:**
>
> - Slidy ukazují jako obsah `/etc/sysconfig/network` řádky `DEVICE=…`, `ONBOOT=…`, `BOOTPROTO=…` –
>   ty patří do **`ifcfg-<rozhraní>`**. `/etc/sysconfig/network` obsahuje globální věci (výše).
> - `BOOTPROTO=dhcp.` – tečka na konci je navíc, správně `BOOTPROTO=dhcp`.
> - RHEL 9 soubory `ifcfg-*` už nepoužívá – NetworkManager ukládá připojení do
>   `/etc/NetworkManager/system-connections/` a spravuje se přes `nmcli`.

### Debian / Ubuntu

**Starší Debian:** `/etc/network/interfaces`

```
auto eth0
iface eth0 inet static
    address 192.168.0.3/24
    gateway 192.168.0.1
```

**Ubuntu 17.10+: netplan** – YAML soubory v **`/etc/netplan/`** (např. `/etc/netplan/01-netcfg.yaml`):

```yaml
# DHCP
network:
  version: 2
  renderer: networkd        # nebo NetworkManager
  ethernets:
    ens3:
      dhcp4: true
```

```yaml
# statická adresa
network:
  version: 2
  ethernets:
    ens3:
      addresses: [192.168.0.3/24]
      routes:
        - to: default
          via: 192.168.0.1
      nameservers:
        addresses: [192.168.0.254, 8.8.8.8]
```

```bash
sudo netplan try             # vyzkouší a když nepotvrdíš do 120 s, vrátí změnu zpět (!)
sudo netplan apply           # použije
```

> ⚠️ **Opravy oproti slidům (netplan):**
>
> - Adresář je **`/etc/netplan/`**, ne `/etc/network/netplan`.
> - Ve slidech je YAML **přeložený** (`síť:`, `verze:`, `vykreslovač:`, `dhcp4: ano`) a **bez odsazení**.
>   Klíče musí být anglicky (`network`, `version`, `renderer`, `dhcp4: true`) a v YAML **rozhoduje
>   odsazení mezerami** (ne tabulátory) – bez něj soubor nefunguje.

### systemd-networkd

Démon **systemd-networkd** spravuje síť podle souborů `*.network` v adresářích
`/usr/lib/systemd/network/` (výchozí od distribuce), `/run/systemd/network/` (dočasné)
a **`/etc/systemd/network/`** (tvoje – mají přednost):

```ini
# /etc/systemd/network/20-wired.network
[Match]
Name=ens3

[Network]
Address=192.168.0.3/24
Gateway=192.168.0.1
DNS=192.168.0.254
```

## 2.7 NetworkManager – `nmcli`

**NetworkManager** (vyvinul Red Hat) automaticky detekuje a nastavuje síť – kabel, Wi-Fi,
některé modemy, VPN. Na desktopu je to ta ikonka sítě v rohu obrazovky, v terminálu **`nmcli`**:

```
nmcli [VOLBY] OBJEKT [PŘÍKAZ] [ARGUMENTY…]
       objekty: general, networking, radio, connection (con), device (dev, d)
```

```bash
nmcli dev                    # zařízení a jejich stav
# DEVICE  TYPE      STATE         CONNECTION
# enp4s0  ethernet  connected     Wired connection 1
# wlp2s0  wifi      disconnected  --
# lo      loopback  unmanaged     --
nmcli con show               # uložená připojení (profily)

# nové připojení se statickou adresou
sudo nmcli con add con-name eth1 ifname eth1 type ethernet \
     ip4 10.0.2.18/24 gw4 10.0.2.2
sudo nmcli con up eth1

# Wi-Fi
nmcli radio wifi on
nmcli dev wifi list
nmcli --ask dev wifi connect MojeSit     # heslo se zeptá interaktivně
```

> ⚠️ **Chyba ve slidech:** `… type ethernet \ip4 10.0.2.18/24 …` – zpětné lomítko `\` slouží
> k **pokračování příkazu na dalším řádku** a musí být **na konci řádku**. Uprostřed řádku by
> z `\ip4` udělalo jen `ip4`, takže to náhodou projde, ale je to chyba přepisu – buď celý příkaz
> na jeden řádek bez `\`, nebo jako výše.
>
> 🔐 Slidy ukazují `nmcli d wifi connect <síť> password <heslo>` – heslo pak zůstane
> v **historii shellu** (`history`, `~/.bash_history`, viz cv02). Lepší je `--ask`.
>
> 🧪 V NDG `nmcli` nejspíš nebude – NetworkManager v kontejneru neběží.

## 2.8 systemd-resolved – `resolvectl`

Na systémech se systemd překládá jména služba **systemd-resolved**. V `/etc/resolv.conf` je pak
často jen `nameserver 127.0.0.53` – lokální „prostředník", který se teprve ptá skutečných DNS serverů.

```bash
resolvectl status                     # jaké DNS servery se skutečně používají (per rozhraní)
resolvectl query netdevgroup.com      # přeložit jméno
# netdevgroup.com: 34.214.209.23
resolvectl query 8.8.8.8              # i zpětně
```

## 2.9 Ovladač síťové karty

Síťová karta funguje díky **ovladači** = **modulu jádra** (viz cv06, `lsmod`, `modinfo`):

```bash
sudo lshw -c network | grep driver       # jaký ovladač karta používá (lshw nemusí být nainstalován)
ethtool -i eth0                          # totéž jednodušeji – řádek driver:
# driver: veth                           ← v kontejneru virtuální; na PC např. e1000e, r8169, iwlwifi
lsmod | grep e1000e                      # je modul načtený?
ip link show eth0                        # je rozhraní UP?
```

---

# 3. Network Troubleshooting

## 3.1 Postup – jdi zdola nahoru

Typické problémy: systém **nevidí síťovou kartu**, **nemá správnou IP**, **nedosáhne na router**,
**nefunguje DNS**. Postupuj krok za krokem – každý krok předpokládá, že ten předchozí prošel:

| # | Otázka | Příkaz | Když selže → |
|---|---|---|---|
| 1 | Vidí systém kartu? Je `UP`? | `ip link` | ovladač (`lsmod`, `ethtool -i`), kabel, `ip link set … up` |
| 2 | Mám IP adresu? | `ip addr` | DHCP (`169.254.x.x` = DHCP neodpověděl), statická konfigurace |
| 3 | Funguje mi vlastní síťový stack? | `ping -c 3 127.0.0.1` | problém v systému |
| 4 | Dosáhnu na bránu? | `ip route`, `ping -c 3 <brána>` | kabel, Wi-Fi, VLAN, chybná maska |
| 5 | Dosáhnu ven na IP? | `ping -c 3 8.8.8.8`, `traceroute 8.8.8.8` | router, firewall, poskytovatel |
| 6 | Funguje DNS? | `ping google.com`, `host google.com`, `cat /etc/resolv.conf` | DNS server v `resolv.conf` |
| 7 | Běží služba a poslouchá? | `ss -tlnp`, `nc -zv host port` | služba neběží, firewall |

> 💡 **Klasika:** `ping 8.8.8.8` funguje, ale `ping google.com` ne → síť je v pořádku,
> **problém je v DNS**.

## 3.2 `ping` – je cíl dosažitelný?

Posílá **ICMP Echo Request** a čeká na **Echo Reply**. Bez `-c` běží donekonečna (**Ctrl+C**).

```bash
ping -c 5 192.168.1.2        # -c 5 = pošli 5 paketů a skonči
# PING 192.168.1.2 (192.168.1.2) 56(84) bytes of data.
# 64 bytes from 192.168.1.2: icmp_seq=1 ttl=64 time=0.065 ms
#                            └ pořadí   └ TTL   └ doba odezvy (RTT)
# ...
# --- 192.168.1.2 ping statistics ---
# 5 packets transmitted, 5 received, 0% packet loss, time 4001ms   ← ztráta paketů!
# rtt min/avg/max/mdev = 0.056/0.061/0.068/0.006 ms

ping -c 3 -i 0.5 localhost   # -i interval mezi pakety (s)
ping -c 3 -W 1 10.9.9.9      # -W čekej na odpověď max. 1 s
ping6 -c 3 ::1               # IPv6 (nebo ping -6)
```

| Výsledek | Význam |
|---|---|
| `64 bytes from …` | cíl odpovídá ✔ |
| `Destination Host Unreachable` | cíl je v mé síti, ale neodpovídá (vypnutý, špatná IP) |
| `Network is unreachable` | nemám trasu (chybí brána) |
| žádná odpověď, 100% packet loss | paket se ztratil cestou, nebo **firewall blokuje ICMP** |
| `Name or service not known` | **DNS** nepřeložilo jméno |

> ❗ Neodpovídá-li cíl na ping, **nemusí být nedostupný** – mnoho serverů ICMP záměrně blokuje.

## 3.3 `traceroute` a `tracepath` – kudy paket jde

**Princip:** pošle pakety s **TTL = 1, 2, 3…**. Každý router TTL sníží o 1, a když dojde na 0,
pošle zpět ICMP **Time Exceeded** – tím prozradí svou adresu. Tak se postupně odhalí celá cesta.

```bash
traceroute 8.8.8.8           # cesta k cíli (IPv4)
traceroute -n 8.8.8.8        # bez překladu IP na jména – rychlejší
traceroute -6 ipv6.google.com   # IPv6 (nebo traceroute6)
tracepath netdevgroup.com    # podobné + zjistí MTU (pmtu) na cestě
# 1?: [LOCALHOST]                      pmtu 1500
# 1:  192.168.1.1                      2.041ms     ← 1. skok = moje brána
# 2:  172.72.53.1                      2.285ms
# 3:  * * *  / no reply                            ← router neodpověděl (ne nutně chyba)
```

- `* * *` = router na tento typ paketu neodpovídá (často filtr) – cesta může pokračovat dál.
- Kde výpis **trvale skončí**, tam je problém.
- `tracepath` používá UDP – hodí se, když routery filtrují ICMP; **nepotřebuje root**.

> ⚠️ **Chyba ve slidech:** „Příkaz traceroute mohou spustit pouze uživatelé s oprávněním root" –
> **neplatí**. Výchozí režim (UDP) spustí běžný uživatel. Root je potřeba jen pro některé režimy,
> např. `traceroute -I` (ICMP) nebo `-T` (TCP).
>
> 🧪 V NDG bez internetu uvidíš nejvýš první skok a pak samé `* * *`.

## 3.4 `netstat` a `ss` – spojení a otevřené porty

`ss` (socket statistics) je novější náhrada `netstat` s podobnými přepínači:

| Přepínač | Význam |
|---|---|
| `-t` / `-u` | TCP / UDP |
| `-l` | jen **naslouchající** (LISTEN) – „jaké služby tu běží" |
| `-a` | všechny (naslouchající i navázaná spojení) |
| `-n` | čísla místo jmen (`22` místo `ssh`) – rychlejší |
| `-p` | který proces port drží (cizí procesy vidíš jen se `sudo`) |
| `-s` | souhrnné statistiky |

```bash
ss -tuln                     # „tuln" – nejpoužívanější kombinace: naslouchající TCP+UDP porty číselně
# Netid State   Recv-Q Send-Q   Local Address:Port   Peer Address:Port
# tcp   LISTEN  0      128            0.0.0.0:22          0.0.0.0:*
# tcp   LISTEN  0      100          127.0.0.1:25          0.0.0.0:*
sudo ss -tulnp               # + který program
ss -tan                      # všechna TCP spojení (ESTAB = navázané)
ss -s                        # souhrn

netstat -tuln                # totéž postaru
netstat -rn                  # směrovací tabulka (= route -n)
netstat -i                   # statistiky rozhraní (RX/TX OK, ERR, DRP)
netstat -ic                  # -c = opakuj každou sekundu (Ctrl+C) – sledování provozu
netstat -s                   # statistiky podle protokolů
```

Jak číst **Local Address**:

| Adresa | Služba je dostupná… |
|---|---|
| `0.0.0.0:22` / `[::]:22` / `*:22` | ze **všech** rozhraní – i ze sítě |
| `127.0.0.1:25` | jen **z tohoto počítače** (loopback) |
| `192.168.1.2:80` | jen přes tuto konkrétní adresu |

> ⚠️ **Opravy oproti slidům (netstat):**
>
> - „`netstat` zobrazí seznam všech portů, včetně nepoužívaných" – **ne**. Samotný `netstat`
>   ukáže jen **navázaná spojení** (bez naslouchajících – i ukázka ve slidu má nadpis
>   *„bez serverů"* / *w/o servers*). Všechny = **`netstat -a`**, jen naslouchající = **`netstat -l`**.
> - Ukázka statistik rozhraní je ve slidu spuštěná jako `netstat -r` – správně **`netstat -i`**.
> - `netstat - l`, `netstat - r` – bez mezery: `netstat -l`, `netstat -r`.
>
> 🧪 `netstat` je v balíku net-tools, který nemusí být nainstalovaný – `ss` je skoro vždy.

## 3.5 `ip neighbor` – kdo je v mé síti (ARP)

Uvnitř sítě se posílá na **MAC adresu**. Protokol **ARP** zjistí „která MAC patří k IP 192.168.1.1"
a výsledek si jádro pamatuje v **tabulce sousedů** (ARP cache):

```bash
ping -c 1 192.168.1.1        # „pozdravím" bránu, aby se dostala do tabulky
ip neigh                     # = ip neighbor show
# 192.168.1.1 dev eth0 lladdr 02:42:c0:a8:01:01 REACHABLE
#                            └ MAC adresa        └ stav: REACHABLE = čerstvé, STALE = starší, FAILED = neodpovídá
ip neigh show dev eth0
arp -a                       # starý způsob
```

## 3.6 `ethtool` – fyzická vrstva

Pro **ethernetové karty a ovladače** – rychlost, duplex, je-li kabel připojen. Potřebuje název rozhraní
a pro některé údaje **root**:

```bash
sudo ethtool eth0            # Speed: 1000Mb/s, Duplex: Full, Link detected: yes
ethtool -i eth0              # ovladač a firmware
sudo ethtool -S eth0         # podrobné statistiky karty (chyby)
```

## 3.7 `netcat` (`nc`) – švýcarský nůž pro TCP/UDP

Multiplatformní (Linux, Windows, Mac) – přenos dat, jednoduchý proxy, **test otevřených portů**:

```
nc [volby] host port[y]
```

```bash
nc -zv localhost 22          # -z = jen zkus spojení, nic neposílej; -v = vypiš výsledek
# Connection to localhost 22 port [tcp/ssh] succeeded!
nc -zv 192.168.1.2 20-25     # sken portů 20 až 25

# mini „chat" v jednom terminálu – server na pozadí, klient mu pošle text
nc -l 12345 &                # poslouchej na portu 12345 (někde je potřeba nc -l -p 12345)
echo "ahoj" | nc -q 1 localhost 12345      # (-q 1 = po odeslání skonči; v některých verzích -N)
```

> ⚠️ **Chyba ve slidech:** „prohledá porty **20 až 25**", ale příkaz je `netcat -z -v 192.168.1.2 **20-35**`.
> Pro porty 20–25 má být `20-25`. A neprohledává „rozhraní" 192.168.1.2, ale **počítač** s touto adresou.
>
> ❗ Skenuj porty **jen na svých strojích** nebo s povolením – sken cizích serverů může být
> vyhodnocen jako útok.
>
> 🧪 Existuje víc verzí netcatu (OpenBSD, traditional, ncat) s mírně odlišnými přepínači.
> V NDG nemusí být nainstalovaný vůbec – náhradou pro test portu je `telnet host port`
> nebo bash: `timeout 1 bash -c '</dev/tcp/localhost/22' && echo otevřeno`.

---

# Úlohy k procvičení

Pracuj v `~/cv07`. Úlohy, které síť **mění**, jen napiš – nespouštěj.

### 1. Networking Fundamentals

1. Zjisti IP adresu a prefix svého rozhraní `eth0`. Kolik počítačů může být v této síti?
2. Zjisti výchozí bránu – dvěma různými příkazy.
3. Jaký DNS server systém používá a v jakém pořadí se jména překládají (`/etc/hosts` vs. DNS)?
4. Přidej do `/etc/hosts` záznam, že `server1` má adresu `192.168.1.50`. Ověř překlad pomocí `getent`
   a vysvětli, proč ho `host server1` nenajde. Záznam pak odstraň.
5. Najdi v `/etc/services`, jaký port a protokol používají `ssh`, `https` a `domain` (DNS).
6. Jsou `192.168.1.2` a `192.168.1.130` ve stejné síti při masce `/24`? A při `/25`?
7. Proč by se `telnet` a `ftp` neměly používat přes internet? Čím je nahradíš?

### 2. Network Configuration

8. Vypiš stručně všechna rozhraní a zjisti MAC adresu `eth0`.
9. Zobraz IP adresy novým (`ip`) i starým (`ifconfig`) příkazem.
10. Zobraz směrovací tabulku třemi různými příkazy. Co znamenají příznaky `U` a `G`?
11. Zjisti jméno počítače (krátké i plné) a zkontroluj `/etc/hostname`.
12. *(jen napsat)* Přidej rozhraní `eth1` adresu `10.0.0.5/24`, zapni ho a nastav výchozí bránu
    `10.0.0.1` – příkazem `ip` i starými příkazy. Proč nastavení nepřežije restart?
13. *(jen napsat)* Netplan soubor pro `ens3`: statická adresa `192.168.10.20/24`, brána `192.168.10.1`,
    DNS `1.1.1.1`.
14. Zjisti, jaký ovladač používá `eth0`.
15. Zjisti, kterým rozhraním a přes jakou bránu by odešel paket na `8.8.8.8`.

### 3. Network Troubleshooting

16. Pošli 3 pingy na `127.0.0.1` a 3 na vlastní IP adresu. Co znamená `ttl` a `time`?
17. Pingni výchozí bránu. Pak zkus `ping -c 3 8.8.8.8` a `ping -c 3 google.com`. Rozliš, co
    selhalo (síť, nebo DNS?).
18. Vypiš naslouchající TCP a UDP porty číselně. Které služby jsou dostupné ze sítě a které jen lokálně?
19. Po pingu brány zobraz tabulku sousedů. Jakou MAC adresu má brána?
20. Ověř, jestli na `localhost` poslouchá port 22 – bez `ss`.
21. Zobraz statistiky rozhraní `eth0` (přijaté/odeslané pakety a chyby).
22. Kolega hlásí: „nejde mi otevřít web". Seřaď kroky diagnostiky a ke každému napiš příkaz.

<details>
<summary>Řešení</summary>

```bash
cd ~/cv07

# 1
ip -4 addr show eth0          # např. inet 192.168.1.2/24
# /24 → 256 adres, 254 pro počítače (bez adresy sítě .0 a broadcastu .255)

# 2
ip route | grep default
route -n                      # řádek 0.0.0.0 s příznakem UG
# (ip route get 8.8.8.8 také prozradí bránu – "via")

# 3
cat /etc/resolv.conf          # řádky nameserver
grep hosts /etc/nsswitch.conf # hosts: files dns  → nejdřív /etc/hosts, pak DNS

# 4
echo "192.168.1.50 server1" | sudo tee -a /etc/hosts
getent hosts server1          # 192.168.1.50  server1
host server1                  # nenajde – host/dig se ptají přímo DNS serveru, /etc/hosts nečtou
sudo sed -i '/server1/d' /etc/hosts
# (proč tee a ne sudo echo ... >> /etc/hosts? Přesměrování >> dělá tvůj shell bez práv roota – viz cv04)

# 5
grep -wE '^(ssh|https|domain)' /etc/services
# ssh 22/tcp, https 443/tcp, domain 53/tcp + 53/udp

# 6
# /24: obě 192.168.1.x → STEJNÁ síť 192.168.1.0/24
# /25: síť má 128 adres → 192.168.1.0–127 a 192.168.1.128–255
#      .2 je v první, .130 ve druhé → RŮZNÉ sítě (komunikují přes router)

# 7
# posílají vše včetně hesla nešifrovaně → odposlech
# telnet → ssh, ftp → sftp / scp

# 8
ip -br link
ip link show eth0             # řádek link/ether = MAC
cat /sys/class/net/eth0/address

# 9
ip addr                       # nebo ip a, ip -br addr
ifconfig                      # může chybět (net-tools)

# 10
ip route
route -n
netstat -rn
# U = trasa je aktivní (up), G = vede přes bránu (gateway)

# 11
hostname -s
hostname -f
cat /etc/hostname

# 12  – jen napsat
sudo ip addr add 10.0.0.5/24 dev eth1
sudo ip link set eth1 up
sudo ip route add default via 10.0.0.1
# postaru:
sudo ifconfig eth1 10.0.0.5 netmask 255.255.255.0 up
sudo route add default gw 10.0.0.1
# Příkazy mění jen běžící konfiguraci v jádře. Trvale to musí být v konfiguraci:
# netplan / ifcfg-eth1 / NetworkManager / systemd-networkd.

# 13  – /etc/netplan/01-static.yaml, pak sudo netplan try
# network:
#   version: 2
#   ethernets:
#     ens3:
#       addresses: [192.168.10.20/24]
#       routes:
#         - to: default
#           via: 192.168.10.1
#       nameservers:
#         addresses: [1.1.1.1]

# 14
ethtool -i eth0 | grep driver
readlink /sys/class/net/eth0/device/driver    # na fyzické kartě; veth v kontejneru tento odkaz nemá

# 15
ip route get 8.8.8.8          # 8.8.8.8 via 192.168.1.1 dev eth0 src 192.168.1.2

# 16
ping -c 3 127.0.0.1
ping -c 3 $(hostname -I | awk '{print $1}')
# ttl = kolik routerů ještě paket smí projít (každý router ubere 1; lokálně 64)
# time = doba odezvy tam a zpět (RTT) v ms

# 17
ping -c 3 $(ip route | awk '/default/ {print $3}')
ping -c 3 8.8.8.8             # v NDG 100% packet loss / Network unreachable → chybí cesta ven
ping -c 3 google.com          # v NDG: Name or service not known / Temporary failure in name resolution → DNS
# Když jde IP a nejde jméno → problém je v DNS.
# Když nejde ani IP → problém je v síti (brána, router, firewall), DNS netřeba řešit.

# 18
ss -tuln
# 0.0.0.0:port, [::]:port, *:port → dostupné ze sítě
# 127.0.0.1:port, [::1]:port, 127.0.0.53… → jen lokálně

# 19
ping -c 1 $(ip route | awk '/default/ {print $3}')
ip neigh                      # lladdr = MAC brány

# 20
nc -zv localhost 22
telnet localhost 22           # „Connected to localhost" = poslouchá; ukončíš Ctrl+] a pak quit
timeout 1 bash -c '</dev/tcp/localhost/22' && echo otevreno || echo zavreno

# 21
ip -s link show eth0
netstat -i                    # sloupce RX-OK, RX-ERR, TX-OK, TX-ERR
ifconfig eth0                 # RX packets / errors, TX packets / errors

# 22
# 1. ip link              – karta existuje a je UP?
# 2. ip addr              – mám IP (ne 169.254.x.x)?
# 3. ping 127.0.0.1       – funguje síťový stack?
# 4. ip route + ping brána – dosáhnu na router?
# 5. ping 8.8.8.8         – dosáhnu ven?  (traceroute 8.8.8.8 ukáže, kde to končí)
# 6. ping/host google.com, cat /etc/resolv.conf – funguje DNS?
# 7. nc -zv server 443    – běží na serveru služba (port 443)?
```

</details>

---

# Tahák

### Základy

| Potřebuju… | Příkaz / soubor |
|---|---|
| moje IP adresy | `ip a`, `ip -br a`, `hostname -I`, `ifconfig` |
| rozhraní a MAC | `ip link`, `ip -br link` |
| směrovací tabulka / brána | `ip route`, `route -n`, `netstat -rn` |
| kudy půjde paket | `ip route get 8.8.8.8` |
| DNS servery | `/etc/resolv.conf`, `resolvectl status` |
| ruční překlad jmen | `/etc/hosts` |
| pořadí překladu jmen | `/etc/nsswitch.conf` (`hosts: files dns`) |
| čísla portů služeb | `/etc/services` |
| jméno počítače | `hostname [-s/-f]`, `hostnamectl`, `/etc/hostname` |

### Konfigurace (do restartu, vyžaduje `sudo`)

| Úkon | `ip` (nový) | starý |
|---|---|---|
| přidat adresu | `ip addr add 10.0.0.5/24 dev eth0` | `ifconfig eth0 10.0.0.5 netmask 255.255.255.0` |
| zapnout / vypnout | `ip link set eth0 up` / `down` | `ifconfig eth0 up` / `down` |
| výchozí brána | `ip route add default via 10.0.0.1` | `route add default gw 10.0.0.1` |
| trasa do sítě | `ip route add 10.1.0.0/16 via 10.0.0.1` | `route add -net 10.1.0.0 netmask 255.255.0.0 gw 10.0.0.1` |
| jméno počítače | `hostnamectl set-hostname jmeno` | `hostname jmeno` |

### Trvalá konfigurace

| Kde | Soubor / nástroj |
|---|---|
| Red Hat (starší) | `/etc/sysconfig/network`, `/etc/sysconfig/network-scripts/ifcfg-eth0` |
| Debian (starší) | `/etc/network/interfaces` |
| Ubuntu (netplan) | `/etc/netplan/*.yaml` → `netplan try` / `netplan apply` |
| systemd-networkd | `/etc/systemd/network/*.network` |
| NetworkManager | `nmcli dev`, `nmcli con show`, `nmcli con add …`, `nmcli dev wifi list` |

### Diagnostika

| Potřebuju… | Příkaz |
|---|---|
| je cíl dosažitelný? | `ping -c 3 cil`, `ping6` |
| kudy vede cesta | `traceroute [-n] cil`, `tracepath cil` |
| překlad jména | `host jmeno`, `dig [+short] jmeno`, `getent hosts jmeno`, `resolvectl query jmeno` |
| zpětný překlad | `host IP`, `dig -x IP` |
| naslouchající porty | `ss -tuln`, `sudo ss -tulnp`, `netstat -tuln` |
| navázaná spojení | `ss -tan`, `netstat -tan` |
| statistiky rozhraní | `ip -s link`, `netstat -i` |
| sousedé (ARP) | `ip neigh`, `arp -a` |
| karta, ovladač, rychlost | `ethtool -i eth0`, `sudo ethtool eth0`, `sudo lshw -c network` |
| je port otevřený? | `nc -zv host port`, `telnet host port` |
| vzdálený přístup / kopie | `ssh user@host`, `scp soubor user@host:cesta`, `sftp user@host` |

---

# Příprava na cvičení 08

> 📌 **Cvičení 08 bude samostudium** (podle posledního slidu).

Samostudium, splněné laby a testy z modulů:

- **Linux Essentials – Module 15 – System and User Security**
- **Linux Essentials – Module 16 – Creating Users and Groups**
- **Linux Essentials – Module 17 – Ownership and Permissions**
- **Linux Essentials – Module 18 – Special Directories and Files** *(je jen na slidu, v zadání chybí – udělej ho pro jistotu taky)*

Na co se zaměřit:

- soubory `/etc/passwd`, `/etc/shadow`, `/etc/group` – co je v jednotlivých sloupcích,
- `useradd`, `usermod`, `userdel`, `passwd`, `groupadd`, `groupmod`, `groupdel`,
- `who`, `w`, `last`, `id`,
- vlastnictví a oprávnění – navazuje na **cvičení 06** (`chown`, `chmod`, `umask`),
- speciální oprávnění a odkazy (setuid, setgid, sticky bit, hard/soft link) – také z **cvičení 06**.
