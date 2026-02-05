# Claude Code Prompt - EchoCast Complete Implementation

## Primary Instruction

Read and follow the complete workflow in: **MASTER-WORKFLOW.md**

This master workflow orchestrates the use of three supporting guides:
1. ENHANCED-PLAYER-SCAN.md (Phase 1: Inventory)
2. DEDUPLICATION-GUIDE.md (Phase 2: Cleanup)
3. FIGMA-ACCURATE-IMPLEMENTATION.md (Phase 3: Refinement)

---

## Task: Execute 3-Phase Implementation

Follow MASTER-WORKFLOW.md exactly, implementing all three phases with stop points for approval.

### Supporting Documentation

**Phase 1 (Inventory) - Reference:**
- ENHANCED-PLAYER-SCAN.md
- Run all detection scans
- Create inventory table
- Output: docs/inventory-report.md

**Phase 2 (Deduplication) - Reference:**
- DEDUPLICATION-GUIDE.md
- Remove duplicates
- Fix navigation
- Output: Clean codebase with 2 tabs

**Phase 3 (Figma Refinement) - Reference:**
- FIGMA-ACCURATE-IMPLEMENTATION.md
- Extract Figma specs with MCP tools
- Implement pixel-perfect components
- Output: docs/figma-measurements.md + refined components

### Figma Design Links

All designs are in: https://www.figma.com/design/BX4rcdUUTuTbIYM9CptAR5/%E2%9C%A8-Kai-s-Projects

Specific screens to implement:
1. Home Empty State: node-id=1416-7172
2. Home With Content: node-id=1696-3836
3. Player Listening Tab: node-id=1878-4405
4. Player Notes Tab: node-id=1878-5413
5. Player Episode Info Tab: node-id=1878-5414

---

## Critical Requirements

1. **Follow MASTER-WORKFLOW.md phase sequence** - Don't skip phases
2. **STOP between phases** - Wait for approval before continuing
3. **Git commit after each phase** - Frequent, safe commits
4. **Document everything** - Create all specified output files
5. **Use Figma MCP tools** - Extract exact specifications in Phase 3

---

## Git Strategy

Repository: https://github.com/mrwangkai/EchoCast
Branch: after-laptop-crash-recovery

**Commit points:**
- After Phase 1 completion
- After Phase 2 completion
- After each component in Phase 3

---

## Progress Tracking

Document all progress in: **docs/implementation-progress.md**

Use the template from MASTER-WORKFLOW.md to track:
- Phase completion status
- Checklist items
- Timestamps
- Blockers or questions

---

## Stop Points for Approval

**After Phase 1:**
- Present inventory-report.md
- Wait for approval of keep/delete decisions

**After Phase 2:**
- Confirm build succeeds
- Confirm app runs with 2 tabs
- Wait for approval to proceed

**After Phase 3:**
- Present figma-measurements.md
- Show implemented components
- Confirm 95%+ accuracy

---

## Expected Timeline

- Phase 1 (Inventory): ~30 minutes
- Phase 2 (Deduplication): ~1-2 hours
- Phase 3 (Figma Refinement): ~3-4 hours

**Total: ~5-6 hours of processing time**

---

## Success Criteria

From MASTER-WORKFLOW.md:

### Clean Codebase
- ✅ Only ONE episode player component
- ✅ Only ONE note capture component
- ✅ No duplicates anywhere
- ✅ 2 tabs: Home + Library
- ✅ Icon buttons: Find + Settings

### Figma Accuracy
- ✅ 95%+ visual match to designs
- ✅ All measurements within 2pt tolerance
- ✅ Uses EchoCastDesignTokens throughout
- ✅ Typography exact
- ✅ Colors exact

### Functionality
- ✅ App builds without errors
- ✅ All features work smoothly
- ✅ Player controls sticky across tabs
- ✅ Note markers positioned correctly

---

## BEGIN EXECUTION

Start with Phase 1 as defined in MASTER-WORKFLOW.md.

Read ENHANCED-PLAYER-SCAN.md and begin comprehensive duplicate detection.

Report findings in docs/inventory-report.md when complete.
