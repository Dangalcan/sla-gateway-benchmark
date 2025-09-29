# About this folder

## `compose_images.sh`

Switch between pinned and latest images for the proxies' docker-compse files.

## `curls/`

Contains several bash scripts with test curl commands.

## `diff.py`

Produces graphs plotting both the expected and actual results (after running benchmark 1).

## `docker_compose_logs.sh`

Saves the logs from the proxy containers to files.

## `full_bmk1_all_authLocations.sh`

Runs the benchmark 1 for all auth. locations.

## `full_test_raw.sh`

Contains commands for each proxy to: create config file, start docker-compose testbed, launch test (with `npm test`) and eventually removes the testbed.

## `generate_full.sh`

Generates a proxy configuration file for each proxy and auth. location.  

## `manual_results_check.sh`

Check results from logs obtained by docker_compose_logs.sh.

## `plots.py`

Produces plots from the benchmark 2 results.

## `test_bed_creation.sh`

Same as `full_test_raw.sh` but without `npm test` and for all four auth. locations.
