rule mapseq_download_db:
    output:
        ref_tax = "db/mapseq/ref-taxonomy.txt",
        ref_seqs = "db/mapseq/ref-seqs.fna"
    threads: 1
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["mapseq"]["dbmemory"]
    params:
        url = config["mapseq"]["url"]
    singularity:
        config["container"]
    log:
        "logs/mapseq_download_db.log"
    benchmark:
        "benchmarks/mapseq_download_db.txt"
    shell:
        """
        wget -O db/mapseq/db.zip {params.url}
        unzip -p -j db/mapseq/db.zip \
            */taxonomy/16S_only/99/majority_taxonomy_7_levels.txt \
            > {output.ref_tax}
        unzip -p -j db/mapseq/db.zip \
            */rep_set/rep_set_16S_only/99/silva_132_99_16S.fna \
            > {output.ref_seqs}
        rm db/mapseq/db.zip
        """

rule mapseq_classify:
    input:
        query = rules.prep_fasta_query.output,
        ref_tax = rules.mapseq_download_db.output.ref_tax,
        ref_seqs = rules.mapseq_download_db.output.ref_seqs
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
        db = "db/mapseq/ref-taxonomy.txt"
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

