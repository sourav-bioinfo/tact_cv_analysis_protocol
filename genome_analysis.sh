#### Genome data processing commands

# Trimming command
trim_galore -q 30 --phred33 -a adapter_sequence_1 -a2 adapter_sequence_2 --stringency 5 --trim-n -e 0.2 -o . --length 75 --paired <raw_read_pair1.fastq raw_read_pair2.fastq

# Alignment command
bwa mem -o sample.sam -t 80 PlasmoDB-59_Pfalciparum3D7_Genome.fasta trimmed_read_pair1.fastq trimmed_read_pair2.fastq

# Sorting and converting alignment
samtools sort -@ 80 -O BAM -o sample.sorted.bam sample1.sam

# Adding readgroup
java -Xmx10G -jar picard.jar AddOrReplaceReadGroups --INPUT sample.sorted.bam --OUTPUT sample.sorted.rg.bam --RGLB gDNA_Illumina_DNA_Prep  --RGPL ILLUMINA --RGPU NOVASEQ --RGSM sample4

# PCR duplicate removal 
java -Xmx10G -jar picard.jar MarkDuplicates --INPUT sample.sorted.rg.bam --METRICS_FILE sample.metrices.txt --OUTPUT sample.sorted.rg.dup.bam --REMOVE_DUPLICATES true --ASSUME_SORT_ORDER coordinate

# Base re-calibrator (Cross data variants obtained from 10.1101/gr.203711.115)
gatk BaseRecalibrator -I sample.sorted.rg.dup.bam -R PlasmoDB-59_Pfalciparum3D7_Genome.fasta --known-sites 3d7_hb3.combined.final.vcf.gz --known-sites 7g8_gb4.combined.final.vcf.gz --known-sites hb3_dd2.combined.final.vcf.gz -O sample.recal_data.table

# Writing recalibrated 
gatk ApplyBQSR -R PlasmoDB-59_Pfalciparum3D7_Genome.fasta -I sample.sorted.rg.dup.bam --bqsr-recal-file sample.recal_data.table -O sample.sorted.rg.dup.recal.bam

# GVCF Calling
gatk --java-options "-Xmx10g" HaplotypeCaller --reference PlasmoDB-59_Pfalciparum3D7_Genome.fasta --input sample.sorted.rg.dup.recal.bam --output sample.g.vcf --sample-ploidy 1 --emit-ref-confidence BP_RESOLUTION --verbosity ERROR

# Merging GVCF
gatk --java-options "-Xmx150g" CombineGVCFs -R PlasmoDB-59_Pfalciparum3D7_Genome.fasta --variant sample1.g.vcf --variant sample2.g.vcf ....... --variant samplen.g.vcf -O merged_sample.g.vcf

# Genotyping GVCF
gatk --java-options "-Xmx150g" GenotypeGVCFs --sample-ploidy 1 --max-alternate-alleles 48 -R PlasmoDB-59_Pfalciparum3D7_Genome.fasta -V merged_sample.g.vcf -O genotyped.vcf
