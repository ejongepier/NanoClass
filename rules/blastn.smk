rule blastn_build_db:
    input:
        "db/common/ref-seqs.fna"
    output:
        touch("db/blastn/DB_BUILD")
    threads: 1
    log:
        "logs/blastn_build_db.log"
    benchmark:
        "benchmarks/blastn_build_db.txt"
    singularity:
        config["container"]
    shell:
        """
        makeblastdb -in {input} -parse_seqids \
            -dbtype nucl 2>&1 | tee -a {log}
        """


rule blastn_chunk:
    input:
        fasta = rules.prep_fasta_query.output
    output:
        expand("classifications/{{run}}/blastn/{{sample}}/{chunk}", 
            chunk = range(1, (int(config["subsample"]["samplesize"]/config["blastn"]["chunksize"])+1))
        )
    params:
        lines = 2 * config["blastn"]["chunksize"],
        out_dir = "classifications/{run}/blastn/{sample}"
    shell:
        """
        split -l {params.lines} --numeric-suffixes=1 {input} {params.out_dir}/
        for chunk in {params.out_dir}/0?; do mv $chunk ${{chunk/\/0/\/}}; done 
        """


rule blastn_classify:
    input:
        rules.blastn_build_db.output,
        db = "db/common/ref-seqs.fna",
        fasta = "classifications/{run}/blastn/{sample}/{chunk}"
    output:
        all = "classifications/{run}/blastn/{sample}/{chunk}.blastn.tmp",
        bestb = "classifications/{run}/blastn/{sample}/{chunk}.blastn.out"
    threads:
        config["blastn"]["threads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["blastn"]["memory"]
    singularity:
        config["container"]
    log:
        "logs/blastn_classify_{run}_{sample}_{chunk}.log"
    benchmark:
        "benchmarks/blastn_classify_{run}_{sample}_{chunk}.txt"
    shell:
        """
        blastn -task 'blastn' -db {input.db} \
            -query {input.fasta} -out {output.all} -outfmt 6 \
            2> {log}
        cat {output.all} | sort -k1,1 -k12,12nr -k11,11n | \
            sort -u -k1,1 --merge | awk \'{{print $1\"\t\"$2}}\' | \
            LANG=en_EN sort -k2 > {output.bestb} 2> {log}
        """

rule blastn_aggregate:
    input:
        out = expand("classifications/{{run}}/blastn/{{sample}}/{chunk}.blastn.out",
            chunk = range(1, (int(config["subsample"]["samplesize"]/config["blastn"]["chunksize"])+1))
        ),
        benchm = expand("benchmarks/blastn_classify_{{run}}_{{sample}}_{chunk}.txt",
            chunk = range(1, (int(config["subsample"]["samplesize"]/config["blastn"]["chunksize"])+1))
        )
    output:
        out = "classifications/{run}/blastn/{sample}.blastn.out",
        benchm = "benchmarks/blastn_classify_{run}_{sample}.txt"
    threads: 1
    log:
        "logs/blastn_aggregate_{run}_{sample}.log"
    benchmark:
        "benchmarks/blastn_aggregate_{run}_{sample}.txt"
    singularity:
        config["container"]
    shell:
        """
        cat {input.out} > {output.out}
        cat {input.benchm} | grep -P "^[0-9]" | \
          awk '{{sum+=$1}} END {{print "s"; print sum}}' \
          > {output.benchm}
        """


rule blastn_tomat:
    input:
        out = "classifications/{run}/blastn/{sample}.blastn.out",
        db = "db/common/ref-taxonomy.txt"
    output:
        taxlist = "classifications/{run}/blastn/{sample}.blastn.taxlist",
        taxmat = "classifications/{run}/blastn/{sample}.blastn.taxmat",
        otumat = "classifications/{run}/blastn/{sample}.blastn.otumat"
    threads: 1
    singularity:
        config["container"]
    log:
        "logs/blastn_tomat_{run}_{sample}.log"
    benchmark:
        "benchmarks/blastn_tomat_{run}_{sample}.txt"
    shell:
        """
        scripts/tomat.py -b {input.out} -t {input.db}
        """
