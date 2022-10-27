REM This file gives an example of how to "merge" (overwrite) a specific folder from one branch to another branch.
REM Merge out of the box supports merging of commits, whereas this is a way to move all folder content from one branch to another.
REM The example "merges" the 'testfiles' folder from 'dev' branch into 'main' branch.
REM Author: Rune Rasmussen (www.runerasmussen.dk)

git checkout main                   REM Go to the destination branch
rm -r testfiles                     REM Remove current folder content, to ensure files not in the source folder are removed from destination folder
git checkout dev -- testfiles/      REM Copy content from 'testfiles' folder in 'dev' branch
git commit -a -m "merge of 'testfiles' folder from 'dev' to 'main' branch"  REM commit the changes in the destination branch
git checkout dev                    REM Go back to 'dev' branch to continue working (avoid changes in 'main' branch)