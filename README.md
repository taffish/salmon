# salmon

TAFFISH app for Salmon, a fast transcript-level RNA-seq quantification tool from
COMBINE-lab.

## Package Identity

| Field | Value |
| --- | --- |
| name | `salmon` |
| command | `taf-salmon` |
| kind | `tool` |
| TAFFISH version | `2.2.1-r1` |
| container image | `ghcr.io/taffish/salmon:2.2.1-r1` |
| upstream | `COMBINE-lab/salmon` |
| upstream release | `v2.2.1` |
| runtime version | `salmon 2.2.1` |
| native platforms | `linux/amd64`, `linux/arm64` |

## What Is Included

This app packages the official Salmon `v2.2.1` Rust CLI Linux release binaries:

- `salmon-cli-x86_64-unknown-linux-gnu.tar.xz`
  - SHA256: `a5250dc9d9e9c4f54e24683f787fca59bafb11ba3d46c500ca5f97b3272693e9`
- `salmon-cli-aarch64-unknown-linux-gnu.tar.xz`
  - SHA256: `bb3b7d1f367f1d3a5001b15c83f38d39584ac6451c2b46e779c311f8f48307fb`

The Dockerfile selects the correct upstream asset from Docker `TARGETARCH`,
verifies the checksum, installs the upstream `salmon` binary under
`/opt/salmon/salmon`, and exposes it as `/usr/local/bin/salmon`.

Salmon 2 is a from-scratch Rust rewrite. It keeps the core
`salmon index` -> `salmon quant` -> `quant.sf` workflow and downstream
quantification table formats, but it is a new major version with intentional
breaking changes.

The runtime image uses `debian:13-slim` and the official Linux GNU binary. The
v2 binary is much lighter than the old C++ distribution and depends only on the
standard GNU runtime libraries available in Debian 13, notably `libgcc_s`, `libm`,
and `libc`.

## Basic Usage

Show TAFFISH wrapper help:

```sh
taf-salmon --help
```

Show upstream Salmon help and version:

```sh
taf-salmon -- --help
taf-salmon -- --version
taf-salmon salmon --help
taf-salmon salmon --version
```

Build a Salmon 2 index:

```sh
taf-salmon salmon index \
  -t transcripts.fa \
  -i salmon_index \
  -k 31 \
  -p 8
```

Quantify single-end reads:

```sh
taf-salmon salmon quant \
  -i salmon_index \
  -l A \
  -r reads.fq.gz \
  -o sample_quant \
  -p 8
```

Quantify paired-end reads:

```sh
taf-salmon salmon quant \
  -i salmon_index \
  -l A \
  -1 reads_1.fq.gz \
  -2 reads_2.fq.gz \
  -o sample_quant \
  -p 8
```

Use the Salmon 2 sketch mode:

```sh
taf-salmon salmon quant \
  -i salmon_index \
  -l A \
  -r reads.fq.gz \
  --sketch \
  -o sample_sketch_quant \
  -p 8
```

Write RAD mappings while quantifying:

```sh
taf-salmon salmon quant \
  -i salmon_index \
  -l A \
  -r reads.fq.gz \
  --writeRad sample.rad \
  -o sample_quant \
  -p 8
```

Quantify a RAD file directly:

```sh
taf-salmon salmon quant \
  --rad sample.rad \
  -o sample_rad_quant \
  -p 8
```

Run deterministic FASTQ quantification:

```sh
taf-salmon salmon quant \
  -i salmon_index \
  -l A \
  -r reads.fq.gz \
  --deterministic \
  -o sample_deterministic_quant \
  -p 8
```

Merge transcript TPMs from multiple `quant.sf` outputs:

```sh
taf-salmon salmon quantmerge \
  --quants sample1_quant sample2_quant \
  --names sample1 sample2 \
  --column TPM \
  -o merged_tpm.tsv
```

## TAFFISH Command Mode

This is a normal TAFFISH tool app with `command_mode = true`.

For Salmon subcommands, prefer the explicit executable form:

```sh
taf-salmon salmon index ...
taf-salmon salmon quant ...
taf-salmon salmon quantmerge ...
taf-salmon salmon debug-map ...
```

Do not rely on:

```sh
taf-salmon index ...
```

In command mode, a non-option first argument can be interpreted as a container
executable name rather than as a Salmon subcommand. The explicit
`taf-salmon salmon ...` form is unambiguous and also lets users run the same
container environment directly.

For option-leading arguments to the default upstream command, this also works:

```sh
taf-salmon -- --version
taf-salmon -- --help
```

## Version Check And Network

Salmon 2 accepts `--no-version-check` and `SALMON_NO_VERSION_CHECK` for
compatibility with C++ Salmon, but upstream documents them as no-ops: Salmon 2
does not contact the network for version checks. Keeping the flag in scripts is
safe, but no longer necessary.

## Functional Surface

Packaged upstream command:

- `salmon index`: build a Salmon 2 index from transcript FASTA
- `salmon quant`: quantify transcript abundance from reads or alignments
- `salmon quant --sketch`: use the Salmon 2 sketch / pseudoalignment path
- `salmon quant --writeRad`: write RAD mappings while quantifying
- `salmon quant --rad`: quantify a RAD file directly
- `salmon quant --deterministic`: run reproducible FASTQ quantification
- `salmon quantmerge`: merge Salmon quantification tables
- `salmon debug-map`: diagnostic per-read best-mapping detail
- `salmon alevin`: present only as an upstream migration message

Salmon 2 removed the legacy integrated `salmon alevin` implementation. This
is an upstream change, not a TAFFISH packaging omission. Upstream recommends the
`piscem` plus `alevin-fry` ecosystem for current single-cell workflows.

The old top-level `salmon --cite` command is not present in Salmon 2. Citation
information remains documented upstream and below.

## Compatibility Notes

Salmon 2.2.1 keeps the Salmon 2.1.x index format. This package still writes
`index_version = 1`, and upstream states that no index rebuild is required when
moving from 2.1.x to 2.2.1. Rebuild indices made by Salmon 2.0.0 or older C++ /
pufferfish versions before quantification.

Downstream quantification outputs remain compatible: `quant.sf`, `cmd_info.json`,
`lib_format_counts.json`, `aux_info/meta_info.json`, and inferential replicate
outputs are intended to stay drop-in for tximport, tximeta, fishpond, and swish.

The Salmon 2 migration guide and v2.1.0 release notes document removed,
accepted-but-ignored, and new options. Notable changes include:

- `--sketch` and `--sketchStrictOrphans` are new Salmon 2 quant options.
- `--minAssignedFrags` is removed.
- `--features` for `index` is removed.
- several niche C++ inference and alignment options are rejected or accepted
  only as compatibility no-ops.

Salmon `2.2.1` is the recommended 2.2.x release. It includes the 2.2.0 feature
set plus a security fix for an `lz4_flex` advisory pulled in by RAD
compression. Upstream highlights include `--writeRad` / `--rad` decoupled
mapping and quantification, `--deterministic` FASTQ quantification, bias-aware
RAD input, and RAD chunk compression through `--radCompress`. Standard
point-estimate `quant.sf`, inferential replicate formats, and the on-disk index
format remain compatible with 2.1.x.

The preceding `2.1.0` release introduced the Salmon 2 index format marker,
applied `-l A` library-type filtering, fixed concordant-pairing and
anchored-alignment behavior, added default uni-MEM seeding, improved decoy-aware
indexing and sketch-mode behavior, emitted `duplicate_clusters.tsv` under
`--keepDuplicates`, and implemented fragment-length probability behavior around
`--noFragLengthDist`.

The app supports native Linux `amd64` and native Linux `arm64` through official
upstream binaries. No Docker platform emulation is required for either declared
platform.

The container includes the upstream binary, upstream README and BSD-3-Clause
license, GNU runtime libraries from Debian 13, and CA certificates. It does not
bundle reference transcriptomes, genomes, decoy lists, annotation files,
`piscem`, `alevin-fry`, `simpleaf`, `oarfish`, or external aligners.

## Smoke Coverage

The smoke tests are independent and run without network access. They check:

- `salmon 2.2.1` runtime version and Rust-port help banner
- no-op compatibility behavior for `--no-version-check`
- help for `index`, `quant`, `quantmerge`, and `debug-map`, including the
  2.2.x `writeRad` and `deterministic` options
- dynamic library resolution through `ldd`
- a tiny Salmon 2 index build that writes `info.json`, `index.ssi`, and
  `index.ctab`, and records `index_version = 1`
- a tiny single-end selective-alignment `quant` run that writes `quant/quant.sf`
- a tiny `quant --sketch` run that writes `sketch_quant/quant.sf`
- `quantmerge` on two synthetic `quant.sf` directories
- the upstream `alevin` removal and migration message

These tests verify packaging, command availability, and small real execution
paths. They are not a substitute for biological validation on production
references and read sets.

## Upstream

- Upstream repository: <https://github.com/COMBINE-lab/salmon>
- Documentation: <https://combine-lab.github.io/salmon/>
- Release: <https://github.com/COMBINE-lab/salmon/releases/tag/v2.2.1>
- Migration guide: <https://github.com/COMBINE-lab/salmon/blob/v2.2.1/MIGRATION.md>
- Upstream license: BSD-3-Clause
- Citation: Patro et al. 2017, Nature Methods
- DOI: `10.1038/nmeth.4197`
- PMID: `28263959`
