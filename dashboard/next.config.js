/** @type {import('next').NextConfig} */
const path = require('path')

const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  webpack: (config, { isServer }) => {
    config.resolve.alias = {
      ...config.resolve.alias,
      '@': path.resolve(__dirname),
    }
    
    // Disable webpack cache in production builds
    if (!isServer) {
      config.cache = false
    }
    
    return config
  },
}

module.exports = nextConfig
