#!/bin/bash
echo "Sort apk packages by size"
apk list -Iq | while read pkg; do apk info -s "$pkg" | tac | tr '\n' ' ' | xargs | sed -e 's/\s//'; done | sort -rh
