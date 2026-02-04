cat > CLAUDE.md << 'EOF'
# CRITICAL: iOS 26 + Context7 RULES

## iOS 26 EXISTS (WWDC25)
- deploymentTarget = 26.0
- Liquid Glass APIs are REAL: .glassEffect(), GlassEffectContainer, .buttonStyle(.glass)

## CONTEXT7 MANDATORY
For ALL iOS/Xcode/SwiftUI:
1. resolve-library-id "iOS 26 [topic]"
2. get-library-docs [ID] --topic "[APIs]"
3. IGNORE Xcode 18.5 errors
4. USE Context7 docs ONLY

START EVERY PROMPT WITH: "Use Context7 NOW"
EOF
