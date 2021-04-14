#!/bin/bash -x

TEMPLATE=PracticeTemplate
TAG="GRI"
LOGDIR="$HOME/2/tmp/PracticeStart.sh"
JACK_PRESET=FastTrack

rm -rf "$LOGDIR"
mkdir -p "$LOGDIR"

. AudioFunctions.sh

builtin=true
hydrogen=true
gxtuner=true
sooperlooper=true
gxtuner=true
zita=true
ardour=true

log -n "Start qjackctl."
start_jackd --preset FastTrack --disconnect-pulseaudio

if $builtin ; then
    log "Exposing builtin HW..."
    launch --name "builtin" --prio 250 -- \
	   alsa_in -j builtin -dhw:0 
    portWait 3 builtin || exit 1
    log done.
fi

if $hydrogen ; then
    log "Launching Hydrogen..."
    launch --name hydrogen --prio 251 -- \
           hydrogen -s "$HOME/src/HydrogenSongs/Metronomes.h2song" 
    portWait 5 Hydrogen || exit 1
    jack_disconnect Hydrogen:out_L system:playback_1
    jack_disconnect Hydrogen:out_R system:playback_2
fi

if $gxtuner ; then
    log "Launching GxTuner..."
    launch --name gxtuner --prio 252 -- \
           carla-single 'http://guitarix.sourceforge.net/plugins/gxtuner#tuner'
    portWait 10 GxTuner || exit 1
    jack_connect system:capture_1 GxTuner:In
    jack_connect system:capture_2 GxTuner:In

fi

if $sooperlooper; then
    log "Launching Sooperlooper ..."
    killall sooperlooper
    launch --name sooperlooper --prio 253 -- \
           slgui -H localhost -t 120
    portWait 3 sooperlooper || exit 1
fi

if $zita ; then
    log "Launching zita..."
    launch --name zita --prio 254 -- \
           zita-mu1
    portWait 5 zita-mu1 || exit 1
    jack_connect zita-mu1:mon_out1.L system:playback_1
    jack_connect zita-mu1:mon_out1.R system:playback_2
fi

if $ardour; then
    log "Starting Ardour6..."
    launch --name ardour --prio 255 -- \
	    Ardour6 --template "$TEMPLATE" --new "$(sessionName)"
    portWait 10 ardour:LTC-Out
    jack_disconnect Master:audio_out1 system:playback_1
    jack_disconnect Master:audio_out2 system:playback_2
    log done.
fi

launch --name qasmixer --prio 256 -- \
    qasmixer

alsamixer -c Track -V all

killLaunches

killall qasmixer
