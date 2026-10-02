// Headless walk through the Developer Hub pages used in Modules 4-7, as one persona.
// Usage: RHDH_USER=dev1 RHDH_PASS=... node <browser-automation>/browser.mjs https://<rhdh>/ --script ./walk-rhdh.mjs
// Reports, per page: HTTP 401/403 API calls, permission/denial texts, error banners, console errors.
export default async function run(page, ui) {
  const user = process.env.RHDH_USER, pass = process.env.RHDH_PASS
  const base = new URL(page.url()).origin
  const denied = []
  page.context().on('response', r => {
    const u = r.url()
    if ((r.status() === 403 || r.status() === 401) && u.includes('/api/')) denied.push(`${r.status()} ${new URL(u).pathname}`)
  })

  // --- sign in through the OIDC popup (Keycloak) ---
  await page.waitForTimeout(2000)
  let snap = await ui.snapshot()
  const btn = snap.match(/@(e\d+) button "(Sign In|Log in|Sign in)"/i)?.[1]
  if (!btn) return { error: 'no sign-in button', snap: snap.slice(0, 800) }
  const [popup] = await Promise.all([page.waitForEvent('popup', { timeout: 20000 }), ui.click(btn)])
  await popup.waitForSelector('#username', { timeout: 30000 })
  await popup.fill('#username', user)
  await popup.fill('#password', pass)
  await Promise.all([popup.waitForEvent('close', { timeout: 30000 }).catch(() => {}), popup.click('#kc-login')])
  await page.waitForTimeout(4000)
  await page.waitForFunction(() => document.body.innerText.trim().length > 100, null, { timeout: 40000 }).catch(() => {})
  const afterLogin = await page.evaluate(() => document.body.innerText.slice(0, 300))
  const signedIn = !/sign in/i.test(afterLogin)

  const pages = [
    ['home', '/'],
    ['catalog', '/catalog'],
    ['component overview', '/catalog/default/component/parasol-insurance-secured'],
    ['component topology', '/catalog/default/component/parasol-insurance-secured/topology'],
    ['component ci', '/catalog/default/component/parasol-insurance-secured/ci'],
    ['component cd', '/catalog/default/component/parasol-insurance-secured/cd'],
    ['component image-registry', '/catalog/default/component/parasol-insurance-secured/image-registry'],
    ['api parasol-insurance-api', '/catalog/default/api/parasol-insurance-api'],
    ['api definition', '/catalog/default/api/parasol-insurance-api/definition'],
    ['create (templates)', '/create'],
    ['lightspeed', '/lightspeed'],
    ['kuadrant api products', '/kuadrant/api-products'],
    ['kuadrant my api keys', '/kuadrant/my-api-keys'],
    ['kuadrant approval', '/kuadrant/api-key-approval'],
    ['rbac', '/rbac'],
    ['notifications', '/notifications'],
    ['bulk import', '/bulk-import/repositories'],
    ['orchestrator', '/orchestrator'],
  ]
  const bad = /not authorized|missing permission|permission denied|unauthorized|forbidden|error occurred|something went wrong|failed to/i
  const results = []
  for (const [name, path] of pages) {
    denied.length = 0
    try {
      await page.goto(base + path, { waitUntil: 'load', timeout: 60000 })
      // client-rendered app: wait for real content, not a fixed delay
      await page.waitForFunction(() => document.body.innerText.trim().length > 100, null, { timeout: 40000 }).catch(() => {})
      await page.waitForTimeout(2500)
      const text = await page.evaluate(() => document.body.innerText)
      const hits = [...new Set((text.match(new RegExp(bad.source, 'gi')) || []).map(s => s.toLowerCase()))]
      const heading = (text.split('\n').map(s => s.trim()).filter(Boolean).slice(0, 3)).join(' | ').slice(0, 120)
      results.push({ page: name, path, chars: text.length, heading, denialText: hits, apiDenied: [...new Set(denied)] })
    } catch (e) {
      results.push({ page: name, path, error: String(e).slice(0, 160) })
    }
  }
  const sidebar = await page.evaluate(() => [...document.querySelectorAll('nav a, [data-testid*="sidebar"] a')].map(a => a.textContent.trim()).filter(Boolean).slice(0, 40))
  return { user, signedIn, afterLogin, sidebar: [...new Set(sidebar)], results }
}
