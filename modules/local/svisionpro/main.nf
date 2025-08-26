process SVISIONPRO {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/svision-pro:2.4--pyhdfd78af_1':
        'biocontainers/svision-pro:2.4--pyhdfd78af_1' }"

    input:
    tuple val(meta), path(bams), path(bams_index)
    tuple val(meta2), path(fasta), path(fai)
    tuple val(meta3), path(access_bed)
    tuple val(meta4), path(model)
    

    output:
    tuple val(meta), path("${prefix}/somatic_SVs/plots/severus_*.html")         , emit: somatic_plots                    , optional: true
    path "versions.yml"                                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"

    def tumor_bam  = "${meta.id}-tumor.bam"
    def normal_bam = "${meta.id}-normal.bam"
    def reference  = fasta      ? "--genome_path genome.fa" : ""
    def model      = model      ? "--model_path $model" : ""
    def access_bed = access_bed ? "--access_path $access_bed" : ""
    
    """
    #unzip reference genome
    if [[ -f ${fasta} ]]; then
        if [[ ${fasta} == *.gz ]]; then
            gunzip -c ${fasta} > genome.fa
        else
            ln -s ${fasta} genome.fa
        fi
    fi

    SVision-pro \\
        $args \\
        --target_path $tumor_bam \\
        --base_path $normal_bam \\
        --out_path $prefix \\
        --sample_name $prefix \\
        --process_num $task.cpus \\
        ${reference} \\
        ${model} \\
        ${access_bed}

    python extract_op.py \\
        --input_vcf ${prefix}.vcf \\
        ${args2}

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
