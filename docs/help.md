salmon 2.3.3-r1

TAFFISH wrapper for Salmon v2.3.3 from COMBINE-lab.
Salmon performs transcript-level RNA-seq quantification from reads or
transcriptome alignments. Salmon 2 is the Rust CLI rewrite: it keeps the
index -> quant -> quant.sf workflow, but uses a new index format.

Usage:
  taf-salmon --help
  taf-salmon --version
  taf-salmon -- --help
  taf-salmon -- --version
  taf-salmon salmon index ...
  taf-salmon salmon quant ...
  taf-salmon salmon quantmerge ...
  taf-salmon salmon debug-map ...

Wrapper Options:
  --help       show this TAFFISH help
  --version    show TAFFISH package version
  --compile    print generated shell code
  --           pass following option-leading arguments to the default command

Common Commands:
  salmon index       build a Salmon 2 transcript index
  salmon quant       quantify transcript abundance from reads or alignments
  salmon quantmerge  merge multiple Salmon quantification outputs
  salmon debug-map   diagnostic per-read best-mapping details

Examples:
  taf-salmon salmon index \
    -t transcripts.fa \
    -i salmon_index \
    -k 31 \
    -p 8

  taf-salmon salmon quant \
    -i salmon_index \
    -l A \
    -r reads.fq.gz \
    --emAccel squarem \
    -o sample_quant \
    -p 8

  taf-salmon salmon quant \
    -i salmon_index \
    -l A \
    -r reads.fq.gz \
    --sketch \
    -o sample_sketch_quant \
    -p 8

  taf-salmon salmon quantmerge \
    --quants sample1_quant sample2_quant \
    --names sample1 sample2 \
    --column TPM \
    -o merged_tpm.tsv

Command Mode:
  command_mode is enabled. For upstream subcommands, prefer:

    taf-salmon salmon index ...
    taf-salmon salmon quant ...

  Avoid ambiguous forms such as "taf-salmon index ..."; a non-option first
  argument may be interpreted as a container executable.

Migration Notes:
  Salmon 2 is a Rust rewrite. Salmon 2.3.3 keeps index_version = 1 and requires
  no rebuild of compatible 2.1.x-2.3.x indices. Default quantification output is
  unchanged from 2.3.2. The new --emAccel squarem and --emAccel daarem modes are
  opt-in EM/VBEM accelerators; default is none. Per-phase timing is available
  through RUST_LOG=salmon::timing=info. Rebuild indices made by Salmon 2.0.x or
  older C++ / pufferfish versions.

  salmon alevin is hidden from help and prints a migration message when called;
  use alevin-fry for current single-cell workflows. salmon --cite is no longer
  a CLI option. Some C++ options are removed or accepted only as no-ops. Details:
    https://github.com/COMBINE-lab/salmon/blob/v2.3.3/MIGRATION.md

Package:
  Image: ghcr.io/taffish/salmon:2.3.3-r1
  Platforms: linux/amd64, linux/arm64
  Runtime version: salmon 2.3.3
  Upstream license: BSD-3-Clause
  Citation DOI: 10.1038/nmeth.4197
