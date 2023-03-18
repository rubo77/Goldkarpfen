#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
#relative time difference utility
#usage: __CHECK__DATES [date1] [date2] or test for age: __CHECK__DATES [date1]
#Tests if date1 is newer than date2 and date 1 is not older than 333 days. Time resolution: days.
#time format: "%y-%m-%d" or "%y-%m-%d %M:%H" (minute and hour are ignored)
#does not account for differences greater than 12 year around a century flip
now=$(date -u +"%y-%m-%d")
this_year=${now%%-*};this_year=${this_year#0};
year1=${1%%-*};year1=${year1#0}
if test -z "$2";then year2=$year1; else year2=${2%%-*};year2=${year2#0};fi

if test "$this_year" -eq 0;then
  this_year=88
  year1=$((year1 - 12))
  year2=$((year2 - 12))
  if test "$year1" -lt -1;then year1=$((year1 + 100));fi
  if test "$year2" -lt -1;then year2=$((year2 + 100));fi
fi
if test $((this_year - year1)) -gt 1;then
  >&2 echo "  EE date1 is older than 333 days"
  exit 1
fi
days_from_null_now=$(echo "$this_year 366 * $(date -u -d "20$now" "+%j") + p" | dc)
days_from_null_1=$(echo "$year1 366 * $(date -u -d "20$1" "+%j") + p" | dc)
days_from_null_2=$(echo "$year2 366 * $(date -u -d "20$2" "+%j") + p" | dc)
if test $((days_from_null_now - days_from_null_1)) -gt 333;then
  >&2 echo "  EE date1 is older than 333 days"
  exit 1
fi
if test $((days_from_null_now - days_from_null_1)) -lt 0;then
  >&2 echo "  EE date1 is from the future"
  exit 1
fi
if ! test -z "$2";then
  if test $((days_from_null_1 - days_from_null_2)) -le 0;then
    >&2 echo "  EE date2 is newer/same age (NOTE: time resolution: days)"
    exit 1
  fi
fi
