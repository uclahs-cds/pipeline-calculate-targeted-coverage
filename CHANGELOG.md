# Changelog
All notable changes to the pipeline-name pipeline.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]
### Added
- Add `get_depth_samtools.nf` module
- Add `merge_intervals_bedtools.nf` module
- Add `depth_to_bed.nf` module
- Add preliminary configs
- Add main workflow
- Add `run_HS_metrics.nf` module
- Add parameters for providing extra arguments to process tools
- Add option to include target and bait bed files or interval target files
- Add external script for joining single sample outputs
- Add module process to generate interval list from bait bed
- Add conditional logic to take target bed with bait bed and/or pre-built interval lists for targets and/or baits
- Add workflow for calculating coverage at select off-target loci
- Add workflow for creating a new interval file with target intervals merged with coverage-enriched off-target dbSNP sites.
- Add flow diagram of pipeline steps.

### Changed
- Update manifest
- Update `metadata.yaml`
- Update output directory structure according to lab standards
- Update workflow to accept external bait file.
- Update docker container registry to ghcr.io/uclahs-cds
- Add coverage cap parameter to `CollectHsMetrics` command
- Add default parameter definitions for coverage cap and external bait file
- Update template.config for target bed +/- bait bed, bait interval list, or target interval list
- Update default parameters.
---

