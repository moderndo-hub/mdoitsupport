/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        bangla: ["'Hind Siliguri'", "'Noto Sans Bengali'", "sans-serif"],
      },
      colors: {
        brand: {
          50: "#eefdf3",
          100: "#d6f9e3",
          500: "#1a9e5c",
          600: "#15824c",
          700: "#116840",
        },
      },
    },
  },
  plugins: [],
};
