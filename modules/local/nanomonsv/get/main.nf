process NANOMONSV_GET {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanomonsv:0.8.0--pyhdfd78af_0':
        'biocontainers/nanomonsv:0.8.0--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(beds), path(tbis), path(bams), path(csis)
    tuple val(meta2), path(fasta)

    output:
    tuple val(meta), path("*.nanomonsv*")         , emit: result
    path "versions.yml"                                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args              = task.ext.args   ?: ''
    def tumor_bam         = task.ext.prefix ?: "${meta.id}-tumor.bam"
    def normal_bam        = task.ext.prefix ?: "${meta.id}-normal.bam"
    def tumor_prefix      = task.ext.prefix ?: "${meta.id}-tumor"
    def normal_prefix     = task.ext.prefix ?: "${meta.id}-normal"

    """
    #unzip reference genome
    if [[ ${fasta} == *.gz ]]; then
        gunzip -c ${fasta} > genome.fa
    else
        ln -s ${fasta} genome.fa
    fi
    
    nanomonsv \\
        get \\
        ${args} \\
        --control_prefix ${normal_prefix} \\
        --control_bam ${normal_bam} \\
        --processes ${task.cpus} \\
        --max_memory_minimap2 ${task.memory.toGiga()} \\
        --sort_option '-S ${task.memory.toGiga()}G' \\
        ${tumor_prefix} \\
        ${tumor_bam} \\
        genome.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanomonsv: \$(echo \$(nanomonsv --version 2>&1) | sed 's/^nanomonsv //')
        mafft: \$(echo \$(mafft --version 2>&1) | sed 's/^v//; s/ (.*//')
        racon: \$(echo \$(racon --version 2>&1) | sed 's/^v//')
        tabix: \$(echo \$(tabix --version 2>&1) | sed 's/^tabix (htslib) //; s/ Copyright.*//')
        bgzip: \$(echo \$(bgzip --version 2>&1) | sed 's/^bgzip (htslib) //; s/ Copyright.*//')
        python: \$(python3 --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.nanomonsv.result.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanomonsv: \$(echo \$(nanomonsv --version 2>&1) | sed 's/^nanomonsv //')
        mafft: \$(echo \$(mafft --version 2>&1) | sed 's/^v//; s/ (.*//')
        racon: \$(echo \$(racon --version 2>&1) | sed 's/^v//')
        tabix: \$(echo \$(tabix --version 2>&1) | sed 's/^tabix (htslib) //; s/ Copyright.*//')
        bgzip: \$(echo \$(bgzip --version 2>&1) | sed 's/^bgzip (htslib) //; s/ Copyright.*//')
        python: \$(python3 --version | sed 's/Python //g')
    END_VERSIONS
    """
}
