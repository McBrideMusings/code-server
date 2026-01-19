# AI Coding Agents

This document covers the AI-powered coding assistants available in the development container and how to configure and use them effectively.

## Available Agents

### Claude Code
**Provider**: Anthropic  
**Installation**: `https://claude.ai/install.sh`  
**Binary Location**: `~/.local/bin/claude`

#### Features
- Code generation and refactoring
- Technical documentation writing
- Code review and optimization suggestions
- Multi-language support with context awareness

#### Usage
```bash
# Interactive coding session
claude

# Code review
claude review file.py

# Generate tests
claude test --file src/main.js

# Documentation generation
claude docs --input src/ --output docs/
```

#### Configuration
```bash
# Set API key (required)
export ANTHROPIC_API_KEY="your-api-key"

# Optional: Set model preference
export CLAUDE_MODEL="claude-3-5-sonnet-20241022"
```

### OpenAI Codex
**Provider**: OpenAI  
**Installation**: `npm install -g @openai/codex`  
**Binary Location**: `/usr/local/bin/codex`

#### Features
- Natural language to code conversion
- Code completion and suggestion
- Bug detection and fixes
- Integration with popular editors

#### Usage
```bash
# Generate code from description
codex "create a REST API for user management in Express.js"

# Complete code snippet
codex complete --file partial.js

# Explain existing code
codex explain --file complex-algorithm.py
```

#### Configuration
```bash
# Set API key
export OPENAI_API_KEY="your-openai-key"

# Configure model
export CODEX_MODEL="gpt-4"
```

### Google Gemini CLI
**Provider**: Google  
**Installation**: `npm install -g @google/gemini-cli`  
**Binary Location**: `/usr/local/bin/gemini`

#### Features
- Multi-modal code analysis (text, images, diagrams)
- Architecture recommendations
- Performance optimization suggestions
- Code security analysis

#### Usage
```bash
# Analyze codebase
gemini analyze --project ./src

# Security scan
gemini security --scan ./

# Performance review
gemini perf --file slow-function.js

# Architecture advice
gemini arch --describe "microservices for e-commerce"
```

#### Configuration
```bash
# Set API key
export GOOGLE_AI_API_KEY="your-google-key"

# Configure project
gemini config set project your-project-id
```

### OpenCode
**Provider**: OpenCode.ai  
**Installation**: `https://opencode.ai/install`  
**Binary Location**: TBD (check installation output)

#### Features
- Open-source focused code generation
- License-compliant code suggestions
- Community-driven model improvements
- Self-hosted options available

#### Usage
```bash
# Generate open-source compliant code
opencode generate --license MIT "database connection pool"

# Check license compatibility
opencode license --check ./src

# Community model usage
opencode --model community-python
```

#### Configuration
```bash
# Set preferred license
export OPENCODE_LICENSE="MIT"

# Configure model endpoint
export OPENCODE_ENDPOINT="https://api.opencode.ai"
```

## Integration Patterns

### VS Code Integration
Most agents can be integrated with VS Code through extensions:

```json
{
    "claude.apiKey": "${env:ANTHROPIC_API_KEY}",
    "openai.apiKey": "${env:OPENAI_API_KEY}",
    "gemini.projectId": "${env:GOOGLE_PROJECT_ID}"
}
```

### Git Hooks
Automate code review with git hooks:

```bash
#!/bin/sh
# .git/hooks/pre-commit
claude review --staged --format json > review.json
```

### CI/CD Pipeline
Integrate in build pipelines:

```yaml
steps:
  - name: AI Code Review
    run: |
      claude review --diff HEAD~1..HEAD
      gemini security --scan ./src
```

## Best Practices

### API Key Management
- **Never commit API keys**: Use environment variables
- **Rotate regularly**: Update keys according to provider recommendations
- **Scope appropriately**: Use read-only keys when possible
- **Monitor usage**: Track API consumption and costs

### Prompt Engineering
- **Be specific**: Detailed prompts yield better results
- **Provide context**: Include relevant code and requirements
- **Iterate**: Refine prompts based on output quality
- **Use examples**: Show desired output format

### Code Review Workflow
1. **Local review**: Use agents for initial code review
2. **Human oversight**: Always review AI suggestions
3. **Testing**: Verify generated code with comprehensive tests
4. **Documentation**: Update docs for AI-assisted changes

## Environment Setup

### Required Environment Variables
```bash
# Add to your shell profile or container environment
export ANTHROPIC_API_KEY="sk-ant-..."
export OPENAI_API_KEY="sk-..."
export GOOGLE_AI_API_KEY="AI..."
export OPENCODE_ENDPOINT="https://api.opencode.ai"
```

### Verification Script
```bash
#!/bin/bash
# verify-agents.sh

echo "Checking AI coding agents..."

# Check binaries
for cmd in claude codex gemini opencode; do
    if command -v $cmd >/dev/null 2>&1; then
        echo "✓ $cmd found"
        $cmd --version 2>/dev/null || echo "  (version check failed)"
    else
        echo "✗ $cmd not found"
    fi
done

# Check API keys
echo ""
echo "Checking API keys..."
[ -n "$ANTHROPIC_API_KEY" ] && echo "✓ Claude API key set" || echo "✗ Claude API key missing"
[ -n "$OPENAI_API_KEY" ] && echo "✓ OpenAI API key set" || echo "✗ OpenAI API key missing"
[ -n "$GOOGLE_AI_API_KEY" ] && echo "✓ Google AI API key set" || echo "✗ Google AI API key missing"
```

## Usage Examples

### Code Generation
```bash
# Generate a complete module
claude "Create a Python class for handling JWT tokens with encode, decode, and validation methods"

# Generate tests
codex "Write pytest tests for the JWT class above"

# Generate documentation
gemini "Create API documentation for the JWT module"
```

### Code Review
```bash
# Review for bugs
claude review --focus bugs src/auth.py

# Security analysis
gemini security --deep-scan src/

# Performance analysis
opencode perf --profile src/database.py
```

### Refactoring
```bash
# Modernize code
claude refactor --target python3.12 legacy/

# Optimize performance
codex optimize --metrics cpu,memory src/

# Apply best practices
gemini standards --framework django src/
```

## Troubleshooting

### Agent Not Found
```bash
# Check PATH
echo $PATH | grep -E "(local/bin|\.local/bin)"

# Reinstall if necessary
curl -fsSL https://claude.ai/install.sh | bash
source ~/.bashrc
```

### API Key Issues
```bash
# Verify key format
echo $ANTHROPIC_API_KEY | cut -c1-10  # Should show "sk-ant-..."

# Test connection
claude --test-api
```

### Rate Limiting
- **Monitor usage**: Check API dashboards regularly
- **Implement backoff**: Add delays between requests
- **Cache results**: Store common AI responses
- **Use efficiently**: Batch requests when possible

## Cost Management

### Token Optimization
- **Minimize context**: Only include relevant code
- **Use streaming**: For long responses when available
- **Cache responses**: Store AI output for reuse
- **Choose models wisely**: Balance cost vs. capability

### Budget Controls
- **Set limits**: Configure API spending limits
- **Monitor daily**: Track usage patterns
- **Review monthly**: Analyze cost per feature
- **Optimize prompts**: Reduce token consumption

## Privacy & Security

### Data Handling
- **Review terms**: Understand each provider's data policy
- **Avoid secrets**: Never include API keys, passwords in prompts
- **Use anonymization**: Remove sensitive data from code samples
- **Local alternatives**: Consider self-hosted options for sensitive code

### Audit Trail
- **Log interactions**: Keep records of AI-assisted changes
- **Track attribution**: Note AI contributions in commit messages
- **Review policies**: Ensure compliance with organizational policies
- **Version control**: Maintain clear history of human vs. AI changes