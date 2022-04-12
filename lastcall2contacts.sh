#!/bin/lksh
IFS=\' read number timestamp <<<"$(sqlite3 /home/mobian/.local/share/calls/records.db .dump|grep ^INSERT|grep tel|tail -1|cut -d\' -f2,4)"
echo number: $number, timestamp: $timestamp
existing=$(/usr/libexec/evolution-data-server/addressbook-export --format=csv|grep "$number"|cut -d\" -f-13)
if [[ -n $existing ]]; then
    yad --title "Add last call to contacts" --text="Number $number already exists as $existing"
    exit 1
fi

yadinput=$(yad --title "Add last call to contacts" --text="Add mobile number: $number" --form --field=name)
name=${yadinput%|}
[[ -z $name ]] && exit 1

cat <<EOF > /tmp/$timestamp.vcf
BEGIN:VCARD
VERSION:3.0
REV:$timestamp
UID:42
FN:$name
N:;$name;;;
TEL;TYPE=CELL,VOICE:$number
END:VCARD

EOF

syncevolution --import /tmp/$timestamp.vcf backend=evolution-contacts database=Personal
status=$?
if [[ $status = 0 ]]; then
    yad --title "Add last call to contacts" --text="Added mobile number: $number as $name"
else
    yad --title "Add last call to contacts" --text="ERROR DURING adding mobile number: $number as $name"
fi
