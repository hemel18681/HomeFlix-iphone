/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        netflix: {
          red: '#E50914',
          darkRed: '#B81D24',
          black: '#141414',
          card: '#181818',
          hover: '#282828',
          border: '#333333',
          muted: '#808080',
          light: '#E5E5E5'
        }
      },
      fontFamily: {
        netflix: ['Netflix Sans', 'Helvetica Neue', 'Segoe UI', 'Roboto', 'Ubuntu', 'sans-serif']
      },
      boxShadow: {
        'netflix-card': '0 8px 24px rgba(0, 0, 0, 0.75)',
        'netflix-modal': '0 12px 48px rgba(0, 0, 0, 0.9)'
      }
    },
  },
  plugins: [],
}
