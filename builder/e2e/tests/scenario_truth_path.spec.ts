/**
 * Phase 1.5 — End-to-end scenario certification (SCN-01).
 *
 * Truth path: login → roster hire → assign signal → observe stream → stop with confirm.
 *
 * Requires the app to be running with at least one user seeded via:
 *   mix jido_builder.create_user --email operator@example.com --password changeme123
 *
 * Run with:
 *   npx playwright test scenario_truth_path.spec.ts
 */
import { test, expect } from '@playwright/test'

const BASE = process.env.APP_URL || 'http://localhost:4000'
const EMAIL = process.env.OPERATOR_EMAIL || 'operator@example.com'
const PASSWORD = process.env.OPERATOR_PASSWORD || 'changeme123'
const AGENT_NAME = `e2e-agent-${Date.now()}`

test.describe('SCN-01 — truth path', () => {
  test('login → hire → assign → observe → stop', async ({ page }) => {
    // ── 1. Login ────────────────────────────────────────────────────────────
    await page.goto(`${BASE}/login`)
    await expect(page.getByRole('heading', { name: 'Sign In' })).toBeVisible()

    await page.fill('input[name="user[email]"]', EMAIL)
    await page.fill('input[name="user[password]"]', PASSWORD)
    await page.click('button[type="submit"]')

    // Should redirect to dashboard
    await expect(page).toHaveURL(`${BASE}/`)
    await expect(page.getByText('Home Dashboard')).toBeVisible()

    // ── 2. Roster hire ──────────────────────────────────────────────────────
    await page.goto(`${BASE}/roster`)
    await expect(page.getByText('Hire a Worker')).toBeVisible()

    await page.fill('input[name="hire[display_name]"]', AGENT_NAME)
    await page.click('button[type="submit"]')

    // New agent row appears in the stream
    await expect(page.locator(`text=${AGENT_NAME}`)).toBeVisible()

    // ── 3. Assign signal ────────────────────────────────────────────────────
    await page.goto(`${BASE}/assignments/new`)
    await expect(page.getByText('New Assignment')).toBeVisible()

    // Select the hired agent
    await page.selectOption('select[name="dispatch[target_agent]"]', { label: AGENT_NAME })
    await page.fill('input[name="dispatch[signal_type]"]', 'ping')
    await page.click('button[type="submit"]')

    // Feedback panel appears
    await expect(page.locator('#dispatch-result')).toBeVisible({ timeout: 5000 })

    // ── 4. Observe stream ───────────────────────────────────────────────────
    await page.goto(`${BASE}/`)
    // Give the telemetry bridge a moment to fan out
    await page.waitForTimeout(500)
    // Activity stream should contain a row for our agent
    await expect(page.locator(`text=${AGENT_NAME}`)).toBeVisible({ timeout: 5000 })

    // ── 5. Stop with confirm ────────────────────────────────────────────────
    await page.goto(`${BASE}/roster`)
    await page.locator(`[phx-value-name="${AGENT_NAME}"][phx-click="request_stop"]`).click()

    // Confirm modal appears
    await expect(page.locator('#stop-confirm-modal')).toBeVisible()
    await page.locator(`[phx-click="confirm_stop"][phx-value-name="${AGENT_NAME}"]`).click()

    // Agent row disappears
    await expect(page.locator(`text=${AGENT_NAME}`)).not.toBeVisible({ timeout: 5000 })
  })
})
