# Dickpic

Analyse photo library for sensetive content

Check out my [Bikini-Bottom](https://github.com/TopScrech/Bikini-Bottom) project that implements a pre-trained [CoreML](https://developer.apple.com/documentation/coreml) model for classifying images in 3 categories: regular, bikini & NSFW

## How does it work?
1. You recieve a photo library permission request
2. The app iterates through photos and videos and runs on-device sensitivity analysis using Apple's [SensitiveContentAnalysis](https://developer.apple.com/documentation/sensitivecontentanalysis) framework
3. Flagged items are shown to let you preview them and delete if needed

## Supported platforms
- iOS/iPadOS 17+ (background processing API is only supported on 26+)
- macOS 14+
