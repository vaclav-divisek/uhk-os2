# Cvičení 02 – Práce s příkazovou řádkou a hledání nápovědy

Podle **NDG Linux Essentials**:

- **Module 5 – Command Line Skills**
- **Module 6 – Getting Help**

**Vstupní požadavky:** splněné *Lab 05 + Chapter 05 Exam* a *Lab 06 + Chapter 06 Exam*,
labs *Linux I. – Configuring the Shell* a *Linux II. – Advanced Shell Features*.

Vše si zkoušíme v laboratorním prostředí **NDG NETLAB+** na [portal.netdevgroup.com](https://portal.netdevgroup.com/).

---

## 0. Příprava prostředí

1. Přihlas se na [portal.netdevgroup.com](https://portal.netdevgroup.com/) a otevři kurz **Linux Essentials**.
2. U modulu 5 (resp. 6) spusť **Lab** – v prohlížeči se otevře terminál.
3. Jsi přihlášen jako uživatel **`sysadmin`**, heslo (např. pro `sudo`) je **`netlab123`**.

```
sysadmin@localhost:~$
```

> - Lab je **dočasný** – po jeho ukončení / vypršení se vše, co jsi vytvořil, smaže.
> - Prostředí je kontejner bez přístupu na internet – **`apt install` nefunguje**, ale vše potřebné
>   pro tyto moduly (`man`, `info`, `locate`, …) už je nainstalované.
> - Kopírování do terminálu v prohlížeči: obvykle `Ctrl+Shift+V` nebo pravé tlačítko myši.

---

# Modul 5 – Command Line Skills

## 5.1 Shell a prompt

**Shell** je program, který čte příkazy a předává je jádru. V NDG labu (i ve většině distribucí) je výchozí **Bash** (*Bourne Again SHell*).

### Shell vs. Bash

- **Shell** = obecný pojem (druh programu) – *příkazový interpret*, rozhraní mezi uživatelem a jádrem.
  Přečte příkaz, rozbalí proměnné a zástupné znaky, najde program a spustí ho.
- **Bash** = jeden **konkrétní** shell (konkrétní program `/bin/bash`), vytvořený v projektu GNU (1989)
  jako svobodná náhrada původního **Bourne shellu** (`sh`).

**Analogie s webovým prohlížečem:**

| Prohlížeče | Shelly |
|---|---|
| „webový prohlížeč" = druh programu | „shell" = druh programu |
| Netscape – původní, ze kterého vzešel Firefox | `sh` – původní Bourne shell, ze kterého vzešel Bash |
| Firefox | `bash` |
| Chrome | `zsh` |
| Edge | `dash` |
| v počítači můžeš mít nainstalovaných víc prohlížečů | v systému může být víc shellů – seznam v `/etc/shells` |
| jeden je nastavený jako **výchozí** | každý uživatel má jeden **výchozí** shell (poslední pole v `/etc/passwd`, zjistíš `echo $SHELL`) |
| jiný prohlížeč můžeš kdykoliv spustit ručně | jiný shell spustíš jeho jménem (`sh`, `dash`), zpět přes `exit` |
| výchozí prohlížeč jde změnit v nastavení | výchozí shell změníš `chsh -s /bin/zsh` |

V NDG labu je výchozím shellem uživatele `sysadmin` **Bash**:

```bash
cat /etc/shells              # nainstalované shelly
grep sysadmin /etc/passwd    # ...:/home/sysadmin:/bin/bash  ← výchozí shell
```

| Shell | Program | Poznámka |
|---|---|---|
| Bourne shell | `sh` | původní unixový shell (1979); dnes je `/bin/sh` obvykle odkaz na `dash` nebo `bash` |
| **Bash** | `bash` | výchozí ve většině Linuxů; rozšiřuje `sh` o historii, aliasy, doplňování Tabem… |
| Dash | `dash` | malý a rychlý, používá se pro systémové skripty (`/bin/sh` v Debianu/Ubuntu) |
| Zsh | `zsh` | výchozí v macOS, hodně rozšíření |
| Fish | `fish` | uživatelsky přívětivý, není kompatibilní se `sh` |
| C shell / tcsh | `csh`, `tcsh` | syntaxe podobná jazyku C |

### Liší se v různých shellech příkazy?

**Externí příkazy jsou všude stejné.** `ls`, `cp`, `cat`, `mkdir`, `grep`… jsou samostatné programy
v `/usr/bin` – shell je jen spustí, takže fungují stejně v `bash`, `sh`, `zsh` i jinde.
*(Analogie: webová stránka google.com je stejná ve Firefoxu i v Chromu.)*

**Liší se syntaxe a vestavěné funkce shellu.**
*(Analogie: ovládání prohlížeče – zkratky, nastavení, doplňky.)*

| Funkce | `bash` | `sh` / `dash` |
|---|---|---|
| historie `!!`, `!42`, šipky, `Ctrl+R` | ✅ | ❌ |
| doplňování Tabem | ✅ | ❌ (v `dash`) |
| rozsahy `echo {1..5}` | `1 2 3 4 5` | `{1..5}` doslova |
| `[[ ... ]]` (rozšířené testy) | ✅ | ❌ chyba |
| pole `a=(x y z)` | ✅ | ❌ chyba |
| `source soubor` | ✅ | ❌ jen `. soubor` |
| `echo -e "a\nb"` | odřádkuje | vypíše i `-e` |
| `$(...)`, `;`, `&&`, `\|\|`, `*`, `?`, `'...'`, `"..."`, proměnné | ✅ | ✅ (základ, umí všechny) |

Vyzkoušej si v NDG:

```bash
echo {1..5}        # bash: 1 2 3 4 5
dash               # přepnu do jiného shellu
echo {1..5}        # dash: {1..5}
!!                 # dash: !!: not found
ls -l /etc | head  # funguje stejně – ls je externí program
exit               # zpět do bashe
```

> Skripty začínají řádkem *shebang*, který určuje, který shell je spustí:
> `#!/bin/bash` (Bash) nebo `#!/bin/sh` (jakýkoliv shell kompatibilní s POSIX `sh`).

```bash
echo $SHELL              # výchozí shell uživatele
echo $0                  # shell, ve kterém právě jsem
cat /etc/shells          # seznam dostupných shellů
```

Prompt `sysadmin@localhost:~$` znamená:

| Část | Význam |
|---|---|
| `sysadmin` | přihlášený uživatel |
| `localhost` | hostname |
| `~` | aktuální adresář (`~` = domovský adresář) |
| `$` | běžný uživatel (`#` = root) |

## 5.2 Formát příkazu

```
příkaz [volby] [argumenty]
```

- **Argument** – na čem příkaz pracuje (soubor, adresář, text…)
- **Volba (option)** – mění chování příkazu
  - krátká: `-l`, lze slučovat: `-la` = `-l -a`
  - dlouhá: `--all`, `--human-readable`

```bash
ls                       # bez voleb a argumentů
ls /etc                  # argument
ls -l /etc               # volba + argument
ls -l -a -h ~            # více voleb
ls -lah ~                # totéž, sloučené
ls --all --human-readable -l ~   # dlouhé volby
ls -r                    # obrácené řazení
ls -lt                   # řazení podle času změny
```

> Linux **rozlišuje velká a malá písmena**: `ls -r` (reverse) ≠ `ls -R` (rekurzivně).

## 5.3 Proměnné (Variables)

Proměnné jsou **klíčovou součástí shellu**. Proměnná je **název (identifikátor)**, kterému je přiřazena **hodnota** (např. `0`, `sue`, `/usr/share/doc`…). Hodnotu pak použiju v příkazech přes `$NAZEV`.

Typy proměnných:

| Typ | Kdo ji vidí |
|---|---|
| **lokální (local)** | jen aktuální shell |
| **prostředí (environment)** | aktuální shell **i všechny programy a skripty**, které z něj spustím |

### Přiřazení hodnoty

`NAZEV=hodnota` – **bez mezer kolem `=`**.

| ✅ Správně | ❌ Špatně | Proč špatně |
|---|---|---|
| `A=1` | `1=a` | název nesmí začínat číslicí |
| `_1=a` | `A-1=3` | pomlčka v názvu není povolená |
| `LONG_VARIABLE='O K'` | `LONG-VARIABLE='WRONG'` | pomlčka (použij podtržítko `_`) |
| `Name='Jose Romero'` | `'user name'=anything` | název nesmí obsahovat mezeru ani být v uvozovkách |

> Název smí obsahovat **písmena, číslice a `_`**, nesmí začínat číslicí. Velká/malá písmena se rozlišují (`name` ≠ `NAME`).

```bash
promenna=hodnota         # BEZ mezer kolem "="!
echo $promenna           # výpis hodnoty – prefix $
Name='Jose Romero'       # mezery v hodnotě → uvozovky
echo "Ahoj $Name"
promenna = hodnota       # CHYBA: shell hledá příkaz "promenna"
```

### Výpis a mazání proměnných

| Příkaz | Co vypíše |
|---|---|
| `set` | **všechny** proměnné (lokální i prostředí) + funkce |
| `env` | jen proměnné **prostředí** |
| `declare -x` | jen proměnné prostředí |
| `typeset -x` | totéž (starší synonymum `declare`) |
| `export -p` | totéž |
| `echo $NAZEV` | hodnotu jedné proměnné |
| `unset NAZEV` | proměnnou smaže |

```bash
set | less
env
declare -x | head
export -p | head
unset promenna
```

> ⚠️ **Nemaž systémové proměnné** jako `PATH` – shell pak přestane nacházet příkazy
> (`unset PATH` → `ls: No such file or directory`). Napraví to až nové přihlášení.

Důležité systémové proměnné: `HOME`, `USER`, `PATH`, `PWD`, `SHELL`, `PS1`, `HISTSIZE`, `HISTFILESIZE`.

### Proměnná místo dlouhé cesty

Dlouhou cestu napíšu jen jednou a pak ji používám v libovolném příkazu:

```bash
DOC=/usr/share/doc/bash
ls $DOC
cd $DOC
cd ~
cp $DOC/README* ~/
echo "Dokumentace k bashi je v: $DOC"
```

### Proměnná s výstupem příkazu (čas)

Do proměnné můžu uložit i **výstup příkazu** pomocí `$( )` (nebo starším zápisem `` `příkaz` ``):

```bash
date                          # aktuální datum a čas
date +%H:%M:%S                # jen čas, např. 14:05:31
CAS=$(date +%H:%M:%S)
echo "Ted je $CAS"
# počkej pár sekund...
echo "Ted je $CAS"            # pořád STEJNÝ čas!
```

> Hodnota se uloží **v okamžiku přiřazení** – proměnná si pamatuje výsledek, ne příkaz.
> Aktuální čas dostanu jen novým spuštěním: `echo "Ted je $(date +%H:%M:%S)"`.

### Lokální proměnná vs. proměnná prostředí – ukázka na skriptu

Vytvořím malý skript, který vypíše čas a pozdraví uživatele uloženého v proměnné `JMENO`:

```bash
cat > cas.sh << 'KONEC'
#!/bin/bash
echo "Ahoj $JMENO, je $(date +%H:%M:%S)"
KONEC

chmod +x cas.sh
./cas.sh                      # Ahoj , je 14:05:31   ← JMENO zatím neexistuje
```

Skript běží jako **nový proces** a vidí jen proměnné **prostředí** (exportované):

```bash
JMENO=Petr                    # lokální proměnná – zná ji jen tento shell, protože bash běží v jiném procesu
echo $JMENO                   # Petr
./cas.sh                      # Ahoj , je 14:06:10   ← skript ji NEVIDÍ

export JMENO                  # z lokální udělám proměnnou prostředí
./cas.sh                      # Ahoj Petr, je 14:06:25

export JMENO=Eva              # rovnou definice + export
./cas.sh                      # Ahoj Eva, je 14:06:40

env | grep JMENO              # teď už je mezi proměnnými prostředí
```

> Psaní skriptů (podmínky, cykly, argumenty) je podrobně až v Modulu 9 – tady skript
> slouží jen k pochopení rozdílu mezi lokální proměnnou a proměnnou prostředí.

## 5.4 Proměnná PATH

`PATH` obsahuje **seznam adresářů oddělených `:`**, ve kterých shell hledá zadané příkazy.
Shell je prochází **zleva doprava** a spustí první nalezený.

```bash
echo $PATH
# /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:...
```

Typické adresáře v `PATH`:

| Adresář | Obsah |
|---|---|
| `/bin` | nejzákladnější příkazy nutné pro běh systému |
| `/usr/bin` | většina příkazů pro běžné uživatele |
| `/sbin` | základní příkazy pro správu systému |
| `/usr/sbin` | většina administrátorských příkazů |
| `/usr/local/bin` | obvykle prázdný; programy zkompilované lokálně |
| `/usr/local/sbin` | obvykle prázdný; lokálně zkompilované admin. příkazy |
| `/home/<uzivatel>/bin` | vlastní skripty uživatele (např. `/home/sysadmin/bin`) |

### Příklad: skript, který shell „nenajde"

Vytvořím v domovském adresáři skript `my.sh` (stejný jako ve slidech):

```bash
cat > my.sh << 'KONEC'
#!/bin/bash
echo "Today is `date +%D`"
echo "Hello $Hello ${USER}tech"
KONEC

chmod u+x my.sh               # právo spuštění pro vlastníka
my.sh
# -bash: my.sh: command not found
```

Proč? Skript leží v `/home/sysadmin`, a ten **není v `PATH`**.

> - `` `date +%D` `` – substituce příkazu, vloží datum ve tvaru `10/01/26`
> - `$Hello` – proměnná, která neexistuje → prázdný text
> - `${USER}tech` – složené závorky oddělí název proměnné od textu za ní
>   (`$USERtech` by hledalo proměnnou `USERtech`, která neexistuje)

**4 způsoby, jak skript mimo `PATH` spustit:**

```bash
# 1) absolutní cesta
/home/sysadmin/my.sh
# Today is 10/01/26
# Hello  sysadmintech

# 2) relativní cesta (./ = aktuální adresář)
./my.sh

# 3) přidání adresáře do PATH (platí jen pro tuto relaci)
PATH=$PATH:/home/sysadmin
echo $PATH                    # ...:/home/sysadmin na konci
my.sh                         # už funguje bez cesty

# 4) zkopírování skriptu do adresáře, který v PATH je
mkdir -p ~/bin
cp my.sh ~/bin/
```

> Bod 4: `~/bin` se do `PATH` přidává automaticky při přihlášení (v `~/.profile`), **pokud existuje**.
> Pokud jsi ho právě vytvořil, odhlas se a přihlas, nebo ho přidej ručně: `PATH=$PATH:~/bin`.
> Trvalé nastavení `PATH` patří do `~/.bashrc`.

**Bez `PATH` se spustí i příkazy, které:**
- jsou **součástí shellu** (builtin – `cd`, `echo`),
- jsou **aliasy**,
- jsou **funkce**,
- jsou vyvolány **absolutní cestou** (`/usr/bin/ls`),
- jsou vyvolány **relativní cestou** (`./my.sh`, `test/newfile`).

### Typ příkazu – `type`

Když se dva příkazy jmenují stejně (můj skript vs. systémový příkaz), `type` ukáže, co se opravdu spustí:

```bash
hello() { echo hello; }       # pro ukázku vytvořím funkci

type echo                     # echo is a shell builtin
type hello                    # hello is a function ...
type ls                       # ls is aliased to `ls --color=auto'
type cal                      # cal is /usr/bin/cal
type junk                     # -bash: type: junk: not found
type -a ls                    # všechny výskyty (alias i /usr/bin/ls)
which ls                      # jen cesta k externímu příkazu
```

| Typ | Popis | Příklad |
|---|---|---|
| **builtin** | součást shellu | `cd`, `echo`, `type`, `history` |
| **externí (soubor)** | spustitelný soubor v `PATH` | `ls`, `cat`, `cal` |
| **alias** | zkratka pro jiný příkaz | `ll`, `ls` |
| **funkce** | funkce definovaná v shellu | `hello` |

### ⚠️ Pořadí hledání – co se spustí, když se dva příkazy jmenují stejně

> **Shell hledá v pořadí: alias → funkce → builtin → `PATH` (adresáře zleva doprava)**
> **a spustí PRVNÍ, co najde.** Zbytek už neprohledává.

Když si tedy vytvořím vlastní `ls`, **může přebít systémový `/usr/bin/ls`** – záleží na tom, jak:

| Jak si udělám „svůj ls" | Spustí se můj? |
|---|---|
| `alias ls='echo muj ls'` | ✅ **ano** – alias má přednost přede vším |
| funkce `ls() { echo muj ls; }` | ✅ **ano** |
| skript `ls` v adresáři, který je v `PATH` **před** `/usr/bin` (`PATH=~/bin:$PATH`) | ✅ **ano** |
| skript `ls` v adresáři přidaném **na konec** `PATH` (`PATH=$PATH:~/bin`) | ❌ ne – shell dřív najde `/usr/bin/ls` |
| skript `ls` v adresáři, který v `PATH` není | ❌ ne – spustím ho jen cestou `./ls` |

Vyzkoušej:

```bash
# funkce přebije systémový ls
ls() { echo "Tohle je MUJ ls"; }
ls                     # Tohle je MUJ ls
type ls                # ls is a function
unset -f ls            # smaže funkci → zase systémový ls

# skript ls v ~/bin
mkdir -p ~/bin
printf '#!/bin/bash\necho "MUJ ls ze skriptu"\n' > ~/bin/ls
chmod +x ~/bin/ls

PATH=$PATH:~/bin       # ~/bin na KONCI
type -a ls             # alias, /usr/bin/ls, ... ~/bin/ls až poslední
\ls                    # systémový ls (\ = bez aliasu)

PATH=~/bin:$PATH       # ~/bin na ZAČÁTKU
hash -r                # bash si pamatuje cesty k příkazům – tímto je zapomene
\ls                    # MUJ ls ze skriptu
ls                     # taky MUJ – alias se rozbalí na "ls --color=auto"
                       # a to "ls" se pak hledá v PATH

rm ~/bin/ls            # úklid!
```

> 🔒 **Bezpečnost:** kdo může zapisovat do adresáře, který je v `PATH` vepředu, může podvrhnout
> `ls`, `sudo` apod. Proto v `PATH` **nikdy není `.`** (aktuální adresář) a vlastní skript
> v aktuálním adresáři musím spustit jako `./my.sh`.

## 5.5 Prompt – proměnná `PS1`

Vzhled promptu určuje proměnná `PS1`. Speciální kódy začínají **zpětným lomítkem `\`**:

| Kód | Význam |
|---|---|
| `\u` | uživatelské jméno |
| `\h` | hostname |
| `\W` | název aktuálního adresáře (jen poslední část) |
| `\w` | celá cesta aktuálního adresáře |
| `\$` | `$` pro běžného uživatele, `#` pro roota |
| `\t` | aktuální čas |

```bash
echo $PS1                       # aktuální nastavení
PUVODNI=$PS1                    # záloha
PS1='\u@\h:\W\$ '               # sysadmin@localhost:~$
PS1='[\t] \u v \w \$ '          # [14:05:31] sysadmin v ~ $
PS1=$PUVODNI                    # obnovení
```

> Změna platí jen pro aktuální relaci; trvale se nastavuje v `~/.bashrc`.

### K čemu je to dobré?

Prompt slouží hlavně k **orientaci a prevenci chyb**:

| K čemu | Kód | Proč |
|---|---|---|
| **Kdo jsem** | `\u`, `\$` | jako root můžeš systém rozbít – `#` místo `$` tě varuje dřív, než napíšeš `rm -rf` |
| **Na jakém stroji** | `\h` | admin má často otevřených víc SSH oken – prompt řekne, jestli jsem na testu, nebo na produkci |
| **Kde jsem** | `\W`, `\w` | nemusím pořád psát `pwd`, než spustím třeba `rm *` |
| **Kdy** | `\t` | při kopírování výstupu do dokumentace / protokolu je vidět, kdy co proběhlo |
| **Barvy** | `\e[...m` | např. červený prompt pro root nebo produkci → „nebezpečné" okno poznám na první pohled |
| **Kontext práce** | — | nástroje si do promptu přidávají info samy, např. git větev nebo Python venv: `(venv) user@host:~/projekt (main)$` |

Příklad „varovného" promptu pro produkční server:

```bash
PS1='\[\e[1;31m\][PRODUKCE] \u@\h:\w\$ \[\e[0m\]'
# [PRODUKCE] sysadmin@localhost:~$          ← tučně červeně
PS1=$PUVODNI                                 # vrácení zpět
```

> `\e[1;31m` zapne tučnou červenou, `\e[0m` vrátí výchozí barvu. Obalení do `\[ \]` říká bashi,
> že jde o neviditelné znaky – jinak by špatně počítal délku řádku a rozbilo by se zalamování.

**Hlavní myšlenka pro cvičení:** i prompt je **jen proměnná** – shell ji vypíše před každým příkazem
a já ji můžu změnit stejně jako jakoukoliv jinou proměnnou.

## 5.6 Historie příkazů

```bash
history                  # výpis historie
history 5                # posledních 5 příkazů
!!                       # zopakuje poslední příkaz
sudo !!                  # poslední příkaz znovu se sudo
!42                      # spustí příkaz č. 42 z historie
!-3                      # třetí příkaz od konce
!ls                      # poslední příkaz začínající "ls"
```

Klávesové zkratky:

| Zkratka | Akce |
|---|---|
| `↑` / `↓` | listování historií |
| `Ctrl+R` | zpětné hledání v historii |
| `Tab` | doplnění příkazu / cesty (2× Tab = nabídka) |
| `Ctrl+A` / `Ctrl+E` | začátek / konec řádku |
| `Ctrl+C` | přeruší běžící příkaz |
| `Ctrl+L` | vyčistí obrazovku (jako `clear`) |
| `Ctrl+D` | konec vstupu / odhlášení |

### Proměnné ovlivňující historii

| Proměnná | Význam |
|---|---|
| `HISTFILE` | soubor s historií (výchozí `~/.bash_history`) |
| `HISTFILESIZE` | kolik záznamů se uloží **do souboru** |
| `HISTSIZE` | kolik záznamů se drží **v paměti**; je-li větší než `HISTFILESIZE`, do souboru se uloží jen posledních `HISTFILESIZE` |
| `HISTCONTROL` | které příkazy se do historie **neukládají** |
| `HISTIGNORE` | vzory příkazů, které se neukládají |

Hodnoty `HISTCONTROL`:

| Hodnota | Efekt |
|---|---|
| `ignoredups` | neukládá stejný příkaz zadaný vícekrát po sobě |
| `ignorespace` | neukládá příkazy začínající **mezerou** |
| `ignoreboth` | `ignoredups` + `ignorespace` |
| `erasedups` | smaže starší výskyty stejného příkazu |
| `ignorespace:erasedups` | kombinace obou |

```bash
echo $HISTFILE $HISTSIZE $HISTFILESIZE $HISTCONTROL

HISTCONTROL=ignoreboth
pwd
pwd
pwd
 echo tajne heslo         # ← mezera na začátku
history 5                 # pwd jen jednou, "tajne heslo" chybí

HISTIGNORE='ls*:cd*:history*:exit'
ls -l
cd /tmp
pwd
history 5                 # z těchto tří se uložilo jen pwd
```

> Historie se zapisuje do souboru `HISTFILE` při odhlášení (nebo ručně `history -w`).

## 5.7 Aliasy

Alias je **další způsob, jak vyvolat příkaz**. Umožňuje:
- **zkratku** pro příkaz,
- vyvolat příkaz se **specifickými volbami**,
- vyvolat **sérii příkazů** (oddělených `;` nebo `|`).

Syntaxe: `alias nazev='prikaz --volby argumenty'`

```bash
alias                          # výpis všech aliasů
alias c='clear'                # zkratka
alias grep='grep --color'      # příkaz s volbou
alias ll='ls -l --color=auto'
alias stav='whoami; date; pwd'           # série příkazů (;)
alias pocet='ls /etc | wc -l'            # série příkazů (|)
type ll
unalias c                      # smazání aliasu
\ls                            # spustí ls BEZ aliasu
```

**Trvalé (persistentní) aliasy** – alias zadaný v terminálu zmizí po odhlášení:

| Soubor | Platnost |
|---|---|
| `/etc/profile`, `/etc/profile.d/*.sh` | pro **všechny** uživatele |
| `~/.bashrc` | jen pro **daného** uživatele |

```bash
echo "alias c='clear'" >> ~/.bashrc
source ~/.bashrc               # načte změny hned (jinak až po novém přihlášení)
```

## 5.8 Funkce

Funkce funguje jako alias, ale může obsahovat **víc příkazů na více řádcích**.

Syntaxe: `nazev_funkce() { prikazy; }`

Příklad ze slidů – funkce, která vytvoří report o adresáři s dokumentací:

```bash
report() {
    cd /usr/share/doc
    echo "Document directory usage report" > /tmp/report
    date >> /tmp/report
    pwd >> /tmp/report
    du -sh . >> /tmp/report
}

report
cat /tmp/report
type report
```

> `>` zapíše výstup do souboru (přepíše ho), `>>` připíše na konec.

**Trvalá funkce** se – stejně jako alias – přidá do `~/.bashrc`. Ukázka `~/.bashrc` ze slidů:

```bash
# .bashrc
HISTCONTROL='ignorespace:erasedups'

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific aliases and functions
alias grep='grep --color'
report() {
    cd /usr/share/doc
    echo "Document directory usage report" > /tmp/report
    date >> /tmp/report
    pwd >> /tmp/report
    du -sh . >> /tmp/report
}
```

## 5.9 Globbing (zástupné znaky)

Shell rozbalí vzory **ještě před spuštěním příkazu**.

| Vzor | Význam |
|---|---|
| `*` | libovolný počet libovolných znaků (i žádný) |
| `?` | právě jeden znak |
| `[abc]` | jeden znak z výčtu |
| `[a-f]` | jeden znak z rozsahu |
| `[!abc]` | jeden znak, který **není** ve výčtu |

```bash
echo /etc/t*             # vše v /etc začínající na t
echo /etc/*.d            # končí na .d
echo /etc/????           # přesně 4znaková jména
echo /etc/[gu]*          # začíná na g nebo u
echo /etc/[a-d]*         # začíná na a–d
echo /etc/[!a-t]*        # NEzačíná na a–t
echo /etc/*[0-9]*        # obsahuje číslici
```

> Tip: `echo` je ideální na vyzkoušení, na co se vzor rozbalí, než ho použiješ s `rm`.

## 5.10 Uvozovky a escapování

| Zápis | Chování |
|---|---|
| `"dvojité"` | potlačí globbing, ale **proměnné a `$( )` se rozbalí** |
| `'jednoduché'` | potlačí **vše** – text se vezme doslova |
| `\` (backslash) | potlačí speciální význam jednoho následujícího znaku |
| `` `příkaz` `` nebo `$(příkaz)` | **substituce příkazu** – nahradí se výstupem příkazu |

```bash
echo The service costs $100 and the path is $PATH
echo "The service costs $100 and the path is $PATH"
echo 'The service costs $100 and the path is $PATH'
echo "The service costs \$100 and the path is $PATH"

echo "Dnes je date"
echo "Dnes je $(date)"
echo "Dnes je `date`"     # starší zápis, raději $( )
echo 'Dnes je $(date)'    # nerozbalí se

echo /etc/*.conf
echo "/etc/*.conf"        # uvozovky potlačí globbing
```

## 5.11 Seznamy (Lists) – řídicí operátory

Seznam = série příkazů oddělených jedním nebo více operátory:

| Operátor | Význam |
|---|---|
| `;` | příkazy se spustí **postupně**; shell čeká na dokončení každého. Návratový kód = kód posledního příkazu. |
| `&` | příkaz se spustí **na pozadí** (v subshellu); shell nečeká a hned vrátí kód 0 |
| `&&` | **AND** – pravý příkaz se spustí jen když levý **uspěl** (návratový kód 0) |
| `\|\|` | **OR** – pravý příkaz se spustí jen když levý **selhal** (≠ 0) |

```bash
# ;
cal 1 2026 ; cal 2 2026 ; cal 3 2026

# &
sleep 10 &                # [1] 1234 – běží na pozadí, prompt je hned volný
jobs                      # výpis úloh na pozadí
echo "mezitim pracuju"

# &&
ls /etc/ssh && echo "uspech"
ls /neexistuje && echo "uspech"

# ||
ls /etc/ssh || echo "chyba"
ls /neexistuje || echo "chyba"

echo $?                   # návratový kód posledního příkazu

# typický vzor "if-else" na jednom řádku
ls /neexistuje && echo OK || echo FAIL

true ; echo $?            # 0
false ; echo $?           # 1
```

---

# Modul 6 – Getting Help

## 6.1 Manuálové stránky – `man`

```bash
man ls
man man                  # nápověda k samotnému man
```

Ovládání (používá pager `less`):

| Klávesa | Akce |
|---|---|
| `Mezerník` / `b` | stránka dolů / nahoru |
| `Enter`, `↓` / `↑` | řádek dolů / nahoru |
| `/text` | hledat dopředu, `n` = další, `N` = předchozí |
| `?text` | hledat dozadu |
| `g` / `G` | začátek / konec |
| `h` | nápověda k ovládání |
| `q` | konec |

### Struktura man stránky

| Sekce | Obsah |
|---|---|
| `NAME` | název a jednořádkový popis |
| `SYNOPSIS` | syntaxe – `[ ]` = volitelné, `...` = může se opakovat, `\|` = nebo |
| `DESCRIPTION` | podrobný popis a volby |
| `OPTIONS` | (někdy samostatně) popis voleb |
| `EXAMPLES` | příklady (ne vždy) |
| `FILES` | související soubory |
| `AUTHOR`, `REPORTING BUGS`, `COPYRIGHT` | autoři, hlášení chyb, licence |
| `SEE ALSO` | související příkazy |

### Sekce (kapitoly) manuálu

| Č. | Obsah |
|---|---|
| **1** | uživatelské příkazy |
| 2 | systémová volání (jádro) |
| 3 | funkce knihoven (C) |
| 4 | speciální soubory (`/dev`) |
| **5** | formáty konfiguračních souborů |
| 6 | hry |
| 7 | různé (konvence, protokoly) |
| **8** | příkazy pro správu systému (root) |
| 9 | rutiny jádra |

Některá jména existují ve více sekcích – například `passwd` je příkaz (1) i formát souboru `/etc/passwd` (5):

```bash
man passwd               # otevře první nalezenou = sekce 1
man 5 passwd             # formát souboru /etc/passwd
man -a passwd            # postupně všechny sekce
man 8 useradd
man 7 man                # jak se píšou man stránky
```

### Hledání v manuálu

```bash
man -f passwd            # = whatis passwd – v jakých sekcích existuje
whatis ls

man -k password          # = apropos password – hledá klíčové slovo v NAME/popisu
apropos copy
apropos -s 1 copy        # jen v sekci 1
man -k '^cp'             # regulární výraz
```

> Když `man -k` nic nenajde, zaktualizuj databázi: `sudo mandb`.

## 6.2 Info stránky – `info`

Podrobnější dokumentace členěná do uzlů (nodes) s odkazy – hlavně u GNU nástrojů.

```bash
info ls
info coreutils
info                     # celý adresář dokumentace
```

| Klávesa | Akce |
|---|---|
| `Mezerník` / `Backspace` | stránka dolů / nahoru |
| `Tab` + `Enter` | přechod na odkaz (`* Menu`) |
| `n` / `p` | další / předchozí uzel |
| `u` | o úroveň výš |
| `l` | zpět (jako v prohlížeči) |
| `s` | hledání |
| `h` | návod k ovládání |
| `q` | konec |

## 6.3 Volba `--help` a příkaz `help`

Rychlé shrnutí voleb přímo z příkazu – nejrychlejší způsob nápovědy:

```bash
ls --help
ls --help | less
cp --help | grep -- '-r'
```

Vestavěné příkazy shellu **nemají** vlastní man stránku – nápovědu dává `help`:

```bash
type cd                  # builtin
man cd                   # nic / obecná stránka
help cd
help                     # seznam všech builtinů
```

## 6.4 Další dokumentace

```bash
ls /usr/share/doc
ls /usr/share/doc/bash
zless /usr/share/doc/bash/README.gz   # .gz soubory čti přes zless / zcat
```

Online: [The Linux Documentation Project](https://tldp.org), dokumentace distribuce (Ubuntu Docs, ArchWiki), `man7.org`.

## 6.5 Hledání příkazů a souborů

### `whereis` – binárka, zdrojáky a man stránky

```bash
whereis ls
whereis passwd           # binárka, /etc/passwd i man stránky
whereis -b passwd        # jen binárky
whereis -m passwd        # jen man stránky
```

### `which` – kterou binárku shell spustí

```bash
which ls
which -a python3
```

### `locate` – rychlé hledání podle databáze

```bash
sudo updatedb                   # heslo netlab123; databáze se jinak aktualizuje 1× denně (cron)
locate passwd
locate -c passwd                # jen počet
locate -i readme                # bez ohledu na velikost písmen
locate -b '\passwd'             # přesný název souboru (basename)
```

> `locate` nenajde soubor vytvořený po posledním `updatedb`:
>
> ```bash
> touch ~/novy_soubor.txt
> locate novy_soubor.txt         # nic
> sudo updatedb
> locate novy_soubor.txt         # už ano
> ```

(Příkaz `find`, který hledá v reálném čase, je podrobněji v dalších modulech.)

---

# Úlohy k procvičení

### Modul 5

1. Které z přiřazení jsou platná? `X1=a`, `1X=a`, `MY-VAR=5`, `MY_VAR=5`, `my var=5`, `_test='a b'`. Ověř v terminálu.
2. Vytvoř lokální proměnnou `KURZ=OS2`. Ověř, že ji `set` vypíše, ale `env` ani `declare -x` ne. Pak ji exportuj a ověř znovu. Nakonec ji smaž.
3. Vytvoř skript `kurz.sh`, který vypíše `Kurz: <KURZ>, cas: <aktualni cas>`. Ověř, že lokální `KURZ` skript nevidí a exportovanou ano.
4. Vytvoř skript `my.sh` ze slidů. Ukaž, že `my.sh` skončí chybou `command not found`, a spusť ho **třemi** různými způsoby (absolutní cesta, relativní cesta, úprava `PATH`).
5. Zjisti, jakého typu jsou příkazy `cd`, `ls`, `echo`, `cal`, `report` (po vytvoření funkce) a `junk`.
6. Nastav prompt tak, aby vypadal jako `[čas] uzivatel@host:adresar$ `. Pak ho vrať zpět.
7. Nastav historii tak, aby neukládala duplicitní příkazy ani příkazy začínající mezerou. Ověř.
8. Vytvoř alias `lsh` pro `ls -lh` a alias `stav`, který postupně vypíše `whoami`, `date` a `pwd`. Udělej `lsh` trvalým.
9. Vytvoř funkci `report` ze slidů, spusť ji a vypiš `/tmp/report`.
10. Vypiš pomocí `echo` všechny soubory v `/etc`, které: a) začínají na `p`, b) mají přesně 5 znaků, c) končí číslicí, d) nezačínají písmenem `a`–`m`.
11. Vypiš doslova text `Cena: $50, cesta: $HOME` (bez rozbalení).
12. Jedním řádkem: vytvoř adresář `~/test` a **jen pokud se to povede**, vypiš `Hotovo`; pokud ne, vypiš `Nepovedlo se`. Spusť to dvakrát a vysvětli rozdíl.
13. Spusť `sleep 20` na pozadí, ověř přes `jobs`, že běží, a mezitím vypiš datum.

<details>
<summary>Řešení – Modul 5</summary>

```bash
# 1
X1=a          # OK
1X=a          # chyba – začíná číslicí
MY-VAR=5      # chyba – pomlčka
MY_VAR=5      # OK
my var=5      # chyba – mezera (shell hledá příkaz "my")
_test='a b'   # OK

# 2
KURZ=OS2
set | grep KURZ               # KURZ=OS2
env | grep KURZ               # nic
declare -x | grep KURZ        # nic
export KURZ
env | grep KURZ               # KURZ=OS2
unset KURZ

# 3
echo 'echo "Kurz: $KURZ, cas: $(date +%H:%M)"' > kurz.sh
chmod +x kurz.sh
KURZ=OS2
./kurz.sh                     # Kurz: , cas: 14:10   ← lokální se nedědí
export KURZ
./kurz.sh                     # Kurz: OS2, cas: 14:10

# 4
my.sh                         # command not found
/home/sysadmin/my.sh
./my.sh
PATH=$PATH:/home/sysadmin
my.sh

# 5
report() { echo test; }
type cd ls echo cal report junk

# 6
PUVODNI=$PS1
PS1='[\t] \u@\h:\W\$ '
PS1=$PUVODNI

# 7
HISTCONTROL=ignoreboth
pwd
pwd
 echo tajne
history 5

# 8
alias lsh='ls -lh'
alias stav='whoami; date; pwd'
echo "alias lsh='ls -lh'" >> ~/.bashrc
source ~/.bashrc

# 9
report() {
    cd /usr/share/doc
    echo "Document directory usage report" > /tmp/report
    date >> /tmp/report
    pwd >> /tmp/report
    du -sh . >> /tmp/report
}
report
cat /tmp/report

# 10
echo /etc/p*
echo /etc/?????
echo /etc/*[0-9]
echo /etc/[!a-m]*

# 11
echo 'Cena: $50, cesta: $HOME'

# 12
mkdir ~/test && echo Hotovo || echo "Nepovedlo se"
# 1. spuštění: Hotovo; 2. spuštění: adresář už existuje → mkdir vrátí ≠ 0 → "Nepovedlo se"

# 13
sleep 20 &
jobs
date
```
</details>

### Modul 6

1. V kterých sekcích manuálu existuje `passwd`? Otevři stránku popisující **formát souboru** `/etc/passwd` a zjisti, kolik polí má jeden řádek.
2. V `man ls` najdi volbu pro řazení podle velikosti souboru.
3. Najdi příkazy, které souvisejí se slovem `compress`.
4. Kterou volbou `cp` kopíruje adresáře rekurzivně? Zjisti to **bez** otevírání `man`.
5. Proč `man cd` nefunguje? Jak získáš nápovědu k `cd`?
6. Kde leží binárka a man stránky příkazu `ls`?
7. Vytvoř soubor `~/hledej_me.txt` a najdi ho pomocí `locate`. Proč napoprvé nic nenajde?
8. V `info coreutils` najdi uzel o příkazu `ls` a přečti si, co dělá volba `--sort`.
9. V jaké sekci manuálu najdeš příkazy pro správu systému? Uveď příklad.

<details>
<summary>Řešení – Modul 6</summary>

```bash
# 1
man -f passwd                   # passwd (1), passwd (1ssl), passwd (5)
man 5 passwd                    # 7 polí oddělených ":"

# 2
man ls   →  /size   →  -S  (sort by file size, largest first)

# 3
apropos compress                # gzip, bzip2, xz, zip ...

# 4
cp --help | grep -i recursive   # -R, -r, --recursive

# 5
type cd                         # builtin → nemá vlastní man stránku
help cd

# 6
whereis ls                      # /usr/bin/ls, /usr/share/man/man1/ls.1.gz

# 7
touch ~/hledej_me.txt
locate hledej_me                # nic – databáze je stará
sudo updatedb
locate hledej_me                # /home/sysadmin/hledej_me.txt

# 8
info coreutils   →  * ls invocation  (nebo rovnou: info ls)

# 9
# sekce 8, např.:
man 8 useradd
man 8 shutdown
```
</details>

---

# Tahák

| Potřebuju… | Příkaz |
|---|---|
| typ příkazu | `type cmd` |
| cestu k binárce | `which cmd`, `whereis cmd` |
| rychlý přehled voleb | `cmd --help` |
| nápovědu k builtinu | `help cmd` |
| plný manuál | `man cmd`, `man 5 soubor` |
| v jakých sekcích je | `man -f` = `whatis` |
| najít příkaz podle tématu | `man -k` = `apropos` |
| podrobnou GNU dokumentaci | `info cmd` |
| najít soubor podle jména | `locate jmeno` (po `sudo updatedb`) |
| návratový kód | `echo $?` |
| proměnnou předat podprocesům | `export VAR` |
| všechny / jen exportované proměnné | `set` / `env`, `declare -x`, `export -p` |
| spustit skript mimo PATH | `./skript.sh`, `/cesta/skript.sh` |
| přidat adresář do PATH | `PATH=$PATH:/adresar` |
| upravit prompt | `PS1='\u@\h:\W\$ '` |
| neukládat duplicity a příkazy s mezerou | `HISTCONTROL=ignoreboth` |
| trvalý alias / funkce | do `~/.bashrc`, pak `source ~/.bashrc` |
| spustit na pozadí | `prikaz &`, `jobs` |
| výstup příkazu do textu | `"$(cmd)"` |
| text doslova | `'...'` |
