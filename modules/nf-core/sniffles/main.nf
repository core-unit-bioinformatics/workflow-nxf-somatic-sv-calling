process SNIFFLES {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/sniffles:2.6.3--pyhdfd78af_0' :
        'biocontainers/sniffles:2.6.3--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(input), path(index)
    tuple val(meta2), path(fasta)
    tuple val(meta3), path(tandem_file)


    output:
    tuple val(meta), path("*.vcf.gz")    , emit: vcf, optional: true
    tuple val(meta), path("*.vcf.gz.tbi"), emit: tbi, optional: true
    tuple val(meta), path("*.snf")       , emit: snf, optional: true
    path "versions.yml"                  , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}${meta.status}"
    def suffix = task.ext.suffix ?: "vcf"
    def reference = fasta ? "--reference ${fasta}" : ""
    def tandem_repeats = tandem_file ? "--tandem-repeats ${tandem_file}" : ''
    def vcf = suffix == "vcf" ? "--vcf ${prefix}.vcf.gz": ''
    def snf = suffix == "snf" ? "--snf ${prefix}.snf": ''
    def both = suffix == "both" ? "--vcf ${prefix}.vcf.gz --snf ${prefix}.snf": ''

    """
    sniffles \\
        --input $input \\
        $reference \\
        -t $task.cpus \\
        $tandem_repeats \\
        $vcf \\
        $snf \\
        $both \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sniffles: \$(sniffles --help 2>&1 | grep Version |sed 's/^.*Version //')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def vcf = suffix == "vcf" ? "echo \"\" | gzip > ${prefix}.vcf.gz; touch ${prefix}.vcf.gz.tbi": ''
    def snf = suffix == "snf" ? "touch ${prefix}.snf": ''
    def both = suffix == "both" ? "touch ${prefix}.snf;echo \"\" | gzip > ${prefix}.vcf.gz; touch ${prefix}.vcf.gz.tbi": ''

    """
    ${vcf}
    ${snf}
    ${both}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sniffles: \$(sniffles --help 2>&1 | grep Version |sed 's/^.*Version //')
    END_VERSIONS
    """
}
