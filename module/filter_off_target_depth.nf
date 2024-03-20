include { generate_standard_filename } from '../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'
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

    output_filename = generate_standard_filename(
        "SAMtools-${params.samtools_version}",
        params.dataset_id,
        params.sample_id,
        [
            'additional_information': "depth-filtered.bed"
        ]
    )

    """
    set -euo pipefail

    awk \
        -v min_depth="${params.min_read_depth}" \
        '\$4 >= min_depth' \
        ${input} \
        > ${output_filename}
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

    output_filename = generate_standard_filename(
        "BEDtools-${params.bedtools_version}",
        params.dataset_id,
        params.sample_id,
        [
            'additional_information': "${tag}_slop-${slop}.bed"
        ]
    )

    """
    set -euo pipefail

    bedtools \
        slop \
        -i ${target_bed} \
        -g ${genome_sizes} \
        -b ${slop} \
        > ${output_filename}
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

    output_filename = generate_standard_filename(
        "BEDtools-${params.bedtools_version}",
        params.dataset_id,
        params.sample_id,
        [
            'additional_information': "off-target-dbSNP_depth-per-base.bed"
        ]
    )

    """
    set -euo pipefail

    bedtools \
        intersect \
        -a ${off_target_bed} \
        -b ${target_bed} \
        -v \
        > ${output_filename}
    """
}
