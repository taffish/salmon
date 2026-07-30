# salmon

TAFFISH app for Salmon, a fast transcript-level RNA-seq quantification tool from
COMBINE-lab.

## Package Identity

| Field | Value |
| --- | --- |
| name | `salmon` |
| command | `taf-salmon` |
| kind | `tool` |
| TAFFISH version | `2.4.1-r1` |
| container image | `ghcr.io/taffish/salmon:2.4.1-r1` |
| TAFFISH app license | `Apache-2.0` |
| upstream | `COMBINE-lab/salmon` |
| upstream release | `v2.4.1` |
| upstream commit | `a6084625d0d713118fa7d315055c68f18605f660` |
| upstream license | `BSD-3-Clause` |
| runtime version | `salmon 2.4.1` |
| native platforms | `linux/amd64`, `linux/arm64` |

## Installation

Refresh the local Hub index and install the app:

```sh
taf update
taf install salmon
```

TAFFISH uses the configured container backend. To select one for a run:

```sh
TAFFISH_CONTAINER_BACKEND=podman taf-salmon -- --version
TAFFISH_CONTAINER_BACKEND=docker taf-salmon -- --version
```

Both declared Linux platforms use native upstream binaries; neither backend
needs architecture emulation for `linux/amd64` or `linux/arm64`.

## What Is Included

This app packages the official Salmon `v2.4.1` Rust CLI Linux release binaries:

- `salmon-cli-x86_64-unknown-linux-gnu.tar.xz`
  - SHA256: `882717ae835fdc6b8676f457a989a3d354a69adb3d7cab0051d21e2e4e1eaf40`
- `salmon-cli-aarch64-unknown-linux-gnu.tar.xz`
  - SHA256: `af8854b208082198aff13879ca69938cfe215e928289de948a802aa7c566efc8`

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
and `libc`. The runtime also includes `procps`, matching upstream's workflow
container compatibility support for tools such as Nextflow that probe `ps`.

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
  --fldPolicy prior \
  --fldMean 250 \
  --fldSD 25 \
  -o sample_rad_quant \
  -p 8
```

Export retained mappings as unsorted BGZF BAM or SAM while quantifying:

```sh
taf-salmon salmon quant \
  -i salmon_index \
  -l A \
  -r reads.fq.gz \
  --writeBam mappings.bam \
  --bamCompressThreads 2 \
  -o sample_quant \
  -p 8

taf-salmon salmon quant \
  -i salmon_index \
  -l A \
  -r reads.fq.gz \
  --writeSam mappings.sam \
  -o sample_quant_sam \
  -p 8
```

`--writeBam` and `--writeSam` preserve Salmon's retained mappings. They do not
sort or index the output; use a downstream alignment tool when that is needed.

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

Enable the opt-in SQUAREM or DAAREM EM/VBEM accelerator for slow-mixing
problems or bootstrap-heavy workloads:

```sh
taf-salmon salmon quant \
  -i salmon_index \
  -l A \
  -r reads.fq.gz \
  --emAccel squarem \
  -o sample_accelerated_quant \
  -p 8
```

Use `--emAccel daarem` for the damped Anderson implementation. The default is
`none`; both accelerators are opt-in and converge to the same fixed point, but
their output is not byte-identical to the default at convergence tolerance.

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
- `salmon quant -a genome.bam --annotation genes.gtf`: quantify from a
  name-grouped genome-aligned BAM plus annotation
- `salmon quant --sketch`: use the Salmon 2 sketch / pseudoalignment path
- `salmon quant --writeRad`: write RAD mappings while quantifying
- `salmon quant --rad`: quantify a RAD file directly
- `salmon quant --fldPolicy baked|derive|prior`: select the fragment-length
  distribution source for RAD quantification
- `salmon quant --deterministic`: run reproducible FASTQ quantification
- `salmon quant --writeBam`: write unsorted BGZF BAM mappings
- `salmon quant --writeSam`: visible alias of the mapping SAM export
- `salmon quant --bamCompressThreads`: control BAM compression threads
- `salmon quant --emAccel squarem|daarem`: opt into EM/VBEM acceleration
- `salmon quantmerge`: merge Salmon quantification tables
- `salmon debug-map`: diagnostic per-read best-mapping detail
- `salmon alevin`: present only as an upstream migration message

Salmon 2 removed the legacy integrated `salmon alevin` implementation. This
is an upstream change, not a TAFFISH packaging omission. Upstream recommends the
`piscem` plus `alevin-fry` ecosystem for current single-cell workflows.

The old top-level `salmon --cite` command is not present in Salmon 2. Citation
information remains documented upstream and below.

## Compatibility Notes

Salmon 2.4.1 keeps `index_version = 1`; upstream requires no index rebuild when
moving from 2.4.0 and preserves Salmon 2 quantification output formats. Rebuild
indices made by Salmon 2.0.x or older C++ / pufferfish versions. Standard
outputs such as `quant.sf`, `cmd_info.json`, `lib_format_counts.json`, and
`aux_info/meta_info.json` remain suitable for downstream consumers including
tximport and tximeta.

Version 2.4.1 fixes a RAD reader race introduced in 2.2.0. The race could
silently produce zero or partial counts and was most likely at low thread
counts; upstream observed it more readily under arm64 CI stress. The affected
paths were `quant --rad`, `--deterministic`, and genome projection with
`-a --annotation`. Plain transcriptome alignment quantification with `-a` and
ordinary reads-mode mapping were not affected. Version 2.4.1 makes no CLI or
index-format changes relative to 2.4.0.

Version 2.4.0 added:

- `--writeBam FILE` for unsorted BGZF BAM mapping export
- the visible `--writeSam` alias for `--writeMappings`
- `--bamCompressThreads` for BAM compression concurrency
- `--fldPolicy baked|derive|prior` for RAD fragment-length handling
- `frag_length_source` provenance in quantification metadata
- refreshed dependencies and security cleanup

Earlier Salmon 2 releases added sketch quantification, RAD separation,
deterministic quantification, genome-projection quantification, SQUAREM/DAAREM
acceleration, and the current index format. The migration guide documents old
C++ options that were removed or retained only as no-ops. Integrated
`salmon alevin` remains removed; use the alevin-fry ecosystem instead.

The app supports native Linux `amd64` and native Linux `arm64` through official
upstream binaries. No Docker platform emulation is required for either declared
platform.

The container includes the upstream binary, upstream README and BSD-3-Clause
license, GNU runtime libraries, `procps`, and CA certificates. It does not
bundle reference transcriptomes, genomes, decoy lists, annotation files,
`piscem`, `alevin-fry`, `simpleaf`, `oarfish`, or external aligners.

## Smoke Coverage

The smoke tests are independent and run without network access. They check:

- `salmon 2.4.1` runtime version and top-level help
- no-op compatibility behavior for `--no-version-check`
- help for `index`, `quant`, `quantmerge`, and `debug-map`, including the
  `sshashTmpDir`, `ramLimit`, `writeRad`, `deterministic`, genome annotation,
  `writeBam`, `writeSam`, `bamCompressThreads`, `fldPolicy`, and `emAccel`
- dynamic library resolution through `ldd`
- a tiny Salmon 2 index build that writes `info.json`, `index.ssi`, and
  `index.ctab`, and records `index_version = 1`
- gzip-compressed single-end and paired-end selective-alignment `quant` runs
  with absolute processed, mapped, and `NumReads` mass assertions
- a tiny `quant --sketch` run that writes `sketch_quant/quant.sf`
- a transcriptome-SAM alignment-mode regression using `U`, `SF`, and `SR`,
  preserving the genuine single-end strandedness regression coverage
- genome-alignment projection from a tiny queryname-sorted SAM plus GTF, with
  absolute processed and mapped fragment assertions
- independent tiny `--emAccel squarem` and `--emAccel daarem` quantification
- real `--writeBam` and `--writeSam` exports, including BAM magic validation
  and BAM-input re-quantification
- eight low-thread RAD re-quantifications with absolute processed/mapped count
  assertions and `frag_length_source = prior`
- deterministic quantification with absolute processed/mapped count assertions
- `quantmerge` on two synthetic `quant.sf` directories
- the upstream `alevin` removal and migration message

These tests verify packaging, command availability, and small real execution
paths. They are not a substitute for biological validation on production
references and read sets.

## Upstream

- Upstream repository: <https://github.com/COMBINE-lab/salmon>
- Documentation: <https://combine-lab.github.io/salmon/>
- Release: <https://github.com/COMBINE-lab/salmon/releases/tag/v2.4.1>
- Migration guide: <https://github.com/COMBINE-lab/salmon/blob/v2.4.1/MIGRATION.md>
- TAFFISH app packaging license: Apache-2.0
- Upstream license: BSD-3-Clause
- Citation: Patro et al. 2017, Nature Methods
- DOI: `10.1038/nmeth.4197`
- PMID: `28263959`
