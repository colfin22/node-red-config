#!/bin/bash
cd /opt/node-red || exit 1
git add -A
git -c user.email=node-red@colfin22.net -c user.name=node-red-lxc commit -q -m "auto backup $(date +%F\ %H:%M)" || exit 0
git push -q
