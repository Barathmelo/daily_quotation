import { GoogleGenAI, Type } from "@google/genai";
import { Quote } from "../types";
import { getApiKey } from "../config/env";

// Initialize Gemini client
// Note: API key should be set via setApiKey() in App.tsx or index.js
let ai: GoogleGenAI | null = null;

export const initializeGemini = (apiKey: string) => {
  if (apiKey) {
    ai = new GoogleGenAI({ apiKey });
  } else {
    console.warn('GEMINI_API_KEY is not set. Please set it in your app initialization.');
  }
};

// Initialize on import if API key is available
const apiKey = getApiKey();
if (apiKey) {
  ai = new GoogleGenAI({ apiKey });
}

// Generate UUID for React Native (crypto.randomUUID might not be available)
const generateUUID = (): string => {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) {
    return crypto.randomUUID();
  }
  // Fallback UUID generator
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
};

export const fetchQuotes = async (count: number = 5): Promise<Quote[]> => {
  try {
    if (!ai) {
      throw new Error('Gemini API client not initialized. Please set GEMINI_API_KEY.');
    }

    const response = await ai.models.generateContent({
      model: 'gemini-2.5-flash',
      contents: `Generate ${count} unique, inspiring, and thought-provoking quotes. 
      The first quote should be particularly relevant for "today" - perhaps about new beginnings, resilience, or mindfulness.
      The subsequent quotes can range from philosophy, success, love, and wisdom.
      Ensure authors are diverse (historical figures, modern thinkers, philosophers).`,
      config: {
        responseMimeType: "application/json",
        responseSchema: {
          type: Type.ARRAY,
          items: {
            type: Type.OBJECT,
            properties: {
              text: {
                type: Type.STRING,
                description: "The content of the quote.",
              },
              author: {
                type: Type.STRING,
                description: "The name of the person who said the quote.",
              },
              category: {
                type: Type.STRING,
                description: "A short category tag for the quote (e.g., Wisdom, Life, Success).",
              },
            },
            required: ["text", "author"],
          },
        },
      },
    });

    const rawQuotes = JSON.parse(response.text || "[]");

    // Map to our Quote interface and add unique IDs
    return rawQuotes.map((q: any) => ({
      id: generateUUID(),
      text: q.text,
      author: q.author,
      category: q.category || "Inspiration",
    }));

  } catch (error) {
    console.error("Failed to fetch quotes from Gemini:", error);
    // Fallback quotes in case of API failure or limit reached
    return [
      {
        id: generateUUID(),
        text: "The only way to do great work is to love what you do.",
        author: "Steve Jobs",
        category: "Success"
      },
      {
        id: generateUUID(),
        text: "Life is what happens when you're busy making other plans.",
        author: "John Lennon",
        category: "Life"
      },
      {
        id: generateUUID(),
        text: "It always seems impossible until it's done.",
        author: "Nelson Mandela",
        category: "Resilience"
      }
    ];
  }
};
