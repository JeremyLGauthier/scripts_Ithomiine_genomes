#! /bin/bash
#$ -cwd
#$ -N maker_mpi
#$ -pe mpi 15
unset PERL5LIB
#. /local/env/envpython-2.4.4.sh
. /local/env/envpython-2.7.15.sh
#. /local/env/envmpich2-1.3.1.sh
. /local/env/envmaker-2.31.10.sh
#. /local/env/envopenmpi-3.1.2.sh


export nb_process=15

while read i
	do
	#creation
	j=`echo "$i" |sed -e 's/\.fasta//g'`
	mkdir ./"$j"_transfert_folder
	
	#RUN1
	mkdir ./"$j"_transfert_folder/Maker_RUN1
	cd ./"$j"_transfert_folder/Maker_RUN1
	
	#remplissage
	ln -s ../../GENOMES.dir/"$j".fasta .
	sed -e 's/genome=G/genome='"$i"'/g' ../../SCRIPTS.dir/maker_opts.ctl > ./maker_opts.ctl
	cp ../../SCRIPTS.dir/maker_bopts.ctl .
	cp ../../SCRIPTS.dir/maker_exe.ctl .
	
	#execution
	mpiexec -n $nb_process maker maker_opts.ctl maker_bopts.ctl maker_exe.ctl -fix_nucleotides
	#maker maker_opts.ctl maker_bopts.ctl maker_exe.ctl -fix_nucleotides
	
	#extract gff
	mv ./"$j".maker.output/"$j"_master_datastore_index.log ./"$j".maker.output/"$j"_master_datastore_index.log.bak
	maker -c8 -dsindex maker_opts.ctl maker_bopts.ctl maker_exe.ctl
	gff3_merge -d ./"$j".maker.output/"$j"_master_datastore_index.log -o maker_round1.gff3
	
	#Snap
	mkdir Snap
	cd Snap
	ln -s ../maker_round1.gff3 .
	maker2zff maker_round1.gff3
	/local/maker/2.31.3/exe/snap/fathom -categorize 1000 genome.ann genome.dna
	/local/maker/2.31.3/exe/snap/fathom -export 1000 -plus uni.ann uni.dna
	/local/maker/2.31.3/exe/snap/forge export.ann export.dna
	/local/maker/2.31.3/exe/snap/hmm-assembler.pl "$j"_1 . > "$j"_1.hmm
	cd ..	
	
	#Augustus
	mkdir Augustus
	cd Augustus
	ln -s ../maker_round1.gff3 .
	ln -s ../../../GENOMES.dir/"$j".fasta .
	. /local/env/envperl-5.22.0.sh
	. /local/env/envaugustus.sh	 
	maker2zff maker_round1.gff3
	/local/maker/2.31.3/exe/snap/zff2gff3.pl genome.ann | perl -plne 's/\t(\S+)$/\t\.\t$1/' > genome.gff3
	perl /local/augustus-3.0/scripts/autoAug.pl --genome="$j".fasta --species="$j"_1 --trainingset=genome.gff3 --noninteractive --cname=genocluster2 -v --useexisting
	
	#cleaning
	cd ../..
	#rm -r ./Maker_RUN1/"$j".maker.output/"$j"_datastore
	

	#RUN2
	mkdir ./Maker_RUN2
	cd ./Maker_RUN2
	
	#remplissage
	ln -s ../../GENOMES.dir/"$j".fasta .
	ln -s ../Maker_RUN1/Snap/"$j"_1.hmm .
	sed -e 's/genome=G/genome='"$i"'/g' -e 's/snaphmm=/snaphmm='"$j"'_1\.hmm/g' -e 's/augustus_species=/augustus_species='"$j"'_1/g' -e 's/est2genome=1/est2genome=0/g' -e 's/protein2genome=1/protein2genome=0/g' ../../SCRIPTS.dir/maker_opts.ctl > ./maker_opts.ctl
	cp ../../SCRIPTS.dir/maker_bopts.ctl .
	cp ../../SCRIPTS.dir/maker_exe.ctl .
	
	#execution
	mpiexec -n $nb_process maker maker_opts.ctl maker_bopts.ctl maker_exe.ctl -fix_nucleotides

	#extract gff
	mv ./"$j".maker.output/"$j"_master_datastore_index.log ./"$j".maker.output/"$j"_master_datastore_index.log.bak
	maker -dsindex maker_opts.ctl maker_bopts.ctl maker_exe.ctl
	gff3_merge -d ./"$j".maker.output/"$j"_master_datastore_index.log -o maker_round2.gff3

	#Snap
	mkdir Snap2
	cd Snap2
	ln -s ../maker_round2.gff3 .
	maker2zff maker_round2.gff3
	/local/maker/2.31.3/exe/snap/fathom -categorize 1000 genome.ann genome.dna
	/local/maker/2.31.3/exe/snap/fathom -export 1000 -plus uni.ann uni.dna
	/local/maker/2.31.3/exe/snap/forge export.ann export.dna
	/local/maker/2.31.3/exe/snap/hmm-assembler.pl "$j"_2 . > "$j"_2.hmm

	#Augustus
	cd ..
	mkdir Augustus2
	cd Augustus2
	ln -s ../maker_round2.gff3 .
	ln -s ../../../GENOMES.dir/"$j".fasta .
	. /local/env/envperl-5.22.0.sh
	. /local/env/envaugustus.sh
	maker2zff maker_round2.gff3
	/local/maker/2.31.3/exe/snap/zff2gff3.pl genome.ann | perl -plne 's/\t(\S+)$/\t\.\t$1/' > genome.gff3
	perl /local/augustus-3.0/scripts/autoAug.pl --genome="$j".fasta --species="$j"_2 --trainingset=genome.gff3 --noninteractive --cname=genocluster2 -v --useexisting
	
	#cleaning
	cd ../..
	#rm -r ./Maker_RUN2/"$j".maker.output/"$j"_datastore
	

	#RUN3
	mkdir ./Maker_RUN3
	cd ./Maker_RUN3
	
	#remplissage
	ln -s ../../GENOMES.dir/"$j".fasta .
	ln -s ../Maker_RUN2/Snap2/"$j"_2.hmm .
	sed -e 's/genome=G/genome='"$i"'/g' -e 's/snaphmm=/snaphmm='"$j"'_2\.hmm/g' -e 's/augustus_species=/augustus_species='"$j"'_2/g' -e 's/est2genome=1/est2genome=0/g' -e 's/protein2genome=1/protein2genome=0/g' ../../SCRIPTS.dir/maker_opts.ctl > ./maker_opts.ctl
	cp ../../SCRIPTS.dir/maker_bopts.ctl .
	cp ../../SCRIPTS.dir/maker_exe.ctl .

	#execution
	mpiexec -n $nb_process maker maker_opts.ctl maker_bopts.ctl maker_exe.ctl -fix_nucleotides

	#extract gff
	mv ./"$j".maker.output/"$j"_master_datastore_index.log ./"$j".maker.output/"$j"_master_datastore_index.log.bak
	maker -dsindex maker_opts.ctl maker_bopts.ctl maker_exe.ctl
	gff3_merge -d ./"$j".maker.output/"$j"_master_datastore_index.log -o maker_round3.gff3
	
	#transformation finale
	awk '{if ($2 == "maker") {print}}' maker_round3.gff3 > "$j"_OGS1.0.gff3
	maker_map_ids --prefix "$j" --justify 6 "$j"_OGS1.0.gff3 > maker.id.map
	map_gff_ids maker.id.map "$j"_OGS1.0.gff3
	gtf=`basename "$j"_OGS1.0.gff3 .gff3`.gtf
	maker2eval_gtf "$j"_OGS1.0.gff3 > $gtf
	. /local/env/enveval.sh
	/local/eval/2.2.8/validate_gtf.pl $gtf > $gtf.validation
	/local/eval/2.2.8/get_general_stats.pl $gtf > $gtf.stats
	. /local/env/envcufflinks-2.2.1.sh
	name=`basename "$j"_OGS1.0.gff3 .gff3`
	echo $name
	. /local/env/envcufflinks-2.2.1.sh
	gffread "$j"_OGS1.0.gff3 -g "$j".fasta -w "$j"_OGS1.0_transcripts.fa -y "$j"_OGS1.0_proteins.fa -x "$j"_OGS1.0_cds.fa
	
	#cleaning
	#rm -r ./"$j".maker.output/"$j"_datastore

	done < $1



