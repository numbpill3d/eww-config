#!/usr/bin/env bash
free | awk '/^Mem:/{printf "%d%%", ($3/$2)*100}'
