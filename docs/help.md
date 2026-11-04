taf-salmon 2.11.0-r1 — index transcripts and quantify RNA-seq abundance.

Usage:
  taf-salmon salmon SUBCOMMAND [OPTIONS]
  taf-salmon --help                Wrapper help
  taf-salmon -- --help             Upstream help
  taf-salmon -- --version          Upstream version

Common tasks:
  taf-salmon salmon index -t transcripts.fa -i salmon_index -k 31 -p 8
  taf-salmon salmon quant -i salmon_index -l A \
    -1 reads_1.fq.gz -2 reads_2.fq.gz -o sample_quant -p 8
  taf-salmon salmon quant -i salmon_index -l A -r reads.fq.gz \
    --geneMap genes.tsv -o single_quant -p 8
  taf-salmon salmon quantmerge --quants sample1_quant sample2_quant \
    --names sample1 sample2 --column TPM -o merged_tpm.tsv

Inputs and compatibility:
  index: transcript FASTA; optional -d decoy-name list.
  quant: index and reads, or -a transcript alignments, genome alignments with
         --annotation genes.gtf, or --rad FILE.
  Upgrading from 2.8 or earlier? Rebuild from the original FASTA and decoys into
  a NEW directory (format v3). Existing v3 indexes from 2.9/2.10 can be reused.
  RAD v2 from current piscem is accepted; Salmon still writes legacy RAD.
  No production reference, index, model or read set is bundled/downloaded.

Options for the current task:
  -l A                   detect library type automatically
  -p INT                 shared decoding/mapping budget (capped at available threads)
  --sketch               sketch/pseudoalignment quantification
  --decoder MODE         auto, serial, parallel, or parallel=N
  --geneMap FILE         gene TSV or GTF/GFF, plain or compressed
  --writeRad FILE        retain RAD mappings
  --rad FILE             quantify a legacy or v2 RAD file
  --writeBam FILE         export unsorted, unindexed BGZF BAM mappings
  --writeSam FILE         export unsorted SAM mappings
  --radScratchDir DIR    choose writable space for the intermediate RAD
  --skipQuant            stop after mapping and retain RAD; no quant.sf
  --emAccel squarem      optional acceleration with the default VBEM
  --useEM --emAccel daarem  DAAREM requires plain EM, not default VBEM

Key outputs:
  quant.sf                      transcript abundance
  quant.genes.sf                gene abundance with --geneMap
  aux_info/meta_info.json       mapping/inference metadata
  logs/salmon_quant.log         run log
  Default quantification deletes its intermediate RAD on success.

Backend selection:
  export TAFFISH_CONTAINER_BACKEND=docker
  Or select podman or apptainer; the analysis commands are unchanged.
  Apptainer requires native Linux. No GPU, display or service port is needed.

Optional administrator-prepared index outside the working directory:
  INDEX_ROOT=/opt/taffish/references/salmon/PROJECT/VERSION/index
  Docker:
    TAFFISH_CONTAINER_BACKEND=docker \
    TAFFISH_DOCKER_RUN_ARGS="-v $INDEX_ROOT:/reference:ro" \
      taf-salmon salmon quant -i /reference -l A -r reads.fq.gz -o result
  Podman:
    TAFFISH_CONTAINER_BACKEND=podman \
    TAFFISH_PODMAN_RUN_ARGS="-v $INDEX_ROOT:/reference:ro" \
      taf-salmon salmon quant -i /reference -l A -r reads.fq.gz -o result
  Apptainer:
    TAFFISH_CONTAINER_BACKEND=apptainer \
    TAFFISH_APPTAINER_RUN_ARGS="--bind $INDEX_ROOT:/reference:ro" \
      taf-salmon salmon quant -i /reference -l A -r reads.fq.gz -o result
  Use a resolved physical mount root without spaces; outputs stay in the
  writable working directory. Select the index explicitly with -i.

Immediate notes:
  Always use a fresh output directory. A rerun can remove old quant.sf and
  quant.genes.sf before detecting a bad input. Zero mapped reads returns nonzero
  even when output files exist; inspect the exit code and aux_info/meta_info.json.
  For streamed input, use a FIFO visible to Salmon inside the container; a host
  shell's /dev/fd paths may not cross the container boundary. See README for an example.
  Ensure enough writable scratch space for indexing and intermediate RAD.
  For ordinary argument paths containing spaces, preserve literal quotes:
    taf-salmon salmon index -t '"transcripts with spaces.fa"' -i index -k 31
  Include salmon before a subcommand; taf-salmon quant may run another program.
  Integrated salmon alevin was removed upstream; use the alevin-fry ecosystem.

More help:
  taf-salmon salmon quant --help
  https://combine-lab.github.io/salmon/
  https://github.com/taffish/salmon
