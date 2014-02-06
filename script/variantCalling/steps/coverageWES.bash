#!/bin/bash

# awk '$8 >= 5 {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6}' eachBase.1-based.coverage |sort -k1,2| uniq -c |awk '{print $2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"int(($1*100/($4-$3))+.5)}'|sort -k 7 -n > finalResult.5.tsv
awk '$8 >= 10 {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6}' eachBase.1-based.coverage |sort -k1,2| uniq -c |awk '{print $2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"int(($1*100/($4-$3))+.5)}'|sort -k 7 -n > coverage_per_cdExon.10.tsv
# awk '$8 >= 15 {print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6}' eachBase.1-based.coverage |sort -k1,2| uniq -c |awk '{print $2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$7"\t"int(($1*100/($4-$3))+.5)}'|sort -k 7 -n > finalResult.15.tsv

