#!/bin/bash
set -euo pipefail

log_msg() {
  if [ "x${GITHUB_WORKSPACE:-}" = "x" ]; then
    echo $* > /dev/stderr
  else
    echo $*
  fi
}

# get a list of config dirs that have changes
log_msg "computing changed dirs"
changed_config_dirs_json=$(
  jq -c 'map(split("/") | .[0:5] | join("/")) | unique' \
  <<< "${CHANGED_CONFIG_FILES}"
)
log_msg "changed config dirs: ${changed_config_dirs_json}"

dir_list=$(echo "${changed_config_dirs_json}" | jq -r 'join(" ")')

# shellcheck disable=SC2016  # no need to expand expressions
# shellcheck disable=SC2046  # need to expand *.yaml
env_list_json=$(
for dd in ${dir_list}; do

  if [ -d "${dd}" ]; then
  yq -sS \
  --arg dir "${dd}" \
  --argjson changeset "${CHANGED_CONFIG_FILES}" \
  '
    now as $nn
    | ($dir | split("/")) as $dir_parts
    | reduce .[] as $item ({}; . * $item)
    | . += {
      oe_name: $dir_parts[1],
      stage: $dir_parts[2],
      instance: $dir_parts[3],
      config_dir: $dir
    }
    # add github environment
    | . += {
      github: [.oe_name, .stage] | join("-")
    }
    | select(has("deploy"))
    | select((.deploy.always // false) == true or ($nn >= ((.deploy.window.from // "2000-01-01T00:00:00Z") | fromdateiso8601) and $nn < ((.deploy.window.to // "2000-01-01T00:00:00Z") | fromdateiso8601)))
    # add deployment defaults
    | .deploy += {
    }
  ' "${dd}"/*.yaml
  fi
done | jq -cs '.'
)

echo "${env_list_json}"
env_list_len=$(echo "${env_list_json}" | jq 'length')

# useful for local testing
if [  "x${GITHUB_OUTPUT:-}" != "x" ]; then
  echo "list=${env_list_json}" >> "${GITHUB_OUTPUT}"
  echo "list_len=${env_list_len}" >> "${GITHUB_OUTPUT}"
fi

if [ "${env_list_len}" = "0" ]; then
  log_msg "::notice ::empty environment list, change deploy window to rollout to an environment"
fi
