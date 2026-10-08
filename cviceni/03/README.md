# Cvičení 03 – Práce se soubory, hledání a archivace

Podle **NDG Linux Essentials** a labů **Linux I.**:

- **Module 7 – Navigating the Filesystem**
- **Module 8 – Managing Files and Directories**
- Linux I. – **File Globbing**, **File Manipulation**, **Finding Files**, **Archive Commands**

**Vstupní požadavky:** splněné *Lab 07 + Chapter 07 Exam* a *Lab 08 + Chapter 08 Exam* a Exams z předchozích modulů.

Vše si zkoušíme v laboratorním prostředí **NDG NETLAB+** na [portal.netdevgroup.com](https://portal.netdevgroup.com/).

---

## 0. Příprava prostředí

1. Přihlas se na [portal.netdevgroup.com](https://portal.netdevgroup.com/) a spusť **Lab** příslušného modulu.
2. Jsi přihlášen jako **`sysadmin`**, heslo pro `sudo` je **`netlab123`**.
3. V `~/Documents` jsou připravené ukázkové soubory (`red.txt`, `numbers.txt`, `letters.txt`, `profile.txt`, `animals.txt`…), se kterými pracují i slidy.

Aby sis nerozbil originály, pracuj v kopii:

```bash
cp -r ~/Documents ~/cv03
cd ~/cv03
ls
```

> Lab je **dočasný** – po jeho ukončení se vše smaže, takže se nemusíš bát experimentovat.

### Co znamená `~` (tilda)

`~` je **zkratka pro domovský adresář** přihlášeného uživatele. Shell ji před spuštěním příkazu nahradí skutečnou cestou (stejně jako rozbaluje `*`).

| Zápis | Znamená | V NDG |
|---|---|---|
| `~` | můj domovský adresář | `/home/sysadmin` |
| `~/cv03` | adresář `cv03` v mém domovském adresáři | `/home/sysadmin/cv03` |
| `~root` | domovský adresář uživatele `root` | `/root` |
| `~jmeno` | domovský adresář uživatele `jmeno` | `/home/jmeno` |

```bash
echo ~                  # /home/sysadmin
echo $HOME              # totéž – hodnota proměnné HOME
echo ~/cv03             # /home/sysadmin/cv03
echo ~root              # /root
cd /etc ; cd ~          # návrat domů (stejně jako samotné "cd")
pwd
```

V promptu `sysadmin@localhost:~$` tilda říká, že **právě jsem ve svém domovském adresáři**.
Po `cd /etc` se prompt změní na `sysadmin@localhost:/etc$`.

> - `~` se rozbalí jen **na začátku slova** a **ne v uvozovkách**: `echo "~"` vypíše doslova `~`.
>   V uvozovkách použij `"$HOME"`.
> - Proč je to užitečné: `~/cv03` funguje odkudkoliv a pro každého uživatele vede do *jeho* domovského adresáře –
>   nemusím psát celou cestu `/home/sysadmin/cv03`.

---

# 1. File Globbing (zástupné znaky)

**Globy** (*wildcards*) slouží k práci se **skupinami souborů** najednou. Vzor rozbalí **shell ještě před spuštěním příkazu** – příkaz (`ls`, `cp`, `rm`…) už dostane hotový seznam jmen.

| Znak | Význam |
|---|---|
| `*` | libovolný řetězec znaků, **včetně prázdného** |
| `?` | **právě jeden** libovolný znak |
| `[ ]` | **právě jeden** znak ze zadané sady / rozsahu |
| `[! ]` nebo `[^ ]` | **právě jeden** znak, který **není** v sadě |

### `*` – libovolný řetězec

```bash
cd ~
ls *               # všechny soubory v aktuálním adresáři (u adresářů vypíše i obsah)
ls -d *            # jen jména, bez obsahu adresářů
ls -d D*           # začínající na D:            Desktop Documents Downloads
ls -d D*n*         # začínající na D a obsahující n: Documents Downloads
ls -d *s           # končící na s
```

### `?` – právě jeden znak

```bash
cd /etc
ls -d ???          # jména dlouhá přesně 3 znaky
ls -d ????*        # jména dlouhá aspoň 4 znaky
ls -d ?a*          # druhé písmeno je a
```

### `[ ]` – jeden znak ze sady

```bash
cd /usr/bin
ls [a-c]*          # začínají na a, b nebo c
ls [abc]????*      # začínají na a/b/c a mají aspoň 5 znaků
ls [!a-c]*         # NEzačínají na a, b ani c
ls [^a-c]*         # totéž (^ funguje v bashi jako !)
ls *[!xyz]         # NEkončí na x, y ani z
ls *[0-9]          # končí číslicí
ls [[:upper:]]*    # začínají velkým písmenem (třída znaků)
```

> ⚠️ **Opravy oproti slidům:**
> - `ls [a-c]` hledá soubor pojmenovaný **jedním** písmenem a–c. Pro „začínající na a–c" je potřeba `ls [a-c]*`.
> - `ls* [^xyz]` je překlep – správně `ls *[^xyz]` (soubory, které **nekončí** na x, y, z).

### Na co si dát pozor

```bash
echo /etc/*.conf             # 💡 echo ukáže, na co se vzor rozbalí – vyzkoušej PŘED rm!
echo "/etc/*.conf"           # v uvozovkách se glob NErozbalí
ls *.neexistuje              # když nic neodpovídá, bash předá vzor doslova → chyba
ls -d .*                     # * nezahrnuje skryté soubory (začínající tečkou) – na ty je .*
```

---

# 2. File Manipulation (práce se soubory)

> V Linuxu je **všechno soubor** – běžné soubory, adresáře, zařízení (`/dev/sda`), i procesy (`/proc`).

| Příkaz | Co dělá |
|---|---|
| `ls` | výpis obsahu adresáře |
| `file` | zjistí **typ dat** v souboru |
| `touch` | vytvoří prázdný soubor / změní časovou známku |
| `cp` | kopíruje |
| `mv` | přesouvá / přejmenovává |
| `rm` | maže soubory (a s `-r` i adresáře) |
| `mkdir` | vytvoří adresář |
| `rmdir` | smaže **prázdný** adresář |

## 2.1 `ls` – výpis

| Volba | Význam |
|---|---|
| `-a` | i **skryté** soubory (začínající `.`) |
| `-l` | **dlouhý** výpis (detaily) |
| `-h` | velikosti čitelně (K, M, G) – s `-l` |
| `-S` | řadit podle **velikosti** (největší první) |
| `-t` | řadit podle **času změny** (nejnovější první) |
| `-r` | **obrácené** řazení |
| `-R` | **rekurzivně** – i obsah podadresářů |
| `-d` | vypíše adresář **samotný**, ne jeho obsah |

```bash
ls -a ~
ls -l ~
ls -lS /etc | head          # největší soubory v /etc
ls -lt ~/cv03               # nejnověji změněné nahoře
ls -ltr ~/cv03              # nejstarší nahoře
ls -R ~/cv03                # i podadresáře
ls -l /etc                  # obsah /etc
ls -ld /etc                 # informace o adresáři /etc samotném
```

### Význam sloupců `ls -l`

```
drwxr-xr-x 2 sysadmin sysadmin 4096 Apr 24 16:24 Desktop
│└───┬───┘ │ └──┬───┘ └──┬───┘ └┬─┘ └────┬────┘ └──┬──┘
│    │     │    │        │      │        │         └─ název souboru
│    │     │    │        │      │        └─ časová známka (poslední změna)
│    │     │    │        │      └─ velikost v bajtech
│    │     │    │        └─ skupina vlastníka
│    │     │    └─ uživatel vlastník
│    │     └─ počet hard linků
│    └─ oprávnění (vlastník / skupina / ostatní)
└─ typ souboru
```

| Typ | Význam |
|---|---|
| `-` | běžný soubor |
| `d` | adresář (directory) |
| `l` | symbolický odkaz (link) |
| `c` / `b` | znakové / blokové zařízení (`/dev`) |
| `s` / `p` | socket / roura (pipe) |

```bash
ls -l /dev/sda /dev/tty /bin/sh /etc/passwd ~   # zkus najít různé typy
```

## 2.2 `file` – co je v souboru

Linux **nepoužívá přípony** k určení typu – `file` se podívá do obsahu:

```bash
file ~/cv03/newhome.txt     # ASCII text
file /bin/ls                # ELF 64-bit LSB executable ...
file /etc                   # directory
file ~/cv03/*               # typ všech souborů

cp /bin/ls ~/obrazek.jpg
file ~/obrazek.jpg          # pořád ELF executable – přípona nic neznamená
rm ~/obrazek.jpg
```

## 2.3 `touch` – vytvoření souboru / změna času

`touch` dělá dvě věci:
1. Pokud soubor **neexistuje** → vytvoří **prázdný** soubor.
2. Pokud **existuje** → aktualizuje jeho **časovou známku** na „teď".

| Volba | Význam |
|---|---|
| (bez voleb) | změní čas přístupu i modifikace na aktuální |
| `-a` | změní jen čas **přístupu** (access) |
| `-m` | změní jen čas **modifikace** |
| `-c` | **nevytváří** soubor, pokud neexistuje (*no-create*) |
| `-t` | nastaví **konkrétní čas** ve tvaru `[[CC]YY]MMDDhhmm[.ss]` |

```bash
cd ~/cv03
touch novy.txt              # vytvoří prázdný soubor
ls -l novy.txt
touch novy.txt              # jen změní čas
ls -l novy.txt
touch -t 202001011200 novy.txt
ls -l novy.txt              # Jan  1  2020 novy.txt
touch -c neexistuje.txt
ls neexistuje.txt           # No such file – -c ho nevytvořil
stat novy.txt               # všechny 3 časy: Access, Modify, Change
```

> ⚠️ Slidy uvádí `-c` jako „atribut" – ve skutečnosti `-c` = **nevytvářet** soubor. Čas změny atributů (*ctime*) `touch` přímo nastavit neumí.

### K čemu je `touch` dobrý?

| Použití | Příklad | Proč |
|---|---|---|
| **Rychle vytvořit prázdný soubor** | `touch poznamky.txt` | nejrychlejší způsob, bez otevírání editoru |
| **Víc souborů najednou** | `touch a.txt b.txt c.txt`, `touch soubor{1..10}.txt` | testovací data pro cvičení s globbingem, `cp`, `rm`, `find` |
| **Připravit soubor, do kterého bude něco zapisovat** | `touch /var/log/moje_app.log` | některé programy vyžadují, aby log soubor už existoval |
| **„Značka" (flag / lock soubor)** | `touch ~/.zaloha_hotova` | skript pak jen testuje, jestli soubor existuje (`[ -f ~/.zaloha_hotova ]`) |
| **Označit soubor jako změněný** | `touch main.c` | nástroje jako `make` nebo zálohovací programy rozhodují podle času změny – touch je „přinutí" soubor znovu zpracovat |
| **Nastavit konkrétní datum** | `touch -t 202001011200 stary.txt` | testování – např. ověření, že `find -mtime +30` najde „staré" soubory |
| **Referenční čas** | `touch -t 202610080800 /tmp/ref` + `find ~ -newer /tmp/ref` | najde vše změněné **po** daném okamžiku |
| **Zkopírovat čas z jiného souboru** | `touch -r original.txt kopie.txt` | kopie bude mít stejné datum jako originál |

```bash
cd ~/cv03
touch soubor{1..5}.txt            # 5 prázdných souborů najednou
ls soubor*

touch -t 202001011200 soubor1.txt # "zestárnu" jeden soubor
find . -name 'soubor*' -mtime +30 # find ho najde jako starší než 30 dní

touch /tmp/ref                    # referenční bod "teď"
sleep 1
touch soubor3.txt                 # změním jiný soubor
find . -newer /tmp/ref            # najde jen ./soubor3.txt

rm soubor*.txt /tmp/ref           # úklid
```

## 2.4 `cp` – kopírování

```
cp [volby] ZDROJ CÍL
cp [volby] ZDROJ1 ZDROJ2 ... CÍLOVÝ_ADRESÁŘ
```

```bash
cd ~
cp /etc/hosts ~/hosts.txt         # zkopíruje a pojmenuje
cp /etc/hosts ~/                  # zkopíruje pod stejným jménem
cp ~/cv03/*.txt /tmp/             # více souborů najednou (glob)
cp -R /etc/perl ~                 # celý adresář (-R / -r = rekurzivně)
cp -v /etc/hosts ~/h2.txt         # -v vypíše, co dělá: '/etc/hosts' -> '/home/sysadmin/h2.txt'
cp -i /etc/hosts ~/h2.txt         # -i se zeptá, než přepíše existující soubor
cp -n /etc/hosts ~/h2.txt         # -n nikdy nepřepíše
cp -p /etc/hosts ~/h3.txt         # -p zachová čas, vlastníka a oprávnění
```

> ⚠️ `cp` bez `-i` **potichu přepíše** existující cílový soubor!
> Bez `-R` adresář nezkopíruje: `cp: -r not specified; omitting directory`.

## 2.5 `mv` – přesun a přejmenování

Stejná syntaxe jako `cp`, ale originál zmizí. **Přejmenování = přesun v rámci stejného adresáře.**

```bash
cd ~/cv03
mv novy.txt prejmenovany.txt      # přejmenování
mkdir archiv
mv prejmenovany.txt archiv/       # přesun do adresáře
mv *.csv archiv/                  # přesun více souborů
mv archiv archiv2                 # přejmenování adresáře – -R není potřeba
mv -i red.txt archiv2/            # -i: zeptá se před přepsáním
mv -v archiv2/red.txt .           # -v: vypíše, co dělá
```

## 2.6 `rm` – mazání

```bash
cd ~/cv03
touch file.txt
rm file.txt
ls file.txt                       # ls: cannot access 'file.txt': No such file or directory

rm -i a*                          # -i: potvrzení u každého souboru
# rm: remove regular file 'adjectives.txt'? n

rm -r archiv2                     # -r: smaže adresář i s obsahem
rm -rf adresar                    # -f: bez ptaní a bez chyb, když neexistuje
```

> ⚠️ **V Linuxu není koš.** Co `rm` smaže, je pryč.
> Před `rm` s globem si vždy nejdřív vyzkoušej vzor přes `ls` nebo `echo`:
> `echo a*` → zkontroluju → `rm a*`.

## 2.7 `mkdir` – vytvoření adresáře

```bash
cd ~
mkdir one two three               # víc adresářů najednou
ls
mkdir red/blue/yellow             # chyba: No such file or directory (red neexistuje)
mkdir -p red/blue/yellow/green    # -p vytvoří i chybějící rodičovské adresáře
ls -R red
mkdir -p red/blue                 # -p: žádná chyba, i když už existuje
mkdir -v dalsi                    # -v: vypíše, co vytvořil
```

## 2.8 `rmdir` – smazání prázdného adresáře

```bash
cd ~
rmdir one                         # OK – prázdný
mkdir test_directory
touch test_directory/soubor
rmdir test_directory              # rmdir: failed to remove 'test_directory': Directory not empty
rm -r test_directory              # adresář s obsahem → rm -r

rmdir -p red/blue/yellow/green    # -p smaže i rodiče, pokud po smazání zůstanou prázdné
ls red                            # už neexistuje
```

| Chci smazat… | Příkaz |
|---|---|
| soubor | `rm soubor` |
| **prázdný** adresář | `rmdir adresar` (nebo `rm -d`) |
| adresář **s obsahem** | `rm -r adresar` |
| prázdnou cestu adresářů | `rmdir -p a/b/c` |

---

# 3. Finding Files (hledání souborů)

## 3.1 FHS – Filesystem Hierarchy Standard

**FHS** je standard, který určuje, **kam v Linuxu co patří**. Díky němu víš, kde hledat konfiguraci, programy nebo logy na jakékoliv distribuci.

| Adresář | Účel |
|---|---|
| `/` | kořen celého souborového systému |
| `/bin` | základní uživatelské programy (`ls`, `cp`…) |
| `/sbin` | systémové / administrátorské programy |
| `/boot` | jádro a soubory zavaděče |
| `/dev` | soubory reprezentující **zařízení** (disky, terminály) |
| `/etc` | **konfigurační** soubory daného stroje |
| `/home` | domovské adresáře uživatelů |
| `/root` | domovský adresář uživatele **root** |
| `/lib` | knihovny pro programy v `/bin` a `/sbin` |
| `/mnt` | místo pro dočasné připojení (mount) souborového systému |
| `/opt` | volitelný software třetích stran |
| `/tmp` | dočasné soubory (maže se po restartu) |
| `/var` | proměnlivá data – logy (`/var/log`), fronty, cache |
| `/usr/share/doc` | dokumentace k balíčkům |
| `/usr/share/info` | info stránky |
| `/usr/share/man` | man stránky |
| `/usr/share/locale` | jazykové lokalizace |

```bash
ls /
ls /etc | head
ls /var/log
```

> V moderních distribucích jsou `/bin`, `/sbin` a `/lib` jen odkazy do `/usr/bin`, `/usr/sbin`, `/usr/lib`
> (ověř: `ls -ld /bin`).

## 3.2 Přehled nástrojů

| Příkaz | Co hledá | Jak |
|---|---|---|
| `locate` | soubory podle **jména** | v **databázi** – rychlé, ale nemusí být aktuální |
| `find` | soubory podle **jména, velikosti, času, vlastníka…** | **živě** v souborovém systému – pomalejší, vždy aktuální |
| `whereis` | **program**, jeho man stránky a zdrojáky | ve standardních systémových adresářích |
| `which` | **program**, který se spustí | v adresářích z `$PATH` |
| `type` | co je to za **příkaz** (alias, builtin, soubor…) | jak to vidí shell |

## 3.3 `locate` – rychlé hledání v databázi

```bash
locate passwd
# /etc/passwd
# /etc/pam.d/chpasswd
# /etc/pam.d/passwd
# /etc/security/opasswd
# ...

locate -c passwd                 # jen počet výsledků
locate -i readme                 # bez ohledu na velikost písmen
locate -b '\passwd'              # jen soubory pojmenované PŘESNĚ passwd
locate '*.conf' | head           # s vzorem (v uvozovkách!)
```

| ✅ Výhoda | ❌ Nevýhoda |
|---|---|
| **velmi rychlý** – nehledá na disku, ale v předem vytvořené databázi | **nenajde soubory, které v databázi nejsou** (vytvořené po poslední aktualizaci) |

```bash
touch ~/hledej_me.txt
locate hledej_me                 # nic – databáze je stará
sudo updatedb                    # aktualizace databáze (heslo netlab123); jinak běží 1× denně
locate hledej_me                 # /home/sysadmin/hledej_me.txt
```

## 3.4 `find` – hledání v živém souborovém systému

```
find [KDE] [KRITÉRIA] [AKCE]
```

| Kritérium | Význam |
|---|---|
| `-name 'vzor'` | jméno (rozlišuje velikost písmen) |
| `-iname 'vzor'` | jméno **bez** ohledu na velikost písmen |
| `-type f` / `-type d` / `-type l` | jen soubory / adresáře / odkazy |
| `-mtime -3` | změněné **před méně než** 3 dny |
| `-mtime +30` | změněné **před více než** 30 dny |
| `-mmin -10` | změněné v posledních 10 minutách |
| `-size +1M` | **větší** než 1 MB (`-` = menší, `k`, `M`, `G`) |
| `-user jane` | patří uživateli `jane` |
| `-empty` | prázdné soubory / adresáře |
| `-maxdepth 1` | nezanořovat se hlouběji než 1 úroveň |

```bash
find ~ -name '*.txt'                    # všechny .txt v domovském adresáři
find ~ -iname 'README*'                 # README, readme, ReadMe…
find /etc -name 'host*'
find /etc -name 'host*' 2>/dev/null     # skryje chyby "Permission denied"
find ~ -type d                          # jen adresáře
find ~ -mmin -30                        # změněné za posledních 30 minut
find /usr -size +5M 2>/dev/null         # větší než 5 MB
find /home -user sysadmin -name '*.txt'
find ~ -empty                           # prázdné soubory a adresáře
find /etc -maxdepth 1 -name '*.conf'    # jen přímo v /etc
```

> 💡 Vzor dávej **do uvozovek** (`'*.txt'`), jinak ho rozbalí shell dřív, než ho dostane `find`.
> `2>/dev/null` přesměruje chybový výstup „do koše" – podrobněji v dalších cvičeních.

**Akce** – co s nalezenými soubory udělat:

```bash
find ~ -name '*.txt' -ls                        # podrobný výpis (jako ls -l)
find ~/cv03 -name '*.txt' -exec ls -l {} \;     # spustí příkaz pro každý nalezený soubor
find ~ -name 'hledej_me.txt' -delete            # smaže nalezené (opatrně!)
find ~/cv03 -name '*.csv' -ok rm {} \;          # jako -exec, ale ptá se
```

> `{}` = nalezený soubor, `\;` = konec příkazu pro `-exec`.

### `locate` vs. `find` – rozdíl v praxi

| | `locate` | `find` |
|---|---|---|
| **Kde hledá** | v **databázi** (`/var/lib/plocate/…`), kterou plní `updatedb` | **přímo na disku**, adresář po adresáři |
| **Rychlost** | okamžitě, i v celém systému | pomaleji, záleží na velikosti prohledávaného stromu |
| **Aktuálnost** | jen stav z poslední aktualizace databáze (1× denně / `sudo updatedb`) | **vždy aktuální** |
| **Podle čeho** | jen podle **jména / cesty** | jméno, typ, velikost, čas, vlastník, oprávnění… |
| **Co umí s výsledkem** | jen vypsat | vypsat, smazat, spustit příkaz (`-exec`) |
| **Kde** | vždy celý systém | jen ve stromu, který zadám (`find /etc …`) |

**Příklad 1 – nově vytvořený soubor:**

```bash
touch ~/novy_report.txt

locate novy_report        # NIC – soubor v databázi ještě není
find ~ -name 'novy_report*'   # /home/sysadmin/novy_report.txt – find hledá živě

sudo updatedb             # aktualizace databáze (heslo netlab123)
locate novy_report        # /home/sysadmin/novy_report.txt – teď už ano
```

**Příklad 2 – smazaný soubor:**

```bash
rm ~/novy_report.txt

find ~ -name 'novy_report*'   # nic – soubor opravdu neexistuje
locate novy_report        # /home/sysadmin/novy_report.txt – databáze ho pořád „pamatuje"!
locate -e novy_report     # -e: vypíše jen soubory, které ještě existují → nic
```

**Příklad 3 – rychlost:**

```bash
time locate '*.conf' | wc -l           # zlomek sekundy
time find / -name '*.conf' 2>/dev/null | wc -l   # výrazně déle – prochází celý disk
```

**Příklad 4 – něco, co `locate` neumí vůbec:**

```bash
find ~ -mmin -10                  # změněné za posledních 10 minut
find /var/log -size +1M           # větší než 1 MB
find ~ -type d -empty             # prázdné adresáře
```

> **Shrnutí:** `locate` = rychlé hledání **podle jména**, když nevadí, že výsledek může být den starý.
> `find` = když potřebuju **aktuální** výsledek, hledat podle **jiných vlastností** nebo s nalezenými soubory **něco udělat**.

## 3.5 `whereis` – program, man stránky a zdrojáky

```bash
whereis grep
# grep: /bin/grep /usr/share/man/man1/grep.1.gz /usr/share/info/grep.info.gz
whereis -b grep             # jen binárka
whereis -m grep             # jen manuál
whereis -s grep             # jen zdrojové kódy (pokud jsou nainstalované)
whereis -u ls cd grep       # "unusual" – položky, kterým něco chybí (např. nemají manuál)
```

> ⚠️ **Upřesnění ke slidům:** `whereis` nehledá v `$PATH`, ale v **pevném seznamu standardních
> systémových adresářů** (`/bin`, `/usr/bin`, `/usr/share/man`…) – proto najde i man stránky.
> Volba `-u` hledá „neobvyklé" položky (*unusual*), tj. ty, kterým chybí binárka, manuál nebo zdrojáky.

## 3.6 `which` – který program se spustí

```bash
which bash                  # /bin/bash  nebo /usr/bin/bash
which ls cp grep
which -a ls                 # všechny výskyty v PATH, ne jen první
which cd                    # nic – cd je builtin, není to soubor
```

`which` vrací umístění **skutečného souboru** a prohledává **jen adresáře z `$PATH`**.

## 3.7 `type` – co je to za příkaz

```bash
type echo                   # echo is a shell builtin
type ls                     # ls is aliased to `ls --color=auto'
type cal                    # cal is /usr/bin/cal
type -a echo                # echo is a shell builtin
                            # echo is /usr/bin/echo     ← existuje i jako program!
type -a ls                  # alias + /usr/bin/ls (+ /bin/ls)
```

> `type -a` ukáže **všechny** možnosti v pořadí, v jakém je shell zkouší (alias → funkce → builtin → `PATH`).
> Proto `which echo` najde `/usr/bin/echo`, ale ve skutečnosti se spustí builtin.

---

# 4. Archive Commands (archivace a komprese)

Dva různé pojmy:

| Pojem | Co dělá | Nástroje |
|---|---|---|
| **Archivace** | **spojí** více souborů a adresářů do **jednoho** souboru (velikost se nezmenší) | `tar`, `cpio`, (`zip`) |
| **Komprese** | **zmenší** velikost souboru pomocí kompresního algoritmu | `gzip`, `bzip2`, `xz`, (`zip`) |

> Typický postup v Linuxu: nejdřív **archivace** (`tar`), pak **komprese** (`gzip`) → soubor `.tar.gz`.
> `zip` dělá obojí najednou (jako ve Windows).

| Nástroj | Přípona | Rozbalení | Zobrazení obsahu bez rozbalení | Poznámka |
|---|---|---|---|---|
| `gzip` | `.gz` | `gunzip` / `gzip -d` | `zcat` | rychlý, nejrozšířenější |
| `bzip2` | `.bz2` | `bunzip2` / `bzip2 -d` | `bzcat` | lepší komprese, pomalejší |
| `xz` | `.xz` | `unxz` / `xz -d` | `xzcat` | nejlepší komprese, nejpomalejší |
| `zip` | `.zip` | `unzip` | `unzip -l` | archiv + komprese, kompatibilní s Windows |
| `tar` | `.tar` (`.tar.gz`, `.tgz`…) | `tar -x` | `tar -t` | jen archivace, kompresi volá přes `-z/-j/-J` |
| `cpio` | `.cpio` | `cpio -i` | `cpio -t` | archivace, seznam souborů čte ze vstupu |
| `dd` | — | — | — | bitová kopie souborů / disků |

## 4.1 `gzip`, `gunzip`, `zcat`

```bash
cd ~/cv03
ls -l red*                        # red.txt
gzip red.txt
ls -l red*                        # red.txt.gz  ← původní soubor ZMIZEL (byl nahrazen)

gzip -c numbers.txt > numbers.txt.gz   # -c: výstup na obrazovku → přesměruju do souboru
ls numbers*                       # numbers.txt  numbers.txt.gz  ← originál zůstal
gzip -k letters.txt               # -k (keep): totéž jednodušeji, originál zůstane

gunzip -l numbers.txt.gz          # -l: info o kompresi
#  compressed  uncompressed  ratio  uncompressed_name
#          42            10 -20.0%  numbers.txt

zcat letters.txt.gz               # zobrazí obsah bez rozbalení

gunzip red.txt.gz                 # rozbalení – zase NAHRADÍ .gz souborem red.txt
ls red*                           # red.txt
gzip -v -9 longfile.txt           # -v: vypíše poměr, -9: nejlepší (nejpomalejší) komprese
```

> 💡 **Záporný poměr komprese** (`-20.0%`) – u velmi malých souborů je „komprimovaný" soubor
> **větší** než originál, protože gzip přidává hlavičku (jméno, čas, kontrolní součet).
>
> Slidy píší `gunzip red.txt` bez `.gz` – funguje to, `gunzip` si příponu `.gz` doplní sám.

## 4.2 `bzip2`, `bunzip2`, `bzcat`

Stejné použití jako `gzip`, jen **jiný kompresní algoritmus** (lepší komprese, pomalejší).

```bash
cd ~/cv03
bzip2 profile.txt
ls profile*                       # profile.txt.bz2
bzcat profile.txt.bz2             # obsah bez rozbalení
# Hello my name is Joe.
# I am 37 years old.
# ...
bunzip2 profile.txt.bz2           # rozbalení
bzip2 -k profile.txt              # -k: ponechá originál
```

## 4.3 `xz`, `unxz`, `xzcat`

**Nejefektivnější** komprese (ale nejpomalejší). Často se používá na archivy vytvořené `tar` nebo `cpio`.
Jako všechny tři kompresory pracuje **s každým souborem zvlášť** – **neslučuje** je do jednoho archivu.

```bash
cd ~/cv03
xz animals.txt
ls animals*                       # animals.txt.xz
xzcat animals.txt.xz              # obsah bez rozbalení
# 1 retriever
# 2 badger
# ...
unxz animals.txt.xz               # nebo: xz -d animals.txt.xz

mkdir xztest && cp *.txt xztest/ && cd xztest
xz -z *                           # -z = komprese; každý soubor zvlášť → spousta .xz souborů
ls
xz -d *.xz                        # zpět
cd .. && rm -r xztest
```

### Porovnání kompresorů

```bash
cd ~
ls -lR /usr > big.txt 2>/dev/null       # vyrobím velký textový soubor
gzip  -k big.txt
bzip2 -k big.txt
xz    -k big.txt
ls -lh big.txt*                   # porovnej velikosti
rm big.txt*
```

## 4.4 `tar` – archivace

`tar` (*tape archive*) **slučuje** soubory a adresáře do jednoho `.tar` souboru. Sám nekomprimuje, ale umí zavolat `gzip` / `bzip2` / `xz`.

| Volba | Význam |
|---|---|
| `-c` | **create** – vytvořit archiv |
| `-t` | **list** – vypsat obsah archivu |
| `-x` | **extract** – rozbalit |
| `-f soubor` | jméno archivu (**musí být poslední** ve skupině voleb) |
| `-v` | **verbose** – vypisovat zpracovávané soubory |
| `-z` | komprese **gzip** → `.tar.gz` / `.tgz` |
| `-j` | komprese **bzip2** → `.tar.bz2` |
| `-J` | komprese **xz** → `.tar.xz` |
| `-C adresar` | rozbalit do jiného adresáře |

> Pomůcka: **c**reate / **t**ell / e**x**tract + **f**ile, např. `tar -cvf`, `tar -tvf`, `tar -xvf`.

```bash
cd ~
# vytvoření archivu
tar -cvf cv03.tar cv03            # jen archiv (bez komprese)
tar -czvf cv03.tar.gz cv03        # + gzip
tar -cjvf cv03.tar.bz2 cv03       # + bzip2
tar -cJvf cv03.tar.xz cv03        # + xz
ls -lh cv03.tar*                  # porovnej velikosti

# výpis obsahu bez rozbalení
tar -tvf cv03.tar
tar -tzvf cv03.tar.gz             # (novější tar kompresi pozná sám, -z není nutné)

# rozbalení
mkdir rozbaleno
tar -xzvf cv03.tar.gz -C rozbaleno
ls -R rozbaleno | head

# rozbalení jen jednoho souboru
tar -xzvf cv03.tar.gz -C /tmp cv03/red.txt

rm -r rozbaleno cv03.tar*         # úklid
```

> ⚠️ `tar -cvf archiv.tar *` – pozor na pořadí! Po `-f` **musí** následovat jméno archivu.
> `tar -cfv archiv.tar …` by vytvořil archiv pojmenovaný `v`.

## 4.5 `zip`, `unzip`

`zip` = **archivace + komprese** najednou. Formát kompatibilní s Windows.

```bash
cd ~
mkdir example && touch example/one example/two example/three
zip ./example/package ./example/*
#   adding: example/one (stored 0%)
#   adding: example/three (stored 0%)
#   adding: example/two (stored 0%)
ls ./example/                     # one  package.zip  three  two

zip -r cv03.zip cv03              # -r: celý adresář rekurzivně (bez -r jen prázdný adresář!)
unzip -l cv03.zip                 # výpis obsahu
mkdir zip_out
unzip cv03.zip -d zip_out         # rozbalení do adresáře (bez -d do aktuálního)
rm -r example zip_out cv03.zip
```

> `stored 0%` – prázdné soubory nemá smysl komprimovat, zip je jen „uloží".
> Na rozdíl od `gzip` **originál nemaže**.

## 4.6 `cpio` – archivace se seznamem souborů ze vstupu

`cpio` (*copy in / copy out*) slučuje soubory do archivu, ale **seznam souborů nečte z argumentů, ale ze standardního vstupu** – typicky z `find` nebo `ls`.

| Mód | Volba | Co dělá |
|---|---|---|
| **copy-out** | `-o` | **vytvoří** archiv (soubory „ven" do archivu) |
| **copy-in** | `-i` | **rozbalí** archiv (soubory „dovnitř" do systému) |
| **copy-pass** | `-p` | zkopíruje soubory do jiného adresáře **bez vytvoření archivu** |

```bash
cd ~
# copy-out: vytvoření archivu
find cv03 | cpio -ov > cv03.cpio

# výpis obsahu
cpio -itv < cv03.cpio

# copy-in: rozbalení
mkdir cpio_out && cd cpio_out
cpio -idv < ../cv03.cpio          # -d: vytvořit potřebné adresáře
ls -R | head
cd ~

# copy-pass: kopie adresářové struktury bez archivu
mkdir cpio_kopie
find cv03 -name '*.txt' | cpio -pdv cpio_kopie
ls -R cpio_kopie | head

rm -r cpio_out cpio_kopie cv03.cpio
```

> `|` (roura) pošle výstup jednoho příkazu na vstup druhého, `>` / `<` přesměruje výstup do / vstup ze souboru.
> Podrobně v Modulu 10 *Working with Text*.

## 4.7 `dd` – bitová kopie

`dd` kopíruje data **po blocích na bitové úrovni** – nezajímá ho, jestli jde o soubor, oddíl, nebo celý disk.

| Parametr | Význam |
|---|---|
| `if=` | vstup (*input file*) |
| `of=` | výstup (*output file*) |
| `bs=` | velikost bloku (např. `1M`) |
| `count=` | kolik bloků zkopírovat |
| `status=progress` | zobrazovat průběh |

Používá se pro:
- **klonování** nebo **smazání (wipe)** celých disků a oddílů,
- kopírování raw dat z vyměnitelných médií (USB, ISO obrazy),
- **zálohu a obnovu MBR** (prvních 512 B disku),
- vytvoření velkých prázdných souborů (např. pro swap / virtuální paměť).

```bash
# bezpečné ukázky – pracují jen se soubory
dd if=/dev/zero of=~/prazdny.img bs=1M count=10    # 10 MB soubor plný nul
ls -lh ~/prazdny.img
dd if=/dev/urandom of=~/nahodny.bin bs=1K count=100
dd if=/etc/passwd of=~/passwd.kopie                # kopie souboru
rm ~/prazdny.img ~/nahodny.bin ~/passwd.kopie
```

```bash
# ⚠️ NESPOUŠTĚT – jen pro ilustraci
dd if=/dev/sda of=/dev/sdb                 # klonování celého disku sda na sdb
dd if=/dev/sda of=mbr.bak bs=512 count=1   # záloha MBR
dd if=/dev/zero of=/dev/sdb                # smazání celého disku
```

> ⚠️ `dd` se přezdívá **„disk destroyer"** – prohozené `if` a `of` přepíše data **bez jakéhokoliv varování**.

---

# Úlohy k procvičení

Před začátkem: `cp -r ~/Documents ~/cv03 && cd ~/cv03` (pokud jsi to ještě neudělal).

### 1. File Globbing

1. V `/etc` vypiš všechny položky, které začínají na `p` a končí na `d`.
2. V `/usr/bin` vypiš příkazy, které mají přesně 2 znaky.
3. V `/usr/bin` vypiš příkazy, které začínají na `a`, `b` nebo `c` a mají aspoň 5 znaků.
4. V `/usr/bin` vypiš příkazy, které **nekončí** na `x`, `y` ani `z` – kolik jich je? (nápověda: `| wc -l`)
5. V `~/cv03` vypiš soubory, jejichž jméno obsahuje číslici.

### 2. File Manipulation

6. V `~/cv03` vypiš soubory seřazené podle velikosti od **nejmenšího**, s čitelnými velikostmi.
7. Zjisti typ souborů `/bin/ls`, `/etc/passwd`, `/dev/null` a `~/cv03/hello.sh`.
8. Vytvoř soubor `stary.txt` a nastav mu datum na 1. 1. 2000 12:00. Ověř přes `ls -l`.
9. Jedním příkazem vytvoř strukturu `~/projekt/src/main`, `~/projekt/doc` a `~/projekt/test`.
10. Zkopíruj všechny `.txt` soubory z `~/cv03` do `~/projekt/doc` tak, aby `cp` vypisoval, co dělá.
11. Přejmenuj `~/projekt/test` na `~/projekt/testy`.
12. Pokus se smazat `~/projekt/doc` pomocí `rmdir`. Proč to nejde? Smaž ho správně.
13. Smaž celý `~/projekt`.

### 3. Finding Files

14. Najdi pomocí `locate` všechny soubory, v jejichž jménu je `bashrc`.
15. Vytvoř soubor `~/tajny_soubor.txt` a najdi ho přes `locate`. Co musíš udělat, aby ho našel?
16. Pomocí `find` najdi v `/etc` všechny soubory končící na `.conf` (bez chybových hlášek).
17. Najdi v `/usr` soubory větší než 10 MB.
18. Najdi v domovském adresáři soubory změněné za posledních 60 minut.
19. Najdi v `~/cv03` všechny `.txt` soubory bez ohledu na velikost písmen a vypiš je jako `ls -l`.
20. Kde leží binárka a manuálová stránka příkazu `passwd`? Jakého typu je příkaz `pwd` – a existuje i jako soubor?

### 4. Archive Commands

21. Zkomprimuj `~/cv03/longfile.txt` pomocí `gzip` tak, aby originál zůstal. Zjisti poměr komprese.
22. Zobraz obsah `letters.txt.gz` bez rozbalení.
23. Zkomprimuj stejný soubor přes `bzip2` a `xz` a porovnej velikosti všech tří.
24. Vytvoř archiv `~/zaloha.tar.gz` z adresáře `~/cv03`. Vypiš jeho obsah bez rozbalení.
25. Rozbal `~/zaloha.tar.gz` do adresáře `/tmp/obnova`.
26. Vytvoř `~/cv03.zip` z adresáře `~/cv03` a rozbal ho do `/tmp/zip`.
27. Pomocí `find` a `cpio` vytvoř archiv všech `.txt` souborů z `~/cv03`.
28. Pomocí `dd` vytvoř 5 MB soubor plný nul a ověř jeho velikost.

<details>
<summary>Řešení</summary>

```bash
# 1
ls -d /etc/p*d

# 2
ls /usr/bin/??          # nebo: cd /usr/bin && ls ??

# 3
cd /usr/bin && ls [abc]????*

# 4
cd /usr/bin && ls *[!xyz] | wc -l

# 5
ls ~/cv03/*[0-9]*

# 6
ls -lShr ~/cv03

# 7
file /bin/ls /etc/passwd /dev/null ~/cv03/hello.sh

# 8
touch -t 200001011200 stary.txt
ls -l stary.txt

# 9
mkdir -p ~/projekt/src/main ~/projekt/doc ~/projekt/test
# nebo s rozbalováním složených závorek:
mkdir -p ~/projekt/{src/main,doc,test}

# 10
cp -v ~/cv03/*.txt ~/projekt/doc/

# 11
mv ~/projekt/test ~/projekt/testy

# 12
rmdir ~/projekt/doc          # Directory not empty – rmdir maže jen prázdné adresáře
rm -r ~/projekt/doc

# 13
rm -r ~/projekt

# 14
locate bashrc

# 15
touch ~/tajny_soubor.txt
locate tajny_soubor          # nic
sudo updatedb                # heslo netlab123
locate tajny_soubor

# 16
find /etc -name '*.conf' 2>/dev/null

# 17
find /usr -size +10M 2>/dev/null

# 18
find ~ -mmin -60

# 19
find ~/cv03 -iname '*.txt' -ls
# nebo: find ~/cv03 -iname '*.txt' -exec ls -l {} \;

# 20
whereis passwd
type -a pwd                  # pwd is a shell builtin / pwd is /usr/bin/pwd (/bin/pwd)

# 21
cd ~/cv03
gzip -k longfile.txt         # nebo: gzip -c longfile.txt > longfile.txt.gz
gunzip -l longfile.txt.gz

# 22
zcat letters.txt.gz

# 23
bzip2 -k longfile.txt
xz -k longfile.txt
ls -l longfile.txt*

# 24
cd ~
tar -czvf zaloha.tar.gz cv03
tar -tzvf zaloha.tar.gz

# 25
mkdir -p /tmp/obnova
tar -xzvf zaloha.tar.gz -C /tmp/obnova

# 26
zip -r cv03.zip cv03
unzip cv03.zip -d /tmp/zip

# 27
find cv03 -name '*.txt' | cpio -ov > txt.cpio
cpio -itv < txt.cpio

# 28
dd if=/dev/zero of=~/nuly.img bs=1M count=5
ls -lh ~/nuly.img
```
</details>

---

# Tahák

| Potřebuju… | Příkaz |
|---|---|
| soubory začínající na `a` | `ls a*` |
| jméno o přesně 3 znacích | `ls ???` |
| začínající na a–c / ne a–c | `ls [a-c]*` / `ls [!a-c]*` |
| vyzkoušet, na co se glob rozbalí | `echo vzor` |
| výpis s detaily / i skryté | `ls -l` / `ls -a` |
| řadit podle velikosti / času | `ls -lS` / `ls -lt` (`-r` obráceně) |
| info o adresáři, ne o obsahu | `ls -ld adresar` |
| typ dat v souboru | `file soubor` |
| prázdný soubor / změna času | `touch soubor`, `touch -t YYYYMMDDhhmm soubor` |
| kopie souboru / adresáře | `cp zdroj cil` / `cp -r adresar cil` |
| přesun / přejmenování | `mv zdroj cil` |
| smazání souboru / adresáře s obsahem | `rm soubor` / `rm -r adresar` |
| potvrzovat přepsání / mazání | `-i` (`cp -i`, `mv -i`, `rm -i`) |
| vytvořit adresářovou cestu | `mkdir -p a/b/c` |
| smazat prázdný adresář | `rmdir adresar` |
| rychle najít soubor podle jména | `locate jmeno` (po `sudo updatedb`) |
| hledat podle jména / velikosti / času | `find kde -name '*.txt'`, `-size +1M`, `-mtime -3` |
| kde je program + manuál | `whereis prikaz` |
| který program se spustí | `which prikaz` |
| co je to za příkaz | `type -a prikaz` |
| zkomprimovat / rozbalit `.gz` | `gzip soubor` / `gunzip soubor.gz` |
| zkomprimovat a ponechat originál | `gzip -k soubor` |
| prohlédnout zkomprimovaný soubor | `zcat` / `bzcat` / `xzcat` |
| vytvořit `.tar.gz` | `tar -czvf archiv.tar.gz adresar` |
| vypsat obsah tar archivu | `tar -tvf archiv.tar.gz` |
| rozbalit tar archiv | `tar -xvf archiv.tar.gz [-C kam]` |
| zip / unzip | `zip -r archiv.zip adresar` / `unzip archiv.zip [-d kam]` |
| archiv přes cpio | `find adr \| cpio -ov > a.cpio`, `cpio -idv < a.cpio` |
| bitová kopie | `dd if=VSTUP of=VYSTUP bs=1M` |

---

# Příprava na cvičení 04

Samostudium, splněné laby a testy z modulů:

- **Linux Essentials – Module 9 – Archiving and Compression**
- **Linux Essentials – Module 10 – Working with Text**
