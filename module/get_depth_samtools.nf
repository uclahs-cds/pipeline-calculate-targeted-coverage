/*
*   Module/process description here
*
*   @input  <name>  <type>  <description>
*   @params <name>  <type>  <description>
*   @output <name>  <type>  <description>
*/
process run_depth_SAMtools {
    container params.docker_image_samtools

    // label "resource_allocation_tool_name_command_name" samtools_depth ??

    publishDir path: "${params.output_dir}/${task.process.replace(':','/')}-${task.index}",
        pattern: "*.tsv",
        mode: "copy",
        enabled: params.save_intermediate.files

    publishDir path: "${params.log_output_dir}",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }

    // Additional directives here
    
    input: 
        path input_BAM
        path target_file


    output:
        // path("${variable_name}.command_name.file_extension"), emit: output_ch_tool_name_command_name
        path "*.tsv", emit: tsv
        path ".command.*"

    script:
    """
    set -euo pipefail

    samtools \
        depth \
        $input_BAM
        -b $target_file \
        -a \
        --min-BQ ${params.min_base_quality} \
        -o ${params.sample_id}.depth_per_base.tsv
    """
}
