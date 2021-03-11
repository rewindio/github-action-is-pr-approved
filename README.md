# github-action-is-pr-approved

Github action which determines if a PR has had the required number of reviews when it is closed

## Usage

### `workflow.yml` Example

Place in a `.yml` file such as this one in your `.github/workflows` folder. [Refer to the documentation on workflow YAML syntax here.](https://help.github.com/en/articles/workflow-syntax-for-github-actions)

```yaml
name: Check for Reviews
on:
  pull_request:
    types: [closed]

jobs:
  check-reviews:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@master

    - name: Reviewed
      uses: docker://rewindio/github-action-is-pr-approved
      env:
        GITHUB_TOKEN: "${{ secrets.GITHUB_TOKEN }}"
      with:
        REPO_ACCESS_PAT: "${{ secrets.GITHUB_TOKEN_WITH_REPO_ACCESS }}"

    - name: Print Review Status
      env:
        reviewed: ${{ steps.verify_reviewers.outputs.reviewed }}
      run:
        echo "The pr review status is $reviewed"

    - name: Apply Not Reviewed Label
      if: steps.verify_reviewers.outputs.reviewed == 'false'
      uses: actions-ecosystem/action-add-labels@v1 
      with:
        github_token: "${{ secrets.GITHUB_TOKEN }}"
        labels: |
          emergency-change
```

### Environment Variables

| Key | Value | Type | Required |
| ------------- | ------------- | ------------- | ------------- |
| `GITHUB_TOKEN` | The autogenerated github actions token | `env` | **Yes** |
| `REPO_ACCESS_PAT` | A github personal access token that has access to the repo settings | `with` | **Yes** |

### Outputs

| Output | Value | Comments |
| ------------- | ------------- | ------------- |
| `reviewed` | true,false | Returns false if the PR has been merge-closed without the required reviewers |

## License

This project is distributed under the [MIT license](LICENSE.md).
