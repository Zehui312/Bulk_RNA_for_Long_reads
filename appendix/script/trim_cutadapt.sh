#!/bin/bash

# Default values


# Parse command line arguments
while getopts "i:s:g:a:m:r:l:h:" opt; do
    case $opt in
        i)
            input_fastq="$OPTARG"
            ;;
        s)
            sample_name="$OPTARG"
            ;;
        g)
            adapter_5="$OPTARG"
            ;;
        a)
            adapter_3="$OPTARG"
            ;;
        m)
            min_length="$OPTARG"
            ;;
        r)
            rounds="$OPTARG"
            ;;
        l)
            min_run_length="$OPTARG"
            ;;
        h)
            echo "Usage: $0 -i <input_fastq> -s <sample_name> -g <adapter_sequence> -a <adapter_sequence> -m <min_length> -r <rounds> -l <min_run_length>"
            echo "  -i: Input FASTQ file path"
            echo "  -s: Sample name for output files"
            echo "  -g: 5' adapter sequence"
            echo "  -a: 3' adapter sequence"
            echo "  -m: Minimum length for reads"
            echo "  -r: Number of rounds for polyAT trimming"
            echo "  -l: Minimum run length for polyAT trimming"
            echo "  -h: Show this help message"
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            echo "Use -h for help"
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

# Check if required arguments are provided
if [[ -z "$input_fastq" || -z "$sample_name" ]]; then
    echo "Error: Both -i (input_fastq) and -s (sample_name) are required."
    echo "Use -h for help"
    exit 1
fi


echo "Input FASTQ: $input_fastq"
echo "Sample Name: $sample_name"
echo "5' Adapter: $adapter_5"
echo "3' Adapter: $adapter_3"
echo "Minimum Length: $min_length"
echo "Rounds: $rounds"
echo "Minimum Run Length: $min_run_length"
echo "Starting adapter trimming with cutadapt..."

cutadapt -g "$adapter_5" -a "$adapter_3" -m "$min_length" -e 0.3 -o ${sample_name}_adapter_trim.fastq.gz ${input_fastq}
python polyAT_split_keep_longer.py -i ${sample_name}_adapter_trim.fastq.gz -o ${sample_name}_reads.cleaned.fastq.gz --min-run "$min_run_length" --rounds "$rounds" --min-len "$min_length" --drop-empty