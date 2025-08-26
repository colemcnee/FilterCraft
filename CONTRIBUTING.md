# Contributing to FilterCraft

Thank you for your interest in contributing to FilterCraft! This document outlines the process for contributing to our professional photo editing application.

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have:

- **macOS 13.0+** for development
- **Xcode 15.0+** with iOS 16.0+ and macOS 12.0+ SDKs  
- **Homebrew** for managing development tools
- **Git** with proper SSH key setup for GitHub

### Initial Setup

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone git@github.com:yourusername/filtercraft.git
   cd filtercraft
   ```
3. **Run the setup script**:
   ```bash
   ./Scripts/setup.sh
   ```
4. **Verify your setup**:
   ```bash
   ./Scripts/test.sh && ./Scripts/lint.sh
   ```

## 🎯 How to Contribute

### Types of Contributions

We welcome several types of contributions:

- **🐛 Bug fixes**: Fix issues in existing functionality
- **✨ New features**: Add new filters, effects, or capabilities
- **📚 Documentation**: Improve docs, comments, or examples
- **🎨 UI/UX improvements**: Enhance user interface and experience
- **⚡ Performance optimizations**: Make the app faster or more efficient
- **🧪 Tests**: Add or improve test coverage
- **🔧 Developer experience**: Improve build tools, CI/CD, or development workflow

### Before You Start

1. **Check existing issues** to see if your contribution is already being worked on
2. **Create an issue** for new features or significant changes to discuss approach
3. **Comment on issues** you'd like to work on to avoid duplicate efforts

## 📝 Development Workflow

### 1. Create a Feature Branch

Always work on a feature branch, never directly on `main`:

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
# or  
git checkout -b docs/documentation-update
```

### 2. Make Your Changes

Follow these guidelines while developing:

#### Code Style
- Use **SwiftLint** for code formatting (run `./Scripts/lint.sh --fix`)
- Follow **existing patterns** and architecture decisions
- Write **clear, descriptive names** for variables and functions
- Add **documentation** for public APIs
- Keep **functions small** and focused (< 50 lines)

#### Architecture Guidelines
- **Separate concerns**: Keep UI, business logic, and data layers distinct
- **Use dependency injection**: Make components testable
- **Follow MVVM patterns**: ViewModels for complex UI logic
- **Leverage Swift features**: Use optionals, enums, and generics appropriately

#### Testing
- **Write tests** for new functionality
- **Update existing tests** when changing behavior  
- **Test on both platforms** (iOS and macOS)
- **Include edge cases** and error conditions

### 3. Test Your Changes

Run the full test suite before committing:

```bash
# Run all tests with coverage
./Scripts/test.sh --coverage

# Run code quality checks
./Scripts/lint.sh --strict

# Test builds on both platforms
./Scripts/build.sh --release
```

### 4. Commit Your Changes

We use [Conventional Commits](https://www.conventionalcommits.org/) format:

```bash
git add .
git commit -m "feat: add new vintage filter effect"
```

#### Commit Message Format

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New features
- `fix`: Bug fixes
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes

**Examples:**
```bash
feat(ios): add new blur filter with intensity control
fix(macos): resolve memory leak in image processing
docs: update installation instructions
test(core): add unit tests for filter application
```

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub with:

- **Clear title** using conventional commit format
- **Detailed description** of changes made
- **Screenshots or demos** for UI changes
- **Testing instructions** for reviewers
- **Breaking changes** clearly noted (if any)

## 🔍 Pull Request Guidelines

### PR Template

Please fill out our PR template completely:

```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)  
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Tested on both iOS and macOS (if applicable)

## Screenshots (if applicable)
Add screenshots or GIFs demonstrating the changes.

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
```

### Review Process

1. **Automated checks** must pass (CI, tests, linting)
2. **Code review** by at least one maintainer
3. **Testing verification** by reviewer when needed
4. **Approval and merge** by maintainer

### Review Criteria

Reviewers will check for:

- **Functionality**: Does it work as intended?
- **Code quality**: Is it readable, maintainable, and well-structured?
- **Performance**: Does it introduce any performance regressions?
- **Testing**: Is it adequately tested?
- **Documentation**: Are changes properly documented?
- **Breaking changes**: Are they justified and clearly communicated?

## 🧪 Testing Guidelines

### Test Categories

Write tests in these categories as appropriate:

#### Unit Tests
- Test individual functions and classes
- Mock external dependencies
- Focus on business logic and edge cases
- Location: `Packages/FilterCraftCore/Tests/`

#### Integration Tests  
- Test component interactions
- Test end-to-end workflows
- Verify cross-platform behavior
- Location: `Apps/*/Tests/`

#### UI Tests
- Test critical user workflows
- Verify accessibility
- Test platform-specific features
- Location: `Apps/*/UITests/`

#### Performance Tests
- Benchmark critical operations
- Detect performance regressions  
- Monitor memory usage
- Location: Test targets with `Performance` suffix

### Writing Good Tests

```swift
func testVintageFilterAppliesCorrectAdjustments() {
    // Arrange
    let editSession = EditSession()
    let testImage = createTestImage()
    
    // Act
    editSession.loadImage(testImage)
    editSession.applyFilter(.vintage, intensity: 1.0)
    
    // Assert
    XCTAssertNotNil(editSession.previewImage)
    XCTAssertEqual(editSession.baseAdjustments.saturation, -0.2, accuracy: 0.01)
    XCTAssertEqual(editSession.baseAdjustments.warmth, 0.3, accuracy: 0.01)
}
```

## 📚 Documentation Standards

### Code Documentation

Use Swift's documentation comments:

```swift
/// Applies a filter to the current image with specified intensity.
/// 
/// - Parameters:
///   - filterType: The type of filter to apply
///   - intensity: The intensity of the effect (0.0 to 1.0)
/// - Returns: True if the filter was applied successfully
public func applyFilter(_ filterType: FilterType, intensity: Float) -> Bool {
    // Implementation
}
```

### README Updates

When adding features:

- Update feature list
- Add usage examples
- Update screenshots if UI changed
- Document any new requirements

### Architecture Documentation

For significant architectural changes:

- Update architecture diagrams
- Document design decisions
- Explain trade-offs made
- Provide migration guides for breaking changes

## 🐛 Bug Reports

When reporting bugs, please include:

### Required Information
- **FilterCraft version**
- **Platform and OS version** (iOS 17.0, macOS 14.1, etc.)
- **Device information** (iPhone 15 Pro, MacBook Pro M2, etc.)
- **Steps to reproduce**
- **Expected behavior**
- **Actual behavior**
- **Screenshots or screen recordings** (if applicable)

### Bug Report Template

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
Add screenshots to help explain your problem.

**Environment:**
 - Device: [e.g. iPhone 15 Pro]
 - OS: [e.g. iOS 17.0]
 - FilterCraft Version: [e.g. 1.0.0]

**Additional context**
Any other context about the problem.
```

## 🌟 Feature Requests

We welcome feature requests! Please:

### Before Submitting
- **Check existing issues** for similar requests
- **Consider the scope** - is this a general-purpose feature?
- **Think about implementation** - is it technically feasible?

### Feature Request Template

```markdown
**Is your feature request related to a problem?**
A clear description of what the problem is.

**Describe the solution you'd like**
A clear description of what you want to happen.

**Describe alternatives you've considered**
Other solutions or features you've considered.

**Additional context**
Screenshots, mockups, or examples of similar features.

**Implementation ideas**
If you have ideas about how this could be implemented.
```

## 🔧 Development Tips

### Useful Commands

```bash
# Run specific test suite
./Scripts/test.sh --ios --coverage

# Fix code style issues automatically  
./Scripts/lint.sh --fix

# Build specific platform
./Scripts/build.sh --macos --release

# Generate Xcode projects
cd Apps/FilterCraft-iOS && xcodegen generate

# Update dependencies
cd Packages/FilterCraftCore && swift package update
```

### Debugging

- Use **Xcode's debugger** for step-through debugging
- Enable **Core Image debug output** for image processing issues  
- Use **Instruments** for performance profiling
- Check **console logs** for runtime warnings

### Performance Considerations

- **Profile before optimizing** - measure actual performance
- **Use Core Image** for image processing when possible
- **Avoid blocking the main thread** for expensive operations
- **Memory management** is crucial for large image processing

## 📞 Getting Help

### Resources

- **Documentation**: [filtercraft.dev/docs](https://filtercraft.dev/docs)
- **API Reference**: Generated docs in Xcode
- **GitHub Discussions**: For questions and general discussion
- **GitHub Issues**: For bug reports and feature requests

### Community

- **Discord**: [FilterCraft Community](https://discord.gg/filtercraft)
- **Twitter**: [@FilterCraftApp](https://twitter.com/FilterCraftApp)
- **Stack Overflow**: Tag questions with `filtercraft`

### Contact Maintainers

For sensitive issues or direct questions:
- Email: [maintainers@filtercraft.dev](mailto:maintainers@filtercraft.dev)
- Create a private GitHub issue

## 🙏 Recognition

Contributors are recognized in several ways:

- **Contributors page**: Listed in CONTRIBUTORS.md
- **Git history**: Permanent record of contributions
- **Release notes**: Significant contributions mentioned
- **Special thanks**: Outstanding contributors highlighted

## 📜 Code of Conduct

This project adheres to our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold this code.

---

**Thank you for contributing to FilterCraft!** 🎉

Your contributions help make professional photo editing accessible to everyone.