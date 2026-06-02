const { test, expect } = require('@playwright/test');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

const viewerHtml = process.env.KEE_AUV_PANEL_HTML
  || path.join(__dirname, '..', 'demo', 'auv-panel-workflow.html');

test('AUV panel workflow exposes interactive reconstructed panels', async ({ page }) => {
  await page.goto(pathToFileURL(viewerHtml).href);

  await expect(page.locator('#review-tour')).toBeVisible();
  await expect(page.locator('#desktop-context')).toContainText('KEE desktop');
  await expect(page.locator('#desktop-context')).toContainText('Symbolics 3675');
  await expect(page.locator('#desktop-context')).toContainText('TI Micro-Explorer');
  await expect(page.locator('#current-kb')).toHaveText('AUV.WORKFLOW');
  await expect(page.locator('[data-edge-mode="selected"]')).toHaveClass(/active/);
  expect(await page.locator('svg#graph .edge.background').count()).toBeGreaterThan(0);
  await expect(page.locator('svg#graph .edge-label')).toHaveCount(0);
  await page.locator('[data-edge-mode="all"]').click();
  expect(await page.locator('svg#graph .edge-label').count()).toBeGreaterThan(0);
  await page.locator('[data-edge-mode="off"]').click();
  await expect(page.locator('svg#graph .edge-label')).toHaveCount(0);
  await expect(page.locator('.inspector-pane h2')).toHaveText('MISSION.STATE');
  await expect(page.locator('#slot-browser')).toContainText('MISSION.PROFILE');
  await expect(page.locator('#slot-browser')).toContainText('PIPELINE.INSPECT');
  await expect(page.locator('#slot-browser')).toContainText('MAX.DEPTH.METERS');
  await expect(page.locator('#slot-browser')).toContainText('180');
  await expect(page.locator('#slot-browser')).toContainText('ACOUSTIC.LINK');
  await expect(page.locator('#slot-browser')).toContainText('LOCKED');
  await expect(page.locator('#slot-browser')).toContainText('ActiveImages');
  await expect(page.locator('#slot-browser')).toContainText('Mission profile');
  await expect(page.locator('#slot-browser')).toContainText('Battery');

  await expect(page.locator('[data-review-tour="panels"]')).toBeEnabled();
  await expect(page.locator('[data-desktop-tour="panels"]')).toBeEnabled();
  await page.locator('[data-review-tour="panels"]').click();

  await expect(page.locator('#picture-browser')).toContainText('Image Panel Windows');
  await expect(page.locator('#picture-browser')).toContainText('Mission Selection Panel');
  await expect(page.locator('#picture-browser')).toContainText('Choose the mission profile');
  await expect(page.locator('#picture-browser .kee-panel .panel-state')).toHaveText('closed');
  await page.locator('button[data-panel-action="open"]').click();
  await expect(page.locator('#picture-browser .kee-panel .panel-state')).toHaveText('open');
  await expect(page.locator('.inspector-pane')).toContainText('Panel opened');
  await page.locator('button[data-panel-action="close"]').click();
  await expect(page.locator('#picture-browser .kee-panel .panel-state')).toHaveText('closed');
  await expect(page.locator('.inspector-pane')).toContainText('Panel closed');

  await page.locator('.panel-window-card[data-panel-name="WORKFLOW.20.PARAMETERS.PANEL"]').click();
  await expect(page.locator('#picture-browser')).toContainText('Parameter Entry Panel');
  await expect(page.locator('#picture-browser')).toContainText('Tune mission parameters');
  await expect(page.locator('#picture-browser .kee-panel .panel-state')).toHaveText('closed');
  await expect(page.locator('#picture-browser')).toContainText('Max depth');
  await expect(page.locator('#picture-browser')).toContainText('Duration');

  await page.locator('.panel-window-card[data-panel-name="WORKFLOW.30.MONITORING.PANEL"]').click();
  await expect(page.locator('#picture-browser')).toContainText('Mission Monitoring Panel');
  await expect(page.locator('#picture-browser')).toContainText('Watch the live mission state');
  await expect(page.locator('#picture-browser .kee-panel .panel-state')).toHaveText('open');
  await expect(page.locator('#picture-browser')).toContainText('Battery');
  await expect(page.locator('#picture-browser')).toContainText('Acoustic link');
  await expect(page.locator('.inspector-pane')).toContainText('Picture mouse');
});
