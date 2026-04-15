#!/bin/bash

cd ${OPENCODE_WORKSPACE}
nohup opencode web --hostname 0.0.0.0 --port ${OPENCODE_WEB_PORT} &

nohup opencode --port ${OPENCODE_PORT} --hostname 0.0.0.0 &

# keep container running
tail -f /dev/null