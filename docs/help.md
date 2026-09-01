salmon 2.7.0-r1

Purpose:
  Build Salmon transcript indexes and quantify transcript abundance from
  RNA-seq reads, alignments, or RAD files.

Usage:
  taf-salmon -- --help
  taf-salmon -- --version
  taf-salmon salmon index [OPTIONS]
  taf-salmon salmon quant [OPTIONS]
  taf-salmon salmon quantmerge [OPTIONS]

Common tasks:
  taf-salmon salmon index \
    -t transcripts.fa -i salmon_index -k 31 -p 8

  taf-salmon salmon quant \
    -i salmon_index -l A \
    -1 reads_1.fq.gz -2 reads_2.fq.gz \
    -o sample_quant -p 8

  taf-salmon salmon quant \
    -i salmon_index -l A -r reads.fq.gz \
    --geneMap genes.tsv -o sample_quant -p 8

  taf-salmon salmon quantmerge \
    --quants sample1_quant sample2_quant \
    --names sample1 sample2 --column TPM -o merged_tpm.tsv

Required inputs:
  index:  -t transcript FASTA; optional -d decoy-name list
  quant:  -i Salmon 2.7 index plus -r single-end or -1/-2 paired reads
          Alternatively use -a transcript alignments, genome alignments with
          --annotation, or --rad FILE.
  Inputs and output locations are user/project paths; no reference database or
  model is bundled or downloaded automatically.

Index compatibility:
  Salmon 2.7 writes index format v2. Every index made by Salmon 2.6 or earlier
  must be rebuilt with salmon index. Older indexes fail with a rebuild message;
  do not reuse them for this app.

Common options:
  -p INT                 shared execution-slot budget
  -l FORMAT              library type, commonly A for automatic detection
  --sketch               use sketch/pseudoalignment mapping
  --decoder MODE         auto, serial, parallel, or parallel=N
  --geneMap FILE         transcript-to-gene TSV or GTF/GFF, compressed or plain
  --writeRad FILE        retain RAD mappings while quantifying
  --rad FILE             quantify a RAD file directly
  --writeBam FILE        write unsorted BGZF BAM mappings
  --writeSam FILE        write unsorted SAM mappings
  --radScratchDir DIR    relocate the temporary intermediate RAD
  --skipQuant            stop after mapping and keep the output RAD

Key outputs:
  quant.sf                       transcript abundance table
  quant.genes.sf                 gene-level table when --geneMap is used
  aux_info/meta_info.json        run, mapping, and inference metadata
  logs/salmon_quant.log          quantification log
  quantmerge -o FILE             merged abundance matrix

Immediate notes:
  Index and quant output directories must be writable. Default quantification
  also needs temporary RAD space; use --radScratchDir for another volume.
  --writeBam and --writeSam outputs are unsorted and unindexed.
  Use the explicit executable form "taf-salmon salmon quant ..." because
  "taf-salmon quant ..." may treat quant as a container executable.
  For paths containing spaces, prefer whitespace-free paths or use the literal
  inner-quote form documented in the README.

Backends:
  Docker, Podman, and Apptainer use the same wrapper commands and need no GPU,
  device, port, network, database, model, or special runtime argument. Select a
  backend with TAFFISH_CONTAINER_BACKEND=docker, podman, or apptainer.

More help:
  taf-salmon salmon index --help
  taf-salmon salmon quant --help
  taf-salmon salmon quantmerge --help
  https://combine-lab.github.io/salmon/
  https://github.com/COMBINE-lab/salmon/releases/tag/v2.7.0

Wrapper options:
  taf-salmon --help       Show this TAFFISH help.
  taf-salmon --version    Show TAFFISH package version.
  taf-salmon --compile    Print the generated wrapper shell.
  taf-salmon -- --help    Pass an option-leading argument to salmon.
