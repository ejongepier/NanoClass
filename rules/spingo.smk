rule spingo_build_db:
    input:
        "db/centrifuge/data/SILVA_132_SSURef_Nr99_tax_silva.fasta"
    output:
        "db/spingo/ref-seqs.fasta"
    threads:
        config["spingo"]["dbthreads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["spingo"]["dbmemory"]
    singularity:
        config["container"]
    log:
        "logs/spingo_db.log"
    benchmark:
        "benchmarks/spingo_db.txt"
    shell:
        """
        cat {input} | \
        sed 's/ /]\t/' | \
        awk -F '\\t|;' -v OFS='\\t' '{{
            if ($1 ~ />/) \
                print $1, $8, $7, $6, $5, $4, $3, $2; \
            else \
                print $1
            }}' > {output}
        spindex -k 8 -p {threads} -d {output}
        """


rule spingo_classify:
    input:
        db = "db/spingo/ref-seqs.fasta",
        fasta = rules.prep_fasta_query.output
    output:
        "classifications/{run}/spingo/{sample}.spingo.out"
    threads:
        config["spingo"]["threads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["spingo"]["memory"]
    singularity:
        config["container"]
    log:
        "logs/spingo_classify_{run}_{sample}.log"
    benchmark:
        "benchmarks/spingo_classify_{run}_{sample}.txt"
    shell:
        """
        spingo -d {input.db} -k 8 -a \
          -p {threads} -i {input.fasta} \
          > {output} 2> {log}
        """


rule spingo_taxlist:
    input:
        "classifications/{run}/spingo/{sample}.spingo.out"
    output:
        "classifications/{run}/spingo/{sample}.spingo.taxlist"
    threads: 1
    singularity:
        config["container"]
    log:
        "logs/spingo_taxlist_{run}_{sample}.log"
    benchmark:
        "benchmarks/spingo_taxlist_{run}_{sample}.txt"
    shell:
        """
        sed 's/ /\\t/' {input} | \
        awk -F '\\t' -v OFS='\\t' '{{
            if (NR == 1) 
                print "#readid","Domain","Phylum","Class","Order","Family","Genus";
            else
                print $1, $4, $6, $8, $10, $12, $14
        }}' > {output}
        """



rule spingo_tomat:
    input:
        list = "classifications/{run}/spingo/{sample}.spingo.taxlist",
    output:
        taxmat = "classifications/{run}/spingo/{sample}.spingo.taxmat",
        otumat = "classifications/{run}/spingo/{sample}.spingo.otumat"
    threads: 1
    singularity:
        config["container"]
    log:
        "logs/spingo_tomat_{run}_{sample}.log"
    benchmark:
        "benchmarks/spingo_tomat_{run}_{sample}.txt"
    shell:
        """
        scripts/tomat.py -l {input.list}
        """
