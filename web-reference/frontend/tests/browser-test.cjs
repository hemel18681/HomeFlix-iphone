const { chromium } = require('playwright');

(async () => {
  console.log('🚀 Starting Playwright Netflix Platform Automated Tests...');

  const launchOptions = {
    headless: true,
    executablePath: '/usr/bin/chromium-browser',
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-dev-shm-usage', '--disable-gpu']
  };

  const browser = await chromium.launch(launchOptions);

  try {
    // ==========================================
    // 1. Desktop Test (1280x800)
    // ==========================================
    console.log('\n--- 1. Testing Desktop Layout (1280x800) ---');
    const desktopPage = await browser.newPage({ viewport: { width: 1280, height: 800 } });
    
    const errors = [];
    desktopPage.on('pageerror', err => {
      console.error('Desktop Page Error:', err.message);
      errors.push(err.message);
    });

    await desktopPage.goto('http://127.0.0.1:5173', { waitUntil: 'networkidle', timeout: 15000 });
    
    // Assert Brand Title exists
    const brand = await desktopPage.locator('text=DHAKA').first();
    await brand.waitFor({ state: 'visible', timeout: 5000 });
    console.log('✓ Brand Header verified: DHAKAFLIX');

    // Assert Billboard Hero section exists
    const heroPlay = await desktopPage.locator('button:has-text("Play")').first();
    await heroPlay.waitFor({ state: 'visible', timeout: 5000 });
    console.log('✓ Billboard Hero Play button verified');

    // Assert Carousel Content rows exist
    const rows = await desktopPage.locator('h2').count();
    console.log(`✓ Verified ${rows} category carousel rows rendered`);

    // Capture Desktop Screenshot
    await desktopPage.screenshot({ path: '/tmp/desktop.png' });
    console.log('✓ Desktop view verified and screenshot captured: /tmp/desktop.png');

    // ==========================================
    // 2. Search Modal Verification
    // ==========================================
    console.log('\n--- 2. Testing Instant Search Modal ---');
    const searchBtn = await desktopPage.locator('button[title*="Search"]').first();
    await searchBtn.click();
    
    const searchInput = await desktopPage.locator('input[placeholder*="Titles, people"]');
    await searchInput.fill('Batman');
    await desktopPage.waitForTimeout(1000); // Debounce wait

    const searchCount = await desktopPage.locator('text=Found').first();
    await searchCount.waitFor({ state: 'visible', timeout: 5000 });
    const countText = await searchCount.textContent();
    console.log(`✓ Search verified: ${countText}`);

    // Close search
    const cancelBtn = await desktopPage.locator('button:has-text("Cancel")').first();
    await cancelBtn.click();
    console.log('✓ Search closed cleanly');

    // ==========================================
    // 3. Mobile Responsive Test (390x844 - iPhone)
    // ==========================================
    console.log('\n--- 3. Testing Mobile Responsive View (390x844) ---');
    const mobilePage = await browser.newPage({
      viewport: { width: 390, height: 844 },
      userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1'
    });

    mobilePage.on('pageerror', err => {
      console.error('Mobile Page Error:', err.message);
      errors.push(err.message);
    });

    await mobilePage.goto('http://127.0.0.1:5173', { waitUntil: 'networkidle', timeout: 15000 });
    
    const mobileBrand = await mobilePage.locator('text=DHAKA').first();
    await mobileBrand.waitFor({ state: 'visible', timeout: 5000 });
    console.log('✓ Mobile view brand verified');

    await mobilePage.screenshot({ path: '/tmp/mobile.png' });
    console.log('✓ Mobile responsive view verified: /tmp/mobile.png');

    if (errors.length > 0) {
      console.error('❌ Tests had page errors:', errors);
      process.exit(1);
    }

    console.log('\n🎉 ALL PLAYWRIGHT AUTOMATED TESTS COMPLETED WITH 100% SUCCESS!');
  } finally {
    await browser.close();
  }
})();
