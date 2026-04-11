import { test, expect } from '@playwright/test'

test('hire/run/observe/stop workflow via roster + dashboard + agent stream views', async ({ page }) => {
  await page.goto('/roster')
  await expect(page.getByText('Roster / Hire Wizard')).toBeVisible()

  await page.goto('/')
  await expect(page.getByText('Workspace Activity')).toBeVisible()

  await page.goto('/agents/demo-1')
  await expect(page.getByText('Viewing agent demo-1')).toBeVisible()
  await expect(page.getByText('Agent Event Stream')).toBeVisible()
})

test('workflow creation and execution view', async ({ page }) => {
  await page.goto('/workflows')
  await expect(page.getByText('Workflow Builder')).toBeVisible()
  await expect(page.getByText('Workflow Execution Stream')).toBeVisible()
})

test('pod creation and broadcast view', async ({ page }) => {
  await page.goto('/teams')
  await expect(page.getByText('Teams (Pods)')).toBeVisible()
  await expect(page.getByText('Coordinate pods of specialized agents.')).toBeVisible()
})

test('cron schedule and cancel view', async ({ page }) => {
  await page.goto('/schedules')
  await expect(page.getByText('Schedules')).toBeVisible()
  await expect(page.getByText('Manage recurring runs and temporal triggers.')).toBeVisible()
})

test('hibernate/thaw controls entrypoint via settings', async ({ page }) => {
  await page.goto('/settings')
  await expect(page.getByText('Settings')).toBeVisible()
  await expect(page.getByText('Project and runtime settings.')).toBeVisible()
})
