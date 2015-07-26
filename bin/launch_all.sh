#!/bin/bash
unset HUE_BRIDGE_IP
unset HUE_BRIDGE_USERNAME

# Min/max brightness for dimmable lights:
export MIN_BRI=31
export MAX_BRI=127

# Saturation for color lights:
export HUE_SATURATION=95

# Run indefinitely, don't let GC muck with shit.
export ITERATIONS=0
export SKIP_GC=1

# Determine how we handle concurrency -- threads vs. async I/O.
export THREADS=1
export MAX_CONNECTS=6

# Whether or not to show success information.
export VERBOSE=0

export CONFIGS=(
  Bridge-01
  Bridge-02
  Bridge-03
)

###############################################################################
HANDLER='(kill -HUP $JOB1; sleep 1; kill -HUP $JOB2; sleep 1; kill -HUP $JOB3) 2>/dev/null'
trap "$HANDLER" EXIT
trap "$HANDLER" QUIT
trap "$HANDLER" KILL

{ time ./bin/go_nuts.rb ${CONFIGS[0]} & }
JOB1=$!
{ time ./bin/go_nuts.rb ${CONFIGS[1]} & }
JOB2=$!
{ time ./bin/go_nuts.rb ${CONFIGS[2]} & }
JOB3=$!

if [[ $ITERATIONS == 0 ]]; then
  echo "Sleeping while $JOB1, $JOB2, and $JOB3 run..."
  sleep 30

  echo
  echo "Cleaning up."
  (
    kill -HUP $JOB1
    sleep 1
    kill -HUP $JOB2
    sleep 1
    kill -HUP $JOB3
  ) 2>/dev/null
else
  wait
fi
