# Org Console LiveView Example

This example contains fully wired LiveViews and shared components for a people-centric operations console.

## Screens

- Home / Team Overview (`TeamOverviewLive`)
- Roster (`RosterLive`)
- Employee profile (`AgentProfileLive`)
- Assignment composer (`AssignmentComposerLive`)
- Workflow designer (`WorkflowDesignerLive`)
- Teams and pods (`TeamsPodsLive`)
- Schedules (`SchedulesLive`)
- Watchers/sensors (`WatchersSensorsLive`)
- Settings/integrations/security (`SettingsIntegrationsSecurityLive`)

Each screen includes:

- loading state
- empty state
- error state
- advanced-mode terminology toggle

Destructive actions include explicit confirmations with consequence messaging:

- fire employee
- stop child
- cancel recurring task
- delete workflow template
- delete integration connection

## Route Wiring

Add these routes in your Phoenix app:

```elixir
scope "/org", MyAppWeb do
  pipe_through :browser

  live "/home", TeamOverviewLive
  live "/roster", RosterLive
  live "/profile/:id", AgentProfileLive
  live "/assignments", AssignmentComposerLive
  live "/workflows", WorkflowDesignerLive
  live "/teams", TeamsPodsLive
  live "/schedules", SchedulesLive
  live "/monitors", WatchersSensorsLive
  live "/settings", SettingsIntegrationsSecurityLive
end
```
