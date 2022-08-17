/*
*   Module/process description here
*
*   @input  <name>  <type>  <description>
*   @params <name>  <type>  <description>
*   @output <name>  <type>  <description>
*/
process run_CollectHsMetrics {
    container params.docker_image_picard

    // label "resource_allocation_tool_name_command_name" samtools_depth ??

    publishDir path: "${workflow_output_dir}/metrics/${task.process.replace(':','/')}-${task.index}",
        pattern: "*.txt",
        mode: "copy",
        enabled: true

    publishDir path: "${params.log_output_dir}",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }

    // Additional directives here
    
    input: 
        path input_bam
        val workflow_output_dir

    output:
        // path("${variable_name}.command_name.file_extension"), emit: output_ch_tool_name_command_name
        path "*.txt", emit: txt
        path ".command.*"

    script:
    """
    set -euo pipefail

    java -jar /usr/local/share/picard-slim-2.26.8-0/picard.jar \
        CollectHsMetrics \
        --BAIT_INTERVALS \
        --INPUT $input_bam \
        --TARGET_INTERVALS interval list \
        --OUTPUT ${params.sample_id}.HsMetrics.txt \
        --TMP_DIR ${params.work_dir} \
        > ${params.sample_id}.collapsed_coverage.bed
    """
}
