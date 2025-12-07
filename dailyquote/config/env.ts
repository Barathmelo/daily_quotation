/**
 * Environment configuration for React Native
 * Set GEMINI_API_KEY in your environment or use react-native-config
 */

// For development, you can set this directly (not recommended for production)
// For production, use react-native-config or pass via app initialization

export const getApiKey = (): string => {
  // Try to get from global (set in App.tsx or index.js)
  if ((global as any).GEMINI_API_KEY) {
    return (global as any).GEMINI_API_KEY;
  }
  
  // Try process.env (if using babel-plugin-transform-inline-environment-variables)
  if (process.env.GEMINI_API_KEY) {
    return process.env.GEMINI_API_KEY;
  }
  
  // Fallback
  return '';
};

// Set API key globally (call this in App.tsx or index.js)
export const setApiKey = (key: string) => {
  (global as any).GEMINI_API_KEY = key;
};

