# Bulk_RNA_for_Long_reads

This pipeline is designed for processing Oxford Nanopore **bacterial sequencing** data, converting raw **POD5 files** into aligned **BAM files** for downstream analysis.

Raw signals are first basecalled to generate FASTQ reads, followed by quality control and filtering to obtain clean reads. The cleaned reads are then demultiplexed by barcode, trimmed to remove adapters and low-quality regions, and finally aligned to a reference genome.

The output BAM files can be directly used for downstream analyses.

## Table of Contents

- [1. Workflow](#1-workflow)
- [2. Create Environment for Bulk_RNA_for_Long_reads](#2-create-environment-for-bulk_rna_for_long_reads)
- [3. Fill meta_data.csv](#3-fill-meta_datacsv)
- [4. Fill demultiplex_table.csv](#4-fill-demultiplex_tablecsv)
- [5. Output Interpretation](#5-output-interpretation)


## 1. Workflow
<img src="/img/workflow.png" width="500">


## 2. Create Environment for Bulk_RNA_for_Long_reads

All required software dependencies are listed in the YAML file. You can create the environment and install all tools with:
```bash
mamba env create -f ont_env.yml
```
After creating the environment, activate it:
```bash
conda activate ont_env
```
---

## 3. Fill meta_data.csv
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


## 4. Fill demultiplex_table.csv
After filling the **meta_data.csv** and **demultiplex_table.csv**, and you can run this pipeline. 
```bash
sh Run_Bulk_RNA_long_pipeline.sh
```


## 5. Output Inteperation
<details>
<summary> 1_umi_extract </summary>

```
├── Fresh_cell_barcode_counts.png
├── Fresh_cell_barcode_knee.png
├── Fresh_check_barcode.txt
├── Fresh_correction.txt
├── Fresh_error.txt
├── Fresh_ext.log
├── Fresh.R1.ext.fq.gz
├── Fresh.R2.ext.fq.gz
├── Fresh.wl.txt
├── raw_stat.txt
└── wl_Fresh.log 
```
</details>

<details>
<summary> 2_kraken </summary>

```
├── kraken_output
│   ├── Fresh_gut.report
│   ├── Fresh_gut_umi.report
│   └── Fresh_silva.report
├── kraken_tables
│   ├── CB_UMI_taxid.txt
│   ├── CB_UMI.txt
│   ├── Fresh_stat.txt
│   ├── kraken_table.txt
│   ├── species_list.txt
│   └── taxid.txt
├── remove_rRNA_ext.txt
└── umi_ext_stat.txt
```

</details>

<details>
<summary> 3_split </summary>

```
├── 0_filter
│   ├── filter_CB.txt
│   ├── filter_kraken_output.txt
│   ├── filter_stat.txt
│   ├── id_list.txt
├── 1_chunck_CB
│   └── cb_run.sh
├── 2_chunck_species
│   ├── all_cblist.txt
│   ├── caculating_count.py
│   ├── gp_run.sh
│   └── matrix.txt
└── all_cblist.txt
```

</details>

<details>
<summary> 4_calcultate_species </summary>

```
── 1_calcultate
│   ├── matrix.txt
│   ├── species_list.txt
│   ├── Top_species_stat.txt
│   ├── Top_species_taxid_filtered.txt
│   └── Top_species_taxid.txt
└── 2_extract_reads
    ├── R_1.stat.txt
    ├── R_2.stat.txt
    └── Top_species_taxid_filtered.txt
```

</details>

<details>
<summary> 5_mapping </summary>

```

```

</details>

<details>
<summary> 6_seurat </summary>

```

```

</details>

<details>
<summary> 7_total_stat </summary>

```

```

</details>

<details>
<summary> 2_kraken </summary>

```

```

</details>
