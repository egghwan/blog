hugo -t lotusdocs
cd public
git add .
git commit -m"v6"
git push origin main
cd ..
git add .
git commit -m"v6"
git push origin master