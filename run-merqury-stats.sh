#!/bin/bash
#

ccsReads="" #"data/pacbio/ccs.fa.gz data/pacbio/ccs2.fa.gz"
tenxDir="" #"data/10x/"
primasm="" #"assembly/primary.fa.gz"
haptigs="" #"assembly/haplotigs.fa.gz"

kmer=21
threads=32
memory=160 #GB

## this image is available on sanger farm cluster
## need to set merqury and meryl path otherwise
img_base="/software/tola/images"
singularity="/software/singularity-v3.6.4/bin/singularity exec -B /lustre:/lustre ${img_base}"
merqury="${singularity}/merqury-1.1.sif merqury.sh"
meryl="${singularity}/merqury-1.1.sif meryl"

## make meryl db
mkdir meryl_db

## make meryl db for ccs reads is straightforward
${meryl} k=${kmer} threads=${threads} memory=${memory} count output meryl_db/ccs.meryl <(zcat ${ccsReads})

## make meryl db for 10x reads
## need to trim the first 23 bases in R1
## *_R1_*.fastq.gz and *_R2_*.fastq.gz matches R1 and R2 files respectively - may need to change
${meryl} k=${kmer} threads=${threads} memory=${memory} count output meryl_db/10x.meryl <(zcat ${tenxDir}/*_R1_*.fastq.gz | awk '{if(NR%2==1) {print} else {print substr($1,24)}}'; zcat ${tenxDir}/*_R2_*.fastq.gz)

## get the real path as we need to cd into the subdirectory to run merqury
meryl10xdb=$(realpath meryl_db/10x.meryl | head -1)
merylccsdb=$(realpath meryl_db/ccs.meryl | head -1)
primasm=$(realpath ${primasm} | head -1)
haptigs=$(realpath ${haptigs} | head -1)

#### run merqury on primary and alt contigs
mkdir -p merqury.10x && cd merqury.10x && ${merqury} ${meryl10xdb} ${primasm} ${haptigs} meryl && cd .. &
mkdir -p merqury.ccs && cd merqury.ccs && ${merqury} ${merylccsdb} ${primasm} ${haptigs} meryl && cd .. &

wait


