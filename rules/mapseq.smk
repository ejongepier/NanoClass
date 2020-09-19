rule mapseq_classify:
    input:
        query = rules.prep_fasta_query.output,
        ref_tax = "db/common/ref-taxonomy.txt",
        ref_seqs = "db/common/ref-seqs.fna"
    output:
        "classifications/{run}/mapseq/{sample}.mapseq.out"
    threads:
        config["mapseq"]["threads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["mapseq"]["memory"]
    singularity:
        config["container"]
    log:
        "logs/mapseq_classify_{run}_{sample}.log"
    benchmark:
        "benchmarks/mapseq_classify_{run}_{sample}.txt"
    shell:
        """
        export LD_LIBRARY_PATH="/usr/local/lib"
        mapseq -nthreads {threads} {input.query} {input.ref_seqs} {input.ref_tax} \
            > {output} 2> {log}
        """

rule mapseq_tomat:
    input:
        out = "classifications/{run}/mapseq/{sample}.mapseq.out",
        db = "db/common/ref-taxonomy.txt"
    output:
        taxlist = "classifications/{run}/mapseq/{sample}.mapseq.taxlist",
        taxmat = "classifications/{run}/mapseq/{sample}.mapseq.taxmat",
        otumat = "classifications/{run}/mapseq/{sample}.mapseq.otumat"
    threads: 1
    singularity:
        config["container"]
    log:
        "logs/mapseq_tomat_{run}_{sample}.log"
    benchmark:
        "benchmarks/mapseq_tomat_{run}_{sample}.txt"
    shell:
        """
        scripts/tomat.py -b {input.out} -t {input.db}
        """

