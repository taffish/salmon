salmon 2.4.1-r1

TAFFISH wrapper for Salmon v2.4.1 from COMBINE-lab.
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
    --writeBam mappings.bam --bamCompressThreads 2 \
    -o sample_quant -p 8

  taf-salmon salmon quant \
    -i salmon_index -l A -r reads.fq.gz \
    --writeRad sample.rad -o mapping_quant -p 8

  taf-salmon salmon quant \
    --rad sample.rad --fldPolicy prior \
    --fldMean 250 --fldSD 25 \
    -o rad_quant -p 8

  taf-salmon salmon quantmerge \
    --quants sample1_quant sample2_quant \
    --names sample1 sample2 --column TPM \
    -o merged_tpm.tsv

Command Mode:
  command_mode is enabled. Use the explicit executable form for upstream
  subcommands, for example "taf-salmon salmon quant ...". A form such as
  "taf-salmon quant ..." is ambiguous because quant may be interpreted as a
  container executable. Use "taf-salmon -- --version" for option-leading
  arguments to the default salmon command.

Salmon 2.4 Features:
  --writeBam FILE writes retained mappings as unsorted BGZF BAM.
  --writeSam writes retained mappings as SAM and aliases --writeMappings.
  --bamCompressThreads controls BAM compression concurrency.
  --fldPolicy baked|derive|prior controls fragment-length handling for RAD.
  --writeRad and --rad separate mapping from quantification.
  --deterministic enables reproducible reads-mode quantification.
  --sketch selects the sketch / pseudoalignment path.
  --emAccel squarem|daarem opts into EM/VBEM acceleration.

Compatibility:
  Salmon 2.4.1 keeps index_version = 1 and needs no index rebuild from 2.4.0.
  Rebuild Salmon 2.0.x or older C++ / pufferfish indices. Version 2.4.1 fixes
  a RAD reader race that could yield zero or partial counts in quant --rad,
  --deterministic, or genome projection (-a plus --annotation), especially at
  low thread counts. Plain -a and ordinary reads-mode mapping were unaffected.

  salmon alevin is no longer implemented and only prints a migration message;
  use alevin-fry for current single-cell workflows. Some old C++ options are
  removed or retained only as compatibility no-ops.

Inputs And Outputs:
  References, decoys, annotations, alignments, RAD files, and reads are supplied
  by the user. Quantification normally writes quant.sf plus JSON metadata under
  the requested output directory. BAM/SAM mapping exports are not sorted or
  indexed. Reference data and external aligners are not bundled.

Package:
  Image: ghcr.io/taffish/salmon:2.4.1-r1
  Backends/platforms: Docker or Podman; native linux/amd64, linux/arm64
  Runtime version: salmon 2.4.1
  Runtime support: GNU libraries, CA certificates, procps
  Licenses: Apache-2.0 (TAFFISH app); BSD-3-Clause (upstream)
  Citation DOI: 10.1038/nmeth.4197
  Release: https://github.com/COMBINE-lab/salmon/releases/tag/v2.4.1
