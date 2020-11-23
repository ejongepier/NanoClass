rule megablast_build_db:
    input:
        "db/blastn/DB_BUILD"
    output:
        touch("db/megablast/DB_BUILD")


rule megablast_chunk:
    input:
        fasta = rules.prep_fasta_query.output
    output:
        temp(expand("classifications/{{run}}/megablast/{{sample}}/{{sample}}.part-{chunk}.fasta",
            chunk = range(1, (config["megablast"]["threads"]+1))
        ))
    params:
        n_chunks = config["megablast"]["threads"],
        out_dir = "classifications/{run}/megablast/{sample}"
    conda:
        config["megablast"]["environment"]
    shell:
        """
        fasta-splitter --n-parts {params.n_chunks} {input} \
            --nopad --out-dir {params.out_dir}
        """

rule megablast_classify:
    input:
        rules.megablast_build_db.output,
        db = "db/common/ref-seqs.fna",
        fasta = "classifications/{run}/megablast/{sample}/{sample}.part-{chunk}.fasta"
    output:
        all = temp("classifications/{run}/megablast/{sample}/{chunk}.megablast.tmp"),
        bestb = temp("classifications/{run}/megablast/{sample}/{chunk}.megablast.out")
    threads: 1
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["megablast"]["memory"]
    conda:
        config["megablast"]["environment"]
    log:
        "logs/{run}/megablast_classify_{sample}_{chunk}.log"
    benchmark:
        "benchmarks/{run}/megablast_classify_{sample}_{chunk}.txt"
    shell:
        """
        blastn -task 'megablast' -db {input.db} \
            -query {input.fasta} -out {output.all} -outfmt 6 \
            2> {log} 
        cat {output.all} | sort -k1,1 -k12,12nr -k11,11n | \
            sort -u -k1,1 --merge | awk \'{{print $1\"\t\"$2}}\' | \
            LANG=en_EN sort -k2 > {output.bestb} 2> {log}
        """
   

rule megablast_aggregate:
    input:
        out = expand("classifications/{{run}}/megablast/{{sample}}/{chunk}.megablast.out",
            chunk = range(1, (config["megablast"]["threads"]+1))
        ),
        benchm = expand("benchmarks/{{run}}/megablast_classify_{{sample}}_{chunk}.txt",
            chunk = range(1, (config["megablast"]["threads"]+1))
        )
    output:
        out = temp("classifications/{run}/megablast/{sample}.megablast.out"),
        benchm = "benchmarks/{run}/megablast_classify_{sample}.txt"
    threads: 1
    params:
        threads = config["megablast"]["threads"]
    conda:
        config["megablast"]["environment"]
    log:
        "logs/{run}/megablast_aggregate_{sample}.log"
    benchmark:
        "benchmarks/{run}/megablast_aggregate_{sample}.txt"
    shell:
        """
        cat {input.out} > {output.out}
        cat {input.benchm} | grep -P "^[0-9]" | \
          awk '{{sum+=$1}} END {{print "s"; print sum / {params.threads}}}' \
          > {output.benchm} 2> {log}
        """


rule megablast_tomat:
    input:
        out = "classifications/{run}/megablast/{sample}.megablast.out",
        db = "db/common/ref-taxonomy.txt"
    output:
        taxlist = "classifications/{run}/megablast/{sample}.megablast.taxlist", 
        taxmat = "classifications/{run}/megablast/{sample}.megablast.taxmat",
        otumat = "classifications/{run}/megablast/{sample}.megablast.otumat"
    threads: 1
    conda:
        config["megablast"]["environment"]
    log:
        "logs/{run}/megablast_tomat_{sample}.log"
    benchmark:
        "benchmarks/{run}/megablast_tomat_{sample}.txt"
    shell:
        "scripts/tomat.py -b {input.out} -t {input.db} 2> {log}"
