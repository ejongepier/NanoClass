rule kraken_build_db:
    output:
        name_table = "db/kraken/taxonomy/names.dmp",
        tax_tree = "db/kraken/taxonomy/nodes.dmp",
        conversion_table = "db/kraken/seqid2taxid.map",
        ref_seqs = "db/kraken/data/SILVA_132_SSURef_Nr99_tax_silva.fasta"
    threads:
        config["kraken"]["dbthreads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["kraken"]["dbmemory"]
    params:
        db = "db/kraken",
        db_type = config["kraken"]["dbtype"]
    conda:
        config["kraken"]["environment"]
    #singularity:
    #    config["kraken"]["container"]
    log:
        "logs/kraken_build_db.log"
    benchmark:
        "benchmarks/kraken_build_db.txt"
    shell:
        """
        kraken2-build --db {params.db} --special {params.db_type} \
          --threads {threads} > {log} 2> {log}
        """

rule kraken_classify:
    input:
        rules.kraken_build_db.output,
        fastq = "data/{run}/nanofilt/{sample}.subsampled.fastq.gz"
    output:
        report = "classifications/{run}/kraken/{sample}.kraken.report",
        out = "classifications/{run}/kraken/{sample}.kraken.out"
    threads:
        config["kraken"]["threads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["kraken"]["memory"]
    params:
        db_dir = "db/kraken"
    conda:
        config["kraken"]["environment"]
    #singularity:
    #    config["kraken"]["container"]
    log:
        "logs/kraken_classify_{run}_{sample}.log"
    benchmark:
        "benchmarks/kraken_classify_{run}_{sample}.txt"
    shell:
        """
        kraken2 --db {params.db_dir} \
            --output {output.out} \
            --report {output.report} \
            --gzip-compressed \
            --threads {threads} {input.fastq} 2> {log}
        """


rule kraken_tomat:
    input:
        kraken_out = "classifications/{run}/kraken/{sample}.kraken.out",
        silva_seqs = "db/kraken/data/SILVA_132_SSURef_Nr99_tax_silva.fasta",
        kraken_map = "db/kraken/seqid2taxid.map"
    output:
        taxlist = "classifications/{run}/kraken/{sample}.kraken.taxlist",
        taxmat = "classifications/{run}/kraken/{sample}.kraken.taxmat",
        otumat = "classifications/{run}/kraken/{sample}.kraken.otumat"
    threads: 1
    log:
        "logs/kraken_tomat_{run}_{sample}.log"
    benchmark:
        "benchmarks/kraken_tomat_{run}_{sample}.txt"
    shell:
        """
        scripts/tomat.py -k {input.kraken_out} -f {input.silva_seqs} \
          -m {input.kraken_map} 2> {log}
        """

