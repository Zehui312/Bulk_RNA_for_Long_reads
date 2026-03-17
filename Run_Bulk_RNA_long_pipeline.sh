meta_data=./table/meta_data.csv

cat $meta_data |grep -v "^Sample_name" | while read line; do
sample_name=$(echo $line | cut -d ',' -f 1)
pod5_path=$(echo $line | cut -d ',' -f 2)
appendix_path=$(echo $line | cut -d ',' -f 3)
output_dir=$(echo $line | cut -d ',' -f 4)
reference_genome=$(echo $line | cut -d ',' -f 5)
basecalling_module=$(echo $line | cut -d ',' -f 6)
trim_approach=$(echo $line | cut -d ',' -f 7)
trim_cutoff=$(echo $line | cut -d ',' -f 8)
QC_quality=$(echo $line | cut -d ',' -f 9)
min_length=$(echo $line | cut -d ',' -f 10)
max_length=$(echo $line | cut -d ',' -f 11)
kit_name=$(echo $line | cut -d ',' -f 12)
demux_table=$(echo $line | cut -d ',' -f 13)
adapter_5=$(echo $line | cut -d ',' -f 14)
adapter_3=$(echo $line | cut -d ',' -f 15)
min_run_length=$(echo $line | cut -d ',' -f 16)
rounds=$(echo $line | cut -d ',' -f 17)
thread_num=$(echo $line | cut -d ',' -f 18)
memory=$(echo $line | cut -d ',' -f 19)
  echo "sh ./appendix/script/Bulk_RNAseq_long_pipeline.sh --sample-name $sample_name --pod5-path $pod5_path --appendix-path $appendix_path --output-dir $output_dir --reference $reference_genome --basecalling-module $basecalling_module --trim-approach $trim_approach --trim-cutoff $trim_cutoff --qc-quality $QC_quality --min-length $min_length --max-length $max_length --kit-name $kit_name --demux-table $demux_table --adapter-5 $adapter_5 --adapter-3 $adapter_3 --min-run-length $min_run_length --threads $thread_num --memory $memory" 
done > ./appendix/script/run_pipeline.sh

mkdir -p ./logs/    
count=1
while read runcode; do
    bsub -P Bulk_RNA_${count} -J Bulk_RNA_${count} -n 2 -R "rusage[mem=8GB]" -eo ./logs/Bulk_RNA_${count}.err -oo ./logs/Bulk_RNA_${count}.out $runcode
    count=$((count + 1))
done < ./appendix/script/run_pipeline.sh

