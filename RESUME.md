# Resume Workflow

## Editing

- Using `Typst` to typeset resume.
- Refer to `Makefile` for commands related to compiling.

## Github Actions

- Using Github Actions to automate the process of updating the resume on OneDrive.
- The workflow is triggered when a push is made to the `main` branch.
- The workflow uses the `rclone` tool to sync the repository `Jaeho_Cho_Resume.pdf` to the OneDrive.

_Note: Copy the output of `rclone config show` or the local `rclone.conf` generated using `rclone config create` to `RCLONE_CONFIG` github secret._