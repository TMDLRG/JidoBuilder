import { defineConfig } from '@playwright/test'

export default defineConfig({
  testDir: './tests',
  timeout: 30_000,
  use: {
    baseURL: process.env.E2E_BASE_URL || 'http://127.0.0.1:4002',
    headless: true
  },
  webServer: {
    command: 'cd .. && MIX_ENV=test mix phx.server',
    url: 'http://127.0.0.1:4002',
    timeout: 120_000,
    reuseExistingServer: !process.env.CI
  }
})
