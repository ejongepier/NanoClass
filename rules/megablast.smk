rule megablast_build_db:
    input:
        "db/common/ref-seqs.fna"
    output:
        touch("db/megablast/DB_BUILD")
    threads: 1
    log:
        "logs/megablast_build_db.log"
    benchmark:
        "benchmarks/megablast_build_db.txt"
    singularity:
        config["container"]
    shell:
        """
        makeblastdb -in {input} -parse_seqids \
            -dbtype nucl 2>&1 | tee -a {log}
        """


rule megablast_chunk:
    input:
        fasta = rules.prep_fasta_query.output
    output:
        expand("classifications/{{run}}/megablast/{{sample}}/{chunk}",
            chunk = range(1, (int(config["subsample"]["samplesize"]/config["megablast"]["chunksize"])+1))
        )
    params:
        lines = 2 * config["megablast"]["chunksize"],
        out_dir = "classifications/{run}/megablast/{sample}"
    shell:
        """
        split -l {params.lines} --numeric-suffixes=1 {input} {params.out_dir}/
        for chunk in {params.out_dir}/0?; do mv $chunk ${{chunk/\/0/\/}}; done
        """


rule megablast_classify:
    input:
        rules.megablast_build_db.output,
        db = "db/common/ref-seqs.fna",
        fasta = "classifications/{run}/megablast/{sample}/{chunk}"
    output:
        all = "classifications/{run}/megablast/{sample}/{chunk}.megablast.tmp",
        bestb = "classifications/{run}/megablast/{sample}/{chunk}.megablast.out"
    threads:
        config["megablast"]["threads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["megablast"]["memory"]
    singularity:
        config["container"]
    log:
        "logs/megablast_classify_{run}_{sample}_{chunk}.log"
    benchmark:
        "benchmarks/megablast_classify_{run}_{sample}_{chunk}.txt"
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
            chunk = range(1, (int(config["subsample"]["samplesize"]/config["blastn"]["chunksize"])+1))
        ),
        benchm = expand("benchmarks/megablast_classify_{{run}}_{{sample}}_{chunk}.txt",
            chunk = range(1, (int(config["subsample"]["samplesize"]/config["blastn"]["chunksize"])+1))
        )
    output:
        out = "classifications/{run}/megablast/{sample}.megablast.out",
        benchm = "benchmarks/megablast_classify_{run}_{sample}.txt"
    threads: 1
    log:
        "logs/megablast_aggregate_{run}_{sample}.log"
    benchmark:
        "benchmarks/megablast_aggregate_{run}_{sample}.txt"
    singularity:
        config["container"]
    shell:
        """
        cat {input.out} > {output.out}
        cat {input.benchm} | grep -P "^[0-9]" | \
          awk '{{sum+=$1}} END {{print "s"; print sum}}' \
          > {output.benchm}
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
    singularity:
        config["container"]
    log:
        "logs/megablast_tomat_{run}_{sample}.log"
    benchmark:
        "benchmarks/megablast_tomat_{run}_{sample}.txt"
    shell:
        """
        scripts/tomat.py -b {input.out} -t {input.db}
        """
