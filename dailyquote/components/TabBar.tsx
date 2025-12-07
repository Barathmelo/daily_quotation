import React, { useState, useEffect } from 'react';
import { View, TouchableOpacity, Text, StyleSheet, Pressable, Platform } from 'react-native';
import { AppView } from '../types';
import { Layers, Heart } from 'lucide-react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';

interface TabBarProps {
  currentView: AppView;
  onChangeView: (view: AppView) => void;
}

export const TabBar: React.FC<TabBarProps> = ({ currentView, onChangeView }) => {
  const insets = useSafeAreaInsets();
  // Optimistic UI state for instant response
  const [activeTab, setActiveTab] = useState(currentView);

  // Sync with prop if it changes externally
  useEffect(() => {
    setActiveTab(currentView);
  }, [currentView]);

  const handlePress = (view: AppView) => {
    if (activeTab === view) return;

    // 1. Instant visual update
    setActiveTab(view);

    // 2. Haptics (React Native Haptics API - iOS only)
    // Note: For cross-platform haptics, consider using react-native-haptic-feedback
    if (Platform.OS === 'ios') {
      // iOS haptics are handled natively by Pressable feedback
    }
    
    // 3. Propagate change
    onChangeView(view);
  };

  return (
    <>
      {/* Gradient fade above tab bar */}
      <View style={styles.gradientFade} />
      
      {/* Native iOS Style Tab Bar */}
      <View style={[styles.container, { paddingBottom: Math.max(insets.bottom, 32) }]}>
        <View style={styles.content}>
          
          {/* Daily / Feed Tab */}
          <Pressable
            onPress={() => handlePress(AppView.FEED)}
            style={({ pressed }) => [
              styles.tab,
              pressed && styles.tabPressed
            ]}
          >
            <View style={[
              styles.tabIconContainer,
              activeTab === AppView.FEED && styles.tabIconContainerActive
            ]}>
              <Layers 
                width={28} 
                height={28} 
                color={activeTab === AppView.FEED ? '#FFFFFF' : '#737373'}
                fill={activeTab === AppView.FEED ? 'rgba(255, 255, 255, 0.1)' : 'none'}
                strokeWidth={activeTab === AppView.FEED ? 2.5 : 2}
              />
            </View>
            <Text style={[
              styles.tabLabel,
              activeTab === AppView.FEED && styles.tabLabelActive
            ]}>
              Daily
            </Text>
          </Pressable>
          
          {/* Favorites Tab */}
          <Pressable
            onPress={() => handlePress(AppView.FAVORITES)}
            style={({ pressed }) => [
              styles.tab,
              pressed && styles.tabPressed
            ]}
          >
            <View style={[
              styles.tabIconContainer,
              activeTab === AppView.FAVORITES && styles.tabIconContainerActiveFavorites
            ]}>
              <Heart 
                width={28} 
                height={28} 
                color={activeTab === AppView.FAVORITES ? '#EF4444' : '#737373'}
                fill={activeTab === AppView.FAVORITES ? '#EF4444' : 'none'}
                strokeWidth={activeTab === AppView.FAVORITES ? 2.5 : 2}
              />
            </View>
            <Text style={[
              styles.tabLabel,
              activeTab === AppView.FAVORITES && styles.tabLabelActiveFavorites
            ]}>
              Saved
            </Text>
          </Pressable>

        </View>
      </View>
    </>
  );
};

const styles = StyleSheet.create({
  gradientFade: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    height: 128,
    backgroundColor: 'transparent',
    // Note: For gradient effect, consider using react-native-linear-gradient
    // For now, using a semi-transparent overlay
    opacity: 0.8,
  },
  container: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: 'rgba(23, 23, 23, 0.6)',
    borderTopWidth: 1,
    borderTopColor: 'rgba(255, 255, 255, 0.1)',
    paddingTop: 8,
  },
  content: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    alignItems: 'center',
    maxWidth: 400,
    marginHorizontal: 'auto',
  },
  tab: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 4,
  },
  tabPressed: {
    opacity: 0.7,
  },
  tabIconContainer: {
    padding: 8,
    borderRadius: 16,
  },
  tabIconContainerActive: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
  },
  tabIconContainerActiveFavorites: {
    backgroundColor: 'rgba(239, 68, 68, 0.1)',
  },
  tabLabel: {
    fontSize: 10,
    fontWeight: '600',
    letterSpacing: 1,
    color: '#737373',
    marginTop: 4,
  },
  tabLabelActive: {
    color: '#FFFFFF',
  },
  tabLabelActiveFavorites: {
    color: '#EF4444',
  },
});
