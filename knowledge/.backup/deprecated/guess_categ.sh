#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function categ () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFPATH="$(readlink -m "$BASH_SOURCE"/..)"
  cd -- "$SELFPATH" || return $?

  local MODJ=
  for MODJ in modules/*.json; do
    categ_one_mod "$MODJ" || return $?
  done
}


function categ_one_mod () {
  local MODJ="$1"
  local MODN="$(basename -- "$MODJ" .json)"
  printf '% 20s: ' "$MODN"
  local -A INFO=()
  eval "INFO=( $(../util/flat_json_dict_to_bash.sed -- "$MODJ") )"
  local DESCR="${INFO[descr_short]}"
  local TAGS=()

  case "$MODN" in
    adc       ) add_tags {io_port,input}/adc sensor/voltage ;;
    bit       ) add_tags math/binary ;;
    bloom     ) add_tags math/{algo,set_theory} ;;
    crypto    ) add_tags crypto ;;
    encoder   ) add_tags datafmt/{hex,base64} ;;
    fifosock  ) add_tags network/generic ;;
    file      ) add_tags database/{spiffs,fat} ;;
    hx711     ) add_tags sensor/{adc,voltage} ;;
    mcp4725   ) add_tags periph/voltage bus/i2c ;;
    net       ) add_tags network/{generic,protocol/{tcp,udp,dns}} ;;
    node      ) add_tags sys/{cpu,platform} ;;
    ow        ) add_tags bus/1wire ;;
    pcm       ) add_tags periph/audio audio/pcm;;
    rfswitch  ) add_tags periph/generic ;;
    sjson     ) add_tags datafmt/json ;;
    somfy     ) add_tags periph/motor ;;
    struct    ) add_tags datafmt/c_struct ;;
    tls       ) add_tags crypto network/protocol/tls ;;
    uart      ) add_tags io_port/{uart,serial} ;;
    xpt2046   ) add_tags input/touchscreen ;;
    yeelink   ) add_tags periph/light sensor/unknown ;;
  esac
  case "$MODN" in
    color-utils ) add_tags datafmt/color{,/rgb{,w},hsv} ;;

    fifo | \
    . )         add_tags datafmt/"$MODN" ;;

    gpio | \
    . )         add_tags io_port/"$MODN" ;;

    coap | \
    . )         add_tags network/protocol/"$MODN" ;;

    pwm | \
    pwm[0-9] | \
    sigma-delta | \
    . )         add_tags io_port/pwm ;;

    rotary | \
    . )         add_tags input/"$MODN" ;;

    cron | \
    tmr | \
    . )         add_tags event/time ;;

    perf | \
    rtcmem | \
    rtctime | \
    . )         add_tags sys/time ;;

    spi | \
    . )         add_tags bus/"$MODN" ;;

    gdbstub | \
    . )         add_tags sys/debug ;;

    redis | \
    rtcfifo | \
    sqlite3 | \
    . )         add_tags database/"${MODN%[0-9]}" ;;
  esac

  local ITEM=
  for ITEM in 433 315; do
    <<<"${DESCR,,}" grep -qPe '\b'"$ITEM"'([/\.]\d+|)\s*mhz\b' \
      && add_tags "rf/${ITEM}_mhz"
  done

  local KWD_TEXT="${DESCR,,}"
  KWD_TEXT="${KWD_TEXT//[\.,\/()-]/ }"
  local KWD_MATCH=

  simp_tag +bus/i2c i2c i²c
  simp_tag +network/protocol/% http sntp mdns mqtt ftp
  simp_tag +network/{email,protocol/%} imap pop3 smtp
  simp_tag +network/medium/wifi wlan wifi
  simp_tag +periph/% display
  simp_tag +periph/light led
  simp_tag +warning/% deprecated

  simp_tag +brand/% \
    adafruit \
    bosch \
    sensortec \
    somfy \
    ;

  if [[ "$KWD_TEXT" == 'access '* ]]; then
    simp_tag +sensor/light {light,luminosity}' sensor'
    simp_tag +sensor/% compass gyroscope accelerometer
    simp_tag +sensor/temp thermometer
    simp_tag +sensor/{temp,press} 'temperature and pressure sensor'
    simp_tag +sensor/{humid,temp,weather} 'humidity and temperature sensor'
    simp_tag +sensor/{temp,humidity,press,weather} \
      'temperature air pressure humidity sensor'
    simp_tag +periph/% motor
  fi

  readarray -t TAGS < <(printf '%s\n' "${TAGS[@]}" | sort --uniq)
  case " ${TAGS[*]} " in
    *'/ '* | \
    *'('* | \
    *')'* | \
    . ) TAGS+=( '!!' );;

    *' bus/'* ) ;;
    *' crypto '* ) ;;
    *' database/'* ) ;;
    *' datafmt/'* ) ;;
    *' event/'* ) ;;
    *' input/'* ) ;;
    *' io_port/'* ) ;;
    *' math/'* ) ;;
    *' network/'* ) ;;
    *' periph/'* ) ;;
    *' sensor/'* ) ;;
    *' sys/'* ) ;;
    *' warning/deprecated '* ) ;;

    * ) TAGS+=( '!!' );;
  esac
  printf '%- 40s | %s\n' "${TAGS[*]}" "${KWD_TEXT:0:80}"

  sed -rf <(echo '
    /[{},]$/!s~$~,~
    s~^(\s+"categories": \[)(\],)$~\1\n'"$(
      printf '    "%s",\\n' "${TAGS[@]}"
      )"'  \2~
    s~\[\],$~\[\n  \],~
    ') -- "$MODJ" | tee -- modules/"$MODN".ceson
}


function add_tags () {
  [ -n "$*" ] || return 0
  local ADD=
  for ADD in "$@"; do
    ADD="${ADD//%/$KWD_MATCH}"
    TAGS+=( "$ADD" )
  done
}


function simp_tag () {
  KWD_MATCH=
  local KWD=
  local ADD_TAGS=()
  for KWD in "$@"; do
    case "$KWD" in
      +* )
        ADD_TAGS+=( "${KWD:1}" )
        continue;;
    esac
    case " $KWD_TEXT " in
      *" ${KWD}s "* | \
      *" ${KWD}es "* | \
      *" $KWD "* )
        KWD_MATCH="$KWD"
        add_tags "${ADD_TAGS[@]}"
        ;;
    esac
  done
  [ -n "$KWD_MATCH" ] || return 2
}











[ "$1" == --lib ] && return 0; categ "$@"; exit $?
