#!/usr/bin/env bash
# vitals_bar.sh <cpu|mem>
# outputs a compact bar: [████░░░░░░] 42%
# 10-char bar using block chars, reads /proc directly — no external tools needed

BAR_FULL="█"
BAR_EMPTY="░"
BAR_WIDTH=10

make_bar() {
  local pct=$1
  local filled=$(( pct * BAR_WIDTH / 100 ))
  local empty=$(( BAR_WIDTH - filled ))
  local bar="["
  local i
  for (( i=0; i<filled; i++ )); do bar+="$BAR_FULL"; done
  for (( i=0; i<empty;  i++ )); do bar+="$BAR_EMPTY"; done
  bar+="] ${pct}%"
  printf "%s" "$bar"
}

case "$1" in
  cpu)
    # read two samples of /proc/stat with a short gap for accuracy
    read -r _ u1 n1 s1 i1 w1 irq1 sirq1 _ < /proc/stat
    sleep 0.2
    read -r _ u2 n2 s2 i2 w2 irq2 sirq2 _ < /proc/stat

    total1=$(( u1 + n1 + s1 + i1 + w1 + irq1 + sirq1 ))
    total2=$(( u2 + n2 + s2 + i2 + w2 + irq2 + sirq2 ))
    idle1=$i1
    idle2=$i2

    dtotal=$(( total2 - total1 ))
    didle=$(( idle2 - idle1 ))

    if (( dtotal == 0 )); then
      pct=0
    else
      pct=$(( ( dtotal - didle ) * 100 / dtotal ))
    fi

    # clamp 0-100
    (( pct < 0   )) && pct=0
    (( pct > 100 )) && pct=100

    make_bar "$pct"
    ;;

  mem)
    local_total=0
    local_avail=0
    while IFS=':' read -r key val; do
      key="${key// /}"
      val="${val// /}"
      val="${val//kB/}"
      val="${val// /}"
      case "$key" in
        MemTotal)     local_total=$val ;;
        MemAvailable) local_avail=$val ;;
      esac
    done < /proc/meminfo

    if (( local_total == 0 )); then
      pct=0
    else
      used=$(( local_total - local_avail ))
      pct=$(( used * 100 / local_total ))
    fi

    (( pct < 0   )) && pct=0
    (( pct > 100 )) && pct=100

    make_bar "$pct"
    ;;

  *)
    printf "[??????????] ??"
    ;;
esac
