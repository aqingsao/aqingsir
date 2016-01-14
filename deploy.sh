#!/bin/bash
trap 'echo CTRL-C was pressed, will exit; exit 1' 2

package="aqingsir"
if [ ! -f $package.zip ]; then
  echo "$package.zip does not exist.";
  exit 1;
fi

unzip $package.zip 2>&1

./restart.sh