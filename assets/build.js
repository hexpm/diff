const esbuild = require('esbuild')
const { spawn } = require('child_process')
const fs = require('fs')
const path = require('path')

const args = process.argv.slice(2)
const watch = args.includes('--watch')
const deploy = args.includes('--deploy')

// Copy static assets to priv/static
const staticSrc = path.join(__dirname, 'static')
const staticDest = path.join(__dirname, '..', 'priv', 'static')

function copyDir(src, dest) {
  fs.mkdirSync(dest, { recursive: true })
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const from = path.join(src, entry.name)
    const to = path.join(dest, entry.name)
    entry.isDirectory() ? copyDir(from, to) : fs.copyFileSync(from, to)
  }
}

if (fs.existsSync(staticSrc)) copyDir(staticSrc, staticDest)

// Tailwind CSS via CLI
const twArgs = ['--input', 'css/app.css', '--output', '../priv/static/css/app.css']
if (watch) twArgs.push('--watch')
if (deploy) twArgs.push('--minify')

const tailwind = spawn(process.execPath, ['./node_modules/.bin/tailwindcss', ...twArgs], {
  stdio: 'inherit',
})
tailwind.on('error', err => {
  console.error('tailwindcss error:', err.message)
  process.exit(1)
})
tailwind.on('exit', (code) => {
  if (code !== 0 && code !== null && !watch) {
    process.exit(code)
  }
})

// esbuild JS bundle
const esbuildOpts = {
  entryPoints: ['js/app.js'],
  bundle: true,
  target: 'es2017',
  outdir: '../priv/static/js',
  minify: deploy,
  sourcemap: !deploy,
  logLevel: 'info',
}

if (watch) {
  esbuild.context(esbuildOpts).then(ctx => {
    ctx.watch()
    // Exit cleanly when Phoenix closes stdin (server shutdown)
    process.stdin.resume()
    process.stdin.on('end', () => {
      ctx.dispose()
      tailwind.kill()
      process.exit(0)
    })
  }).catch((err) => {
    console.error('esbuild context error:', err.message)
    tailwind.kill()
    process.exit(1)
  })
} else {
  esbuild.build(esbuildOpts).catch(() => process.exit(1))
}
