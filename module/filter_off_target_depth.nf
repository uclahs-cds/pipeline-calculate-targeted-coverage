
/*
*   Filter for sites with read depth above a minimum threshold.
*   Important for excluding near-target regions from off-target calculations.
*
*   @input  <name>  <type>  <description>
*   @params <name>  <type>  <description>
*   @output <name>  <type>  <description>
*/


process run_depth_filter {
    publishDir path: "${params.workflow_output_dir}/intermediate/${task.process.replace(':','/')}",
        pattern: "*.bed",
        mode: "copy",
        enabled: params.save_intermediate_files

    publishDir path: "${params.log_output_dir}/process-log/",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }
    
    input: 
        path input

    output:
        path "*.bed", emit: bed
        path ".command.*"

    script:
    """
    set -euo pipefail

    awk \
        -v min_depth="${params.min_read_depth}" \
        '\$4 >= min_depth' \
        ${input} \
        > ${params.sample_id}.depth-filtered.bed
        """
}

/*
*   Add extra coordinates on either side of each BED entry (slop).
*   Important for excluding near-target regions from off-target calculations.
*
*   @input  <name>  <type>  <description>
*   @params <name>  <type>  <description>
*   @output <name>  <type>  <description>
*/


process run_slop_BEDtools {
    container params.docker_image_bedtools

    publishDir path: "${params.workflow_output_dir}/intermediate/${task.process.replace(':','/')}",
        pattern: "*.bed",
        mode: "copy",
        enabled: params.save_intermediate_files

    publishDir path: "${params.log_output_dir}/process-log/",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }
    
    input: 
        path target_bed
        path genome_sizes
        val slop
        val tag

    output:
        path "*.bed", emit: bed
        path ".command.*"

    script:
    """
    set -euo pipefail

    bedtools \
        slop \
        -i ${target_bed} \
        -g ${genome_sizes} \
        -b ${slop} \
        > ${params.sample_id}.${tag}_slop-${slop}.bed
    """
}

/*
*   Exclude targeted and near-target regions from off-target read depth output.
*
*   @input  <name>  <type>  <description>
*   @params <name>  <type>  <description>
*   @output <name>  <type>  <description>
*/
process run_intersect_BEDtools {
    container params.docker_image_bedtools

    publishDir path: "${params.workflow_output_dir}/output/",
        pattern: "*.bed",
        mode: "copy"

    publishDir path: "${params.log_output_dir}/process-log/",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }
    
    input: 
        path target_bed
        path off_target_bed

    output:
        path "*.bed", emit: bed
        path ".command.*"

    script:
    """
    set -euo pipefail

    bedtools \
        intersect \
        -a ${off_target_bed} \
        -b ${target_bed} \
        -v \
        > ${params.sample_id}.off-target-dbSNP_depth-per-base.bed
    """
}
