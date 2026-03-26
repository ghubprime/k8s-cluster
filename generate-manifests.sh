#!/bin/bash

ENVIRONMENT="scots-lab"
KUSTOMIZE_SRC="kustomize/overlays/${ENVIRONMENT}"
RESOURCES=$(find ${KUSTOMIZE_SRC}/*/ -mindepth 1 -maxdepth 1 -type d)

while read RESOURCE; do
  APP="${RESOURCE#*$ENVIRONMENT/}"
  HELM_BASE="helm/base/${APP}"
  HELM_OVERLAY="helm/overlays/${ENVIRONMENT}/${APP}"
  KUSTOMIZE_BASE="kustomize/base/${APP}"
  MANIFESTS_DST="manifests/${ENVIRONMENT}/${APP}"

  # echo APP=$APP
  # echo ENVIRONMENT=$ENVIRONMENT
  # echo RESOURCE=$RESOURCE
  # echo HELM_BASE=$HELM_BASE
  # echo HELM_OVERLAY=$HELM_OVERLAY
  # echo KUSTOMIZE_BASE=$KUSTOMIZE_BASE
  # echo MANIFESTS_DST=$MANIFESTS_DST

  RESOURCE_PATHS=("$HELM_BASE" "$HELM_OVERLAY" "$KUSTOMIZE_BASE" "$RESOURCE")

  # add talos cluster config paths to diff check for talos app
  if [ "$APP" = "cluster/talos" ]; then
    TALOS_CONF=($(yq e '.spec.configPaths[]' "${RESOURCE}/generate-cluster-config.yaml"))
    RESOURCE_PATHS+=(${TALOS_CONF[@]})
  fi

  #echo "RESOURCE_PATHS: ${RESOURCE_PATHS[@]}" >&2

  echo -n "Generating manifest files for ${APP}..."

  # check for changes
  # need to check app specific helm/{base,overlays}, kustomize/{base,overlays}
  if [ "$1" = "--force" ]; then
    CHANGES_LIST="forced"
  else
    if [ "$CI" = "true" ]; then
      # We are in GitHub Actions: Check changes in the latest commit
      CHANGES_LIST=$(git diff --name-only HEAD~1 HEAD -- "${RESOURCE_PATHS[@]}")
    else
      # We are local: Check staged files
      CHANGES_LIST=$(git diff --staged --name-only HEAD -- "${RESOURCE_PATHS[@]}")
    fi
  fi
  if [ ! -z "$CHANGES_LIST" ]; then
    # cleanup existing manifests
    rm -rf "${MANIFESTS_DST}"

    # create output directory if it does not exist
    mkdir -p "$MANIFESTS_DST"

    # build new manifests directly into a single multi-document file to avoid OS filename constraints (like NTFS colons)
    BOOTSTRAP_SINGLE="${MANIFESTS_DST}/_bootstrap.yaml"
    kustomize build "$RESOURCE" --load-restrictor LoadRestrictionsNone --enable-helm --enable-alpha-plugins --enable-exec > "$BOOTSTRAP_SINGLE" 2> "${MANIFESTS_DST}/kustomize_error.log"

    # Generate the Talos bootstrap extramanifests index (single URL per app)
    APP_BASENAME=$(basename "$APP")
    BOOTSTRAP_FILE="bootstrap/k8s-cluster-extramanifests-${APP_BASENAME}.yaml"
    mkdir -p bootstrap
    echo "cluster:" > "$BOOTSTRAP_FILE"
    echo "  extraManifests:" >> "$BOOTSTRAP_FILE"
    echo "    - https://raw.githubusercontent.com/ghubprime/k8s-cluster/refs/heads/main/${MANIFESTS_DST}/_bootstrap.yaml" >> "$BOOTSTRAP_FILE"

    # when run as commit hook, we should
    # add generated files to staging
    # git add "$MANIFESTS_DST"

    echo "done."

    continue
  fi

  echo "skipping (no changes detected)."
done <<<"$RESOURCES"