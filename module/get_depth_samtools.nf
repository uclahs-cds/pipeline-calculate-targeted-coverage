include { generate_standard_filename } from '../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'
/*
*   Module/process description here
*
*   @input  <name>  <type>  <description>
*   @params <name>  <type>  <description>
*   @output <name>  <type>  <description>
*/
process run_depth_SAMtools {
    container params.docker_image_samtools

    publishDir path: "${params.workflow_output_dir}/intermediate/${task.process.replace(':','/')}",
        pattern: "*.tsv",
        mode: "copy",
        enabled: params.save_intermediate_files

    publishDir path: "${params.log_output_dir}/process-log/",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }
    
    input: 
        path input_BAM
        path input_bed
        val tag

    output:
        path "*.tsv", emit: tsv
        path ".command.*"

    script:
    output_filename = generate_standard_filename(
        "SAMtools-${params.samtools_version}",
        params.dataset_id,
        params.sample_id,
        [
            'additional_information': "${tag}-depth-per-base.tsv"
        ]
    )
    """
    set -euo pipefail

    samtools \
        depth \
        ${input_BAM} \
        -b ${input_bed} \
        -aa \
        --min-BQ ${params.min_base_quality} \
        --min-MQ ${params.min_mapping_quality} \
        -o ${output_filename} \
        ${params.samtools_depth_extra_args}
    """
}
