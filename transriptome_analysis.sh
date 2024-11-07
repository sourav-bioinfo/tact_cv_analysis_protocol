#adapter + primer trimming
trim_galore -q 20 --phred33 --clip_R2 10 -a adapter_sequence_1 -a2 adapter_sequence_2 --trim-n -o . --length 35 --paired paired_read_1.fastq paired_read_2.fastq
trim_galore -q 20 --phred33 --trim-n -o . --length 35 --paired adapter_trimmed_read_pair_1.fastq adapter_trimmed_read_pair_2.fastq

#read alignment
hisat2 --dta -S sample.sam --summary-file sample.summ --min-intronlen 20 --max-intronlen 3000 -x PF_genome_v53 --rna-strandness RF -1 adapter_trimmed_read_pair_1.fastq -2 adapter_trimmed_read_pair_2.fastq -p 80

# subsetting reads aligned to maximum three locations
samtools view -H sample.bam > sample.unq.sam
samtools view -F 4 sample.bam | grep 'NH:i:[123]' | grep -v NH:i:10 >> sample.unq.sam

# sort alignment
samtools sort -@ 60 sample.unq.sam -o sample.unq.bam

# genome guided transcriptome assembly for individual samples
stringtie sample1.unq.bam -e -G PlasmoDB-59_Pfalciparum3D7.gff -o sample1_transcriptome.gtf -p 20 --fr -m 150 -j 3 -g 20
stringtie sample2.unq.bam -e -G PlasmoDB-59_Pfalciparum3D7.gff -o sample2_transcriptome.gtf -p 20 --fr -m 150 -j 3 -g 20
.
.
.
stringtie samplen.unq.bam -e -G PlasmoDB-59_Pfalciparum3D7.gff -o samplen_transcriptome.gtf -p 20 --fr -m 150 -j 3 -g 20

# creating consensus transcriptome
stringtie --merge -p 40 -G PlasmoDB-59_Pfalciparum3D7.gff -o stringtie_merged.gtf mergelist.txt


# quantification of transcripts
stringtie -e -B -p 70 -G stringtie_merged.gtf -o sample1.abandunce.gtf sample1.unq.bam
stringtie -e -B -p 70 -G stringtie_merged.gtf -o sample2.abandunce.gtf sample1.unq.bam
.
.
.
stringtie -e -B -p 70 -G stringtie_merged.gtf -o samplen.abandunce.gtf sample1.unq.bam
