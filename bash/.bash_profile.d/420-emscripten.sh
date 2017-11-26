export EMSCRIPTEN_HOME="$b/src/emsdk_portable"
if [ -d "$EMSCRIPTEN_HOME" ] ; then
  . "$EMSCRIPTEN_HOME/emsdk_env.sh" > /dev/null 2>&1
fi
