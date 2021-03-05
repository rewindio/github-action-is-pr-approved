#!/bin/bash

function parseInputs {
  if [ "${INPUT_REPO_ACCESS_PAT}" != "" ]; then
    repo_access_pat=${INPUT_REPO_ACCESS_PAT}
  else
    echo "Input repo_access_pat cannot be empty"
    exit 1
  fi
}

function getPrUrl {
    pr_url=$(jq -r '.pull_request._links.self.href' "${GITHUB_EVENT_PATH}")
}

function getPrObj {
    pr_obj_path="$(mktemp)"

    curl -sSf \
        --url "${pr_url}" \
        --header "authorization: Bearer ${GITHUB_TOKEN}" \
        --header "content-type: application/json" > "${pr_obj_path}"
}

######
###### Mainline
######
function main {

    parseInputs
    getPrUrl
    getPrObj

    # Default to true to handle the case where the PR is not closed or merged
    required_reviewers=true

    action=$(jq -r '.action' "${GITHUB_EVENT_PATH}")

    if [ "${action}" != "closed" ]; then
        echo "*** This PR is not in the closed state. No action taken"
    else
        merged=$(jq -r '.merged' "${pr_obj_path}")

        if [ "${merged}" == "true" ]; then
            reviews_url=${pr_url}/reviews

            echo "Getting number of reviews for this PR from: ${reviews_url}"

            review_count=$(curl -sSf \
                --url "${reviews_url}" \
                --header "authorization: Bearer ${GITHUB_TOKEN}" \
                --header "content-type: application/json" | jq length)

            echo "this PR has been reviewed by ${review_count} people"

            # Now, how many reviews does this repo need?
            default_branch=$(jq -r '.head.repo.default_branch' "${pr_obj_path}")
            echo "default branch: ${default_branch}"

            branches_url=$(jq -r '.head.repo.branches_url' "${pr_obj_path}")
            echo "branches url: ${branches_url}"

            pr_request_reviews_url=$(sed "s/{\/branch}/\/${default_branch}\/protection\/required_pull_request_reviews/" <<< ${branches_url})
            echo "Getting required number of reviewers for this repo from: ${pr_request_reviews_url}"

            required_reviewers_count=$(curl -sSf \
                --url "${pr_request_reviews_url}" \
                --header "Accept: application/vnd.github.luke-cage-preview+json" \
                --header "authorization: Bearer ${repo_access_pat}" \
                --header "content-type: application/json" |jq '.required_approving_review_count |values')

            if [ -z "${required_reviewers_count}" ]; then
                echo "*** Unable to retrieve the required reviewers count - defaulting to 1"
                required_reviewers_count=1
            fi

            echo "this PR requires ${required_reviewers_count} reviews to pass checks"

            if [ "${review_count}" -lt "${required_reviewers_count}" ]; then
                echo "The required number of reviewers did not approve this PR"
                required_reviewers=false
            else
                echo "The required number of reviewers did approve this PR"
                required_reviewers=true
            fi
        else
            echo "*** This PR was not in a merged state"
        fi
    fi

  echo ::set-output name=reviewed::${required_reviewers}
}

main "${*}"
