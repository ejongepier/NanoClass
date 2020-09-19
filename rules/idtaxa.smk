rule idtaxa_build_db:
    input:
        ref_seqs = "db/common/ref-seqs.fna",
        ref_tax = "db/common/ref-taxonomy.txt"
    output:
        "db/idtaxa/ref-db.Rdata"
    threads: 1
    singularity:
        config["idtaxa"]["container"]
    log:
        "logs/idtaxa_learn_taxa.log"
    benchmark:
        "benchmarks/idtaxa_learn_taxa.txt"
    shell:
        """
        export PATH=/opt/conda/envs/R-4.0-conda-only/bin/:$PATH
        Rscript scripts/learntaxa.R {input.ref_seqs} {input.ref_tax} {output}
        """


rule idtaxa_classify:
    input:
        db = "db/idtaxa/ref-db.Rdata",
        query = rules.prep_fasta_query.output
    output:
        "classifications/{run}/idtaxa/{sample}.idtaxa.taxlist"
    threads:
        config["idtaxa"]["threads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["idtaxa"]["memory"]
    singularity:
        config["idtaxa"]["container"]
    log:
        "logs/idtaxa_classify_{run}_{sample}.log"
    benchmark:
        "benchmarks/idtaxa_classify_{run}_{sample}.txt"
    shell:
        """
        export PATH=/opt/conda/envs/R-4.0-conda-only/bin/:$PATH
        Rscript scripts/idtaxa.R {input.db} {input.query} {output} {threads}
        """

rule idtaxa_tomat:
    input:
        list = "classifications/{run}/idtaxa/{sample}.idtaxa.taxlist",
    output:
        taxmat = "classifications/{run}/idtaxa/{sample}.idtaxa.taxmat",
        otumat = "classifications/{run}/idtaxa/{sample}.idtaxa.otumat"
    threads: 1
    singularity:
        config["container"]
    log:
        "logs/idtaxa_tomat_{run}_{sample}.log"
    benchmark:
        "benchmarks/idtaxa_tomat_{run}_{sample}.txt"
    shell:
        """
        scripts/tomat.py -l {input.list}
        """

