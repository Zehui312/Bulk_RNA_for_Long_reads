#!/bin/bash
# Default values
# sample_name="Serum"
# pod5_path="/research/groups/ma1grp/home/zyu/work_2026/RNA_seq_3_March/Bulk_RNA_pipeline/pod5_test"
# appendix_path="/research/groups/ma1grp/home/zyu/work_2026/RNA_seq_3_March/Bulk-RNA-seq-for-Nanopore-long-reads/appendix"
# output_dir="/research/groups/ma1grp/home/zyu/work_2026/RNA_seq_3_March/test_output"
# reference_genome="/research/groups/ma1grp/home/zyu/work_2026/RNA_seq_3_March/Bulk-RNA-seq-for-Nanopore-long-reads/appendix/ref/sample_1.fna"
# basecalling_module="${appendix_path}/model_files/dna_r10.4.1_e8.2_400bps_sup@v5.0.0"
# trim_approach="best-read-segment"
# trim_cutoff=10
# QC_quality=10
# min_length=30
# max_length=3000
# kit_name="SQK-RPB114-24"
# demux_table="/research/groups/ma1grp/home/zyu/work_2026/RNA_seq_3_March/Bulk-RNA-seq-for-Nanopore-long-reads/table/demultiplex_table.csv"
# adapter_5="TGATATTGCTTTNNNNTTNNNNTTNNNNTTNNNNTTTGGG"
# adapter_3="CCCAAANNNNAANNNNAANNNNAANNNNAAGCAATATCA"
# min_run_length=12


# Parse command line arguments
while getopts "s:p:a:o:r:m:t:c:q:l:x:k:d:f:g:n:b:e:h-:" opt; do
    case $opt in
        s) sample_name="$OPTARG" ;;
        p) pod5_path="$OPTARG" ;;
        a) appendix_path="$OPTARG" ;;
        o) output_dir="$OPTARG" ;;
        r) reference_genome="$OPTARG" ;;
        m) basecalling_module="$OPTARG" ;;
        t) trim_approach="$OPTARG" ;;
        c) trim_cutoff="$OPTARG" ;;
        q) QC_quality="$OPTARG" ;;
        l) min_length="$OPTARG" ;;
        x) max_length="$OPTARG" ;;
        k) kit_name="$OPTARG" ;;
        d) demux_table="$OPTARG" ;;
        f) adapter_5="$OPTARG" ;;
        g) adapter_3="$OPTARG" ;;
        n) min_run_length="$OPTARG" ;;
        b) threads="$OPTARG" ;;
        e) memory="$OPTARG" ;;
        h) echo "Usage: $0 [--sample-name|-s sample_name] [--pod5-path|-p pod5_path] [--appendix-path|-a appendix_path] [--output-dir|-o output_dir] [--reference|-r reference] [--basecalling-module|-m basecalling_module] [--trim-approach|-t trim_approach] [--trim-cutoff|-c trim_cutoff] [--qc-quality|-q QC_quality] [--min-length|-l min_length] [--max-length|-x max_length] [--kit-name|-k kit_name] [--demux-table|-d demux_table] [--adapter-5|-f adapter_5] [--adapter-3|-g adapter_3] [--min-run-length|-n min_run_length] [--threads|-b threads] [--memory|-e memory]"; exit 0 ;;
        -) case "${OPTARG}" in
            sample-name) sample_name="${!OPTIND}"; ((OPTIND++)) ;;
            pod5-path) pod5_path="${!OPTIND}"; ((OPTIND++)) ;;
            appendix-path) appendix_path="${!OPTIND}"; ((OPTIND++)) ;;
            output-dir) output_dir="${!OPTIND}"; ((OPTIND++)) ;;
            reference) reference_genome="${!OPTIND}"; ((OPTIND++)) ;;
            basecalling-module) basecalling_module="${!OPTIND}"; ((OPTIND++)) ;;
            trim-approach) trim_approach="${!OPTIND}"; ((OPTIND++)) ;;
            trim-cutoff) trim_cutoff="${!OPTIND}"; ((OPTIND++)) ;;
            qc-quality) QC_quality="${!OPTIND}"; ((OPTIND++)) ;;
            min-length) min_length="${!OPTIND}"; ((OPTIND++)) ;;
            max-length) max_length="${!OPTIND}"; ((OPTIND++)) ;;
            kit-name) kit_name="${!OPTIND}"; ((OPTIND++)) ;;
            demux-table) demux_table="${!OPTIND}"; ((OPTIND++)) ;;
            adapter-5) adapter_5="${!OPTIND}"; ((OPTIND++)) ;;
            adapter-3) adapter_3="${!OPTIND}"; ((OPTIND++)) ;;
            min-run-length) min_run_length="${!OPTIND}"; ((OPTIND++)) ;;
            threads) threads="${!OPTIND}"; ((OPTIND++)) ;;
            memory) memory="${!OPTIND}"; ((OPTIND++)) ;;
            *) echo "Invalid option: --${OPTARG}"; exit 1 ;;
           esac ;;
        *) echo "Invalid option: -$OPTARG"; exit 1 ;;
    esac
done


trim_cutadapt_script=${appendix_path}/script/trim_cutadapt.sh
trim_polyAT_script=${appendix_path}/script/polyAT_split_keep_longer.py 
mapping_script=${appendix_path}/script/mapping_ont_bulk.sh
jobs_check_shell=${appendix_path}/script/Jobs_check.sh


out_put_path=${output_dir}/${sample_name}
if [ ! -d "$out_put_path" ]; then
    mkdir -p "$out_put_path"
fi

echo "The parameters used for this pipeline are:"
echo "Sample name: $sample_name"
echo "Pod5 path: $pod5_path"
echo "Appendix path: $appendix_path"
echo "Output directory: $output_dir"
echo "Reference genome: $reference_genome"
echo "Basecalling module: $basecalling_module"
echo "Trim approach: $trim_approach"
echo "Trim cutoff: $trim_cutoff"
echo "QC quality: $QC_quality"
echo "Minimum read length: $min_length"
echo "Maximum read length: $max_length"
echo "Kit name: $kit_name"
echo "Demultiplexing table: $demux_table"
echo "Adapter 5 sequence: $adapter_5"
echo "Adapter 3 sequence: $adapter_3"
echo "Minimum run length: $min_run_length"

echo "Threads: $threads"
memory=$(echo ${memory} | tr -d '\r')
echo "Memory per job: ${memory}GB"
#=================================================================
#+++++++++++++++++++++++Step 1 basecalling +++++++++++++++++++++++
#=================================================================
mkdir ${out_put_path}/1_1_dorado
cd ${out_put_path}/1_1_dorado

# Step 1 generate dorado basecalling script 
ls ${pod5_path} | grep "pod5" | cut -f 1 -d "." | awk -v basecalling_module=${basecalling_module} -v pod5_path=${pod5_path} '{print "dorado basecaller "basecalling_module" "pod5_path"/"$1".pod5 --no-trim --emit-fastq > "$1".fastq"}' > basecalling.sh

# Step 2 submit dorado basecalling jobs
count=1
while read runcode; do
    bsub -q gpu -gpu "num=1/host" -R a100_80g -R "rusage[mem=16GB]" -P ${sample_name}_basecalling_${count} -J ${sample_name}_basecalling_${count} -eo ${sample_name}_basecalling_${count}.err -oo ${sample_name}_basecalling_${count}.out $runcode
    count=$((count+1))
done < basecalling.sh

sh ${jobs_check_shell} -f basecalling.sh -l ${sample_name}_basecalling

# #=================================================================
# #+++++++++++++++++++++++Step 1_2 QC and stat++++++++++++++++++++++
# #=================================================================
mkdir -p ${out_put_path}/1_2_QC_stat
cd ${out_put_path}/1_2_QC_stat
# Step 1 merge dorado fastq files
cat ${out_put_path}/1_1_dorado/*fastq | gzip > ${sample_name}_1_basecalling.fastq.gz 

# Step 2 chopper trim and filter fastq files based on quality
chopper --trim-approach ${trim_approach} --cutoff ${trim_cutoff} -i ${sample_name}_1_basecalling.fastq.gz | gzip > ${sample_name}_2_chopper.fastq.gz

# Step 3 filter fastq files based on length and quality
zcat ${sample_name}_2_chopper.fastq.gz | NanoFilt -l ${min_length} --maxlength ${max_length} -q ${QC_quality} | gzip > ${sample_name}_3_filtered.fastq.gz

mkdir log_files

# Step 4 NanoPlot and Seqkit stat
bsub -P ${sample_name}_NanoPlot -J ${sample_name}_NanoPlot -n ${threads} -R "rusage[mem=${memory}GB]" -eo log_files/${sample_name}_NanoPlot.err -oo log_files/${sample_name}_NanoPlot.out "
NanoPlot --fastq ${sample_name}_3_filtered.fastq.gz -o ${sample_name}_NanoPlot "

bsub -P ${sample_name}_Stats -J ${sample_name}_Stats -n ${threads} -R "rusage[mem=${memory}GB]" -eo log_files/${sample_name}_Stats.err -oo log_files/${sample_name}_Stats.out "
seqkit stat *.fastq.gz > ${sample_name}_QC_stat.txt"


# #=================================================================
# #+++++++++++++++++++++++Step 2-1  Demultiplexing +++++++++++++++++
# #=================================================================
mkdir -p ${out_put_path}/2-1_Demultiplexing
cd ${out_put_path}/2-1_Demultiplexing
mkdir -p ${out_put_path}/2-1_Demultiplexing/input_fastq
ln -s ${out_put_path}/1_2_QC_stat/${sample_name}_3_filtered.fastq.gz ${out_put_path}/2-1_Demultiplexing/input_fastq/

dorado demux -t 8 --output-dir ${out_put_path}/2-1_Demultiplexing --emit-fastq --kit-name ${kit_name} ${out_put_path}/2-1_Demultiplexing/input_fastq

seqkit stat *.fastq > Demux_stat.txt

#=================================================================
#+++++++++++++++++++++++Step 2-2 rename ++++++++++++++++++++++++++
#=================================================================
mkdir -p ${out_put_path}/2-2_rename
cd ${out_put_path}/2-2_rename

tail -n +2 "$demux_table" | while IFS=, read -r barcode sample ; do
    sample=${sample//$'\r'/}
    file=$(find ${out_put_path}/2-1_Demultiplexing -name "*${barcode}*.fastq")
    if [ -f "$file" ]; then
        ln -s "$file" "${sample}.fastq"
    fi
done

seqkit stat *.fastq > demux_stat.txt

# #=================================================================
# #+++++++++++++++++++++++Step 3  Trim adapter +++++++++++++++++++++
# #=================================================================
mkdir -p ${out_put_path}/3_Trim_adapter
cd ${out_put_path}/3_Trim_adapter

ln -s ${out_put_path}/2-2_rename/*.fastq ./



cp ${trim_polyAT_script} .

ls *.fastq | while read fqfile; do
    echo "sh ${trim_cutadapt_script} -i ${fqfile} -s ${fqfile%%.*} -g ${adapter_5} -a ${adapter_3} -m ${min_length} -r 2 -l ${min_run_length}"
done > run_trim_adapt_polyAT.sh

count=1
while read runcode; do
    bsub -P trim_${count} -J trim_${count} -n 2 -R "rusage[mem=8GB]" -eo trim_${count}.err -oo trim_${count}.out $runcode
    count=$((count + 1))
done < run_trim_adapt_polyAT.sh

sh ${jobs_check_shell} -f run_trim_adapt_polyAT.sh -l trim_

bsub -P stat -J stat -n 2 -R "rusage[mem=8GB]" -eo stat.err -oo stat.out "
seqkit stat *cleaned.fastq.gz *.fastq > Trim_adapter_stat.txt"


#=================================================================
#+++++++++++++++++++++++Step 4-1 mapping with no trim adapter ++++
#=================================================================
mkdir -p ${out_put_path}/4_1_mapping_no_trim
cd ${out_put_path}/4_1_mapping_no_trim

ln -s ${out_put_path}/2-2_rename/*.fastq ./

ls *.fastq | while read fqfile; do
    echo "sh ${mapping_script} -i ${fqfile} -r  ${reference_genome}" 
done > run_mapping_no_trim.sh

count=1
while read runcode; do
    bsub -P ${sample_name}_mapping_no_trim_${count} -J ${sample_name}_mapping_no_trim_${count} -n ${threads} -R "rusage[mem=${memory}GB]" -eo ${sample_name}_mapping_no_trim_${count}.err -oo ${sample_name}_mapping_no_trim_${count}.out $runcode
    count=$((count +1))
done < run_mapping_no_trim.sh

sh ${jobs_check_shell} -f run_mapping_no_trim.sh -l ${sample_name}_mapping_no_trim

#=================================================================
#+++++++++++++++++++++++Step 4-2 mapping withtrim adapter ++++++++
#=================================================================
mkdir -p ${out_put_path}/4_2_mapping_trim
cd ${out_put_path}/4_2_mapping_trim

ln -s ${out_put_path}/3_Trim_adapter/*cleaned.fastq.gz ./

ls *cleaned.fastq.gz | while read fqfile; do
    echo "sh ${mapping_script} -i ${fqfile} -r  ${reference_genome}" 
done > run_mapping_trim.sh

count=1
while read runcode; do
    bsub -P ${sample_name}_mapping_trim_${count} -J ${sample_name}_mapping_trim_${count} -n ${threads} -R "rusage[mem=${memory}GB]" -eo ${sample_name}_mapping_trim_${count}.err -oo ${sample_name}_mapping_trim_${count}.out $runcode
    count=$((count +1))
done < run_mapping_trim.sh

sh ${jobs_check_shell} -f run_mapping_trim.sh -l ${sample_name}_mapping_trim

#=================================================================
#+++++++++++++++++++++++Step 5 Total stat ++++++++++++++++++++++++
#=================================================================
mkdir -p ${out_put_path}/5_total_stat
cd ${out_put_path}/5_total_stat
cp ${out_put_path}/1_2_QC_stat/${sample_name}_QC_stat.txt 1_QC_stat.txt
cp ${out_put_path}/2-2_rename/demux_stat.txt 2_demux_stat.txt
cp ${out_put_path}/3_Trim_adapter/Trim_adapter_stat.txt 3_Trim_adapter_stat.txt

grep "primary mapped " ${out_put_path}/4_1_mapping_no_trim/*alignment_stats.txt | sed 's/^.*mapping_no_trim//g' |sed 's/\.alignment_stats.*(/ /g'|sed 's/:.*$//g' > 4_1_mapping_no_trim_stat.txt
grep "primary mapped " ${out_put_path}/4_2_mapping_trim/*alignment_stats.txt | sed 's/^.*mapping_trim//g' |sed 's/\.alignment_stats.*(/ /g'|sed 's/:.*$//g' > 4_2_mapping_trim_stat.txt


mkdir no_trim_bam_files trim_bam_files
mv ${out_put_path}/4_1_mapping_no_trim/*sorted_reads* ./no_trim_bam_files/
mv ${out_put_path}/4_2_mapping_trim/*sorted_reads* ./trim_bam_files/