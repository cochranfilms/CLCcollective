# CLC Collective

A powerful iOS app that combines the services of Cochran Films and Course Creator Academy, offering video production services and film education in-person and virtual classes.

<div align="center" style="display: flex; justify-content: center; gap: 20px;">
  <img src="assets/images/app-screenshot.png" alt="CLC Collective Home Screen" width="250"/>
  <img src="assets/images/app-screenshot-2.png" alt="CLC Collective Portfolio View" width="250"/>
  <img src="assets/images/app-screenshot-3.png" alt="CLC Collective Services" width="250"/>
</div>

## Features

- Video Production Services
- Course Creation Tools
- Project Management
- Invoice Generation
- AI Assistant Integration
- Client Portal
- Portfolio Showcase

## Getting Started

1. Clone the repository
2. Install dependencies using Swift Package Manager
3. Set up configuration (see below)
4. Build and run the project in Xcode

## Configuration

The app requires several API keys to function properly. Create a `Config.plist` file in the `CLCcollective` directory using the template provided in `Config.template.plist`. You'll need to set up:

1. OpenAI API key for the AI assistant
2. Postmark Server Token for Cochran Films emails
3. Postmark Server Token for Course Creator Academy emails

## Support

For help and support, contact:
- Email: support@cochranfilms.com
- Website: https://www.cochranfilms.com

## Maintainers

- Cody Cochran (@cochranfilms)

## License

This project is proprietary software. All rights reserved.

## Acknowledgments

- Auth0 for authentication
- OpenAI for AI capabilities
- Postmark for email services
- Wave for invoice management 
