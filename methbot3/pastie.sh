#!/bin/bash

output=/tmp/output

echo "## line count" > $output
wc -l bot.rb lib/* models/* plugins/* >> $output
echo >> $output

echo "## tree" >> $output
tree >> $output
echo >> $output

for x in start.sh bot.rb lib/* models/* plugins/* pastie.sh; do
  echo >> $output
  echo "## $x" >> $output
  cat $x >> $output
done 

pastie -p $output

rm $output

