#Raw reads evaluation using FASTQC
source /local/env/envfastqc.sh
fastqc -t 6 $1

#KMER distribution using JELLYFISH and GENOMESCOPE2
jellyfish count -m 31 -s 100M -t 10 -C IS19-2_S2_L001_R12_001.fastq -o mer_counts_2.jf
jellyfish histo -t 10 mer_counts.jf > s1.histo
genomescope2 -i reads.histo -o output -k 31

#Ithomia salapia genome assembly using SUPERNOVA
supernova run --id=SN_all --fastqs=/Ithomia_salapia/data --maxreads='all' --sample IS19-1
supernova run --id=SN_all2 --fastqs=/Ithomia_salapia/data --maxreads='all' --sample IS19-2
supernova mkoutput --asmdir=SN_all/outs/assembly/ --outprefix=SN_all1_pseudohap --style=pseudohap
supernova mkoutput --asmdir=SN_all2/outs/assembly/ --outprefix=SN_all2_pseudohap --style=pseudohap

#Genome merging using RAGOUT
cactus --binariesMode singularity jobStore ithomia.txt ithomia.hal 
cat ithomia.txt 
IS19-1 IS19-1_140MRead_PSH_correctedheader2.fasta
IS19-2 IS19-2_140MRead_PSH_correctedheader2.fasta
ragout recipe.txt -s hal -t 12
cat recipe.txt 
.references = IS19-1
.target = IS19-2
#paths to genome fasta files
IS19-1.fasta = IS19-1_140MRead_PSH_correctedheader2.fasta
IS19-2.fasta = IS19-2_140MRead_PSH_correctedheader2.fasta
#HAL alignment input. Sequences will be extracted from the alignment
.hal = ithomia.hal

#Genome completeness evaluation using BUSCO
busco -i IS19-2_ragout_1000_gn.fasta -l lepidoptera_odb10 -o busco_genome_IS19-2_ragout_1000 -m genome

#RepeatMasker
RepeatMasker -species insecta $1 -pa 12 -small -gff 

#Genome annotation using MAKER
maker_all_process.sh

#Gene set completeness evaluation using BUSCO
busco -i Ithomia_salapia_OGS1.0_proteins.fa -l lepidoptera_odb10 -o busco_prot_Ithomia_salapia_OGS1.0_proteins -m proteins

#Orthologous gene identification using ORTHOFINDER
orthofinder -f PROT.dir -t 8 




