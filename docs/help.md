salmon 2.5.0-r1

TAFFISH wrapper for Salmon v2.5.0 from COMBINE-lab.
Salmon performs transcript-level RNA-seq quantification from reads,
transcriptome alignments, genome alignments plus annotation, or RAD files.

Install:
  taf update
  taf install salmon

Usage:
  taf-salmon --help
  taf-salmon --version
  taf-salmon -- --help
  taf-salmon salmon index ...
  taf-salmon salmon quant ...
  taf-salmon salmon quantmerge ...
  taf-salmon salmon debug-map ...

Wrapper Options:
  --help       show this TAFFISH help
  --version    show TAFFISH package version
  --compile    print generated shell code
  --           pass option-leading arguments to the default command

Common Commands:
  salmon index       build a Salmon 2 transcript index
  salmon quant       quantify from reads, alignments, or RAD
  salmon quantmerge  merge columns from Salmon quantification outputs
  salmon debug-map   print diagnostic per-read mapping details

Examples:
  taf-salmon salmon index \
    -t transcripts.fa -i salmon_index -k 31 -p 8

  taf-salmon salmon quant \
    -i salmon_index -l A \
    -1 reads_1.fq.gz -2 reads_2.fq.gz \
    -o sample_quant -p 8

  taf-salmon salmon quant \
    -i salmon_index -l A -r reads.fq.gz \
    --decoder serial --geneMap genes.gtf.gz \
    -o sample_quant -p 8

  taf-salmon salmon quant \
    -i salmon_index -l A -r reads.fq.gz \
    --writeBam mappings.bam --bamCompressThreads 2 \
    -o sample_quant -p 8

  taf-salmon salmon quant \
    --rad sample.rad --fldPolicy prior \
    --fldMean 250 --fldSD 25 -o rad_quant -p 8

  taf-salmon salmon quantmerge \
    --quants sample1_quant sample2_quant \
    --names sample1 sample2 --column TPM -o merged_tpm.tsv

Command Mode:
  Use the explicit executable form for upstream subcommands, for example
  "taf-salmon salmon quant ...". The shorter "taf-salmon quant ..." may treat
  quant as a container executable. Use "taf-salmon -- --version" for an
  option-leading argument to the default salmon command.

Salmon 2.5 Notes:
  -p is a shared execution-slot budget for compressed-input decoding and
  mapping. --decoder accepts auto, serial, parallel, or parallel=N;
  --threadPolicy accepts a reviewed JSON policy file.
  Compression is detected from content for reads, targets, alignments, and
  gene maps; gzip/BGZF, bzip2, xz, and zstd are supported.
  --writeBam/--writeSam exports are unsorted and unindexed.
  --writeRad and --rad separate mapping from quantification.
  --deterministic enables reproducible reads-mode quantification.
  --sketch selects the sketch / pseudoalignment path.

Compatibility:
  Salmon 2.5.0 keeps index_version = 1 and needs no index rebuild from 2.4.1.
  Rebuild Salmon 2.0.x or older C++ / pufferfish indices. salmon alevin only
  prints a migration message; use alevin-fry for current single-cell work.

Package:
  Image: ghcr.io/taffish/salmon:2.5.0-r1
  Backends/platforms: Docker or Podman; native linux/amd64, linux/arm64
  Runtime version: salmon 2.5.0
  Runtime support: GNU libraries, CA certificates, procps
  Licenses: Apache-2.0 (TAFFISH app); BSD-3-Clause (upstream)
  Citation DOI: 10.1038/nmeth.4197
  Release: https://github.com/COMBINE-lab/salmon/releases/tag/v2.5.0
