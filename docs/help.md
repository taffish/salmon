salmon 1.11.4-r1

TAFFISH wrapper for Salmon v1.11.4 from COMBINE-lab.
Salmon performs transcript-level RNA-seq quantification using indexing,
selective-alignment quantification, alignment-based quantification, and
quantification table merging.

Usage:
  taf-salmon --help
  taf-salmon --version
  taf-salmon -- --help
  taf-salmon -- --version
  taf-salmon salmon --help
  taf-salmon salmon --no-version-check index ...
  taf-salmon salmon --no-version-check quant ...
  taf-salmon salmon --no-version-check quantmerge ...

Wrapper Options:
  --help       show this TAFFISH help
  --version    show TAFFISH package version
  --compile    print generated shell code
  --           pass following option-leading arguments to the default command

Common Commands:
  salmon index       build a Salmon v1.11 SSHash-backed transcript index
  salmon quant       quantify transcript abundance from reads or alignments
  salmon quantmerge  merge multiple Salmon quantification outputs
  salmon --cite      print citation information

Examples:
  taf-salmon salmon --no-version-check index \
    -t transcripts.fa \
    -i salmon_index \
    -k 31 \
    -p 8

  taf-salmon salmon --no-version-check quant \
    -i salmon_index \
    -l A \
    -r reads.fq.gz \
    -o sample_quant \
    -p 8

  taf-salmon salmon --no-version-check quant \
    -i salmon_index \
    -l A \
    -1 reads_1.fq.gz \
    -2 reads_2.fq.gz \
    -o sample_quant \
    -p 8

  taf-salmon salmon --no-version-check quantmerge \
    --quants sample1_quant sample2_quant \
    --names sample1 sample2 \
    --column TPM \
    -o merged_tpm.tsv

Command Mode:
  This app keeps TAFFISH command_mode enabled. For upstream Salmon
  subcommands, prefer the explicit executable form:

    taf-salmon salmon index ...
    taf-salmon salmon quant ...

  Avoid ambiguous forms such as "taf-salmon index ..."; a non-option first
  argument may be interpreted as a container executable rather than as a
  Salmon subcommand.

Network:
  Salmon may try an upstream version check before subcommands. Pass
  --no-version-check for offline, deterministic runs. The wrapper does not
  force this option.

Boundaries:
  Salmon v1.11.4 removed the integrated legacy "salmon alevin" workflow.
  The command now prints an upstream migration message. Use piscem plus
  alevin-fry for current single-cell workflows, or Salmon v1.10.2 if the
  historical alevin implementation is required.

  Indices built with Salmon versions before 1.11.0 must be rebuilt for this
  package because v1.11 uses a new SSHash-backed index format.

Package:
  Image: ghcr.io/taffish/salmon:1.11.4-r1
  Platforms: linux/amd64, linux/arm64
  Runtime version: salmon 1.11.4
  Upstream license: GPL-3.0-or-later
  Citation DOI: 10.1038/nmeth.4197
