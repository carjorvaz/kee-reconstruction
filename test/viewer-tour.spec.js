const { test, expect } = require('@playwright/test');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

const viewerHtml = process.env.KEE_VIEWER_HTML
  || path.join(__dirname, '..', 'demo', 'hamburg-viewer.html');

test('review tour jumps to reconstructed KEE surfaces', async ({ page }) => {
  await page.goto(pathToFileURL(viewerHtml).href);

  await expect(page.locator('#review-tour')).toBeVisible();
  await expect(page.locator('#desktop-roster')).toContainText('Lisp Listener');
  await expect(page.locator('#desktop-roster')).toContainText('KEEpictures');
  await expect(page.locator('[data-desktop-tour="units"]').first()).toBeEnabled();
  await expect(page.locator('#session-pane')).toContainText('CL-USER> (SETUP)');
  await expect(page.locator('[data-edge-mode="selected"]')).toHaveClass(/active/);
  await expect(page.locator('[data-tab="worlds"]')).toHaveClass(/active/);
  await expect(page.locator('.inspector-pane h2')).toHaveText(/WORLD-/);

  await page.locator('[data-session-window="typescript"]').click();
  await expect(page.locator('#session-pane')).toContainText('Complete consistent worlds: 12');
  await page.locator('[data-session-window="prompt"]').click();
  await expect(page.locator('#session-pane')).toContainText('Current KB: PUZZLE');

  await page.locator('[data-review-tour="units"]').click();
  await expect(page.locator('[data-tab="units"]')).toHaveClass(/active/);
  await expect(page.locator('.inspector-pane h2')).toHaveText('PEOPLE');
  await expect(page.locator('#slot-browser thead')).toContainText('Local');
  await expect(page.locator('#slot-browser thead')).toContainText('Inherited');
  await expect(page.locator('#slot-browser thead')).toContainText('Combined');
  await expect(page.locator('#slot-browser thead')).toContainText('Facets');

  await page.locator('[data-review-tour="rules"]').click();
  await expect(page.locator('[data-tab="units"]')).toHaveClass(/active/);
  await expect(page.locator('.inspector-pane')).toContainText('Rule Xref');

  await page.locator('[data-review-tour="worlds"]').click();
  await expect(page.locator('[data-tab="worlds"]')).toHaveClass(/active/);
  await expect(page.locator('.inspector-pane h2')).toHaveText(/WORLD-/);
  await expect(page.locator('.inspector-pane')).toContainText('Nogoods');

  await page.locator('[data-review-tour="agenda"]').click();
  await expect(page.locator('[data-tab="worlds"]')).toHaveClass(/active/);
  await expect(page.locator('.agenda-board')).toBeVisible();

  await page.locator('[data-review-tour="xref"]').click();
  await expect(page.locator('[data-tab="units"]')).toHaveClass(/active/);
  await expect(page.locator('.inspector-pane')).toContainText('Rule Xref');

  await expect(page.locator('[data-review-tour="kee-pictures"]')).toBeEnabled();
  await expect(page.locator('[data-desktop-tour="kee-pictures"]')).toBeEnabled();
  await page.locator('[data-review-tour="kee-pictures"]').click();
  await expect(page.locator('#picture-browser')).toContainText('Hamburg Review Panel');
  await expect(page.locator('#picture-browser')).toContainText('Hamburg Review View');
  await expect(page.locator('#picture-browser')).toContainText('Hamburg Review Window');
  await expect(page.locator('.inspector-pane')).toContainText('Picture mouse');

  await expect(page.locator('[data-review-tour="panels"]')).toBeEnabled();
  await expect(page.locator('[data-desktop-tour="panels"]')).toBeEnabled();
  await page.locator('[data-review-tour="panels"]').click();
  await expect(page.locator('#picture-browser')).toContainText('Hamburg Review Image Panel');
  await expect(page.locator('#picture-browser .kee-panel .panel-state')).toHaveText('open');
  await page.locator('button[data-panel-action="close"]').click();
  await expect(page.locator('#picture-browser .kee-panel .panel-state')).toHaveText('closed');
  await expect(page.locator('.inspector-pane')).toContainText('Panel closed');
  await page.locator('button[data-panel-action="open"]').click();
  await expect(page.locator('#picture-browser .kee-panel .panel-state')).toHaveText('open');
  await expect(page.locator('.inspector-pane')).toContainText('Panel opened');

  await expect(page.locator('[data-review-tour="active-images"]')).toBeEnabled();
  await expect(page.locator('[data-desktop-tour="active-images"]')).toBeEnabled();
  await page.locator('[data-review-tour="active-images"]').click();
  await expect(page.locator('#slot-browser')).toContainText('ActiveImages');
  await expect(page.locator('#slot-browser')).toContainText('Review confidence');
});
