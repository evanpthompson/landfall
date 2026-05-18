# Landfall Integration Registry

Community-built integrations, automations, and agent scripts for Landfall.

To add your integration, open a pull request and add a row to the relevant table.
See [Publishing Your Integration](agent_integration_guide.md#publishing-your-integration) for guidelines.

---

## Official Reference Integrations

| Name | Source namespace | Language | Description |
|---|---|---|---|
| Shell / cron | `agent.shell` | Bash | Push cards from any shell script or cron job. [Example](examples/) |
| Claude research | `agent.claude` | Python | Research a topic with Claude and push a summary card. [Example](examples/claude_research.py) |
| n8n workflow | `agent.n8n` | n8n | Push cards from n8n workflows. [Example](examples/n8n_workflow.json) |
| Home Assistant | `skill.home_assistant` | YAML | Push cards on sensor state changes. [Example](examples/home_assistant.yaml) |
| GitHub Actions | `agent.github` | YAML | Push deploy success/failure cards from workflow events. [Example](examples/github_actions/deploy_status.yml) |
| RSS digest | `agent.rss` | Python | Push the latest headlines from any RSS feed. [Example](examples/rss/rss_digest.py) |
| Todoist due today | `agent.todoist` | Python | Push a rolling due-today and overdue task card. [Example](examples/todoist/todoist_due_today.py) |

---

## Community Integrations

*No community integrations yet — be the first!*

Submitted integrations will appear here once merged.
