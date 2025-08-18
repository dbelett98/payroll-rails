module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/assets/stylesheets/*.css'  
  ],
  theme: {
    extend: {
      colors: {
        'psb-blue': '#1E3A8A',
        'psb-purple': '#8B5CF6',
        'psb-yellow': '#FBBF24',
        'psb-teal': '#14B8A6'
      }
    }
  },
  plugins: []
}