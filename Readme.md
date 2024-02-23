# A Guide to My Game's Actual Build Script
In the spirit of being real, I have included my game's actual build script on Apple platforms.

This is the whole thing. It's what I actually use to build and ship the actual game (Mooselutions) that I actually sell for real money ($4.99).

The one thing you will immediately notice is the lack of an Xcode project. It's not that I don't have an Xcode project. I do, but I only use Xcode as a debugger and totally bypass using it as a build system.

Xcode's build system is slow and more complicated than mine, so I don't use it. I like to walk through the logic of a process procedurally. It annoys me that Xcode has you configure the build by editing a bunch of plist files instead of just programming it like you would anything else. I want to follow my build from start to finish, not have a bunch of magic happening under the hood that I can't easily step through and debug.

And don't even get me started on "Clean Build Folder." I never have to do that with my build system. There is no more guessing.

Becuase I don't use Xcode's build system, I have basically kicked myself out of the walled Eden and now have to fend for myself when it comes to code signing, provisioning, and entitlements. 

I'm not using a default project that sets this up for me. So while you might go into Xcode and press a toggle thingy to enable something like Game Center, I have to find the plist key Apple's putting into the Entitlement.plist instead. If I don't, Apple will give me a really cryptic error after I submit my game.

So I write this to show you the ropes and hopefully speed up your build process. I had to learn many of these lessons the hard way, through trial and error. If I can show the places where I crashed my ship on the rocks, you should be able to avoid some of the traps I got sucked into when learning how to build and distribute Mac OS apps without tightly coupling myself to Xcode and its build system.

## Code Signing for Different Storefronts
Mooselutions is currently available on Steam and the Mac App Store.
[Mooselutions on Steam](https://store.steampowered.com/app/2287140/Mooselutions/)
[Mooselutions on the Mac App Store](https://apps.apple.com/us/app/mooselutions/id6477404960)

That means there are multiple ways the game needs to be built in order to support the different storefronts and platforms it ships on.

When shipping to Steam, the game's executable is signed with different entitlements and a signing certificate that allows for distribution outside of the Mac App Store. Apple typically calls it the Developer ID Application Certificate, which you generate on Apple's Developer portal (developer.apple.com)

Signing for the Mac App Store requires the 3rd Party Mac Developer Application and 3rd Party Mac Developer Installer certificates. 

Why the need for more than one? Because I use Apple's Transporter app to upload builds of my game to the Mac App Store. Transporter won't just take any old app bundle. It needs an installer package, so the commands you see at the bottom of the script transform an app bundle into an installer package, which Transporter will upload if it's structured the right way.

## Things You Definitely Don't Want To Do
While I was throwing various bad ideas against the wall to get this build system to work, I went down some silly rabbit holes. It is my hope that by giving you a clear and definitive answer, you won't try the same things I did.

### Don't try to create your own .xcarchive folder just so you can submit your app
Make an installer package and use Transporter instead. That's what it's for.

You can always try to create the .xcarchive folder and the structure that goes with it, but I suspect Xcode has a better internal process for doing this, and it probably uses some kind of Xcode secret sauce to generate the folders. 

From what I gather, if you want a .xcarchive, you need to have setup a build scheme for your projec and use the xcodebuild command. That means buying into Xcode's build system (i.e. the thing we are trying to avoid).

There might be other reasons to have an .xcarchive (for example submitting dSYMs for crash reporting), but if I needed crash reporting I would just use a third party library that's better at pinpointing where the crash happens.

### Don't try to compile your own XCAssets folder into an Assets.car
When I first attempted to submit Mooselutions, I was getting a bunch of cryptic errors about not having an assets file in my Mac OS app bundle.

I thought I needed to make an Assets.xcassets folder for my game's app icon, but that was a crazy rabbit hole that led nowhere. So now I am going to definitively say you only need to include your app's icon in the bundle you submit. If your app icon has all of the right sizes in it (yes even the 1024 size), Apple will happily accept your app, and your App Icon will appear in Transporter and on App Store connect.

Please don't waste your time creating an XCAssets folder separate from your App Icon thinking you need it to upload your game. You definitely don't.

## A General Warning About Error Messages You Get From Transporter and App Store Connect
Apple's error reporting system for these tools is just horrible. They're a big black box that has you constantly guessing what's wrong. To make it worse, they often give you error messages that take you down the wrong path. For example, they might say you're missing an Assets.xcassets file, but that's not the actual error. The actual error might be the presence of a misleading key in your Info.plist which is related to your App Icon. If you remove the misleading key, the error message goes away.

Don't trust the error messages! They are wrong most of the time!

If it says you're missing a file, look in your Info.plist for the plist key that might be tripping up the system and making it look for the file.

Apple really should include the plist key it's processing when giving error messages. If they did, it would make most of the messages much more clear. For the moment, we just guess, check, and hope for the best.

## Info and Entitlement Plists
I've included the ones I actually use in my project. In general, you want to be very careful with your Info.plist. If a single key is misspelled, duplicated, or otherwise incorrect, Transporter and App Store Connect will give you a bunch of incorrect error messages that will take you on a wild goose chase.

### Info.Plist

#### CFBundleIconFile
If you are shipping your game with an icns file for your App's Icon, this is the key that tells Apple the file name for your icon. Do not include any other plist keys relating to the name or location of an icon. If you do, Apple's tools will get confused and give you error messages saying they're looking for Assets.car

#### LSApplicationCategoryType
If you don't include this one, you will get blindsided with an error message after your build has uploaded and processed. You need to fill this out in order to submit to the Mac App Store.

#### CFBundlePackageType
Since you will create your own installer and submit a .pkg using Transporter, you need to tell it that the type of package you are creating is an application. That's what the APPL stands for. Omit this key and Tansporter won't know what to do with your package when you try to submit.

#### CFBundleShortVersionString
This is the version you report on App Store Connect. For example, if you create a version of your app and call it "1.0.0" on App Store Connect, this value needs to be the same string "1.0.0" If this doesn't match App Store Connect, you'll get an error saying the server can't find a version matching your game.

#### CFBundleVersion
This is your game's actual version, in integer form. It starts at zero and keeps going up. If you don't keep incrementing it with every new build you submit (even if you're submitting a new version), Transporter will give you a cryptic error saying it can't find a version matching your build.

To recap, you *never* reset this number. It starts at zero and keeps going up. If the last build you submitted for version 1.0.0 was CFBundleVersion 21, then then first build you submit for version 1.1.0 should be CFBundleVersion 22. A new short version does not reset this!

#### LSMinimumSystemVersion
This should be the same as the minimum system version you use to compile your game's executable. This is required in order to be on the Mac App Store.
