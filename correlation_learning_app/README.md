# Correlation Learning App Package

## Overview
This package contains an interactive web application designed to help students and faculty understand correlation coefficients through experiential learning. The app uses a "guess the correlation" game format with structured learning progression.

## Files Included

### Core Application Files
- `corr_guessing_game_structured.R` - Main structured learning app with 4 phases
- `corrslider.R` - Simple correlation slider for testing smooth transitions
- `www/` - Web assets folder containing logo and styling

### Documentation
- `blog_post_outline.md` - Complete outline for educational blog post
- `screenshot_guide.md` - Guide for taking and organizing screenshots
- `installation_instructions.md` - Technical setup instructions for hosting

## Educational Purpose
This app helps users develop an intuitive understanding of correlation coefficients through interactive, experiential learning. It's designed for:

- **Students** learning statistics, research methods, or organizational psychology
- **Faculty** teaching statistical concepts in business, psychology, or related fields
- **Professionals** who need to understand research findings and effect sizes
- **Anyone** interested in developing statistical literacy

## Key Features

### Four Learning Phases
1. **Intuitive Relationships** - Familiar correlations (height/weight, study time/GPA)
2. **Medical Research** - Surprising medical intervention effects
3. **Business & Organizational Psychology** - Workplace-relevant correlations from Meyer et al. (2001)
4. **Mixed Challenges** - Combined examples to test integrated understanding

### Interactive Elements
- Real-time scatter plot updates with smooth transitions
- Immediate feedback on correlation guesses
- Binomial Effect Size Display (BESD) for effect size interpretation
- Educational explanations for each correlation

### Accessibility
- **Web-based** - No software installation required for users
- **Mobile-friendly** - Works on phones, tablets, and computers
- **No registration** - Start learning immediately
- **Free access** - Available to anyone with internet

## Hosting Information

### For Users
- **No technical knowledge required** - simply visit the website
- **Works in any modern browser** - Chrome, Firefox, Safari, Edge
- **No downloads or installations** - everything runs in the browser

### For Hosting
- Requires R and R Shiny server setup
- Can be deployed on platforms like Shinyapps.io, RStudio Connect, or custom servers
- See `installation_instructions.md` for technical setup details

## Educational Benefits

### Learning Outcomes
- Develop intuitive understanding of correlation strength
- Learn to interpret effect sizes in practical terms
- Build confidence in discussing research findings
- Connect statistical concepts to real-world applications

### Research Foundation
- Based on Meyer et al. (2001) meta-analysis of psychological testing
- Uses BESD methodology (Rosenthal & Rubin, 1982) for effect size interpretation
- Incorporates educational psychology principles for effective learning

## Usage Scenarios

### For Faculty
- **In-class demonstrations** - Show live during lectures
- **Homework assignments** - Have students complete phases
- **Discussion starters** - Use surprising correlations to spark debate
- **Assessment tool** - Gauge student understanding

### For Students
- **Self-paced learning** - Work through phases independently
- **Review tool** - Reinforce classroom concepts
- **Practice** - Build intuition through repeated exposure
- **Preparation** - Get ready for research methods courses

### For Organizations
- **Training programs** - Teach data literacy
- **Research teams** - Build shared understanding of effect sizes
- **Decision makers** - Understand correlation vs. causation

## Technical Requirements

### For Hosting (Not Users)
- R 4.0 or higher
- R Shiny package
- plotly package
- ggplot2 package
- Web server or cloud hosting platform

### For Users
- Modern web browser
- Internet connection
- No other requirements

## Getting Started

### For Users
1. Visit the hosted website
2. Start with Phase 1 (Intuitive Relationships)
3. Make correlation guesses and see immediate feedback
4. Progress through phases to build understanding
5. Use BESD to understand effect sizes

### For Hosting
1. Follow instructions in `installation_instructions.md`
2. Deploy the R Shiny app to your preferred platform
3. Share the URL with your intended audience
4. Monitor usage and gather feedback

## Support and Feedback

### For Technical Issues
- Check the installation instructions
- Ensure all required R packages are installed
- Verify server configuration and permissions

### For Educational Use
- Review the blog post outline for implementation ideas
- Use the screenshot guide to create educational materials
- Adapt the app for your specific teaching needs

## Future Development

### Potential Enhancements
- Additional correlation types (non-linear, categorical)
- More domain-specific examples
- Integration with learning management systems
- Analytics for tracking learning progress
- Multilingual support

### Community Contributions
- Share feedback and suggestions
- Contribute new correlation examples
- Help improve educational content
- Suggest new features and improvements

---

*This app demonstrates how interactive technology can make complex statistical concepts accessible and engaging for learners at all levels.* 