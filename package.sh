#!/bin/bash
trap 'echo CTRL-C was pressed, will exit; exit 1' 2
package="aqingsir"
rm -rf $package.zip

zip -r $package.zip . -x "*.sh" ".git/*" "*.zip"> /dev/null

scp -P 9527 $package.zip reader@how2read.me:/www/aqingsir/