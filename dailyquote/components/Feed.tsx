import React from 'react';
import { View, ScrollView, StyleSheet, ActivityIndicator, Text, TouchableOpacity, Dimensions } from 'react-native';
import { Quote, AppearanceSettings } from '../types';
import { QuoteSlide } from './QuoteSlide';
import { RefreshCcw } from 'lucide-react-native';

interface FeedProps {
  quotes: Quote[];
  favorites: Quote[];
  onToggleFavorite: (quote: Quote) => void;
  isLoading: boolean;
  onRefresh: () => void;
  appearance: AppearanceSettings;
  onUpdateAppearance: (settings: AppearanceSettings) => void;
}

export const Feed: React.FC<FeedProps> = ({ 
  quotes, 
  favorites, 
  onToggleFavorite, 
  isLoading, 
  onRefresh,
  appearance,
  onUpdateAppearance
}) => {
  const isFavorite = (id: string) => favorites.some(fav => fav.id === id);

  // If we are loading initially and have no quotes, show a loader
  if (isLoading && quotes.length === 0) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#FFFFFF" />
        <Text style={styles.loadingText}>Curating Wisdom...</Text>
      </View>
    );
  }

  const screenHeight = Dimensions.get('window').height;

  return (
    <ScrollView
      style={styles.container}
      contentContainerStyle={styles.contentContainer}
      snapToInterval={screenHeight}
      decelerationRate="fast"
      showsVerticalScrollIndicator={false}
    >
      {quotes.map((quote, index) => (
        <View key={quote.id} style={styles.slideContainer}>
          <QuoteSlide 
            quote={quote} 
            index={index}
            isFavorite={isFavorite(quote.id)}
            onToggleFavorite={onToggleFavorite}
            appearance={appearance}
            onUpdateAppearance={onUpdateAppearance}
          />
        </View>
      ))}
      
      {/* End of Feed - Load More / Refresh Area */}
      <View style={styles.endContainer}>
        <View style={styles.endContent}>
          <Text style={styles.endTitle}>That's it for now.</Text>
          <Text style={styles.endDescription}>
            You've reached the end of this collection.{'\n'}Ready for more inspiration?
          </Text>
          
          <TouchableOpacity 
            onPress={onRefresh}
            disabled={isLoading}
            style={[styles.refreshButton, isLoading && styles.refreshButtonDisabled]}
            activeOpacity={0.8}
          >
            {isLoading ? (
              <ActivityIndicator size="small" color="#FFFFFF" style={styles.refreshIcon} />
            ) : (
              <View style={styles.refreshIcon}>
                <RefreshCcw width={20} height={20} color="#FFFFFF" />
              </View>
            )}
            <Text style={styles.refreshButtonText}>Load Fresh Quotes</Text>
          </TouchableOpacity>
        </View>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000000',
  },
  contentContainer: {
    // Each slide takes full screen height - handled by slideContainer
  },
  slideContainer: {
    width: Dimensions.get('window').width,
    height: Dimensions.get('window').height,
    flex: 1,
  },
  loadingContainer: {
    flex: 1,
    backgroundColor: '#000000',
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 24,
    fontSize: 12,
    fontWeight: '500',
    letterSpacing: 2,
    color: 'rgba(255, 255, 255, 0.5)',
    textTransform: 'uppercase',
  },
  endContainer: {
    width: Dimensions.get('window').width,
    height: Dimensions.get('window').height,
    backgroundColor: '#0A0A0A',
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 32,
    paddingBottom: 128,
  },
  endContent: {
    maxWidth: 320,
    alignItems: 'center',
  },
  endTitle: {
    fontSize: 30,
    fontWeight: '400',
    color: 'rgba(255, 255, 255, 0.9)',
    fontFamily: 'Georgia',
    marginBottom: 8,
    textAlign: 'center',
  },
  endDescription: {
    fontSize: 14,
    color: '#737373',
    lineHeight: 20,
    textAlign: 'center',
    marginBottom: 32,
  },
  refreshButton: {
    width: '100%',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 16,
    paddingHorizontal: 32,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 16,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  refreshButtonDisabled: {
    opacity: 0.5,
  },
  refreshIcon: {
    marginRight: 12,
  },
  refreshButtonText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#FFFFFF',
    letterSpacing: 0.5,
  },
});
