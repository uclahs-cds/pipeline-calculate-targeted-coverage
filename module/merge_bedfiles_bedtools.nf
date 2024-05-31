include { generate_standard_filename } from '../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'
/*
*   Module/process description here
*
*   @input  <name>  <type>  <description>
*   @params <name>  <type>  <description>
*   @output <name>  <type>  <description>
*/
process merge_bedfiles_BEDtools {
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
            'additional_information': "target-with-enriched-off-target-intervals.bed"
        ]
    )

    """
    set -euo pipefail

    cat ${target_bed} ${off_target_bed} | \
        sort -k1,1 -k2,2n | \
        awk '{OFS = "\t"}{print \$1, \$2, \$3}' | \
        bedtools merge \
        > ${output_filename}
    """
}
