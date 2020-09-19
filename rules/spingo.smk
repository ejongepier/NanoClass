rule spingo_build_db:
    input:
        seq = "db/common/ref-seqs.fna",
        tax = "db/common/ref-taxonomy.txt"
    output:
        seq = "db/spingo/ref-seqs.fna",
        tax = "db/spingo/ref-taxonomy.txt"
    threads:
        config["spingo"]["dbthreads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["spingo"]["dbmemory"]
    log:
        "logs/spingo_db.log"
    benchmark:
        "benchmarks/spingo_db.txt"
    singularity:
        config["container"]
    shell:
        """
        scripts/todb.py -s {input.seq} -t {input.tax} -m spingo \
            -S {output.seq} -T {output.tax}
        spindex -k 8 -p {threads} -d {output.seq}
        """


rule spingo_classify:
    input:
        db = "db/spingo/ref-seqs.fna",
        fasta = rules.prep_fasta_query.output
    output:
        "classifications/{run}/spingo/{sample}.spingo.taxlist"
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
          > tmp.out 2> {log}
        sed 's/ /\\t/' tmp.out | \
        awk -F '\\t' -v OFS='\\t' '{{
            if (NR == 1)
                print "#readid","Domain","Phylum","Class","Order","Family","Genus";
            else
                print $1, $4, $6, $8, $10, $12, $14
        }}' > {output} 2> {log} && rm tmp.out
        """

'''
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
'''


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
