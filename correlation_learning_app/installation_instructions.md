# Hosting and Deployment Instructions

## Overview
This guide provides step-by-step instructions for hosting the Correlation Learning App online so that anyone can access it through a web browser. The app is designed to be accessible to users with no technical knowledge.

## Hosting Options

### Free Hosting Platforms
1. **Shinyapps.io** (Recommended for beginners)
   - Free tier available
   - Easy deployment
   - Automatic scaling
   - No server management required

2. **RStudio Cloud**
   - Free tier available
   - Integrated development environment
   - Easy sharing and collaboration

### Paid/Professional Hosting
1. **RStudio Connect**
   - Enterprise-grade hosting
   - Advanced security features
   - User management and analytics
   - Integration with existing infrastructure

2. **Custom Server**
   - Full control over hosting environment
   - Custom domain and branding
   - Advanced configuration options

## Prerequisites for Hosting

### Required Software (For Hosting Only)
- **R** (version 4.0 or higher)
- **RStudio** (recommended for development)
- **R Shiny** package
- **plotly** package
- **ggplot2** package

### System Requirements
- **RAM**: Minimum 4GB, recommended 8GB
- **Storage**: 1GB free space
- **Internet**: Required for package installation and deployment

## Deployment Steps

### Option 1: Shinyapps.io (Recommended)

#### 1. Create Account
1. Go to [https://www.shinyapps.io/](https://www.shinyapps.io/)
2. Sign up for a free account
3. Verify your email address

#### 2. Install rsconnect Package
```r
install.packages('rsconnect')
```

#### 3. Configure Deployment
```r
library(rsconnect)
rsconnect::setAccountInfo(name='<ACCOUNT>',
                          token='<TOKEN>',
                          secret='<SECRET>')
```
*Get these values from your Shinyapps.io account dashboard*

#### 4. Deploy the App
```r
rsconnect::deployApp('corr_guessing_game_structured.R')
```

#### 5. Share the URL
- Your app will be available at: `https://yourusername.shinyapps.io/corr_guessing_game_structured/`
- Share this URL with your intended audience

### Option 2: RStudio Cloud

#### 1. Create RStudio Cloud Account
1. Go to [https://rstudio.cloud/](https://rstudio.cloud/)
2. Sign up for a free account
3. Create a new project

#### 2. Upload Files
1. Upload `corr_guessing_game_structured.R` to your project
2. Upload the `www/` folder if it contains custom assets
3. Install required packages in the R console

#### 3. Deploy and Share
1. Click "Publish" in RStudio
2. Choose "Shiny" as the document type
3. Set sharing permissions (public or private)
4. Share the generated URL

### Option 3: Custom Server

#### 1. Server Setup
1. Install R and R Shiny Server on your server
2. Configure web server (nginx/Apache) as reverse proxy
3. Set up SSL certificates for HTTPS

#### 2. Application Deployment
1. Upload app files to server
2. Install required R packages
3. Configure Shiny Server to serve the app
4. Set up monitoring and logging

#### 3. Domain Configuration
1. Point domain to your server
2. Configure DNS settings
3. Set up SSL certificates
4. Test accessibility

## Post-Deployment

### Testing
1. **Functionality Test**
   - Test all phases of the app
   - Verify smooth transitions work
   - Check BESD calculations
   - Test on different devices and browsers

2. **Performance Test**
   - Monitor response times
   - Check memory usage
   - Test with multiple concurrent users

3. **User Experience Test**
   - Have others try the app
   - Gather feedback on usability
   - Identify any issues or improvements

### Monitoring
1. **Usage Analytics**
   - Track number of users
   - Monitor session duration
   - Identify popular features
   - Track error rates

2. **Performance Monitoring**
   - Monitor server resources
   - Track response times
   - Set up alerts for issues

### Maintenance
1. **Regular Updates**
   - Keep R and packages updated
   - Monitor for security updates
   - Backup app data regularly

2. **User Support**
   - Provide contact information for issues
   - Create FAQ or help documentation
   - Monitor user feedback

## Security Considerations

### For Public Apps
- Ensure no sensitive data is exposed
- Use HTTPS for all connections
- Implement rate limiting if needed
- Monitor for abuse or misuse

### For Educational Institutions
- Consider user authentication if needed
- Implement access controls if required
- Follow institutional IT policies
- Ensure compliance with data protection regulations

## Troubleshooting

### Common Issues
1. **App Won't Deploy**
   - Check all required packages are installed
   - Verify file paths are correct
   - Check for syntax errors in R code

2. **App Runs Slowly**
   - Optimize R code for performance
   - Consider upgrading hosting plan
   - Monitor server resources

3. **Users Can't Access**
   - Check URL is correct
   - Verify hosting platform is running
   - Check firewall and network settings

### Getting Help
- Check hosting platform documentation
- Review R Shiny deployment guides
- Contact hosting platform support
- Consult R community forums

## Cost Considerations

### Free Options
- Shinyapps.io: 5 apps, 25 hours/month
- RStudio Cloud: 1 project, 15 hours/month
- GitHub Pages (for static content)

### Paid Options
- Shinyapps.io: $9/month for 5 apps, 100 hours
- RStudio Connect: $10,000+/year (enterprise)
- Custom server: $20-100/month depending on size

## Best Practices

### For Educational Use
1. **Start Simple**: Use free hosting for initial deployment
2. **Test Thoroughly**: Ensure app works for your target audience
3. **Gather Feedback**: Continuously improve based on user input
4. **Document Usage**: Create guides for students and faculty

### For Production Use
1. **Choose Appropriate Hosting**: Match hosting to expected usage
2. **Implement Monitoring**: Track usage and performance
3. **Plan for Scale**: Be ready to upgrade as usage grows
4. **Maintain Security**: Follow security best practices

---

*This guide helps you make the Correlation Learning App accessible to anyone with an internet connection, regardless of their technical background.* 