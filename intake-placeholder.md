## T14 Bug Fix: Remove inner NavigationStack from PodcastDiscoveryView

Branch: browse-flow-update

### Fix
PodcastDiscoveryView has its own NavigationStack at line 27 which conflicts 
with the parent NavigationStack in HomeView when pushed via navigation.

In PodcastDiscoveryView.swift:
- Remove the inner NavigationStack wrapper (line 27 opening, and its 
  corresponding closing brace)
- Keep all content inside intact — only remove the NavigationStack wrapper itself
- Do not change anything else in the file

Build must succeed. No other files touched.