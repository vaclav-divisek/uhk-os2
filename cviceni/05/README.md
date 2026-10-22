# Cvičení 05 – Shell skripty a systémové logy

Podle **NDG Linux Essentials** a labů **Linux II.**:

- **Module 11 – Basic Scripting**
- Linux II. – **Shell Scripts**, **System Logging**
- **Midterm Exam (Chapters 2–9)**

**Vstupní požadavky:** samostudium Module 11, splněné *Lab 09 + Chapter 09 Exam*, *Lab 11 + Chapter 11 Exam* a Exams z předchozích modulů.

Vše si zkoušíme v laboratorním prostředí **NDG NETLAB+** na [portal.netdevgroup.com](https://portal.netdevgroup.com/).

---

## 0. Příprava prostředí

1. Přihlas se na [portal.netdevgroup.com](https://portal.netdevgroup.com/) a spusť **Lab** příslušného modulu.
2. Jsi přihlášen jako **`sysadmin`**, heslo pro `sudo` je **`netlab123`**.
3. Skripty si budeme ukládat do vlastního adresáře:

```bash
mkdir -p ~/skripty
cd ~/skripty
```

> Skripty píšeme ve **`vi`** (viz [cvičení 04](../04/README.md#3-the-vi-editor)) nebo v `nano` (jednodušší:
> `Ctrl+O` uložit, `Ctrl+X` konec). Kratší skripty jde vytvořit i přes `cat > soubor << 'KONEC'`.

---

# 1. Midterm Exam (Chapters 2–9)

Midterm ověřuje kapitoly **2–9** kurzu Linux Essentials. Přehled k opakování:

| Kapitola | Téma | Co si zopakovat | Kde v návodech |
|---|---|---|---|
| 2 | Operating Systems | co je OS, jádro (kernel), Linux vs. Windows vs. macOS, distribuce (Debian/Ubuntu, Red Hat/Fedora, SUSE…), servery vs. desktop, embedded | — |
| 3 | Working in Linux | desktopové a serverové aplikace, programovací jazyky, shell, správa balíčků (`apt`, `dpkg`, `rpm`, `yum`/`dnf`) | — |
| 4 | Open Source Software and Licensing | open source vs. proprietární, FSF / OSI, **GPL** (copyleft), **BSD / MIT / Apache** (permisivní), Creative Commons, FOSS / FLOSS | — |
| 5 | Command Line Skills | shell, proměnné, `PATH`, `type`, aliasy, globbing, uvozovky, `;` `&&` `\|\|` | [cvičení 02](../02/README.md) |
| 6 | Getting Help | `man` (sekce 1–9), `man -k` / `apropos`, `info`, `--help`, `whereis`, `locate` | [cvičení 02](../02/README.md) |
| 7 | Navigating the Filesystem | `pwd`, `cd`, absolutní vs. relativní cesta, `~`, `.`, `..`, `ls` a jeho volby | [cvičení 03](../03/README.md) |
| 8 | Managing Files and Directories | globbing, `cp`, `mv`, `rm`, `mkdir`, `rmdir`, `touch` | [cvičení 03](../03/README.md) |
| 9 | Archiving and Compression | `gzip`, `bzip2`, `xz`, `tar`, `zip` / `unzip` | [cvičení 03](../03/README.md#4-archive-commands-archivace-a-komprese) |

> Kapitoly 2–4 jsou spíš **teoretické** – na cvičeních jsme je neprocházeli, projdi si je v NDG kurzu.

---

# 2. Shell Scripts (shellové skripty)

## 2.1 Co je skript

V nejjednodušším smyslu je skript **soubor s příkazy**, které bys jinak psal ručně do terminálu – **v pořadí, jak jdou za sebou**. Když soubor spustíš jako program, shell příkazy jeden po druhém provede.

Skripty ale umí víc než jen sled příkazů – mají **proměnné, podmínky, cykly, vstup od uživatele** (podobně jako Perl nebo C). Nejsou tak komplexní jako plnohodnotné programovací jazyky, ale můžou volat **tisíce linuxových příkazů**.

Typické použití: zálohy, reporty, hromadné operace se soubory, automatizace správy systému.

### V jakém jazyce se skripty píšou?

V **jazyce shellu** – u nás **Bash**. Ten se skládá ze dvou částí:

- **příkazy, které znáš z terminálu** (`ls`, `cp`, `grep`, `tar`…) – skript je hlavně volá,
- **syntaxe shellu** – proměnné, `if` / `then` / `fi`, `for`, `while`, `read`, `$( )`, `$?`, `exit`.

> Co napíšeš do terminálu, můžeš dát do skriptu – a naopak. Bash je **příkazový interpret i skriptovací jazyk zároveň**.

**Jakým jazykem se skript provede, určuje první řádek** (*shebang*, viz dále):

| Shebang | Jazyk / interpret | Přípona (jen zvyk) |
|---|---|---|
| `#!/bin/bash` | **Bash** – to, co děláme na cvičení | `.sh` |
| `#!/bin/sh` | POSIX shell (na Ubuntu `dash`) – jen základní syntaxe | `.sh` |
| `#!/usr/bin/python3` | Python | `.py` |
| `#!/usr/bin/perl` | Perl | `.pl` |

> **Přípona `.sh` je jen konvence** – Linux podle ní nic nepozná. Rozhoduje shebang a právo spuštění (`x`).
>
> **Bash** se hodí na automatizaci příkazů. Na složitější logiku, výpočty nebo práci s daty (JSON, CSV, síť)
> je lepší **Python** apod.

### Podobnost s PHP

Kdo zná PHP, uvidí hodně podobného (`$promenna`, `echo`, `"…"` vs. `'…'`), ale v detailech se jazyky liší –
a právě tam vznikají chyby:

| | PHP | Bash |
|---|---|---|
| proměnná – přiřazení | `$jmeno = "Petr";` | `jmeno="Petr"` – **bez `$`, bez mezer kolem `=`** |
| proměnná – čtení | `$jmeno` | `$jmeno` ✅ stejné |
| výpis | `echo "Ahoj $jmeno";` | `echo "Ahoj $jmeno"` ✅ skoro stejné |
| `"…"` vs. `'…'` | v `"…"` se proměnné rozbalí, v `'…'` ne | ✅ **stejné** |
| středník | povinný | nepovinný (jen pro víc příkazů na řádku) |
| podmínka | `if ($a == 5) { … } elseif (…) { … } else { … }` | `if [ $a -eq 5 ]; then … elif …; then … else … fi` |
| porovnání čísel | `==`, `<`, `>` | `-eq`, `-lt`, `-gt` (`<` `>` jsou přesměrování!) |
| bloky | `{ }` | `then … fi`, `do … done` |
| datové typy | int, string, array, bool… | **všechno je text** (počítání jen v `$(( ))`) |
| spojení řetězců | `$a . $b` | `"$a$b"` – stačí napsat vedle sebe |
| co se volá | vestavěné funkce (`strlen()`, `date()`) | hlavně **externí programy** (`date`, `wc`, `grep`) |
| typické použití | webové stránky, backend | automatizace systému, správa serverů |

Nejčastější chyby „po PHPčkovsku":

```bash
$jmeno = "Petr"      # ❌ bash se pokusí spustit příkaz s názvem obsahu $jmeno
jmeno = "Petr"       # ❌ mezery → bash hledá příkaz "jmeno"
jmeno="Petr"         # ✅

if [ $a == 5 ]       # funguje, ale porovnává jako TEXT ("05" ≠ "5")
if [ $a -eq 5 ]      # ✅ porovnání čísel
```

## 2.2 Vytvoření a spuštění skriptu

**3 kroky:**

1. Vytvoř soubor v textovém editoru s příkazy.
2. Na **první řádek** napiš `#!/bin/bash`.
3. Nastav právo spuštění: `chmod a+x soubor` (pro všechny) nebo `chmod u+x soubor` (jen pro sebe).

```bash
cd ~/skripty
vi ahoj.sh
```

```bash
#!/bin/bash
# Muj prvni skript
echo "Ahoj, $USER!"
echo "Dnes je $(date +%d.%m.%Y)"
```

```bash
chmod u+x ahoj.sh
./ahoj.sh
# Ahoj, sysadmin!
# Dnes je 22.10.2026
```

### Shebang `#!`

- `#` (*hash*, „libra") obvykle označuje **komentář** – zbytek řádku shell ignoruje.
- **`#!` na prvním řádku** je výjimka – říká systému, **kterým programem** má skript interpretovat.
- `#!/bin/bash` = spusť to přes Bash. Jiné příklady: `#!/bin/sh`, `#!/usr/bin/python3`.
- Názvy: ***hash-bang*** (hash `#` + bang `!`), *shebang*, *sh-bang*, *sha-bang*, *crunch-bang*.

> Bez shebangu skript spustí aktuální shell – většinou to projde, ale není jisté, který shell to bude
> (viz [rozdíl sh vs. bash](../02/README.md#liší-se-v-různých-shellech-příkazy)).

### Způsoby spuštění

| Zápis | Potřebuje `chmod +x`? | Poznámka |
|---|---|---|
| `./ahoj.sh` | ✅ ano | relativní cesta – skript v aktuálním adresáři |
| `/home/sysadmin/skripty/ahoj.sh` | ✅ ano | absolutní cesta |
| `ahoj.sh` | ✅ ano | jen pokud je adresář v `PATH` |
| `bash ahoj.sh` | ❌ ne | spustí bash a předá mu soubor; shebang se ignoruje |
| `source ahoj.sh` / `. ahoj.sh` | ❌ ne | provede příkazy **v aktuálním shellu** (ne v novém procesu) |

### Skript v `PATH` – adresář `~/bin`

Aby šel skript spustit **jen jménem** (bez `./`), musí ležet v adresáři z proměnné `PATH`. Typická `PATH`:

```
/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/home/sysadmin/bin
```

Běžný uživatel **nemá právo zapisovat** do žádného z nich **kromě `/home/USER/bin`** – tam patří jeho osobní skripty.

```bash
mkdir -p ~/bin
cp ~/skripty/ahoj.sh ~/bin/ahoj
echo $PATH                        # je tam /home/sysadmin/bin?
ahoj                              # funguje bez ./
# pokud ne: PATH=$PATH:~/bin  (nebo se odhlas a přihlas)
```

> Podrobněji o `PATH` a pořadí hledání příkazů: [cvičení 02 – kapitola 5.4](../02/README.md#54-proměnná-path).

### Oprávnění

Skript potřebuje pro uživatele právo **čtení (`r`)** i **spuštění (`x`)** – shell ho musí přečíst, aby ho mohl provést.

```bash
chmod a+x report.sh       # spuštění pro všechny (čtení většinou už mají)
chmod u+x report.sh       # spuštění jen pro vlastníka – soukromý skript
ls -l report.sh           # -rwxr--r-- … x u vlastníka
```

> **SETUID u skriptů:** v Unixu mohli admini nastavit skriptům SETUID (skript běží s právy vlastníka, např. roota).
> Protože se to dalo snadno **zneužít k získání root práv**, **jádro Linuxu SETUID u skriptů ignoruje**.
> Pokud to opravdu potřebuješ, používá se zkompilovaný „obalový" program (*wrapper*) s SETUID, který skript spustí
> (dnes spíš `sudo`).

## 2.3 První skript – report o místě na disku

Skript vytvoří report o velikosti adresáře `/usr/share/doc` (navazuje na funkci `report` z [cvičení 02](../02/README.md#58-funkce) – z funkce, která se rozrůstá, je běžné udělat skript).

```bash
cat > report.sh << 'KONEC'
#!/bin/bash
cd /usr/share/doc
echo "Document directory usage report" > /tmp/report
date >> /tmp/report
pwd >> /tmp/report
du -sh . >> /tmp/report
KONEC

chmod a+x report.sh
./report.sh
cat /tmp/report
# Document directory usage report
# Thu Oct 22 10:14:34 UTC 2026
# /usr/share/doc
# 134M    .
```

> ⚠️ **Opravy oproti slidům** (zkopírováním ze slidů by skript nefungoval):
> - `Echo` → **`echo`** (Linux rozlišuje velká a malá písmena),
> - `du –sh.` → **`du -sh .`** (pomlčka `-` místo `–` a mezera před tečkou),
> - `chmoda+xreport.sh` → **`chmod a+x report.sh`**.

> 💡 Všimni si: `cd` ve skriptu **nezmění adresář tvého terminálu** – skript běží v samostatném procesu.

## 2.4 Proměnné a náhrada příkazů

Proměnné fungují stejně jako v terminálu (viz [cvičení 02](../02/README.md#53-proměnné-variables)): `NAZEV=hodnota`, čtení přes `$NAZEV`.

**Náhrada příkazu** (*command substitution*) spustí příkaz a **místo něj vloží jeho výstup**:

| Zápis | Poznámka |
|---|---|
| `` `prikaz` `` | starší zápis (zpětné apostrofy) |
| `$(prikaz)` | novější, čitelnější, dá se vnořovat – **doporučený** |

```bash
start=`date`
echo $start               # Thu Oct 22 10:42:00 UTC 2026

start=$(date)             # totéž
echo $start

echo "Today is $(date +%D)"           # výstup jako součást argumentu
# Today is 10/22/26
```

### Výstup příkazu jako seznam argumentů

```bash
cat > dirs.txt << 'KONEC'
/usr/share/doc
/usr/share/fonts
/usr/local
KONEC

du -sh $(cat dirs.txt)    # = du -sh /usr/share/doc /usr/share/fonts /usr/local
# 134M    /usr/share/doc
# 21M     /usr/share/fonts
# 2.5M    /usr/local
```

### Report v2 – s časem začátku a konce

```bash
cat > report.sh << 'KONEC'
#!/bin/bash
start=$(date)
echo "Document directory usage report" > /tmp/report
du -sh $(cat ~/skripty/dirs.txt) >> /tmp/report
echo "Start of report: $start" >> /tmp/report
echo "End of report: $(date)" >> /tmp/report
KONEC

./report.sh
more /tmp/report
# Document directory usage report
# 134M    /usr/share/doc
# ...
# Start of report: Thu Oct 22 10:47:36 UTC 2026
# End of report: Thu Oct 22 10:47:37 UTC 2026
```

> `$start` = čas uložený **na začátku** skriptu, `$(date)` na konci = čas **teď** →
> rozdíl ukazuje, jak dlouho skript běžel (viz [proměnná s časem v cvičení 02](../02/README.md#proměnná-s-výstupem-příkazu-čas)).

## 2.5 Vstup od uživatele – `read`

`read` počká, až uživatel něco napíše a stiskne Enter, a uloží to do proměnné.

```bash
read name                             # čeká na vstup (bez nápovědy)
echo "Ahoj $name"

read -p "Please enter name: " name    # -p: zobrazí výzvu (prompt)
echo "Ahoj $name"

read -p "Jmeno a prijmeni: " jmeno prijmeni   # více proměnných – dělí se podle mezer
echo "$prijmeni, $jmeno"

read -s -p "Heslo: " heslo ; echo     # -s: nezobrazuje psané znaky
```

### Report v3 – adresář zadá uživatel

```bash
cat > report.sh << 'KONEC'
#!/bin/bash
read -p "Enter a directory: " dir
start=$(date)
echo "Directory usage report" > /tmp/report
du -sh $dir >> /tmp/report
echo "Start of report: $start" >> /tmp/report
echo "End of report: $(date)" >> /tmp/report
cat /tmp/report
KONEC

./report.sh
# Enter a directory: /etc
```

> ⚠️ Ve slidech je `Red –p` → správně **`read -p`**, a za výzvou musí být **mezera** před jménem proměnné:
> `read -p "Enter a directory: " dir`.

### Argumenty skriptu (`$1`, `$2`…)

Místo `read` může skript dostat hodnoty **rovnou při spuštění** jako argumenty:

| Proměnná | Význam |
|---|---|
| `$0` | jméno skriptu |
| `$1`, `$2`… | 1., 2.… argument |
| `$#` | **počet** argumentů |
| `$@` | **všechny** argumenty |
| `$?` | návratový kód posledního příkazu |

```bash
cat > arg.sh << 'KONEC'
#!/bin/bash
echo "Skript: $0"
echo "Prvni argument: $1"
echo "Pocet argumentu: $#"
echo "Vsechny: $@"
KONEC
chmod u+x arg.sh
./arg.sh /etc /tmp ahoj
```

## 2.6 Podmínky – `test` a `[ ]`

Skript často potřebuje rozhodnout: **existuje soubor? Je číslo větší? Shodují se řetězce?**
Na to slouží příkaz **`test`** – vrátí návratový kód **0 (pravda)** nebo **1 (nepravda)**.

```bash
test -e /etc/passwd ; echo $?     # 0 – existuje
test -e /neexistuje ; echo $?     # 1 – neexistuje
[ -e /etc/passwd ] ; echo $?      # totéž – [ ] je jiný zápis příkazu test
```

> ⚠️ **Mezery uvnitř závorek jsou povinné!** `[ -e soubor ]` ✅, `[-e soubor]` ❌.
> `[` je ve skutečnosti příkaz (`type [` → *shell builtin*) a `]` jeho poslední argument.
> Ve slidech je překlep `test[ -e file ]` – správně buď `test -e file`, nebo `[ -e file ]`.

### Řetězce a čísla

| Test | Pravda, když… | Příklad |
|---|---|---|
| `-z` | řetězec má **nulovou** délku (je prázdný) | `[ -z "$jmeno" ]` |
| `-n` | řetězec **není** prázdný | `[ -n "$jmeno" ]` |
| `=` | řetězce **jsou stejné** | `[ "$USER" = "sysadmin" ]` |
| `!=` | řetězce **se liší** | `[ "$a" != "$b" ]` |
| `-eq` | čísla jsou **rovna** (*equal*) | `[ $a -eq 5 ]` |
| `-ne` | čísla **nejsou** rovna (*not equal*) | `[ $a -ne 5 ]` |
| `-gt` | první je **větší** (*greater than*) | `[ $a -gt 5 ]` |
| `-ge` | první je **větší nebo rovno** | `[ $a -ge 5 ]` |
| `-lt` | první je **menší** (*less than*) | `[ $a -lt 5 ]` |
| `-le` | první je **menší nebo rovno** | `[ $a -le 5 ]` |

> **Řetězce** se porovnávají přes `=` / `!=`, **čísla** přes `-eq`, `-lt`… Pozor: `<` a `>` uvnitř `[ ]`
> znamenají **přesměrování**, ne porovnání!

### Soubory

| Test | Pravda, když… |
|---|---|
| `-e soubor` | soubor **existuje** (*exists*) |
| `-f soubor` | je to **běžný soubor** (*file*) |
| `-d soubor` | je to **adresář** (*directory*) |
| `-r soubor` | aktuální uživatel ho může **číst** |
| `-w soubor` | aktuální uživatel do něj může **zapisovat** |
| `-x soubor` | aktuální uživatel ho může **spustit** |
| `-s soubor` | soubor existuje a **není prázdný** |

```bash
[ -d /etc ] && echo "adresar"
[ -f /etc ] || echo "neni bezny soubor"
[ -w /etc/passwd ] || echo "do /etc/passwd zapisovat nemuzu"
[ $(ls ~ | wc -l) -gt 5 ] && echo "v domovskem adresari je vic nez 5 polozek"
```

> 💡 Proměnné v testech dávej **do uvozovek**: `[ "$jmeno" = "Petr" ]`. Když je `$jmeno` prázdné,
> bez uvozovek by z toho bylo `[ = "Petr" ]` → chyba `unary operator expected`.

## 2.7 Větvení – `if`

### Jednoduché `if`

```
if PODMINKA
then
    PRIKAZY_KDYZ_PRAVDA
fi
```

- `PODMINKA` je **libovolný příkaz** – nejčastěji `[ … ]`, ale může to být i `grep -q …` apod. Rozhoduje jeho **návratový kód** (0 = pravda).
- `fi` = „if" pozpátku – **ukončuje** blok.
- Když je podmínka nepravdivá, neudělá se nic.

```bash
echo $USER
if [ "$USER" = "sysadmin" ]
then
    echo 'Hello sysadmin!'
fi
# Hello sysadmin!
```

> V terminálu po `if …` a Enteru bash zobrazí `>` – čeká na dokončení bloku. Zadávej řádky, až po `fi`.
> Kratší zápis na jednom řádku: `if [ "$USER" = "sysadmin" ]; then echo 'Hello!'; fi`

### `if` + `else`

```
if PODMINKA
then
    PRIKAZY_KDYZ_PRAVDA
else
    PRIKAZY_KDYZ_NEPRAVDA
fi
```

```bash
if [ -r /etc/passwd ]
then
    echo '/etc/passwd is readable'
else
    echo '/etc/passwd is not readable'
fi
# /etc/passwd is readable

if [ -r /etc/shadow ]; then echo 'citelny'; else echo 'necitelny'; fi
# necitelny
```

### `if` + `elif` + `else`

`elif` = „else if" – další podmínka, když předchozí neplatila.

```
if PODMINKA1
then
    PRIKAZY1
elif PODMINKA2
then
    PRIKAZY2
else
    PRIKAZY_JINAK
fi
```

```bash
cat > teplota.sh << 'KONEC'
#!/bin/bash
read -p "Zadej teplotu: " t
if [ "$t" -lt 0 ]
then
    echo "Mrzne"
elif [ "$t" -lt 20 ]
then
    echo "Chladno"
else
    echo "Teplo"
fi
KONEC
chmod u+x teplota.sh
./teplota.sh
```

### Chyba: číselné porovnání řetězce

```bash
if [ "$USER" -eq 'sysadmin' ]
then
    echo 'Hello sysadmin!'
fi
# bash: [: sysadmin: integer expression expected
```

`-eq` porovnává **čísla**, ale `$USER` je **text** → `[` skončí s chybou (návratový kód 2), podmínka se vyhodnotí jako nepravdivá a `echo` se neprovede.

> ⚠️ Slidy používají typografické uvozovky `‘sysadmin’` – v terminálu to **nefunguje** jako uvozovky,
> stanou se součástí textu. Vždy piš rovné `'…'` nebo `"…"`. Stejně tak `Then`/`Else` s velkým písmenem jsou chyba – správně `then`, `else`.

### Kompletní skript: report s kontrolou vstupu

```bash
cat > report.sh << 'KONEC'
#!/bin/bash
read -p "Enter a directory: " dir

if [ -z "$dir" ]
then
    echo "Nezadal jsi adresar."
    exit 1
elif [ ! -d "$dir" ]
then
    echo "$dir neni adresar."
    exit 2
fi

start=$(date)
echo "Directory usage report" > /tmp/report
du -sh "$dir" >> /tmp/report 2> /dev/null
echo "Start of report: $start" >> /tmp/report
echo "End of report: $(date)" >> /tmp/report
cat /tmp/report
KONEC

./report.sh ; echo "Navratovy kod: $?"
```

> `!` neguje podmínku: `[ ! -d "$dir" ]` = „**není** adresář".
> `exit N` ukončí skript s návratovým kódem `N` – viz další kapitola.

## 2.8 Návratové kódy – `$?` a `exit`

Každý příkaz po skončení vrátí **návratový kód** (*exit status*) – celé číslo **0–255**:

| Kód | Význam |
|---|---|
| **0** | **úspěch** |
| **1–255** | **chyba** – konkrétní číslo určuje autor příkazu |

Kód posledního příkazu je v proměnné **`$?`**:

```bash
grep sysadmin /etc/passwd
# sysadmin:x:1001:1001::/home/sysadmin:/bin/bash
echo $?           # 0 – nalezeno

grep neexistuje /etc/passwd
echo $?           # 1 – nic nenalezeno

grep sysadmin /etc/shadow
# grep: /etc/shadow: Permission denied
echo $?           # 2 – chyba
```

U `grep`: **0** = nalezeno, **1** = nic nenalezeno, **2** = chyba. Význam kódů bývá popsán v sekci **EXIT STATUS** manuálové stránky (`man grep` → `/EXIT STATUS`).

> ⚠️ `$?` se přepíše **každým** příkazem – i `echo`. Pokud ho potřebuješ víckrát, ulož si ho: `kod=$?`.
> Ve slidech chybí mezera: `grep sysadmin/etc/passwd` → správně **`grep sysadmin /etc/passwd`**.

### Zahození chybových hlášek

Chyby (STDERR) často jen matou uživatele skriptu. Zahodíš je přesměrováním do `/dev/null`:

```bash
grep sysadmin /etc/shadow 2> /dev/null
echo $?           # 2 – chybu nevidíš, ale kód o ní pořád ví
```

### Použití ve skriptu

```bash
cat > hledej.sh << 'KONEC'
#!/bin/bash
read -p "Koho hledat v /etc/passwd? " kdo
grep -q "^$kdo:" /etc/passwd 2> /dev/null
kod=$?

if [ $kod -eq 0 ]
then
    echo "Uzivatel $kdo existuje."
elif [ $kod -eq 1 ]
then
    echo "Uzivatel $kdo neexistuje."
    exit 1
else
    echo "Chyba pri cteni /etc/passwd."
    exit 2
fi
KONEC
chmod u+x hledej.sh
./hledej.sh ; echo "Skript vratil: $?"
```

> Kratší varianta – příkaz přímo jako podmínka: `if grep -q "^$kdo:" /etc/passwd; then …`

## 2.9 Bonus – cykly a ladění

Ve slidech nejsou, ale v NDG Module 11 ano a hodí se:

```bash
# for – pro každou položku seznamu
for soubor in /etc/*.conf
do
    echo "Konfigurak: $soubor"
done

for i in 1 2 3 4 5; do echo "Cislo $i"; done
for i in {1..5}; do echo "Cislo $i"; done

# while – dokud platí podmínka
i=1
while [ $i -le 5 ]
do
    echo "Cislo $i"
    i=$((i + 1))          # $(( )) = aritmetika
done

# case – výběr podle hodnoty
read -p "Ano/ne? " odp
case $odp in
    a|ano|A|Ano) echo "Souhlas" ;;
    n|ne|N|Ne)   echo "Nesouhlas" ;;
    *)           echo "Nerozumim" ;;
esac
```

**Ladění skriptu:**

```bash
bash -x report.sh         # vypíše každý příkaz před provedením (s + na začátku)
bash -n report.sh         # jen zkontroluje syntaxi, nic nespustí
```

---

# 3. System Logging (systémové logy)

> ℹ️ Tato část ve slidech není – je sestavena podle obsahu labu **Linux II. – System Logging** v NDG.

**Log** je záznam toho, **co se v systému děje** – přihlášení, chyby, starty služeb, zprávy jádra.
Logy jsou **první místo, kam se díváš**, když něco nefunguje.

## 3.1 Kde logy jsou – `/var/log`

```bash
ls /var/log
ls -l /var/log
```

| Soubor | Obsah |
|---|---|
| `/var/log/syslog` | hlavní systémový log (Debian/Ubuntu) |
| `/var/log/messages` | hlavní systémový log (Red Hat/CentOS/Fedora) |
| `/var/log/auth.log` | přihlášení, `sudo`, `ssh` (Debian/Ubuntu); na Red Hatu `/var/log/secure` |
| `/var/log/kern.log` | zprávy jádra |
| `/var/log/dmesg` | zprávy jádra ze startu systému |
| `/var/log/boot.log` | průběh startu systému |
| `/var/log/cron.log` | naplánované úlohy (cron) |
| `/var/log/apt/` | instalace balíčků (`history.log`) |
| `/var/log/wtmp` | historie přihlášení (binární – čte se přes `last`) |
| `/var/log/btmp` | **neúspěšná** přihlášení (binární – `sudo lastb`) |
| `/var/log/lastlog` | poslední přihlášení každého uživatele (`lastlog`) |

> Většina logů je čitelná jen pro **root** → používej `sudo` (heslo `netlab123`).
> Kontejnerové prostředí NDG nemusí mít všechny soubory – podívej se, co v `/var/log` skutečně je.

## 3.2 Čtení logů

Logy jsou **textové soubory** → použiješ nástroje z [cvičení 04](../04/README.md):

```bash
sudo tail /var/log/syslog             # posledních 10 řádků (nejnovější záznamy)
sudo tail -n 50 /var/log/syslog
sudo tail -f /var/log/syslog          # sledování živě – Ctrl+C ukončí
sudo less /var/log/syslog             # listování, /text = hledání, G = konec
sudo grep -i error /var/log/syslog    # jen chyby
sudo grep sudo /var/log/auth.log      # kdo a kdy použil sudo
sudo grep 'Failed password' /var/log/auth.log   # neúspěšná SSH přihlášení
zcat /var/log/syslog.2.gz | less      # starší, zkomprimované logy
```

Typický formát řádku:

```
Oct 22 10:15:01 localhost CRON[1234]: (root) CMD (command -v debian-sa1 > /dev/null)
└──────┬─────┘ └───┬───┘ └───┬────┘  └──────────────────┬────────────────────────┘
     čas       hostname  program[PID]                   zpráva
```

## 3.3 Kdo logy zapisuje – `rsyslog`

Programy posílají zprávy **logovacímu démonovi** (*daemon* = služba běžící na pozadí). V současných distribucích je to **`rsyslogd`** (*rocket-fast syslog*, nástupce starého `syslogd`). Ten podle konfigurace rozhoduje, **do kterého souboru** zprávu zapíše.

Konfigurace: **`/etc/rsyslog.conf`** a soubory v **`/etc/rsyslog.d/`**.

```bash
cat /etc/rsyslog.conf
ls /etc/rsyslog.d/
cat /etc/rsyslog.d/50-default.conf    # Ubuntu – pravidla, co kam zapisovat
```

Pravidlo má tvar **`facility.priority   cíl`**:

```
auth,authpriv.*          /var/log/auth.log
kern.*                   -/var/log/kern.log
*.*;auth,authpriv.none   -/var/log/syslog
*.emerg                  :omusrmsg:*
```

**Facility** – **odkud** zpráva pochází:

| Facility | Zdroj |
|---|---|
| `kern` | jádro |
| `auth`, `authpriv` | přihlašování, bezpečnost |
| `mail` | poštovní server |
| `cron` | plánovač úloh |
| `daemon` | systémové služby |
| `user` | uživatelské programy (výchozí pro `logger`) |
| `local0` – `local7` | volné pro vlastní použití |

**Priority** – **jak vážná** je zpráva (od nejzávažnější):

| # | Priorita | Význam |
|---|---|---|
| 0 | `emerg` | systém je nepoužitelný |
| 1 | `alert` | nutný okamžitý zásah |
| 2 | `crit` | kritický stav |
| 3 | `err` | chyba |
| 4 | `warning` | varování |
| 5 | `notice` | běžná, ale významná událost |
| 6 | `info` | informace |
| 7 | `debug` | ladicí výpisy |

> Pravidlo s prioritou zachytí **tu a všechny závažnější**: `mail.warning` = warning, err, crit, alert, emerg.
> `*` = vše, `none` = nic (`auth.none` = žádné zprávy z auth).

## 3.4 Vlastní záznam do logu – `logger`

`logger` pošle zprávu do systémového logu – hodí se ve **skriptech**:

```bash
logger "Ahoj z prikazove radky"
sudo tail -n 3 /var/log/syslog
# Oct 22 10:30:12 localhost sysadmin: Ahoj z prikazove radky

logger -t ZALOHA "Zaloha dokoncena"           # -t: vlastní značka (tag) místo jména uživatele
logger -p user.err "Neco se pokazilo"         # -p: facility.priority
logger -t ZALOHA -p local0.info "Start"
sudo grep ZALOHA /var/log/syslog
```

Použití ve skriptu:

```bash
#!/bin/bash
if tar -czf /tmp/zaloha.tar.gz ~/skripty 2> /dev/null
then
    logger -t ZALOHA "Zaloha OK"
else
    logger -t ZALOHA -p user.err "Zaloha SELHALA"
fi
```

## 3.5 `journald` a `journalctl`

Na systémech se **systemd** běží vedle (nebo místo) rsyslogu **`systemd-journald`**. Ukládá logy v **binárním** formátu a čtou se příkazem **`journalctl`**.

```bash
journalctl                    # vše (od nejstaršího), listuje se jako v less
journalctl -e                 # skočí na konec
journalctl -f                 # sledování živě (jako tail -f)
journalctl -n 20              # posledních 20 záznamů
journalctl -p err             # jen chyby a závažnější
journalctl -u ssh             # jen konkrétní služba (unit)
journalctl --since "1 hour ago"
journalctl --since today
journalctl -b                 # od posledního startu systému
journalctl -k                 # jen zprávy jádra (jako dmesg)
```

> ⚠️ NDG lab běží v kontejneru, kde **systemd obvykle neběží** – `journalctl` tam nemusí nic vypsat.
> Pak pracuj s textovými logy v `/var/log`.

## 3.6 Zprávy jádra – `dmesg`

Jádro si drží zprávy v **kruhovém bufferu** v paměti (hardware, ovladače, disky, USB…):

```bash
dmesg | less
dmesg | tail
dmesg | grep -i usb
dmesg -T                      # čitelný čas místo sekund od startu
```

> V kontejneru může `dmesg` hlásit `Operation not permitted` – zkus `sudo dmesg`.

## 3.7 Přihlášení uživatelů

```bash
who                   # kdo je právě přihlášen
w                     # kdo je přihlášen a co dělá
last                  # historie přihlášení (z /var/log/wtmp)
last -n 5             # posledních 5
sudo lastb            # neúspěšné pokusy o přihlášení (z /var/log/btmp)
lastlog               # poslední přihlášení každého uživatele
```

## 3.8 Rotace logů – `logrotate`

Logy by rostly donekonečna. **`logrotate`** je pravidelně (typicky 1× denně přes cron) **„rotuje"**:

```
syslog        ← aktuální, sem se zapisuje
syslog.1      ← včerejší
syslog.2.gz   ← starší, zkomprimovaný
syslog.3.gz
...           ← nejstarší se mažou
```

```bash
ls /var/log/syslog*
cat /etc/logrotate.conf           # obecná nastavení
ls /etc/logrotate.d/              # pravidla pro jednotlivé programy
cat /etc/logrotate.d/rsyslog
```

Typické volby: `daily` / `weekly` (jak často), `rotate 4` (kolik starých ponechat), `compress` (komprimovat gzipem), `missingok`, `notifempty`.

---

# Úlohy k procvičení

Pracuj v `~/skripty`.

### Shell Scripts

1. Napiš skript `info.sh`, který vypíše jméno uživatele, hostname, aktuální adresář a datum. Spusť ho třemi různými způsoby.
2. Zkopíruj `info.sh` do `~/bin` pod jménem `info` tak, aby šel spustit jen napsáním `info`.
3. Napiš skript `velikost.sh`, který se zeptá na adresář (`read -p`) a vypíše jeho velikost (`du -sh`).
4. Uprav `velikost.sh`, aby místo `read` bral adresář jako **první argument** (`$1`). Když argument chybí, vypíše nápovědu a skončí s kódem 1.
5. Napiš skript `soubor.sh`, který dostane jméno jako argument a vypíše, jestli jde o **adresář**, **běžný soubor**, nebo **neexistuje**.
6. Napiš skript `vek.sh`, který se zeptá na věk a vypíše `dite` (< 15), `teenager` (15–17) nebo `dospely` (≥ 18).
7. Napiš skript `uzivatel.sh`, který zjistí, jestli uživatel zadaný jako argument existuje v `/etc/passwd`. Vrátí kód 0 (existuje) nebo 1 (neexistuje). Ověř přes `echo $?`.
8. Zjisti návratové kódy: `ls /etc`, `ls /neexistuje`, `grep root /etc/passwd`, `grep xyz /etc/passwd`, `grep root /etc/shadow`. Co znamenají?
9. Napiš skript `zaloha.sh`, který zabalí `~/skripty` do `/tmp/zaloha-DATUM.tar.gz` (datum přes `$(date +%F)`) a vypíše, jestli se to povedlo.

### System Logging

10. Vypiš obsah `/var/log`. Které soubory jsou textové a které binární? (nápověda: `file /var/log/*`)
11. Zapiš do systémového logu zprávu `Cviceni 05 - test` se značkou `OS2` a najdi ji v logu.
12. Zapiš zprávu s prioritou `err` a ověř, že se objevila.
13. Najdi v logu všechna použití `sudo`.
14. Uprav `zaloha.sh` z úlohy 9, aby výsledek zapisoval i do logu přes `logger`.
15. Zjisti, kdo je přihlášen a kdy se naposledy přihlásil uživatel `sysadmin`.
16. Najdi, jak často se rotuje `/var/log/syslog` a kolik starých verzí se uchovává.

<details>
<summary>Řešení</summary>

```bash
cd ~/skripty

# 1
cat > info.sh << 'KONEC'
#!/bin/bash
echo "Uzivatel: $USER"
echo "Hostname: $(hostname)"
echo "Adresar:  $(pwd)"
echo "Datum:    $(date)"
KONEC
chmod u+x info.sh
./info.sh
~/skripty/info.sh
bash info.sh

# 2
mkdir -p ~/bin
cp info.sh ~/bin/info
PATH=$PATH:~/bin        # pokud ~/bin v PATH ještě není
info

# 3
cat > velikost.sh << 'KONEC'
#!/bin/bash
read -p "Zadej adresar: " dir
du -sh "$dir"
KONEC
chmod u+x velikost.sh

# 4
cat > velikost.sh << 'KONEC'
#!/bin/bash
if [ $# -eq 0 ]
then
    echo "Pouziti: $0 ADRESAR"
    exit 1
fi
du -sh "$1"
KONEC
./velikost.sh ; echo $?          # nápověda, 1
./velikost.sh /etc

# 5
cat > soubor.sh << 'KONEC'
#!/bin/bash
if [ -d "$1" ]
then
    echo "$1 je adresar"
elif [ -f "$1" ]
then
    echo "$1 je bezny soubor"
else
    echo "$1 neexistuje"
fi
KONEC
chmod u+x soubor.sh
./soubor.sh /etc ; ./soubor.sh /etc/passwd ; ./soubor.sh /xyz

# 6
cat > vek.sh << 'KONEC'
#!/bin/bash
read -p "Kolik ti je let? " vek
if [ "$vek" -lt 15 ]
then
    echo "dite"
elif [ "$vek" -lt 18 ]
then
    echo "teenager"
else
    echo "dospely"
fi
KONEC
chmod u+x vek.sh

# 7
cat > uzivatel.sh << 'KONEC'
#!/bin/bash
if grep -q "^$1:" /etc/passwd
then
    echo "$1 existuje"
    exit 0
else
    echo "$1 neexistuje"
    exit 1
fi
KONEC
chmod u+x uzivatel.sh
./uzivatel.sh root ; echo $?      # 0
./uzivatel.sh pepa ; echo $?      # 1

# 8
ls /etc > /dev/null ; echo $?                 # 0 – OK
ls /neexistuje ; echo $?                      # 2 – chyba (soubor neexistuje)
grep root /etc/passwd > /dev/null ; echo $?   # 0 – nalezeno
grep xyz /etc/passwd ; echo $?                # 1 – nenalezeno
grep root /etc/shadow ; echo $?               # 2 – chyba (Permission denied)

# 9
cat > zaloha.sh << 'KONEC'
#!/bin/bash
cil=/tmp/zaloha-$(date +%F).tar.gz
if tar -czf "$cil" ~/skripty 2> /dev/null
then
    echo "Zaloha ulozena do $cil"
else
    echo "Zaloha selhala"
    exit 1
fi
KONEC
chmod u+x zaloha.sh
./zaloha.sh
tar -tzf /tmp/zaloha-*.tar.gz

# 10
ls -l /var/log
file /var/log/*

# 11
logger -t OS2 "Cviceni 05 - test"
sudo grep OS2 /var/log/syslog

# 12
logger -t OS2 -p user.err "Testovaci chyba"
sudo tail -n 5 /var/log/syslog

# 13
sudo grep sudo /var/log/auth.log

# 14
cat > zaloha.sh << 'KONEC'
#!/bin/bash
cil=/tmp/zaloha-$(date +%F).tar.gz
if tar -czf "$cil" ~/skripty 2> /dev/null
then
    echo "Zaloha ulozena do $cil"
    logger -t ZALOHA "Zaloha OK: $cil"
else
    echo "Zaloha selhala"
    logger -t ZALOHA -p user.err "Zaloha SELHALA"
    exit 1
fi
KONEC
./zaloha.sh
sudo grep ZALOHA /var/log/syslog

# 15
who
last sysadmin | head -3      # nebo: lastlog -u sysadmin

# 16
cat /etc/logrotate.d/rsyslog   # např. daily / weekly, rotate 7 / rotate 4
```
</details>

---

# Tahák

### Skripty

| Potřebuju… | Zápis |
|---|---|
| první řádek skriptu | `#!/bin/bash` |
| komentář | `# text` |
| udělat spustitelný | `chmod u+x skript.sh` (`a+x` pro všechny) |
| spustit | `./skript.sh`, `bash skript.sh` |
| spouštět jen jménem | uložit do `~/bin` |
| výstup příkazu do proměnné | `x=$(prikaz)` (starší `` x=`prikaz` ``) |
| načíst vstup od uživatele | `read -p "Text: " promenna` |
| argumenty skriptu | `$1 $2 …`, počet `$#`, všechny `$@` |
| podmínka | `if [ … ]; then …; elif [ … ]; then …; else …; fi` |
| porovnat řetězce | `[ "$a" = "$b" ]`, `!=`, `-z`, `-n` |
| porovnat čísla | `-eq -ne -lt -le -gt -ge` |
| testovat soubor | `-e -f -d -r -w -x` |
| negace | `[ ! -d "$dir" ]` |
| návratový kód posledního příkazu | `echo $?` |
| ukončit skript s kódem | `exit 1` |
| zahodit chyby | `2> /dev/null` |
| cyklus | `for x in …; do …; done`, `while [ … ]; do …; done` |
| ladění | `bash -x skript.sh` |

### Logy

| Potřebuju… | Příkaz |
|---|---|
| kde jsou logy | `/var/log` |
| hlavní log (Ubuntu / Red Hat) | `/var/log/syslog` / `/var/log/messages` |
| přihlášení a sudo | `/var/log/auth.log` (`/var/log/secure`) |
| posledních N řádků / živě | `sudo tail -n N soubor`, `sudo tail -f soubor` |
| hledat v logu | `sudo grep -i error /var/log/syslog` |
| zapsat do logu | `logger -t ZNACKA -p user.err "zprava"` |
| konfigurace logování | `/etc/rsyslog.conf`, `/etc/rsyslog.d/` |
| journal (systemd) | `journalctl -f`, `-p err`, `-u sluzba`, `--since today` |
| zprávy jádra | `dmesg`, `journalctl -k` |
| kdo je přihlášen / historie | `who`, `w`, `last`, `sudo lastb`, `lastlog` |
| rotace logů | `/etc/logrotate.conf`, `/etc/logrotate.d/` |

---

# Příprava na cvičení 06

Samostudium, splněné laby a testy z modulů:

- **Linux Essentials – Module 12 – Understanding Computer Hardware**
- **Linux Essentials – Module 13 – Where Data is Stored**
