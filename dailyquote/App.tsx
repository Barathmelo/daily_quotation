import React, { useState, useEffect, useCallback } from 'react';
import { View, StyleSheet, StatusBar } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { Quote, AppView, AppearanceSettings } from './types';
import { fetchQuotes } from './services/gemini';
import { Feed } from './components/Feed';
import { FavoritesList } from './components/FavoritesList';
import { TabBar } from './components/TabBar';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { setApiKey } from './config/env';
import { initializeGemini } from './services/gemini';

// Set API key from environment
// In production, use react-native-config or secure storage
const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
if (GEMINI_API_KEY) {
  setApiKey(GEMINI_API_KEY);
  initializeGemini(GEMINI_API_KEY);
}

// Initial data for immediate rendering before API fetch
const INITIAL_QUOTE: Quote = {
  id: 'initial-1',
  text: "Every moment is a fresh beginning.",
  author: "T.S. Eliot",
  category: "Inspiration"
};

const FAVORITES_STORAGE_KEY = 'dailyWisdomFavorites';

const App: React.FC = () => {
  const [view, setView] = useState<AppView>(AppView.FEED);
  const [quotes, setQuotes] = useState<Quote[]>([INITIAL_QUOTE]);
  const [favorites, setFavorites] = useState<Quote[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  
  // Appearance Settings
  const [appearance, setAppearance] = useState<AppearanceSettings>({
    font: 'serif',
    size: 'md'
  });

  // Load favorites from AsyncStorage on mount
  useEffect(() => {
    const loadFavorites = async () => {
      try {
        const saved = await AsyncStorage.getItem(FAVORITES_STORAGE_KEY);
        if (saved) {
          setFavorites(JSON.parse(saved));
        }
      } catch (e) {
        console.error("Failed to load favorites", e);
      }
    };
    loadFavorites();
  }, []);

  // Fetch quotes logic
  const loadQuotes = useCallback(async (isRefresh = false) => {
    setIsLoading(true);
    try {
      const newQuotes = await fetchQuotes(10); // Fetch 10 quotes at a time
      setQuotes(prev => isRefresh ? newQuotes : [...prev, ...newQuotes]);
    } catch (error) {
      console.error('Failed to load quotes:', error);
    } finally {
      setIsLoading(false);
    }
  }, []);

  // Initial Load
  useEffect(() => {
    const init = async () => {
      setIsLoading(true);
      try {
        const fresh = await fetchQuotes(10);
        setQuotes(fresh);
      } catch (error) {
        console.error('Failed to load initial quotes:', error);
      } finally {
        setIsLoading(false);
      }
    };
    init();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Save favorites to AsyncStorage whenever they change
  useEffect(() => {
    const saveFavorites = async () => {
      try {
        await AsyncStorage.setItem(FAVORITES_STORAGE_KEY, JSON.stringify(favorites));
      } catch (e) {
        console.error("Failed to save favorites", e);
      }
    };
    saveFavorites();
  }, [favorites]);

  const toggleFavorite = (quote: Quote) => {
    setFavorites(prev => {
      const exists = prev.some(f => f.id === quote.id);
      if (exists) {
        return prev.filter(f => f.id !== quote.id);
      }
      return [...prev, quote];
    });
  };

  return (
    <SafeAreaProvider>
      <StatusBar barStyle="light-content" />
      <View style={styles.container}>
        {/* Main Content Area */}
        <View style={styles.mainContent}>
          {view === AppView.FEED ? (
            <Feed 
              quotes={quotes} 
              favorites={favorites} 
              onToggleFavorite={toggleFavorite}
              isLoading={isLoading}
              onRefresh={() => loadQuotes(false)} 
              appearance={appearance}
              onUpdateAppearance={setAppearance}
            />
          ) : (
            <FavoritesList 
              favorites={favorites} 
              onRemove={toggleFavorite} 
              appearance={appearance} 
            />
          )}
        </View>

        {/* Navigation */}
        <TabBar currentView={view} onChangeView={setView} />
      </View>
    </SafeAreaProvider>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000000',
  },
  mainContent: {
    flex: 1,
  },
});

export default App;
