/*
*   Module/process description here
*
*   @input  <name>  <type>  <description>
*   @params <name>  <type>  <description>
*   @output <name>  <type>  <description>
*/
process run_merge_BEDtools {
    container params.docker_image_bedtools

    // label "resource_allocation_tool_name_command_name" samtools_depth ??

    publishDir path: "${params.output_dir}/${task.process.replace(':','/')}-${task.index}",
        pattern: "*.bed",
        mode: "copy",
        enabled: true

    publishDir path: "${params.log_output_dir}",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }

    // Additional directives here
    
    input: 
        path input_BED

    output:
        // path("${variable_name}.command_name.file_extension"), emit: output_ch_tool_name_command_name
        path "*.bed", emit: bed
        path ".command.*"

    script:
    """
    set -euo pipefail

    bedtools \
        merge \
        -i $input_BED
        -c 4 \ Column to perform a collapsing operation on. Read depth is in column 4.
        -o ${params.merge_operation} \ Operation that is performed on -c columns
        > ${params.sample_name}.collapsed_coverage.bed
    """
}
