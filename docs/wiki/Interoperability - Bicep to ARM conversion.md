Bicep is a relatively new Domain-specific language (DSL) and - at the time of writing - not yet in the state of General Availability (GA). For this reason, some people may want to wait for Bicep's _General Availability_ and prefer to use ARM/JSON for the time being.

For these scenarios, the CARML library provides a script that uses the Bicep Toolkit translator/compiler to support the conversion of CARML Bicep modules to ARM/JSON Templates.
This page documents the conversion utility and how to use it.

---

### _Navigation_

- [Location](#location)
- [How it works](#how-it-works)
- [How to use it](#how-to-use-it)

---
# Location

You can find the script under [`/utilities/tools/ConvertTo-ARMTemplate.ps1`](https://github.com/Azure/ResourceModules/blob/main/utilities//tools/ConvertTo-ARMTemplate.ps1)

# How it works

The script finds all `deploy.bicep` files and converts them to json-based ARM templates by using the following steps:
1. Remove existing deploy.json files from folders where deploy.bicep files are also present.
1. Convert .bicep files to .json
1. Remove Bicep metadata from the converted .json files
1. Remove .bicep files and folders
1. Update pipeline files - Replace .bicep with .json in pipeline files

# How to use it

For details on how to use the function, please refer to the script's local documentation.
> **Note:** The script must be loaded ('*dot-sourced*') before the function can be invoked.
