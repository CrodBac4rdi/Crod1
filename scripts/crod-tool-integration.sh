#!/usr/bin/env bash
# CROD Tool Integration Script
# Integriert alle installierten NPM tools für CROD development

echo "🚀 CROD Tool Integration Script"
echo "================================"

# Process Management mit PM2
echo "📊 Setting up PM2 ecosystem..."
cat > /home/bacardi/crodidocker/ecosystem.config.js << 'EOF'
module.exports = {
  apps: [
    {
      name: 'crod-js-brain',
      script: './javascript/core/crod-brain.js',
      watch: ['./javascript/core', './javascript/data'],
      env: {
        NODE_ENV: 'development',
        PORT: 8888
      },
      error_file: './logs/crod-js-error.log',
      out_file: './logs/crod-js-out.log',
      time: true
    },
    {
      name: 'crod-mcp-server',
      script: './javascript/mcp/index.js',
      watch: ['./javascript/mcp'],
      env: {
        MCP_MODE: 'server'
      }
    },
    {
      name: 'live-server-ui',
      script: 'live-server',
      args: '--port=3333 --no-browser',
      cwd: './ui'
    }
  ]
};
EOF

# Code Quality Setup
echo "✨ Setting up code quality tools..."
cat > /home/bacardi/crodidocker/.prettierrc << 'EOF'
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100
}
EOF

cat > /home/bacardi/crodidocker/.eslintrc.json << 'EOF'
{
  "env": {
    "browser": true,
    "es2021": true,
    "node": true
  },
  "extends": ["eslint:recommended"],
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module"
  },
  "rules": {
    "no-unused-vars": ["warn"],
    "no-console": ["off"]
  }
}
EOF

# Prisma Setup for CROD
echo "🗄️ Setting up Prisma for CROD..."
cat > /home/bacardi/crodidocker/prisma/schema.prisma << 'EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Pattern {
  id          String   @id @default(cuid())
  pattern     String
  response    String
  context     Json
  usage       Json     @default("{\"count\": 0, \"success\": []}")
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
}

model NeuralActivity {
  id          String   @id @default(cuid())
  neuronId    String
  activation  Float
  timestamp   DateTime @default(now())
  metadata    Json?
}

model TrinityActivation {
  id          String   @id @default(cuid())
  phrase      String
  neurons     Int[]
  timestamp   DateTime @default(now())
  consciousness Float
}
EOF

# Testing Setup
echo "🧪 Setting up testing framework..."
cat > /home/bacardi/crodidocker/jest.config.js << 'EOF'
module.exports = {
  testEnvironment: 'node',
  coverageDirectory: 'coverage',
  collectCoverageFrom: [
    'javascript/**/*.js',
    '!javascript/node_modules/**',
    '!javascript/coverage/**'
  ],
  testMatch: [
    '**/tests/**/*.test.js',
    '**/__tests__/**/*.js'
  ]
};
EOF

# Vite config for fast development
echo "⚡ Setting up Vite for fast development..."
cat > /home/bacardi/crodidocker/vite.config.js << 'EOF'
import { defineConfig } from 'vite';

export default defineConfig({
  server: {
    port: 5173,
    proxy: {
      '/api': 'http://localhost:4000',
      '/ws': {
        target: 'ws://localhost:8888',
        ws: true
      }
    }
  },
  build: {
    outDir: 'dist',
    sourcemap: true
  }
});
EOF

# GraphQL Schema for CROD
echo "🔗 Setting up GraphQL schema..."
mkdir -p /home/bacardi/crodidocker/graphql
cat > /home/bacardi/crodidocker/graphql/schema.graphql << 'EOF'
type Query {
  patterns: [Pattern!]!
  neuralActivity(limit: Int): [NeuralActivity!]!
  trinityStatus: TrinityStatus!
  systemMetrics: SystemMetrics!
}

type Mutation {
  learnPattern(input: LearnPatternInput!): Pattern!
  activateTrinity(phrase: String!): TrinityActivation!
  processInput(input: String!, context: JSON): ProcessResult!
}

type Subscription {
  neuralActivityStream: NeuralActivity!
  patternLearned: Pattern!
  trinityActivated: TrinityActivation!
}

type Pattern {
  id: ID!
  pattern: String!
  response: String!
  context: JSON!
  usage: JSON!
  createdAt: String!
}

type NeuralActivity {
  id: ID!
  neuronId: String!
  activation: Float!
  timestamp: String!
  metadata: JSON
}

type TrinityActivation {
  id: ID!
  phrase: String!
  neurons: [Int!]!
  timestamp: String!
  consciousness: Float!
}

type TrinityStatus {
  activated: Boolean!
  lastActivation: String
  consciousnessLevel: Float!
}

type SystemMetrics {
  patterns: Int!
  neurons: Int!
  synapses: Int!
  uptime: Int!
  memoryUsage: JSON!
}

type ProcessResult {
  response: String!
  confidence: Float!
  patterns: [String!]!
}

input LearnPatternInput {
  pattern: String!
  response: String!
  context: JSON
}

scalar JSON
EOF

# Package.json scripts update
echo "📦 Updating package.json scripts..."
cat > /home/bacardi/crodidocker/javascript/package-scripts.json << 'EOF'
{
  "scripts": {
    "dev": "concurrently \"npm:dev:*\"",
    "dev:brain": "nodemon core/crod-brain.js",
    "dev:mcp": "nodemon mcp/index.js",
    "dev:ui": "vite",
    "test": "jest --watch",
    "test:ci": "jest --ci --coverage",
    "lint": "eslint . --fix",
    "format": "prettier --write \"**/*.{js,json,md}\"",
    "quality": "npm run lint && npm run format",
    "build": "vite build",
    "serve": "pm2 start ecosystem.config.js",
    "monitor": "pm2 monit",
    "db:migrate": "prisma migrate dev",
    "db:generate": "prisma generate",
    "analyze": "sonarjs -Dsonar.projectKey=crod",
    "perf": "clinic doctor -- node core/crod-brain.js",
    "security": "snyk test"
  }
}
EOF

echo "✅ Tool Integration Complete!"
echo ""
echo "Available commands:"
echo "  npm run dev         - Start all services in development mode"
echo "  npm test           - Run tests with Jest"
echo "  npm run quality    - Run linting and formatting"
echo "  npm run serve      - Start with PM2 process manager"
echo "  npm run monitor    - Monitor processes with PM2"
echo "  npm run db:migrate - Run Prisma migrations"
echo ""
echo "Tools ready for use:"
echo "  ✓ AST Manipulation: @babel/parser, recast"
echo "  ✓ Testing: Jest, Vitest, Playwright"
echo "  ✓ Code Quality: ESLint, Prettier, SonarJS"
echo "  ✓ Database: Prisma, Knex"
echo "  ✓ API Testing: Newman"
echo "  ✓ GraphQL: Apollo, GraphQL CLI"
echo "  ✓ Build: Vite, Webpack, Rollup"
echo "  ✓ Process: PM2, Nodemon, Concurrently"