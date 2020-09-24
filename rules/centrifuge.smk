rule centrifuge_get_db:
    input:
        seq = "db/common/ref-seqs.fna",
        tax = "db/common/ref-taxonomy.txt"
    output:
        name_table = "db/centrifuge/taxonomy/names.dmp",
        tax_tree = "db/centrifuge/taxonomy/nodes.dmp",
        tax_map = "db/centrifuge/ref-tax.map",
        ref_seqs = "db/centrifuge/ref-seqs.fna",
        ref_tax = "db/centrifuge/ref-taxonomy.txt"
    threads: 1
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["centrifuge"]["dbmemory"]
    params:
        url = config["centrifuge"]["taxmapurl"]
    #singularity:
    #    config["centrifuge"]["container"]
    conda:
        config["centrifuge"]["environment"]
    log:
        "logs/centrifuge_get_db.log"
    benchmark:
        "benchmarks/centrifuge_get_db.txt"
    shell:
        """
        centrifuge-download -o db/centrifuge/taxonomy taxonomy 2> {log}
        wget {params.url} -q -O - | gzip -d -c - | \
            awk '{{print $1\".\"$2\".\"$3\"\t\"$(NF)}}' \
            > {output.tax_map} 2>> {log}
        scripts/todb.py -s {input.seq} -t {input.tax} -m centrifuge \
            -S {output.ref_seqs} -T {output.ref_tax} 2>> {log}
        """


rule centrifuge_build_db:
    input:
        name_table = "db/centrifuge/taxonomy/names.dmp",
        tax_tree = "db/centrifuge/taxonomy/nodes.dmp",
        tax_map = "db/centrifuge/ref-tax.map",
        ref_seqs = "db/centrifuge/ref-seqs.fna"
    output:
        touch("db/centrifuge/CENTRIFUGE_DB_BUILD")
    threads:
        config["centrifuge"]["dbthreads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["centrifuge"]["dbmemory"]
    params:
        prefix = "db/centrifuge/ref-db"
    #singularity:
    #    config["centrifuge"]["container"]
    conda:
        config["centrifuge"]["environment"]
    log:
        "logs/centrifuge_build_db.log"
    benchmark:
        "benchmarks/centrifuge_build_db.txt"
    shell:
        """
        centrifuge-build \
          --threads {threads} \
          --conversion-table {input.tax_map} \
          --taxonomy-tree {input.tax_tree} \
          --name-table {input.name_table} \
          {input.ref_seqs} \
          {params.prefix} > {log}
        """


rule centrifuge_classify:
    input:
        rules.centrifuge_build_db.output,
        fastq = "data/{run}/nanofilt/{sample}.subsampled.fastq.gz",
        ref_seqs = "db/centrifuge/ref-seqs.fna"
    output:
        report = temp("classifications/{run}/centrifuge/{sample}.report.tsv"),
        classification = "classifications/{run}/centrifuge/{sample}.centrifuge.out",
    threads:
        config["centrifuge"]["threads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["centrifuge"]["memory"]
    params:
        index_prefix = "db/centrifuge/ref-db"
    conda:
        config["centrifuge"]["environment"]
    #singularity:
    #    config["centrifuge"]["container"]
    log:
        "logs/centrifuge_classify_{run}_{sample}.log"
    benchmark:
        "benchmarks/centrifuge_classify_{run}_{sample}.txt"
    shell:
        """
        centrifuge -x {params.index_prefix} \
          -U {input.fastq} \
          --threads {threads} \
          --report-file {output.report} \
          -S  {output.classification} \
          --met-stderr > {log}
        """


rule centrifuge_tomat:
    input:
        out = "classifications/{run}/centrifuge/{sample}.centrifuge.out",
        ref_seqs = "db/centrifuge/ref-seqs.fna"
    output:
        taxlist = "classifications/{run}/centrifuge/{sample}.centrifuge.taxlist",
        taxmat = "classifications/{run}/centrifuge/{sample}.centrifuge.taxmat",
        otumat = "classifications/{run}/centrifuge/{sample}.centrifuge.otumat"
    threads: 1
    log:
        "logs/centrifuge_tomat_{run}_{sample}.log"
    benchmark:
        "benchmarks/centrifuge_tomat_{run}_{sample}.txt"
    shell:
        "scripts/tomat.py -c {input.out} -f {input.ref_seqs} 2> {log}"

