export interface Quote {
  id: string;
  text: string;
  author: string;
  category?: string;
}

export enum AppView {
  FEED = 'FEED',
  FAVORITES = 'FAVORITES',
}

export type FontFamily = 'serif' | 'sans' | 'mono';
export type TextSize = 'sm' | 'md' | 'lg';

export interface AppearanceSettings {
  font: FontFamily;
  size: TextSize;
}