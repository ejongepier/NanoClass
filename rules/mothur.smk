rule mothur_db:
    output:
        aln = "db/mothur/silva.nr_v132.align",
        tax = "db/mothur/silva.nr_v132.tax"
    threads: 1
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["mothur"]["dbmemory"]
    params:
        url = config["mothur"]["dburl"]
    log:
        "logs/mothur_db.log"
    benchmark:
        "benchmarks/mothur_db.txt"
    singularity:
        config["container"]
    shell:
        """
        tar=$(basename {output.aln} .align)".tgz"
        aln=$(basename {output.aln})
        tax=$(basename {output.tax})
        dir=$(dirname {output.aln})
        wget -O $dir/$tar {params.url}
        tar -C $dir -xvf $dir/$tar $aln
        tar -C $dir -xvf $dir/$tar $tax
        """


rule mothur_classify:
    input:
        query = rules.prep_fasta_query.output,
        aln = rules.mothur_db.output.aln
    output:
        dir = temp(directory("classifications/{run}/mothur/{sample}/")),
        out = "classifications/{run}/mothur/{sample}.mothur.out"
    params:
        file = "{sample}.subsampled.align.report"
    threads:
        config["mothur"]["threads"]
    resources:
        mem_mb = lambda wildcards, attempt: attempt * config["mothur"]["memory"]
    singularity:
        config["mothur"]["container"]
    log:
        "logs/mothur_classify_{run}_{sample}.log"
    benchmark:
        "benchmarks/mothur_classify_{run}_{sample}.txt"
    shell:
        """
        cp {input} {output.dir}
        queryf=$(basename {input.query})
        alnf=$(basename {input.aln})
        echo \"align.seqs(candidate={output.dir}/$queryf, template={output.dir}/$alnf, \
            processors={threads}, ksize=6, align=needleman)\" > {output.dir}/mothur.cmd
        mothur {output.dir}/mothur.cmd
        awk -F '\\t' -v OFS='\\t' '{{if (NR==1) printf "%s","#"; print $1, $3}}' {output.dir}/{params.file} > {output.out} 
        """


rule mothur_tomat:
    input:
        tax = "db/mothur/silva.nr_v132.tax",
        out = "classifications/{run}/mothur/{sample}.mothur.out"
    output:
        taxlist = "classifications/{run}/mothur/{sample}.mothur.taxlist",
        taxmat = "classifications/{run}/mothur/{sample}.mothur.taxmat",
        otumat = "classifications/{run}/mothur/{sample}.mothur.otumat"
    threads: 1
    singularity:
        config["container"]
    log:
        "logs/mothur_tomat_{run}_{sample}.log"
    benchmark:
        "benchmarks/mothur_tomat_{run}_{sample}.txt"
    shell:
        """
        scripts/tomat.py -b {input.out} -t {input.tax}
        """
