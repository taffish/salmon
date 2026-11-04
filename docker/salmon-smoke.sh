#!/bin/sh

set -eu

mode=${1:-all}
expected_version=${SALMON_SMOKE_VERSION:-2.11.0}
case "$mode" in *[!a-z0-9-]*|'') echo 'invalid smoke mode' >&2; exit 2 ;; esac
umask 077
work=$(mktemp -d "/tmp/taf-salmon-smoke-${mode}.XXXXXX")

cleanup() {
    status=$?
    trap - EXIT
    if [ -n "${writer:-}" ]; then kill "$writer" 2>/dev/null || :; wait "$writer" 2>/dev/null || :; fi
    if [ "$status" -ne 0 ]; then
        printf 'smoke-stage=%s exit=%s\n' "$mode" "$status" >&2
        for log in "$work"/*.log "$work"/*.out "$work"/*.ldd; do
            [ -f "$log" ] || continue
            printf 'log=%s\n' "${log##*/}" >&2
            tail -n 40 "$log" >&2
        done
    fi
    rm -rf -- "$work"
    exit "$status"
}

trap cleanup EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

write_reads_fixture() {
    cat > "$work/transcripts.fa" <<'EOF'
>tx1
ACGTACGTACGTACGTACGTACGTACGTACGTACGTACGT
>tx2
TTTTGGGGCCCCAAAATTTTGGGGCCCCAAAATTTTGGGG
EOF

    cat > "$work/reads.fq" <<'EOF'
@r1
ACGTACGTACGTACGTACGT
+
FFFFFFFFFFFFFFFFFFFF
@r2
TTTTGGGGCCCCAAAATTTT
+
FFFFFFFFFFFFFFFFFFFF
@r3
ACGTACGTACGTACGTACGT
+
FFFFFFFFFFFFFFFFFFFF
EOF
}

build_index() {
    salmon --no-version-check index \
        -t "$work/transcripts.fa" \
        -i "$work/idx" \
        -k 15 \
        -p 1 \
        --quiet > "$work/index.log" 2>&1
}

assert_basic_quant() {
    output=$1
    expected=${2:-3}
    inference=${3:-deterministic}
    test -s "$output/quant.sf"
    grep -F 'Name' "$output/quant.sf" >/dev/null
    grep -F 'tx1' "$output/quant.sf" >/dev/null
    grep -F 'tx2' "$output/quant.sf" >/dev/null
    grep -F "\"num_processed\": ${expected}" "$output/aux_info/meta_info.json" >/dev/null
    grep -F "\"num_mapped\": ${expected}" "$output/aux_info/meta_info.json" >/dev/null
    grep -F "\"inference_path\": \"${inference}\"" \
        "$output/aux_info/meta_info.json" >/dev/null
    awk -v expected="$expected" '
        NR > 1 { total += $5 }
        END {
            delta = total - expected
            if (delta < 0) delta = -delta
            exit !(delta < 0.001)
        }
    ' "$output/quant.sf"
}

smoke_buildtime() {
    # Keep the build gate architecture-neutral; linkage, flags and inference
    # belong to the runtime suite, not a particular help layout or CPU count.
    command -v salmon >/dev/null
    salmon --version > "$work/version.out"
    awk -v v="$expected_version" '$1 == "salmon" && $2 == v {ok=1} END {exit !ok}' "$work/version.out"
    grep -Fx "version=${expected_version}" /opt/salmon/share/source.txt >/dev/null
}

smoke_interfaces() {
    test "$(salmon --version)" = "salmon ${expected_version}"
    command -v ldd >/dev/null
    command -v locale >/dev/null
    command -v ps >/dev/null
    command -v gzip >/dev/null
    command -v od >/dev/null
    command -v awk >/dev/null
    command -v cmp >/dev/null
    grep -F 'upstream=COMBINE-lab/salmon' /opt/salmon/share/source.txt >/dev/null
    grep -F "version=${expected_version}" /opt/salmon/share/source.txt >/dev/null
    grep -F 'commit=13a170dcd3d04ecfaaf140db80158fad6d58a837' \
        /opt/salmon/share/source.txt >/dev/null
    salmon --help > "$work/top.help" 2>&1
    grep -F 'RNA-seq transcript quantification' "$work/top.help" >/dev/null
    ldd "$(command -v salmon)" > "$work/salmon.ldd"
    grep -F 'libc.so' "$work/salmon.ldd" >/dev/null
    grep -F 'libgcc_s.so' "$work/salmon.ldd" >/dev/null
    if grep -F 'not found' "$work/salmon.ldd"; then return 1; fi
    salmon --no-version-check --help 2>&1 | grep -F 'no-op' >/dev/null
    salmon --no-version-check index --help 2>&1 | grep -F 'Build a salmon index' >/dev/null
    salmon --no-version-check index --help 2>&1 | grep -F 'sshashTmpDir' >/dev/null
    salmon --no-version-check index --help 2>&1 | grep -F 'ramLimit' >/dev/null
    salmon --no-version-check quant --help > "$work/quant.help" 2>&1
    grep -F 'Quantify transcript abundances' "$work/quant.help" >/dev/null
    grep -F 'writeRad' "$work/quant.help" >/dev/null
    grep -F 'deterministic' "$work/quant.help" >/dev/null
    grep -F -- '--online' "$work/quant.help" >/dev/null
    grep -F 'radScratchDir' "$work/quant.help" >/dev/null
    grep -F 'radCompress' "$work/quant.help" >/dev/null
    grep -F 'skipQuant' "$work/quant.help" >/dev/null
    grep -F 'errorModel' "$work/quant.help" >/dev/null
    grep -F 'annotation' "$work/quant.help" >/dev/null
    grep -F -- '--decoder' "$work/quant.help" >/dev/null
    grep -F -- '--threadPolicy' "$work/quant.help" >/dev/null
    grep -F 'writeBam' "$work/quant.help" >/dev/null
    grep -F 'writeSam' "$work/quant.help" >/dev/null
    grep -F 'bamCompressThreads' "$work/quant.help" >/dev/null
    grep -F 'fldPolicy' "$work/quant.help" >/dev/null
    grep -F 'emAccel' "$work/quant.help" >/dev/null
    salmon --no-version-check quantmerge --help 2>&1 | grep -F 'Merge a column across multiple samples' >/dev/null
    salmon --no-version-check debug-map --help 2>&1 | grep -F 'per-read best-mapping detail' >/dev/null
}

smoke_index() {
    write_reads_fixture
    build_index
    test -s "$work/idx/info.json"
    test -s "$work/idx/index.ssi"
    test -s "$work/idx/index.ctab"
    grep -F "\"salmon_version\": \"${expected_version}\"" "$work/idx/info.json" >/dev/null
    grep -F '"index_version": 3' "$work/idx/info.json" >/dev/null
    grep -F '"sshash_format_version": 6' "$work/idx/info.json" >/dev/null
    grep -F '"num_refs": 2' "$work/idx/info.json" >/dev/null
}

smoke_compatibility() {
    write_reads_fixture
    build_index

    cp -R "$work/idx" "$work/idx-old"
    sed -i 's/"index_version": 3/"index_version": 1/' \
        "$work/idx-old/info.json"
    if salmon --no-version-check quant \
        -i "$work/idx-old" -l A -r "$work/reads.fq" \
        -o "$work/old-quant" -p 1 > "$work/old-index.log" 2>&1; then
        return 1
    fi
    grep -F 'requires index format v3+' "$work/old-index.log" >/dev/null
    grep -F 'rebuild it with' "$work/old-index.log" >/dev/null

    cp -R "$work/idx" "$work/idx-future"
    sed -i 's/"index_version": 3/"index_version": 999/' \
        "$work/idx-future/info.json"
    if salmon --no-version-check quant \
        -i "$work/idx-future" -l A -r "$work/reads.fq" \
        -o "$work/future-quant" -p 1 > "$work/future-index.log" 2>&1; then
        return 1
    fi
    grep -F 'newer than this salmon understands' \
        "$work/future-index.log" >/dev/null
    grep -Fi 'upgrade salmon' "$work/future-index.log" >/dev/null
}

smoke_quant() {
    write_reads_fixture
    build_index
    gzip -c "$work/reads.fq" > "$work/reads.compressed"
    printf '{"parallel_decode":{"min_threads_per_stream":16}}\n' > "$work/thread-policy.json"
    printf 'tx1\tgene1\ntx2\tgene2\n' > "$work/genes.tsv"
    gzip -c "$work/genes.tsv" > "$work/genes.compressed"
    salmon --no-version-check quant \
        -i "$work/idx" -l A -r "$work/reads.compressed" \
        --decoder serial --threadPolicy "$work/thread-policy.json" \
        --geneMap "$work/genes.compressed" \
        -o "$work/quant" -p 1 --quiet > "$work/quant.log" 2>&1
    assert_basic_quant "$work/quant"
    test -s "$work/quant/quant.genes.sf"
    grep -F 'gene1' "$work/quant/quant.genes.sf" >/dev/null
    grep -F 'gene2' "$work/quant/quant.genes.sf" >/dev/null

    cat > "$work/reads_1.fq" <<'EOF'
@p1/1
ACGTACGTACGTACGTACGT
+
FFFFFFFFFFFFFFFFFFFF
@p2/1
TTTTGGGGCCCCAAAATTTT
+
FFFFFFFFFFFFFFFFFFFF
EOF

    cat > "$work/reads_2.fq" <<'EOF'
@p1/2
ACGTACGTACGTACGTACGT
+
FFFFFFFFFFFFFFFFFFFF
@p2/2
CCCCAAAATTTTGGGGCCCC
+
FFFFFFFFFFFFFFFFFFFF
EOF
    gzip -c "$work/reads_1.fq" > "$work/reads_1.fq.gz"
    gzip -c "$work/reads_2.fq" > "$work/reads_2.fq.gz"
    salmon --no-version-check quant \
        -i "$work/idx" -l A \
        -1 "$work/reads_1.fq.gz" -2 "$work/reads_2.fq.gz" \
        -o "$work/paired" -p 1 --quiet > "$work/paired.log" 2>&1
    assert_basic_quant "$work/paired" 2
}

smoke_pool() {
    write_reads_fixture
    build_index
    : > "$work/pool.fq"
    record=1
    while [ "$record" -le 200 ]; do
        printf '@pool%s\nACGTACGTACGTACGTACGT\n+\nFFFFFFFFFFFFFFFFFFFF\n' \
            "$record" >> "$work/pool.fq"
        record=$((record + 1))
    done
    gzip -c "$work/pool.fq" > "$work/pool.fq.gz"

    salmon --no-version-check quant \
        -i "$work/idx" -l A -r "$work/pool.fq.gz" \
        -o "$work/pool-one" -p 1 --decoder serial \
        > "$work/pool-one.log" 2>&1
    assert_basic_quant "$work/pool-one" 200

    iteration=1
    while [ "$iteration" -le 2 ]; do
        output="$work/pool-${iteration}"
        salmon --no-version-check quant \
            -i "$work/idx" -l A -r "$work/pool.fq.gz" \
            -o "$output" -p 8 --decoder parallel \
            > "$work/pool-${iteration}.log" 2>&1
        assert_basic_quant "$output" 200
        grep -F 'decoder selected by request: parallel' \
            "$work/pool-${iteration}.log" >/dev/null
        grep -F 'thread execution plan' "$work/pool-${iteration}.log" >/dev/null
        grep -E 'mapping reads \(selective-alignment mode, [1-8] threads?\)' \
            "$work/pool-${iteration}.log" >/dev/null
        iteration=$((iteration + 1))
    done
    cmp "$work/pool-one/quant.sf" "$work/pool-1/quant.sf"
    cmp "$work/pool-1/quant.sf" "$work/pool-2/quant.sf"
}

smoke_sketch() {
    write_reads_fixture
    build_index
    salmon --no-version-check quant \
        -i "$work/idx" -l A -r "$work/reads.fq" \
        -o "$work/sketch" -p 1 --sketch --quiet > "$work/sketch.log" 2>&1
    assert_basic_quant "$work/sketch"
}

smoke_merge() {
    mkdir -p "$work/q1" "$work/q2"
    printf 'Name\tLength\tEffectiveLength\tTPM\tNumReads\ntx1\t40\t2.432\t100.0\t2.0\ntx2\t40\t2.432\t0.0\t0.0\n' > "$work/q1/quant.sf"
    printf 'Name\tLength\tEffectiveLength\tTPM\tNumReads\ntx1\t40\t2.432\t10.0\t1.0\ntx2\t40\t2.432\t90.0\t9.0\n' > "$work/q2/quant.sf"
    salmon --no-version-check quantmerge \
        --quants "$work/q1" "$work/q2" \
        --names s1 s2 --column TPM \
        -o "$work/merged.tsv" > "$work/merge.log" 2>&1
    grep -F 'Name' "$work/merged.tsv" >/dev/null
    grep -F 'tx2' "$work/merged.tsv" >/dev/null
    grep -F '90' "$work/merged.tsv" >/dev/null
}

smoke_alevin() {
    if salmon --no-version-check alevin > "$work/alevin.out" 2>&1; then
        return 1
    fi
    grep -F 'salmon alevin is not available' "$work/alevin.out" >/dev/null
    grep -F 'alevin-fry' "$work/alevin.out" >/dev/null
}

smoke_alignment() {
    cat > "$work/se.sam" <<'EOF'
@HD	VN:1.6	SO:unsorted
@SQ	SN:tx0	LN:5000
fwd0	0	tx0	2	60	100M	*	0	0	*	*
rev0	16	tx0	202	60	100M	*	0	0	*	*
EOF
    salmon --no-version-check quant -a "$work/se.sam" -l U --noErrorModel -o "$work/u" -p 1 --quiet > "$work/u.log" 2>&1
    salmon --no-version-check quant -a "$work/se.sam" -l SF --noErrorModel -o "$work/sf" -p 1 --quiet > "$work/sf.log" 2>&1
    salmon --no-version-check quant -a "$work/se.sam" -l SR --noErrorModel -o "$work/sr" -p 1 --quiet > "$work/sr.log" 2>&1
    test -s "$work/u/quant.sf"
    test -s "$work/sf/quant.sf"
    test -s "$work/sr/quant.sf"
    grep -F '"num_processed": 2' "$work/u/aux_info/meta_info.json" >/dev/null
    grep -F '"num_mapped": 2' "$work/u/aux_info/meta_info.json" >/dev/null
    grep -F '"num_mapped": 1' "$work/sf/aux_info/meta_info.json" >/dev/null
    grep -F '"num_mapped": 1' "$work/sr/aux_info/meta_info.json" >/dev/null
    # In alignment mode, unmapped records are part of the rate denominator.
    printf 'unmapped\t4\t*\t0\t0\t*\t*\t0\t0\tACGT\tIIII\n' >> "$work/se.sam"
    salmon quant -a "$work/se.sam" -l U --noErrorModel -o "$work/mixed" -p 1 > "$work/mixed.log" 2>&1
    grep -F '"num_processed": 3' "$work/mixed/aux_info/meta_info.json" >/dev/null
    grep -F '"num_mapped": 2' "$work/mixed/aux_info/meta_info.json" >/dev/null
}

smoke_genome() {
    cat > "$work/genes.gtf" <<'EOF'
chr1	test	exon	1	100	.	+	.	gene_id "g1"; transcript_id "tx1";
chr1	test	exon	201	300	.	-	.	gene_id "g2"; transcript_id "tx2";
EOF

    cat > "$work/genome.sam" <<'EOF'
@HD	VN:1.6	SO:queryname
@SQ	SN:chr1	LN:1000
r1	0	chr1	1	60	20M	*	0	0	ACGTACGTACGTACGTACGT	FFFFFFFFFFFFFFFFFFFF	AS:i:40
r2	16	chr1	281	60	20M	*	0	0	AAAATTTTGGGGCCCCAAAA	FFFFFFFFFFFFFFFFFFFF	AS:i:40
EOF

    salmon --no-version-check quant \
        -a "$work/genome.sam" --annotation "$work/genes.gtf" \
        -l U --noErrorModel -o "$work/genome" -p 1 --quiet \
        > "$work/genome.log" 2>&1
    test -s "$work/genome/quant.sf"
    grep -F 'tx1' "$work/genome/quant.sf" >/dev/null
    grep -F 'tx2' "$work/genome/quant.sf" >/dev/null
    grep -F '"num_processed": 2' "$work/genome/aux_info/meta_info.json" >/dev/null
    grep -F '"num_mapped": 2' "$work/genome/aux_info/meta_info.json" >/dev/null
    grep -F '"frag_length_source": "prior"' \
        "$work/genome/aux_info/meta_info.json" >/dev/null
    grep -F '"inference_path": "deterministic"' \
        "$work/genome/aux_info/meta_info.json" >/dev/null
}

smoke_accel() {
    write_reads_fixture
    build_index
    salmon --no-version-check quant \
        -i "$work/idx" -l A -r "$work/reads.fq" \
        -o "$work/squarem" -p 1 --emAccel squarem --quiet > "$work/squarem.log" 2>&1
    salmon --no-version-check quant \
        -i "$work/idx" -l A -r "$work/reads.fq" \
        -o "$work/daarem" -p 1 --useEM --emAccel daarem --quiet > "$work/daarem.log" 2>&1
    assert_basic_quant "$work/squarem"
    assert_basic_quant "$work/daarem"
    if salmon --no-version-check quant \
        -i "$work/idx" -l A -r "$work/reads.fq" \
        -o "$work/invalid-vbem" -p 1 --emAccel daarem \
        > "$work/invalid-vbem.log" 2>&1; then
        echo 'DAAREM with default VBEM was unexpectedly accepted' >&2
        return 1
    fi
    grep -F -- '--emAccel daarem requires plain EM' "$work/invalid-vbem.log" >/dev/null
    test ! -e "$work/invalid-vbem/quant.sf"
}

smoke_radv2() {
    od -An -tx1 -N8 /opt/salmon/share/piscem-v2.rad | grep -F '52 41 44 5f 46 49 4c 45' >/dev/null
    salmon quant --rad /opt/salmon/share/piscem-v2.rad -l IU \
        --fldPolicy prior --fldMean 200 --fldSD 20 -o "$work/v2" -p 1 \
        > "$work/radv2.log" 2>&1
    grep -F '"num_processed": 400' "$work/v2/aux_info/meta_info.json" >/dev/null
    grep -F '"num_mapped": 400' "$work/v2/aux_info/meta_info.json" >/dev/null
    awk 'NR>1 { total+=$5; if ($1=="t0" && $5>299 && $5<301) a=1; if ($1=="t1" && $5>99 && $5<101) b=1 }
         END { exit !(a && b && total>399.999 && total<400.001) }' "$work/v2/quant.sf"
}

smoke_bam() {
    write_reads_fixture
    build_index
    salmon --no-version-check quant \
        -i "$work/idx" -l A -r "$work/reads.fq" \
        -o "$work/bam-quant" -p 1 \
        --writeBam "$work/mappings.bam" --bamCompressThreads 1 --quiet \
        > "$work/bam.log" 2>&1
    salmon --no-version-check quant \
        -i "$work/idx" -l A -r "$work/reads.fq" \
        -o "$work/sam-quant" -p 1 \
        --writeSam "$work/mappings.sam" --quiet > "$work/sam.log" 2>&1
    assert_basic_quant "$work/bam-quant"
    assert_basic_quant "$work/sam-quant"
    test -s "$work/mappings.bam"
    gzip -dc "$work/mappings.bam" > "$work/mappings.raw"
    od -An -tx1 -N4 "$work/mappings.raw" | grep -F '42 41 4d 01' >/dev/null
    grep -F '@PG' "$work/mappings.sam" >/dev/null
    grep -F 'r1' "$work/mappings.sam" >/dev/null
    salmon --no-version-check quant \
        -a "$work/mappings.bam" -l U --noErrorModel \
        -o "$work/bam-input" -p 1 --quiet > "$work/bam-input.log" 2>&1
    assert_basic_quant "$work/bam-input"
}

smoke_rad() {
    write_reads_fixture
    build_index
    salmon --no-version-check quant \
        -i "$work/idx" -l A -r "$work/reads.fq" \
        -o "$work/rad-write" -p 1 \
        --writeRad "$work/mappings.rad" --radCompress zstd --quiet \
        > "$work/rad-write.log" 2>&1
    test -s "$work/mappings.rad"
    assert_basic_quant "$work/rad-write"

    iteration=1
    while [ "$iteration" -le 8 ]; do
        output="$work/rad-${iteration}"
        salmon --no-version-check quant \
            --rad "$work/mappings.rad" \
            -o "$output" -p 1 \
            --fldPolicy prior --fldMean 250 --fldSD 25 --quiet \
            > "$work/rad-${iteration}.log" 2>&1
        assert_basic_quant "$output"
        grep -F '"frag_length_source": "prior"' "$output/aux_info/meta_info.json" >/dev/null
        iteration=$((iteration + 1))
    done
}

smoke_deterministic() {
    write_reads_fixture
    build_index
    salmon --no-version-check quant \
        -i "$work/idx" -l A -r "$work/reads.fq" \
        -o "$work/default" -p 1 --quiet > "$work/default.log" 2>&1
    salmon --no-version-check quant \
        -i "$work/idx" -l A -r "$work/reads.fq" \
        -o "$work/flagged" -p 1 --deterministic --quiet \
        > "$work/flagged.log" 2>&1
    salmon --no-version-check quant \
        -i "$work/idx" -l A -r "$work/reads.fq" \
        -o "$work/online" -p 1 --online \
        > "$work/online.log" 2>&1
    assert_basic_quant "$work/default"
    assert_basic_quant "$work/flagged"
    assert_basic_quant "$work/online" 3 online
    cmp "$work/default/quant.sf" "$work/flagged/quant.sf"
    grep -F '"frag_length_source": "prior"' \
        "$work/default/aux_info/meta_info.json" >/dev/null
    grep -Fi 'deprecated' "$work/online.log" >/dev/null
    if find "$work/default" "$work/flagged" -type f -name '*.rad' | grep . >/dev/null; then
        return 1
    fi

    if salmon --no-version-check quant \
        -i "$work/idx" -l A -r "$work/reads.fq" \
        -o "$work/conflict" -p 1 --online --deterministic \
        > "$work/conflict.log" 2>&1; then
        return 1
    fi
    grep -F "cannot be used with '--deterministic'" "$work/conflict.log" >/dev/null
}

smoke_skip() {
    write_reads_fixture
    build_index
    mkdir -p "$work/scratch"
    salmon --no-version-check quant \
        -i "$work/idx" -l A -r "$work/reads.fq" \
        -o "$work/skip" -p 1 --skipQuant \
        --radScratchDir "$work/scratch" --quiet > "$work/skip.log" 2>&1
    test ! -e "$work/skip/quant.sf"
    test -s "$work/skip/aux_info/meta_info.json"
    grep -F '"inference_path": "none"' \
        "$work/skip/aux_info/meta_info.json" >/dev/null
    test "$(find "$work/skip" -maxdepth 1 -type f -name '*.rad' | wc -l)" -eq 1
    test "$(find "$work/scratch" -mindepth 1 -print | wc -l)" -eq 0
}

smoke_streams() {
    write_reads_fixture
    build_index
    # Each FIFO is created inside this process's private /tmp. Keep the writer
    # PID so a failed reader cannot leave a child blocked on open.
    mkfifo "$work/input.pipe"
    cat "$work/transcripts.fa" > "$work/input.pipe" & writer=$!
    salmon index -t "$work/input.pipe" -i "$work/pipe-index" -k 15 -p 1 \
        > "$work/index-stream.log" 2>&1
    wait "$writer"; writer=
    (cd "$work/idx"; find . -type f | LC_ALL=C sort) > "$work/files"
    (cd "$work/pipe-index"; find . -type f | LC_ALL=C sort) > "$work/files-new"
    cmp "$work/files" "$work/files-new"
    while IFS= read -r member; do
        cmp "$work/idx/$member" "$work/pipe-index/$member"
    done < "$work/files"
    cat "$work/reads.fq" > "$work/input.pipe" & writer=$!
    salmon quant -i "$work/pipe-index" -l U -r "$work/input.pipe" -o "$work/from-pipe" -p 1 \
        > "$work/quant-stream.log" 2>&1
    wait "$writer"; writer=
    assert_basic_quant "$work/from-pipe"
}

smoke_validation() {
    write_reads_fixture
    build_index
    printf 'tx1\tg1\ntx2\tg2\n' > "$work/genes.tsv"
    salmon quant -i "$work/idx" -l U -r "$work/reads.fq" --geneMap "$work/genes.tsv" \
        -o "$work/rerun" -p 1 > "$work/first.log" 2>&1
    test -s "$work/rerun/quant.sf"; test -s "$work/rerun/quant.genes.sf"
    cp "$work/reads.fq" "$work/truncated.fq"
    printf '@incomplete\nACGT\n' >> "$work/truncated.fq"
    if salmon quant -i "$work/idx" -l U -r "$work/truncated.fq" -o "$work/rerun" -p 1 \
         > "$work/cut.log" 2>&1; then return 1; fi
    grep -F 'truncated.fq' "$work/cut.log" >/dev/null
    grep -Ei 'FASTQ record|truncated' "$work/cut.log" >/dev/null
    test ! -e "$work/rerun/quant.sf"; test ! -e "$work/rerun/quant.genes.sf"
    printf '@zero\nCCCCCCCCCCCCCCCCCCCC\n+\nFFFFFFFFFFFFFFFFFFFF\n' > "$work/zero.fq"
    if salmon quant -i "$work/idx" -l U -r "$work/zero.fq" -o "$work/zero" -p 1 \
        > "$work/zero.log" 2>&1; then return 1; fi
    grep -F '0 fragments mapped' "$work/zero.log" >/dev/null
    test -s "$work/zero/quant.sf"
    grep -F '"num_mapped": 0' "$work/zero/aux_info/meta_info.json" >/dev/null
    printf 'unknown-decoy\n' > "$work/decoys"
    if salmon index -t "$work/transcripts.fa" -d "$work/decoys" -k 15 -p 1 \
        -i "$work/invalid" > "$work/decoy.log" 2>&1; then return 1; fi
    grep -F 'unknown-decoy' "$work/decoy.log" >/dev/null
    if salmon quantmerge --quants "$work/zero" "$work/zero" --names same same \
        --column TPM -o "$work/rejected.tsv" > "$work/duplicate.log" 2>&1; then return 1; fi
    grep -Fi 'same' "$work/duplicate.log" >/dev/null
    test ! -s "$work/rejected.tsv"
}

run_mode() {
    case "$1" in
        buildtime) smoke_buildtime ;;
        interfaces) smoke_interfaces ;;
        index) smoke_index ;;
        compatibility) smoke_compatibility ;;
        quant) smoke_quant ;;
        pool) smoke_pool ;;
        sketch) smoke_sketch ;;
        merge) smoke_merge ;;
        alevin) smoke_alevin ;;
        alignment) smoke_alignment ;;
        genome) smoke_genome ;;
        accel) smoke_accel ;;
        bam) smoke_bam ;;
        rad) smoke_rad ;;
        radv2) smoke_radv2 ;;
        deterministic) smoke_deterministic ;;
        skip) smoke_skip ;;
        streams) smoke_streams ;;
        validation) smoke_validation ;;
        *)
            echo "unknown smoke mode: $1" >&2
            return 2
            ;;
    esac
}

if [ "$mode" = all ]; then
    for smoke_mode in interfaces index compatibility quant pool sketch merge alevin alignment genome accel bam rad radv2 deterministic skip streams validation; do
        sh "$0" "$smoke_mode"
    done
else
    run_mode "$mode"
fi
