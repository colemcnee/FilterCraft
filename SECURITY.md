# Security Policy

## Supported Versions

We provide security updates for the following versions of FilterCraft:

| Version | Supported          |
| ------- | ------------------ |
| main    | ✅ Active development |
| Latest release | ✅ Full support |

## Reporting a Vulnerability

If you discover a security vulnerability in FilterCraft, please follow these steps:

### 🔒 Private Disclosure (Preferred)

1. **Do NOT create a public issue** for security vulnerabilities
2. Send an email to the maintainer with details about the vulnerability
3. Include steps to reproduce the issue if possible
4. Allow reasonable time for the issue to be addressed before public disclosure

### 📝 What to Include

When reporting a security issue, please provide:

- A clear description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Any suggested fixes or mitigations
- Your contact information for follow-up

### 🕒 Response Timeline

- **Acknowledgment**: Within 48 hours of report
- **Initial Assessment**: Within 1 week
- **Fix Development**: Depends on severity and complexity
- **Public Disclosure**: After fix is deployed (coordinated disclosure)

## Security Measures

FilterCraft implements the following security measures:

### 🛡️ Repository Security
- Branch protection on main branch
- Required pull request reviews
- Automated security scanning
- Dependency vulnerability monitoring
- Secret scanning with push protection

### 🔍 Code Security
- Regular dependency updates via Dependabot
- Static analysis in CI/CD pipeline
- Code review requirements
- Secure coding practices

### 📱 Application Security
- Sandboxed execution environment
- Secure image processing pipelines
- Memory safety through Swift
- No network communication (offline-first design)
- User data remains local to device

## Best Practices for Contributors

When contributing to FilterCraft:

1. **Dependencies**: Only add well-maintained, trusted dependencies
2. **Sensitive Data**: Never commit secrets, API keys, or personal data
3. **Input Validation**: Always validate and sanitize user inputs
4. **Error Handling**: Implement proper error handling to prevent information leakage
5. **Testing**: Include security-focused test cases
6. **Documentation**: Document security-related design decisions

## Security-Related Issues

For non-security bugs or feature requests related to security, you can:

- Create a public issue with the `security` label
- Discuss security improvements in pull requests
- Propose security enhancements through feature requests

## Acknowledgments

We appreciate the security research community's efforts in keeping FilterCraft secure. Responsible disclosure helps protect all users of the application.

---

**Last Updated**: August 2025
**Contact**: Repository maintainer via GitHub