const { test } = require('@playwright/test');
const { pathToFileURL } = require('node:url');

test('capture generated demo screenshot', async ({ page }) => {
  const html = process.env.KEE_DEMO_HTML;
  const out = process.env.KEE_SCREENSHOT_OUT;
  const tour = process.env.KEE_DEMO_TOUR || '';

  if (!html || !out) {
    throw new Error('KEE_DEMO_HTML and KEE_SCREENSHOT_OUT are required');
  }

  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto(pathToFileURL(html).href);

  if (tour) {
    await page.locator(`[data-review-tour="${tour}"]`).first().click();
  }

  if (tour === 'kee-pictures') {
    await page.locator('#picture-browser').scrollIntoViewIfNeeded();
  }

  await page.screenshot({ path: out });
});
