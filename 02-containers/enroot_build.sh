#!/bin/bash
# Build and run an enroot container end to end, all on ONE GPU node.
# Verified 23 July 2026. Run from the login node: bash enroot_build.sh
srun -p h100 --time=00:15:00 bash -lc '
set -x
cd $HOME
rm -f ubuntu+22.04.sqsh
enroot import -o ubuntu+22.04.sqsh docker://ubuntu:22.04
enroot remove -f ubuntu+22.04 2>/dev/null
enroot create ubuntu+22.04.sqsh
enroot start ubuntu+22.04 echo "hello from enroot"
enroot remove -f ubuntu+22.04
'
