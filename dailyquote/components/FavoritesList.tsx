import React from 'react';
import { View, Text, StyleSheet, ScrollView, TouchableOpacity } from 'react-native';
import { Quote, AppearanceSettings } from '../types';
import { Heart, Trash2, Quote as QuoteIcon } from 'lucide-react-native';

interface FavoritesListProps {
  favorites: Quote[];
  onRemove: (quote: Quote) => void;
  appearance: AppearanceSettings;
}

const getFontFamily = (font: string): string => {
  switch (font) {
    case 'sans': return 'System';
    case 'mono': return 'Courier';
    case 'serif': default: return 'Georgia';
  }
};

export const FavoritesList: React.FC<FavoritesListProps> = ({ favorites, onRemove, appearance }) => {
  const fontFamily = getFontFamily(appearance.font);

  if (favorites.length === 0) {
    return (
      <View style={styles.emptyContainer}>
        <View style={styles.emptyIconContainer}>
          <Heart width={32} height={32} color="#404040" />
        </View>
        <Text style={styles.emptyTitle}>No Favorites Yet</Text>
        <Text style={styles.emptyDescription}>
          Tap the heart icon on quotes you love to save them here.
        </Text>
      </View>
    );
  }

  return (
    <ScrollView 
      style={styles.container}
      contentContainerStyle={styles.contentContainer}
      showsVerticalScrollIndicator={false}
    >
      <Text style={styles.title}>Your Collection</Text>
      <View style={styles.grid}>
        {favorites.map((quote) => (
          <View key={quote.id} style={styles.card}>
            <QuoteIcon width={24} height={24} color="#525252" style={styles.cardIcon} />
            <Text style={[styles.quoteText, { fontFamily }]}>
              "{quote.text}"
            </Text>
            <View style={styles.cardFooter}>
              <Text style={styles.authorText}>
                {quote.author}
              </Text>
              <TouchableOpacity
                onPress={() => onRemove(quote)}
                style={styles.removeButton}
                activeOpacity={0.7}
              >
                <Trash2 width={20} height={20} color="#EF4444" />
              </TouchableOpacity>
            </View>
          </View>
        ))}
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#0A0A0A',
  },
  contentContainer: {
    paddingTop: 64,
    paddingBottom: 96,
    paddingHorizontal: 16,
  },
  title: {
    fontSize: 30,
    fontWeight: '700',
    color: '#FFFFFF',
    marginBottom: 24,
    paddingHorizontal: 8,
    letterSpacing: -0.5,
  },
  grid: {
    gap: 16,
  },
  card: {
    backgroundColor: 'rgba(23, 23, 23, 0.5)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.05)',
    borderRadius: 16,
    padding: 24,
  },
  cardIcon: {
    marginBottom: 16,
    opacity: 0.5,
  },
  quoteText: {
    fontSize: 18,
    lineHeight: 28,
    color: '#F5F5F5',
    marginBottom: 16,
  },
  cardFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.05)',
    paddingTop: 16,
  },
  authorText: {
    fontSize: 14,
    fontWeight: '500',
    color: '#A3A3A3',
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  removeButton: {
    padding: 8,
    borderRadius: 999,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#0A0A0A',
    paddingHorizontal: 32,
  },
  emptyIconContainer: {
    width: 64,
    height: 64,
    backgroundColor: '#171717',
    borderRadius: 999,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 16,
  },
  emptyTitle: {
    fontSize: 20,
    fontWeight: '500',
    color: '#FFFFFF',
    marginBottom: 8,
  },
  emptyDescription: {
    fontSize: 14,
    color: '#A3A3A3',
    textAlign: 'center',
  },
});
