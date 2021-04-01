FROM alpine:3.13.4

LABEL "com.github.actions.name"="Verify PR Review Approval"
LABEL "com.github.actions.description"="Verifies that the number of reviewers matches the configured approval count on a closed PR"
LABEL "com.github.actions.icon"="user-check"
LABEL "com.github.actions.color"="purple"

LABEL version="0.1.0"
LABEL repository="https://github.com/rewindio/github-action-is-pr-approved"
LABEL homepage="https://www.rewind.com/"
LABEL maintainer="Dave North <dave.north@rewind.io>"

RUN apk add --update --no-cache bash curl jq

ADD entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
