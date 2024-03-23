include { generate_standard_filename } from '../external/pipeline-Nextflow-module/modules/common/generate_standardized_filename/main.nf'
/*
*   Module/process description here
*
*   @input  <name>  <type>  <description>
*   @params <name>  <type>  <description>
*   @output <name>  <type>  <description>
*/
process convert_depth_to_bed {
    container params.docker_image_validate

    publishDir path: "${params.workflow_output_dir}/intermediate/${task.process.replace(':','/')}",
        pattern: "*.bed",
        mode: "copy",
        enabled: params.save_intermediate_files

    publishDir path: "${params.workflow_output_dir}/output/",
        pattern: "*.bed",
        mode: "copy",
        enabled: (params.save_raw_target_bed && tag == 'target') || (params.save_all_dbSNP && tag == 'genome-wide-dbSNP')

    publishDir path: "${params.log_output_dir}/process-log/",
        pattern: ".command.*",
        mode: "copy",
        saveAs: { "${task.process.replace(':', '/')}/log${file(it).getName()}" }
    
    input: 
        path input_tsv
        val tag

    output:
        path "*.bed", emit: bed
        path ".command.*"

    script:

    output_filename = generate_standard_filename(
        "SAMtools-${params.samtools_version}",
        params.dataset_id,
        params.sample_id,
        [
            'additional_information': "${tag}-depth-per-base.bed"
        ]
    )

    """
    set -euo pipefail

    cat ${input_tsv} | \
    awk 'BEGIN {OFS="\t"} {chr = \$1; start=\$2-1; stop=\$2; depth=\$3; print chr,start,stop,depth}' \
        | sort -k1,1 -k2,2n \
        > ${output_filename}
    """
}
