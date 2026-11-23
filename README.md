# salmon

`salmon` packages Salmon **2.12.0-r1** for TAFFISH: a CPU CLI for transcript-level
RNA-seq quantification. The thin wrapper preserves upstream commands and options.

## What This App Packages

- Command: `taf-salmon`; tool app with automatic command mode.
- Official [v2.12.0](https://github.com/COMBINE-lab/salmon/releases/tag/v2.12.0),
  commit `d71d1331371d29073006220369cbc48ff1802040`.
- Native Linux amd64 and arm64 official binaries; no emulation or algorithm patches.
- `salmon-cli-x86_64-unknown-linux-gnu.tar.xz` SHA256:
  `44f02f8cca063f68ffd978e948912e942716f37cb59acbce85de39e1e1f38f95`.
- `salmon-cli-aarch64-unknown-linux-gnu.tar.xz` SHA256:
  `c7d10d11a6246c8d33a25e28ad0848485338ba45576b2e94374a8efd62334e19`.
- Digest-pinned Debian 13, GNU runtime libraries, CA certificates and `procps`.
  Binary, upstream README/license and source identity are retained under `/opt/salmon`.
- A tiny synthetic RAD v2 fixture for packaging checks; no production reference data.

Each asset SHA is verified; version, commit, asset and target architecture are
recorded. Build-time checks are limited to executable/version and provenance. Help, dynamic links, indexing, inference and numerical checks run at runtime.

## Upgrading to 2.12

The index format is unchanged from 2.11. Complete v3 indexes from 2.9 onward
can be reused read-only. The deprecated `--online` path is removed: drop the
flag. `--deterministic` remains an accepted no-op; the default is deterministic.
For alignment error scoring, use `--errorModel -t transcripts.fa` with a regular
SAM/BAM file; it needs two passes and rejects a pipe. Ordinary `-a` input now
supports SAM/BAM FIFOs and detects format by content, not the filename.

Upstream 2.12 changes pairing of small inward dovetails, sketch fragment lengths,
genome mate projection, some bias corrections and Gibbs sampling. Estimates need
not match 2.11, and Gibbs draws at the same seed can change across versions.
Do not treat packaging smoke as validation of a research analysis.
Upstream still documents limits: `--skipQuant -l A` counts all placed fragments
before library-type filtering; `--posBias` does not supply a per-fragment
positional weight; failures late in index construction can leave work files.
See the fixed-version release notes for the complete result changes and limits.

### Migrating older indexes

**Do not overwrite your old index.** Salmon 2.9 changed to index format v3 (SSHash 6); the current release refuses 2.8/v2 and earlier. Rebuild from the original FASTA, decoys and index settings in a new directory. Reuse only complete compatible indexes; do not edit `info.json` to bypass a format check.

- [2.9](https://github.com/COMBINE-lab/salmon/releases/tag/v2.9.0) introduced reproducible indexes and per-group VBEM convergence. [2.10](https://github.com/COMBINE-lab/salmon/releases/tag/v2.10.0) also uses ambiguous concordant pairs for the fragment-length distribution.
- [2.11](https://github.com/COMBINE-lab/salmon/releases/tag/v2.11.0) packs the reference for selective alignment, accepts read/FASTA FIFOs, and reports truncated FASTQ as an error.
- Missing decoy names, invalid k/minimizer/quant values, and ambiguous quantmerge sample names are rejected. For SAM/BAM input, group mates by read name; unmapped records count toward the mapping-rate denominator.
- Use **fresh output directories**. A failed rerun can remove old result tables. Zero input/mapped fragments exit nonzero even if diagnostic outputs exist. Check the command status before consuming `quant.sf`.
- The four principal operations are index, read/alignment/RAD quantification, quantmerge and diagnostic mapping. Salmon reads both legacy and piscem RAD v2; its own writer emits legacy RAD. DAAREM requires plain EM; default VBEM supports SQUAREM.

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

### Streaming without passing a host file descriptor

A host shell's process substitution (for example `<(gzip -dc reads.fq.gz)`) is not reliably visible inside a container. Save this as `stream.sh` alongside `reads.fq.gz` and a compatible `index/`, then run **`taf-salmon bash stream.sh`** with any backend. The FIFO lives in the container's private scratch; the producer status is checked.

```bash
#!/usr/bin/env bash
set -eu
scratch=$(mktemp -d)
producer=
cleanup() {
  if [ -n "$producer" ]; then kill "$producer" 2>/dev/null || :; wait "$producer" 2>/dev/null || :; fi
  rm -f -- "$scratch/reads"; rmdir -- "$scratch"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
mkfifo "$scratch/reads"
gzip -dc reads.fq.gz > "$scratch/reads" & producer=$!
salmon quant -i index -l A -r "$scratch/reads" -o streamed -p 1
wait "$producer"
producer=
```

An input cut exactly between two complete records is indistinguishable from an intentionally shorter stream; check producer status too.

For alignment input, use the same in-container producer/FIFO pattern with
`salmon quant -a "$scratch/alignment" -l A -o aligned -p 1`; send the complete
SAM/BAM including its header. Do not use `--errorModel` with a FIFO.

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
  does not produce `quant.sf`. Use fresh outputs (see upgrade notes).
- References/prepared indexes remain read-only. No analysis writes `/opt/salmon`.
  `--no-version-check`/its historical environment variable are no-ops: Salmon 2
  makes no version-check network call. Missing inputs fail, not download.

## References and Administrator-Prepared Indexes

Reference FASTA/annotations/decoys and indexes derived from them are **project
inputs and derived artifacts**. The versioned source exposes no reference/model
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

Docker and Podman run the same native OCI image on each declared platform. On Linux, Apptainer uses a read-only SIF converted from the amd64 candidate. The ordinary CLI needs neither a display nor a port. A site-provided index is read-only; the work directory and per-run scratch are writable. Current release validation and sizes belong in the release notes, not in the installed help.

## Testing and Boundaries

Independent offline smoke covers version/provenance/help, libraries, tiny indexes,
old/future index rejection, single/paired/gzip/gene-map quantification, deterministic
parallel workers, sketch, merge, alignment strandedness, genome projection,
SQUAREM, DAAREM+EM and VBEM rejection, BAM/SAM, repeated legacy RAD inference,
actual RAD v2 and mapping-only cleanup. Each mode uses unique private scratch and
emits stage/exit/log tails on failure; the immutable RAD fixture is never modified.
The 2.12 regressions also cover removed online inference, SAM/BAM FIFO and
misleading suffixes, self-input protection, truncated diagnostic input, mapping-only
sampling metadata, single-end GC fallback and thread-independent Gibbs draws.

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
[migration guide](https://github.com/COMBINE-lab/salmon/blob/v2.12.0/MIGRATION.md).
