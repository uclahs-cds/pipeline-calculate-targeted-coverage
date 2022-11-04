/*
*   Module/process description here
*
*   @input  <name>  <type>  <description>
*   @params <name>  <type>  <description>
*   @output <name>  <type>  <description>
*/
process run_merge_BEDtools {
    container params.docker_image_bedtools

    publishDir path: "${params.workflow_output_dir}/output/",
        pattern: "*.bed",
        mode: "copy"

    publishDir path: "${params.log_output_dir}/process-log/",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }
    
    input: 
        path input_depth_bed

    output:
        path "*.bed", emit: bed
        path ".command.*"

    script:
    """
    set -euo pipefail

    bedtools \
        merge \
        -i $input_depth_bed \
        -c 4 \
        -o ${params.merge_operation} \
        > ${params.sample_id}.collapsed_coverage.bed
    """
}
