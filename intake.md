okay, let's merge the t57 branch to main

git checkout main
git merge t57-continue-listening-disappears
git push origin main

Once you are done, then delete the branch to keep things clean:

git branch -d t57-continue-listening-disappears
git push origin --delete t57-continue-listening-disappears