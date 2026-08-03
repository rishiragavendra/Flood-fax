/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  // Static export: `next build` emits a plain HTML/JS/CSS bundle into out/,
  // which FastAPI serves. No Node server at runtime — one process, one port.
  output: "export",
  images: { unoptimized: true },
  trailingSlash: true,
  // Security headers are applied by FastAPI when it serves the export
  // (see backend/app/main.py); next/headers has no effect in export mode.
};

export default nextConfig;
