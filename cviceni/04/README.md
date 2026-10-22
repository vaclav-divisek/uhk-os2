# Cvičení 04 – Práce s textem, regulární výrazy, vi a přesměrování

Podle **NDG Linux Essentials** a labů **Linux I.**:

- **Module 9 – Archiving and Compression**
- **Module 10 – Working with Text**
- Linux I. – **Text Utilities**, **Regular Expressions**, **The vi Editor**, **Standard Text Streams and Redirection**

**Vstupní požadavky:** splněné *Lab 09 + Chapter 09 Exam* a *Lab 10 + Chapter 10 Exam* a Exams z předchozích modulů.

Vše si zkoušíme v laboratorním prostředí **NDG NETLAB+** na [portal.netdevgroup.com](https://portal.netdevgroup.com/).

---

## 0. Příprava prostředí

1. Přihlas se na [portal.netdevgroup.com](https://portal.netdevgroup.com/) a spusť **Lab** příslušného modulu.
2. Jsi přihlášen jako **`sysadmin`**, heslo pro `sudo` je **`netlab123`**.
3. V `~/Documents` jsou ukázkové soubory, se kterými pracují slidy (`alpha-first.txt`, `longfile.txt`, `newhome.txt`, `numbers.txt`, `letters.txt`, `people.csv`, `profile.txt`, `red.txt`, `animals.txt`, `hidden.txt`…).

Pracuj v kopii, ať si nerozbiješ originály:

```bash
cp -r ~/Documents ~/cv04
cd ~/cv04
ls
```

> Lab je **dočasný** – po jeho ukončení se vše smaže.

---

# 1. Text Utilities (nástroje pro práci s textem)

Linuxové příkazy byly od začátku navrženy hlavně ke **zpracování textu**. Mnoho z nich funguje jako **filtry**: přečtou text, nějak ho upraví a výsledek vypíšou. Filtry se dají **řetězit rourou `|`** – výstup jednoho příkazu je vstupem dalšího.

| Příkaz | Co dělá |
|---|---|
| `cat` | vypíše (a spojí) soubory |
| `split` | rozdělí soubor na více menších |
| `nl` | očísluje řádky |
| `head` / `tail` | prvních / posledních N řádků |
| `paste` | spojí soubory **vedle sebe** (po řádcích) |
| `cut` | vyřízne **sloupce / pole** |
| `sort` | seřadí řádky |
| `uniq` | odstraní / spočítá **opakující se** řádky |
| `od` | zobrazí „surová" data (osmičkově, hexa…) |
| `tr` | nahradí / smaže **znaky** |
| `sed` | nahrazuje **text** (neinteraktivní editor) |
| `wc` | spočítá řádky, slova, znaky |

## 1.1 `cat` – výpis a spojení souborů

`cat` (*concatenate*) vypíše obsah souboru. S více argumenty je **spojí za sebe**.

```bash
cat alpha-first.txt
cat alpha-first.txt alpha-second.txt              # oba za sebou
cat alpha-first.txt alpha-second.txt > alpha-vse.txt   # spojení do nového souboru
cat -n newhome.txt                                # s čísly řádků
cat -A hidden.txt                                 # zobrazí i neviditelné znaky (konce řádků $, tabulátory ^I)
```

> Na dlouhé soubory je lepší `less soubor` (listování, `q` = konec).

## 1.2 `split` – rozdělení souboru

Rozdělí soubor na více souborů. Výchozí: **po 1000 řádcích**, jména s prefixem `x` a abecedním sufixem `aa`, `ab`, `ac`…

```bash
mkdir split_test && cd split_test
split ../longfile.txt
ls                        # xaa xab xac xad xae xaf
wc -l x*                  # každý má max. 1000 řádků

split -l 500 ../longfile.txt cast_      # po 500 řádcích, prefix "cast_"
split -n 3 ../longfile.txt dil_         # na 3 stejně velké části
split -b 10K -d ../longfile.txt blok_   # po 10 KB, číselné sufixy (blok_00, blok_01…)
ls

cat xa* > zpet.txt                      # zpětné složení
cmp zpet.txt ../longfile.txt && echo "Shodne"
cd .. && rm -r split_test
```

## 1.3 `nl` – číslování řádků

```bash
nl newhome.txt
#  1  Thanks for purchasing your new home!!
#  2  **Warning** it may be haunted.
#  ...
nl -b a newhome.txt       # číslovat i prázdné řádky (výchozí je nečíslovat)
nl -s ': ' newhome.txt    # oddělovač za číslem
```

> ⚠️ Ve slidech je překlep `n1` – správně **`nl`** (*number lines*, malé L).

## 1.4 `head` a `tail` – začátek a konec

Výchozí: **10 řádků**. Počet změníš volbou `-n`.

```bash
head alpha.txt            # prvních 10
head -n3 alpha.txt        # první 3
# A is for Apple
# B is for Bear
# C is for Cat
head -3 alpha.txt         # zkrácený zápis

tail alpha.txt            # posledních 10
tail -n3 alpha.txt        # poslední 3
tail -n +5 alpha.txt      # od 5. řádku do konce

head -n 7 alpha.txt | tail -n 3      # řádky 5–7
```

> 💡 `tail -f /var/log/syslog` – sleduje soubor „živě" (nové řádky se průběžně vypisují), ukončíš `Ctrl+C`.

## 1.5 `paste` – spojení souborů vedle sebe

Spojí **odpovídající řádky** více souborů, výchozí oddělovač je **tabulátor**.

```bash
cat numbers.txt           # 1 2 3 4 5 (každé na řádku)
cat letters.txt           # a b c d e
paste numbers.txt letters.txt
# 1       a
# 2       b
# ...
paste -d , numbers.txt letters.txt      # -d: vlastní oddělovač
# 1,a
# 2,b
paste -s numbers.txt                     # -s: všechny řádky souboru do jednoho
# 1       2       3       4       5
```

> Rozdíl: `cat` spojuje soubory **pod sebe**, `paste` **vedle sebe**.

## 1.6 Roura `|` (pipe)

Pošle **výstup** jednoho příkazu jako **vstup** dalšímu. Řetězit lze libovolně mnoho příkazů.

```bash
ls ~ | head -3            # jen první 3 položky
ls /etc | wc -l           # kolik je položek v /etc
cat /etc/passwd | sort | head -5
history | grep ls         # hledání v historii
```

## 1.7 `cut` – vyříznutí sloupců

| Volba | Význam |
|---|---|
| `-d X` | oddělovač polí (výchozí je tabulátor) |
| `-f 1,3` | která **pole** vypsat (`1-3` = rozsah, `3-` = od 3. do konce) |
| `-c 1-5` | které **znaky** vypsat |

Soubor `/etc/passwd` má 7 polí oddělených `:` – `jmeno:heslo:UID:GID:popis:domov:shell`.

```bash
head -1 /etc/passwd
# root:x:0:0:root:/root:/bin/bash

head -1 /etc/passwd | cut -d: -f1,5,6,7
# root:root:/root:/bin/bash

cut -d: -f1 /etc/passwd             # jen jména všech uživatelů
cut -d: -f1,7 /etc/passwd           # jméno + shell
cut -d, -f2 people.csv              # druhý sloupec CSV (příjmení)
cut -c1-3 alpha.txt                 # první 3 znaky každého řádku
```

## 1.8 `sort` – řazení

Bez voleb řadí **abecedně** (podle ASCII / locale).

| Volba | Význam |
|---|---|
| `-r` | obráceně |
| `-n` | **číselně** (jinak by `10` bylo před `9`) |
| `-t X` | oddělovač polí |
| `-k N` | řadit podle **N-tého** pole |
| `-u` | jen unikátní řádky |

```bash
sort people.csv
# Andrew,Tanenbaum
# Dennis,Richie
# Ken,Thompson
# Linus,Torvalds

sort -r people.csv                  # obráceně
sort -t, -k2 people.csv             # podle příjmení (2. pole, oddělovač ,)

printf '10\n9\n100\n' | sort        # 10 100 9   ← abecedně!
printf '10\n9\n100\n' | sort -n     # 9 10 100   ← číselně

sort -t: -k3 -n /etc/passwd | cut -d: -f1,3    # uživatelé seřazení podle UID
```

## 1.9 `uniq` – opakující se řádky

`uniq` odstraní **po sobě jdoucí** duplicitní řádky. Proto se skoro vždy používá **po `sort`**.

| Volba | Význam |
|---|---|
| `-c` | před každý řádek napíše **počet výskytů** |
| `-d` | jen řádky, které se opakují |
| `-u` | jen řádky, které se **ne**opakují |

```bash
printf 'a\na\nb\na\n' | uniq            # a b a   ← poslední a zůstalo (není hned za)
printf 'a\na\nb\na\n' | sort | uniq     # a b

# kolik uživatelů používá který shell
cut -f7 -d: /etc/passwd | sort | uniq -c
#       3 /bin/bash
#       1 /bin/sync
#      23 /usr/sbin/nologin

# seřazeno od nejčastějšího
cut -f7 -d: /etc/passwd | sort | uniq -c | sort -rn
```

> ⚠️ Slidy říkají „odstraní duplicitní řádky" – platí to **jen pro sousední** řádky. Bez `sort` duplicity rozházené po souboru nenajde.

## 1.10 `od` – zobrazení surových dat

`od` (*octal dump*) zobrazí obsah souboru **bajt po bajtu** – osmičkově (výchozí), hexadecimálně, desítkově nebo jako znaky. Hodí se pro odhalení **neviditelných znaků** nebo pro zkoumání poškozených / binárních souborů.

| Volba | Formát |
|---|---|
| (bez voleb) | osmičkově (*octal*) |
| `-x` | hexadecimálně |
| `-d` | desítkově |
| `-c` | jako **znaky** (vč. `\n`, `\r`, `\t`) |

```bash
cat hidden.txt            # vypadá divně / něco chybí
od -x hidden.txt
# 0000000 6854 7369 0d20 7369 0d20 2061 680d 6469 ...
od -c hidden.txt          # nejčitelnější – ukáže i \r (návrat vozíku)
# 0000000   T   h   i   s      \r   i   s      \r       a ...
```

> `\r` (`0d` hexa) je znak **návratu na začátek řádku** – terminál po něm přepíše začátek řádku, proto text „zmizí".
> První sloupec (`0000000`) je **pozice** v souboru (osmičkově).

## 1.11 `tr` – nahrazení znaků

`tr` (*translate*) nahrazuje **jednotlivé znaky** jedné sady znaky druhé sady. Čte **jen ze standardního vstupu** (rourou nebo `<`), jméno souboru jako argument nebere.

```bash
cat alpha-first.txt | tr 'a-z' 'A-Z'    # malá → velká
# A IS FOR ANIMAL
# B IS FOR BEAR
tr 'a-z' 'A-Z' < alpha-first.txt         # totéž bez cat

echo 'ahoj svete' | tr ' ' '_'           # mezery → podtržítka
echo 'a1b2c3' | tr -d '0-9'              # -d: smaže číslice → abc
echo 'aaabbbccc' | tr -s 'a-c'           # -s: sloučí opakované znaky → abc
tr -d '\r' < hidden.txt                  # odstraní \r (oprava "Windows" konců řádků)
```

## 1.12 `sed` – editor proudu (stream editor)

`sed` je **neinteraktivní editor** – upraví text podle zadaného příkazu a výsledek vypíše. Nejčastější použití je **nahrazení**: `s/CO/ČÍM/`.

```bash
sed 's/Animal/Apple/' alpha-first.txt    # nahradí první výskyt na každém řádku
cat alpha-first.txt                      # soubor se NEZMĚNIL – sed jen vypisuje

echo 'aaa' | sed 's/a/X/'                # Xaa  ← jen první výskyt
echo 'aaa' | sed 's/a/X/g'               # XXX  ← g = global, všechny výskyty
echo 'Ahoj' | sed 's/ahoj/Cau/I'         # I = bez ohledu na velikost písmen

sed -n '2,4p' alpha.txt                  # vypíše jen řádky 2–4
sed '3d' alpha.txt                       # vypíše vše kromě 3. řádku
sed '/^$/d' soubor.txt                   # smaže prázdné řádky

cp alpha-first.txt kopie.txt
sed -i 's/Animal/Apple/' kopie.txt       # -i: změní přímo SOUBOR (in-place)
cat kopie.txt
```

> ⚠️ `sed -i` přepisuje soubor bez možnosti vrácení – vyzkoušej nejdřív bez `-i`.

## 1.13 `wc` – počítání

`wc` (*word count*) vypíše počet **řádků, slov a bajtů**.

| Volba | Počítá |
|---|---|
| `-l` | řádky (*lines*) |
| `-w` | slova (*words*) |
| `-c` | bajty |
| `-m` | znaky (u češtiny se liší od bajtů – `č` = 2 bajty) |

```bash
wc alpha-first.txt
#  6 24 90 alpha-first.txt
#  │  │  └─ bajty
#  │  └─ slova
#  └─ řádky

wc -l alpha-first.txt     # 6 alpha-first.txt
wc -w alpha-first.txt     # 24 alpha-first.txt
wc -m alpha-first.txt     # 90 alpha-first.txt
wc -l < alpha-first.txt   # 6   ← jen číslo, bez jména souboru

ls /etc | wc -l           # nejčastější použití – počet řádků výstupu
echo 'čau' | wc -m -c     # 4 5  → 4 znaky, 5 bajtů (č = 2 bajty; počítá se i \n)
```

> Ve slidech je u `–w` a `–m` typografická pomlčka `–` místo `-` – takhle zkopírované to v terminálu **nefunguje**.

---

# 2. Regular Expressions (regulární výrazy)

**Regulární výraz (regex)** je **vzor**, podle kterého příkazy hledají text – např. „řádek začínající na `root`", „slovo z pěti písmen", „číslo".

> ⚠️ **Regex ≠ glob!** Globy (`*`, `?`) rozbaluje **shell** a pracují se **jmény souborů**.
> Regexy zpracovává **příkaz** (`grep`, `sed`…) a pracují s **obsahem** textu. Znaky mají jiný význam:
>
> | | glob | regex |
> |---|---|---|
> | libovolný znak | `?` | `.` |
> | cokoliv | `*` | `.*` |
> | `*` samotná | libovolný řetězec | **předchozí znak** 0× a víckrát |

**Vzory dávej vždy do jednoduchých uvozovek** `'...'` – jinak je může shell rozbalit jako glob dřív, než se dostanou ke `grep`.

Dva typy:

| Typ | Příkazy | Operátory |
|---|---|---|
| **Základní** (*basic regex*, BRE) | `grep`, `sed` | `.` `[ ]` `[^ ]` `*` `^` `$` |
| **Rozšířené** (*extended regex*, ERE) | `grep -E` (= `egrep`), `sed -E` | navíc `+` `?` `{ }` `( )` `\|` |

## 2.1 Základní regulární výrazy

| Operátor | Název | Význam |
|---|---|---|
| `.` | tečka | **jeden libovolný** znak (kromě konce řádku) |
| `[abc]` | seznam | jeden znak **ze seznamu** / rozsahu (`[a-z]`, `[0-9]`) |
| `[^abc]` | negace | jeden znak, který **není** v seznamu |
| `*` | hvězdička | **předchozí** znak **0× nebo víckrát** |
| `^` | přední kotva | vzor musí být na **začátku** řádku |
| `$` | zadní kotva | vzor musí být na **konci** řádku |

### `^` a `$` – kotvy

```bash
grep '^root' /etc/passwd          # řádky ZAČÍNAJÍCÍ na root
# root:x:0:0:root:/root:/bin/bash
grep 'root' /etc/passwd           # root KDEKOLIV na řádku (víc výsledků)

grep 'r$' alpha-first.txt         # řádky KONČÍCÍ na r
# B is for Bear
# F is for Flower

grep 'bash$' /etc/passwd          # uživatelé s shellem bash
grep '^$' newhome.txt             # prázdné řádky
grep -c '^$' newhome.txt          # počet prázdných řádků
```

### `.` – libovolný znak

```bash
cat red.txt
grep 'r..f' red.txt               # r + přesně 2 libovolné znaky + f
# reef
# roof
grep 'r.d' red.txt                # red, rod…
grep '^...$' red.txt              # řádky dlouhé přesně 3 znaky
```

### `[ ]` – znak ze seznamu

```bash
grep '[0-9]' profile.txt          # řádky obsahující číslici
# I am 37 years old.
# 3121991
# I have 2 dogs.
# 123456789101112
grep '[^0-9]' profile.txt         # řádky obsahující aspoň jeden NEčíselný znak
grep '^[0-9]*$' profile.txt       # řádky složené JEN z číslic
grep '^[A-E]' alpha.txt           # začínající na A–E
grep '[aeiou][aeiou]' red.txt     # dvě samohlásky za sebou
```

> Ve slidech je `grep [0-9]` bez uvozovek – funguje to jen náhodou (pokud v adresáři není soubor pojmenovaný číslicí). Vždy piš `'[0-9]'`.

### `*` – předchozí znak 0× nebo víckrát

```bash
grep 'ee*' red.txt                # e + 0 a více dalších e = aspoň jedno e
# red
# reef
# reeed
grep 're*d' red.txt               # r, 0+ e, d → rd, red, reed, reeed…
grep 'r.*d' red.txt               # .* = cokoliv → r a později d
```

> ⚠️ Pozor: `grep 'e*'` najde **každý řádek** – „nula výskytů e" je na každém řádku.

## 2.2 Rozšířené regulární výrazy

Používají se s **`grep -E`** (nebo starším `egrep`).

| Operátor | Význam |
|---|---|
| `( )` | **seskupení** – z více znaků udělá jeden celek |
| `+` | předchozí znak / skupina **1× nebo víckrát** |
| `*` | předchozí znak / skupina **0× nebo víckrát** |
| `?` | předchozí znak / skupina **0× nebo 1×** (je nepovinný) |
| `{n,m}` | předchozí znak / skupina **n až m×** |
| `\|` | **NEBO** (alternativa) |

> ⚠️ Ve slidech je u `+` napsáno „zero or more" – správně **„one or more"** (1× a víc).

### `( )` – seskupení

Hodí se, když chceš `*`, `+`, `?` nebo `{ }` použít na **víc než jeden znak**:

```bash
echo 'Miss Mister Mississippi Missed Mismatched' | grep -oE 'M(iss)+'
# Miss  Mississ  Miss               ← -o vypíše jen nalezené části (každou na řádek);
#                                     Mister a Mismatched neobsahují "iss"
echo 'Miss Mister Mississippi Missed Mismatched' | grep -oE 'M(iss)*'
# Miss  M  Mississ  Miss  M         ← * dovolí i 0 opakování → samotné M
```

> Ukázka ve slidech (`grep -E 'M(iss)*'` bez `-o`) vypíše celý řádek, takže rozdíl není vidět. S `-o` je vidět, co přesně se našlo.

### `+` – jednou a víckrát

| Vzor | Význam |
|---|---|
| `xyz+` | `xy` následované **jedním nebo více** `z` (`xyz`, `xyzz`…) |
| `(xyz)+` | **jedna nebo více kopií** řetězce `xyz` (`xyz`, `xyzxyz`…) |

```bash
grep -E 'e+' red.txt              # aspoň jedno e (jako 'ee*' v základních)
grep -E 'ee+' red.txt             # aspoň dvě e za sebou
grep -E '[0-9]+' profile.txt      # aspoň jedna číslice
```

### `?` – nepovinný znak

| Vzor | Význam |
|---|---|
| `xyz?` | `xy` následované **žádným nebo jedním** `z` (`xy`, `xyz`) |
| `x(yz)?` | `x` následované **žádným nebo jedním** `yz` (`x`, `xyz`) |

```bash
echo -e 'color\ncolour\ncolouur' | grep -E '^colou?r$'
# color
# colour
```

### `{ }` – přesný počet opakování

| Vzor | Význam |
|---|---|
| `a{3}` | **přesně** 3× `a` |
| `a{2,}` | **2× a víc** |
| `a{0,}` | 0× a víc (= `a*`) |
| `a{0,1}` | 0× nebo 1× (= `a?`) |
| `a{,5}` | **nejvýš** 5× |
| `a{2,4}` | 2× až 4× |

```bash
grep -E 'r{1,}' animals.txt       # r jednou a víckrát (= 'r+')
# 1 retriever
# 2 badger
grep -E 'e{2}' red.txt            # přesně dvě e za sebou (reef, reeed – i ty mají ee)
grep -E '^[0-9]{7}$' profile.txt  # řádek z přesně 7 číslic → 3121991
```

### `|` – NEBO

| Vzor | Význam |
|---|---|
| `abc\|xyz` | řetězec `abc` **nebo** `xyz` |
| `ab(c\|d\|e)` | `ab` následované `c` **nebo** `d` **nebo** `e` |
| `ab[cde]` | totéž (pro jednotlivé znaky je `[ ]` jednodušší) |

```bash
grep -E 'root|sysadmin' /etc/passwd
grep -E 'bat|wolf' animals.txt
grep -E '^(A|B|C) ' alpha.txt
```

## 2.3 Sekvence se zpětným lomítkem

| Sekvence | Význam |
|---|---|
| `\b` | **hranice slova** (začátek nebo konec slova) |
| `\B` | **není** hranice slova |
| `\w` | znak slova (písmeno, číslice, `_`) |
| `\s` | bílý znak (mezera, tabulátor) |

```bash
echo 'This is useful' | sed 's/is/was/'
# Thwas is useful          ← nahradilo "is" uvnitř slova This
echo 'This is useful' | sed 's/\bis\b/was/'
# This was useful          ← jen samostatné slovo "is"
echo 'This is useful' | sed 's/\Bis/X/'
# ThX is useful            ← jen "is", které NEZAČÍNÁ slovo
```

## 2.4 Escapování – hledání doslovného znaku

Když chci najít znak, který má v regexu speciální význam (`.`, `*`, `[`, `$`, `^`…), musím před něj dát **`\`**:

```bash
grep 're*' newhome.txt        # r + 0 a více e → najde skoro vše
grep 're\*' newhome.txt       # doslova "re*"
# **Beware** of the ghost in the bedroom.

grep '\.' alpha.txt           # řádky obsahující tečku
grep '!!' newhome.txt         # ! není v regexu speciální
grep '\$' soubor.txt          # doslovný dolar
grep -F '**' newhome.txt      # -F: celý vzor brát doslova (žádný regex)
```

## 2.5 Volby příkazu `grep`

| Volba | Význam |
|---|---|
| `-i` | **bez ohledu na velikost písmen** |
| `-v` | **inverze** – řádky, které vzor **neobsahují** |
| `-l` | vypíše jen **jména souborů**, ve kterých je shoda |
| `-r` | **rekurzivně** i v podadresářích |
| `-w` | jen **celá slova** |
| `-q` | **tiše** – nic nevypíše, jen návratový kód (pro skripty) |
| `-c` | jen **počet** odpovídajících řádků |
| `-n` | s **čísly řádků** |
| `-o` | vypíše jen **nalezenou část**, ne celý řádek |
| `-E` | rozšířené regexy |

```bash
grep -i 'linux' linux.txt
grep -v 'nologin' /etc/passwd       # uživatelé, kteří SE mohou přihlásit
grep -w 'is' alpha-first.txt        # jen samostatné slovo "is" (ne "This")
grep -c 'bash' /etc/passwd          # kolik řádků obsahuje bash
grep -n 'Warning' newhome.txt       # s číslem řádku
grep -l 'Linux' *                   # ve kterých souborech je "Linux"
grep -r 'Linux' ~/cv04              # rekurzivně
grep -q 'root' /etc/passwd && echo "root existuje"
```

## 2.6 Prohledání více souborů

S globem prohledá `grep` více souborů najednou a u každého výsledku uvede **jméno souboru**:

```bash
grep 'Linux' ./*
# grep: ./School: Is a directory
# grep: ./Work: Is a directory
# ./linux.txt:Linux is growing !

grep 'Linux' ./* 2>/dev/null        # bez chybových hlášek o adresářích
grep -r 'Linux' .                   # rekurzivně, adresáře projde
grep -h 'Linux' ./*  2>/dev/null    # -h: bez jmen souborů
```

> 🌐 Na procvičení: [regexone.com](https://regexone.com) (interaktivní lekce), [regex101.com](https://regex101.com) (testování a vysvětlení vzoru).

---

# 3. The vi Editor

**vi** (dnes většinou **vim** = *vi improved*) je **standardní textový editor** na Linuxu a Unixu.

Proč ho umět:
- je to **ASCII textový editor** – ideální na konfigurační soubory a skripty,
- je **dostupný ve všech distribucích** (i na minimálních serverech, kde nic jiného není),
- běží v **terminálu** (přes SSH) i v GUI,
- přidávají se nové funkce, ale **základ je pořád stejný**.

```bash
vi soubor.txt             # otevře (nebo vytvoří) soubor
vimtutor                  # interaktivní výuka vim (~30 min) – pokud je nainstalovaný
```

## 3.1 Tři režimy

```
                   i, a, o, I, A, O
      ┌──────────────────────────────────────┐
      │                                      ▼
┌───────────────┐                   ┌────────────────┐
│ PŘÍKAZOVÝ     │       Esc         │ VKLÁDACÍ       │
│ (command)     │ ◄──────────────── │ (insert)       │
│ pohyb, mazání,│                   │ psaní textu    │
│ kopírování    │                   └────────────────┘
└───────────────┘
   │        ▲
 : │        │ Enter / Esc
   ▼        │
┌───────────────┐
│ EX režim      │
│ :w :q :q! …   │
│ uložit, konec │
└───────────────┘
```

| Režim | K čemu | Jak se do něj dostanu |
|---|---|---|
| **Příkazový** (*command*) | pohyb kurzoru, mazání, kopírování, vkládání | **výchozí** po spuštění; z ostatních přes **`Esc`** |
| **Vkládací** (*insert*) | **psaní textu** | `i`, `a`, `o`… (dole se ukáže `-- INSERT --`) |
| **Ex** | uložení, ukončení, hledání, nastavení | **`:`** z příkazového režimu (kurzor skočí dolů) |

> 💡 Když nevíš, kde jsi: zmáčkni **`Esc`** (klidně víckrát) → jsi v příkazovém režimu.

## 3.2 Pohyb kurzoru (příkazový režim)

| Klávesa | Pohyb |
|---|---|
| `h` | vlevo o znak |
| `j` | dolů o řádek |
| `k` | nahoru o řádek |
| `l` | vpravo o znak |
| `w` | o slovo vpřed |
| `b` | o slovo zpět |
| `^` (nebo `0`) | začátek řádku |
| `$` | konec řádku |
| `gg` / `G` | začátek / konec souboru |
| `5G` | na 5. řádek |

> Šipky fungují taky, ale `hjkl` máš pod prsty a nemusíš sahat mimo klávesnici.

**Číselná předvolba:** před pohyb nebo příkaz můžu napsat **číslo** = kolikrát se má provést.
`5j` = 5 řádků dolů, `3w` = 3 slova vpřed.

## 3.3 Editace textu (příkazový režim)

| Klávesa | Akce |
|---|---|
| `x` | smaže znak pod kurzorem |
| `dd` | **smaže (vyjme) řádek** |
| `3dd` | smaže 3 řádky |
| `dw` | smaže slovo |
| `d3w` | smaže 3 slova |
| `d4h` | smaže 4 znaky vlevo |
| `d$` (nebo `D`) | smaže do konce řádku |
| `cc` | **změní řádek** – smaže ho a přepne do vkládacího režimu |
| `cw` | změní slovo |
| `yy` | **zkopíruje** (*yank*) řádek |
| `3yy` | zkopíruje 3 řádky |
| `p` / `P` | **vloží** (*put*) za / před kurzor |
| `u` | **zpět** (*undo*) |
| `Ctrl+R` | znovu (*redo*) |
| `.` | zopakuje poslední změnu |

> Logika: **příkaz + pohyb** → `d` (delete) + `w` (word) = `dw`; `d` + `$` (konec řádku) = `d$`.
> Smazané (`d`) se ukládá do schránky – `dd` + `p` = **přesun řádku**.

## 3.4 Vkládací režim

| Klávesa | Kde začnu psát |
|---|---|
| `i` | **před** kurzorem |
| `a` | **za** kurzorem |
| `I` | na **začátku** řádku |
| `A` | na **konci** řádku |
| `o` | na **novém řádku pod** kurzorem |
| `O` | na **novém řádku nad** kurzorem |

Z vkládacího režimu zpět: **`Esc`**.

## 3.5 Ex režim – ukládání a ukončení

| Příkaz | Význam |
|---|---|
| `:w` | **uložit** |
| `:w soubor` | uložit **kopii** pod jiným jménem |
| `:w!` | vynutit uložení (např. u souboru jen pro čtení) |
| `:q` | **ukončit** (jen když nejsou neuložené změny) |
| `:q!` | **ukončit BEZ uložení** (zahodit změny) |
| `:wq` nebo `:x` | **uložit a ukončit** |
| `:1` | skok na 1. řádek (nebo na zadané číslo) |
| `:e soubor` | otevřít jiný soubor |
| `:set number` | zobrazit čísla řádků (`:set nonumber` vypne) |
| `:%s/stary/novy/g` | nahradit v celém souboru (stejně jako `sed`) |

Navíc v **příkazovém** režimu (bez dvojtečky):

| Klávesa | Význam |
|---|---|
| `ZZ` | uložit a ukončit (= `:wq`) |
| `ZQ` | ukončit bez uložení (= `:q!`) |
| `/text` | **hledat** vpřed, `n` = další, `N` = předchozí |
| `?text` | hledat vzad |

> ⚠️ Slidy uvádí „v režimu ex existuje příkaz `zz`" – správně je to **`ZZ` (velká písmena) v příkazovém režimu**, bez dvojtečky.
> Malé `zz` dělá něco jiného – posune obrazovku tak, aby byl kurzor uprostřed.

## 3.6 Vyzkoušej si

```bash
cd ~/cv04
cp newhome.txt vi_test.txt
vi vi_test.txt
```

1. `:set number` → zobraz čísla řádků.
2. `3G` → skoč na 3. řádek, `dd` → smaž ho, `u` → vrať zpět.
3. `gg` → začátek, `yy` → zkopíruj 1. řádek, `G` → konec, `p` → vlož ho na konec.
4. `A` → piš na konec řádku ` (kopie)`, `Esc`.
5. `o` → nový řádek pod, napiš `Novy radek`, `Esc`.
6. `/ghost` → najdi slovo ghost, `n` → další výskyt.
7. `:%s/Warning/POZOR/g` → nahraď všechny výskyty.
8. `:w vi_zaloha.txt` → ulož kopii.
9. `:wq` → ulož a ukonči.

```bash
cat vi_test.txt
cat vi_zaloha.txt
```

---

# 4. Standard Text Streams and Redirection

Každý program má **tři standardní datové proudy**:

| Proud | Zkratka | Číslo (*file descriptor*) | Výchozí cíl |
|---|---|---|---|
| **standardní vstup** | `stdin` | **0** | klávesnice |
| **standardní výstup** | `stdout` | **1** | terminál |
| **standardní chybový výstup** | `stderr` | **2** | terminál |

```
              ┌────────────┐ ── 1 stdout ──► terminál / soubor (>)
klávesnice ──►│  PŘÍKAZ    │
/ soubor (<)  │            │ ── 2 stderr ──► terminál / soubor (2>)
   0 stdin    └────────────┘
```

**Přesměrování** (*redirection*) = poslat proud jinam než na výchozí místo – do souboru, z souboru nebo do jiného příkazu.

Příkazy, které čtou text, upraví ho a vypíšou (`sort`, `tr`, `grep`, `cut`…), se nazývají **filtry**.

Formy přesměrování:

| Forma | Operátor |
|---|---|
| **Roura** (*pipeline*) | `\|` |
| Přesměrování **standardního výstupu** | `>`, `>>` |
| Přesměrování **chybového výstupu** | `2>`, `2>>` |
| Přesměrování **standardního vstupu** | `<` |

## 4.1 Standardní výstup – `>` a `>>`

```bash
cd ~
ls ~ > /tmp/home.txt      # výstup do souboru místo na obrazovku
cat /tmp/home.txt
# Desktop
# Documents
# ...

date > /tmp/datum.txt     # > soubor VYTVOŘÍ nebo PŘEPÍŠE
date > /tmp/datum.txt
cat /tmp/datum.txt        # jen jeden řádek

date >> /tmp/datum.txt    # >> PŘIPOJÍ na konec (nebo vytvoří)
date >> /tmp/datum.txt
cat /tmp/datum.txt        # tři řádky
```

| Zápis | Význam |
|---|---|
| `PRIKAZ > SOUBOR` (= `1>`) | vytvoří nebo **přepíše** soubor standardním výstupem |
| `PRIKAZ >> SOUBOR` (= `1>>`) | vytvoří nebo **připojí** na konec souboru |

> ⚠️ `>` přepíše soubor **bez varování**. Navíc `sort soubor > soubor` soubor **vyprázdní** –
> shell ho vymaže dřív, než ho `sort` stihne přečíst. Výstup vždy směřuj do **jiného** souboru.

## 4.2 Chybový výstup – `2>`

Chybové hlášky jdou do **samostatného proudu** (číslo **2**), takže je `>` nezachytí:

```bash
ls /junk
# ls: cannot access '/junk': No such file or directory

ls /junk > /tmp/vystup.txt        # chyba se pořád vypíše na obrazovku!
cat /tmp/vystup.txt               # prázdné

ls /junk 2> /tmp/ls.err           # chyba jde do souboru, na obrazovce nic
cat /tmp/ls.err

find / -name 'passwd' 2> /dev/null      # /dev/null = "černá díra" – chyby zahodí
```

### Výstup i chyby najednou

```bash
ls /etc/hosts /junk                     # 1 výsledek + 1 chyba

ls /etc/hosts /junk > ok.txt 2> err.txt # každý proud do jiného souboru
cat ok.txt                              # /etc/hosts
cat err.txt                             # ls: cannot access '/junk'...

ls /etc/hosts /junk &> vse.txt          # oba proudy do JEDNOHO souboru
ls /etc/hosts /junk > vse.txt 2>&1      # totéž, klasický zápis
ls /etc/hosts /junk &>> vse.txt         # oba proudy připojit
ls /etc/hosts /junk >> vse.txt 2>&1     # totéž
cat vse.txt
```

| Zápis | Význam |
|---|---|
| `PRIKAZ &> SOUBOR` = `PRIKAZ > SOUBOR 2>&1` | stdout **i** stderr do souboru (přepsat) |
| `PRIKAZ &>> SOUBOR` = `PRIKAZ >> SOUBOR 2>&1` | stdout **i** stderr do souboru (připojit) |

> `2>&1` = „pošli proud **2** tam, kam právě vede proud **1**". Proto záleží na pořadí:
> `> soubor 2>&1` ✅ (oba do souboru), ale `2>&1 > soubor` ❌ (chyby na obrazovku – 1 v tu chvíli vedla ještě na terminál).

## 4.3 Standardní vstup – `<`

Některé příkazy (např. `tr`) čtou **jen ze standardního vstupu**. Přesměrováním `<` jim podám soubor:

```bash
tr 'a-z' 'A-Z' < Documents/animals.txt
# 1 RETRIEVER
# 2 BADGER
# ...

tr 'a-z' 'A-Z' < Documents/animals.txt > /tmp/ANIMALS.txt   # vstup i výstup najednou
wc -l < /etc/passwd                                          # jen číslo bez jména souboru
```

## 4.4 Roury (pipelines) – `|`

Výstup jednoho příkazu → vstup dalšího. Tak se z malých nástrojů skládají složitější operace:

```bash
history | grep "ls"
#    1  ls ~ > /tmp/home.txt
#    5  ls 1> /tmp/ls.txt

# 5 nejčastějších shellů uživatelů
cut -d: -f7 /etc/passwd | sort | uniq -c | sort -rn | head -5

# kolik souborů v /etc končí na .conf
ls /etc | grep '\.conf$' | wc -l

# všechna slova z newhome.txt, malými písmeny, seřazená a unikátní
tr -s ' ' '\n' < Documents/newhome.txt | tr 'A-Z' 'a-z' | sort -u
```

> Roura přenáší jen **stdout**. Chyby (stderr) jdou dál na obrazovku – pokud je chceš poslat taky: `prikaz 2>&1 | grep ...` (nebo `|&`).

## 4.5 `tee` – výstup do souboru **i** na obrazovku

`tee` (jako T-kus na potrubí) **zduplikuje** proud – pošle ho do souboru a zároveň dál na výstup.

```bash
date | tee timer.txt
# Thu Oct 22 10:21:24 UTC 2026        ← vidím na obrazovce
cat timer.txt
# Thu Oct 22 10:21:24 UTC 2026        ← a je i v souboru

date | tee -a timer.txt               # -a: připojit, nepřepsat
cat timer.txt                         # dva řádky

ls /etc | tee seznam.txt | wc -l      # uloží seznam a zároveň spočítá řádky
```

> 💡 Častý trik: zápis do souboru, kam nemám práva – `echo text | sudo tee /etc/soubor`
> (`sudo echo text > /etc/soubor` nefunguje, protože přesměrování dělá shell **bez** sudo).

## 4.6 `xargs` – ze vstupu udělá argumenty

Některé příkazy **nečtou standardní vstup**, ale potřebují **argumenty** (`touch`, `rm`, `mkdir`…). `xargs` přečte vstup a předá ho příkazu **jako argumenty**.

```bash
cd ~
echo '1a 1b 1c 1d' | xargs touch      # = touch 1a 1b 1c 1d
ls
# 1a  1b  1c  1d  Desktop  Documents ...

echo '1a 1b 1c 1d' | xargs            # bez příkazu → výchozí je echo
echo '1a 1b 1c 1d' | xargs -n 1       # -n 1: po jednom argumentu na příkaz
ls 1? | xargs rm                      # smaže 1a 1b 1c 1d

find ~/cv04 -name '*.csv' | xargs wc -l   # počet řádků všech .csv
find ~/cv04 -name 'x*' | xargs -p rm      # -p: zeptá se před spuštěním
```

> Rozdíl: `echo soubor | rm` **nefunguje** (`rm` nečte vstup), `echo soubor | xargs rm` ✅.

---

# Úlohy k procvičení

Před začátkem: `cp -r ~/Documents ~/cv04 && cd ~/cv04` (pokud jsi to ještě neudělal).

### 1. Text Utilities

1. Spoj `alpha-first.txt` a `alpha-second.txt` do souboru `alpha-spojene.txt` a očísluj jeho řádky.
2. Rozděl `longfile.txt` na soubory po 2000 řádcích s prefixem `dil_`. Kolik souborů vzniklo?
3. Vypiš 3. až 5. řádek souboru `alpha.txt`.
4. Spoj `numbers.txt` a `letters.txt` vedle sebe s oddělovačem `-`.
5. Vypiš z `/etc/passwd` jen jména uživatelů a jejich domovské adresáře (pole 1 a 6).
6. Seřaď `people.csv` podle příjmení **obráceně**.
7. Zjisti, kolik uživatelů používá který shell, seřazeno od nejčastějšího.
8. Proč se `hidden.txt` vypisuje divně? Zjisti to přes `od` a oprav ho do souboru `opraveny.txt`.
9. Vypiš `animals.txt` velkými písmeny.
10. Vypiš `alpha-first.txt` tak, aby se všechna slova `is` změnila na `was`.
11. Kolik řádků, slov a znaků má `newhome.txt`?

### 2. Regular Expressions

12. Najdi v `/etc/passwd` řádky, které **začínají** na `s`.
13. Najdi v `/etc/passwd` uživatele, jejichž shell **končí** na `nologin`, a spočítej je.
14. Najdi v `red.txt` slova, která mají přesně 4 znaky.
15. Najdi v `profile.txt` řádky, které obsahují **jen** číslice.
16. Najdi v `alpha.txt` řádky, které **ne**obsahují písmeno `e` (bez ohledu na velikost).
17. Pomocí `grep -E` najdi v `animals.txt` řádky obsahující `bat` **nebo** `wolf`.
18. Najdi v `red.txt` řádky, kde jsou aspoň dvě `e` za sebou (zkus základní i rozšířený regex).
19. Najdi v `newhome.txt` řádky obsahující doslovné `**`.
20. Vypiš jména souborů v `~/cv04`, které obsahují slovo `Linux` (bez ohledu na velikost písmen).

### 3. vi Editor

21. Otevři `vi_test.txt` (kopie `newhome.txt`), smaž první dva řádky, na konec přidej řádek `Konec souboru`, ulož a ukonči.
22. Otevři ho znovu, nahraď všechna `the` za `THE`, ale **neukládej** – ukonči bez uložení. Ověř přes `cat`, že se nic nezměnilo.

### 4. Streams and Redirection

23. Ulož výpis `/etc` do `~/etc_seznam.txt` a pak k němu **připoj** výpis `/var`.
24. Spusť `ls /etc /neexistuje` tak, aby výsledek šel do `ok.txt` a chyba do `chyba.txt`.
25. Spusť stejný příkaz tak, aby výstup i chyby šly do jednoho souboru `vse.txt`.
26. Najdi v celém systému soubory `*.conf` bez chybových hlášek a ulož je do `conf.txt`.
27. Převeď `letters.txt` na velká písmena pomocí přesměrování vstupu (`<`) a výsledek ulož do `LETTERS.txt`.
28. Vypiš datum na obrazovku a zároveň ho připoj do `log.txt`. Zopakuj 3×.
29. Pomocí `echo` a `xargs` vytvoř adresáře `pondeli`, `utery`, `streda`.

<details>
<summary>Řešení</summary>

```bash
cd ~/cv04

# 1
cat alpha-first.txt alpha-second.txt > alpha-spojene.txt
nl alpha-spojene.txt

# 2
split -l 2000 longfile.txt dil_
ls dil_* | wc -l

# 3
head -n 5 alpha.txt | tail -n 3      # nebo: sed -n '3,5p' alpha.txt

# 4
paste -d - numbers.txt letters.txt

# 5
cut -d: -f1,6 /etc/passwd

# 6
sort -t, -k2 -r people.csv

# 7
cut -d: -f7 /etc/passwd | sort | uniq -c | sort -rn

# 8
od -c hidden.txt                     # obsahuje \r – terminál po něm přepisuje začátek řádku
tr -d '\r' < hidden.txt > opraveny.txt
cat opraveny.txt

# 9
tr 'a-z' 'A-Z' < animals.txt

# 10
sed 's/\bis\b/was/g' alpha-first.txt

# 11
wc newhome.txt                       # řádky slova bajty;  wc -m pro znaky

# 12
grep '^s' /etc/passwd

# 13
grep 'nologin$' /etc/passwd
grep -c 'nologin$' /etc/passwd

# 14
grep '^....$' red.txt                # nebo: grep -E '^.{4}$' red.txt

# 15
grep '^[0-9]*$' profile.txt          # nebo: grep -E '^[0-9]+$' profile.txt

# 16
grep -vi 'e' alpha.txt

# 17
grep -E 'bat|wolf' animals.txt

# 18
grep 'eee*' red.txt
grep -E 'e{2,}' red.txt

# 19
grep '\*\*' newhome.txt              # nebo: grep -F '**' newhome.txt

# 20
grep -ril 'linux' ~/cv04

# 21
cp newhome.txt vi_test.txt
vi vi_test.txt
#   gg  2dd  G  o  Konec souboru  Esc  :wq

# 22
vi vi_test.txt
#   :%s/the/THE/g   :q!
cat vi_test.txt

# 23
ls /etc > ~/etc_seznam.txt
ls /var >> ~/etc_seznam.txt

# 24
ls /etc /neexistuje > ok.txt 2> chyba.txt

# 25
ls /etc /neexistuje &> vse.txt       # nebo: > vse.txt 2>&1

# 26
find / -name '*.conf' 2> /dev/null > conf.txt

# 27
tr 'a-z' 'A-Z' < letters.txt > LETTERS.txt

# 28
date | tee -a log.txt
date | tee -a log.txt
date | tee -a log.txt
cat log.txt

# 29
echo 'pondeli utery streda' | xargs mkdir
ls -d pondeli utery streda
```
</details>

---

# Tahák

### Text Utilities

| Potřebuju… | Příkaz |
|---|---|
| vypsat / spojit soubory pod sebe | `cat a b > c` |
| spojit soubory vedle sebe | `paste -d , a b` |
| rozdělit soubor | `split -l 1000 soubor prefix_` |
| očíslovat řádky | `nl soubor`, `cat -n soubor` |
| prvních / posledních N řádků | `head -n N`, `tail -n N` |
| sledovat log živě | `tail -f soubor` |
| vyříznout sloupce | `cut -d: -f1,3` |
| seřadit (číselně, podle pole) | `sort -n`, `sort -t, -k2` |
| unikátní řádky / počet výskytů | `sort \| uniq`, `sort \| uniq -c` |
| neviditelné znaky | `od -c soubor`, `cat -A soubor` |
| velká písmena / smazat znaky | `tr 'a-z' 'A-Z'`, `tr -d '\r'` |
| nahradit text | `sed 's/stary/novy/g'` (`-i` = v souboru) |
| spočítat řádky / slova | `wc -l`, `wc -w` |

### Regulární výrazy

| Chci… | Vzor |
|---|---|
| jeden libovolný znak | `.` |
| cokoliv | `.*` |
| znak ze sady / mimo sadu | `[a-z]`, `[^0-9]` |
| začátek / konec řádku | `^vzor`, `vzor$` |
| prázdný řádek | `^$` |
| 0× a víc / 1× a víc / 0–1× | `*`, `+` (`-E`), `?` (`-E`) |
| přesně / rozsah opakování | `{3}`, `{2,4}` (`-E`) |
| nebo | `a\|b` (`-E`) |
| celé slovo | `\bslovo\b`, `grep -w` |
| doslovný speciální znak | `\.`, `\*`, `\$` |
| **grep:** bez velikosti / inverze / počet / číslo řádku | `-i`, `-v`, `-c`, `-n` |
| **grep:** jen jména souborů / rekurzivně / jen nález | `-l`, `-r`, `-o` |

### vi

| Chci… | Klávesy |
|---|---|
| začít psát | `i` (před), `a` (za), `o` (nový řádek) |
| zpět do příkazového režimu | `Esc` |
| pohyb | `h j k l`, `w b`, `^ $`, `gg G`, `5G` |
| smazat znak / slovo / řádek | `x`, `dw`, `dd` |
| kopírovat / vložit | `yy`, `p` |
| zpět / znovu | `u`, `Ctrl+R` |
| hledat | `/text`, `n`, `N` |
| nahradit v celém souboru | `:%s/stary/novy/g` |
| uložit / ukončit / obojí | `:w`, `:q`, `:wq` (`ZZ`) |
| ukončit bez uložení | `:q!` |

### Přesměrování

| Chci… | Zápis |
|---|---|
| výstup do souboru (přepsat / připojit) | `> soubor`, `>> soubor` |
| chyby do souboru | `2> soubor` |
| zahodit chyby | `2> /dev/null` |
| výstup i chyby do souboru | `&> soubor` nebo `> soubor 2>&1` |
| vstup ze souboru | `< soubor` |
| výstup jako vstup dalšího příkazu | `prikaz1 \| prikaz2` |
| do souboru i na obrazovku | `\| tee soubor` (`-a` = připojit) |
| vstup jako argumenty | `\| xargs prikaz` |

---

# Příprava na cvičení 05

Samostudium, splněné laby a testy z modulu:

- **Linux Essentials – Module 11 – Basic Scripting**
