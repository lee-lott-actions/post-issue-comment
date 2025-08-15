# Post Comment to Issue Action

This GitHub Action posts a comment to a specified GitHub issue using the GitHub API. It returns a result indicating whether the comment was posted successfully (`success` for HTTP 201, `failure` otherwise).

## Features
- Posts a comment to a GitHub issue via the GitHub API.
- Outputs a result (`success` or `failure`) for easy integration into workflows.
- Requires a GitHub token with `issues:write` scope for authentication.

## Inputs
| Name           | Description                                      | Required | Default |
|----------------|--------------------------------------------------|----------|---------|
| `issue-number` | The issue number to post the comment to.         | Yes      | N/A     |
| `message`      | The comment message to post.                    | Yes      | N/A     |
| `token`        | GitHub token with repository write access.      | Yes      | N/A     |
| `owner`        | The owner of the repository (user or organization). | Yes      | N/A     |
| `repo-name`    | The name of the repository.                     | Yes      | N/A     |

## Outputs
| Name      | Description                                           |
|-----------|-------------------------------------------------------|
| `result`  | Result of the comment POST request (`success` for HTTP 201, `failure` otherwise). |

## Usage
1. **Add the Action to Your Workflow**:
   Create or update a workflow file (e.g., `.github/workflows/post-comment.yml`) in your repository.

2. **Reference the Action**:
   Use the action by referencing the repository and version (e.g., `v1`), or the local path if stored in the same repository.

3. **Example Workflow**:
   ```yaml
   name: Post Comment on Issue
   on:
     issue_comment:
       types: [created]
   jobs:
     comment:
       runs-on: ubuntu-latest
       steps:
         - name: Post Comment
           id: comment
           uses: lee-lott-actions/post-issue-comment@v1
           with:
             issue-number: ${{ github.event.issue.number }}
             message: 'Thanks for the issue! We will review it soon.'
             token: ${{ secrets.GITHUB_TOKEN }}
             owner: ${{ github.repository_owner }}
             repo-name: ${{ github.event.repository.name }}
         - name: Check Comment Result
           run: |
             if [[ "${{ steps.comment.outputs.result }}" == "success" ]]; then
               echo "Comment posted successfully."
             else
               echo "Error: Failed to post comment."
               exit 1
             fi
