#!/bin/lksh
pingcount=4
sleeptime=90
rtctime=300

source  ~/scripts/mysleep.inc
source  ~/scripts/onac.inc

touch() { echo > "$1" ; }
otthon() { nmcli |grep -q "connected to password" ; }
voicecall() { pactl list |grep -q "Active Profile: Voice Call" ; }
pingwh() {
{ n=$pingcount; while ((n--));do fping 172.16.4.79;done; } | uniq -c
}

#eval "export $(tr -s "\0" "\n" </proc/$(pgrep -u $LOGNAME -x icewm)/environ|grep BUS_SESSION_BUS_ADDRESS)"
eval "export $(tr -s "\0" "\n" </proc/$(pgrep -u mobian -x phosh)/environ|grep BUS_SESSION_BUS_ADDRESS)"

rm -f /tmp/rtcsleep /tmp/screenlock
trap "rm -f /tmp/rtcsleep /tmp/screenlock;cputoggle.sh max" HUP INT TERM

rtcsleep() {
[ -f /tmp/rtcsleep ] && return
touch /tmp/rtcsleep
sleep $((sleeptime * 2))
while [ -f /tmp/screenlock ] && ! otthon && ! onac; do
    if voicecall || [[ $(</sys/devices/platform/backlight/backlight/backlight/bl_power) -ne 4 ]]; then
	echo "voicecall, sleeping $sleeptime"
	sleep $sleeptime
	continue
    fi
	sudo ss -K dport = 6632
	echo "rtcwake -m mem -s $rtctime"
	sudo /usr/sbin/rtcwake -m mem -s $rtctime
	echo "woken up"
	pingwh
    [ ! -f /tmp/screenlock ] && break
    [ -f /tmp/notifyonscreen ] && paplay ~/Sounds/icq_message_sound.wav
    sleep $sleeptime
done
rm -f /tmp/rtcsleep
pingwh
}
screenlocked() {
	touch /tmp/screenlock
	echo SCREEN_LOCKED
	if otthon; then
	    onac || { echo cputoggle min ; cputoggle.sh min ; }
	else
	    cputoggle.sh min
	    onac || rtcsleep &
	fi
#	sudo cpufreq.sh min
}

#if ! otthon; then 
    lockstatus="$(gnome-screensaver-command -q)"
    lockstatus=${lockstatus#*is }
    [[ $lockstatus = active ]] && screenlocked
#fi

dbus-monitor --session "type='signal',interface='org.gnome.ScreenSaver'" |
  while read x; do
    case "$x" in 
	*"boolean true"*) screenlocked
	;;
	*"boolean false"*) echo SCREEN_UNLOCKED
		rm -f /tmp/screenlock
		cputoggle.sh max
		pingwh
	;;
    esac
  done
