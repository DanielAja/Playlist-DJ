# CLAUDE.md - Project Guidelines

## Project Overview
- Web-based Playlist DJ application with HTML, CSS, and JavaScript
- Simple client-side application without build tools (vanilla project)

## Development Commands
- Run locally: Open index.html in a browser or use a local server like `python -m http.server`
- Linting: Install ESLint (`npm install -g eslint`) and run `eslint javascript.js`
- Testing: Manual testing in browser (no automated tests configured yet)

## Code Style Guidelines
- **HTML**: Use semantic HTML5 elements, indent with 2 spaces
- **CSS**: Use descriptive class names, avoid inline styles, organize by component
- **JavaScript**:
  - Use camelCase for variables and functions
  - Prefer const/let over var
  - Add JSDoc comments for functions
  - Use descriptive variable names
  - Handle errors with try/catch blocks for async operations
  - Organize code into logical functions rather than global scope
  - Prefer async/await over raw promises where appropriate

## File Organization
- Keep JavaScript, CSS, and HTML in separate files
- Group related functions together in JavaScript
- Consider component-based organization as app grows