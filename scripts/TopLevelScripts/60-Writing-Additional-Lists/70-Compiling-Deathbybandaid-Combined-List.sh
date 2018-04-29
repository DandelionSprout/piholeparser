#!/bin/bash
## This creates my custom biglist

## Variables
SCRIPTDIRA=$(dirname $0)
source "$SCRIPTDIRA"/foldervars.var

DOMAINTOLOOKFOR="bigzipfiles.facebook.com"

WHATITIS="All Parsed List (edited)"
timestamp=$(echo `date`)
if
[[ -f $COMBINEDBLACKLISTSDBB ]]
then
rm $COMBINEDBLACKLISTSDBB
echo "* $WHATITIS Removed. $timestamp" | tee --append $RECENTRUN &>/dev/null
else
echo "* $WHATITIS Not Removed. $timestamp" | tee --append $RECENTRUN &>/dev/null
fi

if
[[ ! -f $BLACKLISTTEMP ]]
then
printf "$red"  "Blacklist File Missing."
MISSINGBLACK=true
fi
if
[[ ! -f $WHITELISTTEMP ]]
then
printf "$red"  "Whitelist File Missing."
MISSINGWHITE=true
fi
if
[[ ! -f $COMBINEDBLACKLISTS ]]
then
printf "$red"  "Big List File Missing."
touch $COMBINEDBLACKLISTS
fi

printf "$cyan"  "Generating All Parsed List (edited)."
echo ""

## Add Blacklist Domains
if
[[ -z $MISSINGBLACK ]]
then
printf "$yellow"  "Adding Blacklist Domains."
cat $BLACKLISTTEMP $COMBINEDBLACKLISTS >> $FILETEMP
echo -e "`wc -l $FILETEMP | cut -d " " -f 1` lines after blacklist"
echo ""
else
cp $COMBINEDBLACKLISTS $FILETEMP
fi

## Dedupe
printf "$yellow"  "Removing Duplicate Blacklist Entries."
cat -s $FILETEMP | sort -u | gawk '{if (++dup[$0] == 1) print $0;}' >> $TEMPFILE
echo -e "`wc -l $TEMPFILE | cut -d " " -f 1` lines after deduping"
rm $FILETEMP
echo ""

if 
grep -q $DOMAINTOLOOKFOR "$WHITELISTTEMP"
then
echo "$DOMAINTOLOOKFOR in whitelist"
fi

## Remove Whitelist Domains
if
[[ -z $MISSINGWHITE ]]
then
printf "$yellow"  "Removing whitelist Domains."
gawk 'NR==FNR{a[$0];next} !($0 in a)' $WHITELISTTEMP $TEMPFILE >> $FILETEMP
rm $TEMPFILE
comm -23 $FILETEMP <(sort $WHITELISTTEMP) > $TEMPFILE
rm $FILETEMP
grep -Fvxf $WHITELISTTEMP $TEMPFILE >> $FILETEMP
rm $TEMPFILE
echo -e "`wc -l $FILETEMP | cut -d " " -f 1` lines after whitelist"
echo ""
fi

if 
grep -q $DOMAINTOLOOKFOR "$FILETEMP"
then
echo "$DOMAINTOLOOKFOR in dbblist"
fi

if
[[ -f $FILETEMP ]]
then
EDITEDALLPARSEDSIZEBYTES=$(stat -c%s "$FILETEMP")
EDITEDALLPARSEDSIZEKB=`expr $EDITEDALLPARSEDSIZEBYTES / 1024`
EDITEDALLPARSEDSIZEMB=`expr $EDITEDALLPARSEDSIZEBYTES / 1024 / 1024`
echo "EDITEDALLPARSEDSIZEMB="$EDITEDALLPARSEDSIZEMB"" | tee --append $TEMPVARS &>/dev/null
fi

if
[[ "$EDITEDALLPARSEDSIZEMB" -gt 0 && "$EDITEDALLPARSEDSIZEKB" -gt 0 && "$EDITEDALLPARSEDSIZEBYTES" -gt 0 ]]
then
printf "$yellow"  "Size of $BASEFILENAME = $EDITEDALLPARSEDSIZEMB MB."
elif
[[ "$EDITEDALLPARSEDSIZEMB" -eq 0 && "$EDITEDALLPARSEDSIZEKB" -gt 0 && "$EDITEDALLPARSEDSIZEBYTES" -gt 0 ]]
then
printf "$yellow"  "Size of $BASEFILENAME = $EDITEDALLPARSEDSIZEKB KB."
elif
[[ "$EDITEDALLPARSEDSIZEMB" -eq 0 && "$EDITEDALLPARSEDSIZEKB" -eq 0 && "$EDITEDALLPARSEDSIZEBYTES" -gt 0 ]]
then
printf "$yellow"  "Size of List = $EDITEDALLPARSEDSIZEBYTES Bytes."
fi

if
[[ "$EDITEDALLPARSEDSIZEBYTES" -gt 0 ]]
then
EDITEDALLPARSEDHOWMANYLINES=$(echo -e "`wc -l $FILETEMP | cut -d " " -f 1`")
printf "$yellow"  "$EDITEDALLPARSEDHOWMANYLINES Lines After Compiling."
echo "EDITEDALLPARSEDHOWMANYLINES="$EDITEDALLPARSEDHOWMANYLINES"" | tee --append $TEMPVARS &>/dev/null
fi

if
[[ -f $COMBINEDBLACKLISTSDBB && "$EDITEDALLPARSEDSIZEBYTES" -gt 0 ]]
then
printf "$green"  "Old COMBINEDBLACKLISTSDBB File Removed."
rm $COMBINEDBLACKLISTSDBB
fi

## Github has a 100mb limit, and empty files are useless
if 
[[ "$EDITEDALLPARSEDSIZEBYTES" -eq 0 ]]
then
printf "$red"     "File Empty"
echo "* Allparsedlist list was an empty file $timestamp" | tee --append $RECENTRUN &>/dev/null
mv $FILETEMP $COMBINEDBLACKLISTSDBB
elif
[[ "$EDITEDALLPARSEDSIZEMB" -ge "$GITHUBLIMITMB" ]]
then
printf "$red"     "Parsed File Too Large For Github. Deleting."
rm $FILETEMP
touch $COMBINEDBLACKLISTSDBB
echo "* Allparsedlist list was too large to host on github. $EDITEDALLPARSEDSIZEMB bytes $timestamp" | tee --append $RECENTRUN &>/dev/null
elif
[[ "$EDITEDALLPARSEDSIZEMB" -lt "$GITHUBLIMITMB" && -f $FILETEMP ]]
then
mv $FILETEMP $COMBINEDBLACKLISTSDBB
printf "$yellow"  "Big List Edited Created Successfully."
fi
