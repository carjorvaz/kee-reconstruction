const { test, expect } = require('@playwright/test');
const path = require('node:path');
const { pathToFileURL } = require('node:url');

const viewerHtml = process.env.KEE_ASKE_HTML
  || path.join(__dirname, '..', 'demo', 'aske-common-windows.html');

test('ASKE Common Windows demo exposes reviewer-facing panes', async ({ page }) => {
  await page.goto(pathToFileURL(viewerHtml).href);

  await expect(page.locator('#desktop-context')).toContainText('KEE desktop');
  await expect(page.locator('#desktop-context')).toContainText('Unisys Explorer');
  await expect(page.locator('#desktop-context')).toContainText('Common Windows');
  await expect(page.locator('#current-kb')).toHaveText('ASKE.DEMO');
  await expect(page.locator('.inspector-pane h2')).toHaveText('ASKE.SESSION');
  await expect(page.locator('#slot-browser')).toContainText('CURRENT.INTERFACE');
  await expect(page.locator('#slot-browser')).toContainText('RULEMAKER');
  await expect(page.locator('#slot-browser')).toContainText('LAST.ACTION');
  await expect(page.locator('#slot-browser')).toContainText('RULE.EDITING.WINDOW');

  await expect(page.locator('[data-review-tour="panels"]')).toBeEnabled();
  await page.locator('[data-review-tour="panels"]').click();
  await expect(page.locator('#picture-browser')).toContainText('Image Panel Windows');
  await expect(page.locator('#picture-browser')).toContainText('Aske Interface Panel');
  await expect(page.locator('#picture-browser')).toContainText('Interaction Window');
  await expect(page.locator('#picture-browser')).toContainText('Notebook');
  await expect(page.locator('#picture-browser')).toContainText('Display Window');

  await page.locator('.panel-window-card[data-panel-name="RULEMAKER.INTERFACE.PANEL"]').click();
  await expect(page.locator('#picture-browser')).toContainText('Rulemaker Interface Panel');
  await expect(page.locator('#picture-browser')).toContainText('Rule DW');
  await expect(page.locator('#picture-browser')).toContainText('Context DW');
  await expect(page.locator('#picture-browser')).toContainText('Class DW');
  await expect(page.locator('#picture-browser')).toContainText('Rule Editing Window');
  await expect(page.locator('#picture-browser .kee-panel .panel-state')).toHaveText('open');
  await expect(page.locator('.inspector-pane')).toContainText('Picture mouse');
});
