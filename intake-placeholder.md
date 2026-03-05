## T14 Polish: Fix Browse header flash — switch to inline navigation title

Branch: browse-flow-update

In PodcastDiscoveryView.swift:

Add .navigationBarTitleDisplayMode(.inline) alongside the existing 
.navigationTitle("Browse") modifier.

That's the only change. Build must succeed.