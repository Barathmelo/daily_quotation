import React, { useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Modal, Pressable, Animated, Dimensions } from 'react-native';
import { Quote, AppearanceSettings, FontFamily, TextSize } from '../types';
import { Heart, Type } from 'lucide-react-native';

interface QuoteSlideProps {
  quote: Quote;
  isFavorite: boolean;
  onToggleFavorite: (quote: Quote) => void;
  index: number;
  appearance: AppearanceSettings;
  onUpdateAppearance: (settings: AppearanceSettings) => void;
}

const GRADIENTS = [
  ['#1e1b4b', '#581c87', '#0f172a'], // indigo-purple-slate
  ['#0f172a', '#022c22', '#064e3b'], // slate-teal-emerald
  ['#7f1d1d', '#991b1b', '#9a3412'], // rose-red-orange
  ['#030712', '#0f172a', '#18181b'], // gray-slate-zinc
  ['#451a03', '#78350f', '#292524'], // amber-yellow-stone
];

const getFontFamily = (font: FontFamily): string => {
  switch (font) {
    case 'sans': return 'System';
    case 'mono': return 'Courier';
    case 'serif': default: return 'Georgia';
  }
};

const getTextSize = (size: TextSize): number => {
  switch (size) {
    case 'sm': return 24;
    case 'lg': return 40;
    case 'md': default: return 32;
  }
};

export const QuoteSlide: React.FC<QuoteSlideProps> = ({ 
  quote, 
  isFavorite, 
  onToggleFavorite, 
  index,
  appearance,
  onUpdateAppearance
}) => {
  const [showSettings, setShowSettings] = useState(false);
  const [scaleAnim] = useState(new Animated.Value(1));
  
  // Deterministic gradient based on index
  const gradientColors = GRADIENTS[index % GRADIENTS.length];
  
  const fontFamily = getFontFamily(appearance.font);
  const fontSize = getTextSize(appearance.size);

  const handleSaveClick = () => {
    // Haptic feedback
    // Note: For haptics, you might want to use react-native-haptic-feedback
    
    // Trigger animation
    Animated.sequence([
      Animated.timing(scaleAnim, {
        toValue: 0.85,
        duration: 100,
        useNativeDriver: true,
      }),
      Animated.timing(scaleAnim, {
        toValue: 1.35,
        duration: 200,
        useNativeDriver: true,
      }),
      Animated.timing(scaleAnim, {
        toValue: 0.9,
        duration: 150,
        useNativeDriver: true,
      }),
      Animated.timing(scaleAnim, {
        toValue: 1.1,
        duration: 150,
        useNativeDriver: true,
      }),
      Animated.timing(scaleAnim, {
        toValue: 1,
        duration: 100,
        useNativeDriver: true,
      }),
    ]).start();
    
    // Toggle state
    onToggleFavorite(quote);
  };

  return (
    <View style={[styles.container, { backgroundColor: gradientColors[0] }]}>
      {/* Background gradient overlay */}
      <View style={[styles.gradientOverlay, { 
        backgroundColor: gradientColors[1],
        opacity: 0.5,
      }]} />
      <View style={[styles.gradientOverlay, { 
        backgroundColor: gradientColors[2],
        opacity: 0.3,
      }]} />

      {/* Decorative blur circles */}
      <View style={styles.decorativeContainer}>
        <View style={[styles.blurCircle, styles.blurCircleTop]} />
        <View style={[styles.blurCircle, styles.blurCircleBottom]} />
      </View>

      {/* Content Container */}
      <View style={styles.contentContainer}>
        
        {/* Category Badge */}
        <View style={styles.badgeContainer}>
          <View style={styles.badge}>
            <Text style={styles.badgeText}>
              {index === 0 ? "Quote of the Day" : quote.category}
            </Text>
          </View>
        </View>

        {/* Main Quote Text */}
        <Text style={[
          styles.quoteText,
          { fontFamily, fontSize }
        ]}>
          "{quote.text}"
        </Text>
        
        {/* Author divider */}
        <View style={styles.divider} />
        
        {/* Author */}
        <Text style={styles.authorText}>
          {quote.author}
        </Text>

        {/* Action Buttons Row */}
        <View style={styles.actionsContainer}>
          
          {/* Favorite Button */}
          <TouchableOpacity 
            onPress={handleSaveClick}
            style={styles.actionButton}
            activeOpacity={0.8}
          >
            <Animated.View style={[
              styles.actionButtonInner,
              isFavorite ? styles.actionButtonActive : styles.actionButtonInactive,
              { transform: [{ scale: scaleAnim }] }
            ]}>
              <Heart 
                width={24} 
                height={24} 
                color={isFavorite ? '#EF4444' : '#FFFFFF'} 
                fill={isFavorite ? '#EF4444' : 'none'}
              />
            </Animated.View>
            <Text style={styles.actionLabel}>Save</Text>
          </TouchableOpacity>

          {/* Settings Button */}
          <TouchableOpacity 
            onPress={() => setShowSettings(!showSettings)}
            style={styles.actionButton}
            activeOpacity={0.8}
          >
            <View style={[
              styles.actionButtonInner,
              showSettings ? styles.actionButtonActiveSettings : styles.actionButtonInactive
            ]}>
              <Type 
                width={24} 
                height={24} 
                color={showSettings ? '#000000' : '#FFFFFF'} 
              />
            </View>
            <Text style={styles.actionLabel}>Style</Text>
          </TouchableOpacity>
        </View>

        {/* Settings Modal */}
        <Modal
          visible={showSettings}
          transparent={true}
          animationType="fade"
          onRequestClose={() => setShowSettings(false)}
        >
          <Pressable 
            style={styles.modalBackdrop}
            onPress={() => setShowSettings(false)}
          >
            <Pressable style={styles.modalContent} onPress={(e) => e.stopPropagation()}>
              <View style={styles.settingsContainer}>
                
                {/* Font Options */}
                <View style={styles.settingsSection}>
                  <Text style={styles.settingsLabel}>Font</Text>
                  <View style={styles.optionsRow}>
                    {(['serif', 'sans', 'mono'] as const).map(f => (
                      <TouchableOpacity
                        key={f}
                        onPress={() => onUpdateAppearance({ ...appearance, font: f })}
                        style={[
                          styles.optionButton,
                          appearance.font === f && styles.optionButtonActive
                        ]}
                      >
                        <Text style={[
                          styles.optionButtonText,
                          appearance.font === f && styles.optionButtonTextActive
                        ]}>
                          {f === 'serif' ? 'Classic' : f === 'sans' ? 'Modern' : 'Type'}
                        </Text>
                      </TouchableOpacity>
                    ))}
                  </View>
                </View>

                {/* Size Options */}
                <View style={styles.settingsSection}>
                  <Text style={styles.settingsLabel}>Size</Text>
                  <View style={styles.optionsRow}>
                    {(['sm', 'md', 'lg'] as const).map(s => (
                      <TouchableOpacity
                        key={s}
                        onPress={() => onUpdateAppearance({ ...appearance, size: s })}
                        style={[
                          styles.optionButton,
                          appearance.size === s && styles.optionButtonActive
                        ]}
                      >
                        <Text style={[
                          styles.sizeButtonText,
                          s === 'sm' && { fontSize: 12 },
                          s === 'md' && { fontSize: 16 },
                          s === 'lg' && { fontSize: 20 },
                          appearance.size === s && styles.optionButtonTextActive
                        ]}>
                          A
                        </Text>
                      </TouchableOpacity>
                    ))}
                  </View>
                </View>
              </View>
            </Pressable>
          </Pressable>
        </Modal>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    width: '100%',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 32,
    paddingBottom: 128,
  },
  gradientOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
  decorativeContainer: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    opacity: 0.2,
  },
  blurCircle: {
    position: 'absolute',
    width: 384,
    height: 384,
    borderRadius: 192,
    backgroundColor: '#FFFFFF',
  },
  blurCircleTop: {
    top: -192,
    left: -192,
  },
  blurCircleBottom: {
    bottom: -192,
    right: -192,
  },
  contentContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    maxWidth: 600,
    width: '100%',
    zIndex: 10,
  },
  badgeContainer: {
    marginBottom: 32,
  },
  badge: {
    paddingHorizontal: 16,
    paddingVertical: 6,
    borderRadius: 999,
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  badgeText: {
    fontSize: 10,
    fontWeight: '700',
    letterSpacing: 2,
    textTransform: 'uppercase',
    color: 'rgba(255, 255, 255, 0.7)',
  },
  quoteText: {
    textAlign: 'center',
    lineHeight: 40,
    letterSpacing: 0.5,
    color: '#FFFFFF',
    marginBottom: 24,
    textShadowColor: 'rgba(0, 0, 0, 0.5)',
    textShadowOffset: { width: 0, height: 2 },
    textShadowRadius: 4,
  },
  divider: {
    width: 48,
    height: 2,
    backgroundColor: 'rgba(255, 255, 255, 0.3)',
    borderRadius: 1,
    marginBottom: 24,
  },
  authorText: {
    fontSize: 18,
    fontWeight: '500',
    color: 'rgba(255, 255, 255, 0.9)',
    letterSpacing: 0.5,
    marginBottom: 40,
  },
  actionsContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 32,
  },
  actionButton: {
    alignItems: 'center',
    gap: 8,
  },
  actionButtonInner: {
    padding: 16,
    borderRadius: 999,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.05)',
  },
  actionButtonActive: {
    backgroundColor: '#FFFFFF',
  },
  actionButtonActiveSettings: {
    backgroundColor: '#FFFFFF',
  },
  actionButtonInactive: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
  },
  actionLabel: {
    fontSize: 10,
    fontWeight: '500',
    textTransform: 'uppercase',
    letterSpacing: 2,
    color: 'rgba(255, 255, 255, 0.6)',
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    width: 256,
    padding: 16,
    borderRadius: 16,
    backgroundColor: 'rgba(0, 0, 0, 0.6)',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.1)',
  },
  settingsContainer: {
    gap: 16,
  },
  settingsSection: {
    gap: 8,
  },
  settingsLabel: {
    fontSize: 10,
    textTransform: 'uppercase',
    letterSpacing: 2,
    fontWeight: '700',
    color: 'rgba(255, 255, 255, 0.5)',
    marginLeft: 4,
  },
  optionsRow: {
    flexDirection: 'row',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 8,
    padding: 4,
  },
  optionButton: {
    flex: 1,
    paddingVertical: 8,
    borderRadius: 6,
    alignItems: 'center',
  },
  optionButtonActive: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
  },
  optionButtonText: {
    fontSize: 12,
    color: 'rgba(255, 255, 255, 0.5)',
  },
  optionButtonTextActive: {
    color: '#FFFFFF',
    fontWeight: '600',
  },
  sizeButtonText: {
    color: 'rgba(255, 255, 255, 0.5)',
    fontWeight: '600',
  },
});
