# Cvičení 08 – Uživatelé, skupiny a zabezpečení

Podle **NDG Linux Essentials** a labů **Linux II.**:

- **Module 15 – System and User Security**
- **Module 16 – Creating Users and Groups**
- **Module 17 – Ownership and Permissions**
- Linux II. – **6 User and Group Accounts**, **16 Account Security**, **17 Host Security**

**Vstupní požadavky:** samostudium Module 15–17, splněné *Lab 15–17 + Chapter 15–17 Exam* a Exams z předchozích modulů.

Vše si zkoušíme v laboratorním prostředí **NDG NETLAB+** na [portal.netdevgroup.com](https://portal.netdevgroup.com/).

> 🔗 Navazuje na **cvičení 06** – `su`/`sudo` ([2.2](../06/README.md#22-su-a-sudo--práce-jako-jiný-uživatel)),
> `chown`/`chgrp`/`newgrp`, `chmod` a speciální oprávnění setuid/setgid/sticky ([2.7](../06/README.md#27-speciální-oprávnění--setuid-setgid-sticky-bit)).
> Tady je nebudu vysvětlovat znovu od začátku, jen doplním, co je nového.

---

## 0. Příprava prostředí

1. Přihlas se na [portal.netdevgroup.com](https://portal.netdevgroup.com/) a spusť **Lab 15** (16, 17).
2. Jsi přihlášen jako **`sysadmin`**, heslo pro `sudo` je **`netlab123`**.
3. Pracovní adresář:

```bash
mkdir -p ~/cv08
cd ~/cv08
```

> ⚠️ **Omezení NDG labu:**
>
> - Vytvářet a mazat uživatele a skupiny (`useradd`, `groupadd`…) v labu **jde** – na to je lab určený.
>   Na konci po sobě ukliď (`sudo userdel -r test_user` …), nebo lab restartuj.
> - Lab je **Ubuntu (Debian)**, slidy jsou psané hlavně pro **Red Hat**. Výchozí chování se liší
>   (domovský adresář, shell, `!` vs. `!!`) – v návodu je to vždy uvedené.
> - Lab je kontejner bez systemd a bez internetu. `nmap`, `lsof`, `fuser`, `xinetd`, `systemctl`,
>   `runlevel` nemusí být nainstalované nebo nebudou fungovat. `who`, `w` a `last` mohou být prázdné,
>   protože terminál v prohlížeči není klasické přihlášení.
> - Výstupy ve slidech jsou **přeložené do češtiny** – v terminálu budou anglicky. Klíčová slova
>   v konfiguračních souborech (`[Unit]`, `service`, `disable`…) se **nikdy nepřekládají**.
> - S `/etc/sudoers` a `/etc/nologin` opatrně – chybou si můžeš zablokovat `sudo` nebo přihlášení
>   (pomůže pak restart labu). Proto jsou tyto ukázky označené.

---

# 1. User and Group Accounts

Linux je **víceuživatelský** systém – více lidí (a služeb) může pracovat současně. Účty uživatelů
a skupin určují, **kdo smí co**. Většina příkazů v této části vyžaduje **root** (`sudo`).

## 1.1 Přehled souborů

| Soubor | Co obsahuje | Kdo smí číst |
|---|---|---|
| **`/etc/passwd`** | seznam uživatelských účtů (jméno, UID, GID, domov, shell) | **všichni** |
| **`/etc/shadow`** | **hashe hesel** a stárnutí hesel | jen **root** |
| **`/etc/group`** | seznam skupin a jejich členů | všichni |
| **`/etc/gshadow`** | hesla a správci skupin | jen root |
| `/etc/login.defs` | výchozí hodnoty pro **nové** účty (rozsahy UID/GID, stárnutí hesel, UMASK) | všichni |
| `/etc/default/useradd` | výchozí volby příkazu `useradd` (shell, skel, …) | všichni |
| `/etc/skel/` | šablona domovského adresáře – kopíruje se novým uživatelům | všichni |

```bash
ls -l /etc/passwd /etc/shadow /etc/group /etc/gshadow
# -rw-r--r-- 1 root root   ... /etc/passwd     ← čte každý
# -rw-r----- 1 root shadow ... /etc/shadow     ← jen root (a skupina shadow)
```

> 💡 Proč existuje `/etc/shadow`: dřív byly hashe hesel přímo v `/etc/passwd`, který čte každý –
> kdokoliv si je mohl stáhnout a zkoušet prolomit. Proto se přesunuly do souboru, který čte jen root.

## 1.2 `/etc/passwd`

Každý řádek = jeden účet, pole oddělená **dvojtečkou**:

```
test_user:x:1021:1020:Test User:/home/test_user:/bin/bash
│         │ │    │    │         │               └ 7 přihlašovací shell
│         │ │    │    │         └ 6 domovský adresář
│         │ │    │    └ 5 GECOS – celé jméno, komentář
│         │ │    └ 4 GID primární skupiny
│         │ └ 3 UID (root = 0)
│         └ 2 heslo – x = je v /etc/shadow
└ 1 přihlašovací jméno
```

```bash
grep sysadmin /etc/passwd
# sysadmin:x:1001:1001:System Administrator,,,:/home/sysadmin:/bin/bash
getent passwd sysadmin       # totéž, ale funguje i pro účty z LDAP / AD
id sysadmin                  # UID, GID a skupiny přehledně
```

**GECOS** (*General Electric Comprehensive Operating System* – historický název) – obvykle celé jméno.
Může obsahovat seznam oddělený **čárkami**: jméno, kancelář, telefon do práce, telefon domů
(proto `System Administrator,,,`). **Dvojtečka v něm být nesmí** – rozbila by řádek.

**Příkazy, které mění `/etc/passwd`:**

| Příkaz | Co mění |
|---|---|
| `useradd` | přidá nový účet |
| `passwd` | heslo (ve skutečnosti zapisuje do `/etc/shadow`) |
| `usermod` | upraví údaje účtu |
| `userdel` | smaže účet |
| `chfn` | GECOS – jméno, kancelář, telefony (smí i běžný uživatel u sebe) |
| `chsh` | přihlašovací shell (smí i běžný uživatel u sebe) |

```bash
chsh -l                      # nebo cat /etc/shells – povolené shelly
```

> ❗ `/etc/passwd` **needituj ručně** v editoru – překlep v jednom řádku může znemožnit přihlášení.
> Používej příkazy výše, a když už musíš, tak `sudo vipw` (zamkne soubor a zkontroluje ho).
> `finger` z poznámky ve slidech dnes skoro nikde není nainstalovaný – místo něj `getent passwd jméno`.

## 1.3 `/etc/shadow`

```bash
sudo grep sysadmin /etc/shadow
```

```
test_user:$6$nfffgggc$pGt4...:20769:0:99999:7:::
│         │                   │     │ │     │ │││
│         │                   │     │ │     │ ││└ 9 rezervováno
│         │                   │     │ │     │ │└ 8 datum vypršení ÚČTU
│         │                   │     │ │     │ └ 7 neaktivita – dní po vypršení hesla, než se účet zablokuje
│         │                   │     │ │     └ 6 varování – kolik dní předem upozornit
│         │                   │     │ └ 5 max. stáří hesla (dní); 99999 = neomezeně
│         │                   │     └ 4 min. stáří hesla (dní); 0 = smí měnit kdykoliv
│         │                   └ 3 datum poslední změny hesla (dní od 1. 1. 1970)
│         └ 2 hash hesla
└ 1 jméno
```

**Pole 2 – co může obsahovat:**

| Hodnota | Význam |
|---|---|
| `$6$sůl$hash` | heslo zahashované **SHA-512** (`$1$` = MD5 – zastaralé, `$5$` = SHA-256, `$y$` = **yescrypt** – nové Ubuntu/Debian) |
| `!` nebo `!!` na začátku | účet je **zamčený** (`passwd -l`) – nebo heslo ještě nebylo nastaveno (Debian `!`, Red Hat `!!`) |
| `*` | přihlášení heslem není možné (systémové účty) |
| **prázdné** (`test_user::…`) | **žádné heslo** – přihlásí se kdokoliv bez hesla ⚠️ |

> 💡 V souboru **není** heslo, ale **hash** – jednosměrný otisk. Při přihlášení se zahashuje to, co
> napíšeš, a porovná s uloženým. **Sůl** (salt) je náhodný řetězec, díky kterému mají dva uživatelé
> se stejným heslem různé hashe. Proto ani root heslo „nepřečte" – může ho jen přenastavit.
>
> Podrobně krok za krokem to vysvětlují následující podkapitoly.

### Proč se heslo neukládá tak, jak ho napíšeš

Představ si, že by v `/etc/shadow` bylo přímo `test_user:heslo123:…`. Pak:

- kdokoliv, kdo se k souboru dostane (útočník, ukradená záloha, zvědavý kolega s rootem), **vidí
  všechna hesla** – a protože lidé stejné heslo používají i na e-mail, banku a Facebook, má přístup i tam,
- ani správce by neměl vidět heslo uživatele – **ví ho jen uživatel**.

Řešení: systém si heslo **vůbec nepamatuje**. Pamatuje si jen jeho **otisk (hash)** – a to stačí,
aby poznal, jestli jsi napsal správné heslo.

### Co je hash – analogie

**Smoothie:** z jahod, banánu a mléka uděláš v mixéru smoothie. Stejné ovoce = vždy stejné smoothie.
Ale ze smoothie už jahodu a banán **zpátky nesložíš**.

**Otisk prstu:** podle otisku poznáš, jestli je to ten člověk – ale z otisku člověka nevyrobíš.

Hash je matematická funkce, která z libovolného textu udělá řetězec **pevné délky** a má tyto vlastnosti:

| Vlastnost | Co to znamená |
|---|---|
| **deterministická** | stejný vstup → **vždy** stejný hash (jinak by přihlášení nefungovalo) |
| **lavinový efekt** | změna jediného písmene → **úplně jiný** hash, nedá se poznat „jak moc" se vstupy liší |
| **pevná délka** | heslo `a` i celá kniha mají hash stejně dlouhý |
| **jednosměrná** | z hashe **nejde spočítat** původní text |

**Vyzkoušej si v NDG** (`sha256sum` je obyčejný hash, na hesla se v `/etc/shadow` používá složitější
varianta – princip je ale stejný; `-n` = bez znaku nového řádku na konci):

```bash
echo -n heslo | sha256sum
# 56b1db8133d9eb398aabd376f07bf8ab5fc584ea0b8bd6a1770200cb613ca005  -
echo -n heslo | sha256sum          # znovu → PŘESNĚ stejný hash (deterministická)
# 56b1db8133d9eb398aabd376f07bf8ab5fc584ea0b8bd6a1770200cb613ca005  -
echo -n Heslo | sha256sum          # jen velké H → úplně jiný hash (lavinový efekt)
# a522b2e58855d49bf2ca3754f625ff84613c5328421b29907ac6254b2380f97b  -
echo -n "toto je mnohem delsi text nez jedno heslo" | sha256sum
# 1d76fb806c30e12f7e70252aaa208c155a042a8e989e008c7f9b23e4cea64b0b  -   ← pořád 64 znaků
```

Z `56b1db81…` nijak nezjistíš, že to bylo `heslo` – leda bys to **uhádl** a zkusil (viz níže).

### Jak probíhá ověření hesla

```
 napíšeš heslo ──► vezme se sůl z /etc/shadow ($6$nfffgggc$…)
                         │
                         ▼
              hash(tvoje heslo + sůl) ──► porovná s uloženým hashem
                                               │
                                     shoda ────┴──── neshoda
                                       ▼                ▼
                                   přihlášen     Authentication failure
```

Systém heslo **nikdy nedešifruje** – jen spočítá hash toho, co napíšeš, a **porovná** ho s uloženým.

**Hash vs. šifra:**

| | Šifrování | Hash |
|---|---|---|
| jde vrátit zpět? | **ano** – kdo má klíč, dostane původní text | **ne** – jednosměrná funkce, žádný klíč neexistuje |
| k čemu | přenos a uložení dat, která se budou číst (HTTPS, šifrovaný disk) | **ověření**, že znáš heslo, aniž by ho systém musel znát |

> Slidy píší „**šifrované** heslo" – technicky je to **hash**, ne šifra. V praxi se to tak říká, ale
> na zkoušce se rozdíl hodí znát.
>
> 💡 **Analogie:** šifra je **trezor** – kdo má klíč, vyndá obsah zpátky. Hash je **smoothie** –
> zpátky to nejde nikomu, ani tomu, kdo ho udělal.

### Sůl – proč mají dva lidé se stejným heslem jiný hash

**Co by bylo špatně bez soli:** kdyby se hashovalo jen samotné heslo, pak:

1. všichni, kdo mají heslo `heslo123`, by měli v `/etc/shadow` **stejný hash** – na první pohled by
   bylo vidět, kdo má stejné heslo,
2. existují předem spočítané tabulky „hash → heslo" pro miliony běžných hesel (*rainbow tables*).
   Stačilo by v nich hash najít a heslo přečíst, bez jakéhokoliv počítání.

**Jak to řeší sůl:** při nastavení hesla se vygeneruje **náhodná sůl** a hashuje se `heslo + sůl`.
Sůl se uloží **vedle hashe** v čitelné podobě – není tajná, jejím smyslem je jen udělat každý hash unikátní.

```
$6$abc12345$sP0TPe5RxdnixbHn5hkaBnxPY3s.7DS4cQFI…
│ │        └ samotný hash
│ └ sůl (náhodná, uložená čitelně)
└ algoritmus: 6 = SHA-512
```

**Vyzkoušej si** – `openssl passwd` vyrobí hash ve stejném formátu jako v `/etc/shadow`:

```bash
openssl passwd -6 -salt abc12345 heslo123
# $6$abc12345$sP0TPe5RxdnixbHn5hkaBnxPY3s.7DS4cQFI15KWqvPaDGDgdHwKsnrDHe2/fgcUM..vu5HyGOeCcWZyUk9DO0
openssl passwd -6 -salt xyz98765 heslo123      # STEJNÉ heslo, JINÁ sůl → úplně jiný hash
# $6$xyz98765$Y9JnY3JfHfkXyO7I/jqIhgcb5yTxJFSsTK0z20PXNewyFPAeElij93sBbMxje.HWO97M5NBj1PSryOaltka220
openssl passwd -6 -salt abc12345 heslo123      # stejné heslo + stejná sůl → zase stejný hash
```

Přesně tohle dělá systém při přihlášení: vezme sůl `abc12345` ze shadow, spočítá
`hash(tvoje heslo + abc12345)` a porovná s uloženým hashem.

> 🧪 Nové Ubuntu ukládá hesla jako **yescrypt** (`$y$…`), který `openssl` neumí – princip je ale stejný.

### Hash nejde dešifrovat – ale slabé heslo jde **uhádnout**

Když se hash nedá obrátit, jak potom unikají hesla? Útočník, který získá `/etc/shadow`, hash
**nedešifruje** – místo toho **hádá**. Vezme nějaké heslo, zahashuje ho stejným postupem (sůl vidí
přímo v souboru) a porovná. Když se hash shoduje, heslo uhodl. Zkouší přitom:

- **slovník** – seznam běžných a dříve uniklých hesel (`123456`, `heslo`, `Praha2026`) a jejich obměny,
- **hrubou sílu** (*brute force*) – postupně všechny kombinace znaků.

Je to „jen" hádání, ale rychlé: specializovaný software na výkonné grafické kartě zvládne
miliony až miliardy pokusů za sekundu. Krátké nebo slovníkové heslo tak padne během chvíle,
dlouhé a nepředvídatelné prakticky ne. **Celá bezpečnost hesla tedy stojí na tom, že ho útočník
neuhodne.** (Správci stejný postup používají legálně při auditu vlastních systémů, aby odhalili
slabá hesla uživatelů.)

**Proč se tomu dá bránit** – čtyři vrstvy, každá hádání ztěžuje:

| Obrana | Co dělá | Analogie |
|---|---|---|
| **`/etc/shadow` čte jen root** | útočník se k hashům vůbec nedostane | zamčený šuplík |
| **sůl** | každý hash je unikátní → rainbow tables nefungují a každý účet se musí řešit zvlášť | každý dá do smoothie jinou přísadu |
| **pomalý algoritmus** | `$6$` (SHA-512) se opakuje 5000×, **yescrypt** (`$y$`) navíc spotřebuje hodně paměti → méně pokusů za sekundu. Proto je **MD5 `$1$` zastaralé** – je moc rychlé | mixér, který schválně jede celou sekundu |
| **silné heslo** | útočník ho nemá ve slovníku a kombinací je příliš mnoho | dlouhý kód k trezoru |

**Jak poznat silné heslo:**

| Heslo | Odolnost |
|---|---|
| `heslo123`, `Praha2026`, jméno, datum narození | mizivá – je ve slovníku útočníka |
| 8 náhodných znaků | na hraně – u rychlých hashů ho grafické karty zvládnou projít za hodiny až dny |
| dlouhá fráze, např. `kun-modry-skace-pres-plot` | prakticky neprolomitelné hádáním |

> 💡 **Délka je důležitější než složitost.** Každý znak navíc **násobí** počet kombinací, které musí
> útočník projít, kdežto `a` → `@` útočník čeká. Proto se dnes doporučují dlouhé **passphrase** (věty)
> a pro každou službu jiné heslo ze **správce hesel** – aby únik z jednoho webu neohrozil ostatní účty.

**Data jsou počty dní od 1. 1. 1970** (Unix epoch):

```bash
date -d "1970-01-01 +20769 days" +%F         # 2026-11-12   – den → datum
echo $(( $(date +%s) / 86400 ))               # dnešní den jako číslo
sudo chage -l sysadmin                        # nejpohodlněji – chage to převede sám
```

Prázdné heslo je bezpečnostně špatně (výjimkou může být stroj bez sítě). Mnoho distribucí ho
zakazuje přes **PAM** (*Pluggable Authentication Modules*) – rámec, přes který programy jako `login`,
`su`, `sudo` nebo `sshd` ověřují uživatele. PAM řeší **ověření** (heslo), **správu účtu** (vypršel?),
**relace** (co udělat při přihlášení) a **změnu hesla** (pravidla síly hesla). Konfigurace je v `/etc/pam.d/`.

```bash
sudo passwd -d test_user     # root může heslo smazat (pole 2 bude prázdné) – jen pro ukázku!
```

> ⚠️ **Opravy oproti slidům (`/etc/shadow`):**
>
> - Pole 3 není „dny **od** poslední změny hesla", ale **datum** poslední změny – počet dní od 1. 1. 1970.
> - Pole 5 není „počet dní, které **zbývají** do vypršení", ale **maximální stáří** hesla – kolik dní
>   po změně heslo platí.
> - Soubor má **9 polí** – první tabulka ve slidech končí osmým. Druhá tabulka („Stárnutí uživatelských
>   hesel") zase **vynechává pole 7** (neaktivita) – mezi varováním a datem vypršení účtu chybí.
> - `$1$` v ukázce je MD5 – dnes zastaralé, současné systémy používají `$6$` nebo `$y$`.

## 1.4 Systémové a běžné účty

Kromě lidí mají účty i **služby** – `www-data` (web), `mail`, `ftp`, `daemon`, `nobody`…
Služba pak **neběží jako root** – když ji někdo napadne, získá jen práva svého účtu.
Systémové účty jsou v `/etc/passwd`, ale **nedá se na ně přihlásit** (shell `/usr/sbin/nologin`
nebo `/bin/false`, v shadow `*`).

```bash
grep -E 'nologin|false' /etc/passwd | head -5
# daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
# www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
grep -E '^(UID|GID|SYS_UID|SYS_GID)_(MIN|MAX)' /etc/login.defs
# UID_MIN   1000
# UID_MAX  60000
# GID_MIN   1000
# GID_MAX  60000
```

| UID | Komu patří |
|---|---|
| `0` | **root** |
| `1` – `999` | **systémové** účty (služby) |
| `1000` + | **běžní uživatelé** (první vytvořený člověk má obvykle 1000) |
| `65534` | `nobody` – „nikdo", nejnižší práva |

> ⚠️ **Zastaralé ve slidech:** „Ve většině distribucí je vyhrazený rozsah systémových účtů 0 až 499"
> a ukázka `UID_MIN 500` / `GID_MIN 500` – to platilo pro staré Red Hat (do RHEL 6).
> **Dnes** mají prakticky všechny distribuce běžné uživatele **od 1000** (viz i výpis `login.defs`
> ve stejném slidu). Na tradičním UNIXu byla hranice 100.

## 1.5 Vytvoření uživatele – `useradd`

```bash
sudo useradd -D                     # výchozí hodnoty z /etc/default/useradd
# GROUP=100
# HOME=/home
# INACTIVE=-1                       ← -1 = vypnuto (ve slidu chybně „-l")
# EXPIRE=
# SHELL=/bin/sh                     ← Ubuntu: /bin/sh, Red Hat: /bin/bash
# SKEL=/etc/skel
# CREATE_MAIL_SPOOL=no
sudo useradd -D -s /bin/bash        # změna výchozího shellu pro NOVÉ uživatele
```

| Volba | Význam |
|---|---|
| `-m` | **vytvoří domovský adresář** (a zkopíruje do něj `/etc/skel`) |
| `-d /cesta` | jiný domovský adresář |
| `-s /bin/bash` | přihlašovací shell |
| `-c "Jan Novák"` | GECOS (komentář) |
| `-u 1500` | konkrétní UID |
| `-g skupina` | primární skupina (místo nové stejnojmenné) |
| `-G sk1,sk2` | **doplňkové** skupiny |
| `-N` | nevytvářet stejnojmennou skupinu (pak `-g`) |
| `-e 2026-12-31` | datum vypršení **účtu** (`RRRR-MM-DD`) |
| `-f 10` | kolik dní po vypršení hesla se účet zablokuje |
| `-k /etc/skel_dev` | jiná šablona místo `/etc/skel` – **jen spolu s `-m`** |
| `-r` | **systémový** účet (UID < 1000, bez domova) |

**Ukázka v NDG:**

```bash
sudo useradd -m -s /bin/bash -c "Test User" test_user
tail -1 /etc/passwd
# test_user:x:1002:1002:Test User:/home/test_user:/bin/bash
sudo tail -1 /etc/shadow
# test_user:!:20769:0:99999:7:::      ← ! = heslo zatím není, nedá se přihlásit
ls -la /home/test_user              # .bashrc, .profile, .bash_logout – z /etc/skel
sudo passwd test_user               # nastav heslo (dvakrát), až pak se dá přihlásit
su - test_user                      # zkus se přihlásit; zpět: exit
```

> ⚠️ **Debian/Ubuntu vs. Red Hat:**
>
> | | Red Hat | Debian / Ubuntu |
> |---|---|---|
> | `useradd test_user` vytvoří domov? | ano (`CREATE_HOME yes` v `login.defs`) | **ne** – musíš přidat **`-m`** |
> | výchozí shell | `/bin/bash` | `/bin/sh` – přidej **`-s /bin/bash`** |
> | heslo po vytvoření | `!!` | `!` |
> | pohodlnější nástroj | – | **`adduser`** – interaktivní, zeptá se na heslo i jméno |
>
> ⚠️ **Opravy oproti slidům:**
>
> - `tail -l /etc/passwd` – správně **`tail -1`** (číslice jedna = poslední řádek) nebo `tail -n 1`.
>   Písmeno `l` `tail` nezná.
> - „Heslo pro nového uživatele je nastaveno na `!!!`" – ve výpisu je `!!` (dva vykřičníky).

### Soukromé skupiny uživatelů (UPG)

**User Private Group** – při `useradd test_user` vznikne i skupina **`test_user`** a uživatel je jejím
jediným členem (jeho primární skupina). Výhoda: soubory uživatele nepatří do společné skupiny, takže
s `umask 002` nikomu dalšímu nedá právo zápisu. UPG používá **Red Hat i Debian/Ubuntu**
(slidy zmiňují jen Red Hat). Potlačit jde volbami **`-N -g jiná_skupina`**.

```bash
getent group test_user              # test_user:x:1002:
sudo gpasswd -A test_user test_user # test_user je SPRÁVCEM své skupiny…
# …a může do ní pak sám přidávat (bez sudo):  gpasswd -a joe test_user
```

### `/etc/skel` – šablona domovského adresáře

Obsah `/etc/skel` se **zkopíruje** do domova každého **nového** uživatele (`useradd -m`).
Stávajícím uživatelům se nic nepřidá. Uživatel je vlastníkem kopií a smí je měnit i mazat.

```bash
ls -la /etc/skel                    # .bashrc  .bash_logout  .profile
echo "Vitej v laboratori!" | sudo tee /etc/skel/README.txt
sudo useradd -m -s /bin/bash novak
sudo ls -la /home/novak             # README.txt je tam; stávající test_user ho nemá
```

**Typické použití:** výchozí `.bashrc` s aliasy, záložky prohlížeče (adresář `.mozilla` – vytvoř
dočasného uživatele, nastav mu Firefox, zkopíruj jeho `.mozilla` do `/etc/skel`), firemní nastavení.

**Více šablon** pro různé typy uživatelů:

```bash
sudo useradd -m -k /etc/skel_admin bob
sudo useradd -m -k /etc/skel_dev   sue
sudo useradd -m -k /etc/skel_clerk tim
```

> ⚠️ **Chyba ve slidech:** `useradd -k /etc/skel_dev sue` **bez `-m`** – volba `-k` funguje jen
> spolu s `-m` (bez vytvoření domova není kam kopírovat). Na Ubuntu by `useradd` skončil chybou.

## 1.6 Hesla – `passwd`

```bash
passwd                       # změna VLASTNÍHO hesla: 1× současné, 2× nové
sudo passwd test_user        # root nastaví heslo komukoliv (na staré se neptá)
sudo passwd -S test_user     # stav hesla
# test_user P 2026-11-12 0 99999 7 -1
#           │ │          │ │     │ └ neaktivita (-1 = vypnuto)
#           │ │          │ │     └ varování
#           │ │          │ └ max. stáří
#           │ │          └ min. stáří
#           │ └ poslední změna
#           └ P = platné heslo, L = zamčené (locked), NP = žádné heslo
```

| Úkon | `passwd` | `usermod` |
|---|---|---|
| **zamknout** účet (před hash přidá `!`) | `sudo passwd -l test_user` | `sudo usermod -L test_user` |
| **odemknout** (odebere `!`) | `sudo passwd -u test_user` | `sudo usermod -U test_user` |
| smazat heslo (bez hesla!) | `sudo passwd -d test_user` | – |
| vynutit změnu při příštím přihlášení | `sudo passwd -e test_user` | – |
| max. / min. stáří, varování, neaktivita | `passwd -x / -n / -w / -i` | – |

```bash
sudo grep test_user /etc/shadow | cut -c1-30    # test_user:$y$j9T$...
sudo passwd -l test_user
sudo grep test_user /etc/shadow | cut -c1-30    # test_user:!$y$j9T$...   ← ! na začátku
su - test_user                                  # su: Authentication failure
sudo passwd -u test_user
```

> ❗ Zamčení heslem (`passwd -l`) nezablokuje přihlášení **SSH klíčem** – na úplné zablokování
> slouží `sudo usermod -e 1 test_user` (účet vypršel 2. 1. 1970) nebo shell `/usr/sbin/nologin`.
>
> ⚠️ **Opravy oproti slidům (`passwd`):**
>
> - „budete **dvakrát** vyzváni k zadání stávajícího hesla a nového hesla" – současné heslo zadáš
>   **jednou**, nové **dvakrát** (pro kontrolu překlepu).
> - Nadpis tabulky „Výstup příkazu `passwd -s`" – správně **`passwd -S`** (velké S). Malé `-s` nic neukáže.
> - „Chcete-li zamknout a odemknout heslo, použijte volby `-L` a `-U`" s ukázkou `passwd -L` – `passwd`
>   má **malá** `-l` / `-u`. Velká `-L` / `-U` jsou volby **`usermod`**.
> - V ukázce po `passwd -l joe` je řádek shadow uříznutý – správně má být `joe:!$6$MJEowZ…`
>   (tedy stejný řádek s `!` na začátku hashe).

## 1.7 Stárnutí hesel – `chage`

**Ch**ange **age** – nastavuje pole 4–8 v `/etc/shadow` u **existujících** účtů. (Hodnoty
v `/etc/login.defs` – `PASS_MAX_DAYS`, `PASS_MIN_DAYS`, `PASS_WARN_AGE` – platí jen pro **nově
vytvořené** účty.)

```
 změna hesla                      vypršení hesla              zablokování účtu
     │                                 │                             │
     ├── -m (min) ──┤                  │                             │
     │  nesmí měnit │                  │                             │
     ├──────────────── -M (max) ───────┤                             │
     │                     ├─ -W (varuj)┤                             │
     │                                 ├────── -I (neaktivita) ──────┤
     │                                 │  smí se přihlásit, ale MUSÍ  │
     │                                 │  si heslo změnit            │
                                                                     
 -E (datum vypršení účtu) – samostatné pevné datum, kdy účet končí bez ohledu na heslo
```

| Volba | Význam | Pole shadow |
|---|---|---|
| `-l` | **zobrazit** nastavení (běžný uživatel jen u sebe) | – |
| `-d 0` | datum poslední změny (`0` = vynutí změnu hesla při přihlášení) | 3 |
| `-m 5` | min. dní mezi změnami | 4 |
| `-M 90` | max. dní platnosti hesla | 5 |
| `-W 7` | kolik dní předem varovat | 6 |
| `-I 10` | dní po vypršení hesla, než se účet zablokuje | 7 |
| `-E 2026-12-31` | datum vypršení **účtu** (`-E -1` = zrušit) | 8 |

```bash
sudo chage -M 90 -W 7 -I 10 test_user
sudo chage -E 2026-12-31 test_user
sudo chage -l test_user
# Last password change                     : Nov 12, 2026
# Password expires                         : Feb 10, 2027
# Password inactive                        : Feb 20, 2027
# Account expires                          : Dec 31, 2026
# Minimum number of days between password change : 0
# Maximum number of days between password change : 90
# Number of days of warning before password expires : 7
sudo grep test_user /etc/shadow
# test_user:$y$…:20769:0:90:7:10:20818:
sudo chage test_user             # bez voleb = interaktivně se zeptá na všechno
```

Varování se zobrazí **jen při přihlášení**: `Warning: your password will expire in 5 days`.

> ⚠️ **Opravy oproti slidům (`chage`):**
>
> - `chage -E 2025-06-01 test_user q` – písmeno `q` na konci je navíc.
> - Ukázka pak ve `/etc/shadow` ukazuje `16222` – to je **1. 6. 2014**, ne 2025 (2025-06-01 = `20240`).
>   Příklad zůstal z původního kurzu, jen se přepsal rok.
> - „uživatel se pokusí přihlásit 91 dní po poslední změně hesla, bude **zablokován**" – po vypršení
>   hesla je uživatel nejdřív jen **donucen heslo změnit**. Zablokován je až po uplynutí doby
>   neaktivity (`-I`) – přesně jak popisuje další slide. Když `-I` není nastavené (`-1`), zablokován
>   není nikdy.
> - U `/etc/default/useradd` slidy píší `INACTIVE` = „počet dní po **změně** hesla" – správně
>   po **vypršení** hesla.

## 1.8 Úprava uživatele – `usermod`

| Volba | Význam |
|---|---|
| `-c "Bob"` | GECOS / komentář |
| `-s /bin/zsh` | shell |
| `-d /home/new -m` | nový domov (`-m` = **přesune** i obsah; bez něj se jen změní cesta) |
| `-l nove_jmeno` | přejmenuje účet (login) |
| `-g dba` | **primární** skupina |
| `-aG sk1,sk2` | **přidá** do doplňkových skupin ⭐ |
| `-G sk1,sk2` | **nastaví** doplňkové skupiny – **ostatní odebere!** |
| `-e 2026-04-30` | datum vypršení účtu |
| `-L` / `-U` | zamknout / odemknout heslo |

```bash
sudo groupadd dba
sudo usermod -aG dba test_user       # přidá do dba
id test_user                         # uid=1002(test_user) gid=1002(test_user) groups=1002(test_user),1003(dba)
sudo usermod -c "Bob Builder" -s /bin/sh test_user
grep -w test_user /etc/passwd        # ověření
```

> ❗ **Nejčastější chyba:** `usermod -G sudo pepa` **bez `-a`** odebere Pepu ze všech ostatních
> doplňkových skupin. Vždy **`-aG`**. A změna skupin se projeví až po **novém přihlášení** uživatele.
>
> ⚠️ **Opravy oproti slidům (`usermod`):**
>
> - „Chcete-li ověřit změny…, použijte `grep`" a ukázka **`usermod -w test_user /etc/passwd`** –
>   správně **`grep -w test_user /etc/passwd`**.
> - „všimněte si **jiného formátu** než u příkazu `chage`" – formát je **stejný**: `RRRR-MM-DD`.
> - Slidy píší volby **za** jménem (`usermod test_user -e …`). GNU nástroje to snesou, ale zvyk
>   (a manuál) je **volby před jménem**: `usermod -e 2026-04-30 test_user`.
> - `usermod -d /home/new test_user` jen změní cestu v `/etc/passwd` – adresář nevytvoří ani nepřesune.
>   Přidej **`-m`**.

## 1.9 Smazání uživatele – `userdel`

```bash
sudo userdel test_user        # smaže záznam z /etc/passwd, /etc/shadow a ze skupin v /etc/group
sudo userdel -r test_user     # + domovský adresář a poštovní schránku
sudo userdel -f test_user     # i když je přihlášený (násilně)
```

`-r` smaže **jen domov a poštu**. Soubory uživatele jinde (`/tmp`, sdílené adresáře) zůstanou
a místo jména budou mít jen **číslo UID** („sirotci"). Před smazáním je dobré je najít:

```bash
sudo find / -user test_user 2>/dev/null       # soubory uživatele (dokud existuje)
sudo find / -nouser -o -nogroup 2>/dev/null   # soubory, jejichž vlastník/skupina už neexistuje
```

> ❗ Nový uživatel může později dostat **stejné UID** a „zdědí" tak cizí osiřelé soubory.
> Proto osiřelé soubory po smazání účtu smaž, nebo předej jinému vlastníkovi (`chown`).

## 1.10 Skupiny

Skupiny usnadňují správu: práva se dají jednou skupině a všichni její členové je mají.
Příklady: skupina **`sudo`** (Ubuntu) nebo **`wheel`** (Red Hat) = smí používat `sudo`;
každý tým má svou skupinu pro sdílený adresář (viz setgid adresář v cv06).

### `/etc/group`

```
dba:x:1003:mike,john,will
│   │ │    └ 4 doplňkoví členové (oddělení čárkou)
│   │ └ 3 GID
│   └ 2 heslo – x = je v /etc/gshadow (většinou žádné)
└ 1 název skupiny
```

- **Primární skupina** – jedna; uvedená v `/etc/passwd` (pole 4). Dostane ji **každý nový soubor**,
  který uživatel vytvoří.
- **Doplňkové (sekundární) skupiny** – libovolný počet; uvedené v `/etc/group` (pole 4).
  Primární skupina v tomto seznamu obvykle **není** – uživatel je jejím členem „automaticky".

```bash
groups                        # moje skupiny – PRVNÍ = aktuální primární
groups test_user
id                            # gid= primární, groups= všechny
getent group sudo             # sudo:x:27:sysadmin
getent passwd sysadmin | cut -d: -f4    # GID VÝCHOZÍ primární skupiny
newgrp dba                    # dočasně jiná primární skupina (nový shell) – viz cv06; zpět exit
```

> `groups` ukazuje **aktuální** primární skupinu (po `newgrp` se změní), `/etc/passwd` / `getent passwd`
> vždy **výchozí** – tu, se kterou se přihlásíš.
>
> ⚠️ **Nepřesnost ve slidech:** „výchozí primární skupinu zjistíte příkazem `getent group joe`" – to
> vypíše **skupinu jménem `joe`**, a funguje to jen díky UPG (skupina se jmenuje stejně jako uživatel).
> Obecně je výchozí primární skupina v **`getent passwd joe`** (pole 4) nebo v `id -gn joe`.

### `groupadd`, `groupmod`, `groupdel`

```bash
sudo groupadd test_group                # GID přidělí automaticky (nejbližší volné ≥ 1000)
sudo groupadd -g 1980 test_group2       # konkrétní GID
sudo groupadd -r sysgroup               # SYSTÉMOVÁ skupina (GID < 1000)
tail -3 /etc/group

sudo groupmod -g 1981 test_group        # změna GID
sudo groupmod -n admin_group test_group # přejmenování (-n nový název)
sudo groupdel admin_group               # smazání
```

Skupinu **nejde smazat**, pokud je **primární** skupinou některého uživatele:

```
groupdel: cannot remove the primary group of user 'test_user'
```

Smazání skupiny, která **vlastní soubory**, je zrádné – soubory pak mají místo názvu jen číslo GID:

```bash
sudo groupadd test_group
touch /tmp/sample && sudo chgrp test_group /tmp/sample
ls -l /tmp/sample        # -rw-rw-r-- 1 sysadmin test_group 0 … /tmp/sample
sudo groupdel test_group
ls -l /tmp/sample        # -rw-rw-r-- 1 sysadmin 1004       0 … /tmp/sample   ← jen číslo
```

> ⚠️ **Opravy oproti slidům (skupiny):**
>
> - „Pokud chcete vytvořit **systémovou** skupinu, spusťte `groupadd test_group`" – chybí volba
>   **`-r`**: `groupadd -r test_group`.
> - U `groupdel` text mluví o `test_group`, ale příkaz je `groupdel dba`.

### `/etc/gshadow` a `gpasswd`

```
dba:!::mike,john,will
│   │ │└ 4 členové
│   │ └ 3 správci skupiny (smí přidávat/odebírat členy)
│   └ 2 heslo skupiny (! = žádné)
└ 1 název
```

```bash
sudo gpasswd -A test_user dba     # test_user je SPRÁVCEM skupiny dba
sudo gpasswd -a joe dba           # přidat člena (smí i správce skupiny bez sudo)
sudo gpasswd -d joe dba           # odebrat člena
sudo gpasswd dba                  # nastavit heslo skupiny (pro newgrp nečlenů) – v praxi skoro nepoužívané
sudo gpasswd -r dba               # odebrat heslo skupiny
sudo grep dba /etc/gshadow
```

Heslo skupiny dovolí uživateli, který **není členem**, udělat `newgrp dba` – po zadání hesla.

> ⚠️ **Opravy oproti slidům (`gshadow`, `gpasswd`):**
>
> - Ukázka `test_group:$1$nfffgggc$pGt#4:1980:admin:dba,sys` má **5 polí včetně GID** – `/etc/gshadow`
>   má jen **4 pole** a **GID v něm není** (ten je jen v `/etc/group`). Správně např.
>   `test_group:$1$…:admin:dba,sys`.
> - Na slidu „Příkaz gpasswd" má být příkaz, ale je tam znovu ten řádek z gshadow. Správně:
>   **`gpasswd -A test_user dba`**.

---

# 2. Account Security

## 2.1 SUID / SGID – skutečné a efektivní ID

Jak setuid/setgid fungují a jak se nastavují, je v **cv06, kapitola 2.7**. Doplnění:

Každý proces má několik identit:

| ID | Význam |
|---|---|
| **skutečné** (real UID) | kdo proces **spustil** (ty) |
| **efektivní** (effective UID) | **podle čeho se kontrolují práva** |
| **uložené** (saved UID) | záloha, aby se program mohl mezi nimi přepínat |

Normálně jsou skutečné i efektivní stejné. Když spustíš program se **SUID** (např. `passwd`), skutečné UID
zůstane tvoje, ale efektivní se stane UID **vlastníka souboru** (root) – proto `passwd` smí zapsat do
`/etc/shadow`. Po skončení programu se nic „nevrací" – efektivní UID platilo jen pro ten jeden proces.
**SGID** na programu dělá totéž se skupinou (`/usr/bin/wall` → skupina `tty`).

```bash
ls -l /usr/bin/passwd /usr/bin/wall
# -rwsr-xr-x 1 root root … /usr/bin/passwd   ← s u vlastníka = SUID
# -rwxr-sr-x 1 root tty  … /usr/bin/wall     ← s u skupiny  = SGID
```

**Malé `s` vs. velké `S`:**

```bash
touch junk.txt
chmod u+s junk.txt ; ls -l junk.txt     # -rwSr--r--   S = SUID BEZ práva x (nesmysl, nic nedělá)
chmod u+x junk.txt ; ls -l junk.txt     # -rwsr--r--   s = SUID + x
chmod 4755 junk.txt; ls -l junk.txt     # -rwsr-xr-x   4000 = SUID
chmod 2755 junk.txt; ls -l junk.txt     # -rwxr-sr-x   2000 = SGID
chmod u-s,g-s junk.txt                  # odebrat
```

> ⚠️ **Chyba ve slidech:** „Pokud je u spustitelného souboru nastaven bit SUID nebo **sticky**…
> Bit **sticky** umožňuje běžnému uživateli dočasně se stát rootem" – to dělá **SUID**, ne sticky.
> **Sticky bit** (`t`, 1000) se dává na **adresáře** (`/tmp`) a znamená „cizí soubory nesmíš mazat" (cv06).

## 2.2 Audit SUID/SGID souborů

SUID program vlastněný rootem je **potenciální díra** – chyba v něm = útočník je root. Útočník si také
rád nechá „zadní vrátka" jako SUID kopii shellu. Správce proto sleduje, které SUID/SGID soubory existují:

```bash
find / -type f -perm -4000 2>/dev/null          # SUID
find / -type f -perm -2000 2>/dev/null          # SGID
find / -type f -perm /6000 2>/dev/null          # SUID NEBO SGID (/ = aspoň jeden bit)
```

**Základní linie (baseline)** – po čisté instalaci si seznam uložíš a později porovnáš:

```bash
sudo find / -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | sort > ~/cv08/special.perm
# … o měsíc později …
sudo find / -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | sort > ~/cv08/special.new
diff ~/cv08/special.perm ~/cv08/special.new && echo "beze změn"
```

Ideální úloha pro **cron** (plánovač úloh, démon `crond`/`cron`) – spouštět jednou měsíčně automaticky.

> ⚠️ **Opravy oproti slidům (audit):**
>
> - `find / -type f -perm -4000 2>/dev/| less` – chybí `null`: **`2>/dev/null`**.
> - `find / -perm -4000 -o -perm -2000 -ls` – kvůli prioritě operátorů se `-ls` použije **jen na druhou
>   podmínku** (`-perm -2000`), SUID soubory se nevypíšou. Podmínky se `-o` patří do **závorek**:
>   `find / \( -perm -4000 -o -perm -2000 \) -ls` – nebo jednodušeji `find / -perm /6000 -ls`.

## 2.3 `sudo` a `/etc/sudoers`

Základy `sudo` jsou v cv06. `sudo` chce **tvoje** heslo, ne heslo roota, a pamatuje si ho chvíli
(výchozí **5 minut**, Ubuntu **15 minut**; mění se v `sudoers` volbou `timestamp_timeout`).

```bash
sudo -l                      # CO smím přes sudo spustit (velmi užitečné!)
sudo -u test_user whoami     # spustit jako jiný uživatel než root
sudo -k                      # zapomeň uložené heslo (příště se zeptá znovu)
sudo -v                      # obnov uložené heslo (prodluž časový limit)
sudo -n true                 # nikdy se neptej na heslo – když by bylo potřeba, skonči chybou (pro skripty)
sudo -b prikaz               # spusť na pozadí
```

**Konfigurace** – `/etc/sudoers`, upravuje se **jen přes `visudo`** (zkontroluje syntaxi před uložením –
chyba v `sudoers` = nefunkční `sudo` pro všechny):

```bash
sudo visudo                               # celý soubor
sudo visudo -f /etc/sudoers.d/test_user   # LEPŠÍ: vlastní soubor v sudoers.d
sudo visudo -c                            # jen kontrola syntaxe
sudo grep -v '^#' /etc/sudoers | grep -v '^$'   # co v něm je
# root    ALL=(ALL:ALL) ALL
# %sudo   ALL=(ALL:ALL) ALL                ← % = skupina; členové sudo smí všechno
```

**Pravidlo (specifikace):**

```
kdo     kde = (jako_kdo)  co
pepa    ALL = (root)      /usr/bin/apt, /usr/bin/systemctl
%dba    DBNET = (ALL)     ALL
```

**Aliasy** – pojmenované seznamy pro přehlednost:

```
User_Alias  OPERATORS = user1, user2, user3        # seznam UŽIVATELŮ
Host_Alias  DBNET     = 172.16.0.0/255.255.224.0   # počítače / sítě
Runas_Alias OP        = root, operator             # pod kým smí spouštět
Cmnd_Alias  EDITORS   = /usr/bin/vim, /usr/bin/nano  # příkazy (plné cesty!)

OPERATORS   ALL = ALL                # řádek 1
testuser1   DBNET = (ALL) ALL        # řádek 2
testuser2   ALL = EDITORS            # řádek 3
pepa        ALL = (root) NOPASSWD: /usr/bin/systemctl restart apache2
```

| Řádek | Význam |
|---|---|
| 1 | uživatelé z aliasu OPERATORS smí na všech strojích spouštět vše (jako root) |
| 2 | `testuser1` smí na strojích v síti DBNET spustit cokoliv jako kdokoliv |
| 3 | `testuser2` smí spouštět `vim` a `nano` – **jen jako root** (chybí `(…)`, výchozí je root) |
| 4 | `pepa` smí restartovat apache **bez hesla** (`NOPASSWD:`) |

> ⚠️ **Opravy oproti slidům (`sudo`):**
>
> - Řádek 3 (`testuser2 ALL= EDITORS`) slidy vysvětlují „jako uživatel root **nebo jako jakýkoli jiný
>   uživatel**" – bez `(…)` platí jen **root**. Pro „kohokoliv" by muselo být `testuser2 ALL=(ALL) EDITORS`.
> - V tabulce je přeložené `OPERÁTORY ALL=ALL` – alias se musí jmenovat stejně jako v definici: `OPERATORS`.
>   A není to „skupina OPERATORS", ale **alias** se seznamem uživatelů (skupina by se psala `%název`).
> - Ukázka `root@localhost:~# sudo apt-get install …` – root `sudo` nepotřebuje; ukázka patří
>   běžnému uživateli (`sysadmin@localhost:~$`).
> - „`sudo` si pamatuje heslo 15 minut" – to je výchozí hodnota Ubuntu; obecná výchozí hodnota `sudo` je **5 minut**.
>
> ⚠️ **V NDG opatrně:** pokud si `sudoers` rozbiješ, `sudo` přestane fungovat a pomůže jen restart labu.
> Zkoušej přes `visudo -f /etc/sudoers.d/…` – soubor jde pak jednoduše smazat.

## 2.4 `su`

```bash
su -                         # root s jeho prostředím (heslo ROOTA)
su - test_user               # jiný uživatel s jeho prostředím (heslo test_user)
su test_user                 # jiný uživatel, ale ZŮSTANE moje prostředí (PATH, adresář…)
su - test_user -c 'id'       # jen jeden příkaz a hned zpět
su -m test_user              # zachovej proměnné prostředí (-m / -p)
exit                         # zpět
```

| Volba | Význam |
|---|---|
| `-`, `-l` | **přihlašovací** shell – načte profil cílového uživatele, přejde do jeho domova |
| `-c 'příkaz'` | spustí jen jeden příkaz |
| `-m`, `-p` | nemění proměnné prostředí |

`su` chce **heslo cílového účtu**, `sudo` **tvoje** heslo. Root může `su` na kohokoliv bez hesla
(`sudo su - test_user` – ale lepší je `sudo -iu test_user`).

> ⚠️ **Chyba ve slidech:** `su -user1` – mezi `-` a jménem musí být **mezera**: **`su - user1`**.
> (`su -user1` by se chápalo jako shluk jednopísmenných voleb `-u -s -e -r -1` a skončí chybou.)

## 2.5 Síť z pohledu bezpečnosti – `nmap`, `netstat`, `ss`

Každý otevřený port = služba, na kterou se dá zaútočit. **Co neběží, nejde napadnout.**

```bash
sudo ss -tulnp               # co na MÉM stroji poslouchá a který program (viz cv07, 3.4)
sudo netstat -tulnp          # totéž postaru („tulnp" ve slidech jako -lunpt – pořadí je jedno)
```

**`nmap`** (network mapper) – skener portů zvenku. Používají ho správci (audit) i útočníci.

```bash
nmap localhost               # TCP porty: PORT  STATE  SERVICE
# PORT   STATE SERVICE
# 22/tcp open  ssh
# 53/tcp open  domain
sudo nmap -sT -sU localhost  # TCP connect + UDP sken (UDP potřebuje root)
nmap -sn 192.168.1.0/24      # jen zjistit, které počítače v síti žijí (ping sken)
```

| Stav | Význam |
|---|---|
| `open` | na portu **poslouchá** aplikace |
| `closed` | port je dosažitelný, ale nic na něm neposlouchá |
| `filtered` | **firewall** sondy zahazuje – nedá se určit, jestli je otevřený |
| `unfiltered` | port je dosažitelný, ale nmap neurčí, jestli je otevřený nebo zavřený |

> ❗ **Skenuj jen své stroje nebo s písemným povolením.** Sken cizí sítě může být posouzen jako
> pokus o útok (v ČR i trestný čin podle § 230 trestního zákoníku – neoprávněný přístup).
>
> ⚠️ **Opravy oproti slidům (`nmap`):**
>
> - Výstup je přeložený nesmyslně: „STÁTNÍ PŘÍSTAVNÍ SLUŽBA" = `STATE PORT SERVICE` 🙂, stavy
>   „otevřít / uzavřeno / filtrováno" = `open / closed / filtered`.
> - Ukázka `nmap -sT -sU example.com` končí výpisem „Nebyly zadány žádné cíle" – výstup k příkazu nepatří.
>   UDP sken (`-sU`) navíc vyžaduje **root**.
> - `nmap -sP` je **zastaralá** volba, dnes **`-sn`**.
>
> 🧪 V NDG `nmap` nejspíš není – náhradou je `ss -tuln` a `nc -zv localhost 20-80` (cv07, 3.7).

## 2.6 Kdo má otevřený soubor – `lsof`, `fuser`

```bash
lsof -p $$                   # soubory otevřené mým shellem ($$ = PID shellu)
sudo lsof -u sysadmin        # vše, co má otevřené uživatel
sudo lsof -i                 # síťová spojení a naslouchající porty (jako ss -tulnp)
sudo lsof -i TCP:22          # kdo používá port 22
sudo lsof -i @127.0.0.1      # spojení na/z adresy
sudo lsof /var/log/syslog    # kdo má otevřený tento soubor
```

Sloupce: `COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME` – `FD` = jak je soubor otevřený
(`cwd` = pracovní adresář, `rtd` = kořenový adresář, `txt` = program, `mem` = knihovna, `3u` = deskriptor 3 čtení i zápis).

```bash
fuser -v ~/cv08              # které procesy používají adresář
#                      USER        PID ACCESS COMMAND
# /home/sysadmin/cv08: sysadmin    82 ..c..  bash
fuser -v -n tcp 22           # proces na portu 22
sudo fuser -k soubor         # ⚠️ UKONČÍ všechny procesy, které soubor používají
```

`ACCESS`: **`c`** = aktuální (pracovní) adresář, **`r`** = kořenový adresář, **`e`** = spuštěný program,
**`f`** = otevřený soubor, **`m`** = namapovaná knihovna.

> 💡 Typické použití: „`umount: target is busy`" – `fuser -vm /mnt/usb` řekne, kdo disk drží.
>
> ⚠️ **Opravy oproti slidům:**
>
> - Ukázka `fuser -v` je spuštěná jako `fuser /` bez `-v`.
> - U `lsof -i TCP:25` slidy píší „seznam **všech** programů naslouchajících portům" – je to jen **port 25**.

## 2.7 Limity uživatelů – `ulimit`, `limits.conf`

Omezují prostředky shellu a procesů, které z něj spustíš – ochrana proti tomu, aby jeden uživatel
(nebo chybný skript, třeba „fork bomba") nezahltil celý systém.

```bash
ulimit -a                    # všechny (měkké) limity; v závorce je volba
# core file size          (blocks, -c) 0
# open files                      (-n) 1024
# max user processes              (-u) 1048576
ulimit -Sn                   # měkký limit otevřených souborů
ulimit -Hn                   # tvrdý limit otevřených souborů
bash -c 'ulimit -u 100; ulimit -u'      # snížit limit procesů – v podshellu, ať si nezkazíš svůj
```

| Typ | Kdo nastavuje | Pravidlo |
|---|---|---|
| **hard** (tvrdý) | root | strop, vynucuje jádro; běžný uživatel ho smí jen **snížit** |
| **soft** (měkký) | i uživatel | výchozí hodnota; uživatel ji smí měnit **do výše tvrdého** |

**Trvale** – `/etc/security/limits.conf` (a `/etc/security/limits.d/*.conf`), platí od **příštího přihlášení**:

```
#<doména>   <typ>  <položka>  <hodnota>
*           soft   core       0          # všem: žádné core dumpy
@student    hard   nproc      20         # skupina student: max. 20 procesů
@faculty    soft   nproc      20
@faculty    hard   nproc      50
ftp         hard   nproc      0
@student    -      maxlogins  4          # - = soft i hard zároveň
1000:2000   hard   nofile     4096       # rozsah UID
```

**Doména:** jméno uživatele, `@skupina`, `*` (všichni), rozsah UID `min:max` nebo GID `@min:max`.
**Položky:** `core` (velikost core dumpu, KB), `data`, `fsize` (velikost souboru, KB), `memlock`,
`nofile` (otevřené soubory), `nproc` (procesy), `maxlogins`.

> ⚠️ **Opravy oproti slidům (`ulimit`):**
>
> - „Chcete-li tento limit snížit, proveďte…" a pak znovu **`ulimit -a`** – správně např. **`ulimit -u 100`**.
> - „Zobrazená hodnota je tvrdý (skutečný) limit" – `ulimit -a` ukazuje **měkké** limity; tvrdé `ulimit -Ha`.
> - Slide „Syntaxe těchto konfiguračních souborů" nikde neříká **kterých** – jde o `/etc/security/limits.conf`.
> - Ukázka `limits.conf` je přeložená (`#* měkké jádro 0`) – v souboru jen anglicky: `* soft core 0`.

## 2.8 Kdo je přihlášený – `who`, `w`, `last`

```bash
who                          # kdo je právě přihlášen
# root     tty2   2026-11-12 10:00
# sysadmin pts/1  2026-11-12 10:00 (192.168.1.50)   ← v závorce = vzdáleně
who -b                       # kdy naposledy nastartoval systém
who -r                       # aktuální runlevel
whoami                       # jen já

w                            # podrobněji + co kdo dělá a zátěž systému
#  10:44:03 up 50 min,  4 users,  load average: 0.78, 0.44, 0.19
# USER     TTY   FROM          LOGIN@  IDLE   JCPU   PCPU WHAT
# root     tty2  -             10:00   43:44  0.01s  0.01s -bash

last                         # historie přihlášení a restartů ze /var/log/wtmp
last -5 sysadmin             # posledních 5 přihlášení uživatele
last reboot                  # historie restartů
sudo lastb                   # NEÚSPĚŠNÉ pokusy o přihlášení (/var/log/btmp) – útoky na heslo!
lastlog                      # poslední přihlášení každého účtu
```

| Sloupec `w` | Význam |
|---|---|
| `TTY` | terminál – `tty1` = fyzická konzole, `pts/0` = okno terminálu / SSH |
| `FROM` | odkud (IP, jméno, `:0` = grafická relace) |
| `LOGIN@` / `IDLE` | kdy se přihlásil / jak dlouho nic nedělá |
| `JCPU` / `PCPU` | čas CPU všech procesů terminálu / aktuálního procesu |
| `WHAT` | co právě běží |

> Ve slidech je příkaz `last` přeložený jako „**Poslední** příkaz" a ve výstupu „restart systému" –
> v terminálu `last` a `reboot system boot`.
>
> 🧪 V NDG mohou být `who`, `w` i `last` **prázdné** – webový terminál labu se nezapisuje jako
> přihlášení do `utmp`/`wtmp`. Zkus `su - test_user` v druhém terminálu nebo `ssh localhost`, pokud běží SSH.

---

# 3. Host Security

Většina útoků přichází **po síti** – zabezpečení tedy začíná u síťových služeb: **co neběží, nejde napadnout**.
Starý přístup to řešil „super servery" `inetd` / `xinetd`, nový systemd **socket aktivací**.

## 3.1 Super server `xinetd` (historicky)

Místo aby každá služba (telnet, ftp…) běžela neustále, běží jen **`xinetd`**. Ten poslouchá na jejich
portech a službu **spustí až při příchozím spojení**. Přidává řízení přístupu (odkud, kdy, kolik).

- Konfigurace: `/etc/xinetd.conf` + soubor pro každou službu v **`/etc/xinetd.d/`**.
- `wait = yes` → **jednovláknová** služba (požadavky postupně), `wait = no` → **vícevláknová**
  (každé spojení nový proces, paralelně).

```
# /etc/xinetd.d/telnet
service telnet
{
    disable         = no
    flags           = REUSE
    socket_type     = stream
    wait            = no
    user            = root
    server          = /usr/sbin/in.telnetd
    only_from       = 192.168.1.0/24
    no_access       = 192.168.1.66
    access_times    = 08:00-17:00
    log_on_failure += USERID
}
```

```bash
sudo /etc/init.d/xinetd restart     # postaru;  dnes: sudo systemctl restart xinetd
```

Volby démona: `-f soubor` (jiný konfigurační soubor), `-dontfork` (běž v popředí),
`-limit N` (max. procesů), `-filelog soubor` (log do souboru).

> ⚠️ **Opravy oproti slidům (`xinetd`):**
>
> - „Služba `xinetd` se **nyní používá ve všech** systémech Linux" – **neplatí**. Dnes je to výjimka;
>   na moderních distribucích ho nahradila **systemd socket aktivace** (3.2) a ve výchozí instalaci není.
> - Tabulka klíčů je přeložená (`služba`, `příznaky`, `čekat`, `uživatel`, `skupina`, `zakázat`) –
>   v souboru musí být anglicky: `service`, `flags`, `wait`, `user`, `group`, `disable`.

## 3.2 systemd – socket jednotky (`.socket`)

Moderní obdoba `xinetd`: systemd poslouchá na portu/soketu a příslušnou službu spustí, až když přijde
spojení (**socket activation**). `.socket` jednotka patří ke stejnojmenné `.service`.

```ini
# /lib/systemd/system/ssh.socket
[Unit]
Description=OpenBSD Secure Shell server socket
Before=ssh.service
Conflicts=ssh.service
ConditionPathExists=!/etc/ssh/sshd_not_to_be_run

[Socket]
ListenStream=22
Accept=yes

[Install]
WantedBy=sockets.target
```

```bash
systemctl list-sockets --all                 # LISTEN  UNIT  ACTIVATES
systemctl list-unit-files --type=socket      # UNIT FILE  STATE (enabled/disabled/static)
systemctl cat ssh.socket                     # obsah jednotky
```

> ⚠️ **Opravy oproti slidům (systemd):**
>
> - Ukázka jednotky je **přeložená** (`[Jednotka]`, `[Zásuvka]`, `[Instalovat]`, `Popis=`, `Před=`) –
>   systemd zná jen `[Unit]`, `[Socket]`, `[Install]`, `Description=`, `Before=`.
>   A `ConditionsPathExists` → **`ConditionPathExists`** (bez s).
> - `systemctl list-sockets -all` a `list-unit-files -type=socket` – dlouhé volby mají **dvě pomlčky**:
>   `--all`, `--type=socket`. (`listunit-files` v textu = `list-unit-files`.)
>
> 🧪 V NDG kontejneru systemd neběží – `systemctl` vypíše *System has not been booted with systemd*.

## 3.3 TCP Wrappers – `/etc/hosts.allow`, `/etc/hosts.deny`

Řízení přístupu **podle adresy klienta** pro služby zkompilované s knihovnou **`libwrap`**
(historicky `xinetd`, `sshd`, `sendmail`, `vsftpd`). Doplněk k firewallu, ne jeho náhrada.

```
 příchozí spojení na službu s libwrap
          │
  povoluje ho hosts.allow? ── ano ──► PŘÍSTUP POVOLEN
          │ ne
  zakazuje ho hosts.deny? ─── ne ───► PŘÍSTUP POVOLEN
          │ ano
     spojení ZAHOZENO
```

`hosts.allow` se čte **první** a první shoda vyhrává. Typické nastavení „povol jen vyjmenované":

```
# /etc/hosts.allow
sshd: 192.168.1.0/255.255.255.0, .netdevgroup.com    # tečka na začátku = celá doména
sendmail: ALL
ALL: LOCAL

# /etc/hosts.deny
ALL: ALL                                             # všechno ostatní zakaž
```

**Podporuje služba TCP Wrappers?**

```bash
ldd /usr/sbin/sshd | grep libwrap          # vypíše libwrap.so…  → ano
strings /usr/sbin/sshd | grep hosts_access # starší způsob
```

> ⚠️ **Zastaralé:** TCP Wrappers jsou dnes na ústupu – **RHEL 8 je odstranil úplně** a nové verze
> OpenSSH s `libwrap` v řadě distribucí nejsou zkompilované. Na zkoušku je ale znát potřebuješ;
> v praxi se přístup řeší **firewallem** (`nftables`, `firewalld`, `ufw`) a nastavením služby samotné.

## 3.4 Zákaz přihlášení – `/etc/nologin`

Existuje-li soubor **`/etc/nologin`**, smí se přihlásit **jen root**. Ostatním se zobrazí jeho obsah
a přihlášení se odmítne (`login`, `ssh`). Používá se při **údržbě**.

```bash
# ⚠️ jen ukázka – v labu by mohl zablokovat přihlášení
echo 'System down for maintenance until 14:00' | sudo tee /etc/nologin
sudo rm /etc/nologin                     # po údržbě NEZAPOMEŇ smazat
```

Pro jednoho uživatele místo toho stačí shell **`/usr/sbin/nologin`** (`sudo usermod -s /usr/sbin/nologin pepa`).

> Ve slidu je `until 14pm` – buď `2pm`, nebo `14:00`. A `sudo echo … > /etc/nologin` by nefungovalo
> (přesměrování dělá tvůj shell bez práv roota, viz cv04) – proto `| sudo tee`.

## 3.5 `init`, runlevely a systemd targety

**`init`** je **první proces**, který spustí jádro – má **PID 1** a spouští všechno ostatní.
Starý **SysV init** čte `/etc/inittab` a pracuje s **úrovněmi běhu (runlevels)**:

| Runlevel | Debian | Red Hat | systemd target (dnes) |
|---|---|---|---|
| 0 | vypnutí | vypnutí | `poweroff.target` |
| 1 / S | jeden uživatel, údržba | jeden uživatel, údržba | `rescue.target` |
| 2 | **výchozí** – víceuživatelský, grafika, síť | nepoužívá se | `multi-user.target` |
| 3 | jako 2 | **výchozí** – víceuživatelský, text, síť | `multi-user.target` |
| 4 | jako 2 | nepoužívá se | `multi-user.target` |
| 5 | jako 2 | grafický víceuživatelský | `graphical.target` |
| 6 | restart | restart | `reboot.target` |

```bash
runlevel                     # N 3  → předchozí (N = žádný) a aktuální
who -r                       # totéž jinak
grep initdefault /etc/inittab   # id:3:initdefault:   – výchozí runlevel (jen SysV)
sudo init 3                  # ⚠️ přepnutí runlevelu bez restartu (init 0 = vypnout, init 6 = restart)

# systemd (dnešní distribuce)
systemctl get-default        # graphical.target
sudo systemctl set-default multi-user.target
sudo systemctl isolate rescue.target   # ⚠️ obdoba init 1
ps -p 1 -o pid,comm          # co běží jako PID 1 (systemd / init; v kontejneru něco jiného)
```

**Init skripty** – v **`/etc/init.d/`**, každý umí `start`, `stop`, `restart`, `status`, `reload`:

```bash
sudo /etc/init.d/networking restart     # postaru
sudo service ssh status                 # obal, funguje se SysV i systemd
sudo systemctl restart ssh              # systemd
```

Které služby se spustí v kterém runlevelu, určují **symbolické odkazy** v `/etc/rc0.d/` … `/etc/rc6.d/`
(Debian) nebo `/etc/rc.d/rc0.d/` … (Red Hat), např. `/etc/rc3.d/S20ssh -> ../init.d/ssh`
(`S` = start, `K` = kill/stop, číslo = pořadí). Při `init 3` spustí `init` skript `/etc/init.d/rc 3`,
ten **zastaví** služby s `K` a **spustí** služby s `S` pro runlevel 3.

> ⚠️ **Opravy oproti slidům (init):**
>
> - Adresáře odkazů nejsou `/etc/init.d/rc0.d` – `/etc/rc6.d`, ale **`/etc/rc0.d` – `/etc/rc6.d`**
>   (Debian) nebo `/etc/rc.d/rc0.d` – `rc6.d` (Red Hat).
> - Parametry skriptů jsou přeložené („Zastavte", „Restartování", „Znovu načíst") – správně
>   **`start`, `stop`, `restart`, `status`, `reload`**.
> - `/etc/init.d/xinetd restart`, `/etc/init.d/networking restart` – na systemd distribucích dnes
>   `systemctl restart …`.
>
> 🧪 V NDG kontejneru `runlevel` vypíše nejspíš `unknown` a PID 1 není `init` ani `systemd` – kontejner
> nebootuje celý systém.

---

# Úlohy k procvičení

Pracuj v `~/cv08`. Na konci po sobě ukliď (úloha 26).

### 1. User and Group Accounts

1. Vypiš řádek svého účtu v `/etc/passwd` a urči UID, GID, domov a shell. Proč může `/etc/passwd`
   číst každý, ale `/etc/shadow` jen root?
2. Vypiš všechny účty, které se **nemohou přihlásit** (shell `nologin` nebo `false`), a spočítej je.
3. Vypiš jména všech **běžných** uživatelů (UID ≥ 1000, kromě `nobody`).
4. Zjisti z `/etc/login.defs` rozsah UID pro běžné uživatele a výchozí `PASS_MAX_DAYS`.
5. Zobraz výchozí nastavení `useradd`. Jaký shell dostane nový uživatel na Ubuntu?
6. Vytvoř uživatele `test_user` s domovem, shellem `/bin/bash` a komentářem „Test User".
   Ověř v `/etc/passwd`, `/etc/shadow`, `/etc/group` a v jeho domově.
7. Nastav `test_user` heslo a ověř stav příkazem `passwd -S`. Co znamená `!` v `/etc/shadow` před a po?
8. Zamkni účet `test_user`, ověř, že se nejde přihlásit (`su - test_user`), a zase ho odemkni.
9. Nastav `test_user`: heslo platí max. 60 dní, varování 5 dní předem, 7 dní neaktivity, účet vyprší
   31. 12. 2026. Ověř `chage -l` i v `/etc/shadow`. Převeď číslo z pole 8 na datum.
10. Vynuť, aby si `test_user` při příštím přihlášení musel změnit heslo.
11. Přidej do `/etc/skel` soubor `vitej.txt`, vytvoř uživatele `novak` a ověř, že ho má.
    Má ho i `test_user`? Proč?
12. Vytvoř skupiny `vyvoj` a `test` (pro `test` GID 2000). Přidej `test_user` do obou, aniž by
    přišel o jiné skupiny. Ověř `id test_user`.
13. Co by se stalo, kdybys v úloze 12 použil `usermod -G test test_user` (bez `-a`)? Vyzkoušej a ověř.
14. Udělej z `test_user` správce skupiny `vyvoj` a přidej (jako `test_user`) do ní `novak`.
15. Přejmenuj skupinu `test` na `qa` a změň jí GID na 2001.
16. Vytvoř soubor `/tmp/sirotek`, dej mu skupinu `qa` a skupinu smaž. Co uvidíš v `ls -l`? Jak najdeš
    všechny takové soubory?

### 2. Account Security

17. Najdi všechny SUID **a** SGID soubory v `/usr/bin` jedním příkazem `find`.
18. Ulož si seznam SUID/SGID souborů z celého systému jako baseline, přidej SUID na kopii `/bin/ls`
    v `~/cv08` a ukaž, že porovnání změnu odhalí. Pak SUID odeber.
19. Vytvoř soubor, nastav mu SUID bez práva `x` a pak s ním. Jak se liší výpis `ls -l`?
20. Zjisti, co smíš přes `sudo` spouštět. Pak (přes `visudo -f`) povol uživateli `test_user` spouštět
    jako root jen `/usr/bin/apt` a ověř `sudo -l -U test_user`. Soubor pak smaž.
21. Spusť `id` jako `test_user` pomocí `su` i pomocí `sudo`. Kdy se zadává čí heslo?
22. Zjisti měkký a tvrdý limit počtu otevřených souborů. V podshellu snižte limit procesů na 50 a ověř.
23. Napiš řádek do `limits.conf`, který skupině `vyvoj` omezí počet procesů na 100 (tvrdě).
24. Zjisti, kdo je přihlášený, kdy naposledy nastartoval systém a historii přihlášení.

### 3. Host Security

25. Napiš (nespouštěj): pravidla TCP Wrappers, aby se na SSH dalo připojit jen ze sítě `192.168.1.0/24`
    a na nic jiného odnikud. Do kterého souboru co patří?
26. Ukliď: smaž uživatele `test_user` a `novak` i s domovy, skupiny `vyvoj`, soubor `/etc/skel/vitej.txt`
    a `/tmp/sirotek`.
27. Jaký systemd target odpovídá runlevelu 3 a 5? Jaký je výchozí target / runlevel v labu?

<details>
<summary>Řešení</summary>

```bash
cd ~/cv08

# 1
grep "^$USER:" /etc/passwd          # pole 3 UID, 4 GID, 6 domov, 7 shell
# passwd čtou programy (ls, id…), aby převedly UID na jméno; hashe hesel jsou v shadow – ten jen root

# 2
grep -E 'nologin|false$' /etc/passwd
grep -cE 'nologin|false$' /etc/passwd

# 3
awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' /etc/passwd

# 4
grep -E '^(UID_MIN|UID_MAX|PASS_MAX_DAYS)' /etc/login.defs

# 5
sudo useradd -D                     # SHELL=/bin/sh

# 6
sudo useradd -m -s /bin/bash -c "Test User" test_user
grep test_user /etc/passwd
sudo grep test_user /etc/shadow     # test_user:!:…  (! = heslo není nastavené)
grep test_user /etc/group           # UPG – skupina test_user
ls -la /home/test_user              # soubory z /etc/skel

# 7
sudo passwd test_user
sudo passwd -S test_user            # test_user P …   (před nastavením L)
sudo grep test_user /etc/shadow | cut -c1-25
# před: ! = účet bez hesla, zamčený; po: $y$… nebo $6$… = hash

# 8
sudo passwd -l test_user            # nebo sudo usermod -L test_user
sudo passwd -S test_user            # L
su - test_user                      # su: Authentication failure
sudo passwd -u test_user

# 9
sudo chage -M 60 -W 5 -I 7 -E 2026-12-31 test_user
sudo chage -l test_user
sudo grep test_user /etc/shadow     # …:0:60:5:7:20818:
date -d "1970-01-01 +20818 days" +%F     # 2026-12-31

# 10
sudo passwd -e test_user            # nebo sudo chage -d 0 test_user
sudo chage -l test_user             # Last password change: password must be changed

# 11
echo "Vitej!" | sudo tee /etc/skel/vitej.txt
sudo useradd -m -s /bin/bash novak
sudo ls -la /home/novak             # vitej.txt je
sudo ls -la /home/test_user         # není – /etc/skel se kopíruje jen při vytvoření účtu

# 12
sudo groupadd vyvoj
sudo groupadd -g 2000 test
sudo usermod -aG vyvoj,test test_user
id test_user

# 13
sudo usermod -G test test_user
id test_user                        # zůstala jen primární test_user a test – vyvoj ZMIZELA
sudo usermod -aG vyvoj test_user    # oprava

# 14
sudo gpasswd -A test_user vyvoj
su - test_user -c 'gpasswd -a novak vyvoj'     # heslo test_user (po úloze 10 si ho nejdřív musí změnit)
getent group vyvoj                  # vyvoj:x:…:test_user,novak

# 15
sudo groupmod -n qa test
sudo groupmod -g 2001 qa
getent group qa                     # qa:x:2001:test_user

# 16
touch /tmp/sirotek
sudo chgrp qa /tmp/sirotek
sudo groupdel qa
ls -l /tmp/sirotek                  # místo názvu skupiny jen 2001
sudo find / -nogroup 2>/dev/null    # všechny soubory bez existující skupiny (-nouser pro vlastníka)

# 17
find /usr/bin -type f -perm /6000 -ls
# nebo: find /usr/bin -type f \( -perm -4000 -o -perm -2000 \) -ls

# 18
sudo find / -type f -perm /6000 2>/dev/null | sort > special.perm
cp /bin/ls ~/cv08/mujls && chmod u+s ~/cv08/mujls
sudo find / -type f -perm /6000 2>/dev/null | sort > special.new
diff special.perm special.new       # > /home/sysadmin/cv08/mujls
chmod u-s ~/cv08/mujls

# 19
touch suid.txt
chmod u+s suid.txt; ls -l suid.txt  # -rwSrw-r--   velké S = SUID bez x
chmod u+x suid.txt; ls -l suid.txt  # -rwsrw-r--   malé s = SUID + x

# 20
sudo -l
sudo visudo -f /etc/sudoers.d/test_user
#   do souboru napiš:   test_user ALL=(root) /usr/bin/apt
sudo -l -U test_user
sudo rm /etc/sudoers.d/test_user

# 21
su - test_user -c id                # heslo TEST_USER (cílového účtu)
sudo -u test_user id                # heslo SYSADMIN (moje) – a jen když mám právo v sudoers

# 22
ulimit -Sn; ulimit -Hn
bash -c 'ulimit -u 50; ulimit -u'   # 50 – jen v podshellu, můj shell zůstane beze změny

# 23
# /etc/security/limits.conf  (nebo /etc/security/limits.d/vyvoj.conf)
# @vyvoj   hard   nproc   100

# 24
who
w
who -b
last | head                         # v NDG může být prázdné

# 25
# /etc/hosts.allow:
#   sshd: 192.168.1.0/255.255.255.0
# /etc/hosts.deny:
#   ALL: ALL
# hosts.allow se čte první → SSH ze sítě 192.168.1.0/24 projde, vše ostatní zastaví hosts.deny

# 26
sudo userdel -r test_user
sudo userdel -r novak
sudo groupdel vyvoj
sudo rm /etc/skel/vitej.txt /tmp/sirotek
# skupiny test_user a novak (UPG) smazal userdel automaticky

# 27
# runlevel 3 = multi-user.target, runlevel 5 = graphical.target
runlevel; systemctl get-default     # v NDG kontejneru nejspíš nebude fungovat
```

</details>

---

# Tahák

### Soubory

| Soubor | Pole |
|---|---|
| `/etc/passwd` | `jméno:x:UID:GID:GECOS:domov:shell` |
| `/etc/shadow` | `jméno:hash:posl.změna:min:max:varování:neaktivita:vypršení:rezerva` |
| `/etc/group` | `skupina:x:GID:členové` |
| `/etc/gshadow` | `skupina:heslo:správci:členové` |
| `/etc/login.defs` | `UID_MIN`, `GID_MIN`, `PASS_MAX_DAYS`, `PASS_MIN_DAYS`, `PASS_WARN_AGE`, `UMASK` |
| `/etc/default/useradd`, `/etc/skel/` | výchozí hodnoty / šablona domova pro nové uživatele |
| `/etc/sudoers`, `/etc/sudoers.d/` | práva `sudo` – jen přes `visudo` |
| `/etc/security/limits.conf` | limity uživatelů |
| `/etc/hosts.allow`, `/etc/hosts.deny` | TCP Wrappers |
| `/etc/nologin` | zakáže přihlášení všem kromě roota |

### Uživatelé

| Potřebuju… | Příkaz |
|---|---|
| vytvořit uživatele | `useradd -m -s /bin/bash -c "Jméno" jmeno` (Ubuntu: i `adduser jmeno`) |
| výchozí nastavení useradd | `useradd -D` |
| heslo | `passwd` (své), `sudo passwd jmeno` |
| stav hesla | `passwd -S jmeno` (P / L / NP) |
| zamknout / odemknout | `passwd -l` / `-u` nebo `usermod -L` / `-U` |
| vynutit změnu hesla | `passwd -e jmeno`, `chage -d 0 jmeno` |
| stárnutí hesla | `chage -l`, `-M max`, `-m min`, `-W varování`, `-I neaktivita`, `-E RRRR-MM-DD` |
| přidat do skupiny | **`usermod -aG skupina jmeno`** |
| shell / komentář / domov | `usermod -s`, `-c`, `-d … -m` |
| smazat | `userdel jmeno`, `userdel -r jmeno` (i domov) |
| kdo jsem / info o účtu | `id`, `groups`, `getent passwd jmeno` |
| osiřelé soubory | `find / -nouser -o -nogroup` |

### Skupiny

| Potřebuju… | Příkaz |
|---|---|
| vytvořit | `groupadd skupina`, `-g GID`, `-r` (systémová) |
| upravit | `groupmod -n novy_nazev`, `groupmod -g GID` |
| smazat | `groupdel skupina` (nesmí být něčí primární) |
| členové / správci | `gpasswd -a user sk`, `-d user sk`, `-A user sk` |
| dočasně jiná primární | `newgrp skupina` (zpět `exit`) |

### Zabezpečení

| Potřebuju… | Příkaz |
|---|---|
| SUID / SGID soubory | `find / -type f -perm /6000 2>/dev/null` |
| co smím přes sudo | `sudo -l`; jako jiný uživatel `sudo -u user prikaz` |
| upravit sudoers | `sudo visudo`, `sudo visudo -f /etc/sudoers.d/soubor` |
| jiný uživatel | `su - user`, `su - user -c 'prikaz'` |
| otevřené porty | `sudo ss -tulnp`, `sudo netstat -tulnp`, `nmap host` |
| kdo drží soubor / port | `lsof soubor`, `lsof -i :22`, `fuser -v soubor` |
| limity | `ulimit -a`, `ulimit -Sn` / `-Hn` |
| kdo je přihlášený / historie | `who`, `w`, `last`, `sudo lastb`, `lastlog` |
| runlevel / target | `runlevel`, `who -r`, `systemctl get-default` |
| socket jednotky | `systemctl list-sockets --all` |

---

# Příprava na cvičení 09

Podle zadání – samostudium, splněné laby a testy z modulu:

- **Linux Essentials – Module 18 – Special Directories and Files**

Poslední slide navíc říká: **„V rámci přípravy se zaměřte na Challenge Labs a přípravu na zápočtový test."**

- **Challenge Labs** – v NDG jsou to laby bez návodu krok za krokem, kde máš úkol vyřešit sám.
- Na zápočtový test si zopakuj taháky z cvičení [02](../02/README.md), [03](../03/README.md),
  [04](../04/README.md), [05](../05/README.md), [06](../06/README.md), [07](../07/README.md) a tohoto.
- Module 18 navazuje na **cvičení 06** (sticky bit, setgid adresáře, odkazy) – speciální adresáře
  (`/tmp`), soubory a odkazy.
