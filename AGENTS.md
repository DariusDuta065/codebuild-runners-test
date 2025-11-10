# Agents Guide for Terraform Changes

Whenever you are working with Terraform in this repository (including any infrastructure or configuration changes), please run the following commands from the relevant Terraform project directory before opening a PR or merging changes:

1. Format Terraform files:

```bash
terraform fmt -recursive
```

2. Validate Terraform configuration:

```bash
terraform validate
```

3. Run Terraform linting (requires `tflint` installed):

```bash
tflint
```

4. Regenerate Terraform docs for modules that use terraform-docs (requires `terraform-docs` installed):

For the GitHub Actions runners module, run:

```bash
cd codebuild-runners-test
terraform-docs --config .terraform-docs.yml .
```

General guidance:
- Always run these commands in the directory that contains the relevant Terraform configuration (for example, `codebuild-runners-test/infra/...`).
- Fix any reported errors or warnings before committing.
- If you add a new Terraform module that should have docs, configure `terraform-docs` (e.g. via a `.terraform-docs.yml`) and include the appropriate update command in its README.
