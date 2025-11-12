#!/bin/bash
source $HOME/scripts/lib/term-cfns

# Cache file format & path
dumpName="$(date "+%d%m%Y")_netstats"
dumpFile="$HOME/.cache/$dumpName"

# Today format for grep
today="$(date "+%d/%m/%Y")"

# Dumpsys to a file
ads dumpsys netstats > $dumpFile

# Fetch raw data in bytes
# Format: 
#   fetch <match_pattern> <output_name>
fetch () {
  cat $dumpFile |\
    sed 's/ident/\n\nident/g' |\
    awk '/'$1'/,/^$/' |\
    grep --color=never rb |\
    sed 's/st=//g; s/tb=//g; s/rb=//g;' |\
    awk '{print strftime("%d/%m/%Y",$1), $2, $4}' |\
    grep "$today" |\
    awk '{received+=$2;sent+=$3};END{total=received+sent;printf "%-10s %-15i %-15i %i\n", "'$2'", total, received, sent }'
}

# Convert data from bytes to nearest whole format
# Format:
#   data_convert <raw_fetch_format>
net_convert () {
  total="`echo $1 | awk '{print $2}'`"

  # GiB = 1073741824 bytes
  if [[ $total -gt 1073741824 ]]; then
    echo $1 | awk '{divider=1073741824; printf "%-10s %07.3f %-7s %07.3f %-7s %07.3f %s\n", $1 , $2/divider, "GiB" , $3/divider, "GiB" , $4/divider, "GiB" }'
  # MiB = 1048576 bytes
  elif [[ $total -gt 1048576 ]]; then
    echo $1 | awk '{divider=1048576; printf "%-10s %07.3f %-7s %07.3f %-7s %07.3f %s\n", $1 , $2/divider, "MiB" , $3/divider, "MiB" , $4/divider, "MiB" }'

  # KiB = 1024 bytes
  else
    echo $1 | awk '{divider=1024; printf "%-10s %07.3f %-7s %07.3f %-7s %07.3f %s\n", $1 , $2/divider, "KiB" , $3/divider, "KiB" , $4/divider, "KiB" }'

  fi
}

# Wifi consumption in bytes
wifi_raw="`fetch "wifiNetworkKey" "Wi-Fi"`"

# Data consumption in bytes
data_raw="`fetch "metered=true" "Data"`"


case "$1" in
  "-r"|"--raw")
    # Output header
    printf "%-10s %-15s %-15s %s\n" \
      "Type" \
      "Total(B)" \
      "Received(B)" \
      "Sent(B)"

    echo "$wifi_raw"
    echo "$data_raw"
    ;;

  "-n"|"--notify")
    todaydir="$HOME/.cache/netstats/`date "+%Y/%m"`"
    if [[ ! -d "$todaydir" ]]; then
      mkdir -p "$todaydir" 
    fi
    $HOME/bin/dm |\
      tee "$todaydir"/"`date "+%d"`" |\
      termux-notification \
      --alert-once \
      --icon show_chart \
      --ongoing \
      --id 3317 \
      -t "Data Monitor" \
      --group 90
    ;;

  *)
    # Output header
    printf "%-10s %-15s %-15s %s\n" \
      "Type" \
      "Total" \
      "Received" \
      "Sent"

    net_convert "$wifi_raw"
    net_convert "$data_raw"
    ;;
esac


