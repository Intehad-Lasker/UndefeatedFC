import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

const RAILS_URL = process.env.RAILS_URL ?? 'http://localhost:3000'

// https://vite.dev/config/
export default defineConfig(({ command }) => ({
  plugins: [react()],
  // Production builds go into Rails' public/ folder; Rails serves index.html
  // for page routes and the static file server serves the hashed assets from
  // /app/. The dev server keeps the root base so page URLs match production.
  base: command === 'build' ? '/app/' : '/',
  build: {
    outDir: '../public/app',
    emptyOutDir: true,
  },
  server: {
    // In development the React app and the API share an origin through this
    // proxy, exactly as they do in production, so cookies and CSRF behave the
    // same. changeOrigin stays false: Rails' CSRF check compares the Origin
    // header with the Host header, and both must say localhost:5173.
    proxy: {
      '/api': { target: RAILS_URL, changeOrigin: false },
    },
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.js'],
  },
}))
