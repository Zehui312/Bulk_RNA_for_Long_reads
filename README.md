# 🧬Bulk_RNA_for_Long_reads

This pipeline is designed for processing Oxford Nanopore **bacterial sequencing** data, converting raw **POD5 files** into aligned **BAM files** for downstream analysis.

Raw signals are first basecalled to generate FASTQ reads, followed by quality control and filtering to obtain clean reads. The cleaned reads are then demultiplexed by barcode, trimmed to remove adapters and low-quality regions, and finally aligned to a reference genome.

The output BAM files can be directly used for downstream analyses.

## 📌Table of Contents

- [1. Workflow](#1-workflow)
- [2. Create Environment for Bulk_RNA_for_Long_reads](#2-create-environment-for-bulk_rna_for_long_reads)
- [3. Fill meta_data.csv](#3-fill-meta_datacsv)
- [4. Fill demultiplex_table.csv](#4-fill-demultiplex_tablecsv)
- [5. Output Interpretation](#5-output-interpretation)


## 1.💡Workflow
<img src="/img/workflow.png" width="500">


## 2. ⚙️Create Environment for Bulk_RNA_for_Long_reads

All required software dependencies are listed in the YAML file. You can create the environment and install all tools with:
```bash
mamba env create -f ont_env.yml
```
After creating the environment, activate it:
```bash
conda activate ont_env
```
---

## 3. 📂Fill meta_data.csv
You just need to enter your specific parameters into **meta_data.csv**, and then run the pipeline.

| Parameter | Description | Pipeline Step |
|-----------|-------------|----------------|
| Sample_name | Sample identifier | - |
| pod5_path | Path to POD5 files (raw Nanopore signal data) | **1_1basecalling** |
| appendix_path | Path to appendix directory (assign after cloning repository) | - |
| output_path | Path to output directory | - |
| reference_genome | Path to reference genome file (FASTA) | - |
| basecalling_module | Basecalling software/module (e.g., dorado, guppy) | **1_1basecalling** |
| trim_approach | Chopper trimming method (e.g., trim-by-quality, best-read-segment, split-by-low-quality; see [Chopper docs](https://github.com/wdecoster/chopper)) | **1_2Chopper** |
| trim_cutoff | Quality or score cutoff for trimming | **1_2Chopper** |
| QC_quality | Minimum read quality threshold | **1_2QC** |
| min_length | Minimum read length cutoff | **1_2QC** |
| max_length | Maximum read length cutoff | **1_2QC** |
| kit_name | Library preparation kit name (e.g., SQK-RPB114-24) | **2_Demultiplex** |
| demux_table | Path to barcode/sample mapping table | **2_Demultiplex** |
| adapter_5 | 5' adapter sequence | **3_Trim** |
| adapter_3 | 3' adapter sequence | **3_Trim** |
| min_run_length | Minimum poly(A) length for trimming | **3_Trim** |
| Threads | Number of CPU threads | - |
| Memory | Memory allocation (e.g., 16G, 32G) | - |


## 4. 📂Fill demultiplex_table.csv
After filling the **meta_data.csv** and **demultiplex_table.csv**, and you can run this pipeline. 
```bash
sh Run_Bulk_RNA_long_pipeline.sh
```

## ⚠️ Notes
- Ensure metadata consistency
- Check barcode table carefully
- Recommended ≥3 replicates for DE analysis


## 📊5. Output Inteperation
<details>
<summary> 1_1_dorado </summary>

```
├── *.fastq (The each pod5 files were transfer into fastq file)
├── *.err (log err file)
├── *.out (log out file)
```
</details>

<details>
<summary> 1_2_QC_stat </summary>

```
├── JB251030_1_basecalling.fastq.gz (merge all *.fastq at 1_1_dorado into a zip file)
├── JB251030_2_chopper.fastq.gz (the fastq file after chopper)
├── JB251030_3_filtered.fastq.gz (the fastq file after QC)
├── JB251030_NanoPlot (NanoPlot stat JB251030_3_filtered.fastq.gz file)
```

</details>

<details>
<summary> 2-1_Demultiplexing </summary>

```
├── *barcode*.fastq (B251030_3_filtered.fastq.gz was demultiplex into seperated fastq files)
├── Demux_stat.txt (Stat the length of each *barcode*.fastq file)
```

</details>

<details>
<summary> 2-2_rename </summary>

```
├── *.fastq (The *barcode*.fastq files were rename based on demultiplex_table.csv)
├── demux_stat.txt (Stat the length of each *.fastq file)
```

</details>

<details>
<summary> 3_Trim_adapter </summary>

```
├── *.adapter_trim.fastq.gz (The fastq file after trim adapter)
├── *.cleaned.fastq.gz (The fastq file after PolyA/T)
├── Trim_adapter_stat.txt (Stat the length of each *.cleaned.fastq.gz)
```

</details>

<details>
<summary> 4_1_mapping_no_trim </summary>
The file name based on input fastq and reference genome. For examle, sample3_3.ref_sample_1, sample3_3 is the input fastq file, sample_1 is the reference genome.
```
├── *.html (Fastp output file, open with your browser)
├── *.sam (sam file after mapping to genome)
├── *.alignment_stats.txt (mapping rate)
```

</details>

<details>
<summary> 4_2_mapping_trim </summary>
The output is sample as 4_1_mapping_no_trim. The only different is the input fastq file. 4_1_mapping_no_trim input is fastq file without trim, 4_2_mapping_trim input i fastq file with trim.
```

```

</details>

<details>
<summary> 5_total_stat </summary>

```
├── 1_QC_stat.txt (Check 1_1basecalling and 1_2Chopper+QC)
├── 2_demux_stat.txt (Check 2_Demultiplex)
├── 3_Trim_adapter_stat.txt (Check 3_Trim)
├── 4_1_mapping_no_trim_stat.txt (Check 4_Mapping, the input fastq without trim adapter)
├── 4_2_mapping_trim_stat.txt (Check 4_Mapping, the input fastq with trim adapter)
```

</details>
