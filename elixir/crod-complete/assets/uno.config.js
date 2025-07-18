import { defineConfig, presetUno, presetIcons, presetWebFonts } from 'unocss'

export default defineConfig({
  // Phoenix LiveView content paths
  content: {
    filesystem: [
      '../lib/crod_web.ex',
      '../lib/crod_web/**/*.*ex',
      './js/**/*.js'
    ]
  },

  // CROD Neural Framework Theme
  theme: {
    colors: {
      // CROD Brand Colors - Black/Deep Blue Aesthetic
      'crod-black': '#000000',
      'crod-dark': '#0F172A',
      'crod-darker': '#020617',
      'crod-blue': '#1E40AF',
      'crod-blue-light': '#3B82F6',
      'crod-blue-accent': '#60A5FA',
      'crod-purple': '#4F46E5',
      'crod-cyan': '#06B6D4',
      
      // Neural Activity Colors
      'neural-low': '#1E293B',
      'neural-mid': '#475569',
      'neural-high': '#94A3B8',
      'neural-active': '#F1F5F9',
      
      // System Status Colors
      'status-online': '#10B981',
      'status-warning': '#F59E0B',
      'status-error': '#EF4444',
      'status-offline': '#6B7280'
    },
    
    // Grid systems for neural visualizations
    gridTemplateColumns: {
      'neural-small': 'repeat(50, minmax(0, 1fr))',
      'neural-medium': 'repeat(77, minmax(0, 1fr))',
      'neural-large': 'repeat(100, minmax(0, 1fr))',
      'neural-huge': 'repeat(150, minmax(0, 1fr))'
    },
    
    // Animation durations
    transitionDuration: {
      'neural': '100ms',
      'ui': '200ms',
      'smooth': '300ms'
    },
    
    // Glassmorphism effects
    backdropBlur: {
      'neural': '12px',
      'ui': '8px'
    }
  },

  presets: [
    presetUno(),
    presetIcons({
      scale: 1.2,
      warn: true
    }),
    presetWebFonts({
      fonts: {
        'mono': 'JetBrains Mono',
        'sans': 'Inter'
      }
    })
  ],

  // Custom rules for CROD-specific styling
  rules: [
    // Neural glow effect
    [/^neural-glow-(.+)$/, ([, c]) => ({
      'box-shadow': `0 0 20px ${c}, 0 0 40px ${c}50, 0 0 60px ${c}20`
    })],
    
    // Pulsing neural activity
    [/^neural-pulse-(.+)$/, ([, c]) => ({
      'animation': `pulse 1s ease-in-out infinite alternate`,
      'background-color': c
    })],
    
    // CROD brand gradient
    ['crod-gradient', {
      'background': 'linear-gradient(135deg, #1E40AF 0%, #3B82F6 50%, #60A5FA 100%)'
    }],
    
    // Neural grid cell
    ['neural-cell', {
      'aspect-ratio': '1/1',
      'border-radius': '2px',
      'transition': 'all 0.1s ease'
    }],
    
    // Glassmorphism panel
    ['glass-panel', {
      'background': 'rgba(15, 23, 42, 0.6)',
      'backdrop-filter': 'blur(12px)',
      'border': '1px solid rgba(59, 130, 246, 0.2)',
      'border-radius': '16px'
    }]
  ],

  // Shortcuts for common patterns
  shortcuts: {
    // Layout shortcuts
    'crod-container': 'fixed inset-0 w-full h-full bg-crod-black text-white overflow-y-auto',
    'crod-nav': 'bg-crod-darker/95 backdrop-blur-xl px-4 md:px-6 py-3 md:py-4 border-b border-crod-blue/20 shadow-lg flex-shrink-0',
    'crod-main': 'flex-1 bg-gradient-to-br from-crod-darker via-crod-dark to-crod-dark/90 p-4 md:p-6 overflow-y-auto',
    'crod-sidebar': 'w-80 bg-crod-darker border-r border-crod-blue/30 p-6 overflow-y-auto',
    
    // Button shortcuts
    'crod-btn': 'px-4 py-2 rounded-lg font-medium transition-all duration-200 hover:scale-105 active:scale-95',
    'crod-btn-primary': 'crod-btn bg-gradient-to-r from-crod-blue to-crod-blue-accent hover:from-crod-blue-accent hover:to-crod-blue-light text-white shadow-lg hover:shadow-crod-blue/50',
    'crod-btn-secondary': 'crod-btn bg-crod-darker/50 hover:bg-crod-dark/80 text-crod-blue-accent border border-crod-blue/30 backdrop-blur-sm',
    'crod-btn-game': 'p-4 rounded-xl font-semibold text-lg transition-all duration-200 hover:scale-105 shadow-lg active:scale-95',
    
    // Card shortcuts
    'crod-card': 'bg-crod-dark/50 backdrop-blur-sm rounded-xl p-4 md:p-6 border border-crod-blue/20 hover:border-crod-blue/30 transition-all duration-300 shadow-lg hover:shadow-xl hover:shadow-crod-blue/10',
    'crod-card-hover': 'crod-card hover:scale-105 cursor-pointer',
    'crod-stats-card': 'crod-card text-center',
    
    // Text shortcuts
    'crod-title': 'text-xl md:text-2xl font-bold tracking-tight text-white',
    'crod-subtitle': 'text-base md:text-lg text-crod-blue-accent font-medium',
    'crod-text': 'text-gray-300',
    'crod-text-muted': 'text-gray-400',
    
    // Neural visualization shortcuts
    'neural-container': 'w-full h-full bg-crod-dark overflow-hidden',
    'neural-grid': 'grid gap-0 p-2',
    'neural-inactive': 'neural-cell bg-neural-low',
    'neural-active-low': 'neural-cell bg-neural-mid',
    'neural-active-mid': 'neural-cell bg-neural-high',
    'neural-active-high': 'neural-cell bg-neural-active neural-pulse-#60A5FA',
    
    // Status indicators
    'status-online': 'w-2 h-2 bg-status-online rounded-full animate-pulse',
    'status-warning': 'w-2 h-2 bg-status-warning rounded-full',
    'status-error': 'w-2 h-2 bg-status-error rounded-full',
    'status-offline': 'w-2 h-2 bg-status-offline rounded-full'
  }
})