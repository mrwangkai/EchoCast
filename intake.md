Update docs/echocast_todo.md to mark T22 as complete with today's date and note the CarPlay fixes applied.
Then run the following git commands:

1. git add -A
2. Use this exact multi-line commit message:

T22: Fix CarPlay scene registration — CarPlay now functional in simulator

Root causes fixed:
- UIApplicationSupportsCarPlay was missing from Info.plist (iOS was not
  registering EchoCast as a CarPlay-capable app)
- AppDelegate.swift was missing entirely — no implementation of
  application(_:configurationForConnecting:options:) meant iOS could not
  connect the CarPlay scene, causing "No scene exists for identity" error
- CarPlaySceneDelegate.swift and CarPlayNowPlayingController.swift were
  not added to the Xcode target, so the classes were not compiled

Validation: EchoCast CarPlay template loads in simulator showing
CPListTemplate with "No recent episodes" state. Physical device
validation pending TestFlight build.

3. git checkout main
4. git merge t43-view-all-sheets
5. git push origin main

Stop here and wait for confirmation before doing anything else.