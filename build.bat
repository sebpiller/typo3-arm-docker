REM On Windows, build the current Jenkins image and push it to public docker registry
docker buildx build --push --platform linux/amd64,linux/arm64,linux/arm/v7 --tag sebpiller/typo3 .
pause