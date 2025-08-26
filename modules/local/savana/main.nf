process SAVANA {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/savana:1.3.5--pyhdfd78af_0':
        'biocontainers/savana:1.3.5--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(bams), path(bams_index)
    tuple val(meta2), path(fasta), path(fai)

    output:
    tuple val(meta), path("${prefix}/somatic_SVs/plots/severus_*.html")         , emit: somatic_plots                    , optional: true
    path "versions.yml"                                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"

    def tumor_bam = "${meta.id}-tumor.bam"
    def normal_bam = "${meta.id}-normal.bam"
    def reference = fasta ? "--ref $fasta" : ""
    
    """
    savana \\
        $args \\
        --tumour $tumor_bam \\
        --normal $normal_bam \\
        --threads $task.cpus \\
        --cna_threads $task.cpus \\
        --outdir $prefix \\
        ${reference} \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        savana: \$(savana --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"

    """
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        savana: \$(savana --version)
    END_VERSIONS
    """
}
