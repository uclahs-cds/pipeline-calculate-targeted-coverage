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
- Add external script for joining single sample outputs

### Changed
- Update manifest
- Update `metadata.yaml`
- Update output directory structure according to lab standards
- Update workflow to accept external bait file.
- Update docker container registry to ghcr.io/uclahs-cds

---

