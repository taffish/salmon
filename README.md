# salmon

TAFFISH app for Salmon, a fast transcript-level RNA-seq quantification tool from
COMBINE-lab.

## Package Identity

| Field | Value |
| --- | --- |
| name | `salmon` |
| command | `taf-salmon` |
| kind | `tool` |
| TAFFISH version | `2.7.0-r1` |
| container image | `ghcr.io/taffish/salmon:2.7.0-r1` |
| TAFFISH app license | `Apache-2.0` |
| upstream | `COMBINE-lab/salmon` |
| upstream release | `v2.7.0` |
| upstream commit | `d3be8b31d31242683c01fc5510c48fbd8bc917fb` |
| upstream license | `BSD-3-Clause` |
| runtime version | `salmon 2.7.0` |
| native platforms | `linux/amd64`, `linux/arm64` |

## Installation

Refresh the local Hub index and install the app:

```sh
taf update
taf install salmon
```

TAFFISH uses the configured container backend. To select one for a run:

```sh
TAFFISH_CONTAINER_BACKEND=docker taf-salmon -- --version
TAFFISH_CONTAINER_BACKEND=podman taf-salmon -- --version
TAFFISH_CONTAINER_BACKEND=apptainer taf-salmon -- --version
```

Both declared Linux platforms use native upstream binaries; neither backend
needs architecture emulation for `linux/amd64` or `linux/arm64`. Salmon is a
backend-neutral CPU CLI, so no backend-specific GPU, device, port, network or
mount argument is embedded in the wrapper.

## What Is Included

This app packages the official Salmon `v2.7.0` Rust CLI Linux release binaries:

- `salmon-cli-x86_64-unknown-linux-gnu.tar.xz`
  - SHA256: `5f42fcd70f270bc9ee8adee0c384fbb457f1606f792d36bb86e0dacf2e46e74a`
- `salmon-cli-aarch64-unknown-linux-gnu.tar.xz`
  - SHA256: `7273f7b50314416b0429b581c472bf1c99ff4d1af35448ab792e4752533fd073`

The Dockerfile selects the correct upstream asset from Docker `TARGETARCH`,
verifies the checksum, installs the upstream `salmon` binary under
`/opt/salmon/salmon`, records immutable source identity in
`/opt/salmon/share/source.txt`, and exposes it as `/usr/local/bin/salmon`.
During a cross-architecture Buildx build, checksum and provenance checks still
run, but target-binary execution is deferred to runtime smoke. Native builds
run only the stable version, ordinary-help, provenance, and `ldd` build-time
checks; real index and quantification paths remain runtime-only.

Salmon 2 is a from-scratch Rust rewrite. It keeps the core
`salmon index` -> `salmon quant` -> `quant.sf` workflow and downstream
quantification table formats, but it is a new major version with intentional
breaking changes.

The runtime image uses the pinned multi-architecture `debian:13-slim` manifest
`sha256:d7e12182ce18b85b93007c1dedf31f2d29e01ccf3182cc4017c709b6259bc132`
and the official Linux GNU binary. The
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

Current TAFFISH automatic command mode reconstructs a shell command line. If a
path contains whitespace, ordinary outer-shell quoting alone is insufficient;
include literal single quotes inside that argument:

```sh
taf-salmon salmon quant \
  -i "'indexes/salmon index'" -l A \
  -r "'reads/sample 1.fq.gz'" \
  -o "'results/sample 1'" -p 8
```

The inner single quotes are intentional. Prefer whitespace-free paths when
possible.

### Rebuild pre-2.7 indexes

Salmon 2.7.0 changes the on-disk index format from v1 to v2. Every index built
by Salmon 2.6.0 or earlier must be rebuilt from its transcript FASTA and decoy
list before quantification:

```sh
taf-salmon salmon index \
  -t transcripts.fa \
  -d decoys.txt \
  -i salmon_index_v2 \
  -k 31 \
  -p 8
```

Omit `-d` when the reference has no decoy-name list. Salmon 2.7 rejects an old
index with an actionable rebuild message; it does not silently reuse or convert
the incompatible index in place.

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

For compressed reads, `-p` is the shared execution-slot budget for decoding
and mapping. Salmon chooses a serial or parallel decoder automatically. To
override that decision or supply a reviewed policy file:

```sh
taf-salmon salmon quant \
  -i salmon_index -l A -r reads.fq.gz \
  --decoder serial \
  --threadPolicy thread-policy.json \
  -o sample_quant -p 8
```

`--decoder` accepts `auto`, `serial`, `parallel`, or `parallel=N`. Compression
is detected from file content rather than the extension for reads, targets,
alignments, and gene maps; supported formats include gzip/BGZF, bzip2, xz, and
zstd. A plain or non-seekable input falls back to serial decoding.

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

Salmon 2.6 performs deterministic FASTQ quantification by default:

```sh
taf-salmon salmon quant \
  -i salmon_index \
  -l A \
  -r reads.fq.gz \
  -o sample_deterministic_quant \
  -p 8
```

The retained `--deterministic` flag is accepted as a no-op for existing scripts.
`quant.sf` is byte-identical across runs and thread counts. The deprecated
`--online` option still selects the pre-2.6 one-pass path in Salmon 2.7.0; new
workflows should use the deterministic default.

The default path writes an lz4-compressed intermediate RAD and deletes it on
success. Use `--radScratchDir /path/to/scratch` to place that temporary file on
another volume, or `--radCompress zstd` for stronger compression. `--skipQuant`
stops after mapping and keeps the RAD under the output directory as the run's
deliverable; it does not write `quant.sf`.

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
- `salmon quant --decoder auto|serial|parallel|parallel=N`: control compressed
  input decoding within the shared thread budget
- `salmon quant --threadPolicy FILE`: override the decoder engagement policy
- `salmon quant --geneMap FILE`: accept plain or compressed GTF/GFF/TSV gene maps
- `salmon quant --writeRad`: write RAD mappings while quantifying
- `salmon quant --rad`: quantify a RAD file directly
- `salmon quant --fldPolicy baked|derive|prior`: select the fragment-length
  distribution source for RAD quantification
- plain `salmon quant`: run deterministic two-phase quantification by default
- `salmon quant --deterministic`: accepted no-op compatibility spelling
- `salmon quant --online`: use the deprecated pre-2.6 one-pass path
- `salmon quant --radScratchDir`: relocate the temporary intermediate RAD
- `salmon quant --radCompress lz4|zstd|none`: select RAD compression
- `salmon quant --skipQuant`: stop after mapping and keep the output RAD
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

Salmon 2.7.0 writes `index_version = 2` and `sshash_format_version = 5` in
`info.json`. All pre-2.7 Salmon indexes are format v1 and must be rebuilt.
Salmon also rejects indexes that advertise a future format with an explicit
upgrade message instead of falling through to a low-level I/O error.

The v2 index adopts a unified canonical k-mer dictionary based on SSHash v6.
Upstream reports about 23% lower peak RSS during GRCh38 cDNA index construction,
8–13% fewer dictionary bytes, and faster sketch mapping. Against Salmon 2.6.0,
upstream found byte-identical `quant.sf` and per-fragment RAD records on its
validation sets; the compatibility break is the index representation, not the
quantification result contract.

Version 2.6.0 makes deterministic two-phase quantification the default for
selective-alignment, sketch, and alignment input. `aux_info/meta_info.json`
records `inference_path` as `deterministic`, `online`, or `none`; the last value
is used for mapping-only `--skipQuant`. The default intermediate RAD is deleted
on success. Upstream estimates temporary lz4 RAD usage at roughly 45 MB per
million fragments in sketch mode and 55 MB per million fragments in selective
alignment, with the exact size depending on multimapping.

The release also restores and corrects library-format accounting, removes decoy
rows from RAD-based `quant.sf`, reports applied and detected library types
separately, fixes metadata placeholders, and uses BAM `AS` tags by default in
alignment mode. Pipelines that parse `quant.sf` by row number, interpret
`library_types` as the detected type, or enforce thresholds on absolute
compatible-fragment counts should review the upstream 2.6.0 migration notes.

Version 2.5.1 is a dependency and scheduler-hardening update. It replaces the
adaptive mapping pool used in 2.5.0 with a fixed maximum worker set: workers
above the current target park at batch boundaries and wake when the target
grows, so no worker is created after startup and the configured ceiling is
structural. Parked workers release record buffers. Upstream reports unchanged
quantification results, identical mapped counts across modes, byte-identical
serial/parallel `quant.sf` under `--deterministic`, and no index rebuild.

Version 2.5.0 makes `-p` a shared execution-slot budget for mapping and gzip
decoding. It adds adaptive decoder scheduling, `--decoder`, `--threadPolicy`,
content-based gzip/BGZF/bzip2/xz/zstd detection across input paths, and
compressed `--geneMap` support. Upstream reports unchanged quantification
results and no index rebuild requirement. It also fixes incomplete failed RAD
outputs, widens packed equivalence-class offsets, improves gene-map validation
and warnings, and updates the parallel decoding stack to include the upstream
deadlock fix.

At a fixed thread count with the serial decoder, upstream reports byte-identical
`quant.sf` output relative to 2.4.1. Across thread counts, floating-point shard
reduction can vary below reported precision; repeated single-threaded runs are
still expected to be byte-identical.

Version 2.4.1 fixed a RAD reader race introduced in 2.2.0. It could silently
produce zero or partial counts in `quant --rad`, `--deterministic`, and genome
projection with `-a --annotation`, especially at low thread counts. The runtime
smoke retains repeated one-thread RAD regression coverage for this path.

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

Reference transcriptomes, genomes, decoy lists, annotations, reads, alignments,
and RAD files are project-specific inputs rather than a fixed Salmon database.
Salmon does not provide a production database downloader that should be mapped
to a shared TAFFISH database path, so a database installation helper and
automatic database mount are not applicable. Users mount or pass their own
project inputs explicitly. The official 2.7.0 workspace and release assets
provide the CLI only; no official local GUI, viewer extra, plugin GUI, or
desktop companion is part of this app's upstream distribution.

## Backend Capability Matrix

| Capability | Docker | Podman | Apptainer |
| --- | --- | --- | --- |
| native `linux/amd64` image | supported | supported | supported when the site provides an amd64 SIF/runtime |
| native `linux/arm64` image | supported | supported | supported when the site provides an arm64 SIF/runtime |
| index, reads/alignment quant, RAD, merge | same wrapper | same wrapper | same wrapper |
| project inputs and writable outputs | normal TAFFISH workdir/bind | normal TAFFISH workdir/bind | normal TAFFISH workdir/bind |
| database/model auto-mount | N/A: no canonical external resource | N/A | N/A |
| GPU/device/port/network option | N/A | N/A | N/A |

The validation matrix for this candidate uses fresh offline Docker and Podman
containers with normal and read-only roots, plus an actual read-only Apptainer
SIF made from the same candidate OCI content. No backend writes the image tree;
all index, scratch, and quantification output is confined to the command's
writable work directory or an explicit user path.

## Smoke Coverage

The smoke tests are independent and run without network access. They check:

- `salmon 2.7.0` runtime version, embedded source identity, and top-level help
- no-op compatibility behavior for `--no-version-check`
- help for `index`, `quant`, `quantmerge`, and `debug-map`, including the
  `sshashTmpDir`, `ramLimit`, `decoder`, `threadPolicy`, `writeRad`,
  deterministic-default, `online`, `radScratchDir`, `radCompress`, `skipQuant`,
  `errorModel`, genome annotation, `writeBam`, `writeSam`,
  `bamCompressThreads`, `fldPolicy`, and `emAccel`
- dynamic library resolution through `ldd`
- a tiny Salmon 2 index build that writes `info.json`, `index.ssi`, and
  `index.ctab`, and records `index_version = 2` plus
  `sshash_format_version = 5`
- actionable rejection of a simulated pre-2.7 index and a simulated future
  index format, without creating a misleading quantification output
- gzip-compressed single-end and paired-end selective-alignment `quant` runs
  with absolute processed, mapped, and `NumReads` mass assertions; the
  single-end case uses misleading filenames, an explicit serial decoder, a
  validated thread-policy JSON file, and a gzip-compressed gene map
- one single-thread and two eight-slot forced-parallel default quantifications;
  the smoke asserts the parallel execution plan, absolute processed/mapped
  counts, read-mass conservation, and byte-identical cross-thread/repeated `quant.sf`
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
- default deterministic, no-op `--deterministic`, deprecated `--online`, and
  conflicting-path behavior with exact `inference_path` assertions
- mapping-only `--skipQuant` with output-RAD retention and scratch cleanup
- zstd-compressed RAD writing followed by direct RAD quantification
- `quantmerge` on two synthetic `quant.sf` directories
- the upstream `alevin` removal and migration message

These tests verify packaging, command availability, and small real execution
paths. They are not a substitute for biological validation on production
references and read sets.

## Upstream

- Upstream repository: <https://github.com/COMBINE-lab/salmon>
- Documentation: <https://combine-lab.github.io/salmon/>
- Release: <https://github.com/COMBINE-lab/salmon/releases/tag/v2.7.0>
- Release notes: <https://github.com/COMBINE-lab/salmon/blob/v2.7.0/docs/release-notes-2.7.0.md>
- Migration guide: <https://github.com/COMBINE-lab/salmon/blob/v2.7.0/MIGRATION.md>
- TAFFISH app packaging license: Apache-2.0
- Upstream license: BSD-3-Clause
- Citation: Patro et al. 2017, Nature Methods
- DOI: `10.1038/nmeth.4197`
- PMID: `28263959`
