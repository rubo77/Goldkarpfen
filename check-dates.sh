#!/bin/sh
#GPL-3 - See LICENSE file for copyright and license details.
#relative time difference utility
#usage: __CHECK__DATES [date1] [date2] or test for age: __CHECK__DATES [date1]
#Tests if date1 is newer than date2 and date 1 is not older than 333 days. Time resolution: days.
#time format: "%y-%m-%d" or "%y-%m-%d %M:%H" (minute and hour are ignored)
#does not account for differences greater than 10 year around a century flip
now=$(date --utc +"%y-%m-%d")
this_year=$(echo "$now" | awk -F "-" '{printf "%d\n",$1;}')
year1=$(echo "$1" | awk -F "-" '{printf "%d\n",$1;}')
if test -z "$2";then
  year2=$(echo "$1" | awk -F "-" '{printf "%d\n",$1;}')
else
  year2=$(echo "$2" | awk -F "-" '{printf "%d\n",$1;}')
fi

if test "$this_year" -eq 0;then
  this_year=90
  year1=$((year1 - 10))
  year2=$((year2 - 10))
  if test "$year1" -lt -1;then
    year1=$((year1 + 100))
  fi
  if test "$year2" -lt -1;then
    year2=$((year2 + 100))
  fi
fi
if test $((this_year - year1)) -gt 1;then
  >&2 echo "  EE date1 is older than 333 days"
  exit 1
fi
days_from_null_now=$(( $(date --utc -d "$now" "+%j") + 366 * this_year))
days_from_null_1=$(( $(date --utc -d "$1" "+%j") + 366 * year1 ))
days_from_null_2=$(( $(date --utc -d "$2" "+%j") + 366 * year2 ))
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
