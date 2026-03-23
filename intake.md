# 1. Make sure everything is committed on the branch
git add -A && git commit -m "T105: Granola-inspired home treatment — elevated Continue Listening surface + anchored empty state"

# 2. Switch to main
git checkout main

# 3. Squash merge
git merge --squash t102-home-granola-treatment

# 4. Commit the squash
git commit -m "T105: Granola-inspired home treatment — anchored empty state (GeometryReader, 42% position) + removed band treatment per visual review"

# 5. Force delete the branch
git branch -D t102-home-granola-treatment

# 6. Push to origin
git push origin main