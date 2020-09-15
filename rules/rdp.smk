rule rdp_download_db:
    output:
        "db/rdp/train_set.fa.gz"
    threads: 1
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["rdp"]["dbmemory"]
    singularity:
        config["container"]
    params:
        url = config["rdp"]["dburl"]
    log:
        "logs/rdp_downl_db.log"
    benchmark:
        "benchmarks/rdp_downl_db.txt"
    shell:
        """
        export PATH=/opt/conda/envs/R-4.0-conda-only/bin/:$PATH
        wget {params.url} -O {output} 2> {log}
        """


rule rdp_classify:
    input:
        db = rules.rdp_download_db.output,
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
