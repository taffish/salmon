#!/bin/sh

set -eu

mode=${1:-all}
expected_version=${SALMON_SMOKE_VERSION:-2.4.1}
work="/tmp/taf-salmon-smoke-${mode}"

cleanup() {
    rm -rf "$work"
}

trap cleanup EXIT HUP INT TERM
cleanup
mkdir -p "$work"

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
    test -s "$output/quant.sf"
    grep -F 'Name' "$output/quant.sf" >/dev/null
    grep -F 'tx1' "$output/quant.sf" >/dev/null
    grep -F 'tx2' "$output/quant.sf" >/dev/null
    grep -F "\"num_processed\": ${expected}" "$output/aux_info/meta_info.json" >/dev/null
    grep -F "\"num_mapped\": ${expected}" "$output/aux_info/meta_info.json" >/dev/null
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
    command -v salmon >/dev/null
    command -v ldd >/dev/null
    test "$(salmon --version)" = "salmon ${expected_version}"
    salmon --help 2>&1 | grep -F 'RNA-seq transcript quantification' >/dev/null
    ldd "$(command -v salmon)" > "$work/salmon.ldd"
    grep -F 'libgcc_s.so' "$work/salmon.ldd" >/dev/null
    grep -F 'libc.so' "$work/salmon.ldd" >/dev/null
    ! grep -F 'not found' "$work/salmon.ldd" >/dev/null

    write_reads_fixture
    build_index
    test -s "$work/idx/info.json"
    test -s "$work/idx/index.ssi"
    test -s "$work/idx/index.ctab"
    grep -F "\"salmon_version\": \"${expected_version}\"" "$work/idx/info.json" >/dev/null
    salmon --no-version-check quant \
        -i "$work/idx" -l A -r "$work/reads.fq" \
        -o "$work/quant" -p 1 --quiet > "$work/quant.log" 2>&1
    assert_basic_quant "$work/quant"
}

smoke_interfaces() {
    test "$(salmon --version)" = "salmon ${expected_version}"
    command -v ldd >/dev/null
    command -v locale >/dev/null
    command -v ps >/dev/null
    command -v gzip >/dev/null
    command -v od >/dev/null
    command -v awk >/dev/null
    salmon --help 2>&1 | grep -F 'RNA-seq transcript quantification' >/dev/null
    ! salmon --help 2>&1 | grep -F '(Rust port)' >/dev/null
    ! salmon --help 2>&1 | grep -F 'alevin' >/dev/null
    salmon --no-version-check --help 2>&1 | grep -F 'no-op' >/dev/null
    salmon --no-version-check index --help 2>&1 | grep -F 'Build a salmon index' >/dev/null
    salmon --no-version-check index --help 2>&1 | grep -F 'sshashTmpDir' >/dev/null
    salmon --no-version-check index --help 2>&1 | grep -F 'ramLimit' >/dev/null
    salmon --no-version-check quant --help 2>&1 | grep -F 'Quantify transcript abundances' >/dev/null
    salmon --no-version-check quant --help 2>&1 | grep -F 'writeRad' >/dev/null
    salmon --no-version-check quant --help 2>&1 | grep -F 'deterministic' >/dev/null
    salmon --no-version-check quant --help 2>&1 | grep -F 'annotation' >/dev/null
    salmon --no-version-check quant --help 2>&1 | grep -F 'writeBam' >/dev/null
    salmon --no-version-check quant --help 2>&1 | grep -F 'writeSam' >/dev/null
    salmon --no-version-check quant --help 2>&1 | grep -F 'bamCompressThreads' >/dev/null
    salmon --no-version-check quant --help 2>&1 | grep -F 'fldPolicy' >/dev/null
    salmon --no-version-check quant --help 2>&1 | grep -F 'emAccel' >/dev/null
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
    grep -F '"index_version": 1' "$work/idx/info.json" >/dev/null
    grep -F '"num_refs": 2' "$work/idx/info.json" >/dev/null
}

smoke_quant() {
    write_reads_fixture
    build_index
    gzip -c "$work/reads.fq" > "$work/reads.fq.gz"
    salmon --no-version-check quant \
        -i "$work/idx" -l A -r "$work/reads.fq.gz" \
        -o "$work/quant" -p 1 --quiet > "$work/quant.log" 2>&1
    assert_basic_quant "$work/quant"

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
    grep -F '"frag_length_source": "rad_baked_prior"' \
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
        -o "$work/daarem" -p 1 --emAccel daarem --quiet > "$work/daarem.log" 2>&1
    assert_basic_quant "$work/squarem"
    assert_basic_quant "$work/daarem"
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
        --writeRad "$work/mappings.rad" --quiet > "$work/rad-write.log" 2>&1
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
        -o "$work/deterministic" -p 1 --deterministic --quiet \
        > "$work/deterministic.log" 2>&1
    assert_basic_quant "$work/deterministic"
    grep -F '"frag_length_source": "rad_baked_prior"' \
        "$work/deterministic/aux_info/meta_info.json" >/dev/null
}

run_mode() {
    case "$1" in
        buildtime) smoke_buildtime ;;
        interfaces) smoke_interfaces ;;
        index) smoke_index ;;
        quant) smoke_quant ;;
        sketch) smoke_sketch ;;
        merge) smoke_merge ;;
        alevin) smoke_alevin ;;
        alignment) smoke_alignment ;;
        genome) smoke_genome ;;
        accel) smoke_accel ;;
        bam) smoke_bam ;;
        rad) smoke_rad ;;
        deterministic) smoke_deterministic ;;
        *)
            echo "unknown smoke mode: $1" >&2
            return 2
            ;;
    esac
}

if [ "$mode" = all ]; then
    for smoke_mode in interfaces index quant sketch merge alevin alignment genome accel bam rad deterministic; do
        sh "$0" "$smoke_mode"
    done
else
    run_mode "$mode"
fi
