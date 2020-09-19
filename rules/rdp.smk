rule rdp_build_db:
    input:
        seq = "db/common/ref-seqs.fna",
        tax = "db/common/ref-taxonomy.txt"
    output:
        seq = "db/rdp/ref-seqs.fna.gz",
        tax = "db/rdp/ref-taxonomy.txt"
    threads: 1
    log:
        "logs/rdp_db.log"
    benchmark:
        "benchmarks/rdp_db.txt"
    singularity:
        config["container"]
    shell:
        """
        scripts/todb.py -s {input.seq} -t {input.tax} -m rdp -S tmp.seq -T {output.tax}
        gzip -c tmp.seq > {output.seq} && rm tmp.seq 
        """


rule rdp_classify:
    input:
        db = "db/rdp/ref-seqs.fna.gz",
        query = rules.prep_fasta_query.output
    output:
        "classifications/{run}/rdp/{sample}.rdp.taxlist"
    threads:
        config["rdp"]["threads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["rdp"]["memory"]
    singularity:
        config["rdp"]["container"]
    log:
        "logs/rdp_classify_{run}_{sample}.log"
    benchmark:
        "benchmarks/rdp_classify_{run}_{sample}.txt"
    shell:
        """
        export PATH=/opt/conda/envs/R-4.0-conda-only/bin/:$PATH
        Rscript scripts/assigntaxonomy.R {input.db} {input.query} {output} {threads}
        """


rule rdp_tomat:
    input:
        list = "classifications/{run}/rdp/{sample}.rdp.taxlist",
    output:
        taxmat = "classifications/{run}/rdp/{sample}.rdp.taxmat",
        otumat = "classifications/{run}/rdp/{sample}.rdp.otumat"
    threads: 1
    singularity:
        config["container"]
    log:
        "logs/rdp_tomat_{run}_{sample}.log"
    benchmark:
        "benchmarks/rdp_tomat_{run}_{sample}.txt"
    shell:
        """
        scripts/tomat.py -l {input.list}
        """
