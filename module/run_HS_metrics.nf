/*
*   Module/process description here
*
*   @input  <name>  <type>  <description>
*   @params <name>  <type>  <description>
*   @output <name>  <type>  <description>
*/


process run_BedToIntervalList_picard {
    container params.docker_image_picard
    containerOptions "--volume ${params.reference}"
    // picard-slim-2.27.4-0


    publishDir path: "${workflow_output_dir}/intermediate/${task.process.replace(':','/')}-${task.index}",
        pattern: "*.interval_list",
        mode: "copy",
        enabled: params.save_intermediate_files

    publishDir path: "${params.log_output_dir}",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }

    input: 
        path input_bed
        val workflow_output_dir

    output:
        // path("${variable_name}.command_name.file_extension"), emit: output_ch_tool_name_command_name
        path "*.interval_list", emit: interval_list
        path ".command.*"

    script:
    """
    set -euo pipefail

    java -jar /usr/local/share/picard-slim-${params.picard_version}-0/picard.jar \
        BedToIntervalList \
        --INPUT $input_bed \
        --OUTPUT ${params.sample_id}.target.interval_list \
        --SEQUENCE_DICTIONARY ${params.reference}
        --SORT false
    """

}

process run_CollectHsMetrics_picard {
    container params.docker_image_picard
    containerOptions "--volume ${params.reference}"

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
        path target_interval_list
        path bait_interval_list
        val workflow_output_dir

    output:
        // path("${variable_name}.command_name.file_extension"), emit: output_ch_tool_name_command_name
        path "*.txt", emit: txt
        path ".command.*"

    script:
    """
    set -euo pipefail

    java -jar /usr/local/share/picard-slim-${params.picard_version}-0/picard.jar \
        CollectHsMetrics \
        --BAIT_INTERVALS $bait_interval_list \
        --INPUT $input_bam \
        --TARGET_INTERVALS $target_interval_list \
        --OUTPUT ${params.sample_id}.HsMetrics.txt \
        --TMP_DIR ${params.work_dir} 
    """
}
