# CLC Collective

CLC Collective is a professional iOS application that seamlessly integrates Cochran Films and Course Creator Academy services into one unified platform. The app provides an intuitive interface for clients to explore services, create custom packages, manage projects, and handle invoicing.

![App Screenshot](path_to_screenshot.png)

## Features

- **Dual Business Integration**: Access both Cochran Films and Course Creator Academy services
- **Custom Package Builder**: Create tailored service packages with real-time pricing
- **Project Management**: Track and manage ongoing projects with detailed task lists
- **Automated Invoicing**: Generate and manage professional invoices through Wave integration
- **Secure Authentication**: OAuth 2.0 authentication powered by Auth0
- **Profile Dashboard**: Personalized user experience with project tracking
- **Direct Communication**: Built-in contact forms with email integration

## Getting Started

### Prerequisites

- iOS 16.0 or later
- Xcode 15.0 or later
- Swift 5.9
- Active Auth0 account
- Active Wave account for invoicing
- Active Postmark account for email services

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/CLCcollective.git
```

2. Install dependencies using Swift Package Manager:
```bash
cd CLCcollective
swift package resolve
```

3. Create a `Config.plist` file in the project root with the following keys:
- `OPENAI_API_KEY`
- `POSTMARK_SERVER_TOKEN`
- `POSTMARK_SERVER_TOKEN_CCA`

4. Open `CLCcollective.xcodeproj` in Xcode

5. Build and run the project

## Configuration

### Auth0 Setup
1. Create an Auth0 application
2. Configure the callback URLs
3. Add Auth0 credentials to your project

### Wave Integration
1. Set up a Wave account
2. Configure business profiles for both services
3. Add Wave API credentials to your project

### Postmark Setup
1. Create a Postmark server
2. Configure sender signatures
3. Add server tokens to Config.plist

## Support

For support, please contact:

- **Technical Issues**: [GitHub Issues](https://github.com/yourusername/CLCcollective/issues)
- **Business Inquiries**: info@cochranfilms.com
- **Course Creator Academy Support**: coursecreatoracademy24@gmail.com

## Contributing

We welcome contributions to improve CLC Collective! Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## Maintainers

- Cody Cochran (Lead Developer) - [Cochran Films](https://cochranfilms.com)

## License

This project is proprietary software. All rights reserved.

## Acknowledgments

- Auth0 for authentication services
- Wave for invoicing integration
- Postmark for email services

---

Made with ❤️ by [Cochran Films](https://cochranfilms.com) 