# Goodmem Devcontainer

The **Goodmem Devcontainer** is a complete, zero-configuration development environment designed to get you coding instantly. It packages all necessary SDKs, tools, and extensions into a single, pre-baked container, ensuring a consistent and efficient workflow for every developer.

---

### What's Included 📦

* **Languages:** Python 3.10 (with GoodMem & OpenAI SDKs), Java 17, .NET 8, Go 1.22, and Node.js 20 (with pnpm).
* **VS Code Extensions:** Pre-installed extensions for all included languages, plus essential linters and formatters.
* **Ready to Use:** Pre-configured shell access as the `vscode` user. All settings are baked into the image — no setup scripts needed.

### The Benefits ✅

* **Zero Setup Time:** No need to manually install compilers, SDKs, linters, or extensions.
* **Consistency:** Everyone on the team uses the exact same environment, eliminating "it works on my machine" problems.
* **Seamless Upgrades:** Updating to a new version is as simple as changing a single line in a configuration file.
* **Reliability:** All logic is pre-baked into the image, avoiding fragile post-creation scripts that can fail.
* **Offline-Friendly:** Once the container image is pulled, you don’t need an internet connection to use the environment.

---

## Getting Started

Choose the path that best fits your needs.

#### Option 1: Start a New Project from Scratch (Recommended)

This is the fastest way to get started. Use this if you're beginning a new project and want a clean, pre-configured workspace in the cloud.

**Simply click the button below:**

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://github.com/codespaces/new?repo=pair-systems-inc/goodmem-template-repository)
<!-- 
    IMPORTANT: For the button above to work, you must create a public GitHub repository
    at 'github.com/pair-systems-inc/goodmem-template-repository' and make it a "Template Repository" 
    in its settings. It should contain your .devcontainer/devcontainer.json file.
-->

**What this does:**
* Creates a new, private GitHub repository for you.
* Launches a GitHub Codespace with the Goodmem Devcontainer fully configured and ready to go.
* You can start creating files and writing code immediately.

#### Option 2: Add to an Existing Project

Use this method if you have an existing project on your desktop and want to add the Goodmem environment to it.

1.  Open your project in your local VS Code.
2.  Open the Command Palette with `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac).
3.  Type and select **"Dev Containers: Add Dev Container Configuration Files..."**
4.  Choose **"From a template."**
5.  When prompted, paste in the template URL: `ghcr.io/pair-systems-inc/templates/goodmem-dev`
6.  Follow the prompts, accepting the default settings.
7.  When VS Code asks, click **"Reopen in Container."** Your project will now be running inside the Goodmem dev environment.

---

## Your First Run: Setting Up and Testing GoodMem

Once your Codespace is running or you've opened the project in a local dev container, follow these steps to configure your API keys and run your first test. This entire process happens inside the VS Code environment.

#### Step 1: Create Your Environment File

You will store your secret API keys in an environment file. In the VS Code terminal (at the bottom of the editor), create a new `.env` file by running this command:

```bash
touch .env
