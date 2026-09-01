#!/usr/bin/env bash

set -euo pipefail

bucket="gs://younwoo-bucket"
destination="${PWD}/data"
selection="all"
dry_run=false

usage() {
  cat <<'USAGE'
Usage: ./download_gcp.sh [options]

Download the materialized OMOP exports and their ordered column manifests.

Options:
  --dest DIR       Local data root (default: ./data)
  --bucket URI     GCS bucket (default: gs://younwoo-bucket)
  --only NAME      all, mimiciv, or synpuf (comma-separated values accepted)
  --dry-run        Show the selected prefixes and gsutil operations only
  -h, --help       Show this help

The live bucket contains newer exports than the supplied DOCX screenshot:
  mimiciv/          40 headered OMOP CSV files
  mimiciv_column/   40 ordered column manifests
  synpuf23/         39 headered OMOP CSV files
  synpuf23_column/  39 ordered column manifests

The default download is about 288.3 GiB before PostgreSQL storage and WAL.
Downloads are resumable because gsutil rsync is used without deletion.
USAGE
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

while (($# > 0)); do
  case "$1" in
    --dest)
      (($# >= 2)) || die "--dest requires a value"
      destination=$2
      shift 2
      ;;
    --bucket)
      (($# >= 2)) || die "--bucket requires a value"
      bucket=$2
      shift 2
      ;;
    --only)
      (($# >= 2)) || die "--only requires a value"
      selection=$2
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

[[ $bucket == gs://* ]] || die "--bucket must begin with gs://"
[[ -n $destination ]] || die "--dest cannot be empty"

declare -a prefixes=()
add_prefix() {
  local candidate=$1 existing
  for existing in "${prefixes[@]:-}"; do
    [[ $existing == "$candidate" ]] && return 0
  done
  prefixes+=("$candidate")
}

IFS=',' read -r -a requested <<<"$selection"
for item in "${requested[@]}"; do
  case "$item" in
    all)
      add_prefix mimiciv
      add_prefix mimiciv_column
      add_prefix synpuf23
      add_prefix synpuf23_column
      ;;
    mimiciv)
      add_prefix mimiciv
      add_prefix mimiciv_column
      ;;
    synpuf|synpuf23)
      add_prefix synpuf23
      add_prefix synpuf23_column
      ;;
    '')
      die "empty entry in --only"
      ;;
    *)
      die "unsupported --only value: $item"
      ;;
  esac
done

((${#prefixes[@]} > 0)) || die "no dataset prefix selected"

printf 'Bucket:      %s\n' "$bucket"
printf 'Destination: %s\n' "$destination"
printf 'Prefixes:\n'
printf '  - %s\n' "${prefixes[@]}"

if $dry_run; then
  for prefix in "${prefixes[@]}"; do
    printf 'gsutil -m rsync -r %q %q\n' \
      "${bucket%/}/${prefix}/" "${destination%/}/${prefix}/"
  done
  exit 0
fi

command -v gsutil >/dev/null 2>&1 || die \
  "gsutil was not found. Install Google Cloud CLI; authenticate if the bucket requires it."

mkdir -p "$destination"
destination=$(cd "$destination" && pwd -P)

printf 'Checking bucket access...\n'
gsutil ls "${bucket%/}/" >/dev/null

for prefix in "${prefixes[@]}"; do
  local_dir="${destination}/${prefix}"
  mkdir -p "$local_dir"
  printf '\nDownloading %s ...\n' "$prefix"
  # No -d flag: local files are never deleted because the bucket changed.
  gsutil -m rsync -r "${bucket%/}/${prefix}/" "${local_dir}/"
done

contains_prefix() {
  local wanted=$1 current
  for current in "${prefixes[@]}"; do
    [[ $current == "$wanted" ]] && return 0
  done
  return 1
}

validate_export() {
  local data_prefix=$1 manifest_prefix=$2 expected_tables=$3
  local data_path="${destination}/${data_prefix}"
  local manifest_path="${destination}/${manifest_prefix}"
  local manifest filename table data_file expected_header actual_header invalid
  local -a data_files manifests

  [[ -d $data_path ]] || die "missing data directory: ${data_prefix}"
  [[ -d $manifest_path ]] || die "missing manifest directory: ${manifest_prefix}"

  shopt -s nullglob
  data_files=("${data_path}"/*.csv)
  manifests=("${manifest_path}"/*_column.csv)
  shopt -u nullglob

  ((${#data_files[@]} == expected_tables)) || die \
    "${data_prefix}: expected ${expected_tables} CSV files, found ${#data_files[@]}"
  ((${#manifests[@]} == expected_tables)) || die \
    "${manifest_prefix}: expected ${expected_tables} manifests, found ${#manifests[@]}"

  for manifest in "${manifests[@]}"; do
    [[ -s $manifest ]] || die "empty column manifest: ${manifest}"
    filename=${manifest##*/}
    table=${filename%_column.csv}
    data_file="${data_path}/${table}.csv"
    [[ -s $data_file ]] || die "missing or empty data file: ${data_prefix}/${table}.csv"

    invalid=$(tr -d '\r' < "$manifest" | LC_ALL=C grep -Ev '^[a-z][a-z0-9_]*$' || true)
    [[ -z $invalid ]] || die "invalid column name in ${manifest_prefix}/${filename}: ${invalid}"

    expected_header=$(tr -d '\r' < "$manifest" | paste -sd, -)
    actual_header=$(LC_ALL=C head -n 1 "$data_file" | tr -d '\r')
    [[ -n $expected_header ]] || die "no columns in ${manifest_prefix}/${filename}"
    [[ $actual_header == "$expected_header" ]] || die \
      "header/manifest mismatch for ${data_prefix}/${table}.csv"
  done

  for data_file in "${data_files[@]}"; do
    filename=${data_file##*/}
    table=${filename%.csv}
    [[ -s "${manifest_path}/${table}_column.csv" ]] || die \
      "no manifest for ${data_prefix}/${filename}"
  done

  printf '  %s: %d table/header contracts verified.\n' "$data_prefix" "$expected_tables"
}

printf '\nValidating every downloaded CSV against its ordered column manifest...\n'
if contains_prefix mimiciv; then
  validate_export mimiciv mimiciv_column 40
fi
if contains_prefix synpuf23; then
  validate_export synpuf23 synpuf23_column 39
fi

printf '\nDownload and layout validation completed successfully.\n'
printf 'Data root for psql: %s\n' "$destination"
