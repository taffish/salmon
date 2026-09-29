# salmon

`salmon` packages Salmon **2.8.0-r1** for TAFFISH: a CPU CLI for transcript-level
RNA-seq quantification. The thin wrapper preserves upstream commands and options.

## What This App Packages

- Command: `taf-salmon`; tool app with automatic command mode.
- Official [v2.8.0](https://github.com/COMBINE-lab/salmon/releases/tag/v2.8.0),
  commit `ed926b8f6120c592ba13e696fe24732004ee0132`.
- Native Linux amd64 and arm64 official binaries; no emulation or algorithm patches.
- `salmon-cli-x86_64-unknown-linux-gnu.tar.xz` SHA256:
  `10a7f7994df7ef0592ac191cc79a1abd41316463000b307647a9dcab21e1efa6`.
- `salmon-cli-aarch64-unknown-linux-gnu.tar.xz` SHA256:
  `3b2bf20b7a87c8207e83debd7aa0a6fefa85fb3b211ca069a394584dee1025c3`.
- Digest-pinned Debian 13, GNU runtime libraries, CA certificates and `procps`.
  Binary, upstream README/license and source identity are retained under `/opt/salmon`.
- A tiny synthetic RAD v2 fixture for packaging checks; no production reference data.

Each asset SHA is verified; version, commit, asset and target architecture are
recorded. Build-time checks are limited to version, ordinary help, provenance and
dynamic libraries. Full indexing, inference and numerical checks run at runtime.

## Scope and 2.8 Changes

Included: `index`, read/alignment/RAD `quant`, `quantmerge`, `debug-map`, selective
alignment and sketch mapping, gene aggregation, genome projection, BAM/SAM export,
bootstrap/Gibbs options, and upstream inference/decoding controls.

The [2.8 release notes](https://github.com/COMBINE-lab/salmon/blob/v2.8.0/docs/release-notes-2.8.0.md)
describe two important changes:

- Read **RAD v2** from current piscem and legacy RAD. Salmon's own writer remains
  legacy; accepting v2 does not imply writing v2.
- `--emAccel daarem` now requires **plain EM** (`--useEM` or `--meta`). Default
  VBEM plus DAAREM is rejected; use `none` or SQUAREM with VBEM. The upstream fix
  addresses negative intermediate abundances and inappropriate convergence.

Salmon 2.7 indexes remain compatible: index format v2 and SSHash format 5 are
unchanged. Rebuild indexes from 2.6 or earlier. Deterministic two-phase inference
remains the default; `--deterministic` is a no-op, `--online` the deprecated
one-pass path. This does not promise identical floating-point results across CPU
architectures or changed inference options. SQUAREM does not promise the same
VBEM fixed point as plain iteration.

Not bundled: production reads/references, generic pretrained models, aligners,
`piscem`, `alevin-fry`, `simpleaf`, `oarfish`, or a GUI environment. Integrated
`salmon alevin` was removed upstream and gives a migration message. These separate
tools are not hidden runtime dependencies of this Salmon CLI.

GUI discovery checked the release workspace, CLI features, official installation,
documentation and linked companion tools. There is no Salmon GUI/server, viewer
extra or plugin entrypoint. The Astro website is documentation, not a local
analysis UI. No display, browser, ports or service lifecycle are needed.

## Installation and Usage

Install a published version with `taf update` then `taf install salmon`.
Run from a directory containing your inputs:

```sh
taf-salmon --help
taf-salmon -- --help
taf-salmon -- --version
taf-salmon salmon index -t transcripts.fa -d decoys.txt -i index -k 31 -p 8
taf-salmon salmon quant -i index -l A -1 r1.fq.gz -2 r2.fq.gz -o quant -p 8
taf-salmon salmon quant -i index -l A -r reads.fq.gz --geneMap genes.tsv -o quant-se
taf-salmon salmon quant -i index -l A -r reads.fq.gz --sketch -o quant-sketch
taf-salmon salmon quant -i index -l A -r reads.fq.gz --useEM --emAccel daarem -o quant-em
taf-salmon salmon quant --rad mappings.rad --fldPolicy prior --fldMean 250 --fldSD 25 -o quant-rad
taf-salmon salmon quantmerge --quants sample1 sample2 --names s1 s2 --column TPM -o merged.tsv
```

Omit `-d` without a decoy-name list. Reference, decoys, library type, priors,
mapping mode, bias correction and inference method are scientific choices.
`--writeRad FILE` retains mappings; `--writeBam FILE`/`--writeSam FILE` exports
unsorted, unindexed mappings. Sorting/indexing requires a downstream tool.
Genome alignments must be name-grouped with the corresponding `--annotation`.

`-p` is the shared mapping/decoding budget. Compression is content-detected for
gzip/BGZF, bzip2, xz and zstd. `--decoder auto|serial|parallel|parallel=N` and
`--threadPolicy FILE` control decoding; plain/non-seekable inputs use serial decoding.

## Command Mode and Paths

Prefer `taf-salmon salmon quant ...`, not `taf-salmon quant ...`: the first
non-option argument denotes a container executable. Wrapper `--help`/`--version`
differ from upstream `-- --help`/`-- --version`. Current TAFFISH reconstructs a
shell line; preserve literal quoting for spaces:

```sh
taf-salmon salmon index -t '"transcripts with spaces.fa"' -i '"index with spaces"' -k 31
taf-salmon salmon quant -i '"index with spaces"' -l A -r '"sample 1.fq.gz"' -o '"result 1"'
```

## Inputs, Outputs and Runtime Writes

- Index: transcript FASTA and optional decoy list. Quant: matching index and reads,
  transcript alignments, genome alignments/annotation, or RAD; optional gene map.
- `quant.sf`: transcript table; `quant.genes.sf`: gene table with `--geneMap`.
  `aux_info/meta_info.json`: processed/mapped fragments and inference metadata;
  `logs/salmon_quant.log`: run log. `quantmerge -o` writes the merged matrix.
- Index construction writes its output and scratch (`--sshashTmpDir` if supplied).
  Quant writes output and intermediate RAD; use `--radScratchDir` for writable
  space. Intermediate RAD is deleted on success; `--skipQuant` retains RAD and
  does not produce `quant.sf`. Use new outputs: upstream may overwrite files.
- References/prepared indexes remain read-only. No analysis writes `/opt/salmon`.
  `--no-version-check`/its historical environment variable are no-ops: Salmon 2
  makes no version-check network call. Missing inputs fail, not download.

## References and Administrator-Prepared Indexes

Reference FASTA/annotations/decoys and indexes derived from them are **project
inputs and derived artifacts**. The 2.8 source exposes no reference/model
downloader, catalog, alias lookup or remote fallback, and defines no downloadable
Salmon reference family. An app-specific catalog installer, automatic discovery
or override/disable helper is therefore N/A, not merely omitted because users
choose an organism. Acquisition/license/provenance belong to the reference project.

A team can prepare an approved index once and share it read-only. Suggested roots:
`~/.local/share/taffish/references/salmon/PROJECT/VERSION/index`,
`/usr/local/share/taffish/references/salmon/PROJECT/VERSION/index`, or
`/opt/taffish/references/salmon/PROJECT/VERSION/index`. Build in new writable staging;
verify `info.json`, every index member and representative quantification before
promoting the complete directory. Record input SHA256, Salmon version, options,
resource license and member hashes; a directory alone is not a complete index.

Administrators manage ownership, with traversable 0755 directories and readable
0644 ordinary files. Users need no index write permission. Do not change shared
permissions during analysis. Software BSD licensing does not grant rights to
third-party references; site sharing follows reference terms. This app performs
no automatic sudo/system installation or scientific reference selection.

Set `INDEX_ROOT=/opt/taffish/references/salmon/PROJECT/VERSION/index` for an index
outside the working directory:

| Backend | Installed-wrapper command |
| --- | --- |
| Docker | `TAFFISH_CONTAINER_BACKEND=docker TAFFISH_DOCKER_RUN_ARGS="-v $INDEX_ROOT:/reference:ro" taf-salmon salmon quant -i /reference -l A -r reads.fq.gz -o result` |
| Podman | `TAFFISH_CONTAINER_BACKEND=podman TAFFISH_PODMAN_RUN_ARGS="-v $INDEX_ROOT:/reference:ro" taf-salmon salmon quant -i /reference -l A -r reads.fq.gz -o result` |
| Apptainer | `TAFFISH_CONTAINER_BACKEND=apptainer TAFFISH_APPTAINER_RUN_ARGS="--bind $INDEX_ROOT:/reference:ro" taf-salmon salmon quant -i /reference -l A -r reads.fq.gz -o result` |

Use resolved physical mount roots without spaces. `-i` selects the index explicitly;
scratch/output stays writable in the workdir. A project-local index inside the
ordinary workdir is the simplest alternative. Missing/incompatible indexes fail.

## Backend Validation

Both declared platforms are native: `linux/amd64` and `linux/arm64`. No emulation,
GPU/device/port/network option is intrinsic. Apptainer requires native Linux, not
macOS. Optional read-only reference mounts are site/run policy.

Validation on 2026-09-26 used this exact candidate, not old 2.7 results:

| Native platform | Docker | Podman | Apptainer |
| --- | --- | --- | --- |
| linux/amd64 (xjp) | full direct/read-only smoke and wrapper PASS | full direct/read-only smoke and wrapper PASS | actual read-only SIF and wrapper PASS |
| linux/arm64 (local Linux VMs) | full direct/read-only smoke PASS; final wrapper rerun incomplete (host engine startup stalled) | full direct/read-only smoke and wrapper PASS | not separately validated |

All 288 exact manifest probes passed. Four complete backend/platform wrapper
suites passed (84 calls), including ordinary users, argument spaces, compressed
reads, DAAREM policy, RAD v2, actual read-only shared indexes and failure diagnostics.
The final arm64 Docker wrapper rerun passed its first 13 calls, then Docker stopped
starting even a no-bind version probe (containers stayed Created, PID 0). This is
not counted as a full wrapper PASS; earlier evidence is retained, not relabelled.
No daemon restart was performed. There is no architecture-specific mount/runtime
branch: both native platforms and all three backend axes are independently covered.

An index genuinely built by official Salmon 2.7.0 was reused read-only by 2.8.0;
input/index hashes stayed unchanged. This is a tiny compatibility test, not a
production-reference validation. Native arm64 Apptainer remains untested.

Final Docker image sizes: amd64 113,554,396 bytes (108.29 MiB), arm64 133,279,850
bytes (127.11 MiB). `/opt/salmon` is about 21/19 MiB respectively. Multi-stage
fetching excludes curl/xz tooling and download archives; apt lists are removed.
No Python/Conda/build toolchain, production data or obvious large removable cache
is retained. Runtime libraries, certificates, procps and upstream notices remain.

## Testing and Boundaries

Independent offline smoke covers version/provenance/help, libraries, tiny indexes,
old/future index rejection, single/paired/gzip/gene-map quantification, deterministic
parallel workers, sketch, merge, alignment strandedness, genome projection,
SQUAREM, DAAREM+EM and VBEM rejection, BAM/SAM, repeated legacy RAD inference,
actual RAD v2 and mapping-only cleanup. Each mode uses unique private scratch and
emits stage/exit/log tails on failure; the immutable RAD fixture is never modified.

Direct manifest probes, Docker/Podman read-only-root probes, actual read-only SIF,
and generated-wrapper binds are separate layers. Tiny packaging tests do not prove
production reference installation, biological accuracy, the full upstream test
suite or cross-architecture bitwise reproducibility.

## License and Citation

TAFFISH packaging: Apache-2.0. Upstream Salmon and the adapted synthetic test
construction: BSD-3-Clause; original release LICENSE/README remain in the image.
References retain their own licenses. Cite Patro et al. (2017), Nature Methods,
DOI `10.1038/nmeth.4197`, PMID `28263959`, and record the exact Salmon version.

See [upstream documentation](https://combine-lab.github.io/salmon/) and the
[migration guide](https://github.com/COMBINE-lab/salmon/blob/v2.8.0/MIGRATION.md).
