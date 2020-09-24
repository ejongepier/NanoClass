rule minimap_classify:
    input:
        target = "db/common/ref-seqs.fna",
        query = "data/{run}/nanofilt/{sample}.subsampled.fastq.gz"
    output:
        temp("classifications/{run}/minimap/{sample}.minimap.bam")
    threads: 
        config["minimap"]["threads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["minimap"]["memory"]
    conda:
        config["minimap"]["environment"]
    #singularity:
    #    config["minimap"]["container"]
    params:
        extra = "-K 25M --no-kalloc --print-qname -aLx map-ont"
    log:
        "logs/minimap_classify_{run}_{sample}.log"
    benchmark:
        "benchmarks/minimap_classify_{run}_{sample}.txt"
    shell:
        """
        minimap2 {params.extra} -t {threads} {input.target} \
          {input.query} -o {output} 2> {log}
        """

rule minimap_bam2out:
    input:
        "classifications/{run}/minimap/{sample}.minimap.bam"
    output:
        "classifications/{run}/minimap/{sample}.minimap.out"
    threads:
        config["minimap"]["threads"]
    conda:
        config["minimap"]["environment"]
    #singularity:
    #    config["common"]["container2"]
    log:
        "logs/minimap_sortbam_{run}_{sample}.log"
    benchmark:
        "benchmarks/minimap_sortbam_{run}_{sample}.txt"
    shell:
        """
        samtools sort -@ {threads} {input} | \
        samtools view -@ {threads} -F 2308 | \
        cut -f 1,3 > {output} 2> {log}
        """

rule minimap_tomat:
    input:
        out = "classifications/{run}/minimap/{sample}.minimap.out",
        db = "db/common/ref-taxonomy.txt"
    output:
        taxlist = "classifications/{run}/minimap/{sample}.minimap.taxlist",
        taxmat = "classifications/{run}/minimap/{sample}.minimap.taxmat",
        otumat = "classifications/{run}/minimap/{sample}.minimap.otumat"
    threads: 1
    log:
        "logs/minimap_tomat_{run}_{sample}.log"
    benchmark:
        "benchmarks/minimap_tomat_{run}_{sample}.txt"
    shell:
        "scripts/tomat.py -b {input.out} -t {input.db} 2> {log}"
