#!/bin/sh

APPS_SCRIPT="$HOME/tmp/JamulusPIDs.sh"
rm -rf "$APPS_SCRIPT"
echo "#!/bin/sh" > "$APPS_SCRIPT"
chmod +x "$APPS_SCRIPT"

JAMULUS_LOG="/dev/null"
ALSA_IN_LOG="/dev/null"
MIDI_LOG="/dev/null"
ARDOUR_LOG="/dev/null"

# Disconnect pulse audio from jack. Ardour will reconnect it.
jack_disconnect 'PulseAudio JACK Sink:front-left' 'system:playback_1'
jack_disconnect 'PulseAudio JACK Sink:front-right' 'system:playback_2'
jack_disconnect 'system:capture_1' 'PulseAudio JACK Source:front-left'
jack_disconnect 'system:capture_2' 'PulseAudio JACK Source:front-right'

# Start Jamulus but don't connect anything.
launch_remember JAMULUS_PID Jamulus --nojackconnect & >& "$JAMULUS_LOG"
echo JAMULUS_PID="$JAMULUS_PID" >> "$APPS_SCRIPT"

# Set up the built in input
launch_remember ALSA_IN_PID alsa_in -j builtin -dhw:0 & >& "$ALSA_IN_LOG"
echo ALSA_IN_PID="$ALSA_IN_PID" >> "$APPS_SCRIPT"

# Midi
launch_remember MIDI_PID a2jmidid -e & >& "$MIDI_LOG"
echo MIDI_PID="$MIDI_PID" >> "$APPS_SCRIPT"

# Ardour
launch_remember ARDOUR_PID Ardour6 --template "$TEMPLATE" --new "$(sessionName)" & >& "$ARDOUR_LOG_FILE"
echo ARDOUR_PID="$ARDOUR_PID" >> "$APPS_SCRIPT"
