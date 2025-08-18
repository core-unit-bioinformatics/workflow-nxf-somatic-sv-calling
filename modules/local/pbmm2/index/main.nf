process PBMM2_INDEX {
    tag "$meta.id"
    label 'process_medium'


    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pbmm2:1.17.0--h9ee0642_0':
        'biocontainers/pbmm2:1.17.0--h9ee0642_0' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple path("*.mmi")         , emit: mmi
    path "versions.yml"         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    pbmm2 \\
        index \\
        $args \\
        $fasta \\
        ${prefix}.mmi \\
        --num-threads ${task.cpus}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pbmm2: \$(pbmm2 --version |& sed '1!d ; s/pbmm2 //')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.mmi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        pbmm2: \$(pbmm2 --version |& sed '1!d ; s/pbmm2 //')
    END_VERSIONS
    """
}
