/**
 * Configuration utility for external deployments (Railway, Vercel, etc.)
 * Optimized for production use outside of Replit
 */

export const config = {
  openai: {
    apiKey: process.env.OPENAI_API_KEY || undefined
  },

  github: {
    token: process.env.GITHUB_TOKEN || 
           process.env.GITHUB_PERSONAL_ACCESS_TOKEN || 
           undefined
  },

  database: {
    url: process.env.DATABASE_URL
  },

  server: {
    port: parseInt(process.env.PORT || '5000', 10),
    nodeEnv: process.env.NODE_ENV || 'development'
  }
};

export function validateConfig() {
  const warnings: string[] = [];
  const errors: string[] = [];
  
  if (!config.openai.apiKey) {
    errors.push('OPENAI_API_KEY is not set - AI features will not work');
  } else {
    console.log('OpenAI API Key: configured (starts with ' + config.openai.apiKey.substring(0, 7) + '...)');
  }
  
  if (!config.github.token) {
    warnings.push('GITHUB_TOKEN not set - GitHub search will have lower rate limits (60 requests/hour)');
  } else {
    console.log('GitHub Token: configured');
  }
  
  if (!config.database.url) {
    warnings.push('DATABASE_URL not set - using in-memory storage');
  } else {
    console.log('Database: configured');
  }
  
  return { warnings, errors };
}

export function isOpenAIConfigured(): boolean {
  return !!config.openai.apiKey;
}

export function isGitHubConfigured(): boolean {
  return !!config.github.token;
}

export function getConfigStatus() {
  return {
    openai: isOpenAIConfigured(),
    github: isGitHubConfigured(),
    database: !!config.database.url,
    environment: config.server.nodeEnv
  };
}
