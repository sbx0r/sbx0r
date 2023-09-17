#!/bin/bash

set -o

readonly BADGE_COLOR="d1d2d3"
readonly BADGES_URL="https://img.shields.io/badge"
readonly BADGES_STATIC_PARAMS="style=for-the-badge&?logoWidth=30"
readonly BADGES_LOGO_PARAM="logo=data:image/png;base64,"
readonly BADGES_LINK_PARAM="link="
readonly ICONS_FILEPATH="portfolio/techs/icons-list.yml"
readonly README_FILEPATH="./README.md"
readonly README_HEADER_START="<!-- TECH RADAR START -->"
readonly README_HEADER_END="<!-- TECH RADAR END -->"


function get_scaled_image_data() {

  local url=$1
  local o_filename="thumb.png"

  curl $url --silent --output $o_filename
  convert -geometry 20x $o_filename -quality 90 $o_filename
  _err=$?
  if [[ $_err -ne 0 ]]; then
    echo "[ ERROR ] Problem converting image from $url."
    exit 1
  fi
  base64 -w0 $o_filename
  rm $o_filename

}

# Clear Tech Radar
sed "/^$README_HEADER_START/,/^$README_HEADER_END/{/$README_HEADER_STOP/b;d;}" \
  $README_FILEPATH > $README_FILEPATH.tmp
mv $README_FILEPATH.tmp $README_FILEPATH

IFS=$'\n'
for type in $(yq '.[].type' $ICONS_FILEPATH); do

  # Insert Tech header into readme
  sed "/^$README_HEADER_END/i# $type\n" $README_FILEPATH > $README_FILEPATH.tmp
  mv $README_FILEPATH.tmp $README_FILEPATH

  tech=$(yq ".[] | select(.type == \"$type\")" $ICONS_FILEPATH)

  for name in $(yq '.data.[].name' <<< $tech); do

    name_unified=$(echo ${name// /_})
    official_site=$(yq ".data.[] | select(.name == \"$name\") | .officialURL" <<< $tech)
    predefined_badge=$(yq ".data.[] | select(.name == \"$name\") | .predefinedBadge" <<< $tech)
    if [[ $predefined_badge == "null" ]]; then

      icon_url=$(yq ".data.[] | select(.name == \"$name\") | .iconURL" <<< $tech)
      image_data=$(get_scaled_image_data $icon_url)
      _err=$?
      if [[ $_err -ne 0 ]]; then
        $image_data
        exit 1
      fi

      badge_url=$(printf '%s/%s-%s?%s&%s%s&%s%s' \
        $BADGES_URL \
        $name_unified \
        $BADGE_COLOR \
        $BADGES_STATIC_PARAMS \
        $BADGES_LOGO_PARAM \
        $image_data \
        $BADGES_LINK_PARAM \
        $official_site)
    else
      badge_url=$(printf '%s&%s%s' $predefined_badge $BADGES_LINK_PARAM $official_site)
    fi

    sed "/^$README_HEADER_END/i[![$name_unified]($badge_url)]($official_site)" $README_FILEPATH > $README_FILEPATH.tmp
    mv $README_FILEPATH.tmp $README_FILEPATH

  done;

  sed "/^$README_HEADER_END/i<br>" $README_FILEPATH > $README_FILEPATH.tmp
  mv $README_FILEPATH.tmp $README_FILEPATH

done;
